import SwiftUI

// MARK: - Saved web apps (PWA-style shortcuts)

struct SavedWebApp: Identifiable, Codable, Equatable {
    let id: UUID
    var name: String
    var url: String
    var symbol: String

    init(id: UUID = UUID(), name: String, url: String, symbol: String = "globe") {
        self.id = id
        self.name = name
        self.url = url
        self.symbol = symbol
    }
}

final class WebAppStore: ObservableObject {
    static let shared = WebAppStore()
    @Published var apps: [SavedWebApp] {
        didSet {
            if let data = try? JSONEncoder().encode(apps) {
                UserDefaults.standard.set(data, forKey: "webapps")
            }
        }
    }

    private init() {
        if let data = UserDefaults.standard.data(forKey: "webapps"),
           let decoded = try? JSONDecoder().decode([SavedWebApp].self, from: data) {
            apps = decoded
        } else {
            apps = []
        }
    }

    func add(name: String, url: String) {
        guard !apps.contains(where: { $0.url == url }) else { return }
        apps.append(SavedWebApp(name: name, url: url))
    }

    func remove(_ app: SavedWebApp) {
        apps.removeAll { $0.id == app.id }
    }
}

// MARK: - Tab overview (sheet opened from the toolbar)

struct TabOverviewView: View {
    @ObservedObject var model: BrowserModel
    @ObservedObject private var settings = SettingsStore.shared
    @ObservedObject private var lang = LanguageManager.shared
    @Environment(\.dismiss) private var dismiss
    @State private var confirmCloseAll = false

    var body: some View {
        ZStack {
            settings.backgroundView()

            VStack(spacing: 0) {
                HStack {
                    Text(lang.t("tabs.title"))
                        .font(.app(20))
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                    Spacer()
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 26))
                            .foregroundColor(Color(UIColor.systemGray2))
                    }
                }
                .padding(.horizontal, 18)
                .padding(.top, 18)
                .padding(.bottom, 10)

