import SwiftUI

// MARK: - First-run setup flow

struct OnboardingView: View {
    @ObservedObject var model: BrowserModel
    var onFinish: () -> Void

    @ObservedObject private var lang = LanguageManager.shared
    @ObservedObject private var settings = SettingsStore.shared
    @Environment(\.scenePhase) private var scenePhase

    @State private var page = 0
    @State private var openedSettings = false
    @State private var defaultBrowserDone = false

    private let pageCount = 5

    // Design tokens instead of the old hardcoded palette.
    private var bg: Color { settings.background }
    private var card: Color { settings.cardColor }
    private var field: Color { AppColor.fill }
    private var accent: Color { settings.accent }
    private var secondary: Color { AppColor.textSecondary }

    var body: some View {
        ZStack {
            bg.ignoresSafeArea()

            VStack(spacing: 0) {
                header

                TabView(selection: $page) {
                    welcomePage.tag(0)
                    languagePage.tag(1)
                    searchPage.tag(2)
                    browserPage.tag(3)
                    donePage.tag(4)
                }
                .tabViewStyle(.page(indexDisplayMode: .never))

                footer
            }
        }
        .onChange(of: scenePhase) { phase in
            // Coming back from the Settings app counts as "handled it".
            if phase == .active && openedSettings {
                defaultBrowserDone = true
            }
        }
    }

    // MARK: Header (progress + skip)

    private var header: some View {
        VStack(spacing: Metrics.Space.sm) {
            HStack {
                Text(String(format: lang.t("ob.done.progress"), page + 1, pageCount))
                    .font(.app(TypeScale.caption))
                    .fontWeight(.medium)
                    .foregroundColor(secondary)
                Spacer()
                if page < pageCount - 1 {
                    Button(lang.t("common.skip")) { appAnimate { page = pageCount - 1 } }
                        .font(.app(TypeScale.footnote))
                        .fontWeight(.semibold)
                        .foregroundColor(secondary)
                        .frame(minHeight: Metrics.Touch.min)
                        .contentShape(Rectangle())
                }
            }

            HStack(spacing: Metrics.Space.xs) {
                ForEach(0..<pageCount, id: \.self) { index in
                    Capsule()
                        .fill(index <= page ? accent : field)
                        .frame(height: Metrics.Space.xs)
                        .accessibilityHidden(true)
                }
            }
        }
        .padding(.horizontal, Metrics.Space.xl)
        .padding(.top, Metrics.Space.md)
        .padding(.bottom, Metrics.Space.sm)
    }

    // MARK: Page 1 – Welcome

    private var welcomePage: some View {
        ScrollView {
            VStack(spacing: Metrics.Space.xl) {
                Spacer(minLength: Metrics.Space.xxl)

                RoundedRectangle(cornerRadius: Metrics.Radius.lg)
                    .fill(accent)
                    .frame(width: Metrics.Touch.min * 2, height: Metrics.Touch.min * 2)
                    .overlay(
                        RoundedRectangle(cornerRadius: Metrics.Tile.radius)
                            .fill(Color.black)
                            .frame(width: Metrics.Space.xxl, height: Metrics.Space.sm)
                    )
                    .shadow(color: accent.opacity(0.35), radius: Metrics.Space.xl, y: Metrics.Space.sm)
                    .accessibilityHidden(true)

                Text(lang.t("ob.welcome.title"))
                    .font(.app(TypeScale.title))
                    .fontWeight(.bold)
                    .foregroundColor(AppColor.textPrimary)
                    .multilineTextAlignment(.center)
                    .accessibilityAddTraits(.isHeader)

                Text(lang.t("ob.welcome.body"))
                    .font(.app(TypeScale.body))
                    .foregroundColor(secondary)
                    .multilineTextAlignment(.center)
                    .lineSpacing(Metrics.Space.xs)

                HStack(spacing: Metrics.Space.sm) {
                    Image(systemName: "clock.badge.checkmark")
                        .foregroundColor(accent)
                        .accessibilityHidden(true)
                    Text(lang.t("ob.welcome.note"))
                        .foregroundColor(secondary)
                }
                .font(.app(TypeScale.footnote))
                .padding(.horizontal, Metrics.Space.md)
                .padding(.vertical, Metrics.Space.sm)
                .background(card)
                .clipShape(RoundedRectangle(cornerRadius: Metrics.Radius.md, style: .continuous))

                Spacer(minLength: Metrics.Space.xxl)
            }
            .padding(.horizontal, Metrics.Space.xl)
            .frame(maxWidth: .infinity)
        }
    }

