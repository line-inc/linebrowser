import Foundation
import NetworkExtension
import Combine

// MARK: - DNS Sniffer VPN (NETunnelProviderManager → our packet tunnel)

/// Owns the packet-tunnel connection used by the device-wide DNS sniffer.
/// (iOS 27 SDK: `NEPacketTunnelProviderManager` was folded into
/// `NETunnelProviderManager`.)
@MainActor
final class TunnelManager: ObservableObject {
    static let shared = TunnelManager()

    @Published var status: NEVPNStatus = .invalid
    @Published var lastError: String?
    /// Guards against double-taps while a save/start is in flight.
    @Published var busy = false

    private var manager: NETunnelProviderManager?
    private var observer: NSObjectProtocol?

    private static let providerBundleID = "com.lineinc.linebrowser.packettunnel"

    private init() {
        observer = NotificationCenter.default.addObserver(
            forName: .NEVPNStatusDidChange, object: nil, queue: .main
        ) { [weak self] _ in
            Task { @MainActor in self?.refresh() }
        }
        load()
    }

    deinit {
        if let observer { NotificationCenter.default.removeObserver(observer) }
    }

    /// Re-reads connection status from the stored manager.
    func refresh() {
        status = manager?.connection.status ?? .invalid
        if status == .invalid { load() }
    }

    func load() {
        NETunnelProviderManager.loadAllFromPreferences { [weak self] managers, _ in
            Task { @MainActor in
                guard let self else { return }
                self.manager = managers?.first
                self.status = managers?.first?.connection.status ?? .invalid
            }
        }
    }

    func toggle() {
        guard !busy else { return }
        switch status {
        case .connected, .connecting, .reasserting, .disconnecting:
            manager?.connection.stopVPNTunnel()
        default:
            start()
        }
    }

    private func start() {
        busy = true
        lastError = nil

        NETunnelProviderManager.loadAllFromPreferences { [weak self] managers, error in
            Task { @MainActor in
                guard let self else { return }
                if let error {
                    self.busy = false
                    self.lastError = error.localizedDescription
                    return
                }

                let manager = managers?.first ?? NETunnelProviderManager()
                let alreadyConfigured =
                    (manager.protocolConfiguration as? NETunnelProviderProtocol)?
                    .providerBundleIdentifier == Self.providerBundleID

                if !alreadyConfigured {
                    let proto = NETunnelProviderProtocol()
                    proto.providerBundleIdentifier = Self.providerBundleID
                    proto.serverAddress = "Line Browser DNS Sniffer"
                    manager.protocolConfiguration = proto
                    manager.localizedDescription = "Line Browser DNS Sniffer"
                    manager.isEnabled = true
                }
                self.manager = manager

                let go = {
                    do {
                        try manager.connection.startVPNTunnel(options: nil)
                    } catch {
                        self.lastError = error.localizedDescription
                    }
                    Task { @MainActor in
                        self.busy = false
                        self.refresh()
                    }
                }

                if alreadyConfigured {
                    go()
                } else {
                    manager.saveToPreferences { [weak self] error in
                        Task { @MainActor in
                            guard let self else { return }
                            if let error {
                                self.busy = false
                                self.lastError = error.localizedDescription
                            } else {
                                go()
                            }
                        }
                    }
                }
            }
        }
    }
}

// MARK: - IKEv2 VPN client (NEVPNManager / personal VPN)

/// Stores server credentials (password lives in the iOS keychain as a
/// persistent reference) and drives a standard IKEv2/IPsec tunnel.
@MainActor
final class IKEv2Manager: ObservableObject {
    static let shared = IKEv2Manager()

    private static let defaultsKey = "vpn.fields"
    private static let keychainService = "com.lineinc.linebrowser.vpn"

    @Published var status: NEVPNStatus = .invalid
    @Published var lastError: String?
    @Published var busy = false

    @Published var server: String { didSet { persist() } }
    @Published var remoteID: String { didSet { persist() } }
    @Published var username: String { didSet { persist() } }
    /// Never persisted to UserDefaults — only to the keychain, on connect.
    @Published var password = ""

