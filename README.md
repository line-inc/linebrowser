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
- **Network Layer**: **NetworkExtension** — a `NEPacketTunnelProvider` app extension for the device-wide DNS sniffer, plus `NEVPNManager` for the standards-based IKEv2 VPN client.
- **Project Generation**: **XcodeGen** (`project.yml`) — the `.xcodeproj` is generated, so targets, entitlements, and build settings live in a single reviewable file.

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
- **Ad & Tracker Blocker**: a curated blocklist of **56 ad-network, tracker, and telemetry domains** (Google Ads/Analytics, Facebook Pixel, TikTok, Criteo, Taboola, Outbrain, ComScore, Hotjar, Mixpanel, AppsFlyer, Adjust, New Relic, and more).
- **Two-Layer Blocking**: rules apply both **in-page** (a compiled `WKContentRuleList` — Safari-style content rules) and **at the DNS level** (the sniffer answers `NXDOMAIN` for blocked hosts), so trackers are stopped before a single packet leaves the device.
- **Shared Blocklist**: `Shared/SharedNetwork.swift` is compiled into both the app and the tunnel extension — one source of truth, no drift.
- **Burn on Exit**: one toggle wipes history, cookies, cache, and site data whenever the app backgrounds.
- **Site-Level Controls**: a JavaScript on/off toggle, pop-up blocking, "open links in new tab", and one-tap *Clear Website Data*.
- **Private by Default**: the default search engine is **DuckDuckGo**.

### 🌐 Network Tools
- **Packet Sniffer (DNS, device-wide)**: an on-device `NEPacketTunnelProvider` tunnel that routes **DNS queries only** — every other packet and IP passes straight through untouched. Each lookup is logged live with its domain, blocked domains are refused, and clean queries are forwarded to **Cloudflare 1.1.1.1**. Because it sits below the app layer, it sees lookups from *every* app on the phone, not just the browser. Searchable, filterable, clearable log.
- **Network Monitor**: an in-page JavaScript bridge (`fetch`, `XHR`, resource timing, navigations) that captures **every request a page makes** — documents, images, scripts, fonts, analytics — with status codes, sizes, and timing. Answers the question *"which sites phone home?"*
- **IKEv2 VPN Client**: a standard, OS-level IKEv2/IPsec tunnel via `NEVPNManager`. Enter server, remote ID, username, and password; the credential is stored in the **iOS Keychain** and the tunnel appears in *Settings ▸ VPN* like any other.

> **Transparency note**: the sniffer logs DNS queries and forwards them to Cloudflare 1.1.1.1. It does not proxy, inspect, or store your actual traffic — only DNS names are visible to it, and the log lives on your device.

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
├── project.yml                  # XcodeGen spec — targets, entitlements, build settings
├── iosApp.swift                 # App entry point, scene phase, deep links
├── BrowserModel.swift           # Tabs, navigation, search engines, bookmarks
├── ContentView.swift            # Main browser chrome + WKWebView bridge
├── BrowsingScreens.swift        # Tab overview, site settings, web apps
├── Screens.swift                # Shared UI primitives (ScreenShell, cards, buttons)
├── SettingsView.swift           # Settings root, all navigation links
├── PersonalizationScreens.swift # Theme, layout, wallpaper, accessibility
├── PrivacyScreens.swift         # Privacy Hub, Passwords, Vault
├── NetworkScreens.swift         # DNS Sniffer, VPN client, Network Monitor
├── NetworkCore.swift            # DNS log + request stores, JS bridge source
├── SecureStores.swift           # Keychain passwords, AES-GCM vault
├── VPNManager.swift             # Packet-tunnel + IKEv2 tunnel management
├── SettingsStore.swift          # Persisted preferences, colors, wallpapers
├── Localization.swift           # EN/RO string tables (246 keys each)
├── OnboardingView.swift         # First-run flow: language, engine, default browser
├── ColorHex.swift               # Hex → Color helper
│
├── PacketTunnel/                # App extension — device-wide DNS sniffer
│   ├── PacketTunnelProvider.swift   # NEPacketTunnelProvider: parse, log, block, forward
│   ├── Info.plist                   # com.apple.networkextension.packet-tunnel
│   └── PacketTunnel.entitlements
│
├── Shared/
│   └── SharedNetwork.swift      # Blocklist + app-group prefs (app ⇄ extension)
│
├── Assets.xcassets/             # App icon
├── Info.plist                   # App manifest (written by XcodeGen from project.yml)
├── LineBrowser.entitlements     # Packet tunnel, VPN API, app group
├── ScreenshotHarness.swift      # DEBUG-only UI capture harness (never ships)
└── privacy.html                 # Bilingual privacy policy source
```

**Targets**

| Target | Bundle ID | Role |
|---|---|---|
| `LineBrowser` | `com.lineinc.linebrowser` | The app |
| `PacketTunnel` | `com.lineinc.linebrowser.packettunnel` | DNS sniffer extension, embedded in the app |

Both share the app group `group.com.lineinc.linebrowser`, which is how the blocklist toggle and DNS log cross the process boundary.

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

**Entitlements required** (all configured in `project.yml`): `packet-tunnel-provider`, `allow-vpn`, and the app group. The tunnel extension will not start without them.

**App Store screenshots** are captured with `ScreenshotHarness.swift`, a DEBUG-only harness that renders any screen full-bleed on the simulator:

```bash
xcrun simctl launch <device-udid> com.lineinc.linebrowser --lb-shot dnssniffer
```

Valid screens: `home`, `web`, `settings`, `theme`, `passwords`, `vault`, `privacy`, `dnssniffer`, `vpn`, `netmonitor`. The harness is wrapped in `#if DEBUG` and compiles out of Release archives entirely — it has been verified absent from the shipping binary.

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