    // MARK: Page 2 – Language

    private var languagePage: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Metrics.Space.lg) {
                pageTitle(lang.t("ob.language.title"), subtitle: lang.t("ob.language.body"))

                ForEach(AppLanguage.allCases) { option in
                    Button {
                        appAnimate { lang.set(option) }
                    } label: {
                        HStack(spacing: Metrics.Space.md) {
                            Text(option.flag)
                                .font(.app(TypeScale.title))
                                .accessibilityHidden(true)

                            VStack(alignment: .leading, spacing: Metrics.Space.xs) {
                                Text(option.displayName(lang))
                                    .font(.app(TypeScale.callout))
                                    .fontWeight(.semibold)
                                    .foregroundColor(AppColor.textPrimary)
                                Text(option == .system
                                     ? lang.t("ob.language.systemSub")
                                     : (option.nativeName == option.displayName(lang) ? " " : option.nativeName))
                                    .font(.app(TypeScale.caption))
                                    .foregroundColor(secondary)
                            }

                            Spacer(minLength: Metrics.Space.sm)

                            Image(systemName: lang.language == option ? "checkmark.circle.fill" : "circle")
                                .foregroundColor(lang.language == option ? accent : secondary)
                                .font(.system(size: Metrics.Icon.lg))
                                .accessibilityHidden(true)
                        }
                        .padding(Metrics.Space.md)
                        .frame(minHeight: Metrics.Touch.min)
                        .background(card)
                        .clipShape(RoundedRectangle(cornerRadius: Metrics.Radius.md, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: Metrics.Radius.md, style: .continuous)
                                .stroke(lang.language == option ? accent : Color.clear, lineWidth: 1.5)
                        )
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(PressButtonStyle())
                    .accessibilityAddTraits(lang.language == option ? [.isSelected] : [])
                }
            }
            .padding(.horizontal, Metrics.Space.xl)
            .padding(.top, Metrics.Space.sm)
        }
    }

    // MARK: Page 3 – Search engine

    private var searchPage: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Metrics.Space.lg) {
                pageTitle(lang.t("ob.search.title"), subtitle: lang.t("ob.search.body"))

                ForEach(BrowserModel.engines, id: \.self) { engine in
                    Button {
                        appAnimate { model.searchEngine = engine }
                    } label: {
                        HStack(spacing: Metrics.Space.md) {
                            Text(engineInitial(engine))
                                .font(.app(TypeScale.callout))
                                .fontWeight(.bold)
                                .foregroundColor(AppColor.textPrimary)
                                .frame(width: Metrics.Tile.side, height: Metrics.Tile.side)
                                .background(accent)
                                .clipShape(RoundedRectangle(cornerRadius: Metrics.Radius.sm, style: .continuous))
                                .accessibilityHidden(true)

                            VStack(alignment: .leading, spacing: Metrics.Space.xs) {
                                Text(engineName(engine))
                                    .font(.app(TypeScale.callout))
                                    .fontWeight(.semibold)
                                    .foregroundColor(AppColor.textPrimary)
                                Text(engineSubtitle(engine))
                                    .font(.app(TypeScale.caption))
                                    .foregroundColor(secondary)
                            }

                            Spacer(minLength: Metrics.Space.sm)

                            Image(systemName: model.searchEngine == engine ? "checkmark.circle.fill" : "circle")
                                .foregroundColor(model.searchEngine == engine ? accent : secondary)
                                .font(.system(size: Metrics.Icon.lg))
                                .accessibilityHidden(true)
                        }
                        .padding(Metrics.Space.md)
                        .frame(minHeight: Metrics.Touch.min)
                        .background(card)
                        .clipShape(RoundedRectangle(cornerRadius: Metrics.Radius.md, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: Metrics.Radius.md, style: .continuous)
                                .stroke(model.searchEngine == engine ? accent : Color.clear, lineWidth: 1.5)
                        )
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(PressButtonStyle())
                    .accessibilityAddTraits(model.searchEngine == engine ? [.isSelected] : [])
                }
            }
            .padding(.horizontal, Metrics.Space.xl)
            .padding(.top, Metrics.Space.sm)
        }
    }

    // MARK: Page 4 – Default browser

    private var browserPage: some View {
        ScrollView {
            VStack(spacing: Metrics.Space.xl) {
                Spacer(minLength: Metrics.Space.lg)

                Image(systemName: "safari.fill")
                    .font(.system(size: Metrics.Icon.xl * 2))
                    .foregroundColor(accent)
                    .frame(width: Metrics.Touch.min * 2.5, height: Metrics.Touch.min * 2.5)
                    .background(card)
                    .clipShape(RoundedRectangle(cornerRadius: Metrics.Radius.lg, style: .continuous))
                    .accessibilityHidden(true)

                Text(lang.t("ob.browser.title"))
                    .font(.app(TypeScale.title))
                    .fontWeight(.bold)
                    .foregroundColor(AppColor.textPrimary)
                    .multilineTextAlignment(.center)
                    .accessibilityAddTraits(.isHeader)

                Text(lang.t("ob.browser.body"))
                    .font(.app(TypeScale.body))
                    .foregroundColor(secondary)
                    .multilineTextAlignment(.center)
                    .lineSpacing(Metrics.Space.xs)

                VStack(alignment: .leading, spacing: Metrics.Space.sm) {
                    Label {
                        Text(lang.t("ob.browser.hint"))
                            .font(.app(TypeScale.footnote))
                            .foregroundColor(AppColor.textPrimary)
                    } icon: {
                        Image(systemName: "arrow.up.forward.app.fill")
                            .foregroundColor(accent)
                            .accessibilityHidden(true)
                    }
                    Text(lang.t("ob.browser.returns"))
                        .font(.app(TypeScale.caption))
                        .foregroundColor(secondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(Metrics.Space.md)
                .background(card)
                .clipShape(RoundedRectangle(cornerRadius: Metrics.Radius.md, style: .continuous))

                Spacer(minLength: Metrics.Space.lg)
            }
            .padding(.horizontal, Metrics.Space.xl)
        }
    }

    // MARK: Page 5 – Done

    private var donePage: some View {
        ScrollView {
            VStack(spacing: Metrics.Space.xl) {
                Spacer(minLength: Metrics.Space.xl)

                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: Metrics.Icon.xl * 2))
                    .foregroundColor(accent)
                    .accessibilityHidden(true)

                Text(lang.t("ob.done.title"))
                    .font(.app(TypeScale.title))
                    .fontWeight(.bold)
                    .foregroundColor(AppColor.textPrimary)
                    .accessibilityAddTraits(.isHeader)

                Text(lang.t("ob.done.body"))
                    .font(.app(TypeScale.body))
                    .foregroundColor(secondary)
                    .multilineTextAlignment(.center)

                VStack(spacing: 0) {
                    summaryRow(
                        icon: "globe",
                        title: lang.t("ob.done.language"),
                        value: LanguageManager.shared.effective.displayName(lang),
                        flag: LanguageManager.shared.effective.flag
                    )
                    Divider().overlay(AppColor.separator)
                    summaryRow(
                        icon: "magnifyingglass",
                        title: lang.t("ob.done.search"),
                        value: engineName(model.searchEngine),
                        flag: nil
                    )
                    Divider().overlay(AppColor.separator)
                    summaryRow(
                        icon: "safari",
                        title: lang.t("ob.done.defaultBrowser"),
                        value: defaultBrowserDone ? "" : lang.t("ob.done.notSet"),
                        flag: nil,
                        ok: defaultBrowserDone
                    )
                }
                .padding(.horizontal, Metrics.Space.xs)
                .background(card)
                .clipShape(RoundedRectangle(cornerRadius: Metrics.Radius.md, style: .continuous))

                Spacer(minLength: Metrics.Space.xl)
            }
            .padding(.horizontal, Metrics.Space.xl)
        }
    }

    private func summaryRow(icon: String, title: String, value: String, flag: String?, ok: Bool = false) -> some View {
        HStack(spacing: Metrics.Space.md) {
            Image(systemName: icon)
                .font(.system(size: Metrics.Icon.sm, weight: .medium))
                .foregroundColor(.white)
                .frame(width: Metrics.Tile.side, height: Metrics.Tile.side)
                .background(field)
                .clipShape(RoundedRectangle(cornerRadius: Metrics.Tile.radius, style: .continuous))
                .accessibilityHidden(true)

            Text(title)
                .font(.app(TypeScale.footnote))
                .fontWeight(.medium)
                .foregroundColor(AppColor.textPrimary)

            Spacer(minLength: Metrics.Space.sm)

            if let flag {
                Text(flag)
                    .font(.app(TypeScale.callout))
                    .accessibilityHidden(true)
            }
            if ok {
                // State marker; VoiceOver announces it because the value is
                // empty on this row when the browser is already set.
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: Metrics.Icon.md, weight: .semibold))
                    .foregroundColor(accent)
                    .accessibilityLabel(lang.t("settings.done"))
            }
            if !value.isEmpty {
                Text(value)
                    .font(.app(TypeScale.footnote))
                    .foregroundColor(ok ? accent : secondary)
            }
        }
        .padding(.vertical, Metrics.Space.md)
        .padding(.horizontal, Metrics.Space.sm)
        .frame(minHeight: Metrics.Touch.min, alignment: .leading)
    }

    // MARK: Footer

    private var footer: some View {
        VStack(spacing: Metrics.Space.md) {
            switch page {
            case 3:
                PrimaryButton(title: lang.t("ob.browser.cta")) {
                    openedSettings = true
                    if let url = URL(string: UIApplication.openSettingsURLString) {
                        UIApplication.shared.open(url)
                    }
                }
                SecondaryButton(title: lang.t("common.later")) { appAnimate { page = 4 } }
            case 4:
                PrimaryButton(title: lang.t("ob.done.cta")) { onFinish() }
            default:
                PrimaryButton(title: page == 0 ? lang.t("ob.welcome.cta") : lang.t("common.continue")) {
                    appAnimate { page += 1 }
                }
                if page > 0 {
                    SecondaryButton(title: lang.t("common.back")) { appAnimate { page -= 1 } }
                }
            }
        }
        .padding(.horizontal, Metrics.Space.xl)
        .padding(.top, Metrics.Space.md)
        .padding(.bottom, Metrics.Space.lg)
        .background(bg)
    }

    // MARK: Pieces

    private func pageTitle(_ title: String, subtitle: String) -> some View {
        VStack(alignment: .leading, spacing: Metrics.Space.sm) {
            Text(title)
                .font(.app(TypeScale.title))
                .fontWeight(.bold)
                .foregroundColor(AppColor.textPrimary)
                .accessibilityAddTraits(.isHeader)
            Text(subtitle)
                .font(.app(TypeScale.footnote))
                .foregroundColor(secondary)
                .lineSpacing(Metrics.Space.xs)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(.top, Metrics.Space.xs)
    }

    // MARK: Search engine labels

    private func engineName(_ id: String) -> String {
        switch id {
        case "google": return "Google"
        case "bing": return "Bing"
        case "ecosia": return "Ecosia"
        default: return "DuckDuckGo"
        }
    }

    private func engineSubtitle(_ id: String) -> String {
        switch id {
        case "google": return lang.t("ob.search.googleSub")
        case "bing": return lang.t("ob.search.bingSub")
        case "ecosia": return lang.t("ob.search.ecosiaSub")
        default: return lang.t("ob.search.ddgSub")
        }
    }

    private func engineInitial(_ engine: String) -> String {
        String(engineName(engine).prefix(1))
    }
}
