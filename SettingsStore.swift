import SwiftUI
import Combine

/// Single source of truth for every preference the browser honours.
/// Persisted to UserDefaults, observable by any view.
final class SettingsStore: ObservableObject {
    static let shared = SettingsStore()
    private let d = UserDefaults.standard

    // MARK: Appearance
    @Published var accentHex: UInt32 { didSet { d.set(Int64(accentHex), forKey: "s.accent") } }
    @Published var pureBlack: Bool { didSet { d.set(pureBlack, forKey: "s.pureBlack") } }
    @Published var wallpaperID: String { didSet { d.set(wallpaperID, forKey: "s.wallpaper") } }

    // MARK: Layout
    @Published var addressBarTop: Bool { didSet { d.set(addressBarTop, forKey: "s.barTop") } }
    @Published var homePage: String { didSet { d.set(homePage, forKey: "s.home") } }
    @Published var showTabCount: Bool { didSet { d.set(showTabCount, forKey: "s.tabCount") } }
    @Published var restoreSession: Bool { didSet { d.set(restoreSession, forKey: "s.restore") } }

    // MARK: Accessibility
    @Published var textScale: Double { didSet { d.set(textScale, forKey: "s.scale") } }
    @Published var highContrast: Bool { didSet { d.set(highContrast, forKey: "s.contrast") } }
    @Published var reduceMotion: Bool { didSet { d.set(reduceMotion, forKey: "s.motion") } }
    @Published var forceZoom: Bool { didSet { d.set(forceZoom, forKey: "s.zoom") } }

    // MARK: Site behaviour
    @Published var jsEnabled: Bool { didSet { d.set(jsEnabled, forKey: "s.js") } }
    @Published var blockPopups: Bool { didSet { d.set(blockPopups, forKey: "s.popups") } }
    @Published var openLinksInNewTab: Bool { didSet { d.set(openLinksInNewTab, forKey: "s.newTab") } }

    // MARK: Privacy
    @Published var blockAds: Bool { didSet { d.set(blockAds, forKey: "s.blockAds") } }
    @Published var clearOnExit: Bool { didSet { d.set(clearOnExit, forKey: "s.clearOnExit") } }

    // MARK: - Init

    private init() {
        let d = UserDefaults.standard
        accentHex      = d.object(forKey: "s.accent")    != nil ? UInt32(d.integer(forKey: "s.accent"))    : 0xFF34C759
        pureBlack      = d.bool(forKey: "s.pureBlack")
        wallpaperID    = d.string(forKey: "s.wallpaper")  ?? "none"
        addressBarTop  = d.object(forKey: "s.barTop")     != nil ? d.bool(forKey: "s.barTop")  : true
        homePage       = d.string(forKey: "s.home")       ?? "https://lineinc.ro"
        showTabCount   = d.object(forKey: "s.tabCount")   != nil ? d.bool(forKey: "s.tabCount")  : true
        restoreSession = d.object(forKey: "s.restore")    != nil ? d.bool(forKey: "s.restore")   : true
        textScale      = d.object(forKey: "s.scale")      != nil ? d.double(forKey: "s.scale")   : 1.0
        highContrast   = d.bool(forKey: "s.contrast")
        reduceMotion   = d.bool(forKey: "s.motion")
        forceZoom      = d.bool(forKey: "s.zoom")
        jsEnabled      = d.object(forKey: "s.js")         != nil ? d.bool(forKey: "s.js")        : true
        blockPopups    = d.object(forKey: "s.popups")     != nil ? d.bool(forKey: "s.popups")    : true
        openLinksInNewTab = d.bool(forKey: "s.newTab")
        blockAds       = d.object(forKey: "s.blockAds")   != nil ? d.bool(forKey: "s.blockAds")  : true
        clearOnExit    = d.bool(forKey: "s.clearOnExit")
    }

    // MARK: - Derived values

    var accent: Color { Color(accentHex) }

    var background: Color {
        if highContrast { return .black }
        if pureBlack { return Color.black }
        return Color(UIColor(red: 0.04, green: 0.05, blue: 0.06, alpha: 1))
    }

    var cardColor: Color {
        highContrast ? Color(UIColor(white: 0.16, alpha: 1)) : Color(0xFF1E2024)
    }

    var chromeColor: Color {
        highContrast ? Color(UIColor(white: 0.11, alpha: 1)) : Color(0xFF141416)
    }

    // MARK: - Wallpaper

    static let wallpapers: [(id: String, colors: [UInt32])] = [
        ("midnight", [0x0A0C10, 0x101418]),
        ("forest",   [0x06110B, 0x0E2417]),
        ("ocean",    [0x05101E, 0x0B2440]),
        ("grape",    [0x140A20, 0x2A1140]),
        ("ember",    [0x1A0A06, 0x3A140A]),
        ("slate",    [0x14161A, 0x24282E]),
        ("mint",     [0x061612, 0x0C2A22]),
        ("crimson",  [0x1A0608, 0x360C12]),
    ]

    /// Root background: chosen gradient, saved photo, or the plain color.
    func backgroundView() -> AnyView {
        if wallpaperID == "custom", let name = d.string(forKey: "s.wallpaperFile") {
            let url = Self.documentsDirectory().appendingPathComponent(name)
            if let data = try? Data(contentsOf: url), let ui = UIImage(data: data) {
                return AnyView(
                    Image(uiImage: ui)
                        .resizable()
                        .scaledToFill()
                        .ignoresSafeArea()
                )
            }
        }
        if let preset = Self.wallpapers.first(where: { $0.id == wallpaperID }) {
            return AnyView(
                LinearGradient(
                    colors: preset.colors.map { Color($0) },
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
            )
        }
        return AnyView(background.ignoresSafeArea())
    }

    var hasCustomWallpaper: Bool { wallpaperID != "none" }

    static func documentsDirectory() -> URL {
        FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
    }

    /// Persists a picked photo and points the wallpaper at it.
    func saveWallpaper(_ data: Data) {
        try? FileManager.default.createDirectory(
            at: Self.documentsDirectory(), withIntermediateDirectories: true
        )
        let url = Self.documentsDirectory().appendingPathComponent("wallpaper.jpg")
        try? data.write(to: url, options: .atomic)
        d.set("wallpaper.jpg", forKey: "s.wallpaperFile")
        wallpaperID = "custom"
    }

    func removeWallpaperImage() {
        if let name = d.string(forKey: "s.wallpaperFile") {
            try? FileManager.default.removeItem(at: Self.documentsDirectory().appendingPathComponent(name))
        }
        d.removeObject(forKey: "s.wallpaperFile")
    }
}

// MARK: - Scaled text helper

extension Font {
    /// Scales with the in-app "Text size" accessibility setting.
    static func app(_ size: CGFloat) -> Font {
        .system(size: size * SettingsStore.shared.textScale)
    }
}
