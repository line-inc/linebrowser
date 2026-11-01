import SwiftUI
import UIKit

/// Debug-only logging: compiled out of Release/App Store builds.
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

// MARK: - Building blocks for the settings screens

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

/// A titled group of rows on a rounded card.
struct CardSection<Content: View>: View {
    let title: String
    var subtitle: String? = nil
    @ViewBuilder var content: Content
    @ObservedObject var settings = SettingsStore.shared

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            if !title.isEmpty {
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.app(12))
                        .fontWeight(.bold)
                        .foregroundColor(settings.accent)
                    if let subtitle {
                        Text(subtitle)
                            .font(.app(12))
                            .foregroundColor(Color(UIColor.systemGray2))
                    }
                }
                .padding(.leading, 4)
            }
            VStack(spacing: 0) { content }
                .background(settings.cardColor)
                .cornerRadius(14)
        }
    }
}

/// Tappable row that pushes a destination.
struct NavRow: View {
    let icon: String
    let color: Color
    let title: String
    var subtitle: String? = nil
    var value: String? = nil

    var body: some View {
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
                if let subtitle {
                    Text(subtitle)
                        .font(.app(12))
                        .foregroundColor(Color(UIColor.systemGray2))
                }
            }
            Spacer()
            if let value {
                Text(value)
                    .font(.app(13))
                    .foregroundColor(settings.accent)
            }
            Image(systemName: "chevron.right")
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(Color(UIColor.systemGray2))
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .contentShape(Rectangle())
    }

    @ObservedObject var settings = SettingsStore.shared
}

/// Switch row.
struct ToggleRow: View {
    let icon: String
    let color: Color
    let title: String
    var subtitle: String? = nil
    @Binding var isOn: Bool

    var body: some View {
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
                if let subtitle {
                    Text(subtitle)
                        .font(.app(12))
                        .foregroundColor(Color(UIColor.systemGray2))
                }
            }
            Spacer()
            Toggle("", isOn: $isOn)
                .labelsHidden()
                .tint(settings.accent)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
    }

    @ObservedObject var settings = SettingsStore.shared
}

/// Checkable single-choice row.
struct OptionRow: View {
    let icon: String
    let title: String
    var subtitle: String? = nil
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 14) {
                Image(systemName: icon)
                    .font(.system(size: 15))
                    .foregroundColor(.white)
                    .frame(width: 32, height: 32)
                    .background(settings.accent)
                    .cornerRadius(8)
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.app(15))
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                    if let subtitle {
                        Text(subtitle)
                            .font(.app(12))
                            .foregroundColor(Color(UIColor.systemGray2))
                    }
                }
                Spacer()
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 20))
                    .foregroundColor(isSelected ? settings.accent : Color(UIColor.systemGray2))
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    @ObservedObject var settings = SettingsStore.shared
}

/// Consistent empty state for lists.
struct EmptyState: View {
    let icon: String
    let title: String
    var subtitle: String? = nil

    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 26))
                .foregroundColor(Color(UIColor.systemGray2))
            Text(title)
                .font(.app(14))
                .fontWeight(.semibold)
                .foregroundColor(.white)
            if let subtitle {
                Text(subtitle)
                    .font(.app(12))
                    .foregroundColor(Color(UIColor.systemGray3))
                    .multilineTextAlignment(.center)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 18)
        .padding(.horizontal, 12)
    }
}

/// Static explanation row.
struct InfoRow: View {
    let icon: String
    let color: Color
    let text: String

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 14))
                .foregroundColor(color)
                .frame(width: 24)
            Text(text)
                .font(.app(13))
                .foregroundColor(Color(UIColor.systemGray))
                .fixedSize(horizontal: false, vertical: true)
            Spacer(minLength: 0)
        }
        .padding(12)
    }
}

// MARK: - Buttons

struct PrimaryButton: View {
    let title: String
    var icon: String? = nil
    let action: () -> Void
    @ObservedObject var settings = SettingsStore.shared

    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                if let icon { Image(systemName: icon) }
                Text(title)
                    .font(.app(16))
                    .fontWeight(.semibold)
            }
            .foregroundColor(.black)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(settings.accent)
            .cornerRadius(14)
        }
        .buttonStyle(PressButtonStyle())
    }
}

struct SecondaryButton: View {
    let title: String
    var icon: String? = nil
    var color: Color = Color(UIColor.systemGray2)
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                if let icon { Image(systemName: icon) }
                Text(title).font(.app(15)).fontWeight(.medium)
            }
            .foregroundColor(color)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 13)
            .background(Color(UIColor(white: 0.13, alpha: 1)))
            .cornerRadius(14)
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
                VStack(alignment: .leading, spacing: 18) {
                    content
                }
                .padding(.horizontal, 16)
                .padding(.top, 10)
                .padding(.bottom, 32)
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
