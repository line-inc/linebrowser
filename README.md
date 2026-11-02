# 🟢 Line Browser

<p align="center">
  <img src="logo.png" width="128" height="128" alt="Line Browser Logo" />
</p>

<p align="center">
  <b>A premium, privacy-first web browser for iPhone & iPad, built with SwiftUI &amp; WKWebView.</b>
</p>

<p align="center">
  <a href="https://lineinc.ro"><img src="https://img.shields.io/badge/Website-lineinc.ro-00E676?style=for-the-badge&logo=googlechrome&logoColor=white" alt="Website" /></a>
  <a href="https://discord.gg/w4F7QAuHBf"><img src="https://img.shields.io/badge/Discord-Join%20Community-5865F2?style=for-the-badge&logo=discord&logoColor=white" alt="Discord" /></a>
  <a href="https://github.com/line-inc/linebrowser"><img src="https://img.shields.io/badge/GitHub-Line%20Inc.-181717?style=for-the-badge&logo=github&logoColor=white" alt="GitHub" /></a>
  <img src="https://img.shields.io/badge/platform-iOS%2016.0%2B-00E676?style=for-the-badge&logo=apple&logoColor=white" alt="Platform" />
</p>

---

**Line Browser** is a premium mobile web browser focused on privacy, high performance, freedom, and advanced customization, officially developed by **Line Inc.** This is the **iOS** edition — a fully native Swift codebase, not a wrapper around a cross-platform engine.

---

## ⚙️ Engine & Architecture

- **Rendering Engine**: **WKWebView (Safari / WebKit)** — the native iOS engine. Fast page loads, full support for modern web standards, and hardware-accelerated compositing with no cross-platform bridge overhead.
- **UI Interface**: **SwiftUI** — a fully native, fluid interface written in Swift 5.9 with an observable-model architecture (`BrowserModel`, `SettingsStore`, `LanguageManager`). No UIKit view controllers to bridge, no web-based UI.
- **Encryption & Storage**: **CryptoKit (AES-256-GCM)** for the private vault and **iOS Keychain** (`kSecAttrAccessibleWhenUnlockedThisDeviceOnly`) for passwords and encryption keys. Nothing is written to plaintext disk.
- **Project Generation**: **XcodeGen** (`project.yml`) — the `.xcodeproj` is generated, so targets and build settings live in a single reviewable file.

---

## 📱 Device & System Compatibility

