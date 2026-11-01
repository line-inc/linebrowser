import Foundation
import Combine
import WebKit

// MARK: - Tab model

struct BrowserTab: Identifiable, Codable, Equatable {
    let id: UUID
    var url: String
    var title: String

    init(id: UUID = UUID(), url: String = "about:blank", title: String = "New Tab") {
        self.id = id
        self.url = url
        self.title = title
    }
}

// MARK: - Browser state

class BrowserModel: ObservableObject {
    /// Address of the active tab — the web view mirrors this.
    @Published var currentUrl: String = "https://lineinc.ro"
    @Published var inputUrl: String = "https://lineinc.ro"
    @Published var isLoading: Bool = false
    /// Deterministic page load progress (0–1) for the address-bar line.
    @Published var progress: Double = 0
    @Published var title: String = "Line Inc."
    /// Persisted — otherwise the star toggles into the void across launches.
    @Published var bookmarks: [String] {
        didSet { UserDefaults.standard.set(bookmarks, forKey: bookmarkKey) }
    }
    @Published var history: [String] = []
    @Published var showSettings: Bool = false
    @Published var showTabs: Bool = false
    /// Human-readable message from the last failed navigation (nil = no error).
    @Published var lastError: String?
    /// Bumped when the user explicitly asks to (re)load the current address
    /// (refresh button, Retry, re-submitting the same URL). The web view
    /// treats a token change as "load again no matter what".
    @Published var reloadToken: Int = 0

    // Tabs
    @Published var tabs: [BrowserTab]
    @Published var activeTabID: UUID

    /// Identifier of the search engine chosen during setup (or in Settings).
    @Published var searchEngine: String {
        didSet { UserDefaults.standard.set(searchEngine, forKey: "searchEngine") }
    }

    static let engines = ["duckduckgo", "google", "bing", "ecosia"]

    private let tabKey = "browser.tabs"
    private let activeTabKey = "browser.activeTab"
    private let bookmarkKey = "browser.bookmarks"

    init() {
        let d = UserDefaults.standard
        let stored = d.string(forKey: "searchEngine") ?? "duckduckgo"
        searchEngine = Self.engines.contains(stored) ? stored : "duckduckgo"
        bookmarks = d.stringArray(forKey: bookmarkKey) ?? ["https://lineinc.ro"]

        // Restore the previous session (Tabs ▸ "Restore session on launch").
        var restored: [BrowserTab]?
        if SettingsStore.shared.restoreSession,
           let data = d.data(forKey: tabKey),
           let decoded = try? JSONDecoder().decode([BrowserTab].self, from: data),
           !decoded.isEmpty {
            restored = decoded
        }
        let list = restored ?? [BrowserTab(url: "https://lineinc.ro", title: "Line Inc.")]
        tabs = list

        if let activeID = d.uuid(forKey: activeTabKey), let match = list.first(where: { $0.id == activeID }) {
            activeTabID = match.id
        } else {
            activeTabID = list[0].id
        }

        let start = list.first(where: { $0.id == activeTabID })?.url ?? "https://lineinc.ro"
        currentUrl = start
        inputUrl = start
    }

    // MARK: - Tabs

    var activeTab: BrowserTab? { tabs.first { $0.id == activeTabID } }

    @discardableResult
    func newTab(url: String = "about:blank", title: String = "New Tab") -> BrowserTab {
        let tab = BrowserTab(url: url, title: title)
        tabs.append(tab)
        activeTabID = tab.id
        currentUrl = url
        inputUrl = url == "about:blank" ? "" : url
        persistTabs()
        return tab
    }

    func selectTab(_ id: UUID) {
        guard let tab = tabs.first(where: { $0.id == id }) else { return }
        activeTabID = id
        currentUrl = tab.url
        inputUrl = tab.url == "about:blank" ? "" : tab.url
        persistTabs()
    }

