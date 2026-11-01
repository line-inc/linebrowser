import SwiftUI
import NetworkExtension

// MARK: - Shared bits

private func statusAccent(_ status: NEVPNStatus) -> Color {
    switch status {
    case .connected, .reasserting: return .green
    case .connecting, .disconnecting: return .orange
    case .invalid: return Color(UIColor.systemGray2)
    default: return .gray
    }
}

private func isActive(_ status: NEVPNStatus) -> Bool {
    status == .connected || status == .connecting
        || status == .reasserting || status == .disconnecting
}

private let logTimeFormatter: DateFormatter = {
    let f = DateFormatter()
    f.dateFormat = "HH:mm:ss"
    return f
}()

private func byteString(_ bytes: Int) -> String {
    let b = Double(bytes)
    if b >= 1_048_576 { return String(format: "%.1f MB", b / 1_048_576) }
    if b >= 1024 { return String(format: "%.1f KB", b / 1024) }
    return "\(bytes) B"
}

// MARK: - Packet Sniffer (device-wide DNS log + blocking)

struct DnsSnifferView: View {
    @ObservedObject private var tunnel = TunnelManager.shared
    @ObservedObject private var log = DnsLogStore.shared
    @ObservedObject private var settings = SettingsStore.shared
    @ObservedObject private var lang = LanguageManager.shared
    @AppStorage(AppGroup.blockAdsKey, store: UserDefaults(suiteName: AppGroup.id))
    private var blockAds = true

    @State private var filter = ""
    @State private var pulse = false
    @FocusState private var filterFocused: Bool

    private var filtered: [DnsEntry] {
        guard !filter.isEmpty else { return log.entries }
        let f = filter.lowercased()
        return log.entries.filter { $0.host.contains(f) }
    }

