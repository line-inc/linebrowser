import SwiftUI
import WebKit

// MARK: - Built-in ad / tracker block list (Safari content rules)

enum ContentBlocker {
    static let identifier = "linebrowser.ads"

    /// One rule per domain: WebKit's content-rule regex has no `|` support,
    /// so alternatives have to be separate rules. The list itself lives in
    /// Blocklist.swift (SharedBlocklist).
    static let domains: [String] = SharedBlocklist.domains

    static var json: String {
        let rules = domains.map { domain -> String in
            let dotted = domain.replacingOccurrences(of: ".", with: "\\.")
            let pattern = "^[A-Za-z][A-Za-z0-9+.-]*://([^/]+\\.)?\(dotted)/"
            let escaped = pattern.replacingOccurrences(of: "\\", with: "\\\\")
            return "{\"trigger\":{\"url-filter\":\"\(escaped)\"},\"action\":{\"type\":\"block\"}}"
        }
        return "[" + rules.joined(separator: ",") + "]"
    }
}

// MARK: - Web view wrapper

struct WKWebViewWrapper: UIViewRepresentable {
    @ObservedObject var model: BrowserModel
    @ObservedObject var settings = SettingsStore.shared

    func makeUIView(context: Context) -> WKWebView {
        let config = WKWebViewConfiguration()
        config.allowsInlineMediaPlayback = true
        config.defaultWebpagePreferences.allowsContentJavaScript = settings.jsEnabled
        config.preferences.javaScriptCanOpenWindowsAutomatically = !settings.blockPopups

        // Network monitor: JS bridge (fetch/XHR/resource timing) → RequestStore.
        config.userContentController.addUserScript(
            WKUserScript(source: NetworkJS.source,
                         injectionTime: .atDocumentEnd,
                         forMainFrameOnly: false))
        config.userContentController.add(
            WeakScriptMessageHandler(delegate: context.coordinator), name: "lbNet")

        let webView = WKWebView(frame: .zero, configuration: config)
        webView.navigationDelegate = context.coordinator
        webView.allowsBackForwardNavigationGestures = true

        #if DEBUG
        // Screenshot mode only: dismiss cookie-consent overlays so the hero shot
        // isn't blocked. Compiled out of Release entirely.
        if ScreenshotMode.screen != nil {
            config.userContentController.addUserScript(
                WKUserScript(source: ScreenshotCleanup.js,
                             injectionTime: .atDocumentEnd,
                             forMainFrameOnly: false))
        }
        #endif

        // Real load progress → the thin line under the address bar.
        context.coordinator.progressObservation = webView.observe(\.estimatedProgress) { [weak coordinator = context.coordinator] webView, _ in
            coordinator?.parent.model.progress = webView.estimatedProgress
        }

        // Let the wallpaper show through blank / transparent pages.
        webView.isOpaque = false
        webView.backgroundColor = .clear
        webView.scrollView.backgroundColor = .clear
        applyZoom(to: webView, force: settings.forceZoom)

        context.coordinator.appliedBlockAds = settings.blockAds
        context.coordinator.appliedJS = settings.jsEnabled
        context.coordinator.applyContentRules(to: webView, enabled: settings.blockAds)

        let target = model.currentUrl
        context.coordinator.programmaticTarget = target
        if let url = URL(string: target) {
            debugLog("[WK] initial load → \(target)")
            webView.load(URLRequest(url: url))
        }
        return webView
    }

