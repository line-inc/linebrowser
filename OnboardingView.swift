import SwiftUI

// MARK: - First-run setup flow

struct OnboardingView: View {
    @ObservedObject var model: BrowserModel
    var onFinish: () -> Void

    @ObservedObject private var lang = LanguageManager.shared
    @Environment(\.scenePhase) private var scenePhase

    @State private var page = 0
    @State private var openedSettings = false
    @State private var defaultBrowserDone = false

    private let pageCount = 5

    private let bg = Color(UIColor(red: 0.04, green: 0.05, blue: 0.06, alpha: 1))
    private let card = Color(0xFF1E2024)
    private let field = Color(0xFF2C2C2E)
    private let accent = Color(0xFF34C759)
    private let secondary = Color(UIColor.systemGray2)

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
        VStack(spacing: 12) {
            HStack {
                Text(String(format: lang.t("ob.done.progress"), page + 1, pageCount))
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(secondary)
                Spacer()
                if page < pageCount - 1 {
                    Button(lang.t("common.skip")) { appAnimate { page = pageCount - 1 } }
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(secondary)
                }
            }

            HStack(spacing: 5) {
                ForEach(0..<pageCount, id: \.self) { index in
                    Capsule()
                        .fill(index <= page ? accent : field)
                        .frame(height: 4)
                }
            }
        }
        .padding(.horizontal, 24)
        .padding(.top, 16)
        .padding(.bottom, 8)
    }

    // MARK: Page 1 – Welcome

    private var welcomePage: some View {
        ScrollView {
            VStack(spacing: 22) {
                Spacer(minLength: 30)

                RoundedRectangle(cornerRadius: 20)
                    .fill(accent)
                    .frame(width: 88, height: 88)
                    .overlay(
                        RoundedRectangle(cornerRadius: 6)
                            .fill(Color.black)
                            .frame(width: 34, height: 8)
                    )
                    .shadow(color: accent.opacity(0.35), radius: 24, y: 8)

                Text(lang.t("ob.welcome.title"))
                    .font(.system(size: 27, weight: .bold))
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)

                Text(lang.t("ob.welcome.body"))
                    .font(.system(size: 15))
                    .foregroundColor(secondary)
                    .multilineTextAlignment(.center)
                    .lineSpacing(3)

                HStack(spacing: 7) {
                    Image(systemName: "clock.badge.checkmark")
                        .foregroundColor(accent)
                    Text(lang.t("ob.welcome.note"))
                        .foregroundColor(secondary)
                }
                .font(.system(size: 13))
                .padding(.horizontal, 14)
                .padding(.vertical, 9)
                .background(card)
                .cornerRadius(12)

                Spacer(minLength: 30)
            }
            .padding(.horizontal, 28)
            .frame(maxWidth: .infinity)
        }
    }

    // MARK: Page 2 – Language

    private var languagePage: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                pageTitle(lang.t("ob.language.title"), subtitle: lang.t("ob.language.body"))

                ForEach(AppLanguage.allCases) { option in
                    Button {
                        appAnimate { lang.set(option) }
                    } label: {
                        HStack(spacing: 14) {
                            Text(option.flag)
                                .font(.system(size: 24))

                            VStack(alignment: .leading, spacing: 2) {
                                Text(option.displayName(lang))
                                    .font(.system(size: 16, weight: .semibold))
                                    .foregroundColor(.white)
                                Text(option == .system
                                     ? lang.t("ob.language.systemSub")
                                     : (option.nativeName == option.displayName(lang) ? " " : option.nativeName))
                                    .font(.system(size: 12))
                                    .foregroundColor(secondary)
                            }

                            Spacer()

                            Image(systemName: lang.language == option ? "checkmark.circle.fill" : "circle")
                                .foregroundColor(lang.language == option ? accent : secondary)
                                .font(.system(size: 20))
                        }
                        .padding(14)
                        .background(card)
                        .cornerRadius(14)
                        .overlay(
                            RoundedRectangle(cornerRadius: 14)
                                .stroke(lang.language == option ? accent : Color.clear, lineWidth: 1.5)
                        )
                    }
                    .buttonStyle(PressButtonStyle())
                }
            }
            .padding(.horizontal, 24)
            .padding(.top, 8)
        }
    }

    // MARK: Page 3 – Search engine

    private var searchPage: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                pageTitle(lang.t("ob.search.title"), subtitle: lang.t("ob.search.body"))

                ForEach(BrowserModel.engines, id: \.self) { engine in
                    Button {
                        appAnimate { model.searchEngine = engine }
                    } label: {
                        HStack(spacing: 14) {
                            Text(engineInitial(engine))
                                .font(.system(size: 16, weight: .bold))
                                .foregroundColor(.white)
                                .frame(width: 36, height: 36)
                                .background(accent)
                                .cornerRadius(10)

                            VStack(alignment: .leading, spacing: 2) {
                                Text(engineName(engine))
                                    .font(.system(size: 16, weight: .semibold))
                                    .foregroundColor(.white)
                                Text(engineSubtitle(engine))
                                    .font(.system(size: 12))
                                    .foregroundColor(secondary)
                            }

                            Spacer()

                            Image(systemName: model.searchEngine == engine ? "checkmark.circle.fill" : "circle")
                                .foregroundColor(model.searchEngine == engine ? accent : secondary)
                                .font(.system(size: 20))
                        }
                        .padding(14)
                        .background(card)
                        .cornerRadius(14)
                        .overlay(
                            RoundedRectangle(cornerRadius: 14)
                                .stroke(model.searchEngine == engine ? accent : Color.clear, lineWidth: 1.5)
                        )
                    }
                    .buttonStyle(PressButtonStyle())
                }
            }
            .padding(.horizontal, 24)
            .padding(.top, 8)
        }
    }

    // MARK: Page 4 – Default browser

    private var browserPage: some View {
        ScrollView {
            VStack(spacing: 20) {
                Spacer(minLength: 16)

                Image(systemName: "safari.fill")
                    .font(.system(size: 54))
                    .foregroundColor(accent)
                    .frame(width: 110, height: 110)
                    .background(card)
                    .cornerRadius(28)

                Text(lang.t("ob.browser.title"))
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)

                Text(lang.t("ob.browser.body"))
                    .font(.system(size: 15))
                    .foregroundColor(secondary)
                    .multilineTextAlignment(.center)
                    .lineSpacing(3)

                VStack(alignment: .leading, spacing: 8) {
                    Label {
                        Text(lang.t("ob.browser.hint"))
                            .font(.system(size: 13))
                            .foregroundColor(.white)
                    } icon: {
                        Image(systemName: "arrow.up.forward.app.fill")
                            .foregroundColor(accent)
                    }
                    Text(lang.t("ob.browser.returns"))
                        .font(.system(size: 12))
                        .foregroundColor(secondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(14)
                .background(card)
                .cornerRadius(14)

                Spacer(minLength: 16)
            }
            .padding(.horizontal, 26)
        }
    }

    // MARK: Page 5 – Done

    private var donePage: some View {
        ScrollView {
            VStack(spacing: 20) {
                Spacer(minLength: 24)

                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 64))
                    .foregroundColor(accent)

                Text(lang.t("ob.done.title"))
                    .font(.system(size: 26, weight: .bold))
                    .foregroundColor(.white)

                Text(lang.t("ob.done.body"))
                    .font(.system(size: 15))
                    .foregroundColor(secondary)
                    .multilineTextAlignment(.center)

                VStack(spacing: 0) {
                    summaryRow(
                        icon: "globe",
                        title: lang.t("ob.done.language"),
                        value: LanguageManager.shared.effective.displayName(lang),
                        flag: LanguageManager.shared.effective.flag
                    )
                    Divider().overlay(field)
                    summaryRow(
                        icon: "magnifyingglass",
                        title: lang.t("ob.done.search"),
                        value: engineName(model.searchEngine),
                        flag: nil
                    )
                    Divider().overlay(field)
                    summaryRow(
                        icon: "safari",
                        title: lang.t("ob.done.defaultBrowser"),
                        value: defaultBrowserDone ? "" : lang.t("ob.done.notSet"),
                        flag: nil,
                        ok: defaultBrowserDone
                    )
                }
                .padding(.horizontal, 6)
                .background(card)
                .cornerRadius(16)

                Spacer(minLength: 24)
            }
            .padding(.horizontal, 26)
        }
    }

    private func summaryRow(icon: String, title: String, value: String, flag: String?, ok: Bool = false) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 14))
                .foregroundColor(.white)
                .frame(width: 30, height: 30)
                .background(field)
                .cornerRadius(8)

            Text(title)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.white)

            Spacer()

            if let flag {
                Text(flag).font(.system(size: 16))
            }
            if ok {
                Image(systemName: "checkmark.circle.fill").foregroundColor(accent)
            }
            if !value.isEmpty {
                Text(value)
                    .font(.system(size: 13))
                    .foregroundColor(ok ? accent : secondary)
            }
        }
        .padding(.vertical, 12)
        .padding(.horizontal, 10)
    }

    // MARK: Footer

    private var footer: some View {
        VStack(spacing: 10) {
            switch page {
            case 3:
                primaryButton(lang.t("ob.browser.cta")) {
                    openedSettings = true
                    if let url = URL(string: UIApplication.openSettingsURLString) {
                        UIApplication.shared.open(url)
                    }
                }
                secondaryButton(lang.t("common.later")) { appAnimate { page = 4 } }
            case 4:
                primaryButton(lang.t("ob.done.cta")) { onFinish() }
            default:
                primaryButton(page == 0 ? lang.t("ob.welcome.cta") : lang.t("common.continue")) {
                    appAnimate { page += 1 }
                }
                if page > 0 {
                    secondaryButton(lang.t("common.back")) { appAnimate { page -= 1 } }
                }
            }
        }
        .padding(.horizontal, 24)
        .padding(.top, 10)
        .padding(.bottom, 14)
        .background(bg)
    }

    // MARK: Pieces

    private func pageTitle(_ title: String, subtitle: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.system(size: 24, weight: .bold))
                .foregroundColor(.white)
            Text(subtitle)
                .font(.system(size: 14))
                .foregroundColor(secondary)
                .lineSpacing(3)
        }
        .padding(.top, 6)
    }

    private func primaryButton(_ title: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(Color.black)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 15)
                .background(accent)
                .cornerRadius(14)
        }
        .buttonStyle(PressButtonStyle())
    }

    private func secondaryButton(_ title: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 15, weight: .medium))
                .foregroundColor(secondary)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 10)
        }
        .buttonStyle(PressButtonStyle())
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
