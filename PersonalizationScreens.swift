import SwiftUI
import PhotosUI

// MARK: - One-off hero sizes
//
// Two preview surfaces need a height the shared `Metrics` rhythm doesn't
// express. They are named here so no magic number is ever written inline in
// a modifier.

private enum PreviewSize {
    /// Preset wallpaper thumbnail height in the 3-up grid.
    static let wallpaperThumb: CGFloat = 64
    /// Full custom-wallpaper preview.
    static let customPreview: CGFloat = 140
}

// MARK: - Theme

struct ThemeSettingsView: View {
    @ObservedObject private var settings = SettingsStore.shared
    @ObservedObject private var lang = LanguageManager.shared

    private static let accents: [(name: String, hex: UInt32)] = [
        ("green",  0x34C759),
        ("blue",   0x0A84FF),
        ("indigo", 0x5E5CE6),
        ("purple", 0xBF5AF2),
        ("pink",   0xFF375F),
        ("red",    0xFF453A),
        ("orange", 0xFF9F0A),
        ("yellow", 0xFFD60A),
        ("teal",   0x64D2FF),
        ("gray",   0xF2F2F7),
    ]

    var body: some View {
        ScreenShell(title: lang.t("screen.theme.title")) {
            CardSection(title: lang.t("theme.accent")) {
                LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 5),
                          spacing: Metrics.Space.md) {
                    ForEach(Self.accents, id: \.hex) { item in
                        Button {
                            appAnimate { settings.accentHex = item.hex }
                        } label: {
                            Circle()
                                .fill(Color(item.hex))
                                .frame(width: Metrics.Touch.min, height: Metrics.Touch.min)
                                .overlay(
                                    Circle().stroke(AppColor.textPrimary,
                                                    lineWidth: settings.accentHex == item.hex ? 3 : 0)
                                )
                                .shadow(color: Color(item.hex).opacity(0.5),
                                        radius: settings.accentHex == item.hex ? Metrics.Space.sm : 0)
                        }
                        .buttonStyle(PressButtonStyle())
                        .accessibilityLabel(item.name)
                        .accessibilityAddTraits(settings.accentHex == item.hex ? [.isSelected] : [])
                    }
                }
                .padding(Metrics.Space.md)
            }

            CardSection(title: lang.t("theme.surface")) {
                ToggleRow(icon: "circle.fill", color: .black,
                          title: lang.t("theme.oled"), subtitle: lang.t("theme.oledSub"),
                          isOn: $settings.pureBlack)
                Divider().overlay(AppColor.separator)
                ToggleRow(icon: "circle.lefthalf.filled", color: AppColor.textTertiary,
                          title: lang.t("a11y.contrast"), subtitle: lang.t("a11y.contrastSub"),
                          isOn: $settings.highContrast)
            }

            CardSection(title: lang.t("theme.preview")) {
                VStack(spacing: Metrics.Space.md) {
                    // Mock address bar.
                    HStack(spacing: Metrics.Space.md) {
                        RoundedRectangle(cornerRadius: Metrics.Tile.radius)
                            .fill(settings.accent)
                            .frame(width: Metrics.Tile.side, height: Metrics.Tile.side)
                            // On-accent glyph, same rule as `PrimaryButton`.
                            .overlay(RoundedRectangle(cornerRadius: Metrics.Space.xs)
                                .fill(Color.black)
                                .frame(width: Metrics.Space.md, height: Metrics.Space.xs))
                            .accessibilityHidden(true)
                        HStack {
                            Image(systemName: "lock.fill")
                                .font(.system(size: Metrics.Icon.sm, weight: .medium))
                                .foregroundColor(settings.accent)
                                .accessibilityHidden(true)
                            Text(lang.t("chrome.placeholder"))
                                .font(.app(TypeScale.footnote))
                                .foregroundColor(AppColor.textPrimary.opacity(0.8))
                            Spacer()
                        }
                        .padding(Metrics.Space.sm)
                        .background(AppColor.fill)
                        .clipShape(Capsule())
                    }
                    .padding(Metrics.Space.md)
                    .background(settings.chromeColor)
                    .clipShape(RoundedRectangle(cornerRadius: Metrics.Radius.md, style: .continuous))

                    // Mock toolbar.
                    HStack {
                        Image(systemName: "house.fill").foregroundColor(AppColor.textPrimary)
                        Spacer()
                        Image(systemName: "star.fill").foregroundColor(settings.accent)
                        Spacer()
                        Image(systemName: "plus.circle.fill").foregroundColor(AppColor.textPrimary)
                        Spacer()
                        Image(systemName: "ellipsis.circle.fill").foregroundColor(AppColor.textPrimary)
                    }
                    .font(.system(size: Metrics.Icon.md, weight: .medium))
                    .padding(.horizontal, Metrics.Space.xl)
                    .padding(.vertical, Metrics.Space.md)
                    .background(settings.chromeColor)
                    .clipShape(RoundedRectangle(cornerRadius: Metrics.Radius.md, style: .continuous))
                    .accessibilityHidden(true)
                }
                .padding(Metrics.Space.md)
            }
        }
    }
}