                ScrollView {
                    VStack(spacing: 10) {
                        ForEach(model.tabs) { tab in
                            Button {
                                model.selectTab(tab.id)
                                dismiss()
                            } label: {
                                tabRow(tab)
                            }
                            .buttonStyle(.plain)
                        }

                        // ── Bookmarks ────────────────────────────────
                        if !model.bookmarks.isEmpty {
                            Text(lang.t("tabs.bookmarks"))
                                .font(.app(12))
                                .fontWeight(.semibold)
                                .foregroundColor(Color(UIColor.systemGray2))
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(.top, 12)

                            ForEach(model.bookmarks, id: \.self) { url in
                                bookmarkRow(url)
                            }
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.bottom, 16)
                }

                HStack(spacing: 12) {
                    PrimaryButton(title: lang.t("tabs.new"), icon: "plus") {
                        model.newTab()
                        dismiss()
                    }
                    if model.tabs.count > 1 {
                        SecondaryButton(title: lang.t("tabs.closeAll"), icon: "trash", color: .red) {
                            if settings.restoreSession && !confirmCloseAll {
                                confirmCloseAll = true
                            } else {
                                closeAll()
                            }
                        }
                    }
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 22)
                .padding(.top, 6)
            }
        }
        .confirmationDialog(lang.t("tabs.confirmClose"),
                            isPresented: $confirmCloseAll, titleVisibility: .visible) {
            Button(lang.t("tabs.closeAll"), role: .destructive) { closeAll() }
            Button(lang.t("common.skip"), role: .cancel) {}
        }
    }

    private func tabRow(_ tab: BrowserTab) -> some View {
        HStack(spacing: 12) {
            RoundedRectangle(cornerRadius: 8)
                .fill(tab.id == model.activeTabID ? settings.accent : Color(UIColor(white: 0.2, alpha: 1)))
                .frame(width: 34, height: 34)
                .overlay(Image(systemName: tab.url == "about:blank" ? "plus" : "globe")
                    .font(.system(size: 14))
                    .foregroundColor(.white))

            VStack(alignment: .leading, spacing: 2) {
                Text(tab.title.isEmpty ? lang.t("tabs.untitled") : tab.title)
                    .font(.app(15))
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                    .lineLimit(1)
                Text(tab.url)
                    .font(.app(12))
                    .foregroundColor(Color(UIColor.systemGray2))
                    .lineLimit(1)
            }
            Spacer()

            if model.tabs.count > 1 {
                Button {
                    model.closeTab(tab.id)
                } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(.white)
                        .frame(width: 26, height: 26)
                        .background(Color(UIColor(white: 0.25, alpha: 1)))
                        .clipShape(Circle())
                }
                .buttonStyle(.plain)
            }
        }
        .padding(12)
        .background(settings.cardColor)
        .cornerRadius(14)
        .overlay(RoundedRectangle(cornerRadius: 14)
            .stroke(tab.id == model.activeTabID ? settings.accent : Color.clear, lineWidth: 1.5))
    }

    private func bookmarkRow(_ url: String) -> some View {
        HStack(spacing: 12) {
            RoundedRectangle(cornerRadius: 8)
                .fill(Color(UIColor(white: 0.2, alpha: 1)))
                .frame(width: 34, height: 34)
                .overlay(Image(systemName: "star.fill")
                    .font(.system(size: 13))
                    .foregroundColor(settings.accent))

            VStack(alignment: .leading, spacing: 2) {
                Text(URL(string: url)?.host ?? url)
                    .font(.app(14))
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                    .lineLimit(1)
                Text(url)
                    .font(.app(11))
                    .foregroundColor(Color(UIColor.systemGray2))
                    .lineLimit(1)
            }
            Spacer()

            // Remove from bookmarks (opening the page = tapping the row).
            Button {
                model.toggleBookmark(url)
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(.white)
                    .frame(width: 24, height: 24)
                    .background(Color(UIColor(white: 0.25, alpha: 1)))
                    .clipShape(Circle())
            }
            .buttonStyle(.plain)
        }
        .padding(12)
        .background(settings.cardColor)
        .cornerRadius(14)
        .contentShape(Rectangle())
        .onTapGesture {
            model.submit(url)
            dismiss()
        }
    }

    private func closeAll() {
        model.tabs = [BrowserTab(url: SettingsStore.shared.homePage, title: "Line Inc.")]
        model.selectTab(model.tabs[0].id)
        dismiss()
    }
}

// MARK: - Tabs settings

struct TabsSettingsView: View {
    @ObservedObject var model: BrowserModel
    @ObservedObject private var settings = SettingsStore.shared
    @ObservedObject private var lang = LanguageManager.shared

    var body: some View {
        ScreenShell(title: lang.t("screen.tabs.title")) {
            CardSection(title: lang.t("tabs.open")) {
                if model.tabs.isEmpty {
                    EmptyState(icon: "rectangle.stack.badge.plus", title: lang.t("tabs.empty"))
                } else {
                    ForEach(Array(model.tabs.enumerated()), id: \.element.id) { index, tab in
                        Button {
                            model.selectTab(tab.id)
                        } label: {
                            HStack(spacing: 12) {
                                Image(systemName: tab.id == model.activeTabID ? "record.circle" : "circle")
                                    .foregroundColor(tab.id == model.activeTabID ? settings.accent
                                                     : Color(UIColor.systemGray2))
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(tab.title.isEmpty ? lang.t("tabs.untitled") : tab.title)
                                        .font(.app(14))
                                        .fontWeight(.medium)
                                        .foregroundColor(.white)
                                        .lineLimit(1)
                                    Text(tab.url)
                                        .font(.app(11))
                                        .foregroundColor(Color(UIColor.systemGray2))
                                        .lineLimit(1)
                                }
                                Spacer()
                                Button {
                                    model.closeTab(tab.id)
                                } label: {
                                    Image(systemName: "xmark.circle.fill")
                                        .foregroundColor(.red)
                                }
                                .buttonStyle(.plain)
                            }
                            .padding(.horizontal, 12)
                            .padding(.vertical, 10)
                        }
                        .buttonStyle(.plain)
                        if index < model.tabs.count - 1 {
                            Divider().overlay(Color.black.opacity(0.4))
                        }
                    }
                }
            }

            CardSection(title: lang.t("layout.tabs")) {
                ToggleRow(icon: "square.stack.3d.up.fill", color: .cyan,
                          title: lang.t("layout.tabCount"), subtitle: lang.t("layout.tabCountSub"),
                          isOn: $settings.showTabCount)
                Divider().overlay(Color.black.opacity(0.4))
                ToggleRow(icon: "arrow.clockwise.circle.fill", color: .green,
                          title: lang.t("layout.restore"), subtitle: lang.t("layout.restoreSub"),
                          isOn: $settings.restoreSession)
            }
        }
    }
}

