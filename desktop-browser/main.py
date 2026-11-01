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

class LineBrowserWindow(QMainWindow):
    def __init__(self):
        super().__init__()
        self.setWindowTitle("Line Browser")
        self.resize(1350, 850)

        # Clean Chrome-like Dark Theme
        self.setStyleSheet("""
            QMainWindow { background-color: #121316; }
            QTabWidget::pane { border: none; background: #121316; }
            QTabBar::tab { background: #1E2024; color: #94A3B8; padding: 8px 18px; border-top-left-radius: 6px; border-top-right-radius: 6px; font-size: 13px; font-weight: 500; }
            QTabBar::tab:selected { background: #121316; color: #FFFFFF; font-weight: bold; border-top: 2px solid #34C759; }
            QLineEdit { background-color: #202124; color: #FFFFFF; border: 1.5px solid #3C4043; border-radius: 20px; padding: 8px 16px; font-size: 14px; }
            QLineEdit:focus { border: 1.5px solid #34C759; }
            QPushButton { background-color: #202124; color: #FFFFFF; border: none; border-radius: 6px; padding: 8px 12px; font-weight: 600; }
            QPushButton:hover { background-color: #323639; color: #34C759; }
        """)

        central_widget = QWidget()
        self.setCentralWidget(central_widget)
        main_layout = QVBoxLayout(central_widget)
        main_layout.setContentsMargins(0, 0, 0, 0)
        main_layout.setSpacing(0)

        # Chrome-style Toolbar
        toolbar_widget = QWidget()
        toolbar_widget.setStyleSheet("background-color: #1e1f22; border-bottom: 1px solid #2c2d30;")
        toolbar_layout = QHBoxLayout(toolbar_widget)
        toolbar_layout.setContentsMargins(10, 8, 10, 8)
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
        self.url_bar.setPlaceholderText("Căutați pe Google sau introduceți o adresă web...")
        self.url_bar.returnPressed.connect(self.navigate_to_url)

        self.btn_menu = QPushButton("⋮")
        self.btn_menu.clicked.connect(self.show_menu)

        toolbar_layout.addWidget(self.btn_back)
        toolbar_layout.addWidget(self.btn_forward)
        toolbar_layout.addWidget(self.btn_reload)
        toolbar_layout.addWidget(self.btn_home)
        toolbar_layout.addWidget(self.url_bar)
        toolbar_layout.addWidget(self.btn_menu)

        main_layout.addWidget(toolbar_widget)

        # Chrome-style Tabs
        self.tabs = QTabWidget()
        self.tabs.setTabsClosable(True)
        self.tabs.tabCloseRequested.connect(self.close_tab)
        self.tabs.currentChanged.connect(self.tab_changed)

        main_layout.addWidget(self.tabs)

        self.go_home()

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
            self.go_home()
            self.tabs.removeTab(0)

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
            QMenu::item { padding: 8px 28px; border-radius: 4px; }
            QMenu::item:selected { background-color: #34c759; color: #121316; font-weight: bold; }
        """)

        new_tab_action = menu.addAction("Filă nouă (Ctrl+T)")
        new_tab_action.triggered.connect(lambda: self.go_home())

        history_action = menu.addAction("Istoric")
        history_action.triggered.connect(lambda: QMessageBox.information(self, "Istoric", "Istoricul de navigare este gol."))

        downloads_action = menu.addAction("Descărcări (Ctrl+J)")
        downloads_action.triggered.connect(lambda: QMessageBox.information(self, "Descărcări", "Nicio descărcare activă."))

        about_action = menu.addAction("Despre Line Browser")
        about_action.triggered.connect(lambda: QMessageBox.information(self, "Despre", "Line Browser v1.0.0 (Chromium Core)\nCopyright © 2026 Line Inc."))

        menu.exec(self.btn_menu.mapToGlobal(self.btn_menu.rect().bottomLeft()))

if __name__ == "__main__":
    app = QApplication(sys.argv)
    window = LineBrowserWindow()
    window.show()
    sys.exit(app.exec())
