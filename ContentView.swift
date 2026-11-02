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
        .animation(settings.reduceMotion ? nil : .easeInOut(duration: 0.2), value: model.lastError)
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
            HStack(spacing: 10) {
                RoundedRectangle(cornerRadius: 6)
                    .fill(settings.accent)
                    .frame(width: 24, height: 24)
                    .overlay(
                        RoundedRectangle(cornerRadius: 2)
                            .fill(Color.black)
                            .frame(width: 10, height: 3)
                    )

                HStack(spacing: 6) {
                    Image(systemName: isSecure ? "lock.fill" : "lock.open")
                        .font(.system(size: 10))
                        .foregroundColor(isSecure ? settings.accent : .orange)
                        .animation(.easeOut(duration: 0.15), value: isSecure)

                    TextField(lang.t("chrome.placeholder"), text: $model.inputUrl)
                        .foregroundColor(.white)
                        .font(.app(13))
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
                        Button {
                            model.inputUrl = ""
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                                .font(.system(size: 13))
                                .foregroundColor(Color(UIColor.systemGray2))
                        }
                        .buttonStyle(.plain)
                        .transition(.opacity.combined(with: .scale(scale: 0.8)))
                    }

                    Button(action: {
                        model.submit(model.inputUrl)
                        addressFocused = false
                    }) {
                        Image(systemName: "arrow.clockwise")
                            .foregroundColor(addressFocused ? settings.accent : Color(UIColor.systemGray2))
                            .font(.system(size: 12))
                    }
                    .buttonStyle(PressButtonStyle())
                }
                .padding(8)
                .background(Color(0xFF2C2C2E))
                .cornerRadius(20)
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(settings.accent.opacity(addressFocused ? 0.9 : 0),
                                lineWidth: 1.5)
                )
                .animation(.easeOut(duration: 0.15), value: addressFocused)

                Button(action: {
                    Haptics.tap()
                    model.showSettings = true
                }) {
                    Image(systemName: "gearshape.fill")
                        .foregroundColor(.white)
                        .font(.system(size: 16))
                }
                .buttonStyle(PressButtonStyle())
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
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
        .animation(.easeOut(duration: 0.2), value: model.isLoading)
        .animation(.easeOut(duration: 0.25), value: model.progress)
        .animation(.easeOut(duration: 0.2), value: model.inputUrl.isEmpty)
    }

    // MARK: Bottom toolbar

    private var bottomBar: some View {
        HStack {
            Button(action: {
                Haptics.tap()
                model.submit(settings.homePage)
            }) {
                Image(systemName: "house.fill")
                    .foregroundColor(.white)
                    .font(.system(size: 18))
            }
            .buttonStyle(PressButtonStyle())

            Spacer()

            Button(action: {
                Haptics.tap()
                model.showTabs = true
            }) {
                ZStack(alignment: .topTrailing) {
                    Image(systemName: "square.on.square")
                        .foregroundColor(.white)
                        .font(.system(size: 17))
                    if settings.showTabCount {
                        Text("\(model.tabs.count)")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(.black)
                            .padding(.horizontal, 4)
                            .padding(.vertical, 1)
                            .background(settings.accent)
                            .cornerRadius(6)
                            .offset(x: 12, y: -8)
                            .id(model.tabs.count)
                            .transition(.scale(scale: 0.6).combined(with: .opacity))
                    }
                }
            }
            .buttonStyle(PressButtonStyle())

            Spacer()

            Button(action: {
                model.toggleBookmark(model.currentUrl)
                Haptics.tap(.medium)
            }) {
                Image(systemName: model.isBookmarked(model.currentUrl) ? "star.fill" : "star")
                    .foregroundColor(model.isBookmarked(model.currentUrl)
                                     ? settings.accent : Color(UIColor.systemGray))
                    .font(.system(size: 18))
            }
            .buttonStyle(PressButtonStyle())

            Spacer()

            Button(action: {
                Haptics.tap()
                model.newTab()
            }) {
                Image(systemName: "plus.circle.fill")
                    .foregroundColor(.white)
                    .font(.system(size: 20))
            }
            .buttonStyle(PressButtonStyle())

            Spacer()

            Button(action: {
                Haptics.tap()
                model.showSettings = true
            }) {
                Image(systemName: "ellipsis.circle.fill")
                    .foregroundColor(.white)
                    .font(.system(size: 18))
            }
            .buttonStyle(PressButtonStyle())
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 12)
        .background(chrome)
    }

    private var chrome: Color {
        settings.hasCustomWallpaper ? settings.chromeColor.opacity(0.92) : settings.chromeColor
    }

    // MARK: Error banner

    private func errorBanner(_ message: String) -> some View {
        HStack(spacing: 8) {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundColor(.yellow)
                .font(.system(size: 13))
            Text(message)
                .foregroundColor(.white)
                .font(.app(12))
                .lineLimit(2)
            Spacer(minLength: 4)

            // Retry: re-submits the current address.
            Button {
                model.lastError = nil
                model.submit(model.inputUrl)
            } label: {
                Text(lang.t("chrome.retry"))
                    .font(.app(12))
                    .fontWeight(.semibold)
                    .foregroundColor(.black)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(Color.yellow)
                    .cornerRadius(8)
            }
            .buttonStyle(PressButtonStyle())

            Button {
                appAnimate { model.lastError = nil }
            } label: {
                Image(systemName: "xmark.circle.fill")
                    .foregroundColor(Color(UIColor.systemGray))
                    .font(.system(size: 16))
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(Color(0xFF4A2020))
        .cornerRadius(12)
        .padding(.horizontal, 14)
        .padding(.bottom, 74)
        .transition(.move(edge: .bottom).combined(with: .opacity))
    }
}
