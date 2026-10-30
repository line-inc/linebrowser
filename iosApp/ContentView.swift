import SwiftUI
import WebKit

struct WebView: UIViewRepresentable {
    let url: URL

    func makeUIView(context: Context) -> WKWebView {
        let prefs = WKWebpagePreferences()
        prefs.allowsContentJavaScript = true
        let config = WKWebViewConfiguration()
        config.defaultWebpagePreferences = prefs
        let webView = WKWebView(frame: .zero, configuration: config)
        webView.load(URLRequest(url: url))
        return webView
    }

    func updateUIView(_ uiView: WKWebView, context: Context) {}
}

struct ContentView: View {
    var body: some View {
        ZStack {
            Color(UIColor(red: 0.04, green: 0.05, blue: 0.06, alpha: 1.0))
                .ignoresSafeArea()

            WebView(url: URL(string: "https://lineinc.ro")!)
                .ignoresSafeArea(edges: [.bottom, .horizontal])
        }
    }
}
