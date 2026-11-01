import Foundation
import NetworkExtension
import Network

/// Device-wide DNS sniffer.
///
/// iOS sends every DNS query on the phone to 100.64.0.1 (the resolver we
/// install via `dnsSettings`), and the only route we install points at that
/// address — so *only* DNS enters this tunnel; all other traffic and IPs
/// stay on the normal path. Each query is logged to the app group, blocked
/// (NXDOMAIN) when on the block list, otherwise forwarded to 1.1.1.1 and the
/// answer handed back to the asking app.
class PacketTunnelProvider: NEPacketTunnelProvider {
    private let queue = DispatchQueue(label: "linebrowser.dns-proxy")
    private var ipID: UInt16 = 0
    private var blockAds = true
    private var lastToggleCheck = Date.distantPast

    private static let serverIP = Data([1, 1, 1, 1])       // upstream resolver
    private static let tunnelDNSIP = Data([100, 64, 0, 1]) // what clients see

    // MARK: - Tunnel lifecycle

    override func startTunnel(options: [String: NSObject]?,
                              completionHandler: @escaping (Error?) -> Void) {
        blockAds = AppGroup.defaults?.object(forKey: AppGroup.blockAdsKey) as? Bool ?? true
        print("[DNS] sniffer starting")

        let settings = NEPacketTunnelNetworkSettings(tunnelRemoteAddress: "1.1.1.1")

        let ipv4 = NEIPv4Settings(addresses: ["100.64.0.2"],
                                  subnetMasks: ["255.255.255.255"])
        // Only the resolver address is routed into the tunnel.
        ipv4.includedRoutes = [
            NEIPv4Route(destinationAddress: "100.64.0.1",
                        subnetMask: "255.255.255.255"),
        ]
        settings.ipv4Settings = ipv4

        let dns = NEDNSSettings(servers: ["100.64.0.1"])
        dns.matchDomains = [""] // every lookup resolves through us
        settings.dnsSettings = dns
        settings.mtu = 1400

        setTunnelNetworkSettings(settings) { [weak self] error in
            guard let self else {
                completionHandler(error)
                return
            }
            if let error {
                completionHandler(error)
                return
            }
            print("[DNS] tunnel up — logging DNS only, forwarding to 1.1.1.1")
            self.readPackets()
            completionHandler(nil)
        }
    }

    override func stopTunnel(with reason: NEProviderStopReason,
                             completionHandler: @escaping () -> Void) {
        print("[DNS] sniffer stopping (\(reason.rawValue))")
        completionHandler()
    }

    // MARK: - Packet loop

    private func readPackets() {
        packetFlow.readPackets { [weak self] packets, _ in
            guard let self else { return }
            for data in packets {
                // All mutable state lives on `queue`.
                self.queue.async { self.handle(data) }
            }
            self.readPackets()
        }
    }

    // MARK: - Parsing

    private func handle(_ data: Data) {
        let b = [UInt8](data)
        // IPv4 only; our routes guarantee everything here targets us.
        guard b.count >= 20, b[0] >> 4 == 4 else { return }
        let ihl = Int(b[0] & 0x0F) * 4
        guard ihl >= 20, b.count >= ihl + 8, b[9] == 17 else { return } // UDP

        let srcPort = UInt16(b[ihl]) << 8 | UInt16(b[ihl + 1])
        let dstPort = UInt16(b[ihl + 2]) << 8 | UInt16(b[ihl + 3])
        let udpLen = Int(UInt16(b[ihl + 4]) << 8 | UInt16(b[ihl + 5]))
        guard dstPort == 53, udpLen >= 8, b.count >= ihl + udpLen else { return }

        let payload = Data(b[(ihl + 8)..<(ihl + udpLen)])
        let clientIP = Data(b[12..<16])
        process(payload, clientIP: clientIP, clientPort: srcPort)
    }

    private struct Query {
        let host: String
        let qtype: Int
        /// Offset just past QTYPE+QCLASS — used to build error responses
        /// that carry only the question section (no echoed EDNS OPT).
        let questionEnd: Int
    }

