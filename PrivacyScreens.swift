import SwiftUI

// MARK: - Privacy & Security

struct PrivacySettingsView: View {
    @ObservedObject var model: BrowserModel
    @ObservedObject private var settings = SettingsStore.shared
    @ObservedObject private var lang = LanguageManager.shared
    @State private var showClearConfirm = false
    @State private var clearing = false
    @State private var cleared = false

    var body: some View {
        ScreenShell(title: lang.t("screen.privacy.title")) {
            CardSection(title: lang.t("privacy.protection")) {
                ToggleRow(icon: "shield.lefthalf.filled", color: settings.accent,
                          title: lang.t("privacy.blockAds"), subtitle: lang.t("privacy.blockAdsSub"),
                          isOn: $settings.blockAds)
                Divider().overlay(Color.black.opacity(0.4))
                ToggleRow(icon: "clock.arrow.circlepath", color: .orange,
                          title: lang.t("privacy.clearOnExit"), subtitle: lang.t("privacy.clearOnExitSub"),
                          isOn: $settings.clearOnExit)
                Divider().overlay(Color.black.opacity(0.4))
                ToggleRow(icon: "key.fill", color: .yellow,
                          title: lang.t("privacy.keychain"), subtitle: lang.t("privacy.keychainSub"),
                          isOn: .constant(true))
                    .disabled(true)
            }

            CardSection(title: lang.t("privacy.data"), subtitle: lang.t("privacy.dataSub")) {
                Button {
                    showClearConfirm = true
                } label: {
                    HStack(spacing: 14) {
                        Image(systemName: clearing ? "arrow.triangle.2.circlepath" : "trash.fill")
                            .font(.system(size: 15))
                            .foregroundColor(.white)
                            .frame(width: 32, height: 32)
                            .background(cleared ? Color.green : Color.red)
                            .cornerRadius(8)
                        Text(cleared ? lang.t("site.cleared") : lang.t("privacy.clearNow"))
                            .font(.app(15))
                            .fontWeight(.semibold)
                            .foregroundColor(cleared ? settings.accent : .white)
                        Spacer()
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 12)
                }
                .buttonStyle(.plain)
                .disabled(clearing)
            }

            CardSection(title: "") {
                InfoRow(icon: "lock.shield", color: settings.accent, text: lang.t("privacy.note"))
            }
        }
        .confirmationDialog(lang.t("site.clearConfirm"),
                            isPresented: $showClearConfirm, titleVisibility: .visible) {
            Button(lang.t("privacy.clearNow"), role: .destructive) {
                clearing = true
                model.clearAllWebsiteData {
                    clearing = false
                    cleared = true
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) { cleared = false }
                }
            }
            Button(lang.t("common.skip"), role: .cancel) {}
        }
    }
}

// MARK: - Privacy Hub (network privacy)

struct PrivacyHubView: View {
    @ObservedObject var model: BrowserModel
    @ObservedObject private var settings = SettingsStore.shared
    @ObservedObject private var lang = LanguageManager.shared

    private var currentURL: URL? { URL(string: model.currentUrl) }
    private var isSecure: Bool { currentURL?.scheme == "https" }

