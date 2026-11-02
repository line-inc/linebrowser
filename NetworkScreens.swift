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
                VStack(spacing: Metrics.Space.md) {
                    HStack {
                        Text("\(store.entries.count) \(lang.t("monitor.captured"))")
                            .font(.app(TypeScale.caption))
                            .foregroundColor(AppColor.textSecondary)
                            .monospacedDigit()
                        Spacer()
                        if !store.entries.isEmpty {
                            Button(lang.t("monitor.clear")) {
                                appAnimate { store.clear() }
                            }
                            .font(.app(TypeScale.caption))
                            .fontWeight(.semibold)
                            .foregroundColor(settings.accent)
                            .buttonStyle(PressButtonStyle())
                            .frame(minHeight: Metrics.Touch.min)
                        }
                    }

                    searchField

                    if filtered.isEmpty {
                        EmptyState(icon: "waveform.path.ecg",
                                   title: store.entries.isEmpty ? lang.t("monitor.empty") : lang.t("monitor.noMatch"),
                                   subtitle: store.entries.isEmpty ? lang.t("monitor.emptySub") : nil)
                    } else {
                        VStack(spacing: Metrics.Space.sm) {
                            ForEach(filtered) { entry in
                                requestRow(entry)
                                    .transition(.opacity)
                                if entry.id != filtered.last?.id {
                                    Divider().overlay(AppColor.separator)
                                }
                            }
                        }
                        .animation(settings.reduceMotion ? nil : .easeOut(duration: 0.2),
                                   value: filtered)
                    }
                }
                .padding(Metrics.Space.md)
            }

            CardSection(title: "") {
                InfoRow(icon: "info.circle", color: AppColor.textTertiary, text: lang.t("monitor.note"))
                    .padding(.vertical, Metrics.Space.xs)
            }
        }
    }

    // MARK: - Filter

    private var searchField: some View {
        HStack(spacing: Metrics.Space.sm) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: Metrics.Icon.sm, weight: .medium))
                .foregroundColor(filterFocused ? settings.accent : AppColor.textTertiary)
                .frame(width: Metrics.Icon.lg)
                .accessibilityHidden(true)
            TextField(lang.t("monitor.search"), text: $filter)
                .font(.app(TypeScale.body))
                .foregroundColor(AppColor.textPrimary)
                .autocapitalization(.none)
                .disableAutocorrection(true)
                .focused($filterFocused)
            if !filter.isEmpty {
                Button {
                    appAnimate { filter = "" }
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: Metrics.Icon.md))
                        .foregroundColor(AppColor.textTertiary)
                }
                .buttonStyle(.plain)
                .frame(minWidth: Metrics.Touch.min, minHeight: Metrics.Touch.min)
                .contentShape(Rectangle())
                .accessibilityLabel(lang.t("monitor.search"))
            }
        }
        .padding(.horizontal, Metrics.Space.md)
        .frame(minHeight: Metrics.Touch.min)
        .background(AppColor.fill)
        .clipShape(RoundedRectangle(cornerRadius: Metrics.Radius.sm, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: Metrics.Radius.sm, style: .continuous)
                .stroke(settings.accent.opacity(filterFocused ? 0.9 : 0),
                        lineWidth: 1.5)
        )
        .animation(settings.reduceMotion ? nil : .easeOut(duration: 0.15),
                   value: filterFocused)
    }

    // MARK: - Rows

    private func requestRow(_ entry: RequestEntry) -> some View {
        HStack(alignment: .top, spacing: Metrics.Space.sm) {
            Image(systemName: kindIcon(entry.kind))
                .font(.system(size: Metrics.Icon.sm, weight: .medium))
                .foregroundColor(AppColor.textSecondary)
                .frame(width: Metrics.Tile.side, height: Metrics.Tile.side)
                .background(AppColor.fill)
                .clipShape(RoundedRectangle(cornerRadius: Metrics.Tile.radius, style: .continuous))
                .accessibilityHidden(true)
                .padding(.top, Metrics.Space.xs)

            VStack(alignment: .leading, spacing: Metrics.Space.xs) {
                Text(entry.url)
                    .font(.app(TypeScale.footnote))
                    .foregroundColor(AppColor.textPrimary)
                    .lineLimit(1)
                    .truncationMode(.middle)

                HStack(spacing: Metrics.Space.sm) {
                    if entry.status > 0 {
                        Text("\(entry.status)")
                            .foregroundColor(statusColor(entry.status))
                    } else {
                        Text("—")
                            .foregroundColor(AppColor.textTertiary)
                    }
                    Text(logTimeFormatter.string(from: entry.date))
                    if entry.ms > 0 {
                        Text("\(Int(entry.ms)) ms")
                    }
                    if entry.bytes > 0 {
                        Text(byteString(entry.bytes))
                    }
                }
                .font(.system(size: TypeScale.micro, weight: .medium, design: .monospaced))
                .foregroundColor(AppColor.textSecondary)
                .monospacedDigit()
                .lineLimit(1)
                .minimumScaleFactor(0.85)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(.vertical, Metrics.Space.xs)
        .frame(minHeight: Metrics.Touch.min, alignment: .top)
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