    private func parse(_ b: [UInt8]) -> Query? {
        guard b.count >= 12 else { return nil }
        var i = 12
        var labels: [String] = []
        while i < b.count {
            let len = Int(b[i])
            if len == 0 { i += 1; break }
            if len & 0xC0 == 0xC0 { i += 2; break } // compression pointer
            i += 1
            guard i + len <= b.count else { return nil }
            labels.append(String(decoding: b[i..<(i + len)], as: UTF8.self))
            i += len
        }
        guard i + 4 <= b.count else { return nil }
        let qtype = Int(b[i]) << 8 | Int(b[i + 1])
        return Query(host: labels.joined(separator: ".").lowercased(),
                     qtype: qtype,
                     questionEnd: i + 4)
    }

    // MARK: - Decisions

    private func process(_ payload: Data, clientIP: Data, clientPort: UInt16) {
        let b = [UInt8](payload)
        guard let query = parse(b) else { return }

        let blocked = shouldBlock(query.host)
        DNSLogWriter.append(DnsEntry(t: Date().timeIntervalSince1970,
                                     host: query.host.isEmpty ? "?" : query.host,
                                     qt: Self.qtypeName(query.qtype),
                                     blocked: blocked))
        if blocked {
            print("[DNS] BLOCK \(query.host)")
            write(Self.errorResponse(payload, questionEnd: query.questionEnd, rcode: 3),
                  clientIP: clientIP, clientPort: clientPort)
            return
        }
        forward(payload, query: query, clientIP: clientIP, clientPort: clientPort)
    }

    private func shouldBlock(_ host: String) -> Bool {
        let now = Date()
        if now.timeIntervalSince(lastToggleCheck) > 1 {
            lastToggleCheck = now
            blockAds = AppGroup.defaults?.object(forKey: AppGroup.blockAdsKey) as? Bool ?? true
        }
        return blockAds && SharedBlocklist.isBlocked(host)
    }

    // MARK: - Upstream (1.1.1.1)

    private func forward(_ payload: Data, query: Query,
                         clientIP: Data, clientPort: UInt16) {
        let conn = NWConnection(host: NWEndpoint.Host("1.1.1.1"),
                                port: NWEndpoint.Port(rawValue: 53)!,
                                using: .udp)
        let replied = RepliedBox()

        conn.stateUpdateHandler = { [weak self] state in
            switch state {
            case .ready:
                conn.send(content: payload, completion: .contentProcessed { error in
                    if let error, replied.mark() {
                        print("[DNS] send failed: \(error)")
                        self?.write(Self.errorResponse(payload,
                                                       questionEnd: query.questionEnd,
                                                       rcode: 2),
                                    clientIP: clientIP, clientPort: clientPort)
                    }
                })
            case .failed(let error):
                if replied.mark() {
                    print("[DNS] upstream failed: \(error)")
                    self?.write(Self.errorResponse(payload,
                                                   questionEnd: query.questionEnd,
                                                   rcode: 2),
                                clientIP: clientIP, clientPort: clientPort)
                }
                conn.cancel()
            default:
                break
            }
        }
        conn.start(queue: queue)
        conn.receiveMessage { [weak self] data, _, _, error in
            if let data, replied.mark() {
                self?.write(Self.buildIPv4(src: Self.serverIP, dst: clientIP,
                                           sport: 53, dport: clientPort,
                                           payload: data, id: self?.nextIPID() ?? 0),
                            clientIP: clientIP, clientPort: clientPort)
            } else if error != nil, replied.mark() {
                self?.write(Self.errorResponse(payload,
                                               questionEnd: query.questionEnd,
                                               rcode: 2),
                            clientIP: clientIP, clientPort: clientPort)
            }
            conn.cancel()
        }
    }

    /// One-shot "have we already answered?" flag (all accesses on `queue`).
    private final class RepliedBox {
        var replied = false
        func mark() -> Bool {
            if replied { return false }
            replied = true
            return true
        }
    }

