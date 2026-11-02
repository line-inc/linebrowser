import SwiftUI

// MARK: - Shared bits

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