// MARK: - Preferences & Layout

struct LayoutSettingsView: View {
    @ObservedObject private var settings = SettingsStore.shared
    @ObservedObject private var lang = LanguageManager.shared
    @State private var homeDraft: String = ""

    var body: some View {
        ScreenShell(title: lang.t("screen.layout.title")) {
            CardSection(title: lang.t("layout.bar")) {
                OptionRow(icon: "rectangle.lefthalf.inset.filled", title: lang.t("layout.barTop"),
                          isSelected: settings.addressBarTop) {
                    settings.addressBarTop = true
                }
                Divider().overlay(AppColor.separator)
                OptionRow(icon: "rectangle.righthalf.inset.filled", title: lang.t("layout.barBottom"),
                          isSelected: !settings.addressBarTop) {
                    settings.addressBarTop = false
                }
            }

            CardSection(title: lang.t("layout.home"), subtitle: lang.t("layout.homeSub")) {
                HStack(spacing: Metrics.Space.md) {
                    Image(systemName: "house")
                        .font(.system(size: Metrics.Icon.md, weight: .medium))
                        .foregroundColor(settings.accent)
                        .frame(width: Metrics.Icon.lg)
                        .accessibilityHidden(true)
                    TextField("https://lineinc.ro", text: $homeDraft)
                        .font(.app(TypeScale.body))
                        .foregroundColor(AppColor.textPrimary)
                        .keyboardType(.URL)
                        .autocapitalization(.none)
                        .disableAutocorrection(true)
                        .onSubmit { saveHome() }
                    Button(lang.t("layout.save"), action: saveHome)
                        .font(.app(TypeScale.body))
                        .fontWeight(.semibold)
                        .foregroundColor(settings.accent)
                        .frame(minHeight: Metrics.Touch.min)
                        .contentShape(Rectangle())
                        .buttonStyle(PressButtonStyle())
                }
                .padding(Metrics.Space.md)
            }

            CardSection(title: lang.t("layout.tabs")) {
                ToggleRow(icon: "square.stack.3d.up.fill", color: .cyan,
                          title: lang.t("layout.tabCount"), subtitle: lang.t("layout.tabCountSub"),
                          isOn: $settings.showTabCount)
                Divider().overlay(AppColor.separator)
                ToggleRow(icon: "arrow.clockwise.circle.fill", color: .green,
                          title: lang.t("layout.restore"), subtitle: lang.t("layout.restoreSub"),
                          isOn: $settings.restoreSession)
            }
        }
        .onAppear { homeDraft = settings.homePage }
    }

    private func saveHome() {
        var value = homeDraft.trimmingCharacters(in: .whitespaces)
        if !value.isEmpty && !value.hasPrefix("http://") && !value.hasPrefix("https://") {
            value = "https://" + value
        }
        if !value.isEmpty { settings.homePage = value }
        homeDraft = settings.homePage
    }
}

// MARK: - Wallpapers

struct WallpaperSettingsView: View {
    @ObservedObject private var settings = SettingsStore.shared
    @ObservedObject private var lang = LanguageManager.shared
    @State private var picked: PhotosPickerItem?

    private let columns = Array(repeating: GridItem(.flexible(), spacing: Metrics.Space.md), count: 3)

