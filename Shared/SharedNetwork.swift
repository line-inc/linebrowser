import Foundation

// MARK: - App Group shared between Line Browser and the PacketTunnel extension

enum AppGroup {
    static let id = "group.com.lineinc.linebrowser"
    static let dnsLogFileName = "dns-log.jsonl"
    /// Darwin notification posted whenever the DNS log file changes.
    static let dnsNotifyName = "com.lineinc.linebrowser.dnslog"
    /// Key in the group's UserDefaults: device-wide DNS ad blocking.
    static let blockAdsKey = "dns.blockAds"

    static var container: URL? {
        FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: id)
    }

    static var logURL: URL? {
        container?.appendingPathComponent(dnsLogFileName)
    }

    /// UserDefaults of the group — written by the app (toggles), read by the
    /// tunnel extension (cached ~1s).
    static var defaults: UserDefaults? {
        UserDefaults(suiteName: id)
    }
}

// MARK: - One captured DNS query (JSON-lines encoded into the group container)

struct DnsEntry: Identifiable, Codable, Equatable {
    var id: UUID = UUID()
    /// Epoch seconds.
    var t: Double
    var host: String
    /// "A", "AAAA", "CNAME", …
    var qt: String
    var blocked: Bool

    var date: Date { Date(timeIntervalSince1970: t) }
}

// MARK: - Ad / tracker domains shared by the in-page content blocker (app)
// and the device-wide DNS sniffer (packet-tunnel extension).

enum SharedBlocklist {
    static let domains: [String] = [
        "doubleclick.net", "googlesyndication.com", "googleadservices.com",
        "googletagmanager.com", "google-analytics.com", "googletagservices.com",
        "facebook.com", "connect.facebook.net", "fbcdn.net",
        "ads.tiktok.com", "adnxs.com", "criteo.com", "criteo.net",
        "taboola.com", "outbrain.com", "scorecardresearch.com", "comscore.com",
        "hotjar.com", "mixpanel.com", "segment.io", "segment.com",
        "amplitude.com", "branch.io", "appsflyer.com", "adjust.com",
        "matomo.org", "openx.net", "rubiconproject.com", "pubmatic.com",
        "smartadserver.com", "zedo.com", "moatads.com", "adform.net",
        "adcolony.com", "applovin.com", "inmobi.com", "mopub.com",
        "fullstory.com", "clarity.ms", "crazyegg.com", "optimizely.com",
        "newrelic.com", "nr-data.net", "doubleverify.com", "adtrafficquality.google",
        // Extra domains the in-page rules don't need but DNS blocking catches
        // (tracking pixels, telemetry endpoints):
        "ads.yahoo.com", "advertising.com", "serving-sys.com",
        "cassavaengine.com", "zerostats.com", "appsdt.com",
        "engine.adcontextpartners.com", "onetag-sys.com", "permutive.com",
        "bat.bing.com", "clarity-prod.westus.cloudapp.azure.com",
    ]

    /// Exact-or-suffix match: "ads.example.com" matches "doubleclick.net"? No —
    /// matches only if the host itself or a parent domain is on the list.
    static func isBlocked(_ host: String) -> Bool {
        let h = host.lowercased()
        guard !h.isEmpty else { return false }
        return domains.contains { h == $0 || h.hasSuffix("." + $0) }
    }
}

// MARK: - Append-only DNS log writer (runs inside the extension; the app
// only reads + truncates).

enum DNSLogWriter {
    private static let encoder = JSONEncoder()
    private static var lastNotify = Date.distantPast

    static func append(_ entry: DnsEntry) {
        guard let url = AppGroup.logURL else { return }
        let fm = FileManager.default
        if !fm.fileExists(atPath: url.path) {
            fm.createFile(atPath: url.path, contents: nil)
        }
        guard let fh = try? FileHandle(forWritingTo: url) else { return }
        var line = (try? encoder.encode(entry)) ?? Data()
        line.append(0x0A)
        _ = try? fh.seekToEnd()
        try? fh.write(contentsOf: line)
        try? fh.close()

        // Keep the file bounded: >96 KB → keep the newest 500 lines.
        if let size = (try? fm.attributesOfItem(atPath: url.path)[.size]) as? Int,
           size > 96_000 {
            trim(url: url)
        }
        notifyThrottled()
    }

    /// Truncate (used by the app's "Clear" button).
    static func clear() {
        guard let url = AppGroup.logURL else { return }
        try? Data().write(to: url)
        post()
    }

    private static func trim(url: URL) {
        guard let data = try? Data(contentsOf: url),
              let text = String(data: data, encoding: .utf8) else { return }
        let lines = text.split(separator: "\n", omittingEmptySubsequences: true)
        guard lines.count > 600 else { return }
        let kept = lines.suffix(500).joined(separator: "\n") + "\n"
        try? kept.data(using: .utf8)?.write(to: url)
    }

    private static func notifyThrottled() {
        let now = Date()
        guard now.timeIntervalSince(lastNotify) > 0.4 else { return }
        lastNotify = now
        post()
    }

    static func post() {
        CFNotificationCenterPostNotification(
            CFNotificationCenterGetDarwinNotifyCenter(),
            CFNotificationName(AppGroup.dnsNotifyName as CFString),
            nil, nil, true)
    }
}