    var body: some View {
        ScreenShell(title: lang.t("screen.sniffer.title")) {
            // ── Status ────────────────────────────────────────────────
            CardSection(title: lang.t("sniffer.status")) {
                HStack(spacing: 14) {
                    Image(systemName: "antenna.radiowaves.left.and.right")
                        .font(.system(size: 15))
                        .foregroundColor(.white)
                        .frame(width: 34, height: 34)
                        .background(statusAccent(tunnel.status))
                        .cornerRadius(9)
                        .scaleEffect(pulse ? 1.12 : 1)
                    VStack(alignment: .leading, spacing: 3) {
                        Text(lang.t(netStatusKey(tunnel.status)))
                            .font(.app(15))
                            .fontWeight(.semibold)
                            .foregroundColor(.white)
                            .contentTransition(.opacity)
                        Text("\(log.entries.count) \(lang.t("sniffer.queries"))")
                            .font(.app(12))
                            .foregroundColor(Color(UIColor.systemGray2))
                            .monospacedDigit()
                    }
                    Spacer()
                    if tunnel.busy {
                        ProgressView()
                            .tint(settings.accent)
                            .transition(.opacity)
                    }
                }
                .padding(12)
                .animation(settings.reduceMotion ? nil : .easeOut(duration: 0.18),
                           value: tunnel.status)

                if let error = tunnel.lastError {
                    InfoRow(icon: "exclamationmark.triangle.fill", color: .red, text: error)
                        .padding(.horizontal, 12)
                        .padding(.bottom, 10)
                        .transition(.opacity)
                }

                VStack(spacing: 10) {
                    if isActive(tunnel.status) {
                        SecondaryButton(title: lang.t("sniffer.stop"), icon: "stop.fill", color: .red) {
                            tunnel.toggle()
                        }
                        .transition(.opacity)
                    } else {
                        PrimaryButton(title: lang.t("sniffer.start"), icon: "play.fill") {
                            tunnel.toggle()
                        }
                        .transition(.opacity)
                    }
                }
                .padding(.horizontal, 12)
                .padding(.bottom, 12)
                .animation(settings.reduceMotion ? nil : .easeOut(duration: 0.16),
                           value: tunnel.status)
            }

            // ── Options ───────────────────────────────────────────────
            CardSection(title: lang.t("sniffer.options")) {
                ToggleRow(icon: "shield.lefthalf.filled", color: settings.accent,
                          title: lang.t("sniffer.blockAds"),
                          subtitle: lang.t("sniffer.blockAdsSub"),
                          isOn: $blockAds)
                Divider().overlay(Color.black.opacity(0.4))
                InfoRow(icon: "info.circle", color: .gray, text: lang.t("sniffer.note"))
                    .padding(.vertical, 6)
            }

            // ── Live log ──────────────────────────────────────────────
            CardSection(title: "\(lang.t("sniffer.log")) (\(log.entries.count))") {
                VStack(spacing: 10) {
                    HStack(spacing: 10) {
                        Image(systemName: "magnifyingglass")
                            .foregroundColor(Color(UIColor.systemGray2))
                            .frame(width: 22)
                        TextField(lang.t("sniffer.search"), text: $filter)
                            .font(.app(14))
                            .foregroundColor(.white)
                            .autocapitalization(.none)
                            .disableAutocorrection(true)
                            .focused($filterFocused)
                    }
                    .padding(11)
                    .background(Color(UIColor(white: 0.13, alpha: 1)))
                    .cornerRadius(10)
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(settings.accent.opacity(filterFocused ? 0.9 : 0),
                                    lineWidth: 1.5)
                    )
                    .animation(settings.reduceMotion ? nil : .easeOut(duration: 0.15),
                               value: filterFocused)

                    if filtered.isEmpty {
                        EmptyState(icon: log.entries.isEmpty ? "antenna.radiowaves.left.and.right" : "magnifyingglass",
                                   title: log.entries.isEmpty ? lang.t("sniffer.empty") : lang.t("sniffer.noMatch"),
                                   subtitle: log.entries.isEmpty ? lang.t("sniffer.emptySub") : nil)
                    } else {
                        VStack(spacing: 7) {
                            ForEach(filtered) { entry in
                                logRow(entry)
                                    .transition(.opacity)
                                if entry.id != filtered.last?.id {
                                    Divider().overlay(Color.black.opacity(0.35))
                                }
                            }
                        }
                        .animation(settings.reduceMotion ? nil : .easeOut(duration: 0.2),
                                   value: filtered)
                    }

                    if !log.entries.isEmpty {
                        SecondaryButton(title: lang.t("sniffer.clear"), icon: "trash") {
                            appAnimate { log.clear() }
                        }
                    }
                }
                .padding(12)
            }
        }
        .onAppear {
            tunnel.load()
            log.reload()
            updatePulse(tunnel.status)
        }
        .onReceive(Timer.publish(every: 2, on: .main, in: .common).autoconnect()) { _ in
            tunnel.refresh()
            log.reload()
        }
        .onChange(of: tunnel.status) { status in
            updatePulse(status)
            if status == .connected { Haptics.success() }
        }
    }

    private func logRow(_ entry: DnsEntry) -> some View {
        HStack(spacing: 10) {
            Circle()
                .fill(entry.blocked ? Color.red : Color.green)
                .frame(width: 7, height: 7)
            VStack(alignment: .leading, spacing: 2) {
                Text(entry.host)
                    .font(.app(14))
                    .fontWeight(.medium)
                    .foregroundColor(.white)
                    .lineLimit(1)
                    .truncationMode(.middle)
                Text("\(logTimeFormatter.string(from: entry.date)) · \(entry.qt)")
                    .font(.app(11))
                    .foregroundColor(Color(UIColor.systemGray3))
                    .monospacedDigit()
            }
            Spacer(minLength: 6)
            if entry.blocked {
                Text(lang.t("sniffer.blocked"))
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(.red)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 3)
                    .background(Color.red.opacity(0.14))
                    .cornerRadius(5)
            }
        }
    }

    private func updatePulse(_ status: NEVPNStatus) {
        if status == .connected, !settings.reduceMotion, !pulse {
            withAnimation(.easeInOut(duration: 1.0).repeatForever(autoreverses: true)) {
                pulse = true
            }
        } else if status != .connected, pulse {
            withAnimation(.easeOut(duration: 0.2)) { pulse = false }
        }
    }
}

// MARK: - IKEv2 VPN client

struct VpnClientView: View {
    @ObservedObject private var vpn = IKEv2Manager.shared
    @ObservedObject private var settings = SettingsStore.shared
    @ObservedObject private var lang = LanguageManager.shared