    func updateUIView(_ uiView: WKWebView, context: Context) {
        let coordinator = context.coordinator

        // ── Settings-driven configuration ────────────────────────────────
        if settings.jsEnabled != coordinator.appliedJS {
            coordinator.appliedJS = settings.jsEnabled
            uiView.configuration.defaultWebpagePreferences.allowsContentJavaScript = settings.jsEnabled
            coordinator.reloadNeeded = true
            debugLog("[WK] javaScriptEnabled → \(settings.jsEnabled)")
        }
        uiView.configuration.preferences.javaScriptCanOpenWindowsAutomatically = !settings.blockPopups
        applyZoom(to: uiView, force: settings.forceZoom)
        if settings.blockAds != coordinator.appliedBlockAds {
            coordinator.appliedBlockAds = settings.blockAds
            coordinator.applyContentRules(to: uiView, enabled: settings.blockAds)
            coordinator.reloadNeeded = true
        }
        if coordinator.reloadNeeded && !uiView.isLoading {
            coordinator.reloadNeeded = false
            debugLog("[WK] reload (settings changed)")
            uiView.reload()
        }

        // ── Navigation ───────────────────────────────────────────────────
        let target = model.currentUrl
        guard !target.isEmpty, let url = URL(string: target), url.scheme != nil else { return }

        // A *different* address was requested → any earlier failure is stale.
        if coordinator.lastTarget != target {
            coordinator.lastTarget = target
            coordinator.failedTarget = nil
        }

        // 0. Explicit load request (refresh button, Retry, re-submitting the
        //    same address) — bypass every "already there / already failed"
        //    guard below.
        if model.reloadToken != coordinator.appliedReloadToken {
            coordinator.appliedReloadToken = model.reloadToken
            coordinator.failedTarget = nil
            coordinator.programmaticTarget = target
            model.lastError = nil
            debugLog("[WK] load (requested) → \(target)")
            uiView.load(URLRequest(url: url))
            return
        }

        // 1. This exact address already failed — do NOT auto-retry (loop guard).
        if coordinator.failedTarget == target { return }

        // 2. Already displaying the requested page.
        if uiView.url?.absoluteString == target { return }

        // 3. Already fetching it — during a provisional navigation `webView.url`
        //    is still nil, so without this check every state change would cancel
        //    the load and start over (the page could never commit).
        if uiView.isLoading, coordinator.programmaticTarget == target { return }

        // 4. A link tapped inside the page is loading — don't fight it.
        if uiView.isLoading, coordinator.programmaticTarget == nil { return }

        coordinator.programmaticTarget = target
        model.lastError = nil
        debugLog("[WK] load → \(target)")
        uiView.load(URLRequest(url: url))
    }

