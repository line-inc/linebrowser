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
            this.Width = 1280;
            this.Height = 800;

            webBrowser = new WebBrowser();
            webBrowser.Dock = DockStyle.Fill;
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
