import sys
import os
import json
import requests
from PyQt5.QtCore import QUrl, Qt
from PyQt5.QtGui import QIcon, QAction
from PyQt5.QtWidgets import (
    QApplication, QMainWindow, QWidget, QVBoxLayout, QHBoxLayout,
    QLineEdit, QPushButton, QTabWidget, QMessageBox, QDialog, QLabel,
    QMenu
)
from PyQt5.QtWebEngineWidgets import QWebEngineView

class AboutDialog(QDialog):
    def __init__(self, parent=None):
        super().__init__(parent)
        self.setWindowTitle("Despre Line Browser")
        self.setFixedSize(400, 250)
        self.setStyleSheet("background-color: #121316; color: white; font-family: sans-serif;")

        layout = QVBoxLayout()

        title = QLabel("Line Browser")
        title.setStyleSheet("font-size: 22px; font-weight: bold; color: #34C759;")
        title.setAlignment(Qt.AlignmentFlag.AlignCenter)

        version = QLabel("Versiune 1.0.0")
        version.setStyleSheet("font-size: 14px; color: #94A3B8;")
        version.setAlignment(Qt.AlignmentFlag.AlignCenter)

        desc = QLabel("Un browser web modern, rapid și axat pe confidențialitate.")
        desc.setStyleSheet("font-size: 12px; color: #CBD5E1;")
        desc.setAlignment(Qt.AlignmentFlag.AlignCenter)
        desc.setWordWrap(True)

        copyright = QLabel("Copyright © 2026 Line Inc. Toate drepturile rezervate.")
        copyright.setStyleSheet("font-size: 11px; color: #64748B;")
        copyright.setAlignment(Qt.AlignmentFlag.AlignCenter)

        btn = QPushButton("Închide")
        btn.setStyleSheet("background-color: #34C759; color: black; font-weight: bold; border-radius: 6px; padding: 8px;")
        btn.clicked.connect(self.accept)

        layout.addWidget(title)
        layout.addWidget(version)
        layout.addWidget(desc)
        layout.addWidget(copyright)
        layout.addWidget(btn)
        self.setLayout(layout)

class LineBrowserWindow(QMainWindow):
    def __init__(self):
        super().__init__()
        self.setWindowTitle("Line Browser")
        self.resize(1200, 800)

        # Apply dark theme stylesheet
        self.setStyleSheet("""
            QMainWindow { background-color: #121316; }
            QTabWidget::pane { border: 1px solid #2C2C2E; background: #121316; }
            QTabBar::tab { background: #1E2024; color: #A0A0A5; padding: 8px 16px; border-top-left-radius: 6px; border-top-right-radius: 6px; }
            QTabBar::tab:selected { background: #2C2C2E; color: #FFFFFF; font-weight: bold; }
            QLineEdit { background-color: #2C2C2E; color: #FFFFFF; border: 1px solid #3A3A3C; border-radius: 18px; padding: 6px 14px; font-size: 13px; }
            QPushButton { background-color: #2C2C2E; color: #FFFFFF; border: none; border-radius: 4px; padding: 6px 12px; }
            QPushButton:hover { background-color: #3A3A3C; }
        """)

        central_widget = QWidget()
        self.setCentralWidget(central_widget)
        main_layout = QVBoxLayout(central_widget)
        main_layout.setContentsMargins(0, 0, 0, 0)

        # Toolbar layout
        toolbar_layout = QHBoxLayout()
        toolbar_layout.setContentsMargins(8, 8, 8, 8)

        self.btn_back = QPushButton("◀")
        self.btn_back.clicked.connect(self.go_back)
        self.btn_forward = QPushButton("▶")
        self.btn_forward.clicked.connect(self.go_forward)
        self.btn_reload = QPushButton("🔄")
        self.btn_reload.clicked.connect(self.reload_page)
        self.btn_home = QPushButton("🏠")
        self.btn_home.clicked.connect(self.go_home)

        self.url_bar = QLineEdit()
        self.url_bar.returnPressed.connect(self.navigate_to_url)

        self.btn_menu = QPushButton("⋮ Meniu")
        self.btn_menu.clicked.connect(self.show_menu)

        toolbar_layout.addWidget(self.btn_back)
        toolbar_layout.addWidget(self.btn_forward)
        toolbar_layout.addWidget(self.btn_reload)
        toolbar_layout.addWidget(self.btn_home)
        toolbar_layout.addWidget(self.url_bar)
        toolbar_layout.addWidget(self.btn_menu)

        main_layout.addLayout(toolbar_layout)

        # Tabs widget
        self.tabs = QTabWidget()
        self.tabs.setTabsClosable(True)
        self.tabs.tabCloseRequested.connect(self.close_tab)
        self.tabs.currentChanged.connect(self.tab_changed)

        main_layout.addWidget(self.tabs)

        # Open initial tab
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
            self.tabs.setTabText(index, title[:15] + "..." if len(title) > 15 else title)

    def navigate_to_url(self):
        text = self.url_bar.text().strip()
        if not text.startswith("http://") and not text.startswith("https://"):
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
        self.add_new_tab("https://lineinc.ro", "Line Inc.")

    def show_menu(self):
        menu = QMenu(self)
        menu.setStyleSheet("background-color: #1E2024; color: white; selection-background-color: #34C759; padding: 6px;")

        new_tab_action = menu.addAction("Filă nouă")
        new_tab_action.triggered.connect(lambda: self.add_new_tab("https://lineinc.ro", "Line Inc."))

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
                QMessageBox.information(self, "Actualizări", f"Linia este la zi! Cea mai recentă versiune pe GitHub este {tag}.\n{url}")
            else:
                QMessageBox.warning(self, "Actualizări", "Nu s-a putut verifica conexiunea cu GitHub.")
        except Exception as e:
            QMessageBox.critical(self, "Eroare", f"Eroare la verificare: {str(e)}")

if __name__ == "__main__":
    app = QApplication(sys.argv)
    window = LineBrowserWindow()
    window.show()
    sys.exit(app.exec())