    /// Pinch zoom is enabled/disabled through the scroll view's zoom range.
    private func applyZoom(to webView: WKWebView, force: Bool) {
        let target: CGFloat = force ? 5.0 : 1.0
        guard webView.scrollView.maximumZoomScale != target else { return }
        webView.scrollView.maximumZoomScale = target
        if !force {
            webView.scrollView.zoomScale = 1.0
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    class Coordinator: NSObject, WKNavigationDelegate, WKScriptMessageHandler {
        var parent: WKWebViewWrapper
        /// The URL we asked WebKit to load; nil while the page drives navigation itself.
        var programmaticTarget: String?
        var installedRules: WKContentRuleList?
        var rulesInstalled: Bool { installedRules != nil }
        var reloadNeeded = false
        /// The address whose load last failed — auto-retrying it from
        /// `updateUIView` would spin forever (every state publish re-renders).
        var failedTarget: String?
        /// The address currently shown/requested, to notice real navigations.
        var lastTarget: String?
        /// Sync point for `model.reloadToken` (explicit refresh/Retry).
        var appliedReloadToken = 0
        /// KVO observation driving the address-bar progress line.
        var progressObservation: NSKeyValueObservation?
        /// The settings we last *applied* (targets, not live state) — comparing
        /// against live state would retry forever when a compile fails.
        var appliedBlockAds = false
        var appliedJS = true

        init(_ parent: WKWebViewWrapper) {
            self.parent = parent
        }

        // MARK: Content blocking

        func applyContentRules(to webView: WKWebView, enabled: Bool) {
            let store = WKContentRuleListStore.default()
            if enabled {
                guard !rulesInstalled else { return }
                store?.compileContentRuleList(forIdentifier: ContentBlocker.identifier,
                                              encodedContentRuleList: ContentBlocker.json) { list, error in
                    DispatchQueue.main.async {
                        guard let list else {
                            debugLog("[WK] rules compile failed: \(String(describing: error))")
                            return
                        }
                        webView.configuration.userContentController.add(list)
                        self.installedRules = list
                        debugLog("[WK] ad/tracker rules active")
                    }
                }
            } else {
                guard let installedRules else { return }
                webView.configuration.userContentController.remove(installedRules)
                self.installedRules = nil
                debugLog("[WK] ad/tracker rules removed")
            }
        }

        // MARK: Navigation policy

        func webView(_ webView: WKWebView,
                     decidePolicyFor navigationAction: WKNavigationAction,
                     decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
            if let requested = navigationAction.request.url?.absoluteString,
               requested != programmaticTarget {
                // Navigation started inside the page (user tapped a link).
                programmaticTarget = nil
            }
            decisionHandler(.allow)
        }

        /// Target=_blank / window.open — decide where the new page goes.
        func webView(_ webView: WKWebView,
                     createWebViewWith configuration: WKWebViewConfiguration,
                     for navigationAction: WKNavigationAction,
                     windowFeatures: WKWindowFeatures) -> WKWebView? {
            guard let url = navigationAction.request.url else { return nil }
            if parent.settings.openLinksInNewTab {
                DispatchQueue.main.async { self.parent.model.newTab(url: url.absoluteString) }
            } else {
                programmaticTarget = url.absoluteString
                DispatchQueue.main.async { webView.load(URLRequest(url: url)) }
            }
            return nil
        }

        // MARK: Network monitor bridge

        /// Every request the page makes (fetch/XHR/resource timing) arrives
        /// here from the injected JS and lands in the Network Monitor.
        func userContentController(_ userContentController: WKUserContentController,
                                   didReceive message: WKScriptMessage) {
            guard message.name == "lbNet",
                  let body = message.body as? [String: Any] else { return }
            RequestStore.shared.record(js: body)
        }

        /// Main-frame HTTP status for the Network Monitor.
        func webView(_ webView: WKWebView,
                     decidePolicyFor navigationResponse: WKNavigationResponse,
                     decisionHandler: @escaping (WKNavigationResponsePolicy) -> Void) {
            if navigationResponse.isForMainFrame,
               let http = navigationResponse.response as? HTTPURLResponse,
               let url = http.url {
                RequestStore.shared.recordNavigation(url: url.absoluteString,
                                                     status: http.statusCode)
            }
            decisionHandler(.allow)
        }

        // MARK: Lifecycle

        func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
            parent.model.isLoading = true
            parent.model.lastError = nil
            debugLog("[WK] didStart provisional \(webView.url?.absoluteString ?? "nil")")
        }

        func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
            parent.model.isLoading = false
            parent.model.progress = 0
            programmaticTarget = nil
            if let url = webView.url?.absoluteString {
                parent.model.currentUrl = url
                parent.model.inputUrl = url
                parent.model.updateActive(url: url, title: webView.title)
            }
            if let title = webView.title {
                parent.model.title = title
            }
            parent.model.lastError = nil
            debugLog("[WK] didFinish \(webView.url?.absoluteString ?? "nil")")
        }

        func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
            handle(error)
        }

        func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
            handle(error)
        }

        private func handle(_ error: Error) {
            let ns = error as NSError
            let attempted = programmaticTarget
            parent.model.isLoading = false
            parent.model.progress = 0
            programmaticTarget = nil

            // Cancelled means *we* replaced the load — not a real failure.
            if ns.code == NSURLErrorCancelled { return }
            // 102 = "Frame load interrupted" (download links, etc.).
            if ns.domain == "WebKitErrorDomain" && ns.code == 102 { return }

            // Remember what we tried so `updateUIView` won't retry it forever.
            failedTarget = attempted
            parent.model.lastError = ns.localizedDescription
            if let attempted {
                RequestStore.shared.recordNavigation(url: attempted, status: 0)
            }
            debugLog("[WK] FAILED \(ns.domain) \(ns.code): \(ns.localizedDescription)")
        }
    }
}

// MARK: - Weak script-message proxy

