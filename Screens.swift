import SwiftUI
import UIKit

// MARK: - Design tokens
//
// Every repeated number in the UI lives here. Screens compose tokens; they
// never hardcode spacing, radii, icon sizes or text colours. Changing the
// look of the app is a one-file edit.

enum Metrics {

    /// 4/8pt spacing rhythm (xs → xxl). Section tiers use lg/xl/xxl.
    enum Space {
        static let xs: CGFloat = 4
        static let sm: CGFloat = 8
        static let md: CGFloat = 12
        static let lg: CGFloat = 16
        static let xl: CGFloat = 24
        static let xxl: CGFloat = 32
    }

    enum Radius {
        static let sm: CGFloat = 10
        static let md: CGFloat = 14
        static let lg: CGFloat = 18
        /// Full-round pill (address bar).
        static let pill: CGFloat = 20
    }

    /// SF Symbol point sizes — one per hierarchy level, never mixed ad hoc.
    enum Icon {
        static let sm: CGFloat = 14
        static let md: CGFloat = 16
        static let lg: CGFloat = 24
        static let xl: CGFloat = 28
    }

    /// Coloured tile behind a row's glyph.
    enum Tile {
        static let side: CGFloat = 32
        static let radius: CGFloat = 8
    }

    /// Apple's minimum touch target. Rows pad out to at least this.
    enum Touch {
        static let min: CGFloat = 44
    }

    /// Fixed browser chrome that overlays must clear.
    enum Chrome {
        /// Distance the error banner sits above the bottom toolbar.
        static let bannerClearance: CGFloat = 74
    }
}

/// Semantic type sizes. All go through `Font.app(_:)` so the in-app
/// "Text size" accessibility setting scales them together.
enum TypeScale {
    /// Dense metadata only (timestamps, byte counts) — never body copy.
    static let micro: CGFloat = 11
    static let caption: CGFloat = 12
    static let footnote: CGFloat = 13
    static let body: CGFloat = 15
    static let callout: CGFloat = 16
    static let title: CGFloat = 20
}

// MARK: - Semantic colours
//
// Values are chosen to clear WCAG AA (4.5:1) against `SettingsStore.cardColor`
// (#1E2024, relative luminance 0.0144):
//
//   secondary #9A9AA2 → 5.65:1   tertiary #8A8A91 → 4.60:1
//
// The previous hard-coded `systemGray2` (#636366) measured 2.72:1 and failed.

enum AppColor {
    static var textPrimary: Color { .white }

    static var textSecondary: Color {
        SettingsStore.shared.highContrast ? Color(0xC9C9D1) : Color(0x9A9AA2)
    }

    static var textTertiary: Color {
        SettingsStore.shared.highContrast ? Color(0xB4B4BC) : Color(0x8A8A91)
    }

    /// Hairline separators — visible in both light and dark wallpapers.
    static var separator: Color {
        SettingsStore.shared.highContrast
            ? Color.white.opacity(0.28)
            : Color.white.opacity(0.10)
    }

    /// Neutral fill for secondary buttons (was a hardcoded `white 0.13`).
    static var fill: Color { Color(0x212126) }

    /// Address-bar / toolbar surface.
    static var chromeFill: Color { Color(0x2C2C2E) }

    /// Error banner surface — must isolate the message from the page behind.
    static var dangerSurface: Color { Color(0x4A2020) }
}

// MARK: - Debug-only logging (compiled out of Release/App Store builds)

@inline(__always)
func debugLog(_ items: Any...) {
    #if DEBUG
    print(items.map { "\($0)" }.joined(separator: " "))
    #endif
}

// MARK: - Feel (haptics + press feedback)

enum Haptics {
    static func tap(_ style: UIImpactFeedbackGenerator.FeedbackStyle = .light) {
        UIImpactFeedbackGenerator(style: style).impactOccurred()
    }
    static func success() {
        UINotificationFeedbackGenerator().notificationOccurred(.success)
    }
}

/// The base "tap" feel: a short ease-out scale with a matching haptic.
/// The scale is applied to the label only, so surrounding layout never shifts.
struct PressButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.97 : 1)
            .opacity(configuration.isPressed ? 0.9 : 1)
            .animation(.easeOut(duration: 0.12), value: configuration.isPressed)
            .onChange(of: configuration.isPressed) { pressed in
                if pressed { Haptics.tap() }
            }
    }
}

/// Runs `changes` animated, unless "Reduce motion" is enabled in Settings.
func appAnimate(_ changes: () -> Void) {
    withAnimation(SettingsStore.shared.reduceMotion ? nil : .easeInOut(duration: 0.22), changes)
}

// MARK: - Screen chrome

/// Dark (or wallpaper) background used by every pushed screen.
struct ScreenBackground: ViewModifier {
    @ObservedObject var settings = SettingsStore.shared
    func body(content: Content) -> some View {
        ZStack {
            settings.backgroundView()
            content
        }
    }
}