    var body: some View {
        ScreenShell(title: lang.t("screen.hub.title")) {
            CardSection(title: lang.t("hub.connection")) {
                HStack(spacing: 14) {
                    Image(systemName: isSecure ? "lock.fill" : "lock.open")
                        .font(.system(size: 16))
                        .foregroundColor(.white)
                        .frame(width: 36, height: 36)
                        .background(isSecure ? settings.accent : .orange)
                        .cornerRadius(10)
                    VStack(alignment: .leading, spacing: 3) {
                        Text(isSecure ? lang.t("hub.secure") : lang.t("hub.insecure"))
                            .font(.app(15))
                            .fontWeight(.semibold)
                            .foregroundColor(.white)
                        Text(currentURL?.host ?? "—")
                            .font(.app(12))
                            .foregroundColor(Color(UIColor.systemGray2))
                            .lineLimit(1)
                    }
                    Spacer()
                    Text(currentURL?.scheme?.uppercased() ?? "—")
                        .font(.app(12))
                        .fontWeight(.bold)
                        .foregroundColor(settings.accent)
                }
                .padding(12)
            }

            CardSection(title: lang.t("hub.network")) {
                ToggleRow(icon: "shield.lefthalf.filled", color: settings.accent,
                          title: lang.t("privacy.blockAds"), subtitle: lang.t("privacy.blockAdsSub"),
                          isOn: $settings.blockAds)
                Divider().overlay(Color.black.opacity(0.4))

                Button {
                    if let url = URL(string: UIApplication.openSettingsURLString) {
                        UIApplication.shared.open(url)
                    }
                } label: {
                    HStack(spacing: 14) {
                        Image(systemName: "network")
                            .font(.system(size: 15))
                            .foregroundColor(.white)
                            .frame(width: 32, height: 32)
                            .background(.indigo)
                            .cornerRadius(8)
                        VStack(alignment: .leading, spacing: 2) {
                            Text(lang.t("hub.dns"))
                                .font(.app(15))
                                .fontWeight(.semibold)
                                .foregroundColor(.white)
                            Text(lang.t("hub.dnsSub"))
                                .font(.app(12))
                                .foregroundColor(Color(UIColor.systemGray2))
                        }
                        Spacer()
                        Image(systemName: "arrow.up.forward.app")
                            .font(.system(size: 13))
                            .foregroundColor(settings.accent)
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 10)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
            }

            CardSection(title: lang.t("hub.tools")) {
                NavigationLink { NetworkMonitorView() } label: {
                    hubRow(icon: "waveform.path.ecg", color: .orange,
                           title: lang.t("row.monitor.title"),
                           subtitle: lang.t("row.monitor.sub"),
                           value: "\(requests.entries.count)")
                }
                .buttonStyle(.plain)
            }

            CardSection(title: "") {
                InfoRow(icon: "info.circle", color: .gray, text: lang.t("hub.toolsNote"))
                Divider().overlay(Color.black.opacity(0.4))
                InfoRow(icon: "checkmark.seal", color: settings.accent, text: lang.t("hub.trackingNote"))
            }
        }
    }

    private func hubRow(icon: String, color: Color, title: String,
                        subtitle: String, value: String) -> some View {
        HStack(spacing: 14) {
            Image(systemName: icon)
                .font(.system(size: 15))
                .foregroundColor(.white)
                .frame(width: 32, height: 32)
                .background(color)
                .cornerRadius(8)
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.app(15))
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                Text(subtitle)
                    .font(.app(12))
                    .foregroundColor(Color(UIColor.systemGray2))
                    .lineLimit(1)
            }
            Spacer()
            Text(value)
                .font(.app(13))
                .foregroundColor(settings.accent)
                .lineLimit(1)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .contentShape(Rectangle())
    }

    @ObservedObject private var requests = RequestStore.shared
}

// MARK: - Password manager (Keychain)

struct PasswordsView: View {
    @ObservedObject private var store = PasswordStore.shared
    @ObservedObject private var settings = SettingsStore.shared
    @ObservedObject private var lang = LanguageManager.shared

    @State private var site = ""
    @State private var username = ""
    @State private var password = ""
    @State private var revealedIDs: Set<UUID> = []
    @State private var copiedID: UUID?

