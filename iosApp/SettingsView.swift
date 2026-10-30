import SwiftUI

struct SettingsView: View {
    @Environment(\.dismiss) var dismiss

    var body: some View {
        NavigationView {
            ZStack {
                Color(UIColor(red: 0.07, green: 0.08, blue: 0.09, alpha: 1.0))
                    .ignoresSafeArea()

                List {
                    Section(header: Text("GENERAL").foregroundColor(Color(0xFF34C759))) {
                        HStack {
                            Image(systemName: "globe")
                                .foregroundColor(.green)
                            Text("Limba Aplicației")
                                .foregroundColor(.white)
                            Spacer()
                            Text("Română")
                                .foregroundColor(.gray)
                        }
                        .listRowBackground(Color(0xFF1E2024))

                        HStack {
                            Image(systemName: "moon.fill")
                                .foregroundColor(.indigo)
                            Text("Mod Întunecat")
                                .foregroundColor(.white)
                            Spacer()
                            Toggle("", isOn: .constant(true))
                                .tint(Color(0xFF34C759))
                        }
                        .listRowBackground(Color(0xFF1E2024))
                    }

                    Section(header: Text("DESPRE").foregroundColor(Color(0xFF34C759))) {
                        HStack {
                            Text("Versiune Aplicație")
                                .foregroundColor(.white)
                            Spacer()
                            Text("1.0.0")
                                .foregroundColor(.gray)
                        }
                        .listRowBackground(Color(0xFF1E2024))

                        HStack {
                            Text("Copyright")
                                .foregroundColor(.white)
                            Spacer()
                            Text("© 2026 Line Inc.")
                                .foregroundColor(.gray)
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
