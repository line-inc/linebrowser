import SwiftUI
import Combine

// MARK: - Languages

enum AppLanguage: String, CaseIterable, Identifiable {
    case system = "system"
    case english = "en"
    case romanian = "ro"

    var id: String { rawValue }

    /// Display name in the language's own tongue (`.system` is localized at call site).
    var nativeName: String {
        switch self {
        case .system: return ""
        case .english: return "English"
        case .romanian: return "Română"
        }
    }

    /// Localized display name for pickers.
    func displayName(_ lang: LanguageManager) -> String {
        self == .system ? lang.t("ob.language.system") : nativeName
    }

    var flag: String {
        switch self {
        case .system: return "🖥️"
        case .english: return "🇬🇧"
        case .romanian: return "🇷🇴"
        }
    }
}

// MARK: - Language manager

final class LanguageManager: ObservableObject {
    static let shared = LanguageManager()

    private let languageKey = "app.language"
    private let systemLanguagesKey = "app.system.languages"

    @Published private(set) var language: AppLanguage

    /// The languages the device was using before we ever overrode them.
    private let systemLanguages: [String]

    private init() {
        // Snapshot the true device languages (only when not overridden yet).
        let appleLanguages = UserDefaults.standard.stringArray(forKey: "AppleLanguages") ?? []
        if let stored = UserDefaults.standard.stringArray(forKey: systemLanguagesKey) {
            systemLanguages = stored
        } else {
            systemLanguages = appleLanguages
            if !appleLanguages.isEmpty {
                UserDefaults.standard.set(appleLanguages, forKey: systemLanguagesKey)
            }
        }

        let raw = UserDefaults.standard.string(forKey: languageKey) ?? AppLanguage.system.rawValue
        language = AppLanguage(rawValue: raw) ?? .system
    }

    /// The language actually in use right now (`.system` resolved).
    var effective: AppLanguage {
        if language != .system { return language }
        let first = systemLanguages.first ?? "en"
        return first.lowercased().hasPrefix("ro") ? .romanian : .english
    }

    func set(_ newLanguage: AppLanguage) {
        guard newLanguage != language else { return }
        language = newLanguage
        UserDefaults.standard.set(newLanguage.rawValue, forKey: languageKey)

        // Also steer system-provided strings (WebKit form prompts, share sheet, etc.)
        if newLanguage == .system {
            UserDefaults.standard.set(systemLanguages, forKey: "AppleLanguages")
        } else {
            UserDefaults.standard.set([newLanguage.rawValue], forKey: "AppleLanguages")
        }
    }

    /// Looks up a localized string. Falls back to English, then to the key itself.
    func t(_ key: String) -> String {
        let code = effective == .romanian ? "ro" : "en"
        if let value = Strings.table[code]?[key] { return value }
        if let value = Strings.table["en"]?[key] { return value }
        return key
    }
}

// MARK: - Strings