    var body: some View {
        ScreenShell(title: lang.t("screen.wallpaper.title")) {
            CardSection(title: lang.t("wall.preset")) {
                LazyVGrid(columns: columns, spacing: Metrics.Space.md) {
                    Button {
                        appAnimate { settings.wallpaperID = "none" }
                    } label: {
                        VStack(spacing: Metrics.Space.sm) {
                            RoundedRectangle(cornerRadius: Metrics.Radius.md)
                                .fill(settings.background)
                                .frame(height: PreviewSize.wallpaperThumb)
                                .overlay(RoundedRectangle(cornerRadius: Metrics.Radius.md)
                                    .stroke(settings.wallpaperID == "none" ? settings.accent : Color.clear,
                                            lineWidth: 2))
                                .overlay(Image(systemName: "slash.circle")
                                    .font(.system(size: Metrics.Icon.lg, weight: .light))
                                    .foregroundColor(AppColor.textTertiary)
                                    .accessibilityHidden(true))
                            Text(lang.t("wall.none"))
                                .font(.app(TypeScale.micro))
                                .foregroundColor(AppColor.textPrimary)
                        }
                    }
                    .buttonStyle(PressButtonStyle())
                    .accessibilityAddTraits(settings.wallpaperID == "none" ? [.isSelected] : [])

                    ForEach(SettingsStore.wallpapers, id: \.id) { preset in
                        Button {
                            appAnimate { settings.wallpaperID = preset.id }
                        } label: {
                            VStack(spacing: Metrics.Space.sm) {
                                LinearGradient(colors: preset.colors.map { Color($0) },
                                               startPoint: .topLeading, endPoint: .bottomTrailing)
                                    .frame(height: PreviewSize.wallpaperThumb)
                                    .clipShape(RoundedRectangle(cornerRadius: Metrics.Radius.md, style: .continuous))
                                    .overlay(RoundedRectangle(cornerRadius: Metrics.Radius.md)
                                        .stroke(settings.wallpaperID == preset.id ? settings.accent : Color.clear,
                                                lineWidth: 2))
                                Text(preset.id.capitalized)
                                    .font(.app(TypeScale.micro))
                                    .foregroundColor(AppColor.textPrimary)
                            }
                        }
                        .buttonStyle(PressButtonStyle())
                        .accessibilityAddTraits(settings.wallpaperID == preset.id ? [.isSelected] : [])
                    }
                }
                .padding(Metrics.Space.md)
            }

            CardSection(title: lang.t("wall.custom"), subtitle: lang.t("wall.customSub")) {
                VStack(spacing: Metrics.Space.md) {
                    if settings.wallpaperID == "custom" {
                        CustomWallpaperPreview()
                            .frame(height: PreviewSize.customPreview)
                            .clipShape(RoundedRectangle(cornerRadius: Metrics.Radius.md, style: .continuous))
                            .clipped()
                    }

                    PhotosPicker(selection: $picked, matching: .images) {
                        HStack(spacing: Metrics.Space.sm) {
                            Image(systemName: "photo.on.rectangle.angled")
                                .font(.system(size: Metrics.Icon.md, weight: .semibold))
                                .accessibilityHidden(true)
                            Text(lang.t("wall.pick"))
                                .font(.app(TypeScale.callout))
                                .fontWeight(.semibold)
                        }
                        .foregroundColor(.black)
                        .frame(maxWidth: .infinity)
                        .frame(minHeight: Metrics.Touch.min)
                        .padding(.vertical, Metrics.Space.sm)
                        .background(settings.accent)
                        .clipShape(RoundedRectangle(cornerRadius: Metrics.Radius.md, style: .continuous))
                    }

                    if settings.wallpaperID == "custom" {
                        SecondaryButton(title: lang.t("wall.remove"), icon: "trash", color: .red) {
                            settings.removeWallpaperImage()
                            settings.wallpaperID = "none"
                        }
                    }

                    InfoRow(icon: "info.circle", color: AppColor.textTertiary, text: lang.t("wall.note"))
                }
                .padding(Metrics.Space.md)
            }
        }
        .onChange(of: picked) { item in
            guard let item else { return }
            Task {
                if let data = try? await item.loadTransferable(type: Data.self) {
                    settings.saveWallpaper(data)
                }
                picked = nil
            }
        }
    }
}

private struct CustomWallpaperPreview: View {
    @ObservedObject var settings = SettingsStore.shared
    var body: some View { settings.backgroundView() }
}

// MARK: - Accessibility

struct AccessibilitySettingsView: View {
    @ObservedObject private var settings = SettingsStore.shared
    @ObservedObject private var lang = LanguageManager.shared

    private let scales: [Double] = [0.9, 1.0, 1.15, 1.3]

    var body: some View {
        ScreenShell(title: lang.t("screen.accessibility.title")) {
            CardSection(title: lang.t("a11y.text")) {
                HStack(spacing: Metrics.Space.sm) {
                    ForEach(scales, id: \.self) { scale in
                        Button {
                            appAnimate { settings.textScale = scale }
                        } label: {
                            VStack(spacing: Metrics.Space.xs) {
                                Text("A")
                                    .font(.system(size: TypeScale.title * CGFloat(scale), weight: .semibold))
                                Text("\(Int(scale * 100))%")
                                    .font(.app(TypeScale.micro))
                            }
                            .foregroundColor(settings.textScale == scale ? .black : AppColor.textPrimary)
                            .frame(maxWidth: .infinity)
                            .frame(minHeight: Metrics.Touch.min)
                            .padding(.vertical, Metrics.Space.md)
                            .background(settings.textScale == scale ? settings.accent
                                        : AppColor.fill)
                            .clipShape(RoundedRectangle(cornerRadius: Metrics.Radius.md, style: .continuous))
                        }
                        .buttonStyle(PressButtonStyle())
                        .accessibilityLabel("\(Int(scale * 100))%")
                        .accessibilityAddTraits(settings.textScale == scale ? [.isSelected] : [])
                    }
                }
                .padding(Metrics.Space.md)
            }

            CardSection(title: lang.t("a11y.display")) {
                ToggleRow(icon: "circle.hexagongrid.fill", color: .yellow,
                          title: lang.t("a11y.contrast"), subtitle: lang.t("a11y.contrastSub"),
                          isOn: $settings.highContrast)
                Divider().overlay(AppColor.separator)
                ToggleRow(icon: "figure.walk.motion", color: .orange,
                          title: lang.t("a11y.motion"), subtitle: lang.t("a11y.motionSub"),
                          isOn: $settings.reduceMotion)
            }

            CardSection(title: lang.t("a11y.web")) {
                ToggleRow(icon: "arrow.up.left.and.arrow.down.right", color: .blue,
                          title: lang.t("a11y.zoom"), subtitle: lang.t("a11y.zoomSub"),
                          isOn: $settings.forceZoom)
            }
        }
    }
}