extension View {
    func screenBackground() -> some View { modifier(ScreenBackground()) }
}

// MARK: - Row internals
//
// NavRow / ToggleRow / OptionRow share these two pieces instead of each
// re-declaring the same modifier chain.

/// Coloured tile + glyph. Decorative when a visible label sits beside it.
private struct RowIcon: View {
    let icon: String
    let color: Color

    var body: some View {
        Image(systemName: icon)
            .font(.system(size: Metrics.Icon.md, weight: .medium))
            .foregroundColor(.white)
            .frame(width: Metrics.Tile.side, height: Metrics.Tile.side)
            .background(color)
            .clipShape(RoundedRectangle(cornerRadius: Metrics.Tile.radius, style: .continuous))
            .accessibilityHidden(true)
    }
}

/// Title + optional subtitle, with contrast-corrected colours.
private struct RowText: View {
    let title: String
    var subtitle: String? = nil

    var body: some View {
        VStack(alignment: .leading, spacing: Metrics.Space.xs) {
            Text(title)
                .font(.app(TypeScale.body))
                .fontWeight(.semibold)
                .foregroundColor(AppColor.textPrimary)
                .multilineTextAlignment(.leading)
                .fixedSize(horizontal: false, vertical: true)
            if let subtitle {
                Text(subtitle)
                    .font(.app(TypeScale.caption))
                    .foregroundColor(AppColor.textSecondary)
                    .multilineTextAlignment(.leading)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

// MARK: - Building blocks for the settings screens

/// A titled group of rows on a rounded card.
struct CardSection<Content: View>: View {
    let title: String
    var subtitle: String? = nil
    @ViewBuilder var content: Content
    @ObservedObject var settings = SettingsStore.shared

    var body: some View {
        VStack(alignment: .leading, spacing: Metrics.Space.sm) {
            if !title.isEmpty {
                VStack(alignment: .leading, spacing: Metrics.Space.xs) {
                    Text(title)
                        .font(.app(TypeScale.caption))
                        .fontWeight(.bold)
                        .foregroundColor(settings.accent)
                        .accessibilityAddTraits(.isHeader)
                    if let subtitle {
                        Text(subtitle)
                            .font(.app(TypeScale.caption))
                            .foregroundColor(AppColor.textSecondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
                .padding(.leading, Metrics.Space.xs)
            }
            VStack(spacing: 0) { content }
                .background(settings.cardColor)
                .clipShape(RoundedRectangle(cornerRadius: Metrics.Radius.md, style: .continuous))
        }
    }
}

/// Row wrapper: guarantees the 44pt minimum target and the shared padding.
private struct RowSurface<Content: View>: View {
    @ViewBuilder var content: Content
    var body: some View {
        content
            .padding(.horizontal, Metrics.Space.md)
            .frame(minHeight: Metrics.Touch.min)
            .frame(maxWidth: .infinity, alignment: .leading)
            .contentShape(Rectangle())
    }
}

/// Tappable row. Draws its own chevron unless it sits inside a
/// `NavigationLink`, which already appends one (pass `showsChevron: false`
/// there or the row renders `> >`).
struct NavRow: View {
    let icon: String
    let color: Color
    let title: String
    var subtitle: String? = nil
    var value: String? = nil
    var showsChevron: Bool = true
    @ObservedObject var settings = SettingsStore.shared

    var body: some View {
        RowSurface {
            HStack(spacing: Metrics.Space.md) {
                RowIcon(icon: icon, color: color)
                RowText(title: title, subtitle: subtitle)
                if let value {
                    Text(value)
                        .font(.app(TypeScale.footnote))
                        .foregroundColor(settings.accent)
                        .layoutPriority(1)
                }
                if showsChevron {
                    Image(systemName: "chevron.right")
                        .font(.system(size: Metrics.Icon.sm, weight: .semibold))
                        .foregroundColor(AppColor.textTertiary)
                        .accessibilityHidden(true)
                }
            }
        }
    }
}

/// Switch row.
struct ToggleRow: View {
    let icon: String
    let color: Color
    let title: String
    var subtitle: String? = nil
    @Binding var isOn: Bool
    @ObservedObject var settings = SettingsStore.shared

    var body: some View {
        RowSurface {
            HStack(spacing: Metrics.Space.md) {
                RowIcon(icon: icon, color: color)
                RowText(title: title, subtitle: subtitle)
                Toggle("", isOn: $isOn)
                    .labelsHidden()
                    .tint(settings.accent)
                    .accessibilityLabel(title)
            }
        }
    }
}

/// Checkable single-choice row.
struct OptionRow: View {
    let icon: String
    let title: String
    var subtitle: String? = nil
    let isSelected: Bool
    let action: () -> Void
    @ObservedObject var settings = SettingsStore.shared

    var body: some View {
        Button(action: action) {
            RowSurface {
                HStack(spacing: Metrics.Space.md) {
                    RowIcon(icon: icon, color: settings.accent)
                    RowText(title: title, subtitle: subtitle)
                    Spacer(minLength: Metrics.Space.sm)
                    Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                        .font(.system(size: 20, weight: isSelected ? .bold : .regular))
                        .foregroundColor(isSelected ? settings.accent : AppColor.textTertiary)
                        .accessibilityHidden(true)
                }
            }
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(isSelected ? [.isSelected] : [])
    }
}

/// Consistent empty state for lists.
struct EmptyState: View {
    let icon: String
    let title: String
    var subtitle: String? = nil

    var body: some View {
        VStack(spacing: Metrics.Space.sm) {
            Image(systemName: icon)
                .font(.system(size: Metrics.Icon.xl, weight: .light))
                .foregroundColor(AppColor.textTertiary)
                .accessibilityHidden(true)
            Text(title)
                .font(.app(TypeScale.body))
                .fontWeight(.semibold)
                .foregroundColor(AppColor.textPrimary)
                .accessibilityAddTraits(.isHeader)
            if let subtitle {
                Text(subtitle)
                    .font(.app(TypeScale.caption))
                    .foregroundColor(AppColor.textTertiary)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, Metrics.Space.xl)
        .padding(.horizontal, Metrics.Space.md)
    }
}

/// Static explanation row. Informational, never tappable.
struct InfoRow: View {
    let icon: String
    let color: Color
    let text: String

    var body: some View {
        HStack(alignment: .top, spacing: Metrics.Space.md) {
            Image(systemName: icon)
                .font(.system(size: Metrics.Icon.sm, weight: .medium))
                .foregroundColor(color)
                .frame(width: Metrics.Icon.lg, alignment: .center)
                .accessibilityHidden(true)
            Text(text)
                .font(.app(TypeScale.footnote))
                .foregroundColor(AppColor.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
            Spacer(minLength: 0)
        }
        .padding(Metrics.Space.md)
        .frame(minHeight: Metrics.Touch.min, alignment: .top)
    }
}

// MARK: - Buttons

struct PrimaryButton: View {
    let title: String
    var icon: String? = nil
    let action: () -> Void
    @ObservedObject var settings = SettingsStore.shared

    /// Black on the accent clears 4.5:1 for every accent in the palette.
    private var onAccent: Color { .black }

    var body: some View {
        Button(action: action) {
            HStack(spacing: Metrics.Space.sm) {
                if let icon {
                    Image(systemName: icon)
                        .font(.system(size: Metrics.Icon.md, weight: .semibold))
                        .accessibilityHidden(true)
                }
                Text(title)
                    .font(.app(TypeScale.callout))
                    .fontWeight(.semibold)
            }
            .foregroundColor(onAccent)
            .frame(maxWidth: .infinity)
            .frame(minHeight: Metrics.Touch.min)
            .padding(.vertical, Metrics.Space.sm)
            .background(settings.accent)
            .clipShape(RoundedRectangle(cornerRadius: Metrics.Radius.md, style: .continuous))
        }
        .buttonStyle(PressButtonStyle())
    }
}

struct SecondaryButton: View {
    let title: String
    var icon: String? = nil
    var color: Color = AppColor.textSecondary
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: Metrics.Space.sm) {
                if let icon {
                    Image(systemName: icon)
                        .font(.system(size: Metrics.Icon.md, weight: .medium))
                        .accessibilityHidden(true)
                }
                Text(title)
                    .font(.app(TypeScale.body))
                    .fontWeight(.medium)
            }
            .foregroundColor(color)
            .frame(maxWidth: .infinity)
            .frame(minHeight: Metrics.Touch.min)
            .padding(.vertical, Metrics.Space.sm)
            .background(AppColor.fill)
            .clipShape(RoundedRectangle(cornerRadius: Metrics.Radius.md, style: .continuous))
        }
        .buttonStyle(PressButtonStyle())
    }
}

/// Standard scrollable screen chrome.
struct ScreenShell<Content: View>: View {
    let title: String
    @ViewBuilder var content: Content
    @ObservedObject private var settings = SettingsStore.shared
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ZStack {
            settings.backgroundView()
            ScrollView {
                VStack(alignment: .leading, spacing: Metrics.Space.xl) {
                    content
                }
                .padding(.horizontal, Metrics.Space.lg)
                .padding(.top, Metrics.Space.md)
                .padding(.bottom, Metrics.Space.xxl)
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .navigationTitle(title)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(LanguageManager.shared.t("settings.done")) { dismiss() }
                    .foregroundColor(SettingsStore.shared.accent)
            }
        }
    }
}
