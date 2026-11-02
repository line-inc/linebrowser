#if DEBUG
import SwiftUI

/// Renders one screen full-bleed so App Store screenshots can be captured from
/// the simulator without touching the user's personal device (no private data,
/// no manual tapping, exact pixel sizes).
///
/// DEBUG-only — compiled out of Release archives entirely.
struct ScreenshotHarness: View {
    @ObservedObject var model: BrowserModel
    @ObservedObject private var settings = SettingsStore.shared
    let screen: String

    var body: some View {
        content
            .preferredColorScheme(.dark)
            .onAppear { prepare() }
    }

    @ViewBuilder private var content: some View {
        switch screen {
        case "home", "web":
            ContentView(model: model)
        case "settings":
            SettingsView(model: model)
        case "theme":
            ThemeSettingsView()
        case "passwords":
            PasswordsView()
        case "vault":
            VaultView()
        case "privacy":
            PrivacyHubView(model: model)
        case "netmonitor":
            NetworkMonitorView()
        default:
            ContentView(model: model)
        }
    }

    private func prepare() {
        // Freeze transitions so captures are crisp, not mid-animation.
        settings.reduceMotion = true
        if screen == "web", let url = URL(string: "https://lineinc.ro") {
            model.open(url)
        }
    }
}

/// True when launched with `--lb-shot <screen>`; used by iosApp to swap in the
/// harness instead of the real app flow (which would show onboarding).
enum ScreenshotMode {
    static var screen: String? {
        let args = ProcessInfo.processInfo.arguments
        guard let i = args.firstIndex(of: "--lb-shot"), i + 1 < args.count else { return nil }
        return args[i + 1]
    }
}

/// Injected only in screenshot mode: dismisses cookie-consent overlays (and a few
/// common equivalents) after the page settles, so the hero shot isn't blocked.
enum ScreenshotCleanup {
    static let js = """
    (function () {
      var SEL = ['[id*="cookie"]', '[class*="cookie"]', '[id*="consent"]',
                 '[class*="consent"]', '[id*="gdpr"]', '[class*="gdpr"]',
                 // Support/chat widgets (tawk, crisp, intercom, drift, hubspot…)
                 '[id*="tawk"]', '[class*="tawk"]', '[id*="crisp"]',
                 '[class*="crisp"]', '[id*="intercom"]', '[class*="intercom"]',
                 '[id*="drift"]', '[class*="drift"]', '[id*="hubspot"]',
                 '[class*="hubspot"]', '[id*="chat-widget"]', '[class*="chat-widget"]',
                 '[id*="tidio"]', '[class*="tidio"]', '[id*="zendesk"]',
                 '[class*="zendesk"]', 'iframe[src*="tawk"]', 'iframe[src*="crisp"]',
                 'iframe[src*="intercom"]'];
      var HANDLED = /^\\s*(accept all|accept cookies|allow all|agree|got it|ok|i agree|only essential|essential only|reject|decline)\\s*$/i;

      function kill(root) {
        try {
          root.querySelectorAll(SEL.join(',')).forEach(function (el) {
            var st = getComputedStyle(el);
            var pos = st.position;
            if (pos === 'fixed' || pos === 'absolute' || st.zIndex > 10) el.remove();
          });
          // Buttons whose label is a consent action.
          root.querySelectorAll('button, a[role="button"]').forEach(function (b) {
            if (HANDLED.test(b.textContent || '')) b.click();
          });

          // Close any floating overlay (chat bubbles, popups): click explicit
          // close controls first, then strip fixed/absolute nodes with a high
          // stacking level that aren't the page's main content.
          var closeSel = ['[aria-label*="close" i]', '[aria-label*="dismiss" i]',
                          '[title*="close" i]', '[title*="dismiss" i]',
                          '[class*="close"]', '[class*="dismiss"]'];
          root.querySelectorAll(closeSel.join(',')).forEach(function (b) {
            var r = b.getBoundingClientRect();
            if (r.width && r.height && r.width < 90 && r.height < 90) b.click();
          });

          root.querySelectorAll('body *').forEach(function (el) {
            var st = getComputedStyle(el);
            if (st.position !== 'fixed' && st.position !== 'absolute') return;
            if (st.display === 'none' || st.visibility === 'hidden') return;
            var z = parseInt(st.zIndex, 10);
            if (isNaN(z)) z = 0;
            var r = el.getBoundingClientRect();
            if (z < 50 || !r.width || !r.height) return;
            // Keep elements that are effectively full-page (site layout chrome).
            if (r.width >= window.innerWidth * 0.98 && r.height >= window.innerHeight * 0.9) return;
            el.remove();
          });
        } catch (e) {}
      }

      function run() {
        kill(document);
        // Absolute/overlay wrappers that hold no cookie keyword but contain one.
        document.querySelectorAll('body > div').forEach(function (d) {
          if (/cookie|consent|gdpr/i.test(d.textContent || '')) {
            var st = getComputedStyle(d);
            if (st.position === 'fixed' || st.position === 'absolute') d.remove();
          }
        });
      }

      run();
      [400, 1200, 2500, 5000, 9000, 14000].forEach(function (t) { setTimeout(run, t); });
    })();
    """
}
#endif
