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
                Divider().overlay(AppColor.separator)
                ToggleRow(icon: "clock.arrow.circlepath", color: .orange,
                          title: lang.t("privacy.clearOnExit"), subtitle: lang.t("privacy.clearOnExitSub"),
                          isOn: $settings.clearOnExit)
                Divider().overlay(AppColor.separator)
                ToggleRow(icon: "key.fill", color: .yellow,
                          title: lang.t("privacy.keychain"), subtitle: lang.t("privacy.keychainSub"),
                          isOn: .constant(true))
                    .disabled(true)
            }

            CardSection(title: lang.t("privacy.data"), subtitle: lang.t("privacy.dataSub")) {
                Button {
                    showClearConfirm = true
                } label: {
                    HStack(spacing: Metrics.Space.md) {
                        Image(systemName: clearing ? "arrow.triangle.2.circlepath" : "trash.fill")
                            .font(.system(size: Metrics.Icon.md, weight: .medium))
                            .foregroundColor(.white)
                            .frame(width: Metrics.Tile.side, height: Metrics.Tile.side)
                            .background(cleared ? Color.green : Color.red)
                            .clipShape(RoundedRectangle(cornerRadius: Metrics.Tile.radius, style: .continuous))
                            .accessibilityHidden(true)
                        Text(cleared ? lang.t("site.cleared") : lang.t("privacy.clearNow"))
                            .font(.app(TypeScale.body))
                            .fontWeight(.semibold)
                            .foregroundColor(cleared ? settings.accent : AppColor.textPrimary)
                        Spacer()
                    }
                    .padding(Metrics.Space.md)
                    .frame(minHeight: Metrics.Touch.min)
                    .contentShape(Rectangle())
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
                HStack(spacing: Metrics.Space.md) {
                    Image(systemName: isSecure ? "lock.fill" : "lock.open")
                        .font(.system(size: Metrics.Icon.md, weight: .medium))
                        .foregroundColor(.white)
                        .frame(width: Metrics.Tile.side, height: Metrics.Tile.side)
                        .background(isSecure ? settings.accent : .orange)
                        .clipShape(RoundedRectangle(cornerRadius: Metrics.Tile.radius, style: .continuous))
                        .accessibilityHidden(true)
                    VStack(alignment: .leading, spacing: Metrics.Space.xs) {
                        Text(isSecure ? lang.t("hub.secure") : lang.t("hub.insecure"))
                            .font(.app(TypeScale.body))
                            .fontWeight(.semibold)
                            .foregroundColor(AppColor.textPrimary)
                        Text(currentURL?.host ?? "—")
                            .font(.app(TypeScale.caption))
                            .foregroundColor(AppColor.textSecondary)
                            .lineLimit(1)
                    }
                    Spacer(minLength: Metrics.Space.sm)
                    Text(currentURL?.scheme?.uppercased() ?? "—")
                        .font(.app(TypeScale.caption))
                        .fontWeight(.bold)
                        .foregroundColor(settings.accent)
                }
                .padding(Metrics.Space.md)
                .frame(minHeight: Metrics.Touch.min, alignment: .leading)
            }

            CardSection(title: lang.t("hub.network")) {
                ToggleRow(icon: "shield.lefthalf.filled", color: settings.accent,
                          title: lang.t("privacy.blockAds"), subtitle: lang.t("privacy.blockAdsSub"),
                          isOn: $settings.blockAds)
                Divider().overlay(AppColor.separator)

                Button {
                    if let url = URL(string: UIApplication.openSettingsURLString) {
                        UIApplication.shared.open(url)
                    }
                } label: {
                    HStack(spacing: Metrics.Space.md) {
                        Image(systemName: "network")
                            .font(.system(size: Metrics.Icon.md, weight: .medium))
                            .foregroundColor(.white)
                            .frame(width: Metrics.Tile.side, height: Metrics.Tile.side)
                            .background(Color.indigo)
                            .clipShape(RoundedRectangle(cornerRadius: Metrics.Tile.radius, style: .continuous))
                            .accessibilityHidden(true)
                        VStack(alignment: .leading, spacing: Metrics.Space.xs) {
                            Text(lang.t("hub.dns"))
                                .font(.app(TypeScale.body))
                                .fontWeight(.semibold)
                                .foregroundColor(AppColor.textPrimary)
                            Text(lang.t("hub.dnsSub"))
                                .font(.app(TypeScale.caption))
                                .foregroundColor(AppColor.textSecondary)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                        Spacer(minLength: Metrics.Space.sm)
                        Image(systemName: "arrow.up.forward.app")
                            .font(.system(size: Metrics.Icon.sm, weight: .semibold))
                            .foregroundColor(settings.accent)
                            .accessibilityHidden(true)
                    }
                    .padding(.horizontal, Metrics.Space.md)
                    .frame(minHeight: Metrics.Touch.min)
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
                InfoRow(icon: "info.circle", color: AppColor.textTertiary, text: lang.t("hub.toolsNote"))
                Divider().overlay(AppColor.separator)
                InfoRow(icon: "checkmark.seal", color: settings.accent, text: lang.t("hub.trackingNote"))
            }
        }
    }

    private func hubRow(icon: String, color: Color, title: String,
                        subtitle: String, value: String) -> some View {
        HStack(spacing: Metrics.Space.md) {
            Image(systemName: icon)
                .font(.system(size: Metrics.Icon.md, weight: .medium))
                .foregroundColor(.white)
                .frame(width: Metrics.Tile.side, height: Metrics.Tile.side)
                .background(color)
                .clipShape(RoundedRectangle(cornerRadius: Metrics.Tile.radius, style: .continuous))
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: Metrics.Space.xs) {
                Text(title)
                    .font(.app(TypeScale.body))
                    .fontWeight(.semibold)
                    .foregroundColor(AppColor.textPrimary)
                Text(subtitle)
                    .font(.app(TypeScale.caption))
                    .foregroundColor(AppColor.textSecondary)
                    .lineLimit(1)
            }
            Spacer(minLength: Metrics.Space.sm)
            Text(value)
                .font(.app(TypeScale.footnote))
                .foregroundColor(settings.accent)
                .lineLimit(1)
        }
        .padding(.horizontal, Metrics.Space.md)
        .frame(minHeight: Metrics.Touch.min)
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
                VStack(spacing: Metrics.Space.md) {
                    field(icon: "globe", placeholder: lang.t("pw.site"), text: $site)
                    field(icon: "person", placeholder: lang.t("pw.username"), text: $username)
                    field(icon: "key", placeholder: lang.t("pw.password"), text: $password, secure: true)
                    PrimaryButton(title: lang.t("pw.save"), icon: "plus") {
                        guard !site.isEmpty, !password.isEmpty else { return }
                        store.add(site: site, username: username, password: password)
                        site = ""; username = ""; password = ""
                    }
                }
                .padding(Metrics.Space.md)
            }

            CardSection(title: lang.t("pw.saved")) {
                if store.items.isEmpty {
                    EmptyState(icon: "key", title: lang.t("pw.empty"),
                               subtitle: lang.t("pw.note"))
                } else {
                    ForEach(store.items) { credential in
                        VStack(alignment: .leading, spacing: Metrics.Space.sm) {
                            HStack(spacing: Metrics.Space.md) {
                                Image(systemName: "key.fill")
                                    .font(.system(size: Metrics.Icon.md, weight: .medium))
                                    .foregroundColor(.black)
                                    .frame(width: Metrics.Tile.side, height: Metrics.Tile.side)
                                    .background(Color.yellow)
                                    .clipShape(RoundedRectangle(cornerRadius: Metrics.Tile.radius, style: .continuous))
                                    .accessibilityHidden(true)
                                VStack(alignment: .leading, spacing: Metrics.Space.xs) {
                                    Text(credential.site)
                                        .font(.app(TypeScale.body))
                                        .fontWeight(.semibold)
                                        .foregroundColor(AppColor.textPrimary)
                                    Text(credential.username.isEmpty ? "—" : credential.username)
                                        .font(.app(TypeScale.caption))
                                        .foregroundColor(AppColor.textSecondary)
                                }
                                Spacer(minLength: Metrics.Space.sm)
                                Button {
                                    if revealedIDs.contains(credential.id) {
                                        revealedIDs.remove(credential.id)
                                    } else {
                                        revealedIDs.insert(credential.id)
                                    }
                                } label: {
                                    Image(systemName: revealedIDs.contains(credential.id)
                                          ? "eye.slash.fill" : "eye.fill")
                                        .font(.system(size: Metrics.Icon.md, weight: .medium))
                                        .foregroundColor(settings.accent)
                                        .frame(minWidth: Metrics.Touch.min, minHeight: Metrics.Touch.min)
                                        .contentShape(Rectangle())
                                }
                                .buttonStyle(.plain)
                                .accessibilityLabel(revealedIDs.contains(credential.id)
                                                    ? "Hide password" : "Reveal password")

                                Button {
                                    UIPasteboard.general.string = credential.password
                                    copiedID = credential.id
                                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                                        if copiedID == credential.id { copiedID = nil }
                                    }
                                } label: {
                                    Image(systemName: copiedID == credential.id
                                          ? "checkmark.circle.fill" : "doc.on.doc")
                                        .font(.system(size: Metrics.Icon.md, weight: .medium))
                                        .foregroundColor(copiedID == credential.id ? .green : settings.accent)
                                        .frame(minWidth: Metrics.Touch.min, minHeight: Metrics.Touch.min)
                                        .contentShape(Rectangle())
                                }
                                .buttonStyle(.plain)
                                .accessibilityLabel(copiedID == credential.id
                                                    ? "Password copied" : "Copy password")

                                Button {
                                    store.remove(credential)
                                } label: {
                                    Image(systemName: "trash")
                                        .font(.system(size: Metrics.Icon.md, weight: .medium))
                                        .foregroundColor(.red)
                                        .frame(minWidth: Metrics.Touch.min, minHeight: Metrics.Touch.min)
                                        .contentShape(Rectangle())
                                }
                                .buttonStyle(.plain)
                                .accessibilityLabel("Delete password")
                            }

                            if revealedIDs.contains(credential.id) {
                                Text(credential.password)
                                    .font(.system(size: TypeScale.footnote, design: .monospaced))
                                    .foregroundColor(settings.accent)
                                    .padding(Metrics.Space.sm)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .background(AppColor.fill)
                                    .clipShape(RoundedRectangle(cornerRadius: Metrics.Radius.sm, style: .continuous))
                            }
                        }
                        .padding(Metrics.Space.md)
                        if credential.id != store.items.last?.id {
                            Divider().overlay(AppColor.separator)
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
        HStack(spacing: Metrics.Space.md) {
            Image(systemName: icon)
                .font(.system(size: Metrics.Icon.md, weight: .medium))
                .foregroundColor(settings.accent)
                .frame(width: Metrics.Icon.lg)
                .accessibilityHidden(true)
            Group {
                if secure {
                    SecureField(placeholder, text: text)
                } else {
                    TextField(placeholder, text: text)
                }
            }
            .font(.app(TypeScale.body))
            .foregroundColor(AppColor.textPrimary)
            .autocapitalization(.none)
            .disableAutocorrection(true)
        }
        .padding(.horizontal, Metrics.Space.md)
        .frame(minHeight: Metrics.Touch.min)
        .background(AppColor.fill)
        .clipShape(RoundedRectangle(cornerRadius: Metrics.Radius.sm, style: .continuous))
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
            VStack(spacing: Metrics.Space.lg) {
                Image(systemName: "lock.shield.fill")
                    .font(.system(size: Metrics.Icon.xl + Metrics.Icon.lg))
                    .foregroundColor(settings.accent)
                    .accessibilityHidden(true)
                    .padding(.top, Metrics.Space.md)
                Text(lang.t("vault.locked"))
                    .font(.app(TypeScale.callout))
                    .fontWeight(.semibold)
                    .foregroundColor(AppColor.textPrimary)
                    .accessibilityAddTraits(.isHeader)
                Text(lang.t("vault.lockedSub"))
                    .font(.app(TypeScale.footnote))
                    .foregroundColor(AppColor.textSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, Metrics.Space.sm)
                if let error = vault.lastError {
                    Text(error)
                        .font(.app(TypeScale.caption))
                        .foregroundColor(.red)
                        .multilineTextAlignment(.center)
                }
                PrimaryButton(title: lang.t("vault.unlock"), icon: "faceid") {
                    busy = true
                    vault.unlock(reason: lang.t("vault.reason")) { _ in busy = false }
                }
                .disabled(busy)
                .padding(.horizontal, Metrics.Space.md)
                .padding(.bottom, Metrics.Space.md)
            }
            .frame(maxWidth: .infinity)
        }
    }

    private var unlockedView: some View {
        VStack(alignment: .leading, spacing: Metrics.Space.lg) {
            CardSection(title: lang.t("vault.add")) {
                VStack(spacing: Metrics.Space.md) {
                    HStack(spacing: Metrics.Space.md) {
                        Image(systemName: "text.cursor")
                            .font(.system(size: Metrics.Icon.md, weight: .medium))
                            .foregroundColor(settings.accent)
                            .frame(width: Metrics.Icon.lg)
                            .accessibilityHidden(true)
                        TextField(lang.t("vault.titleField"), text: $title)
                            .font(.app(TypeScale.body))
                            .foregroundColor(AppColor.textPrimary)
                    }
                    .padding(.horizontal, Metrics.Space.md)
                    .frame(minHeight: Metrics.Touch.min)
                    .background(AppColor.fill)
                    .clipShape(RoundedRectangle(cornerRadius: Metrics.Radius.sm, style: .continuous))

                    HStack(alignment: .top, spacing: Metrics.Space.md) {
                        Image(systemName: "doc.text")
                            .font(.system(size: Metrics.Icon.md, weight: .medium))
                            .foregroundColor(settings.accent)
                            .frame(width: Metrics.Icon.lg)
                            .padding(.top, Metrics.Space.xs)
                            .accessibilityHidden(true)
                        TextField(lang.t("vault.contentField"), text: $content, axis: .vertical)
                            .font(.app(TypeScale.body))
                            .foregroundColor(AppColor.textPrimary)
                            .lineLimit(3...8)
                    }
                    .padding(.horizontal, Metrics.Space.md)
                    .padding(.vertical, Metrics.Space.sm)
                    .background(AppColor.fill)
                    .clipShape(RoundedRectangle(cornerRadius: Metrics.Radius.sm, style: .continuous))

                    PrimaryButton(title: lang.t("vault.encrypt"), icon: "lock.fill") {
                        vault.add(title: title, content: content)
                        title = ""; content = ""
                    }
                }
                .padding(Metrics.Space.md)
            }

            CardSection(title: lang.t("vault.items")) {
                if vault.items.isEmpty {
                    EmptyState(icon: "lock", title: lang.t("vault.empty"))
                } else {
                    ForEach(vault.items) { item in
                        VStack(alignment: .leading, spacing: Metrics.Space.sm) {
                            Button {
                                appAnimate { expandedID = expandedID == item.id ? nil : item.id }
                            } label: {
                                HStack(spacing: Metrics.Space.md) {
                                    Image(systemName: "doc.text.fill")
                                        .font(.system(size: Metrics.Icon.md, weight: .medium))
                                        .foregroundColor(.black)
                                        .frame(width: Metrics.Tile.side, height: Metrics.Tile.side)
                                        .background(settings.accent)
                                        .clipShape(RoundedRectangle(cornerRadius: Metrics.Tile.radius, style: .continuous))
                                        .accessibilityHidden(true)
                                    VStack(alignment: .leading, spacing: Metrics.Space.xs) {
                                        Text(item.title)
                                            .font(.app(TypeScale.body))
                                            .fontWeight(.semibold)
                                            .foregroundColor(AppColor.textPrimary)
                                            .lineLimit(1)
                                        Text(item.created, style: .date)
                                            .font(.app(TypeScale.micro))
                                            .foregroundColor(AppColor.textSecondary)
                                    }
                                    Spacer(minLength: Metrics.Space.sm)
                                    Image(systemName: expandedID == item.id ? "chevron.up" : "chevron.down")
                                        .font(.system(size: Metrics.Icon.sm, weight: .semibold))
                                        .foregroundColor(AppColor.textTertiary)
                                        .accessibilityHidden(true)
                                }
                                .padding(Metrics.Space.md)
                                .frame(minHeight: Metrics.Touch.min)
                                .contentShape(Rectangle())
                            }
                            .buttonStyle(.plain)
                            .accessibilityValue(expandedID == item.id
                                                ? lang.t("privacy.on") : lang.t("privacy.off"))

                            if expandedID == item.id {
                                Text(item.content)
                                    .font(.app(TypeScale.footnote))
                                    .foregroundColor(AppColor.textSecondary)
                                    .padding(Metrics.Space.md)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .background(AppColor.fill)
                                    .clipShape(RoundedRectangle(cornerRadius: Metrics.Radius.sm, style: .continuous))
                                Button(role: .destructive) {
                                    vault.remove(item)
                                    expandedID = nil
                                } label: {
                                    Label(lang.t("vault.delete"), systemImage: "trash")
                                        .font(.app(TypeScale.footnote))
                                        .fontWeight(.medium)
                                        .foregroundColor(.red)
                                        .frame(minHeight: Metrics.Touch.min)
                                        .contentShape(Rectangle())
                                }
                                .buttonStyle(.plain)
                                .padding(.horizontal, Metrics.Space.md)
                            }
                        }
                        if item.id != vault.items.last?.id {
                            Divider().overlay(AppColor.separator)
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
