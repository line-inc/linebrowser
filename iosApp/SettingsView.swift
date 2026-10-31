import SwiftUI

struct SettingsView: View {
    @Environment(\.dismiss) var dismiss
    @ObservedObject var model: BrowserModel

    var body: some View {
        NavigationView {
            ZStack {
                Color(UIColor(red: 0.04, green: 0.05, blue: 0.06, alpha: 1.0))
                    .ignoresSafeArea()

                List {
                    // ── PERSONALIZARE ──────────────────────────────────────────────
                    Section(header: Text("PERSONALIZARE").foregroundColor(Color(0xFF34C759)).font(.system(size: 12, weight: .bold))) {
                        NavigationLink(destination: Text("Setări Temă").foregroundColor(.white)) {
                            SettingsRow(icon: "paintpalette.fill", color: .purple, title: "Temă", subtitle: "Mod întunecat, culori de accent, iconițe")
                        }
                        .listRowBackground(Color(0xFF1E2024))

                        NavigationLink(destination: Text("Preferințe și Layout").foregroundColor(.white)) {
                            SettingsRow(icon: "slider.horizontal.3", color: .blue, title: "Preferințe și Aranjament", subtitle: "Poziție bară de adrese, bare de navigare, scalare UI")
                        }
                        .listRowBackground(Color(0xFF1E2024))

                        NavigationLink(destination: Text("Imagini de fundal").foregroundColor(.white)) {
                            SettingsRow(icon: "photo.fill", color: .orange, title: "Imagini de fundal", subtitle: "Fundal browser, colecții LineOS & Aero")
                        }
                        .listRowBackground(Color(0xFF1E2024))

                        NavigationLink(destination: Text("Accesibilitate").foregroundColor(.white)) {
                            SettingsRow(icon: "accessibility", color: .green, title: "Accesibilitate", subtitle: "Scalare text, forțare zoom, mod contrast ridicat")
                        }
                        .listRowBackground(Color(0xFF1E2024))
                    }

                    // ── NAVIGARE WEB ────────────────────────────────────────────────
                    Section(header: Text("NAVIGARE WEB").foregroundColor(Color(0xFF34C759)).font(.system(size: 12, weight: .bold))) {
                        NavigationLink(destination: Text("Setări File").foregroundColor(.white)) {
                            SettingsRow(icon: "rectangle.stack.fill", color: .cyan, title: "File", subtitle: "Aranjamente file, file în fundal și închidere automată")
                        }
                        .listRowBackground(Color(0xFF1E2024))

                        NavigationLink(destination: Text("Setări Site").foregroundColor(.white)) {
                            SettingsRow(icon: "globe", color: .teal, title: "Setări Site", subtitle: "Gestionare permisiuni site, JavaScript, pop-up-uri")
                        }
                        .listRowBackground(Color(0xFF1E2024))

                        NavigationLink(destination: Text("Aplicații Web & PWA").foregroundColor(.white)) {
                            SettingsRow(icon: "square.grid.2x2.fill", color: .pink, title: "Aplicații Web & PWA", subtitle: "Gestionare, clonare și descoperire Progressive Web Apps")
                        }
                        .listRowBackground(Color(0xFF1E2024))
                    }

                    // ── CONFIDENȚIALITATE ȘI SECURITATE ─────────────────────────────
                    Section(header: Text("CONFIDENȚIALITATE ȘI SECURITATE").foregroundColor(Color(0xFF34C759)).font(.system(size: 12, weight: .bold))) {
                        NavigationLink(destination: Text("Confidențialitate și Securitate").foregroundColor(.white)) {
                            SettingsRow(icon: "shield.fill", color: Color(0xFF34C759), title: "Confidențialitate și Securitate", subtitle: "Șterge datele de navigare, cookie-uri, navigare sigură")
                        }
                        .listRowBackground(Color(0xFF1E2024))

                        NavigationLink(destination: Text("Manager de Parole").foregroundColor(.white)) {
                            SettingsRow(icon: "key.fill", color: .yellow, title: "Manager de Parole", subtitle: "Creați, deblocați și gestionați credențialele salvate")
                        }
                        .listRowBackground(Color(0xFF1E2024))

                        NavigationLink(destination: Text("Seif Privat").foregroundColor(.white)) {
                            SettingsRow(icon: "lock.shield.fill", color: .red, title: "Seif Privat (Safe Locker)", subtitle: "Seif criptat biometric pentru descărcări și documente")
                        }
                        .listRowBackground(Color(0xFF1E2024))
                    }

                    // ── PROXY & VPN ─────────────────────────────────────────────────
                    Section(header: Text("PROXY &amp; VPN").foregroundColor(Color(0xFF34C759)).font(.system(size: 12, weight: .bold))) {
                        NavigationLink(destination: Text("Hub de Confidențialitate (Tor & VPN)").foregroundColor(.white)) {
                            SettingsRow(icon: "network", color: .indigo, title: "Hub de Confidențialitate", subtitle: "Rutare rețea Tor, WireGuard VPN, SOCKS5 și DNS criptat")
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
                            Text("1.0.0")
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
