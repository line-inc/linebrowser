# Line Browser Desktop (Windows / Linux / macOS)

A native, high-performance desktop web browser built with Python, PyQt6, and QtWebEngine, fully rebranded for **Line Inc.** with custom dark mode, multi-tab support, check for updates via GitHub API, and clean branding.

## How to Run:
1. Install Python 3.10+
2. Install dependencies:
   ```bash
   pip install -r requirements.txt
   ```
3. Run the browser:
   ```bash
   python main.py
   ```
4. To package into a standalone `.exe` for Windows, install PyInstaller:
   ```bash
   pip install pyinstaller
   pyinstaller --noconsole --onefile main.py -n LineBrowser
   ```
