import SwiftUI
import PhotosUI

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
                LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 5), spacing: 14) {
                    ForEach(Self.accents, id: \.hex) { item in
                        Button {
                            settings.accentHex = item.hex
                        } label: {
                            Circle()
                                .fill(Color(item.hex))
                                .frame(width: 44, height: 44)
                                .overlay(
                                    Circle().stroke(Color.white,
                                                    lineWidth: settings.accentHex == item.hex ? 3 : 0)
                                )
                                .shadow(color: Color(item.hex).opacity(0.5),
                                        radius: settings.accentHex == item.hex ? 8 : 0)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(14)
            }

            CardSection(title: lang.t("theme.surface")) {
                ToggleRow(icon: "circle.fill", color: .black,
                          title: lang.t("theme.oled"), subtitle: lang.t("theme.oledSub"),
                          isOn: $settings.pureBlack)
                Divider().overlay(Color.black.opacity(0.4))
                ToggleRow(icon: "circle.lefthalf.filled", color: .gray,
                          title: lang.t("a11y.contrast"), subtitle: lang.t("a11y.contrastSub"),
                          isOn: $settings.highContrast)
            }

            CardSection(title: lang.t("theme.preview")) {
                VStack(spacing: 12) {
                    HStack(spacing: 10) {
                        RoundedRectangle(cornerRadius: 6)
                            .fill(settings.accent)
                            .frame(width: 24, height: 24)
                            .overlay(RoundedRectangle(cornerRadius: 2)
                                .fill(Color.black)
                                .frame(width: 10, height: 3))
                        HStack {
                            Image(systemName: "lock.fill")
                                .font(.system(size: 10))
                                .foregroundColor(settings.accent)
                            Text(lang.t("chrome.placeholder"))
                                .font(.app(13))
                                .foregroundColor(.white.opacity(0.8))
                            Spacer()
                        }
                        .padding(8)
                        .background(Color(0xFF2C2C2E))
                        .cornerRadius(20)
                    }
                    .padding(12)
                    .background(settings.chromeColor)
                    .cornerRadius(14)

                    HStack {
                        Image(systemName: "house.fill").foregroundColor(.white)
                        Spacer()
                        Image(systemName: "star.fill").foregroundColor(settings.accent)
                        Spacer()
                        Image(systemName: "plus.circle.fill").foregroundColor(.white)
                        Spacer()
                        Image(systemName: "ellipsis.circle.fill").foregroundColor(.white)
                    }
                    .font(.system(size: 18))
                    .padding(.horizontal, 30)
                    .padding(.vertical, 12)
                    .background(settings.chromeColor)
                    .cornerRadius(14)
                }
                .padding(12)
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
                Divider().overlay(Color.black.opacity(0.4))
                OptionRow(icon: "rectangle.righthalf.inset.filled", title: lang.t("layout.barBottom"),
                          isSelected: !settings.addressBarTop) {
                    settings.addressBarTop = false
                }
            }

            CardSection(title: lang.t("layout.home"), subtitle: lang.t("layout.homeSub")) {
                HStack(spacing: 12) {
                    Image(systemName: "house")
                        .foregroundColor(settings.accent)
                        .frame(width: 24)
                    TextField("https://lineinc.ro", text: $homeDraft)
                        .font(.app(14))
                        .foregroundColor(.white)
                        .keyboardType(.URL)
                        .autocapitalization(.none)
                        .disableAutocorrection(true)
                        .onSubmit { saveHome() }
                    Button(lang.t("layout.save"), action: saveHome)
                        .font(.app(14))
                        .fontWeight(.semibold)
                        .foregroundColor(settings.accent)
                }
                .padding(12)
            }

            CardSection(title: lang.t("layout.tabs")) {
                ToggleRow(icon: "square.stack.3d.up.fill", color: .cyan,
                          title: lang.t("layout.tabCount"), subtitle: lang.t("layout.tabCountSub"),
                          isOn: $settings.showTabCount)
                Divider().overlay(Color.black.opacity(0.4))
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

    private let columns = Array(repeating: GridItem(.flexible(), spacing: 12), count: 3)

    var body: some View {
        ScreenShell(title: lang.t("screen.wallpaper.title")) {
            CardSection(title: lang.t("wall.preset")) {
                LazyVGrid(columns: columns, spacing: 12) {
                    Button {
                        settings.wallpaperID = "none"
                    } label: {
                        VStack(spacing: 6) {
                            RoundedRectangle(cornerRadius: 12)
                                .fill(settings.background)
                                .frame(height: 64)
                                .overlay(RoundedRectangle(cornerRadius: 12)
                                    .stroke(settings.wallpaperID == "none" ? settings.accent : Color.clear,
                                            lineWidth: 2))
                                .overlay(Image(systemName: "slash.circle")
                                    .foregroundColor(.gray))
                            Text(lang.t("wall.none"))
                                .font(.app(11))
                                .foregroundColor(.white)
                        }
                    }
                    .buttonStyle(.plain)

                    ForEach(SettingsStore.wallpapers, id: \.id) { preset in
                        Button {
                            settings.wallpaperID = preset.id
                        } label: {
                            VStack(spacing: 6) {
                                LinearGradient(colors: preset.colors.map { Color($0) },
                                               startPoint: .topLeading, endPoint: .bottomTrailing)
                                    .frame(height: 64)
                                    .cornerRadius(12)
                                    .overlay(RoundedRectangle(cornerRadius: 12)
                                        .stroke(settings.wallpaperID == preset.id ? settings.accent : Color.clear,
                                                lineWidth: 2))
                                Text(preset.id.capitalized)
                                    .font(.app(11))
                                    .foregroundColor(.white)
                            }
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(14)
            }

            CardSection(title: lang.t("wall.custom"), subtitle: lang.t("wall.customSub")) {
                VStack(spacing: 12) {
                    if settings.wallpaperID == "custom" {
                        CustomWallpaperPreview()
                            .frame(height: 140)
                            .cornerRadius(12)
                            .clipped()
                    }

                    PhotosPicker(selection: $picked, matching: .images) {
                        HStack(spacing: 8) {
                            Image(systemName: "photo.on.rectangle.angled")
                            Text(lang.t("wall.pick"))
                                .font(.app(15))
                                .fontWeight(.semibold)
                        }
                        .foregroundColor(.black)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 13)
                        .background(settings.accent)
                        .cornerRadius(14)
                    }

                    if settings.wallpaperID == "custom" {
                        SecondaryButton(title: lang.t("wall.remove"), icon: "trash", color: .red) {
                            settings.removeWallpaperImage()
                            settings.wallpaperID = "none"
                        }
                    }

                    InfoRow(icon: "info.circle", color: .gray, text: lang.t("wall.note"))
                }
                .padding(12)
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
                HStack(spacing: 8) {
                    ForEach(scales, id: \.self) { scale in
                        Button {
                            settings.textScale = scale
                        } label: {
                            VStack(spacing: 4) {
                                Text("A")
                                    .font(.system(size: 10 + scale * 8, weight: .semibold))
                                Text("\(Int(scale * 100))%")
                                    .font(.app(11))
                            }
                            .foregroundColor(settings.textScale == scale ? .black : .white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(settings.textScale == scale ? settings.accent
                                        : Color(UIColor(white: 0.14, alpha: 1)))
                            .cornerRadius(12)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(12)
            }

            CardSection(title: lang.t("a11y.display")) {
                ToggleRow(icon: "circle.hexagongrid.fill", color: .yellow,
                          title: lang.t("a11y.contrast"), subtitle: lang.t("a11y.contrastSub"),
                          isOn: $settings.highContrast)
                Divider().overlay(Color.black.opacity(0.4))
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
