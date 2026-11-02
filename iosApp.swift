import SwiftUI

@main
struct iosApp: App {
    @StateObject private var model = BrowserModel()
    @AppStorage("hasCompletedSetup") private var hasCompletedSetup = false
    @Environment(\.scenePhase) private var scenePhase

    var body: some Scene {
        WindowGroup {
            Group {
                #if DEBUG
                if let shot = ScreenshotMode.screen {
                    ScreenshotHarness(model: model, screen: shot)
                } else {
                    root
                }
                #else
                root
                #endif
            }
            .animation(SettingsStore.shared.reduceMotion ? nil : .easeInOut(duration: 0.25), value: hasCompletedSetup)
            .onOpenURL { url in
                // Links handed over by other apps (we are the default browser).
                guard let scheme = url.scheme?.lowercased(),
                      scheme == "http" || scheme == "https" else { return }
                model.open(url)
                hasCompletedSetup = true
            }
        }
        .onChange(of: scenePhase) { phase in
            // Privacy ▸ "Clear data in background".
            if phase == .background, SettingsStore.shared.clearOnExit {
                model.clearAllWebsiteData()
            }
        }
    }

    /// Normal app flow (onboarding → browser). Extracted so DEBUG screenshot
    /// launches can bypass it.
    @ViewBuilder private var root: some View {
        if hasCompletedSetup {
            ContentView(model: model)
        } else {
            OnboardingView(model: model) {
                withAnimation { hasCompletedSetup = true }
            }
        }
    }
}