// MARK: - Site settings

struct SiteSettingsView: View {
    @ObservedObject var model: BrowserModel
    @ObservedObject private var settings = SettingsStore.shared
    @ObservedObject private var lang = LanguageManager.shared
    @State private var clearing = false
    @State private var showClearConfirm = false
    @State private var cleared = false

    var body: some View {
        ScreenShell(title: lang.t("screen.site.title")) {
            CardSection(title: lang.t("site.engine"), subtitle: lang.t("site.engineSub")) {
                ForEach(BrowserModel.engines, id: \.self) { engine in
                    OptionRow(icon: "magnifyingglass", title: engineName(engine),
                              subtitle: engineSub(engine),
                              isSelected: model.searchEngine == engine) {
                        model.searchEngine = engine
                    }
                    if engine != BrowserModel.engines.last {
                        Divider().overlay(Color.black.opacity(0.4))
                    }
                }
            }

            CardSection(title: lang.t("site.behaviour")) {
                ToggleRow(icon: "curlybraces", color: .yellow,
                          title: lang.t("site.js"), subtitle: lang.t("site.jsSub"),
                          isOn: $settings.jsEnabled)
                Divider().overlay(Color.black.opacity(0.4))
                ToggleRow(icon: "rectangle.on.rectangle.angled", color: .orange,
                          title: lang.t("site.popups"), subtitle: lang.t("site.popupsSub"),
                          isOn: $settings.blockPopups)
                Divider().overlay(Color.black.opacity(0.4))
                ToggleRow(icon: "plus.square.on.square", color: .blue,
                          title: lang.t("site.newTab"), subtitle: lang.t("site.newTabSub"),
                          isOn: $settings.openLinksInNewTab)
            }

            CardSection(title: lang.t("site.data"), subtitle: lang.t("site.dataSub")) {
                Button {
                    showClearConfirm = true
                } label: {
                    HStack(spacing: 14) {
                        Image(systemName: clearing ? "arrow.triangle.2.circlepath" : "trash.fill")
                            .font(.system(size: 15))
                            .foregroundColor(.white)
                            .frame(width: 32, height: 32)
                            .background(cleared ? .green : .red)
                            .cornerRadius(8)
                        Text(cleared ? lang.t("site.cleared") : lang.t("site.clear"))
                            .font(.app(15))
                            .fontWeight(.semibold)
                            .foregroundColor(cleared ? settings.accent : .white)
                        Spacer()
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 12)
                }
                .buttonStyle(.plain)
                .disabled(clearing)
            }
        }
        .confirmationDialog(lang.t("site.clearConfirm"),
                            isPresented: $showClearConfirm, titleVisibility: .visible) {
            Button(lang.t("site.clear"), role: .destructive) {
                clearing = true
                model.clearAllWebsiteData {
                    clearing = false
                    cleared = true
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) { cleared = false }
                }
            }
            Button(lang.t("common.skip"), role: .cancel) {}
        }
    }

    private func engineName(_ id: String) -> String {
        switch id {
        case "google": return "Google"
        case "bing": return "Bing"
        case "ecosia": return "Ecosia"
        default: return "DuckDuckGo"
        }
    }

    private func engineSub(_ id: String) -> String {
        switch id {
        case "google": return lang.t("ob.search.googleSub")
        case "bing": return lang.t("ob.search.bingSub")
        case "ecosia": return lang.t("ob.search.ecosiaSub")
        default: return lang.t("ob.search.ddgSub")
        }
    }
}

