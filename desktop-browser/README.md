# LineBrowser Desktop for Windows

Portul desktop Windows al LineBrowser folosește motorul de randare Gecko.

## Motor

Android folosește **GeckoView 158**. Desktop-ul pornește runtime-ul Gecko cu un profil LineBrowser propriu:

1. `C:\Program Files\Mozilla Firefox\firefox.exe`
2. `C:\Users\WinTechDragos\Desktop\Firefox.exe` dacă e un runtime valid
3. Variabila `LINE_FIREFOX_PATH`
4. Ulterior: un build din `line-desktop-gecko` (mozilla-central)

Extensiile din `app/assets/web_extensions` sunt aceleași ca pe Android.

## Rulare

În PowerShell, din acest folder:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\Run-LineBrowser.ps1
```

Prima rulare copiază runtime-ul Gecko în `runtime\firefox` (ca să putem debloca extensiile nesemnate), apoi profilul LineBrowser în `data\profile`.

## Structură

- `app/assets` — copiate din Android (adblock, AI models, web_extensions)
- `app/ui` — pagină de start, setări, bookmarks, istoric (WebExtension Line UI)
- `app/shield` — Line Shield (lista din `adblock_seed.txt`)
- `profile-template` — `user.js` + `userChrome.css`
- `scripts` — lansare și sincronizare profil
- `line-desktop-gecko` — sursa Mozilla (păstrată; nu e ștearsă)

Pagina Settings arată versiunea LineBrowser 1.0.0, copyright-ul Line Inc. și verifică release-urile repository-ului oficial. Repository-ul publică în prezent un APK Android, nu un installer Windows; actualizarea automată pe Windows necesită publicarea unui pachet desktop pentru Windows.

Gecko este motorul Mozilla și păstrează atribuirea proprie a motorului. Interfața LineBrowser și logo-ul folosesc brandingul Line Inc.

Electron (`package.json`, `main.js`, `index.html`) a fost scos. `node_modules` rămâne doar dacă Windows încă ține `default_app.asar` deschis; șterge-l cu `scripts\Remove-Electron.ps1` după ce închizi procesele care îl blochează.
