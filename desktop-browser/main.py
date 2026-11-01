import sys
import os
from PyQt5.QtCore import QUrl, Qt
from PyQt5.QtWidgets import QApplication, QMainWindow, QVBoxLayout, QWidget, QLineEdit, QHBoxLayout, QPushButton
from PyQt5.QtWebEngineWidgets import QWebEngineView

class MainWindow(QMainWindow):
    def __init__(self):
        super().__init__()
        self.setWindowTitle("Line Browser")
        self.resize(1350, 850)

        central = QWidget()
        self.setCentralWidget(central)
        layout = QVBoxLayout(central)
        layout.setContentsMargins(0, 0, 0, 0)
        layout.setSpacing(0)

        # Toolbar
        toolbar = QWidget()
        toolbar.setStyleSheet("background-color: #141416; padding: 8px;")
        t_layout = QHBoxLayout(toolbar)

        self.url_bar = QLineEdit()
        self.url_bar.setText("https://lineinc.ro")
        self.url_bar.setStyleSheet("background-color: #1E2024; color: white; border-radius: 16px; padding: 6px 14px; font-size: 14px; border: 1px solid #2C2C2E;")
        self.url_bar.returnPressed.connect(self.load_url)

        t_layout.addWidget(self.url_bar)
        layout.addWidget(toolbar)

        # Web View (Real Chromium Engine)
        self.browser = QWebEngineView()
        self.browser.setUrl(QUrl("https://lineinc.ro"))
        layout.addWidget(self.browser)

    def load_url(self):
        url = self.url_bar.text().strip()
        if not url.startswith("http://") and not url.startswith("https://"):
            url = "https://" + url
        self.browser.setUrl(QUrl(url))

if __name__ == "__main__":
    app = QApplication(sys.argv)
    window = MainWindow()
    window.show()
    sys.exit(app.exec_())
