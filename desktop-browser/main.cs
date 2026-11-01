using System;
using System.Diagnostics;
using System.Windows.Forms;
using System.IO;

namespace LineBrowser
{
    static class Program
    {
        [STAThread]
        static void Main()
        {
            string url = "https://lineinc.ro";
            string[] browsers = {
                @"C:\Program Files\Microsoft\Edge\Application\msedge.exe",
                @"C:\Program Files (x86)\Microsoft\Edge\Application\msedge.exe",
                @"C:\Program Files\Google\Chrome\Application\chrome.exe",
                @"C:\Program Files (x86)\Google\Chrome\Application\chrome.exe"
            };

            string browserPath = "";
            foreach (var b in browsers)
            {
                if (File.Exists(b))
                {
                    browserPath = b;
                    break;
                }
            }

            if (string.IsNullOrEmpty(browserPath))
            {
                try {
                    Process.Start(new ProcessStartInfo(url) { UseShellExecute = true });
                } catch {
                    MessageBox.Show("Nu s-a putut găsi Google Chrome sau Microsoft Edge pe acest calculator.", "Line Browser Error", MessageBoxButtons.OK, MessageBoxIcon.Error);
                }
            }
            else
            {
                try {
                    Process.Start(browserPath, $"--app=\"{url}\" --window-size=1300,850");
                } catch {
                    Process.Start(new ProcessStartInfo(url) { UseShellExecute = true });
                }
            }
        }
    }
}