enum Strings {
    static let table: [String: [String: String]] = [
        "en": [
            // Common
            "common.continue": "Continue",
            "common.back": "Back",
            "common.skip": "Skip",
            "common.later": "Maybe later",
            "common.remove": "Remove",

            // Onboarding – welcome
            "ob.welcome.title": "Welcome to Line Browser",
            "ob.welcome.body": "A fast, private and customizable browser built for the modern web.",
            "ob.welcome.note": "Setup takes less than a minute.",
            "ob.welcome.cta": "Get started",

            // Onboarding – language
            "ob.language.title": "Choose your language",
            "ob.language.body": "The whole interface switches instantly. You can change it any time in Settings.",
            "ob.language.system": "System default",
            "ob.language.systemSub": "Follow your iPhone language",

            // Onboarding – search engine
            "ob.search.title": "Default search engine",
            "ob.search.body": "Used whenever you type a question or keyword in the address bar.",
            "ob.search.ddgSub": "Privacy first, zero tracking",
            "ob.search.googleSub": "Familiar results and answers",
            "ob.search.bingSub": "Microsoft search with AI",
            "ob.search.ecosiaSub": "Plant trees with your searches",

            // Onboarding – default browser
            "ob.browser.title": "Set as default browser",
            "ob.browser.body": "Links you tap in other apps open here instead of Safari — mail, chats, notes, everywhere.",
            "ob.browser.hint": "In Settings, tap “Default Browser App” and pick Line Browser.",
            "ob.browser.cta": "Open Settings",
            "ob.browser.returns": "Come back here when you are done.",

            // Onboarding – done
            "ob.done.title": "You're all set",
            "ob.done.body": "Everything is ready. Enjoy browsing with Line Browser.",
            "ob.done.cta": "Start browsing",
            "ob.done.language": "Language",
            "ob.done.search": "Search engine",
            "ob.done.defaultBrowser": "Default browser",
            "ob.done.notSet": "Not set yet",
            "ob.done.progress": "Step %d of %d",

            // Main UI
            "chrome.placeholder": "Search or enter web address",

            // Settings – chrome
            "settings.title": "Settings",
            "settings.close": "Close",
            "settings.section.personalization": "PERSONALIZATION",
            "settings.section.navigation": "WEB BROWSING",
            "settings.section.privacy": "PRIVACY & SECURITY",
            "settings.section.about": "ABOUT",
            "settings.language": "Language",
            "settings.languageSub": "Interface language",
            "settings.defaultBrowser": "Default Browser",
            "settings.defaultBrowserSub": "Open links from other apps here",

            // Settings – rows
            "row.theme.title": "Theme",
            "row.theme.sub": "Dark mode, accent colors, icons",
            "row.layout.title": "Preferences & Layout",
            "row.layout.sub": "Address bar position, toolbars, UI scaling",
            "row.wallpapers.title": "Wallpapers",
            "row.wallpapers.sub": "Browser backgrounds, LineOS & Aero collections",
            "row.accessibility.title": "Accessibility",
            "row.accessibility.sub": "Text scaling, forced zoom, high contrast mode",
            "row.tabs.title": "Tabs",
            "row.tabs.sub": "Tab layouts, background tabs and auto-close",
            "row.sites.title": "Site Settings",
            "row.sites.sub": "Site permissions, JavaScript, pop-ups",
            "row.pwa.title": "Web Apps & PWA",
            "row.pwa.sub": "Manage, clone and discover Progressive Web Apps",
            "row.privacy.title": "Privacy & Security",
            "row.privacy.sub": "Clear browsing data, cookies, secure browsing",
            "row.passwords.title": "Password Manager",
            "row.passwords.sub": "Create, unlock and manage saved credentials",
            "row.vault.title": "Private Vault",
            "row.vault.sub": "Biometric encrypted vault for downloads and documents",
            "row.hub.title": "Privacy Hub",
            "row.hub.sub": "Ad blocking, connection status and the Network Monitor",
            "row.website.title": "Official Website",
            "row.website.sub": "lineinc.ro",

            // Settings – destinations
            "dest.theme": "Theme Settings",
            "dest.layout": "Preferences & Layout",
            "dest.wallpapers": "Wallpapers",
            "dest.accessibility": "Accessibility",
            "dest.tabs": "Tab Settings",
            "dest.sites": "Site Settings",
            "dest.pwa": "Web Apps & PWA",
            "dest.privacy": "Privacy & Security",
            "dest.passwords": "Password Manager",
            "dest.vault": "Private Vault",
            "dest.hub": "Privacy Hub",

            // Settings – about
            "settings.version": "App Version",
            "settings.copyright": "Copyright",
            "settings.website": "Official Website",

            // Shared screen chrome
            "settings.done": "Done",
            "chrome.retry": "Retry",

            // Theme
            "screen.theme.title": "Theme",
            "theme.accent": "ACCENT COLOR",
            "theme.surface": "SURFACE",
            "theme.oled": "Pure black (OLED)",
            "theme.oledSub": "True black background, saves battery on OLED",
            "theme.preview": "PREVIEW",

            // Layout
            "screen.layout.title": "Preferences & Layout",
            "layout.bar": "ADDRESS BAR",
            "layout.barTop": "Top",
            "layout.barBottom": "Bottom",
            "layout.home": "HOME PAGE",
            "layout.homeSub": "Opened by the home button",
            "layout.save": "Save",
            "layout.tabs": "TABS",
            "layout.tabCount": "Show tab count",
            "layout.tabCountSub": "Badge on the tabs button",
            "layout.restore": "Restore session on launch",
            "layout.restoreSub": "Reopen your tabs next time",

            // Wallpapers
            "screen.wallpaper.title": "Wallpapers",
            "wall.preset": "PRESETS",
            "wall.none": "None",
            "wall.custom": "YOUR PHOTO",
            "wall.customSub": "Shown behind the browser chrome and blank pages",
            "wall.pick": "Choose photo",
            "wall.remove": "Remove photo",
            "wall.note": "Your photo stays on this iPhone — it is never uploaded.",

            // Accessibility
            "screen.accessibility.title": "Accessibility",
            "a11y.text": "TEXT SIZE",
            "a11y.display": "DISPLAY",
            "a11y.motion": "Reduce motion",
            "a11y.motionSub": "Minimize animations and transitions",
            "a11y.contrast": "High contrast",
            "a11y.contrastSub": "Stronger colors and borders for readability",
            "a11y.web": "WEB CONTENT",
            "a11y.zoom": "Allow pinch zoom",
            "a11y.zoomSub": "Zoom into pages with two fingers",

            // Tabs
            "screen.tabs.title": "Tabs",
            "tabs.title": "Open Tabs",
            "tabs.open": "OPEN TABS",
            "tabs.new": "New Tab",
            "tabs.closeAll": "Close All",
            "tabs.confirmClose": "Close all tabs?",
            "tabs.untitled": "Untitled",
            "tabs.empty": "No open tabs yet.",
            "tabs.bookmarks": "BOOKMARKS",

            // Site settings
            "screen.site.title": "Site Settings",
            "site.engine": "SEARCH ENGINE",
            "site.engineSub": "Used when you type a keyword",
            "site.behaviour": "BEHAVIOUR",
            "site.js": "JavaScript",
            "site.jsSub": "Required by most sites; turn off to harden",
            "site.popups": "Block pop-ups",
            "site.popupsSub": "Refuse windows opened by scripts",
            "site.newTab": "Open links in new tab",
            "site.newTabSub": "Links that open a new window become a tab",
            "site.data": "WEBSITE DATA",
            "site.dataSub": "Cookies, cache and local storage",
            "site.clear": "Clear website data",
            "site.cleared": "Website data cleared",
            "site.clearConfirm": "Delete all cookies and cached files?",

            // Web apps
            "screen.pwa.title": "Web Apps & PWA",
            "pwa.current": "CURRENT PAGE",
            "pwa.add": "Add",
            "pwa.share": "Share",
            "pwa.note": "Use Share ▸ Add to Home Screen for a real home-screen icon.",
            "pwa.installed": "SAVED WEB APPS",
            "pwa.empty": "No web apps saved yet.",

            // Privacy & security
            "screen.privacy.title": "Privacy & Security",
            "privacy.protection": "PROTECTION",
            "privacy.blockAds": "Block ads & trackers",
            "privacy.blockAdsSub": "Filters requests to known ad and analytics networks",
            "privacy.clearOnExit": "Clear data in background",
            "privacy.clearOnExitSub": "Wipes cookies and cache when you switch away",
            "privacy.keychain": "Keychain storage",
            "privacy.keychainSub": "Passwords are kept in the iOS keychain",
            "privacy.data": "BROWSING DATA",
            "privacy.dataSub": "Everything stored by visited sites",
            "privacy.clearNow": "Clear browsing data",
            "privacy.note": "Browsing history never leaves this device.",
            "privacy.on": "On",
            "privacy.off": "Off",

            // Privacy hub
            "screen.hub.title": "Privacy Hub",
            "hub.connection": "CONNECTION",
            "hub.secure": "Secure connection",
            "hub.insecure": "Not encrypted",
            "hub.network": "NETWORK PRIVACY",
            "hub.dns": "Encrypted DNS",
            "hub.dnsSub": "Configure DNS over HTTPS in iOS Settings",
            "hub.toolsNote": "The Network Monitor shows every request the current page makes — images, scripts, analytics — with status codes and sizes.",
            "hub.trackingNote": "Ad & tracker blocking and encrypted DNS cover the everyday tracking vectors.",

            // Passwords
            "screen.passwords.title": "Password Manager",
            "pw.add": "ADD CREDENTIAL",
            "pw.addSub": "Stored in the iOS keychain, never in the cloud",
            "pw.site": "Website",
            "pw.username": "Username or email",
            "pw.password": "Password",
            "pw.save": "Save password",
            "pw.saved": "SAVED PASSWORDS",
            "pw.empty": "No passwords saved yet.",
            "pw.note": "Tap the eye to reveal, the doc icon to copy.",
            "pw.reveal": "Reveal password",
            "pw.hide": "Hide password",
            "pw.copy": "Copy password",
            "pw.copied": "Password copied",
            "pw.delete": "Delete password",

            // Vault
            "screen.vault.title": "Private Vault",
            "vault.locked": "Vault locked",
            "vault.lockedSub": "Items are encrypted with AES-256 and only decrypt after Face ID or your passcode.",
            "vault.unlock": "Unlock vault",
            "vault.reason": "Unlock your private vault",
            "vault.unlocked": "Unlocked",
            "vault.lockedShort": "Locked",
            "vault.add": "NEW ITEM",
            "vault.titleField": "Title",
            "vault.contentField": "Secret content…",
            "vault.encrypt": "Encrypt & save",
            "vault.items": "ENCRYPTED ITEMS",
            "vault.empty": "Nothing stored yet.",
            "vault.delete": "Delete permanently",
            "vault.lock": "Lock vault",

            // Network
            "settings.section.network": "NETWORK",
            "row.monitor.title": "Network Monitor",
            "row.monitor.sub": "Every request the page makes",
            "hub.tools": "NETWORK TOOLS",
            "screen.monitor.title": "Network Monitor",
            "monitor.live": "LIVE TRAFFIC",
            "monitor.captured": "requests captured",
            "monitor.clear": "Clear",
            "monitor.search": "Filter URLs",
            "monitor.empty": "No requests captured yet",
            "monitor.emptySub": "Open a page — every request it makes (documents, images, scripts, fetch/XHR) shows up here live.",
            "monitor.noMatch": "No matching requests",
            "monitor.note": "Captured in-page by this browser — only requests from the page you have open. Nothing is sent anywhere.",
        ],

        "ro": [
            // Comun
            "common.continue": "Continuă",
            "common.back": "Înapoi",
            "common.skip": "Sari",
            "common.later": "Mai târziu",
            "common.remove": "Elimină",

            // Onboarding – bun venit
            "ob.welcome.title": "Bine ai venit în Line Browser",
            "ob.welcome.body": "Un browser rapid, privat și personalizabil, construit pentru web-ul modern.",
            "ob.welcome.note": "Configurarea durează mai puțin de un minut.",
            "ob.welcome.cta": "Începe",

            // Onboarding – limbă
            "ob.language.title": "Alege limba",
            "ob.language.body": "Toată interfața se schimbă instant. Poți modifica oricând din Setări.",
            "ob.language.system": "Limba sistemului",
            "ob.language.systemSub": "După limba iPhone-ului",

            // Onboarding – motor de căutare
            "ob.search.title": "Motor de căutare implicit",
            "ob.search.body": "Este folosit de fiecare dată când scrii o întrebare sau un cuvânt cheie în bara de adrese.",
            "ob.search.ddgSub": "Confidențialitate, fără urmărire",
            "ob.search.googleSub": "Rezultate și răspunsuri familiare",
            "ob.search.bingSub": "Căutarea Microsoft cu IA",
            "ob.search.ecosiaSub": "Plantează copaci cu căutările tale",

            // Onboarding – browser implicit
            "ob.browser.title": "Setează ca browser implicit",
            "ob.browser.body": "Linkurile atinse în alte aplicații se deschid aici, nu în Safari — mail, chat, notițe, peste tot.",
            "ob.browser.hint": "În Setări, apasă „Browser implicit” și alege Line Browser.",
            "ob.browser.cta": "Deschide Setările",
            "ob.browser.returns": "Revino aici când ai terminat.",

            // Onboarding – gata
            "ob.done.title": "Ești pregătit",
            "ob.done.body": "Totul este configurat. Naveghează cu plăcere în Line Browser.",
            "ob.done.cta": "Începe navigarea",
            "ob.done.language": "Limbă",
            "ob.done.search": "Motor de căutare",
            "ob.done.defaultBrowser": "Browser implicit",
            "ob.done.notSet": "Nesetat încă",
            "ob.done.progress": "Pasul %d din %d",

            // Interfața principală
            "chrome.placeholder": "Caută sau introdu adresa web",

            // Setări – chenar
            "settings.title": "Setări",
            "settings.close": "Închide",
            "settings.section.personalization": "PERSONALIZARE",
            "settings.section.navigation": "NAVIGARE WEB",
            "settings.section.privacy": "CONFIDENȚIALITATE ȘI SECURITATE",
            "settings.section.about": "DESPRE",
            "settings.language": "Limbă",
            "settings.languageSub": "Limba interfeței",
            "settings.defaultBrowser": "Browser Implicit",
            "settings.defaultBrowserSub": "Deschide aici linkurile din alte aplicații",

            // Setări – rânduri
            "row.theme.title": "Temă",
            "row.theme.sub": "Mod întunecat, culori de accent, iconițe",
            "row.layout.title": "Preferințe și Aranjament",
            "row.layout.sub": "Poziție bară de adrese, bare de navigare, scalare UI",
            "row.wallpapers.title": "Imagini de fundal",
            "row.wallpapers.sub": "Fundal browser, colecții LineOS & Aero",
            "row.accessibility.title": "Accesibilitate",
            "row.accessibility.sub": "Scalare text, forțare zoom, mod contrast ridicat",
            "row.tabs.title": "File",
            "row.tabs.sub": "Aranjamente file, file în fundal și închidere automată",
            "row.sites.title": "Setări Site",
            "row.sites.sub": "Gestionare permisiuni site, JavaScript, pop-up-uri",
            "row.pwa.title": "Aplicații Web & PWA",
            "row.pwa.sub": "Gestionare, clonare și descoperire Progressive Web Apps",
            "row.privacy.title": "Confidențialitate și Securitate",
            "row.privacy.sub": "Șterge datele de navigare, cookie-uri, navigare sigură",
            "row.passwords.title": "Manager de Parole",
            "row.passwords.sub": "Creați, deblocați și gestionați credențialele salvate",
            "row.vault.title": "Seif Privat",
            "row.vault.sub": "Seif criptat biometric pentru descărcări și documente",
            "row.hub.title": "Hub de Confidențialitate",
            "row.hub.sub": "Blocare reclame, stare conexiune și Monitorul de rețea",
            "row.website.title": "Website Oficial",
            "row.website.sub": "lineinc.ro",

            // Setări – destinații
            "dest.theme": "Setări Temă",
            "dest.layout": "Preferințe și Layout",
            "dest.wallpapers": "Imagini de fundal",
            "dest.accessibility": "Accesibilitate",
            "dest.tabs": "Setări File",
            "dest.sites": "Setări Site",
            "dest.pwa": "Aplicații Web & PWA",
            "dest.privacy": "Confidențialitate și Securitate",
            "dest.passwords": "Manager de Parole",
            "dest.vault": "Seif Privat (Safe Locker)",
            "dest.hub": "Hub de Confidențialitate",

            // Setări – despre
            "settings.version": "Versiune Aplicație",
            "settings.copyright": "Copyright",
            "settings.website": "Website Oficial",

            // Interfața ecranelor
            "settings.done": "Gata",
            "chrome.retry": "Reîncearcă",

            // Temă
            "screen.theme.title": "Temă",
            "theme.accent": "CULOARE DE ACCENT",
            "theme.surface": "SUPRAFAȚĂ",
            "theme.oled": "Negru pur (OLED)",
            "theme.oledSub": "Fundal negru adevărat, economisește bateria pe OLED",
            "theme.preview": "PREVIZUALIZARE",

            // Layout
            "screen.layout.title": "Preferințe și Layout",
            "layout.bar": "BARĂ DE ADRESE",
            "layout.barTop": "Sus",
            "layout.barBottom": "Jos",
            "layout.home": "PAGINA DE START",
            "layout.homeSub": "Deschisă de butonul Acasă",
            "layout.save": "Salvează",
            "layout.tabs": "FILE",
            "layout.tabCount": "Arată numărul de file",
            "layout.tabCountSub": "Insignă pe butonul de file",
            "layout.restore": "Restaurează sesiunea la pornire",
            "layout.restoreSub": "Redeschide filele data viitoare",

            // Imagini de fundal
            "screen.wallpaper.title": "Imagini de fundal",
            "wall.preset": "PRESETĂRI",
            "wall.none": "Fără",
            "wall.custom": "FOTOGRAFIA TA",
            "wall.customSub": "Se vede în spatele interfeței și al paginilor goale",
            "wall.pick": "Alege fotografie",
            "wall.remove": "Elimină fotografia",
            "wall.note": "Fotografia rămâne pe acest iPhone — nu este încărcată nicăieri.",

            // Accesibilitate
            "screen.accessibility.title": "Accesibilitate",
            "a11y.text": "DIMENSIUNEA TEXTULUI",
            "a11y.display": "AFIȘARE",
            "a11y.motion": "Reduc mișcarea",
            "a11y.motionSub": "Minimizează animațiile și tranzițiile",
            "a11y.contrast": "Contrast ridicat",
            "a11y.contrastSub": "Culori și borduri mai puternice pentru lizibilitate",
            "a11y.web": "CONȚINUT WEB",
            "a11y.zoom": "Permite zoom cu degetele",
            "a11y.zoomSub": "Apropie paginile cu două degete",

            // File
            "screen.tabs.title": "File",
            "tabs.title": "File Deschise",
            "tabs.open": "FILE DESCHISE",
            "tabs.new": "File nou",
            "tabs.closeAll": "Închide toate",
            "tabs.confirmClose": "Închizi toate filele?",
            "tabs.untitled": "Fără titlu",
            "tabs.empty": "Nicio filă deschisă încă.",
            "tabs.bookmarks": "MARCAJE",

            // Setări site
            "screen.site.title": "Setări Site",
            "site.engine": "MOTOR DE CĂUTARE",
            "site.engineSub": "Folosit când scrii un cuvânt cheie",
            "site.behaviour": "COMPORTAMENT",
            "site.js": "JavaScript",
            "site.jsSub": "Necesar pentru majoritatea site-urilor; dezactivează pentru protecție",
            "site.popups": "Blochează pop-up-urile",
            "site.popupsSub": "Refuză ferestrele deschise de scripturi",
            "site.newTab": "Deschide linkurile în filă nouă",
            "site.newTabSub": "Linkurile care deschid ferestre noi devin file",
            "site.data": "DATE SITE",
            "site.dataSub": "Cookie-uri, cache și stocare locală",
            "site.clear": "Șterge datele site-urilor",
            "site.cleared": "Datele site-urilor au fost șterse",
            "site.clearConfirm": "Ștergi toate cookie-urile și fișierele din cache?",

            // Aplicații web
            "screen.pwa.title": "Aplicații Web & PWA",
            "pwa.current": "PAGINA ACTUALĂ",
            "pwa.add": "Adaugă",
            "pwa.share": "Trimite",
            "pwa.note": "Folosește Trimite ▸ Adaugă pe ecranul principal pentru o pictogramă reală.",
            "pwa.installed": "APLICAȚII WEB SALVATE",
            "pwa.empty": "Nicio aplicație web salvată încă.",

            // Confidențialitate
            "screen.privacy.title": "Confidențialitate și Securitate",
            "privacy.protection": "PROTECȚIE",
            "privacy.blockAds": "Blochează reclamele și trackerele",
            "privacy.blockAdsSub": "Filtrează cererile către rețelele de reclame și analiză cunoscute",
            "privacy.clearOnExit": "Șterge datele în fundal",
            "privacy.clearOnExitSub": "Curăță cookie-urile și cache-ul când schimbi aplicația",
            "privacy.keychain": "Stocare în Keychain",
            "privacy.keychainSub": "Parolele sunt ținute în keychain-ul iOS",
            "privacy.data": "DATE DE NAVIGARE",
            "privacy.dataSub": "Tot ce stochează site-urile vizitate",
            "privacy.clearNow": "Șterge datele de navigare",
            "privacy.note": "Istoricul de navigare nu părăsește niciodată acest dispozitiv.",
            "privacy.on": "Pornit",
            "privacy.off": "Oprit",

            // Hub
            "screen.hub.title": "Hub de Confidențialitate",
            "hub.connection": "CONEXIUNE",
            "hub.secure": "Conexiune securizată",
            "hub.insecure": "Necriptată",
            "hub.network": "PRIVACITATE DE REȚEA",
            "hub.dns": "DNS criptat",
            "hub.dnsSub": "Configurează DNS peste HTTPS în Setările iOS",
            "hub.toolsNote": "Monitorul de rețea arată fiecare cerere pe care o face pagina curentă — imagini, scripturi, analytics — cu coduri de status și dimensiuni.",
            "hub.trackingNote": "Blocarea reclamelor și DNS-ul criptat acoperă vectorii de tracking obișnuiți.",

            // Parole
            "screen.passwords.title": "Manager de Parole",
            "pw.add": "ADAUGĂ CREDENȚIAL",
            "pw.addSub": "Stocate în keychain-ul iOS, niciodată în cloud",
            "pw.site": "Site",
            "pw.username": "Nume de utilizator sau email",
            "pw.password": "Parolă",
            "pw.save": "Salvează parola",
            "pw.saved": "PAROLE SALVATE",
            "pw.empty": "Nicio parolă salvată încă.",
            "pw.note": "Atinge ochiul pentru a afișa, iconița pentru a copia.",
            "pw.reveal": "Arată parola",
            "pw.hide": "Ascunde parola",
            "pw.copy": "Copiază parola",
            "pw.copied": "Parolă copiată",
            "pw.delete": "Șterge parola",

            // Seif
            "screen.vault.title": "Seif Privat",
            "vault.locked": "Seif blocat",
            "vault.lockedSub": "Elementele sunt criptate cu AES-256 și se decriptează doar după Face ID sau codul de siguranță.",
            "vault.unlock": "Deblochează seiful",
            "vault.reason": "Deblochează seiful tău privat",
            "vault.unlocked": "Deblocat",
            "vault.lockedShort": "Blocat",
            "vault.add": "ELEMENT NOU",
            "vault.titleField": "Titlu",
            "vault.contentField": "Conținut secret…",
            "vault.encrypt": "Criptează și salvează",
            "vault.items": "ELEMENTE CRIPATE",
            "vault.empty": "Nimic stocat încă.",
            "vault.delete": "Șterge definitiv",
            "vault.lock": "Blochează seiful",

            // Rețea
            "settings.section.network": "REȚEA",
            "row.monitor.title": "Monitor de rețea",
            "row.monitor.sub": "Fiecare cerere a paginii",
            "hub.tools": "UNELTE DE REȚEA",
            "screen.monitor.title": "Monitor de rețea",
            "monitor.live": "TRAFIC ÎN DIRECT",
            "monitor.captured": "cereri capturate",
            "monitor.clear": "Golește",
            "monitor.search": "Filtrează URL-uri",
            "monitor.empty": "Încă nu s-au capturat cereri",
            "monitor.emptySub": "Deschide o pagină — fiecare cerere pe care o face (documente, imagini, scripturi, fetch/XHR) apare aici în direct.",
            "monitor.noMatch": "Nicio cerere potrivită",
            "monitor.note": "Capturat în pagină de acest browser — doar cererile paginii deschise. Nimic nu este trimis nicăieri.",
        ],
    ]
}
