import Foundation
import Security
import CryptoKit
import LocalAuthentication

// MARK: - Keychain-backed password manager

struct Credential: Identifiable, Codable, Equatable {
    let id: UUID
    var site: String
    var username: String
    var password: String

    init(id: UUID = UUID(), site: String, username: String, password: String) {
        self.id = id
        self.site = site
        self.username = username
        self.password = password
    }
}

final class PasswordStore: ObservableObject {
    static let shared = PasswordStore()

    @Published var items: [Credential] { didSet { persist() } }

    private let service = "com.lineinc.linebrowser.passwords"
    private let account = "credentials"

    private init() {
        items = Self.load(service: service, account: account)
    }

    func add(site: String, username: String, password: String) {
        guard !site.isEmpty, !password.isEmpty else { return }
        items.append(Credential(site: site, username: username, password: password))
    }

    func remove(_ credential: Credential) {
        items.removeAll { $0.id == credential.id }
    }

    // MARK: Keychain plumbing

    private func persist() {
        guard let data = try? JSONEncoder().encode(items) else { return }
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
        ]
        let attributes: [String: Any] = [kSecValueData as String: data]
        let status = SecItemUpdate(query as CFDictionary, attributes as CFDictionary)
        if status == errSecItemNotFound {
            var add = query
            add[kSecValueData as String] = data
            add[kSecAttrAccessible as String] = kSecAttrAccessibleWhenUnlockedThisDeviceOnly
            SecItemAdd(add as CFDictionary, nil)
        }
    }

    private static func load(service: String, account: String) -> [Credential] {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne,
        ]
        var result: AnyObject?
        guard SecItemCopyMatching(query as CFDictionary, &result) == errSecSuccess,
              let data = result as? Data,
              let decoded = try? JSONDecoder().decode([Credential].self, from: data)
        else { return [] }
        return decoded
    }
}

// MARK: - Biometric private vault (AES-GCM)

struct VaultItem: Identifiable, Codable, Equatable {
    let id: UUID
    var title: String
    var content: String
    var created: Date

    init(id: UUID = UUID(), title: String, content: String, created: Date = Date()) {
        self.id = id
        self.title = title
        self.content = content
        self.created = created
    }
}

final class VaultStore: ObservableObject {
    static let shared = VaultStore()

    @Published var isUnlocked = false
    @Published var items: [VaultItem] = []
    @Published var lastError: String?

    private var key: SymmetricKey?
    private let service = "com.lineinc.linebrowser.vault"
    private let accountKey = "key"
    private let accountItems = "items"

    private init() {}

    // MARK: Unlock / lock

    func unlock(reason: String, completion: @escaping (Bool) -> Void) {
        let context = LAContext()
        var error: NSError?
        guard context.canEvaluatePolicy(.deviceOwnerAuthentication, error: &error) else {
            lastError = error?.localizedDescription
            completion(false)
            return
        }
        context.evaluatePolicy(.deviceOwnerAuthentication, localizedReason: reason) { [weak self] success, evalError in
            DispatchQueue.main.async {
                guard let self else { return }
                if success {
                    self.key = self.loadOrCreateKey()
                    self.items = self.decryptItems()
                    self.isUnlocked = self.key != nil
                    self.lastError = self.key == nil ? evalError?.localizedDescription : nil
                } else {
                    self.lastError = evalError?.localizedDescription
                }
                completion(success)
            }
        }
    }

    func lock() {
        key = nil
        items = []
        isUnlocked = false
    }

    // MARK: Editing

    func add(title: String, content: String) {
        guard !content.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        items.insert(VaultItem(title: title.isEmpty ? "—" : title, content: content), at: 0)
        saveItems()
    }

    func remove(_ item: VaultItem) {
        items.removeAll { $0.id == item.id }
        saveItems()
    }

    // MARK: Crypto

    private func loadOrCreateKey() -> SymmetricKey? {
        if let data = Self.readKeychain(service: service, account: accountKey) {
            return SymmetricKey(data: data)
        }
        let key = SymmetricKey(size: .bits256)
        guard Self.writeKeychain(data: key.withUnsafeBytes { Data($0) },
                                 service: service, account: accountKey) else { return nil }
        return key
    }

    private func decryptItems() -> [VaultItem] {
        guard let key,
              let blob = Self.readKeychain(service: service, account: accountItems),
              let box = try? AES.GCM.SealedBox(combined: blob),
              let plain = try? AES.GCM.open(box, using: key),
              let decoded = try? JSONDecoder().decode([VaultItem].self, from: plain)
        else { return [] }
        return decoded
    }

    private func saveItems() {
        guard let key, let plain = try? JSONEncoder().encode(items) else { return }
        guard let box = try? AES.GCM.seal(plain, using: key),
              let combined = box.combined else { return }
        _ = Self.writeKeychain(data: combined, service: service, account: accountItems)
    }

    // MARK: Keychain helpers

    private static func readKeychain(service: String, account: String) -> Data? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne,
        ]
        var result: AnyObject?
        guard SecItemCopyMatching(query as CFDictionary, &result) == errSecSuccess else { return nil }
        return result as? Data
    }

    private static func writeKeychain(data: Data, service: String, account: String) -> Bool {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
        ]
        let attributes: [String: Any] = [kSecValueData as String: data]
        let status = SecItemUpdate(query as CFDictionary, attributes as CFDictionary)
        if status == errSecItemNotFound {
            var add = query
            add[kSecValueData as String] = data
            add[kSecAttrAccessible as String] = kSecAttrAccessibleWhenUnlockedThisDeviceOnly
            return SecItemAdd(add as CFDictionary, nil) == errSecSuccess
        }
        return status == errSecSuccess
    }
}
