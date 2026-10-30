import SwiftUI
import WebKit

struct WKWebViewWrapper: UIViewRepresentable {
    let urlString: String
    @ObservedObject var model: BrowserModel

    func makeUIView(context: Context) -> WKWebView {
        let config = WKWebViewConfiguration()
        config.allowsInlineMediaPlayback = true
        let webView = WKWebView(frame: .zero, configuration: config)
        webView.navigationDelegate = context.coordinator
        if let url = URL(string: urlString) {
            webView.load(URLRequest(url: url))
        }
        return webView
    }

    func updateUIView(_ uiView: WKWebView, context: Context) {
        if let url = URL(string: model.currentUrl), uiView.url?.absoluteString != model.currentUrl {
            uiView.load(URLRequest(url: url))
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    class Coordinator: NSObject, WKNavigationDelegate {
        var parent: WKWebViewWrapper

        init(_ parent: WKWebViewWrapper) {
            self.parent = parent
        }

        func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
            parent.model.isLoading = true
        }

        func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
            parent.model.isLoading = false
            if let url = webView.url?.absoluteString {
                parent.model.currentUrl = url
                parent.model.inputUrl = url
            }
            if let title = webView.title {
                parent.model.title = title
            }
        }
    }
}

struct ContentView: View {
    @StateObject private var model = BrowserModel()
    @State private var showMenu = false

    var body: some View {
        ZStack {
            Color(UIColor(red: 0.04, green: 0.05, blue: 0.06, alpha: 1.0))
                .ignoresSafeArea()

            VStack(spacing: 0) {
                // Top Address Bar
                HStack(spacing: 10) {
                    RoundedRectangle(cornerRadius: 6)
                        .fill(Color(0xFF34C759))
                        .frame(width: 24, height: 24)
                        .overlay(
                            RoundedRectangle(cornerRadius: 2)
                                .fill(Color.black)
                                .frame(width: 10, height: 3)
                        )

                    HStack {
                        Image(systemName: "lock.fill")
                            .font(.system(size: 10))
                            .foregroundColor(Color(0xFF34C759))

                        TextField("Caută sau introdu adresa web", text: $model.inputUrl)
                            .foregroundColor(.white)
                            .font(.system(size: 13))
                            .keyboardType(.url)
                            .autocapitalization(.none)
                            .onSubmit {
                                var formatted = model.inputUrl.trimmingCharacters(in: .whitespaces)
                                if !formatted.hasPrefix("http://") && !formatted.hasPrefix("https://") {
                                    if formatted.contains(".") && !formatted.contains(" ") {
                                        formatted = "https://" + formatted
                                    } else {
                                        let query = formatted.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? formatted
                                        formatted = "https://duckduckgo.com/?q=\(query)"
                                    }
                                }
                                model.currentUrl = formatted
                                model.inputUrl = formatted
                            }

                        if model.isLoading {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                .scaleEffect(0.7)
                        } else {
                            Button(action: {
                                model.currentUrl = model.inputUrl
                            }) {
                                Image(systemName: "arrow.clockwise")
                                    .foregroundColor(.gray)
                                    .font(.system(size: 12))
                            }
                        }
                    }
                    .padding(8)
                    .background(Color(0xFF2C2C2E))
                    .cornerRadius(20)

                    Button(action: {
                        model.showSettings = true
                    }) {
                        Image(systemName: "gearshape.fill")
                            .foregroundColor(.white)
                            .font(.system(size: 16))
                    }
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(Color(0xFF141416))

                // Web Content Area
                WKWebViewWrapper(urlString: model.currentUrl, model: model)
                    .ignoresSafeArea(edges: .horizontal)

                // Bottom Navigation Toolbar
                HStack {
                    Button(action: {
                        model.currentUrl = "https://lineinc.ro"
                        model.inputUrl = "https://lineinc.ro"
                    }) {
                        Image(systemName: "house.fill")
                            .foregroundColor(.white)
                            .font(.system(size: 18))
                    }
                    Spacer()
                    Button(action: {
                        model.bookmarks.append(model.currentUrl)
                    }) {
                        Image(systemName: "star.fill")
                            .foregroundColor(Color(0xFF34C759))
                            .font(.system(size: 18))
                    }
                    Spacer()
                    Button(action: {
                        model.currentUrl = "about:blank"
                        model.inputUrl = ""
                    }) {
                        Image(systemName: "plus.circle.fill")
                            .foregroundColor(.white)
                            .font(.system(size: 20))
                    }
                    Spacer()
                    Button(action: {
                        model.showSettings = true
                    }) {
                        Image(systemName: "ellipsis.circle.fill")
                            .foregroundColor(.white)
                            .font(.system(size: 18))
                    }
                }
                .padding(.horizontal, 24)
                .padding(.vertical, 12)
                .background(Color(0xFF141416))
            }
        }
        .sheet(isPresented: $model.showSettings) {
            SettingsView()
        }
    }
}