    var body: some View {
        ScreenShell(title: lang.t("screen.passwords.title")) {
            CardSection(title: lang.t("pw.add"), subtitle: lang.t("pw.addSub")) {
                VStack(spacing: 10) {
                    field(icon: "globe", placeholder: lang.t("pw.site"), text: $site)
                    field(icon: "person", placeholder: lang.t("pw.username"), text: $username)
                    field(icon: "key", placeholder: lang.t("pw.password"), text: $password, secure: true)
                    PrimaryButton(title: lang.t("pw.save"), icon: "plus") {
                        guard !site.isEmpty, !password.isEmpty else { return }
                        store.add(site: site, username: username, password: password)
                        site = ""; username = ""; password = ""
                    }
                }
                .padding(12)
            }

            CardSection(title: lang.t("pw.saved")) {
                if store.items.isEmpty {
                    EmptyState(icon: "key", title: lang.t("pw.empty"),
                               subtitle: lang.t("pw.note"))
                } else {
                    ForEach(store.items) { credential in
                        VStack(alignment: .leading, spacing: 8) {
                            HStack(spacing: 12) {
                                Image(systemName: "key.fill")
                                    .font(.system(size: 14))
                                    .foregroundColor(.black)
                                    .frame(width: 30, height: 30)
                                    .background(.yellow)
                                    .cornerRadius(8)
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(credential.site)
                                        .font(.app(15))
                                        .fontWeight(.semibold)
                                        .foregroundColor(.white)
                                    Text(credential.username.isEmpty ? "—" : credential.username)
                                        .font(.app(12))
                                        .foregroundColor(Color(UIColor.systemGray2))
                                }
                                Spacer()
                                Button {
                                    if revealedIDs.contains(credential.id) {
                                        revealedIDs.remove(credential.id)
                                    } else {
                                        revealedIDs.insert(credential.id)
                                    }
                                } label: {
                                    Image(systemName: revealedIDs.contains(credential.id)
                                          ? "eye.slash.fill" : "eye.fill")
                                        .foregroundColor(settings.accent)
                                }
                                .buttonStyle(.plain)

                                Button {
                                    UIPasteboard.general.string = credential.password
                                    copiedID = credential.id
                                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                                        if copiedID == credential.id { copiedID = nil }
                                    }
                                } label: {
                                    Image(systemName: copiedID == credential.id
                                          ? "checkmark.circle.fill" : "doc.on.doc")
                                        .foregroundColor(copiedID == credential.id ? .green : settings.accent)
                                }
                                .buttonStyle(.plain)

                                Button {
                                    store.remove(credential)
                                } label: {
                                    Image(systemName: "trash").foregroundColor(.red)
                                }
                                .buttonStyle(.plain)
                            }

                            if revealedIDs.contains(credential.id) {
                                Text(credential.password)
                                    .font(.system(size: 13, design: .monospaced))
                                    .foregroundColor(settings.accent)
                                    .padding(8)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .background(Color(UIColor(white: 0.12, alpha: 1)))
                                    .cornerRadius(8)
                            }
                        }
                        .padding(12)
                        if credential.id != store.items.last?.id {
                            Divider().overlay(Color.black.opacity(0.4))
                        }
                    }
                }
            }

            CardSection(title: "") {
                InfoRow(icon: "lock.shield", color: settings.accent, text: lang.t("pw.note"))
            }
        }
    }

    private func field(icon: String, placeholder: String, text: Binding<String>,
                       secure: Bool = false) -> some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .foregroundColor(settings.accent)
                .frame(width: 22)
            Group {
                if secure {
                    SecureField(placeholder, text: text)
                } else {
                    TextField(placeholder, text: text)
                }
            }
            .font(.app(14))
            .foregroundColor(.white)
            .autocapitalization(.none)
            .disableAutocorrection(true)
        }
        .padding(11)
        .background(Color(UIColor(white: 0.13, alpha: 1)))
        .cornerRadius(10)
    }
}

// MARK: - Private vault (biometric + encrypted)

struct VaultView: View {
    @ObservedObject private var vault = VaultStore.shared
    @ObservedObject private var settings = SettingsStore.shared
    @ObservedObject private var lang = LanguageManager.shared

    @State private var title = ""
    @State private var content = ""
    @State private var busy = false
    @State private var expandedID: UUID?

    var body: some View {
        ScreenShell(title: lang.t("screen.vault.title")) {
            if !vault.isUnlocked {
                lockedView
            } else {
                unlockedView
            }
        }
    }

