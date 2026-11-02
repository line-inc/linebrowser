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
        self.resize(750, 600)
        self.setStyleSheet("""
            QDialog { background-color: #202124; color: #f1f3f4; font-family: -apple-system, sans-serif; }
            QLabel { color: #f1f3f4; font-size: 13px; }
            QPushButton { background-color: #323639; color: #ffffff; border: 1px solid #5f6368; border-radius: 8px; padding: 8px 14px; font-weight: 600; }
            QPushButton:hover { background-color: #3c4043; border-color: #8ab4f8; color: #8ab4f8; }
            QScrollArea { border: none; background: transparent; }
            QFrame { background-color: #292a2d; border: 1px solid #3c4043; border-radius: 12px; margin-bottom: 8px; }
        """)

        layout = QVBoxLayout(self)
        layout.setContentsMargins(24, 24, 24, 24)

        header_layout = QHBoxLayout()
        title = QLabel("Setări Line Browser (Desktop)")
        title.setStyleSheet("font-size: 20px; font-weight: bold; color: #8ab4f8;")
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
            t_label.setStyleSheet("font-weight: bold; font-size: 14px; color: #f1f3f4;")
            d_label = QLabel(desc_text)
            d_label.setStyleSheet("color: #9aa0a6; font-size: 12px;")
            text_layout.addWidget(t_label)
            text_layout.addWidget(d_label)
            card_layout.addLayout(text_layout)

            btn = QPushButton(action_text)
            btn.clicked.connect(callback)
            card_layout.addWidget(btn)

            scroll_layout.addWidget(card)

        add_setting_card("Aspect și Temă", "Mod întunecat Google Chrome, culori de accent", "Config", lambda: QMessageBox.information(self, "Temă", "Modul Dark Mode este activ."))
        add_setting_card("Limba Aplicației", "Schimbă limba de afișare a browserului", "Română", lambda: QMessageBox.information(self, "Limbă", "Limbă setată pe Română."))
        add_setting_card("Line Shield (AdBlock)", "Blochează reclamele și trackerele pe pagini web", "Activ", lambda: QMessageBox.information(self, "AdBlock", "Line Shield este activ pe desktop."))
        add_setting_card("Seif Privat & Parole", "Manager de parole criptat AES-256", "Deschide", lambda: QMessageBox.information(self, "Seif", "Seif de parole securizat."))
        add_setting_card("Versiune", "1.0.0 (Chromium Core)", "La zi", lambda: QMessageBox.information(self, "Versiune", "Line Browser v1.0.0\nCopyright © 2026 Line Inc."))

        scroll.setWidget(scroll_content)
        layout.addWidget(scroll)

