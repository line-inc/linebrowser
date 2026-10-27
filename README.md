# LineBrowser

Line Browser este un navigator web mobil de clasă premium, axat pe confidențialitate, performanță înaltă, libertate și personalizare avansată, dezvoltat oficial de Line Inc..
⚙️ Pe ce este bazat (Engine & Arhitectură)
•
Motor de Randare: Mozilla GeckoView v158.0 — același motor web avansat, independent și securizat utilizat de versiunile desktop și mobile Firefox. Oferă viteze excelente de încărcare a paginilor, suport complet pentru standarde moderne web și compatibilitate nativă cu extensii desktop.
•
Interfață UI: Jetpack Compose + Material 3 — interfață modernă, fluidă și receptivă, scrisă în Kotlin cu arhitectură Clean MVVM (Unidirectional Data Flow).
•
Criptare & Stocare: Room + SQLCipher (criptare AES-256) — stocare privată criptată hardware pentru date, seif biometric și parole.
📱 Compatibilitate Dispozitive & Sisteme
•
Sistem de Operare: Compatibil cu Android 8.0 (API level 26) până la Android 16+ (API level 36+).
•
Arhitecturi Hardware Procesor: Suport 100% Universal pentru toate arhitecturile de procesoare:
◦
ARM64 (arm64-v8a)
◦
ARM32 (armeabi-v7a)
◦
x86 / x86_64
•
Suport Memorie Android 15+ (16 KB Page-Size Alignment): Implementat cu extragere nativă a bibliotecilor (extractNativeLibs="true"), oferind compatibilitate 100% garantată pe telefoane de ultimă generație cu HyperOS / Android 15 (ex. Poco F7, Samsung Galaxy S23/S24/S25 Ultra, Google Pixel, Xiaomi, OnePlus, Motorola, RealMe, Vivo, Oppo etc.).
🛡️ Funcționalități Complete
1. Confidențialitate & Protecție De-Googled
•
Fără Telemetrie sau Urmărire: Eliminarea completă a serviciilor de urmărire Google și fundal analitic. Motorul de căutare implicit este DuckDuckGo.
•
Line Shield (Ad & Tracker Blocker): Blocant nativ de reclame, ferestre pop-up și cookiem-uri de urmărire (bazat pe EasyList & uAssets).
•
Burn Data (Ștergere la un Tap): Curățare instantanee dintr-o singură apăsare a istoricului, fișierelor cookie, memoriei cache și sesiunilor active.
•
Private Safe Locker: Seif biometric (amprentă/PIN) criptat AES-256 pentru stocarea privată a fișierelor descărcate, pozelor, documentelor și parolelor.
•
Proxy & Network Hub:
◦
Rețea Tor Integrată (kmp-tor): Rutare anonimă a traficului prin rețeaua Tor.
◦
Tunel WireGuard VPN: Suport pentru conectare și configurare VPN direct prin fișiere .conf.
◦
Proxy SOCKS5 & DNS Criptat: Suport DoH (DNS over HTTPS) și DoT (DNS over TLS).
◦
Protecție WebRTC & QUIC: Prevenirea scurgerilor de adresă IP reală.
2. Suport Extensii Firefox Desktop (WebExtensions)
•
Instalare Add-ons: Posibilitatea de a instala orice extensie compatibilă Firefox (.xpi, .crx sau neîmpachetată).
•
Extensii Nativ Integrat:
◦
uBlock Origin: Blocant oficial de conținut și reclame.
◦
Universal Text Copy: Forțarea copierii și selecției textului pe pagini protejate.
◦
Media Grabber: Detectarea și capturarea fluxurilor media.
◦
AI Overview Blocker: Ascunderea casetelor de AI din căutări.
•
Activare în Modul Incognito: Puteți alege ce extensii să ruleze și în filele private.
3. Media & Descărcări
•
Stream Sniffer & Grabber: Capturarea și descărcarea fluxurilor HLS (.m3u8), DASH și MP4.
•
Player Video ExoPlayer Integrat: Player hardware-accelerat cu gesturi pe ecran (volum, luminozitate, derulare), selector de viteză și calitate.
•
Redare în Fundal (Background Audio/Video Playback): Continuarea redării audio/video când ecranul este blocat sau când comutați în alte aplicații.
•
Predare Descărcări (External Handoff): Opțiune de predare a descărcărilor către aplicații externe (1DM, ADM, FDM, NDM) sau salvare în managerul intern/seiful privat.
4. Suita Quick Tools
•
Scaner & Generator QR / Coduri de Bare: Scanare prin cameră sau fișiere; generare de coduri QR pentru adrese web sau text.
•
Traducător Nativ (On-Device & Online): Traducere offline 100% privată cu pachete descărcabile pe dispozitiv.
•
Consolă Developer JavaScript (Live REPL): Depanarea și executarea codului JS în timp real.
•
Editor Stil Pagină: Injectare live de JS/CSS pentru modificarea vizuală a oricărui site.
•
Export PDF: Salvarea oricărei pagini web ca document PDF.
•
Web Apps & PWA Manager: Adăugarea site-urilor favorite pe ecranul principal sub formă de scurtături PWA.
5. Personalizare & Colecția LineOS
•
Colecția de Fundaluri LineOS: Secțiune dedicată cu 12 imagini de fundal în rezoluție înaltă integrate nativ în aplicație.
•
Teme Vizuale: Mod Dark Slate, Negru Pur (AMOLED), Crem (Creamy Light) și Luminos (Pure Light).
•
Culori de Accent: Line Emerald Green (#34C759) — Implicit Line Inc., Ocean Blue, Crimson Red, Sunset Orange, Royal Purple, Monochrome.
•
Personalizare Ecran Principal: Reordonarea sau activarea/dezactivarea secțiunilor (Logo, Căutare, Scurtături, Recente, Raport Confidențialitate).
🌐 Legături Oficiale & Comunitate
•
Website Oficial: lineinc.ro
•
Suport & Contact: lineinc.ro/contact/
•
Comunitate Discord: discord.gg/w4F7QAuHBf
•
GitHub: github.com/line-inc/linebrowser
•
Politica de Confidențialitate: Privacy Policy
•
Copyright: Copyright © 2026 Line Inc. All rights reserved.
