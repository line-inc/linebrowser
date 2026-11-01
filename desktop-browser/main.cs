using System;
using System.Windows.Forms;

namespace LineBrowser
{
    public class BrowserForm : Form
    {
        private WebBrowser webBrowser;

        public BrowserForm()
        {
            this.Text = "Line Browser (Chromium Core)";
            this.Width = 1300;
            this.Height = 850;

            webBrowser = new WebBrowser();
            webBrowser.Dock = DockStyle.Fill;
            webBrowser.ScriptErrorsSuppressed = true; // Supress legacy JS compatibility popups
            webBrowser.Url = new Uri("https://lineinc.ro");

            this.Controls.Add(webBrowser);
        }

        [STAThread]
        public static void Main()
        {
            Application.EnableVisualStyles();
            Application.SetCompatibleTextRenderingDefault(false);
            Application.Run(new BrowserForm());
        }
    }
}