    private func nextIPID() -> UInt16 {
        ipID &+= 1
        return ipID
    }

    // MARK: - Writing responses back to the client

    private func write(_ packet: Data, clientIP: Data, clientPort: UInt16) {
        packetFlow.writePackets([packet],
                                withProtocols: [NSNumber(value: AF_INET)])
    }

    // MARK: - Packet builders

    /// Copies the question section and stamps an error header on it.
    private static func errorResponse(_ q: Data, questionEnd: Int, rcode: Int) -> Data {
        let end = min(questionEnd, q.count)
        guard end >= 12 else { return q }
        var r = Data(q[0..<end])
        r[2] = 0x80 | (r[2] & 0x01)          // QR | RD (echoed)
        r[3] = 0x80 | UInt8(rcode & 0x0F)    // RA | RCODE
        r[6] = 0; r[7] = 0                   // ANCOUNT
        r[8] = 0; r[9] = 0                   // NSCOUNT
        r[10] = 0; r[11] = 0                 // ARCOUNT (drop echoed EDNS OPT)
        return r
    }

    private static func buildIPv4(src: Data, dst: Data, sport: UInt16,
                                  dport: UInt16, payload: Data, id: UInt16) -> Data {
        let udpLen = 8 + payload.count
        let total = 20 + udpLen
        var pkt = Data(count: total)
        pkt[0] = 0x45
        pkt[2] = UInt8(total >> 8); pkt[3] = UInt8(total & 0xFF)
        pkt[4] = UInt8(id >> 8); pkt[5] = UInt8(id & 0xFF)
        pkt[8] = 64                           // TTL
        pkt[9] = 17                           // UDP
        pkt.replaceSubrange(12..<16, with: src)
        pkt.replaceSubrange(16..<20, with: dst)
        let ipCsum = onesComplement(Array(pkt[0..<20]))
        pkt[10] = UInt8(ipCsum >> 8); pkt[11] = UInt8(ipCsum & 0xFF)

        pkt[20] = UInt8(sport >> 8); pkt[21] = UInt8(sport & 0xFF)
        pkt[22] = UInt8(dport >> 8); pkt[23] = UInt8(dport & 0xFF)
        pkt[24] = UInt8(udpLen >> 8); pkt[25] = UInt8(udpLen & 0xFF)
        pkt.replaceSubrange(28..<total, with: payload)

        // UDP checksum over IPv4 pseudo-header + header + payload.
        var pseudo = [UInt8]()
        pseudo.append(contentsOf: src)
        pseudo.append(contentsOf: dst)
        pseudo.append(0)
        pseudo.append(17)
        pseudo.append(UInt8(udpLen >> 8)); pseudo.append(UInt8(udpLen & 0xFF))
        pseudo.append(contentsOf: pkt[20..<total])
        var u = onesComplement(pseudo)
        if u == 0 { u = 0xFFFF }
        pkt[26] = UInt8(u >> 8); pkt[27] = UInt8(u & 0xFF)
        return pkt
    }

    private static func onesComplement(_ bytes: [UInt8]) -> UInt16 {
        var sum: UInt32 = 0
        var i = 0
        while i + 1 < bytes.count {
            sum += UInt32(bytes[i]) << 8 | UInt32(bytes[i + 1])
            i += 2
        }
        if i < bytes.count { sum += UInt32(bytes[i]) << 8 }
        while (sum >> 16) != 0 { sum = (sum & 0xFFFF) + (sum >> 16) }
        return ~UInt16(sum & 0xFFFF)
    }

    private static func qtypeName(_ type: Int) -> String {
        switch type {
        case 1: return "A"
        case 28: return "AAAA"
        case 5: return "CNAME"
        case 12: return "PTR"
        case 15: return "MX"
        case 16: return "TXT"
        case 33: return "SRV"
        case 65: return "HTTPS"
        default: return "\(type)"
        }
    }
}
