import SwiftUI

struct SettingsView: View {
    @Environment(\.dismiss) var dismiss
    @ObservedObject var model: BrowserModel
    @ObservedObject private var lang = LanguageManager.shared
    @ObservedObject private var settings = SettingsStore.shared

    var body: some View {
        NavigationStack {
            ZStack {
                settings.backgroundView()

                List {
                    // ── PERSONALIZARE ──────────────────────────────────────────────
                    Section(header: sectionHeader(lang.t("settings.section.personalization"))) {
                        card(languageRow)

                        card(
                            NavigationLink(destination: ThemeSettingsView()) {
                                NavRow(icon: "paintpalette.fill", color: .purple,
                                       title: lang.t("row.theme.title"), subtitle: lang.t("row.theme.sub"),
                                       value: accentName,
                                       showsChevron: false)
                            }
                        )

                        card(
                            NavigationLink(destination: LayoutSettingsView()) {
                                NavRow(icon: "slider.horizontal.3", color: .blue,
                                       title: lang.t("row.layout.title"), subtitle: lang.t("row.layout.sub"),
                                       value: settings.addressBarTop ? lang.t("layout.barTop")
                                                                    : lang.t("layout.barBottom"),
                                       showsChevron: false)
                            }
                        )

                        card(
                            NavigationLink(destination: WallpaperSettingsView()) {
                                NavRow(icon: "photo.fill", color: .orange,
                                       title: lang.t("row.wallpapers.title"), subtitle: lang.t("row.wallpapers.sub"),
                                       value: wallpaperName,
                                       showsChevron: false)
                            }
                        )

                        card(
                            NavigationLink(destination: AccessibilitySettingsView()) {
                                NavRow(icon: "accessibility", color: .green,
                                       title: lang.t("row.accessibility.title"), subtitle: lang.t("row.accessibility.sub"),
                                       value: "\(Int(settings.textScale * 100))%",
                                       showsChevron: false)
                            }
                        )
                    }

                    // ── NAVIGARE WEB ────────────────────────────────────────────────
                    Section(header: sectionHeader(lang.t("settings.section.navigation"))) {
                        card(
                            NavigationLink(destination: TabsSettingsView(model: model)) {
                                NavRow(icon: "square.stack.3d.up.fill", color: .cyan,
                                       title: lang.t("row.tabs.title"), subtitle: lang.t("row.tabs.sub"),
                                       value: "\(model.tabs.count)",
                                       showsChevron: false)
                            }
                        )

                        card(
                            NavigationLink(destination: SiteSettingsView(model: model)) {
                                NavRow(icon: "globe", color: .teal,
                                       title: lang.t("row.sites.title"), subtitle: lang.t("row.sites.sub"),
                                       value: engineName,
                                       showsChevron: false)
                            }
                        )

                        card(
                            NavigationLink(destination: PWASettingsView(model: model)) {
                                NavRow(icon: "square.grid.2x2.fill", color: .pink,
                                       title: lang.t("row.pwa.title"), subtitle: lang.t("row.pwa.sub"),
                                       value: "\(webApps.apps.count)",
                                       showsChevron: false)
                            }
                        )
                    }

                    // ── CONFIDENȚIALITATE ȘI SECURITATE ─────────────────────────────
                    Section(header: sectionHeader(lang.t("settings.section.privacy"))) {
                        card(
                            NavigationLink(destination: PrivacySettingsView(model: model)) {
                                NavRow(icon: "shield.fill", color: settings.accent,
                                       title: lang.t("row.privacy.title"), subtitle: lang.t("row.privacy.sub"),
                                       value: settings.blockAds ? lang.t("privacy.on") : lang.t("privacy.off"),
                                       showsChevron: false)
                            }
                        )

                        card(
                            NavigationLink(destination: PasswordsView()) {
                                NavRow(icon: "key.fill", color: .yellow,
                                       title: lang.t("row.passwords.title"), subtitle: lang.t("row.passwords.sub"),
                                       value: "\(passwords.items.count)",
                                       showsChevron: false)
                            }
                        )

                        card(
                            NavigationLink(destination: VaultView()) {
                                NavRow(icon: "lock.shield.fill", color: .red,
                                       title: lang.t("row.vault.title"), subtitle: lang.t("row.vault.sub"),
                                       value: vault.isUnlocked ? lang.t("vault.unlocked") : lang.t("vault.lockedShort"),
                                       showsChevron: false)
                            }
                        )

                        card(
                            NavigationLink(destination: PrivacyHubView(model: model)) {
                                NavRow(icon: "network", color: .indigo,
                                       title: lang.t("row.hub.title"), subtitle: lang.t("row.hub.sub"),
                                       showsChevron: false)
                            }
                        )
                    }

                    // ── REȚEA ──────────────────────────────────────────────────────
                    Section(header: sectionHeader(lang.t("settings.section.network"))) {
                        card(
                            NavigationLink(destination: NetworkMonitorView()) {
                                NavRow(icon: "waveform.path.ecg", color: .orange,
                                       title: lang.t("row.monitor.title"),
                                       subtitle: lang.t("row.monitor.sub"),
                                       value: "\(requests.entries.count)",
                                       showsChevron: false)
                            }
                            // Anchor for `--lb-scroll` in the screenshot harness.
                            .id("settings.network")
                        )
                    }

                    // ── DESPRE ──────────────────────────────────────────────────────
                    Section(header: sectionHeader(lang.t("settings.section.about"))) {
                        card(defaultBrowserRow)

                        card(
                            HStack(spacing: Metrics.Space.md) {
                                Image(systemName: "info.circle.fill")
                                    .foregroundColor(AppColor.textTertiary)
                                    .frame(width: Metrics.Icon.lg)
                                    .accessibilityHidden(true)
                                Text(lang.t("settings.version"))
                                    .font(.app(TypeScale.body))
                                    .foregroundColor(AppColor.textPrimary)
                                Spacer()
                                Text(appVersion)
                                    .font(.app(TypeScale.body))
                                    .foregroundColor(AppColor.textTertiary)
                                    .monospacedDigit()
                            }
                            .padding(.vertical, Metrics.Space.xs)
                        )

                        card(
                            HStack(spacing: Metrics.Space.md) {
                                Image(systemName: "c.circle.fill")
                                    .foregroundColor(AppColor.textTertiary)
                                    .frame(width: Metrics.Icon.lg)
                                    .accessibilityHidden(true)
                                Text(lang.t("settings.copyright"))
                                    .font(.app(TypeScale.body))
                                    .foregroundColor(AppColor.textPrimary)
                                Spacer()
                                Text("© 2026 Line Inc.")
                                    .font(.app(TypeScale.body))
                                    .foregroundColor(AppColor.textTertiary)
                            }
                            .padding(.vertical, Metrics.Space.xs)
                        )

                        card(
                            Button(action: {
                                if let url = URL(string: "https://lineinc.ro") {
                                    UIApplication.shared.open(url)
                                }
                            }) {
                                NavRow(icon: "link", color: .green,
                                       title: lang.t("row.website.title"),
                                       subtitle: lang.t("row.website.sub"),
                                       value: nil)
                            }
                        )
                    }
                }
                .scrollContentBackground(.hidden)
            }
            .navigationTitle(lang.t("settings.title"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(lang.t("settings.close")) {
                        dismiss()
                    }
                    .foregroundColor(settings.accent)
                }
            }
        }
        .environment(\.colorScheme, .dark)
    }