    private var lockedView: some View {
        CardSection(title: "") {
            VStack(spacing: 16) {
                Image(systemName: "lock.shield.fill")
                    .font(.system(size: 52))
                    .foregroundColor(settings.accent)
                    .padding(.top, 12)
                Text(lang.t("vault.locked"))
                    .font(.app(16))
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                Text(lang.t("vault.lockedSub"))
                    .font(.app(13))
                    .foregroundColor(Color(UIColor.systemGray2))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 8)
                if let error = vault.lastError {
                    Text(error)
                        .font(.app(12))
                        .foregroundColor(.red)
                        .multilineTextAlignment(.center)
                }
                PrimaryButton(title: lang.t("vault.unlock"), icon: "faceid") {
                    busy = true
                    vault.unlock(reason: lang.t("vault.reason")) { _ in busy = false }
                }
                .disabled(busy)
                .padding(.horizontal, 12)
                .padding(.bottom, 14)
            }
            .frame(maxWidth: .infinity)
        }
    }

    private var unlockedView: some View {
        VStack(alignment: .leading, spacing: 18) {
            CardSection(title: lang.t("vault.add")) {
                VStack(spacing: 10) {
                    HStack(spacing: 10) {
                        Image(systemName: "text.cursor").foregroundColor(settings.accent).frame(width: 22)
                        TextField(lang.t("vault.titleField"), text: $title)
                            .font(.app(14)).foregroundColor(.white)
                    }
                    .padding(11)
                    .background(Color(UIColor(white: 0.13, alpha: 1)))
                    .cornerRadius(10)

                    HStack(alignment: .top, spacing: 10) {
                        Image(systemName: "doc.text").foregroundColor(settings.accent).frame(width: 22)
                        TextField(lang.t("vault.contentField"), text: $content, axis: .vertical)
                            .font(.app(14)).foregroundColor(.white)
                            .lineLimit(3...8)
                    }
                    .padding(11)
                    .background(Color(UIColor(white: 0.13, alpha: 1)))
                    .cornerRadius(10)

                    PrimaryButton(title: lang.t("vault.encrypt"), icon: "lock.fill") {
                        vault.add(title: title, content: content)
                        title = ""; content = ""
                    }
                }
                .padding(12)
            }

            CardSection(title: lang.t("vault.items")) {
                if vault.items.isEmpty {
                    EmptyState(icon: "lock", title: lang.t("vault.empty"))
                } else {
                    ForEach(vault.items) { item in
                        VStack(alignment: .leading, spacing: 6) {
                            Button {
                                appAnimate { expandedID = expandedID == item.id ? nil : item.id }
                            } label: {
                                HStack(spacing: 12) {
                                    Image(systemName: "doc.text.fill")
                                        .font(.system(size: 14))
                                        .foregroundColor(.black)
                                        .frame(width: 30, height: 30)
                                        .background(settings.accent)
                                        .cornerRadius(8)
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(item.title)
                                            .font(.app(15))
                                            .fontWeight(.semibold)
                                            .foregroundColor(.white)
                                            .lineLimit(1)
                                        Text(item.created, style: .date)
                                            .font(.app(11))
                                            .foregroundColor(Color(UIColor.systemGray2))
                                    }
                                    Spacer()
                                    Image(systemName: expandedID == item.id ? "chevron.up" : "chevron.down")
                                        .font(.system(size: 12))
                                        .foregroundColor(Color(UIColor.systemGray2))
                                }
                                .padding(12)
                                .contentShape(Rectangle())
                            }
                            .buttonStyle(.plain)

                            if expandedID == item.id {
                                Text(item.content)
                                    .font(.app(13))
                                    .foregroundColor(Color(UIColor.systemGray))
                                    .padding(10)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .background(Color(UIColor(white: 0.12, alpha: 1)))
                                    .cornerRadius(8)
                                Button(role: .destructive) {
                                    vault.remove(item)
                                    expandedID = nil
                                } label: {
                                    Label(lang.t("vault.delete"), systemImage: "trash")
                                        .font(.app(13))
                                        .foregroundColor(.red)
                                }
                                .buttonStyle(.plain)
                                .padding(.horizontal, 12)
                            }
                        }
                        if item.id != vault.items.last?.id {
                            Divider().overlay(Color.black.opacity(0.4))
                        }
                    }
                }
            }

            SecondaryButton(title: lang.t("vault.lock"), icon: "lock.fill") {
                vault.lock()
            }
        }
    }
}
