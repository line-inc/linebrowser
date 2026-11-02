# App Store submission checklist — Line Browser

Bundle ID `com.lineinc.linebrowser` · Apple ID **6829544330** · SKU `linebrowser-001`
Repo: `line-inc/linebrowser`, branch `iOS`, HEAD `5bb49da` (in sync)

Copy lives in **`AppStoreCopy.md`**. Paste from there — do not retype.

---

## 1. Upload the build

```
build/export/Line Browser.ipa     1,587,746 bytes (1.59 MB)
```

1. Open **Xcode → Window → Organizer**.
2. Select the archive under *Line Browser*, click **Distribute App → Custom**.
3. Sign in with **your own** Apple ID (not the `line-inc` CI identity).

### Verified on the exported IPA

Inspected `Payload/LineBrowser.app` directly — these are facts, not assumptions:

| Check | Result |
|---|---|
| Bundle ID | `com.lineinc.linebrowser` ✅ |
| Version / build | `1.0.0` / `4` |
| Deployment target | iOS 16.0 · device family iPhone + iPad |
| App extensions | **none** — 0 `.appex` in the archive |
| NetworkExtension | **not linked** (`otool -L` clean) |
| VPN strings | **0** in `Info.plist` |
| Export compliance | `ITSAppUsesNonExemptEncryption = false` ✅ |
| Screenshot harness | compiled out of Release (`--lb-shot` absent) |
| Permissions | **Face ID only** (`NSFaceIDUsageDescription`) |

**If App Review asks about ATS:** `NSAllowsArbitraryLoads = true` is set because
this is a browser — it must load arbitrary `http`/`https` URLs the user types.
That is the expected configuration for this category, not a workaround.

> Xcode may rewrite `LineBrowser.xcodeproj/project.pbxproj` when it opens the
> project ("Recovered References" has corrupted the bundle ID before).
> If `git status` shows the pbxproj modified, run:
> `git checkout -- LineBrowser.xcodeproj/`

---

## 2. Screenshots — 18 files, already captured

Source: `build/screenshots/appstore/`

| Folder | Files | Dimensions | Slot |
|---|---|---|---|
| `6.9-inch/` | `01-web` … `06-settings` | 1320 × 2868 | iPhone 6.9" |
| `6.3-inch/` | `01-web` … `06-settings` | 1206 × 2622 | iPhone 6.3" |
| `13-inch-ipad/` | `01-web` … `06-settings` | 2064 × 2752 | iPad 13" |

Upload **in numeric order** — all three sets share the same sequence:

```
01-web  02-privacy  03-netmonitor  04-passwords  05-vault  06-settings
```

> The 13-inch iPad set is **required** — its absence is what produced
> *"Unable to Add for Review."*

---

## 3. App information

| Field | Value |
|---|---|
| **Primary Category** | **Utilities** ← also required; missing this blocks review |
| Secondary Category | Productivity |
| Age Rating | 17+ |
| Subtitle | `Private ad-blocked browser` (26/30) |
| Copyright | `© 2026 Line Inc.` |
| Keywords | `browser,adblock,tracker,password,secure,private,blocker,romana,tabs,pwa` (71/100) |
| Privacy Policy URL | `https://vladutzztech.github.io/lineinc-privacy/` ✅ live, VPN-free |

**Promotional text** (editable anytime, 170 max):
- EN — 155/170
- RO — 167/170

**Description** (EN + RO) — paste from `AppStoreCopy.md`, sections `## Description — EN`
and `## Description — RO`.

> ⚠️ **Subtitle and Description lock on first submission.** Get them right now.

---

## 4. App Privacy

Already declared: **"We do not collect data."** Matches the app — no analytics SDK,
no tracking pixel, no backend. Leave as-is.

Privacy Policy URL must be reachable (confirmed HTTP 200, bilingual EN/RO,
**0** references to VPN / Network Extension / DNS Sniffer).

---

## 5. Before you click Submit

- [ ] Build uploaded and shows as *Ready to Submit* in App Store Connect
- [ ] All **18** screenshots present (6 + 6 + 6) and in the right slots
- [ ] **Primary Category = Utilities**
- [ ] Subtitle / Description / Keywords / Promo pasted from `AppStoreCopy.md`
- [ ] Privacy Policy URL set and verified live
- [ ] Export compliance answered (**no** encryption beyond the OS — the app adds none)
- [ ] `project.pbxproj` unmodified: `git status --short` shows nothing

---

## Optional

**Install on your iPhone for a hands-on pass** (physical device, not screenshots):

```
UDID 00008150-000C54503EE3401C  (iPhone 17)
```

Build Debug for the device and tap through the Network section — screenshots
were captured on simulators specifically to keep your personal data off them.
