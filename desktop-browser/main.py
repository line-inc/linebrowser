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

class ChromeBrowserWindow(QMainWindow):
    def __init__(self):
        super().__init__()
        self.setWindowTitle("Line Browser")
        self.resize(1350, 850)

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

        # 1. Chrome-style Toolbar (Top)
        toolbar_widget = QWidget()
        toolbar_widget.setStyleSheet("background-color: #323639; border-bottom: 1px solid #1e1f22;")
        toolbar_layout = QHBoxLayout(toolbar_widget)
        toolbar_layout.setContentsMargins(10, 8, 10, 8)
        toolbar_layout.setSpacing(6)

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

        self.btn_extensions = QPushButton("🧩")
        self.btn_extensions.setToolTip("Extensii")
        self.btn_extensions.clicked.connect(lambda: QMessageBox.information(self, "Extensii", "Magazinul de extensii Line Browser este activ."))

        self.btn_menu = QPushButton("⋮")
        self.btn_menu.setToolTip("Meniu Google Chrome")
        self.btn_menu.clicked.connect(self.show_menu)

        toolbar_layout.addWidget(self.btn_back)
        toolbar_layout.addWidget(self.btn_forward)
        toolbar_layout.addWidget(self.btn_reload)
        toolbar_layout.addWidget(self.btn_home)
        toolbar_layout.addWidget(self.url_bar)
        toolbar_layout.addWidget(self.btn_extensions)
        toolbar_layout.addWidget(self.btn_menu)

        main_layout.addWidget(toolbar_widget)

        # 2. Chrome-style Tabs (Below Toolbar)
        self.tabs = QTabWidget()
        self.tabs.setTabsClosable(True)
        self.tabs.tabCloseRequested.connect(self.close_tab)
        self.tabs.currentChanged.connect(self.tab_changed)

        main_layout.addWidget(self.tabs)

        # Add initial tab
        self.add_new_tab("https://www.google.com", "Google")

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
        self.add_new_tab("https://www.google.com", "Google")

    def show_menu(self):
        menu = QMenu(self)
        menu.setStyleSheet("""
            QMenu { background-color: #292a2d; color: #f1f3f4; border: 1px solid #5f6368; border-radius: 8px; padding: 6px; font-size: 13px; }
            QMenu::item { padding: 8px 32px; border-radius: 4px; }
            QMenu::item:selected { background-color: #8ab4f8; color: #202124; font-weight: bold; }
        """)

        new_tab_action = menu.addAction("Filă nouă (Ctrl+T)")
        new_tab_action.triggered.connect(lambda: self.add_new_tab("https://www.google.com", "Google"))

        history_action = menu.addAction("Istoric (Ctrl+H)")
        history_action.triggered.connect(lambda: QMessageBox.information(self, "Istoric", "Istoricul de navigare."))

        downloads_action = menu.addAction("Descărcări (Ctrl+J)")
        downloads_action.triggered.connect(lambda: QMessageBox.information(self, "Descărcări", "Managerul de descărcări."))

        settings_action = menu.addAction("Setări")
        settings_action.triggered.connect(lambda: QMessageBox.information(self, "Setări", "Setările Line Browser (Chromium Core).\nCopyright © 2026 Line Inc."))

        about_action = menu.addAction("Despre Google Chrome / Line Browser")
        about_action.triggered.connect(lambda: QMessageBox.information(self, "Despre", "Line Browser v1.0.0 (Powered by Chromium / QtWebEngine)\nCopyright © 2026 Line Inc."))

        menu.exec(self.btn_menu.mapToGlobal(self.btn_menu.rect().bottomLeft()))

if __name__ == "__main__":
    app = QApplication(sys.argv)
    window = ChromeBrowserWindow()
    window.show()
    sys.exit(app.exec_())