    private var observer: NSObjectProtocol?

    private init() {
        let stored = UserDefaults.standard.dictionary(forKey: Self.defaultsKey) as? [String: String]
        server = stored?["server"] ?? ""
        remoteID = stored?["remoteID"] ?? ""
        username = stored?["username"] ?? ""

        observer = NotificationCenter.default.addObserver(
            forName: .NEVPNStatusDidChange, object: nil, queue: .main
        ) { [weak self] _ in
            Task { @MainActor in self?.refresh() }
        }
        load()
    }

    deinit {
        if let observer { NotificationCenter.default.removeObserver(observer) }
    }

    private func persist() {
        UserDefaults.standard.set(["server": server, "remoteID": remoteID, "username": username],
                                  forKey: Self.defaultsKey)
    }

    func refresh() {
        status = NEVPNManager.shared().connection.status
    }

    /// Reloads the shared manager from preferences (single-argument
    /// completion on current SDKs — the receiver refreshes itself).
    func load() {
        NEVPNManager.shared().loadFromPreferences { [weak self] _ in
            Task { @MainActor in
                self?.refresh()
            }
        }
    }

    func toggle() {
        guard !busy else { return }
        switch status {
        case .connected, .connecting, .reasserting, .disconnecting:
            NEVPNManager.shared().connection.stopVPNTunnel()
        default:
            connect()
        }
    }

    private func connect() {
        let lang = LanguageManager.shared
        guard !server.trimmingCharacters(in: .whitespaces).isEmpty else {
            lastError = lang.t("vpn.incomplete")
            return
        }
        busy = true
        lastError = nil

        NEVPNManager.shared().loadFromPreferences { [weak self] _ in
            Task { @MainActor in
                guard let self else { return }
                let manager = NEVPNManager.shared()

                let ike = NEVPNProtocolIKEv2()
                ike.serverAddress = self.server
                ike.remoteIdentifier = self.remoteID.isEmpty ? self.server : self.remoteID
                ike.authenticationMethod = .none // EAP: username + password
                ike.useExtendedAuthentication = true
                ike.username = self.username
                ike.deadPeerDetectionRate = .medium
                ike.disconnectOnSleep = false
                if let ref = Self.savePasswordToKeychain(self.password,
                                                         account: self.username) {
                    ike.passwordReference = ref
                }

                manager.protocolConfiguration = ike
                manager.localizedDescription = "Line Browser VPN"
                manager.isEnabled = true

                manager.saveToPreferences { [weak self] error in
                    Task { @MainActor in
                        guard let self else { return }
                        if let error {
                            self.busy = false
                            self.lastError = error.localizedDescription
                            return
                        }
                        do {
                            try manager.connection.startVPNTunnel(options: nil)
                        } catch {
                            self.lastError = error.localizedDescription
                        }
                        self.busy = false
                        self.password = ""
                        self.refresh()
                    }
                }
            }
        }
    }

    /// Writes the password to the keychain and returns its persistent
    /// reference (what `NEVPNProtocolIKEv2.passwordReference` expects).
    /// With an empty password it just returns the existing reference.
    private static func savePasswordToKeychain(_ password: String, account: String) -> Data? {
        let base: [CFString: Any] = [
            kSecClass: kSecClassGenericPassword,
            kSecAttrService: keychainService,
            kSecAttrAccount: account,
        ]

        if password.isEmpty {
            let q = base.merging([kSecReturnPersistentRef: true]) { a, _ in a }
            var ref: CFTypeRef?
            guard SecItemCopyMatching(q as CFDictionary, &ref) == errSecSuccess else { return nil }
            return ref as? Data
        }

        SecItemDelete(base as CFDictionary)
        var add = base
        add[kSecValueData] = password.data(using: .utf8)
        add[kSecAttrAccessible] = kSecAttrAccessibleAfterFirstUnlock
        add[kSecReturnPersistentRef] = true
        var ref: CFTypeRef?
        guard SecItemAdd(add as CFDictionary, &ref) == errSecSuccess else { return nil }
        return ref as? Data
    }
}
