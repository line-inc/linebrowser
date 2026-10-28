# 🟢 Line Browser

<p align="center">
  <img src="app/src/main/res/drawable/lineinc.png" width="128" height="128" alt="Line Browser Logo" />
</p>

<p align="center">
  <b>A premium, privacy-first mobile web browser built with Jetpack Compose & Mozilla GeckoView.</b>
</p>

<p align="center">
  <a href="https://lineinc.ro"><img src="https://img.shields.io/badge/Website-lineinc.ro-00E676?style=for-the-badge&logo=googlechrome&logoColor=white" alt="Website" /></a>
  <a href="https://discord.gg/w4F7QAuHBf"><img src="https://img.shields.io/badge/Discord-Join%20Community-5865F2?style=for-the-badge&logo=discord&logoColor=white" alt="Discord" /></a>
  <a href="https://github.com/line-inc/linebrowser"><img src="https://img.shields.io/badge/GitHub-Line%20Inc.-181717?style=for-the-badge&logo=github&logoColor=white" alt="GitHub" /></a>
</p>

---

**Line Browser** is a premium mobile web browser focused on privacy, high performance, freedom, and advanced customization, officially developed by **Line Inc.**.

## ⚙️ Engine & Architecture

- **Rendering Engine**: **Mozilla GeckoView v158.0** — the same advanced, independent, and secure web engine used by Firefox desktop and mobile versions. It delivers excellent page load speeds, full support for modern web standards, and native compatibility with desktop extensions.
- **UI Interface**: **Jetpack Compose + Material 3** — a modern, fluid, and responsive interface written in Kotlin with a Clean MVVM architecture (Unidirectional Data Flow).
- **Encryption & Storage**: **Room + SQLCipher (AES-256 encryption)** — hardware-encrypted private storage for data, biometric safe, and passwords.

---

## 📱 Device & System Compatibility

- **Operating System**: Compatible with **Android 8.0 (API level 26)** up to **Android 16+ (API level 36+)**.
- **Processor Hardware Architectures**: 100% Universal support for all processor architectures:
  - **ARM64 (arm64-v8a)**
  - **ARM32 (armeabi-v7a)**
  - **x86 / x86_64**
- **Android 15+ Memory Support (16 KB Page-Size Alignment)**: Implemented with native library extraction (`extractNativeLibs="true"`), offering 100% guaranteed compatibility on next-generation phones running HyperOS / Android 15 (e.g., Poco F7, Samsung Galaxy S23/S24/S25 Ultra, Google Pixel, Xiaomi, OnePlus, Motorola, RealMe, Vivo, Oppo, etc.).

---

## 🛡️ Complete Features

### 🔒 Privacy & De-Googled Protection
- **No Telemetry or Tracking**: Complete elimination of Google tracking services and background analytics. The default search engine is **DuckDuckGo**.
- **Line Shield (Ad & Tracker Blocker)**: Native blocker for ads, pop-up windows, and tracking cookies (powered by EasyList & uAssets).
- **Burn Data (One-Tap Wipe)**: Instant cleanup of history, cookies, cache, and active sessions with a single tap.
- **Private Safe Locker**: Biometric safe (fingerprint/PIN) encrypted with AES-256 for private storage of downloaded files, photos, documents, and passwords.
- **Proxy & Network Hub**:
  - **Integrated Tor Network (`kmp-tor`)**: Anonymous traffic routing through the Tor network.
  - **WireGuard VPN Tunnel**: Support for connecting and configuring VPNs directly via `.conf` files.
  - **Custom SOCKS5 Proxy & Encrypted DNS**: Support for DoH (DNS over HTTPS) and DoT (DNS over TLS).
  - **WebRTC & QUIC Protection**: Prevention of real IP address leaks.

### 🔌 Firefox Desktop Extension Support (WebExtensions)
- **Add-ons Installation**: Ability to install any Firefox-compatible extension (`.xpi`, `.crx`, or unpacked).
- **Pre-integrated Extensions**:
  - **uBlock Origin**: Official content and ad blocker.
  - **Universal Text Copy**: Forcing text copying and selection on protected pages.
  - **Media Grabber**: Detecting and capturing media streams.
  - **AI Overview Blocker**: Hiding AI search result boxes on Google & Bing.
- **Incognito Mode Activation**: Choose which extensions are allowed to run in private tabs.