    func closeTab(_ id: UUID) {
        guard tabs.count > 1, let index = tabs.firstIndex(where: { $0.id == id }) else {
            // Never close the last remaining tab — just reset it.
            if let only = tabs.first, only.id == id {
                tabs[0] = BrowserTab(url: SettingsStore.shared.homePage, title: "Line Inc.")
                selectTab(tabs[0].id)
            }
            return
        }
        tabs.remove(at: index)
        if activeTabID == id {
            let next = tabs[min(index, tabs.count - 1)]
            selectTab(next.id)
        } else {
            persistTabs()
        }
    }

    /// Keeps the active tab in sync when a page finishes loading.
    func updateActive(url: String, title: String?) {
        if let index = tabs.firstIndex(where: { $0.id == activeTabID }) {
            tabs[index].url = url
            if let title, !title.isEmpty { tabs[index].title = title }
        }
        if !history.contains(url) { history.append(url) }
        persistTabs()
    }

    private func persistTabs() {
        guard SettingsStore.shared.restoreSession else { return }
        if let data = try? JSONEncoder().encode(tabs) {
            UserDefaults.standard.set(data, forKey: tabKey)
        }
        UserDefaults.standard.set(activeTabID, forKey: activeTabKey)
    }

    // MARK: - Search

    var searchPrefix: String {
        switch searchEngine {
        case "google": return "https://www.google.com/search?q="
        case "bing": return "https://www.bing.com/search?q="
        case "ecosia": return "https://www.ecosia.org/search?q="
        default: return "https://duckduckgo.com/?q="
        }
    }

    /// Turns free text into a URL: a domain becomes a visit, anything else a search.
    func resolve(_ raw: String) -> String {
        let text = raw.trimmingCharacters(in: .whitespaces)
        guard !text.isEmpty else { return currentUrl }
        if text.hasPrefix("http://") || text.hasPrefix("https://") { return text }
        if text.contains(".") && !text.contains(" ") && !text.hasSuffix(".") {
            return "https://" + text
        }
        let query = text.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? text
        return searchPrefix + query
    }

    func submit(_ raw: String) {
        let url = resolve(raw)
        if url == currentUrl {
            // Re-submitting the address we're already on = "load it again".
            // Without this the refresh/Retry buttons hit the web view's
            // "already displaying this URL" guard and do nothing.
            reloadToken += 1
        } else {
            currentUrl = url
        }
        inputUrl = url
    }

    /// Used when an external app hands us a link (default-browser behaviour).
    func open(_ url: URL) {
        let string = url.absoluteString
        if let tab = tabs.first(where: { $0.id == activeTabID }),
           tab.url == "about:blank" || tab.url.isEmpty {
            // Reuse the fresh empty tab instead of spawning another one.
            if let index = tabs.firstIndex(where: { $0.id == activeTabID }) {
                tabs[index].url = string
            }
        } else {
            newTab(url: string, title: string)
            return
        }
        currentUrl = string
        inputUrl = string
        persistTabs()
    }

    // MARK: - Bookmarks

    func toggleBookmark(_ url: String) {
        if let index = bookmarks.firstIndex(of: url) {
            bookmarks.remove(at: index)
        } else {
            bookmarks.append(url)
        }
    }

    func isBookmarked(_ url: String) -> Bool { bookmarks.contains(url) }

    // MARK: - Privacy

    /// Wipes cookies, caches, localStorage and other website data.
    func clearAllWebsiteData(completion: (() -> Void)? = nil) {
        let store = WKWebsiteDataStore.default()
        store.fetchDataRecords(ofTypes: WKWebsiteDataStore.allWebsiteDataTypes()) { records in
            store.removeData(ofTypes: WKWebsiteDataStore.allWebsiteDataTypes(), for: records) {
                DispatchQueue.main.async {
                    self.history.removeAll()
                    completion?()
                }
            }
        }
    }
}

extension UserDefaults {
    func uuid(forKey key: String) -> UUID? {
        guard let string = string(forKey: key) else { return nil }
        return UUID(uuidString: string)
    }
    func set(_ uuid: UUID, forKey key: String) {
        set(uuid.uuidString, forKey: key)
    }
}