- **Operating System**: **iOS 16.0** and later (iPhone & iPad).
- **Device Family**: **Universal** — one binary targets both `iPhone` and `iPad`, with all four orientations enabled on iPad for multitasking support.
- **Architectures**: **arm64** (all modern iPhones and iPads).
- **Default Browser**: registers the `http` and `https` URL schemes, so iOS offers Line Browser under *Settings ▸ Default Browser App* and hands external links to it.
- **Requirements to build**: Xcode 15+, [XcodeGen](https://github.com/yonaskolb/XcodeGen) (`brew install xcodegen`).

---

## 🛡️ Complete Features

### 🔒 Privacy & Ad Blocking
- **No Telemetry, No Accounts, No Servers**: there is no analytics SDK, no tracking pixel, no backend. Nothing about you is collected or transmitted — confirmed in the [Privacy Policy](https://vladutzztech.github.io/lineinc-privacy/).
- **Ad & Tracker Blocker**: a curated blocklist of **56 ad-network, tracker, and telemetry domains** (Google Ads/Analytics, Facebook Pixel, TikTok, Criteo, Taboola, Outbrain, ComScore, Hotjar, Mixpanel, AppsFlyer, Adjust, New Relic, and more), enforced by a compiled **`WKContentRuleList`** (Safari-style content rules) so blocked requests never leave the page.
- **Single Source of Truth**: `Blocklist.swift` is the one list that drives every rule — change it once, blocking updates everywhere.
- **Burn on Exit**: one toggle wipes history, cookies, cache, and site data whenever the app backgrounds.
- **Site-Level Controls**: a JavaScript on/off toggle, pop-up blocking, "open links in new tab", and one-tap *Clear Website Data*.
- **Private by Default**: the default search engine is **DuckDuckGo**.

### 🌐 Network Tools
- **Network Monitor**: an in-page JavaScript bridge (`fetch`, `XHR`, resource timing, navigations) that captures **every request a page makes** — documents, images, scripts, fonts, analytics — with status codes, sizes, and timing. Answers the question *"which sites phone home?"* Searchable and filterable, and it only ever sees the page you have open — nothing is sent anywhere.

### 🔑 Passwords & Vault
- **Keychain Password Manager**: save site, username, and password pairs directly to the **iOS Keychain** — never in iCloud, never on a server. Per-entry reveal, one-tap copy to clipboard, and delete.
- **Biometric Private Vault**: an AES-256-GCM encrypted locker for notes and secrets, unlocked with **Face ID or device passcode** via `LocalAuthentication`. The 256-bit key is generated once and kept in the Keychain — the vault contents are never stored unencrypted.
- **Device-Only Storage**: both stores use `kSecAttrAccessibleWhenUnlockedThisDeviceOnly`, so the data is never written to an iCloud keychain backup.

### 🎨 Personalization & Accessibility
- **10 Accent Colors**: Line Emerald Green (`#34C759`, default), Blue, Indigo, Purple, Pink, Red, Orange, Yellow, Teal, Gray.
- **8 Gradient Wallpapers**: Midnight, Forest, Ocean, Grape, Ember, Slate, Mint, Crimson — plus **bring-your-own photo** from the photo library.
- **Surface Modes**: normal dark, **Pure Black (AMOLED)**, and a high-contrast variant with stronger borders.
- **Layout Control**: move the address bar to the **top or bottom**, set a custom home page, toggle the tab-count badge, and enable session restore.
- **Accessibility**: text-size scaling, **Reduce Motion**, **High Contrast**, and a toggle to allow pinch-zoom on sites that block it. Every animation respects Reduce Motion.
- **Micro-interactions**: press-scale buttons and haptic feedback throughout, with a reduced-motion path for every transition.

### 🗂 Tabs, Bookmarks & Web Apps
- **Tab Overview**: see every open tab with title and URL, switch or close them individually, or close all at once.
- **Bookmarks**: star any page from the toolbar; bookmarks persist across launches.
- **Session Restore**: reopen your tabs exactly where you left them.
- **Web Apps (PWA)**: save the current page to an in-app home screen, or hand it off to the system Share sheet for a real home-screen icon.

### 🌍 Bilingual Interface (English / Romanian)
- **246 strings**, fully translated in both **English** and **Română** — every screen, every settings row, every empty state.
- **Instant runtime switching** from Settings, no relaunch required.
- **Auto-detects** your system language on first launch, with the choice offered during onboarding.
- Romanian diacritics are correct throughout (ă, â, î, ș, ț).

---

## 🗂 Project Structure

```
LineBrowser/
├── project.yml                  # XcodeGen spec — targets, build settings
├── iosApp.swift                 # App entry point, scene phase, deep links
├── BrowserModel.swift           # Tabs, navigation, search engines, bookmarks
├── ContentView.swift            # Main browser chrome + WKWebView bridge
├── BrowsingScreens.swift        # Tab overview, site settings, web apps
├── Screens.swift                # Shared UI primitives (ScreenShell, cards, buttons)
├── SettingsView.swift           # Settings root, all navigation links
├── PersonalizationScreens.swift # Theme, layout, wallpaper, accessibility
├── PrivacyScreens.swift         # Privacy Hub, Passwords, Vault
├── NetworkScreens.swift         # Network Monitor
├── NetworkCore.swift            # Request store + in-page JS bridge source
├── Blocklist.swift              # Ad/tracker domains for the content blocker
├── SecureStores.swift           # Keychain passwords, AES-GCM vault
├── SettingsStore.swift          # Persisted preferences, colors, wallpapers
├── Localization.swift           # EN/RO string tables (211 keys each)
├── OnboardingView.swift         # First-run flow: language, engine, default browser
├── ColorHex.swift               # Hex → Color helper
│
├── Assets.xcassets/             # App icon
├── Info.plist                   # App manifest (written by XcodeGen from project.yml)
├── ScreenshotHarness.swift      # DEBUG-only UI capture harness (never ships)
└── privacy.html                 # Bilingual privacy policy source
```

**Target**

| Target | Bundle ID | Role |
|---|---|---|
| `LineBrowser` | `com.lineinc.linebrowser` | The app — single target, no extensions |

---

## 🛠️ Building from Source

```bash
# 1. Install XcodeGen (once)
brew install xcodegen

# 2. Generate the Xcode project from project.yml
xcodegen generate

# 3. Open it
open LineBrowser.xcodeproj
```

Then select your device or a simulator and hit **⌘R**.

**Command line:**

```bash
# Debug build to a connected device
xcodebuild -project LineBrowser.xcodeproj \
  -scheme LineBrowser \
  -destination 'platform=iOS,name=iPhone 17' \
  -configuration Debug build

# Release archive
xcodebuild -project LineBrowser.xcodeproj \
  -scheme LineBrowser \
  -destination 'generic/platform=iOS' \
  -configuration Release \
  -archivePath build/LineBrowser.xcarchive archive
```

> ⚠️ **Run `xcodegen generate` after adding or removing any source file** — the `.xcodeproj` is generated, not hand-edited. Never commit `xcuserdata/`.

**No entitlements required** — the app uses no VPN, NetworkExtension, or app-group capabilities, so there is nothing for App Review to question on that front.

**App Store screenshots** are captured with `ScreenshotHarness.swift`, a DEBUG-only harness that renders any screen full-bleed on the simulator:

```bash
xcrun simctl launch <device-udid> com.lineinc.linebrowser --lb-shot netmonitor
```

Valid screens: `home`, `web`, `settings`, `theme`, `passwords`, `vault`, `privacy`, `netmonitor`. The harness is wrapped in `#if DEBUG` and compiles out of Release archives entirely — it has been verified absent from the shipping binary.

---

## 🌐 Official Links & Community

- 🌐 **Official Website**: [lineinc.ro](https://lineinc.ro)
- 🏦 **Paypal**: [Support us!](https://www.paypal.me/lineincofficial)
- ✉️ **Support & Contact**: [lineinc.ro/support/](https://www.lineinc.ro/support/)
- 💬 **Discord Community**: [discord.gg/w4F7QAuHBf](https://discord.gg/w4F7QAuHBf)
- 🐙 **GitHub Repository**: [github.com/line-inc/linebrowser](https://github.com/line-inc/linebrowser)
- 📄 **Privacy Policy**: [lineinc-privacy](https://vladutzztech.github.io/lineinc-privacy/)

### Other Platforms

| Platform | Branch |
|---|---|
| 🤖 Android | [`Android`](https://github.com/line-inc/linebrowser/tree/Android) |
| 🪟 Windows | [`Windows`](https://github.com/line-inc/linebrowser/tree/Windows) |
| 🍎 macOS | [`MacOS`](https://github.com/line-inc/linebrowser/tree/MacOS) |
| 🐧 Linux | [`Linux`](https://github.com/line-inc/linebrowser/tree/Linux) |
| 📱 **iOS** | **`ios`** *(this branch)* |

<p align="center">
  <b>Copyright © 2026 Line Inc. All rights reserved.</b>
</p>
