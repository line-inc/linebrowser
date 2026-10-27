# LineBrowser

Line Browser is a premium mobile web browser focused on privacy, high performance, freedom, and advanced customization, officially developed by Line Inc.

⚙️ Engine & Architecture
Rendering Engine: Mozilla GeckoView v158.0 — the same advanced, independent, and secure web engine used by Firefox desktop and mobile versions. It delivers excellent page load speeds, full support for modern web standards, and native compatibility with desktop extensions.

UI Interface: Jetpack Compose + Material 3 — a modern, fluid, and responsive interface written in Kotlin with a Clean MVVM architecture (Unidirectional Data Flow).

Encryption & Storage: Room + SQLCipher (AES-256 encryption) — hardware-encrypted private storage for data, biometric safe, and passwords.

📱 Device & System Compatibility
Operating System: Compatible with Android 8.0 (API level 26) up to Android 16+ (API level 36+).

Processor Hardware Architectures: 100% Universal support for all processor architectures:

ARM64 (arm64-v8a)

ARM32 (armeabi-v7a)

x86 / x86_64

Android 15+ Memory Support (16 KB Page-Size Alignment): Implemented with native library extraction (extractNativeLibs="true"), offering 100% guaranteed compatibility on next-generation phones running HyperOS / Android 15 (e.g., Poco F7, Samsung Galaxy S23/S24/S25 Ultra, Google Pixel, Xiaomi, OnePlus, Motorola, RealMe, Vivo, Oppo, etc.).

🛡️ Complete Features
1. Privacy & De-Googled Protection
No Telemetry or Tracking: Complete elimination of Google tracking services and background analytics. The default search engine is DuckDuckGo.

Line Shield (Ad & Tracker Blocker): Native blocker for ads, pop-up windows, and tracking cookies (powered by EasyList & uAssets).

Burn Data (One-Tap Wipe): Instant cleanup of history, cookies, cache, and active sessions with a single tap.

Private Safe Locker: Biometric safe (fingerprint/PIN) encrypted with AES-256 for private storage of downloaded files, photos, documents, and passwords.

Proxy & Network Hub:

Integrated Tor Network (kmp-tor): Anonymous traffic routing through the Tor network.

WireGuard VPN Tunnel: Support for connecting and configuring VPNs directly via .conf files.

SOCKS5 Proxy & Encrypted DNS: Support for DoH (DNS over HTTPS) and DoT (DNS over TLS).

WebRTC & QUIC Protection: Prevention of real IP address leaks.

2. Firefox Desktop Extension Support (WebExtensions)
Add-ons Installation: Ability to install any Firefox-compatible extension (.xpi, .crx, or unpacked).

Pre-integrated Extensions:

uBlock Origin: Official content and ad blocker.

Universal Text Copy: Forcing text copying and selection on protected pages.

Media Grabber: Detecting and capturing media streams.

AI Overview Blocker: Hiding AI search result boxes.

Incognito Mode Activation: Choose which extensions are allowed to run in private tabs.

3. Media & Downloads
Stream Sniffer & Grabber: Capturing and downloading HLS (.m3u8), DASH, and MP4 streams.

Integrated ExoPlayer Video Player: Hardware-accelerated player with onscreen gestures (volume, brightness, scrubbing), speed selector, and quality options.

Background Audio/Video Playback: Continue audio/video playback when the screen is locked or when switching to other apps.

External Download Handoff: Option to hand off downloads to external apps (1DM, ADM, FDM, NDM) or save them to internal storage/private safe.

4. Quick Tools Suite
QR & Barcode Scanner/Generator: Scan via camera or files; generate QR codes for web addresses or text.

Native Translator (On-Device & Online): 100% private offline translation with downloadable device packages.

JavaScript Developer Console (Live REPL): Debug and execute JS code in real time.

Page Style Editor: Live JS/CSS injection for visual modification of any website.

PDF Export: Save any web page as a PDF document.

Web Apps & PWA Manager: Add favorite sites to the home screen as PWA shortcuts.

5. Personalization & LineOS Collection
LineOS Wallpaper Collection: Dedicated section featuring 12 high-resolution wallpapers natively integrated into the app.

Visual Themes: Dark Slate, Pure Black (AMOLED), Creamy Light, and Pure Light modes.

Accent Colors: Line Emerald Green (#34C759) — default by Line Inc., Ocean Blue, Crimson Red, Sunset Orange, Royal Purple, Monochrome.

Home Screen Customization: Reorder or toggle sections on/off (Logo, Search, Shortcuts, Recents, Privacy Report).

🌐 Official Links & Community
Official Website: lineinc.ro

Support & Contact: lineinc.ro/contact/

Discord Community: discord.gg/w4F7QAuHBf

GitHub: github.com/line-inc/linebrowser

Privacy Policy: Privacy Policy

Copyright: Copyright © 2026 Line Inc. All rights reserved.
