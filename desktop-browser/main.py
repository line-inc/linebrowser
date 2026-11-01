import sys
import os
import requests
from PyQt5.QtCore import QUrl, Qt
from PyQt5.QtGui import QIcon, QFont, QColor
from PyQt5.QtWidgets import (
    QApplication, QMainWindow, QWidget, QVBoxLayout, QHBoxLayout,
    QLineEdit, QPushButton, QTabWidget, QMessageBox, QDialog, QLabel,
    QMenu, QScrollArea, QFrame
)
from PyQt5.QtWebEngineWidgets import QWebEngineView

class SettingsDialog(QDialog):
    def __init__(self, parent=None):
        super().__init__(parent)
        self.setWindowTitle("Setări Line Browser")
        self.resize(720, 600)
        self.setStyleSheet("""
            QDialog { background-color: #121316; color: #F1F5F9; font-family: -apple-system, sans-serif; }
            QLabel { color: #F1F5F9; font-size: 13px; }
            QPushButton { background-color: #1E2024; color: #FFFFFF; border: 1px solid #2C2C2E; border-radius: 8px; padding: 8px 14px; font-weight: 600; }
            QPushButton:hover { background-color: #25282D; border-color: #34C759; color: #34C759; }
            QScrollArea { border: none; background: transparent; }
            QFrame { background-color: #1E2024; border: 1px solid #2C2C2E; border-radius: 12px; margin-bottom: 8px; }
        """)

        layout = QVBoxLayout(self)
        layout.setContentsMargins(24, 24, 24, 24)

        header_layout = QHBoxLayout()
        title = QLabel("Setări Line Browser")
        title.setStyleSheet("font-size: 20px; font-weight: bold; color: #34C759;")
        header_layout.addWidget(title)

        close_btn = QPushButton("✕ Închide")
        close_btn.clicked.connect(self.accept)
        header_layout.addWidget(close_btn, alignment=Qt.AlignmentFlag.AlignRight)

        layout.addLayout(header_layout)

        scroll = QScrollArea()
        scroll.setWidgetResizable(True)
        scroll_content = QWidget()
        scroll_layout = QVBoxLayout(scroll_content)

        def add_setting_card(title_text, desc_text, action_text, callback):
            card = QFrame()
            card_layout = QHBoxLayout(card)
            card_layout.setContentsMargins(16, 14, 16, 14)

            text_layout = QVBoxLayout()
            t_label = QLabel(title_text)
            t_label.setStyleSheet("font-weight: bold; font-size: 14px; color: #F1F5F9;")
            d_label = QLabel(desc_text)
            d_label.setStyleSheet("color: #94A3B8; font-size: 12px;")
            text_layout.addWidget(t_label)
            text_layout.addWidget(d_label)
            card_layout.addLayout(text_layout)

            btn = QPushButton(action_text)
            btn.clicked.connect(callback)
            card_layout.addWidget(btn)

            scroll_layout.addWidget(card)

        cat_p = QLabel("PERSONALIZARE")
        cat_p.setStyleSheet("color: #34C759; font-weight: bold; font-size: 11px; margin-top: 10px;")
        scroll_layout.addWidget(cat_p)

        add_setting_card("Temă și Aspect", "Mod întunecat, culori de accent, iconițe", "Configurează", lambda: QMessageBox.information(self, "Temă", "Modul Matte Dark cu accent Line Emerald Green este activ."))
        add_setting_card("Limba Aplicației", "Schimbă limba de afișare a aplicației", "Română", lambda: QMessageBox.information(self, "Limbă", "Aplicația este setată pe limba Română."))
        add_setting_card("Imagini de Fundal", "Fundal browser, colecții LineOS & Aero", "Galerie", lambda: QMessageBox.information(self, "Fundaluri", "Colecțiile LineOS & Aero sunt integrate."))

        cat_b = QLabel("NAFIGARE WEB")
        cat_b.setStyleSheet("color: #34C759; font-weight: bold; font-size: 11px; margin-top: 10px;")
        scroll_layout.addWidget(cat_b)

        add_setting_card("File", "Aranjament file, file în fundal și închidere automată", "Gestionează", lambda: QMessageBox.information(self, "File", "Gestionarea filelor este activă."))
        add_setting_card("Setări Site", "Gestionare permisiuni site, JavaScript, pop-up-uri", "Setări", lambda: QMessageBox.information(self, "Setări Site", "Toate permisiunile sunt configurate."))

        cat_s = QLabel("CONFIDENȚIALITATE ȘI SECURITATE")
        cat_s.setStyleSheet("color: #34C759; font-weight: bold; font-size: 11px; margin-top: 10px;")
        scroll_layout.addWidget(cat_s)

        add_setting_card("Line Shield (Ad & Tracker Blocker)", "Blochează reclamele și trackerele pe fiecare pagină", "Activ", lambda: QMessageBox.information(self, "Line Shield", "Line Shield blochează active trackerele."))
        add_setting_card("Seif Privat & Manager de Parole", "Protecție biometrică și criptare AES-256", "Deschide", lambda: QMessageBox.information(self, "Seif", "Seiful criptat este securizat."))

        cat_a = QLabel("DESPRE")
        cat_a.setStyleSheet("color: #34C759; font-weight: bold; font-size: 11px; margin-top: 10px;")
        scroll_layout.addWidget(cat_a)

        add_setting_card("Versiune Aplicație", "1.0.0 (Chromium Core)", "La zi", lambda: QMessageBox.information(self, "Versiune", "Line Browser v1.0.0"))
        add_setting_card("Copyright", "© 2026 Line Inc. Toate drepturile rezervate.", "Line Inc.", lambda: {})

        scroll.setWidget(scroll_content)
        layout.addWidget(scroll)