/// `userContentController` retains its message handlers strongly; the
/// coordinator must not be kept alive (and cycle back to the web view)
/// through that reference, so messages forward weakly.
private final class WeakScriptMessageHandler: NSObject, WKScriptMessageHandler {
    weak var delegate: WKScriptMessageHandler?

    init(delegate: WKScriptMessageHandler) {
        self.delegate = delegate
    }

    func userContentController(_ userContentController: WKUserContentController,
                               didReceive message: WKScriptMessage) {
        delegate?.userContentController(userContentController, didReceive: message)
    }
}

// MARK: - Browser UI

struct ContentView: View {
    @ObservedObject var model: BrowserModel
    @ObservedObject private var settings = SettingsStore.shared
    @ObservedObject private var lang = LanguageManager.shared
    @FocusState private var addressFocused: Bool

    /// Lock colour: secure sites get the accent, plain http warns in orange.
    private var isSecure: Bool {
        guard let scheme = URL(string: model.currentUrl)?.scheme else { return false }
        return scheme == "https"
    }

    var body: some View {
        ZStack {
            settings.backgroundView()

            VStack(spacing: 0) {
                if settings.addressBarTop {
                    addressBar
                }

                WKWebViewWrapper(model: model, settings: settings)
                    .ignoresSafeArea(edges: .horizontal)

                if !settings.addressBarTop {
                    addressBar
                }

                bottomBar
            }
            .background(settings.background.opacity(settings.hasCustomWallpaper ? 0 : 1))
        }
        .overlay(alignment: .bottom) {
            if let error = model.lastError {
                errorBanner(error)
            }
        }
        .animation(motion(.easeInOut(duration: 0.2)), value: model.lastError)
        .sheet(isPresented: $model.showSettings) {
            SettingsView(model: model)
        }
        .sheet(isPresented: $model.showTabs) {
            TabOverviewView(model: model)
                .presentationDetents([.medium, .large])
                .presentationDragIndicator(.visible)
        }
        .scrollDismissesKeyboard(.interactively)
    }

    // MARK: Address bar

