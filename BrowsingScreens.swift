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
                        .font(.app(TypeScale.title))
                        .fontWeight(.bold)
                        .foregroundColor(AppColor.textPrimary)
                        .accessibilityAddTraits(.isHeader)
                    Spacer()
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: Metrics.Icon.xl))
                            .foregroundColor(AppColor.textTertiary)
                            .frame(minWidth: Metrics.Touch.min, minHeight: Metrics.Touch.min)
                            .contentShape(Rectangle())
                    }
                    .buttonStyle(PressButtonStyle())
                    .accessibilityLabel(lang.t("settings.close"))
                }
                .padding(.horizontal, Metrics.Space.lg)
                .padding(.top, Metrics.Space.lg)
                .padding(.bottom, Metrics.Space.md)

                ScrollView {
                    VStack(spacing: Metrics.Space.md) {
                        ForEach(model.tabs) { tab in
                            Button {
                                model.selectTab(tab.id)
                                dismiss()
                            } label: {
                                tabRow(tab)
                            }
                            .buttonStyle(PressButtonStyle())
                        }

                        // ── Bookmarks ────────────────────────────────
                        if !model.bookmarks.isEmpty {
                            Text(lang.t("tabs.bookmarks"))
                                .font(.app(TypeScale.caption))
                                .fontWeight(.semibold)
                                .foregroundColor(AppColor.textSecondary)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(.top, Metrics.Space.md)
                                .accessibilityAddTraits(.isHeader)

                            ForEach(model.bookmarks, id: \.self) { url in
                                bookmarkRow(url)
                            }
                        }
                    }
                    .padding(.horizontal, Metrics.Space.lg)
                    .padding(.bottom, Metrics.Space.lg)
                }

                HStack(spacing: Metrics.Space.md) {
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
                .padding(.horizontal, Metrics.Space.lg)
                .padding(.bottom, Metrics.Space.xl)
                .padding(.top, Metrics.Space.sm)
            }
        }
        .confirmationDialog(lang.t("tabs.confirmClose"),
                            isPresented: $confirmCloseAll, titleVisibility: .visible) {
            Button(lang.t("tabs.closeAll"), role: .destructive) { closeAll() }
            Button(lang.t("common.skip"), role: .cancel) {}
        }
    }

    private func tabRow(_ tab: BrowserTab) -> some View {
        HStack(spacing: Metrics.Space.md) {
            RoundedRectangle(cornerRadius: Metrics.Tile.radius)
                .fill(tab.id == model.activeTabID ? settings.accent : AppColor.fill)
                .frame(width: Metrics.Tile.side, height: Metrics.Tile.side)
                .overlay(Image(systemName: tab.url == "about:blank" ? "plus" : "globe")
                    .font(.system(size: Metrics.Icon.md, weight: .medium))
                    .foregroundColor(AppColor.textPrimary))
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: Metrics.Space.xs) {
                Text(tab.title.isEmpty ? lang.t("tabs.untitled") : tab.title)
                    .font(.app(TypeScale.body))
                    .fontWeight(.semibold)
                    .foregroundColor(AppColor.textPrimary)
                    .lineLimit(1)
                Text(tab.url)
                    .font(.app(TypeScale.caption))
                    .foregroundColor(AppColor.textSecondary)
                    .lineLimit(1)
            }
            Spacer(minLength: Metrics.Space.sm)

            if model.tabs.count > 1 {
                Button {
                    model.closeTab(tab.id)
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: Metrics.Icon.lg, weight: .medium))
                        .foregroundColor(AppColor.textSecondary)
                        .frame(minWidth: Metrics.Touch.min, minHeight: Metrics.Touch.min)
                        .contentShape(Rectangle())
                }
                .buttonStyle(PressButtonStyle())
                .accessibilityLabel(lang.t("settings.close"))
            }
        }
        .padding(Metrics.Space.md)
        .background(settings.cardColor)
        .clipShape(RoundedRectangle(cornerRadius: Metrics.Radius.md, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: Metrics.Radius.md, style: .continuous)
            .stroke(tab.id == model.activeTabID ? settings.accent : Color.clear, lineWidth: 1.5))
        .frame(minHeight: Metrics.Touch.min)
        .contentShape(Rectangle())
    }

    private func bookmarkRow(_ url: String) -> some View {
        HStack(spacing: Metrics.Space.md) {
            RoundedRectangle(cornerRadius: Metrics.Tile.radius)
                .fill(AppColor.fill)
                .frame(width: Metrics.Tile.side, height: Metrics.Tile.side)
                .overlay(Image(systemName: "star.fill")
                    .font(.system(size: Metrics.Icon.md, weight: .medium))
                    .foregroundColor(settings.accent))
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: Metrics.Space.xs) {
                Text(URL(string: url)?.host ?? url)
                    .font(.app(TypeScale.body))
                    .fontWeight(.semibold)
                    .foregroundColor(AppColor.textPrimary)
                    .lineLimit(1)
                Text(url)
                    .font(.app(TypeScale.micro))
                    .foregroundColor(AppColor.textSecondary)
                    .lineLimit(1)
            }
            Spacer(minLength: Metrics.Space.sm)

            // Remove from bookmarks (opening the page = tapping the row).
            Button {
                model.toggleBookmark(url)
            } label: {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: Metrics.Icon.lg, weight: .medium))
                    .foregroundColor(AppColor.textSecondary)
                    .frame(minWidth: Metrics.Touch.min, minHeight: Metrics.Touch.min)
                    .contentShape(Rectangle())
            }
            .buttonStyle(PressButtonStyle())
            .accessibilityLabel(lang.t("common.remove"))
        }
        .padding(Metrics.Space.md)
        .background(settings.cardColor)
        .clipShape(RoundedRectangle(cornerRadius: Metrics.Radius.md, style: .continuous))
        .frame(minHeight: Metrics.Touch.min)
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
                            HStack(spacing: Metrics.Space.md) {
                                Image(systemName: tab.id == model.activeTabID ? "record.circle" : "circle")
                                    .font(.system(size: Metrics.Icon.md, weight: .medium))
                                    .foregroundColor(tab.id == model.activeTabID ? settings.accent
                                                     : AppColor.textTertiary)
                                    .accessibilityHidden(true)
                                VStack(alignment: .leading, spacing: Metrics.Space.xs) {
                                    Text(tab.title.isEmpty ? lang.t("tabs.untitled") : tab.title)
                                        .font(.app(TypeScale.body))
                                        .fontWeight(.medium)
                                        .foregroundColor(AppColor.textPrimary)
                                        .lineLimit(1)
                                    Text(tab.url)
                                        .font(.app(TypeScale.micro))
                                        .foregroundColor(AppColor.textSecondary)
                                        .lineLimit(1)
                                }
                                Spacer(minLength: Metrics.Space.sm)
                                Button {
                                    model.closeTab(tab.id)
                                } label: {
                                    Image(systemName: "xmark.circle.fill")
                                        .font(.system(size: Metrics.Icon.md, weight: .medium))
                                        .foregroundColor(.red)
                                        .frame(minWidth: Metrics.Touch.min, minHeight: Metrics.Touch.min)
                                        .contentShape(Rectangle())
                                }
                                .buttonStyle(PressButtonStyle())
                                .accessibilityLabel(lang.t("settings.close"))
                            }
                            .padding(.horizontal, Metrics.Space.md)
                            .padding(.vertical, Metrics.Space.sm)
                            .frame(minHeight: Metrics.Touch.min)
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(PressButtonStyle())
                        if index < model.tabs.count - 1 {
                            Divider().overlay(AppColor.separator)
                        }
                    }
                }
            }

            CardSection(title: lang.t("layout.tabs")) {
                ToggleRow(icon: "square.stack.3d.up.fill", color: .cyan,
                          title: lang.t("layout.tabCount"), subtitle: lang.t("layout.tabCountSub"),
                          isOn: $settings.showTabCount)
                Divider().overlay(AppColor.separator)
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
                        Divider().overlay(AppColor.separator)
                    }
                }
            }

            CardSection(title: lang.t("site.behaviour")) {
                ToggleRow(icon: "curlybraces", color: .yellow,
                          title: lang.t("site.js"), subtitle: lang.t("site.jsSub"),
                          isOn: $settings.jsEnabled)
                Divider().overlay(AppColor.separator)
                ToggleRow(icon: "rectangle.on.rectangle.angled", color: .orange,
                          title: lang.t("site.popups"), subtitle: lang.t("site.popupsSub"),
                          isOn: $settings.blockPopups)
                Divider().overlay(AppColor.separator)
                ToggleRow(icon: "plus.square.on.square", color: .blue,
                          title: lang.t("site.newTab"), subtitle: lang.t("site.newTabSub"),
                          isOn: $settings.openLinksInNewTab)
            }

            CardSection(title: lang.t("site.data"), subtitle: lang.t("site.dataSub")) {
                Button {
                    showClearConfirm = true
                } label: {
                    HStack(spacing: Metrics.Space.md) {
                        Image(systemName: clearing ? "arrow.triangle.2.circlepath" : "trash.fill")
                            .font(.system(size: Metrics.Icon.md, weight: .medium))
                            .foregroundColor(AppColor.textPrimary)
                            .frame(width: Metrics.Tile.side, height: Metrics.Tile.side)
                            .background(cleared ? Color.green : Color.red)
                            .clipShape(RoundedRectangle(cornerRadius: Metrics.Tile.radius, style: .continuous))
                            .accessibilityHidden(true)
                        Text(cleared ? lang.t("site.cleared") : lang.t("site.clear"))
                            .font(.app(TypeScale.body))
                            .fontWeight(.semibold)
                            .foregroundColor(cleared ? settings.accent : AppColor.textPrimary)
                        Spacer(minLength: Metrics.Space.sm)
                    }
                    .padding(.horizontal, Metrics.Space.md)
                    .padding(.vertical, Metrics.Space.md)
                    .frame(minHeight: Metrics.Touch.min, alignment: .leading)
                    .contentShape(Rectangle())
                }
                .buttonStyle(PressButtonStyle())
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
                VStack(spacing: Metrics.Space.md) {
                    HStack(spacing: Metrics.Space.md) {
                        Image(systemName: "globe")
                            .font(.system(size: Metrics.Icon.md, weight: .medium))
                            .foregroundColor(settings.accent)
                            .accessibilityHidden(true)
                        Text(model.currentUrl)
                            .font(.app(TypeScale.footnote))
                            .foregroundColor(AppColor.textPrimary)
                            .lineLimit(1)
                        Spacer()
                    }
                    .padding(Metrics.Space.md)
                    .background(AppColor.fill)
                    .clipShape(RoundedRectangle(cornerRadius: Metrics.Radius.md, style: .continuous))

                    HStack(spacing: Metrics.Space.md) {
                        PrimaryButton(title: lang.t("pwa.add"), icon: "plus") {
                            store.add(name: model.title.isEmpty ? host(of: model.currentUrl) : model.title,
                                      url: model.currentUrl)
                        }
                        if let url = URL(string: model.currentUrl) {
                            ShareLink(item: url) {
                                HStack(spacing: Metrics.Space.sm) {
                                    Image(systemName: "square.and.arrow.up")
                                        .font(.system(size: Metrics.Icon.md, weight: .semibold))
                                        .accessibilityHidden(true)
                                    Text(lang.t("pwa.share"))
                                        .font(.app(TypeScale.callout))
                                        .fontWeight(.semibold)
                                }
                                .foregroundColor(.black)
                                .frame(maxWidth: .infinity)
                                .frame(minHeight: Metrics.Touch.min)
                                .padding(.vertical, Metrics.Space.sm)
                                .background(settings.accent)
                                .clipShape(RoundedRectangle(cornerRadius: Metrics.Radius.md, style: .continuous))
                            }
                        }
                    }

                    InfoRow(icon: "info.circle", color: AppColor.textTertiary, text: lang.t("pwa.note"))
                }
                .padding(Metrics.Space.md)
            }

            CardSection(title: lang.t("pwa.installed")) {
                if store.apps.isEmpty {
                    EmptyState(icon: "square.grid.2x2", title: lang.t("pwa.empty"))
                } else {
                    ForEach(store.apps) { app in
                        HStack(spacing: Metrics.Space.md) {
                            Button {
                                open(app)
                            } label: {
                                HStack(spacing: Metrics.Space.md) {
                                    Image(systemName: app.symbol)
                                        .font(.system(size: Metrics.Icon.md, weight: .medium))
                                        .foregroundColor(AppColor.textPrimary)
                                        .frame(width: Metrics.Tile.side, height: Metrics.Tile.side)
                                        .background(settings.accent)
                                        .clipShape(RoundedRectangle(cornerRadius: Metrics.Tile.radius, style: .continuous))
                                        .accessibilityHidden(true)
                                    VStack(alignment: .leading, spacing: Metrics.Space.xs) {
                                        Text(app.name)
                                            .font(.app(TypeScale.body))
                                            .fontWeight(.semibold)
                                            .foregroundColor(AppColor.textPrimary)
                                            .lineLimit(1)
                                        Text(app.url)
                                            .font(.app(TypeScale.micro))
                                            .foregroundColor(AppColor.textSecondary)
                                            .lineLimit(1)
                                    }
                                    Spacer(minLength: Metrics.Space.sm)
                                    Image(systemName: "chevron.right")
                                        .font(.system(size: Metrics.Icon.sm, weight: .semibold))
                                        .foregroundColor(AppColor.textTertiary)
                                        .accessibilityHidden(true)
                                }
                                .padding(.horizontal, Metrics.Space.md)
                                .padding(.vertical, Metrics.Space.sm)
                                .frame(minHeight: Metrics.Touch.min)
                                .contentShape(Rectangle())
                            }
                            .buttonStyle(PressButtonStyle())

                            Button {
                                store.remove(app)
                            } label: {
                                Image(systemName: "trash")
                                    .font(.system(size: Metrics.Icon.md, weight: .medium))
                                    .foregroundColor(.red)
                                    .frame(minWidth: Metrics.Touch.min, minHeight: Metrics.Touch.min)
                                    .contentShape(Rectangle())
                            }
                            .buttonStyle(PressButtonStyle())
                            .accessibilityLabel(lang.t("common.remove"))
                        }
                        if app.id != store.apps.last?.id {
                            Divider().overlay(AppColor.separator)
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
