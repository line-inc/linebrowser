import SwiftUI

struct SettingsView: View {
    @Environment(\.dismiss) var dismiss
    @ObservedObject var model: BrowserModel

    @State private var adBlockEnabled = true
    @State private var httpsOnly = true
    @State private var trackingProtection = true
    @State private var customDns = "Cloudflare (1.1.1.1)"
    @State private var searchEngine = "DuckDuckGo"

    var body: some View {
        NavigationView {
            ZStack {
                Color(UIColor(red: 0.04, green: 0.05, blue: 0.06, alpha: 1.0))
                    .ignoresSafeArea()

                List {
                    // ── PERSONALIZARE ──────────────────────────────────────────────
                    Section(header: Text("PERSONALIZARE").foregroundColor(Color(0xFF34C759)).font(.system(size: 12, weight: .bold))) {
                        HStack {
                            SettingsRow(icon: "globe", color: .green, title: "Limba Aplicației", subtitle: "Română (Selectată)")
                        }
                        .listRowBackground(Color(0xFF1E2024))

                        HStack {
                            SettingsRow(icon: "moon.fill", color: .indigo, title: "Mod Întunecat", subtitle: "Temă AMOLED activă")
                            Spacer()
                            Toggle("", isOn: .constant(true))
                                .tint(Color(0xFF34C759))
                        }
                        .listRowBackground(Color(0xFF1E2024))
                    }

                    // ── NAVIGARE WEB ────────────────────────────────────────────────
                    Section(header: Text("NAVIGARE WEB").foregroundColor(Color(0xFF34C759)).font(.system(size: 12, weight: .bold))) {
                        Picker(selection: $searchEngine, label: SettingsRow(icon: "magnifyingglass", color: .blue, title: "Motor de căutare", subtitle: searchEngine)) {
                            Text("DuckDuckGo").tag("DuckDuckGo")
                            Text("Google").tag("Google")
                            Text("Brave").tag("Brave")
                            Text("Bing").tag("Bing")
                        }
                        .pickerStyle(.menu)
                        .listRowBackground(Color(0xFF1E2024))

                        HStack {
                            SettingsRow(icon: "shield.fill", color: Color(0xFF34C759), title: "Line Shield (AdBlock)", subtitle: "Blocare activă reclame & trackere")
                            Spacer()
                            Toggle("", isOn: $adBlockEnabled)
                                .tint(Color(0xFF34C759))
                        }
                        .listRowBackground(Color(0xFF1E2024))
                    }

                    // ── CONFIDENȚIALITATE ȘI SECURITATE ─────────────────────────────
                    Section(header: Text("CONFIDENȚIALITATE ȘI SECURITATE").foregroundColor(Color(0xFF34C759)).font(.system(size: 12, weight: .bold))) {
                        HStack {
                            SettingsRow(icon: "lock.fill", color: .orange, title: "Mod Exclusiv HTTPS", subtitle: "Criptare automată a conexiunilor")
                            Spacer()
                            Toggle("", isOn: $httpsOnly)
                                .tint(Color(0xFF34C759))
                        }
                        .listRowBackground(Color(0xFF1E2024))

                        HStack {
                            SettingsRow(icon: "eye.slash.fill", color: .red, title: "Protecție anti-urmărire", subtitle: "Izolare cookie-uri terțe")
                            Spacer()
                            Toggle("", isOn: $trackingProtection)
                                .tint(Color(0xFF34C759))
                        }
                        .listRowBackground(Color(0xFF1E2024))
                    }

                    // ── DESPRE ──────────────────────────────────────────────────────
                    Section(header: Text("DESPRE").foregroundColor(Color(0xFF34C759)).font(.system(size: 12, weight: .bold))) {
                        HStack {
                            Image(systemName: "info.circle.fill")
                                .foregroundColor(.gray)
                                .frame(width: 24)
                            Text("Versiune Aplicație")
                                .foregroundColor(.white)
                            Spacer()
                            Text("1.0.0 (Build 10001)")
                                .foregroundColor(.gray)
                        }
                        .listRowBackground(Color(0xFF1E2024))

                        HStack {
                            Image(systemName: "c.circle.fill")
                                .foregroundColor(.gray)
                                .frame(width: 24)
                            Text("Copyright")
                                .foregroundColor(.white)
                            Spacer()
                            Text("© 2026 Line Inc.")
                                .foregroundColor(.gray)
                        }
                        .listRowBackground(Color(0xFF1E2024))

                        Button(action: {
                            if let url = URL(string: "https://lineinc.ro") {
                                UIApplication.shared.open(url)
                            }
                        }) {
                            SettingsRow(icon: "link", color: .green, title: "Website Oficial", subtitle: "lineinc.ro")
                        }
                        .listRowBackground(Color(0xFF1E2024))
                    }
                }
                .scrollContentBackground(.hidden)
            }
            .navigationTitle("Setări")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Închide") {
                        dismiss()
                    }
                    .foregroundColor(Color(0xFF34C759))
                }
            }
        }
    }
}

struct SettingsRow: View {
    let icon: String
    let color: Color
    let title: String
    let subtitle: String

    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: icon)
                .font(.system(size: 16))
                .foregroundColor(.white)
                .frame(width: 32, height: 32)
                .background(color)
                .cornerRadius(8)

            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .foregroundColor(.white)
                    .font(.system(size: 15, weight: .semibold))
                Text(subtitle)
                    .foregroundColor(Color(UIColor.systemGray2))
                    .font(.system(size: 11.5))
            }
            Spacer()
        }
        .padding(.vertical, 4)
    }
}