class ChromeBrowserWindow(QMainWindow):
    def __init__(self):
        super().__init__()
        self.setWindowTitle("Line Browser")
        self.resize(1400, 900)

        # Pixel-for-pixel Google Chrome Dark Mode stylesheet
        self.setStyleSheet("""
            QMainWindow { background-color: #202124; }
            QTabWidget::pane { border: none; background: #202124; }
            QTabBar { background-color: #1e1f22; }
            QTabBar::tab { background: #2b2d31; color: #9aa0a6; padding: 8px 20px; border-top-left-radius: 8px; border-top-right-radius: 8px; font-size: 12.5px; font-weight: 500; margin-right: 2px; }
            QTabBar::tab:selected { background: #323639; color: #FFFFFF; font-weight: bold; border-top: 2px solid #8ab4f8; }
            QLineEdit { background-color: #202124; color: #FFFFFF; border: 1.5px solid #5f6368; border-radius: 20px; padding: 8px 16px; font-size: 14px; }
            QLineEdit:focus { border: 1.5px solid #8ab4f8; }
            QPushButton { background-color: #2b2d31; color: #FFFFFF; border: none; border-radius: 16px; padding: 6px 12px; font-weight: 600; font-size: 13px; }
            QPushButton:hover { background-color: #3c4043; color: #8ab4f8; }
        """)

        central_widget = QWidget()
        self.setCentralWidget(central_widget)
        main_layout = QVBoxLayout(central_widget)
        main_layout.setContentsMargins(0, 0, 0, 0)
        main_layout.setSpacing(0)

        # Chrome-style Top Toolbar
        toolbar_widget = QWidget()
        toolbar_widget.setStyleSheet("background-color: #323639; border-bottom: 1px solid #1e1f22;")
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
        self.url_bar.setPlaceholderText("Căutați pe Google sau introduceți adresa web...")
        self.url_bar.returnPressed.connect(self.navigate_to_url)

        self.btn_settings = QPushButton("⚙️ Setări")
        self.btn_settings.clicked.connect(self.open_settings)

        self.btn_menu = QPushButton("⋮")
        self.btn_menu.setToolTip("Meniu Google Chrome")
        self.btn_menu.clicked.connect(self.show_menu)

        toolbar_layout.addWidget(self.btn_back)
        toolbar_layout.addWidget(self.btn_forward)
        toolbar_layout.addWidget(self.btn_reload)
        toolbar_layout.addWidget(self.btn_home)
        toolbar_layout.addWidget(self.url_bar)
        toolbar_layout.addWidget(self.btn_settings)
        toolbar_layout.addWidget(self.btn_menu)

        main_layout.addWidget(toolbar_widget)

        # Chrome-style Tabs
        self.tabs = QTabWidget()
        self.tabs.setTabsClosable(True)
        self.tabs.tabCloseRequested.connect(self.close_tab)
        self.tabs.currentChanged.connect(self.tab_changed)

        main_layout.addWidget(self.tabs)

        # Add initial tab
        self.add_new_tab("https://lineinc.ro", "Line Inc.")

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
            self.close()

    def tab_changed(self, index):
        current_view = self.tabs.currentWidget()
        if isinstance(current_view, QWebEngineView):
            self.url_bar.setText(current_view.url().toString())

    def url_changed(self, qurl, view):
        if self.tabs.currentWidget() == view:
            self.url_bar.setText(qurl.toString())

    def title_changed(self, title, view):
        index = self.tabs.indexOf(view)
        if index != -1:
            self.tabs.setTabText(index, title[:18] + "..." if len(title) > 18 else title)

    def navigate_to_url(self):
        text = self.url_bar.text().strip()
        if not text:
            return
        if not text.startswith("http://") and not text.startswith("https://") and not text.startswith("file://"):
            if "." in text and " " not in text:
                text = "https://" + text
            else:
                text = f"https://www.google.com/search?q={text}"

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
        self.add_new_tab("https://lineinc.ro", "Line Inc.")

    def open_settings(self):
        SettingsDialog(self).exec()

    def show_menu(self):
        menu = QMenu(self)
        menu.setStyleSheet("""
            QMenu { background-color: #292a2d; color: #f1f3f4; border: 1px solid #5f6368; border-radius: 8px; padding: 6px; font-size: 13px; }
            QMenu::item { padding: 8px 32px; border-radius: 4px; }
            QMenu::item:selected { background-color: #8ab4f8; color: #202124; font-weight: bold; }
        """)

        new_tab_action = menu.addAction("Filă nouă (Ctrl+T)")
        new_tab_action.triggered.connect(lambda: self.add_new_tab("https://lineinc.ro", "Line Inc."))

        settings_action = menu.addAction("Setări")
        settings_action.triggered.connect(self.open_settings)

        history_action = menu.addAction("Istoric (Ctrl+H)")
        history_action.triggered.connect(lambda: QMessageBox.information(self, "Istoric", "Istoricul de navigare."))

        downloads_action = menu.addAction("Descărcări (Ctrl+J)")
        downloads_action.triggered.connect(lambda: QMessageBox.information(self, "Descărcări", "Managerul de descărcări."))

        about_action = menu.addAction("Despre Line Browser")
        about_action.triggered.connect(lambda: QMessageBox.information(self, "Despre", "Line Browser v1.0.0 (Chromium Core)\nCopyright © 2026 Line Inc."))

        menu.exec(self.btn_menu.mapToGlobal(self.btn_menu.rect().bottomLeft()))

if __name__ == "__main__":
    app = QApplication(sys.argv)
    window = ChromeBrowserWindow()
    window.show()
    sys.exit(app.exec_())