    var body: some View {
        ScreenShell(title: lang.t("screen.vpn.title")) {
            // ── Status ────────────────────────────────────────────────
            CardSection(title: lang.t("sniffer.status")) {
                HStack(spacing: 14) {
                    Image(systemName: "lock.shield.fill")
                        .font(.system(size: 15))
                        .foregroundColor(.white)
                        .frame(width: 34, height: 34)
                        .background(statusAccent(vpn.status))
                        .cornerRadius(9)
                    VStack(alignment: .leading, spacing: 3) {
                        Text(lang.t(netStatusKey(vpn.status)))
                            .font(.app(15))
                            .fontWeight(.semibold)
                            .foregroundColor(.white)
                            .contentTransition(.opacity)
                        Text(vpn.status == .connected && !vpn.server.isEmpty
                             ? vpn.server : lang.t("vpn.statusSub"))
                            .font(.app(12))
                            .foregroundColor(Color(UIColor.systemGray2))
                            .lineLimit(1)
                            .contentTransition(.opacity)
                    }
                    Spacer()
                    if vpn.busy {
                        ProgressView()
                            .tint(settings.accent)
                            .transition(.opacity)
                    }
                }
                .padding(12)
                .animation(settings.reduceMotion ? nil : .easeOut(duration: 0.18),
                           value: vpn.status)

                if let error = vpn.lastError {
                    InfoRow(icon: "exclamationmark.triangle.fill", color: .red, text: error)
                        .padding(.horizontal, 12)
                        .padding(.bottom, 10)
                        .transition(.opacity)
                }

                VStack(spacing: 10) {
                    if isActive(vpn.status) {
                        SecondaryButton(title: lang.t("vpn.disconnect"), icon: "stop.fill", color: .red) {
                            vpn.toggle()
                        }
                        .transition(.opacity)
                    } else {
                        PrimaryButton(title: lang.t("vpn.connect"), icon: "power") {
                            vpn.toggle()
                        }
                        .transition(.opacity)
                    }
                }
                .padding(.horizontal, 12)
                .padding(.bottom, 12)
                .animation(settings.reduceMotion ? nil : .easeOut(duration: 0.16),
                           value: vpn.status)
            }

            // ── Server & credentials ──────────────────────────────────
            CardSection(title: lang.t("vpn.credentials")) {
                VStack(spacing: 10) {
                    field(icon: "server.rack", placeholder: lang.t("vpn.server"),
                          text: $vpn.server)
                    field(icon: "number", placeholder: lang.t("vpn.remoteId"),
                          text: $vpn.remoteID)
                    field(icon: "person", placeholder: lang.t("vpn.username"),
                          text: $vpn.username)
                    field(icon: "key", placeholder: lang.t("vpn.password"),
                          text: $vpn.password, secure: true)
                }
                .padding(12)
            }

            // ── Honest note ───────────────────────────────────────────
            CardSection(title: "") {
                InfoRow(icon: "info.circle", color: .gray, text: lang.t("vpn.note"))
                    .padding(.vertical, 6)
            }
        }
        .onAppear { vpn.load() }
        .onChange(of: vpn.status) { status in
            if status == .connected { Haptics.success() }
        }
        .onReceive(Timer.publish(every: 2, on: .main, in: .common).autoconnect()) { _ in
            vpn.refresh()
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

// MARK: - Network Monitor (every request the browser tab makes)

struct NetworkMonitorView: View {
    @ObservedObject private var store = RequestStore.shared
    @ObservedObject private var settings = SettingsStore.shared
    @ObservedObject private var lang = LanguageManager.shared

    @State private var filter = ""
    @FocusState private var filterFocused: Bool

    private var filtered: [RequestEntry] {
        guard !filter.isEmpty else { return store.entries }
        let f = filter.lowercased()
        return store.entries.filter { $0.url.lowercased().contains(f) }
    }

    var body: some View {
        ScreenShell(title: lang.t("screen.monitor.title")) {
            CardSection(title: lang.t("monitor.live")) {
                VStack(spacing: 10) {
                    HStack {
                        Text("\(store.entries.count) \(lang.t("monitor.captured"))")
                            .font(.app(12))
                            .foregroundColor(Color(UIColor.systemGray2))
                            .monospacedDigit()
                        Spacer()
                        if !store.entries.isEmpty {
                            Button(lang.t("monitor.clear")) {
                                appAnimate { store.clear() }
                            }
                            .font(.app(12))
                            .fontWeight(.semibold)
                            .foregroundColor(settings.accent)
                            .buttonStyle(PressButtonStyle())
                        }
                    }

                    HStack(spacing: 10) {
                        Image(systemName: "magnifyingglass")
                            .foregroundColor(Color(UIColor.systemGray2))
                            .frame(width: 22)
                        TextField(lang.t("monitor.search"), text: $filter)
                            .font(.app(14))
                            .foregroundColor(.white)
                            .autocapitalization(.none)
                            .disableAutocorrection(true)
                            .focused($filterFocused)
                    }
                    .padding(11)
                    .background(Color(UIColor(white: 0.13, alpha: 1)))
                    .cornerRadius(10)
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(settings.accent.opacity(filterFocused ? 0.9 : 0),
                                    lineWidth: 1.5)
                    )
                    .animation(settings.reduceMotion ? nil : .easeOut(duration: 0.15),
                               value: filterFocused)

                    if filtered.isEmpty {
                        EmptyState(icon: "waveform.path.ecg",
                                   title: store.entries.isEmpty ? lang.t("monitor.empty") : lang.t("monitor.noMatch"),
                                   subtitle: store.entries.isEmpty ? lang.t("monitor.emptySub") : nil)
                    } else {
                        VStack(spacing: 6) {
                            ForEach(filtered) { entry in
                                requestRow(entry)
                                    .transition(.opacity)
                                if entry.id != filtered.last?.id {
                                    Divider().overlay(Color.black.opacity(0.35))
                                }
                            }
                        }
                        .animation(settings.reduceMotion ? nil : .easeOut(duration: 0.2),
                                   value: filtered)
                    }
                }
                .padding(12)
            }

            CardSection(title: "") {
                InfoRow(icon: "info.circle", color: .gray, text: lang.t("monitor.note"))
                    .padding(.vertical, 6)
            }
        }
    }

    private func requestRow(_ entry: RequestEntry) -> some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: kindIcon(entry.kind))
                .font(.system(size: 12))
                .foregroundColor(Color(UIColor.systemGray2))
                .frame(width: 26, height: 26)
                .background(Color(UIColor(white: 0.16, alpha: 1)))
                .cornerRadius(7)
                .padding(.top, 1)
            VStack(alignment: .leading, spacing: 3) {
                Text(entry.url)
                    .font(.app(13))
                    .foregroundColor(.white)
                    .lineLimit(1)
                    .truncationMode(.middle)
                HStack(spacing: 6) {
                    if entry.status > 0 {
                        Text("\(entry.status)")
                            .font(.system(size: 10, weight: .bold, design: .monospaced))
                            .foregroundColor(statusColor(entry.status))
                    } else {
                        Text("—")
                            .font(.system(size: 10, weight: .bold, design: .monospaced))
                            .foregroundColor(Color(UIColor.systemGray3))
                    }
                    Text(logTimeFormatter.string(from: entry.date))
                        .monospacedDigit()
                    if entry.ms > 0 {
                        Text("\(Int(entry.ms)) ms")
                            .monospacedDigit()
                    }
                    if entry.bytes > 0 {
                        Text(byteString(entry.bytes))
                            .monospacedDigit()
                    }
                }
                .font(.app(10))
                .foregroundColor(Color(UIColor.systemGray2))
            }
        }
        .padding(.horizontal, 2)
        .padding(.vertical, 4)
    }

    private func kindIcon(_ kind: String) -> String {
        switch kind {
        case "doc": return "globe"
        case "fetch": return "arrow.triangle.2.circlepath"
        case "xhr", "xmlhttprequest": return "arrow.up.right"
        case "img", "image": return "photo"
        case "script": return "curlybraces"
        case "link", "css": return "paintbrush"
        case "font": return "textformat"
        case "iframe", "frame": return "rectangle.on.rectangle"
        case "video", "audio": return "play.rectangle"
        case "beacon": return "dot.radiowaves.up.forward"
        default: return "circle.dashed"
        }
    }

    private func statusColor(_ status: Int) -> Color {
        switch status {
        case 200..<300: return .green
        case 300..<400: return .blue
        case 400..<500: return .orange
        default: return .red
        }
    }
}