    // MARK: - Row helpers

    /// Applies the card background to a list row in one call.
    private func card<Content: View>(_ content: Content) -> some View {
        content.listRowBackground(settings.cardColor)
    }

    private func sectionHeader(_ title: String) -> some View {
        Text(title)
            .foregroundColor(settings.accent)
            .font(.app(TypeScale.caption))
            .fontWeight(.bold)
            .textCase(.uppercase)
            .accessibilityAddTraits(.isHeader)
    }

    // MARK: - Language picker

    private var languageRow: some View {
        Menu {
            ForEach(AppLanguage.allCases) { option in
                Button {
                    lang.set(option)
                } label: {
                    if lang.language == option {
                        Label(option.displayName(lang), systemImage: "checkmark")
                    } else {
                        Text(option.displayName(lang))
                    }
                }
            }
        } label: {
            NavRow(icon: "globe", color: .blue,
                   title: lang.t("settings.language"),
                   subtitle: lang.language == .system ? lang.t("ob.language.systemSub") : nil,
                   value: lang.language.displayName(lang))
        }
        .accessibilityLabel(lang.t("settings.language"))
        .accessibilityValue(lang.language.displayName(lang))
    }

    // MARK: - Default browser shortcut

    private var defaultBrowserRow: some View {
        Button(action: {
            if let url = URL(string: UIApplication.openSettingsURLString) {
                UIApplication.shared.open(url)
            }
        }) {
            NavRow(icon: "safari", color: settings.accent,
                   title: lang.t("settings.defaultBrowser"),
                   subtitle: lang.t("settings.defaultBrowserSub"))
        }
    }

    // MARK: - Live values

    @ObservedObject private var passwords = PasswordStore.shared
    @ObservedObject private var vault = VaultStore.shared
    @ObservedObject private var webApps = WebAppStore.shared
    @ObservedObject private var requests = RequestStore.shared

    private var appVersion: String {
        Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "1.0.0"
    }

    private var accentName: String {
        switch settings.accentHex {
        case 0x34C759: return "Green"
        case 0x0A84FF: return "Blue"
        case 0x5E5CE6: return "Indigo"
        case 0xBF5AF2: return "Purple"
        case 0xFF375F: return "Pink"
        case 0xFF453A: return "Red"
        case 0xFF9F0A: return "Orange"
        case 0xFFD60A: return "Yellow"
        case 0x64D2FF: return "Cyan"
        default: return "Gray"
        }
    }

    private var wallpaperName: String {
        settings.wallpaperID == "none" ? lang.t("wall.none") : settings.wallpaperID.capitalized
    }

    private var engineName: String {
        switch model.searchEngine {
        case "google": return "Google"
        case "bing": return "Bing"
        case "ecosia": return "Ecosia"
        default: return "DuckDuckGo"
        }
    }
}