    private var addressBar: some View {
        VStack(spacing: 0) {
            HStack(spacing: Metrics.Space.md) {
                // Brand mark — purely ornamental beside the address field.
                RoundedRectangle(cornerRadius: Metrics.Tile.radius, style: .continuous)
                    .fill(settings.accent)
                    .frame(width: Metrics.Tile.side, height: Metrics.Tile.side)
                    .overlay(
                        RoundedRectangle(cornerRadius: Metrics.Radius.sm, style: .continuous)
                            .fill(Color.black)
                            .frame(width: Metrics.Space.lg, height: Metrics.Space.xs)
                    )
                    .accessibilityHidden(true)

                HStack(spacing: Metrics.Space.sm) {
                    Image(systemName: isSecure ? "lock.fill" : "lock.open")
                        .font(.system(size: Metrics.Icon.sm, weight: .medium))
                        .foregroundColor(isSecure ? settings.accent : .orange)
                        .animation(motion(.easeOut(duration: 0.15)), value: isSecure)
                        .accessibilityHidden(true)

                    TextField(lang.t("chrome.placeholder"), text: $model.inputUrl)
                        .foregroundColor(AppColor.textPrimary)
                        .font(.app(TypeScale.footnote))
                        .keyboardType(.URL)
                        .textContentType(.URL)
                        .autocapitalization(.none)
                        .disableAutocorrection(true)
                        .submitLabel(.go)
                        .focused($addressFocused)
                        .onSubmit {
                            model.submit(model.inputUrl)
                            addressFocused = false
                        }

                    if addressFocused && !model.inputUrl.isEmpty {
                        chromeButton {
                            model.inputUrl = ""
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                                .font(.system(size: Metrics.Icon.md))
                                .foregroundColor(AppColor.textTertiary)
                        }
                        .transition(.opacity.combined(with: .scale(scale: 0.8)))
                    }

                    chromeButton {
                        model.submit(model.inputUrl)
                        addressFocused = false
                    } label: {
                        Image(systemName: "arrow.clockwise")
                            .font(.system(size: Metrics.Icon.sm, weight: .semibold))
                            .foregroundColor(addressFocused ? settings.accent : AppColor.textSecondary)
                    }
                }
                .padding(.horizontal, Metrics.Space.sm)
                .frame(minHeight: Metrics.Touch.min)
                .background(AppColor.chromeFill)
                .clipShape(RoundedRectangle(cornerRadius: Metrics.Radius.pill, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: Metrics.Radius.pill, style: .continuous)
                        .stroke(settings.accent.opacity(addressFocused ? 0.9 : 0),
                                lineWidth: 1.5)
                )
                .animation(motion(.easeOut(duration: 0.15)), value: addressFocused)

                chromeButton {
                    model.showSettings = true
                } label: {
                    Image(systemName: "gearshape.fill")
                        .font(.system(size: Metrics.Icon.lg, weight: .medium))
                        .foregroundColor(AppColor.textPrimary)
                }
                .accessibilityLabel(lang.t("settings.title"))
            }
            .padding(.horizontal, Metrics.Space.md)
            .padding(.vertical, Metrics.Space.sm)
            .background(chrome)

            // Deterministic progress line — follows real load progress.
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Color.clear
                    Rectangle()
                        .fill(settings.accent)
                        .frame(width: geo.size.width * max(0.02, model.progress))
                        .opacity(model.isLoading ? 1 : 0)
                }
            }
            .frame(height: 2)
            .background(chrome)
        }
        .animation(motion(.easeOut(duration: 0.2)), value: model.isLoading)
        .animation(motion(.easeOut(duration: 0.25)), value: model.progress)
        .animation(motion(.easeOut(duration: 0.2)), value: model.inputUrl.isEmpty)
    }

    // MARK: Bottom toolbar
    //
    // Every control is expanded to the 44pt minimum target — the raw glyphs
    // are only 16-20pt, which is below Apple's touch guidance.

    private var bottomBar: some View {
        HStack(spacing: Metrics.Space.sm) {
            chromeButton {
                model.submit(settings.homePage)
            } label: {
                Image(systemName: "house.fill")
                    .font(.system(size: Metrics.Icon.lg, weight: .medium))
                    .foregroundColor(AppColor.textPrimary)
            }
            .accessibilityLabel(lang.t("layout.home"))

            Spacer(minLength: Metrics.Space.sm)

            chromeButton {
                model.showTabs = true
            } label: {
                ZStack(alignment: .topTrailing) {
                    Image(systemName: "square.on.square")
                        .font(.system(size: Metrics.Icon.lg, weight: .medium))
                        .foregroundColor(AppColor.textPrimary)
                    if settings.showTabCount {
                        Text("\(model.tabs.count)")
                            // .app() so the badge tracks the in-app text-size
                            // setting; a raw .system(size:) would ignore it.
                            .font(.app(TypeScale.micro))
                            .fontWeight(.bold)
                            .foregroundColor(.black)
                            .padding(.horizontal, Metrics.Space.xs)
                            .padding(.vertical, Metrics.Space.xs / 2)
                            .background(settings.accent)
                            .clipShape(RoundedRectangle(cornerRadius: Metrics.Space.xs, style: .continuous))
                            .offset(x: Metrics.Space.md, y: -Metrics.Space.sm)
                            .id(model.tabs.count)
                            .transition(.scale(scale: 0.6).combined(with: .opacity))
                    }
                }
            }
            .accessibilityLabel(lang.t("row.tabs.title"))
            .accessibilityValue("\(model.tabs.count)")

            Spacer(minLength: Metrics.Space.sm)

            chromeButton {
                model.toggleBookmark(model.currentUrl)
                Haptics.tap(.medium)
            } label: {
                Image(systemName: model.isBookmarked(model.currentUrl) ? "star.fill" : "star")
                    .font(.system(size: Metrics.Icon.lg, weight: .medium))
                    .foregroundColor(model.isBookmarked(model.currentUrl)
                                     ? settings.accent : AppColor.textSecondary)
            }
            .accessibilityLabel(lang.t("tabs.bookmarks"))
            .accessibilityValue(model.isBookmarked(model.currentUrl)
                                ? lang.t("privacy.on") : lang.t("privacy.off"))

            Spacer(minLength: Metrics.Space.sm)

            chromeButton {
                model.newTab()
            } label: {
                Image(systemName: "plus.circle.fill")
                    .font(.system(size: Metrics.Icon.xl, weight: .medium))
                    .foregroundColor(AppColor.textPrimary)
            }
            .accessibilityLabel(lang.t("tabs.new"))

            Spacer(minLength: Metrics.Space.sm)

            chromeButton {
                model.showSettings = true
            } label: {
                Image(systemName: "ellipsis.circle.fill")
                    .font(.system(size: Metrics.Icon.lg, weight: .medium))
                    .foregroundColor(AppColor.textPrimary)
            }
            .accessibilityLabel(lang.t("settings.title"))
        }
        .padding(.horizontal, Metrics.Space.xl)
        .padding(.vertical, Metrics.Space.md)
        .background(chrome)
    }

    private var chrome: Color {
        settings.hasCustomWallpaper ? settings.chromeColor.opacity(0.92) : settings.chromeColor
    }

    // MARK: Error banner

    private func errorBanner(_ message: String) -> some View {
        HStack(spacing: Metrics.Space.sm) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: Metrics.Icon.sm, weight: .medium))
                .foregroundColor(.yellow)
                .accessibilityHidden(true)

            Text(message)
                .foregroundColor(AppColor.textPrimary)
                .font(.app(TypeScale.caption))
                .lineLimit(2)
                .fixedSize(horizontal: false, vertical: true)

            Spacer(minLength: Metrics.Space.xs)

            // Retry: re-submits the current address.
            Button {
                model.lastError = nil
                model.submit(model.inputUrl)
            } label: {
                Text(lang.t("chrome.retry"))
                    .font(.app(TypeScale.caption))
                    .fontWeight(.semibold)
                    .foregroundColor(.black)
                    .padding(.horizontal, Metrics.Space.md)
                    .frame(minHeight: Metrics.Touch.min)
                    .background(.yellow)
                    .clipShape(RoundedRectangle(cornerRadius: Metrics.Tile.radius, style: .continuous))
            }
            .buttonStyle(PressButtonStyle())

            chromeButton {
                appAnimate { model.lastError = nil }
            } label: {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: Metrics.Icon.lg))
                    .foregroundColor(AppColor.textSecondary)
            }
            .accessibilityLabel(lang.t("settings.close"))
        }
        .padding(.horizontal, Metrics.Space.md)
        .padding(.vertical, Metrics.Space.md)
        .background(AppColor.dangerSurface)
        .clipShape(RoundedRectangle(cornerRadius: Metrics.Radius.md, style: .continuous))
        .padding(.horizontal, Metrics.Space.lg)
        .padding(.bottom, Metrics.Chrome.bannerClearance)
        .transition(.move(edge: .bottom).combined(with: .opacity))
    }

    // MARK: Shared chrome button
    //
    // Expands the hit area to the 44pt minimum without changing the glyph.
    // `PressButtonStyle` already fires a light haptic on press-down, so
    // actions here must NOT call `Haptics.tap()` again — that reads as a
    // double buzz. Actions only add haptics with real semantic weight
    // (e.g. `.medium` when a bookmark toggles).

    private func chromeButton<Label: View>(action: @escaping () -> Void,
                                           @ViewBuilder label: () -> Label) -> some View {
        Button(action: action, label: label)
            .buttonStyle(PressButtonStyle())
            .frame(minWidth: Metrics.Touch.min, minHeight: Metrics.Touch.min)
            .contentShape(Rectangle())
    }

    /// Returns `nil` (no animation) when Reduce Motion is on.
    private func motion(_ animation: Animation) -> Animation? {
        settings.reduceMotion ? nil : animation
    }
}