### 🎥 Media & Downloads
- **Stream Sniffer & Grabber**: Capturing and downloading HLS (`.m3u8`), DASH, and MP4 streams.
- **Integrated ExoPlayer Video Player**: Hardware-accelerated player with onscreen gestures (volume, brightness, scrubbing), speed selector, and quality options.
- **Background Audio/Video Playback**: Continue audio/video playback when the screen is locked or when switching to other apps.
- **External Download Handoff**: Option to hand off downloads to external apps (1DM, ADM, FDM, NDM) or save them to internal storage/private safe.

### 📱 Universal Home Screen Widgets (4 Native Widgets)
- **Search & Quick Actions Bar (4x1)**: Sleek pill-shaped search bar with voice search, QR camera scanner, and 1-tap Incognito switch.
- **Quick Access Shortcuts Grid (4x2)**: Instant access to Line Inc. Website, Downloads, History, Bookmarks, and Incognito.
- **Line Shield Privacy Stats Widget (3x2)**: Real-time live counter showing trackers prevented and bandwidth saved.
- **Combined Search & Shortcuts Widget (4x3)**: High-productivity combo featuring top search bar + bottom shortcuts grid.

### 📱 Split-Screen Dual Browsing
- **Side-by-Side Dual Web View**: Browse two websites simultaneously on a split-screen layout with independent URLs and navigation controls.

### 🔗 Send Tab to Device
- **Instant Tab Pairing & Sharing**: Share or push active web pages to desktop or other mobile devices via instant QR code and link pairing.

### 🛠️ Quick Tools Suite
- **QR & Barcode Scanner/Generator**: Scan via camera or files; generate QR codes for web addresses or text.
- **Native Translator (On-Device & Online)**: 100% private offline translation with downloadable device packages.
- **JavaScript Developer Console (Live REPL)**: Debug and execute JS code in real time.
- **Page Style Editor**: Live JS/CSS injection for visual modification of any website.
- **PDF Export**: Save any web page as a PDF document.
- **Web Apps & PWA Manager**: Add favorite sites to the home screen as PWA shortcuts.

### 🎨 Personalization & Wallpaper Collections
- **LineOS Wallpaper Collection**: Dedicated section featuring 12 high-resolution native LineOS wallpapers.
- **Aero Wallpaper Collection**: Dedicated section featuring 7 classic Windows 7 Aero glass & aurora wallpapers.
- **Visual Themes**: Dark Slate, Pure Black (AMOLED), Creamy Light, and Pure Light modes.
- **Accent Colors**: **Line Emerald Green (`#34C759`) — default by Line Inc.**, Ocean Blue, Crimson Red, Sunset Orange, Royal Purple, Monochrome.
- **Home Screen Customization**: Reorder or toggle sections on/off (Logo, Search, Shortcuts, Recents, Privacy Report).

### 🌍 Multilingual Support (13 Languages)
Full native localization and display language support for:
- 🇬🇧 **English**
- 🇷🇴 **Romanian (Română)**
- 🇪🇸 **Spanish (Español)**
- 🇫🇷 **French (Français)**
- 🇩🇪 **German (Deutsch)**
- 🇮🇳 **Hindi (हिन्दी)**
- 🇵🇹 **Portuguese (Português)**
- 🇵🇱 **Polish (Polski)**
- 🇷🇺 **Russian (Русский)**
- 🇨🇳 **Chinese (简体中文)**
- 🇯🇵 **Japanese (日本語)**
- 🇦🇪 **Arabic (العربية)**
- 🇮🇩 **Indonesian (Bahasa Indonesia)**

---

## 🌐 Official Links & Community

- 🌐 **Official Website**: [lineinc.ro](https://lineinc.ro)
- ✉️ **Support & Contact**: [lineinc.ro/contact/](https://lineinc.ro/contact/)
- 💬 **Discord Community**: [discord.gg/w4F7QAuHBf](https://discord.gg/w4F7QAuHBf)
- 🐙 **GitHub Repository**: [github.com/line-inc/linebrowser](https://github.com/line-inc/linebrowser)
- 📄 **Privacy Policy**: [Privacy Policy Document](https://docs.google.com/document/d/1jjsZudFI7WomhGrvZo6TSNtEGY_yboMXcrdWwlivMtE/edit?tab=t.0#heading=h.120j6elx02sn)

<p align="center">
  <b>Copyright © 2026 Line Inc. All rights reserved.</b>
</p>