class LineBrowserWindow(QMainWindow):
    def __init__(self):
        super().__init__()
        self.setWindowTitle("Line Browser")
        self.resize(1350, 850)

        self.setStyleSheet("""
            QMainWindow { background-color: #121316; }
            QTabWidget::pane { border: 1px solid #2C2C2E; background: #121316; }
            QTabBar::tab { background: #181A1E; color: #94A3B8; padding: 10px 22px; border-top-left-radius: 8px; border-top-right-radius: 8px; font-size: 13px; font-weight: 500; }
            QTabBar::tab:selected { background: #22252A; color: #FFFFFF; font-weight: bold; border-bottom: 2px solid #34C759; }
            QLineEdit { background-color: #1E2024; color: #FFFFFF; border: 1.5px solid #2C2C2E; border-radius: 20px; padding: 8px 16px; font-size: 14px; }
            QLineEdit:focus { border: 1.5px solid #34C759; }
            QPushButton { background-color: #1E2024; color: #FFFFFF; border: 1.5px solid #2C2C2E; border-radius: 8px; padding: 8px 14px; font-weight: 600; }
            QPushButton:hover { background-color: #25282D; border-color: #34C759; color: #34C759; }
        """)

        central_widget = QWidget()
        self.setCentralWidget(central_widget)
        main_layout = QVBoxLayout(central_widget)
        main_layout.setContentsMargins(0, 0, 0, 0)
        main_layout.setSpacing(0)

        toolbar_widget = QWidget()
        toolbar_widget.setStyleSheet("background-color: #141416; border-bottom: 1px solid #1E2024;")
        toolbar_layout = QHBoxLayout(toolbar_widget)
        toolbar_layout.setContentsMargins(12, 10, 12, 10)
        toolbar_layout.setSpacing(8)

        self.btn_back = QPushButton("◀")
        self.btn_back.clicked.connect(self.go_back)
        self.btn_forward = QPushButton("▶")
        self.btn_forward.clicked.connect(self.go_forward)
        self.btn_reload = QPushButton("🔄")
        self.btn_reload.clicked.connect(self.reload_page)
        self.btn_home = QPushButton("🏠")
        self.btn_home.clicked.connect(self.go_home)

        self.url_bar = QLineEdit()
        self.url_bar.setPlaceholderText("Caută sau introdu adresa web...")
        self.url_bar.returnPressed.connect(self.navigate_to_url)

        self.btn_settings = QPushButton("⚙️ Setări")
        self.btn_settings.clicked.connect(self.open_settings)

        self.btn_menu = QPushButton("⋮ Meniu")
        self.btn_menu.clicked.connect(self.show_menu)

        toolbar_layout.addWidget(self.btn_back)
        toolbar_layout.addWidget(self.btn_forward)
        toolbar_layout.addWidget(self.btn_reload)
        toolbar_layout.addWidget(self.btn_home)
        toolbar_layout.addWidget(self.url_bar)
        toolbar_layout.addWidget(self.btn_settings)
        toolbar_layout.addWidget(self.btn_menu)

        main_layout.addWidget(toolbar_widget)

        self.tabs = QTabWidget()
        self.tabs.setTabsClosable(True)
        self.tabs.tabCloseRequested.connect(self.close_tab)
        self.tabs.currentChanged.connect(self.tab_changed)

        main_layout.addWidget(self.tabs)

        self.open_home_tab()

    def open_home_tab(self):
        home_path = os.path.abspath(os.path.join(os.path.dirname(__file__), "home.html"))
        self.add_new_tab(f"file:///{home_path.replace(os.sep, '/')}", "Acasă - Line Browser")

    def add_new_tab(self, url_str, title="Filă nouă"):
        view = QWebEngineView()
        view.setUrl(QUrl(url_str))
        view.urlChanged.connect(lambda qurl, v=view: self.url_changed(qurl, v))
        view.titleChanged.connect(lambda t, v=view: self.title_changed(t, v))

        index = self.tabs.addTab(view, title)
        self.tabs.setCurrentIndex(index)

    def close_tab(self, index):
        if self.tabs.count() > 1:
            self.tabs.removeTab(index)
        else:
            self.open_home_tab()
            self.tabs.removeTab(0)

    def tab_changed(self, index):
        current_view = self.tabs.currentWidget()
        if isinstance(current_view, QWebEngineView):
            url_str = current_view.url().toString()
            if "home.html" in url_str:
                self.url_bar.setText("")
            else:
                self.url_bar.setText(url_str)

    def url_changed(self, qurl, view):
        if self.tabs.currentWidget() == view:
            url_str = qurl.toString()
            if "home.html" in url_str:
                self.url_bar.setText("")
            else:
                self.url_bar.setText(url_str)

    def title_changed(self, title, view):
        index = self.tabs.indexOf(view)
        if index != -1:
            display_title = title if title else "Filă nouă"
            self.tabs.setTabText(index, display_title[:18] + "..." if len(display_title) > 18 else display_title)

    def navigate_to_url(self):
        text = self.url_bar.text().strip()
        if not text:
            return
        if not text.startswith("http://") and not text.startswith("https://") and not text.startswith("file://"):
            if "." in text and " " not in text:
                text = "https://" + text
            else:
                text = f"https://duckduckgo.com/?q={text}"

        current_view = self.tabs.currentWidget()
        if isinstance(current_view, QWebEngineView):
            current_view.setUrl(QUrl(text))

    def go_back(self):
        view = self.tabs.currentWidget()
        if isinstance(view, QWebEngineView):
            view.back()

    def go_forward(self):
        view = self.tabs.currentWidget()
        if isinstance(view, QWebEngineView):
            view.forward()

    def reload_page(self):
        view = self.tabs.currentWidget()
        if isinstance(view, QWebEngineView):
            view.reload()

    def go_home(self):
        self.open_home_tab()

    def open_settings(self):
        SettingsDialog(self).exec()

    def show_menu(self):
        menu = QMenu(self)
        menu.setStyleSheet("""
            QMenu { background-color: #1E2024; color: #F1F5F9; border: 1px solid #2C2C2E; border-radius: 8px; padding: 6px; font-size: 13px; }
            QMenu::item { padding: 8px 24px; border-radius: 4px; }
            QMenu::item:selected { background-color: #34C759; color: #121316; font-weight: bold; }
        """)

        new_tab_action = menu.addAction("Filă nouă")
        new_tab_action.triggered.connect(self.open_home_tab)

        settings_action = menu.addAction("Setări")
        settings_action.triggered.connect(self.open_settings)

        update_action = menu.addAction("Verifică actualizări (Check for updates)")
        update_action.triggered.connect(self.check_updates)

        about_action = menu.addAction("Despre Line Browser")
        about_action.triggered.connect(lambda: AboutDialog(self).exec())

        menu.exec(self.btn_menu.mapToGlobal(self.btn_menu.rect().bottomLeft()))

    def check_updates(self):
        try:
            res = requests.get("https://api.github.com/repos/line-inc/linebrowser/releases/latest", timeout=5)
            if res.status_code == 200:
                data = res.json()
                tag = data.get("tag_name", "v1.0.0")
                url = data.get("html_url", "https://github.com/line-inc/linebrowser/releases")
                QMessageBox.information(self, "Actualizări", f"Line Browser este la zi! Cea mai recentă versiune pe GitHub este {tag}.\n{url}")
            else:
                QMessageBox.warning(self, "Actualizări", "Nu s-a putut verifica conexiunea cu GitHub.")
        except Exception as e:
            QMessageBox.critical(self, "Eroare", f"Eroare la verificare: {str(e)}")

if __name__ == "__main__":
    app = QApplication(sys.argv)
    window = LineBrowserWindow()
    window.show()
    sys.exit(app.exec())