// MARK: - Web apps & PWA

struct PWASettingsView: View {
    @ObservedObject var model: BrowserModel
    @ObservedObject private var store = WebAppStore.shared
    @ObservedObject private var settings = SettingsStore.shared
    @ObservedObject private var lang = LanguageManager.shared

    var body: some View {
        ScreenShell(title: lang.t("screen.pwa.title")) {
            CardSection(title: lang.t("pwa.current")) {
                VStack(spacing: 12) {
                    HStack(spacing: 10) {
                        Image(systemName: "globe")
                            .foregroundColor(settings.accent)
                        Text(model.currentUrl)
                            .font(.app(13))
                            .foregroundColor(.white)
                            .lineLimit(1)
                        Spacer()
                    }
                    .padding(12)
                    .background(Color(UIColor(white: 0.13, alpha: 1)))
                    .cornerRadius(12)

                    HStack(spacing: 12) {
                        PrimaryButton(title: lang.t("pwa.add"), icon: "plus") {
                            store.add(name: model.title.isEmpty ? host(of: model.currentUrl) : model.title,
                                      url: model.currentUrl)
                        }
                        if let url = URL(string: model.currentUrl) {
                            ShareLink(item: url) {
                                HStack(spacing: 8) {
                                    Image(systemName: "square.and.arrow.up")
                                    Text(lang.t("pwa.share")).font(.app(15)).fontWeight(.semibold)
                                }
                                .foregroundColor(.black)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 14)
                                .background(settings.accent)
                                .cornerRadius(14)
                            }
                        }
                    }

                    InfoRow(icon: "info.circle", color: .gray, text: lang.t("pwa.note"))
                }
                .padding(12)
            }

            CardSection(title: lang.t("pwa.installed")) {
                if store.apps.isEmpty {
                    EmptyState(icon: "square.grid.2x2", title: lang.t("pwa.empty"))
                } else {
                    ForEach(store.apps) { app in
                        HStack(spacing: 12) {
                            Button {
                                open(app)
                            } label: {
                                HStack(spacing: 12) {
                                    Image(systemName: app.symbol)
                                        .font(.system(size: 15))
                                        .foregroundColor(.white)
                                        .frame(width: 32, height: 32)
                                        .background(settings.accent)
                                        .cornerRadius(8)
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(app.name)
                                            .font(.app(15))
                                            .fontWeight(.semibold)
                                            .foregroundColor(.white)
                                            .lineLimit(1)
                                        Text(app.url)
                                            .font(.app(11))
                                            .foregroundColor(Color(UIColor.systemGray2))
                                            .lineLimit(1)
                                    }
                                    Spacer()
                                    Image(systemName: "chevron.right")
                                        .font(.system(size: 12, weight: .semibold))
                                        .foregroundColor(Color(UIColor.systemGray2))
                                }
                                .padding(.horizontal, 12)
                                .padding(.vertical, 10)
                                .contentShape(Rectangle())
                            }
                            .buttonStyle(.plain)

                            Button {
                                store.remove(app)
                            } label: {
                                Image(systemName: "trash")
                                    .foregroundColor(.red)
                                    .font(.system(size: 14))
                            }
                            .buttonStyle(.plain)
                        }
                        if app.id != store.apps.last?.id {
                            Divider().overlay(Color.black.opacity(0.4))
                        }
                    }
                }
            }
        }
    }

    private func open(_ app: SavedWebApp) {
        model.submit(app.url)
        model.showSettings = false
    }

    private func host(of url: String) -> String {
        URL(string: url)?.host ?? url
    }
}
