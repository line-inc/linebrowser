const EXTENSIONS = {
  shield: "line-shield@linebrowser.app",
  dark: "line-force-dark@linebrowser.app",
  ai: "line-ai-blocker@linebrowser.app",
  copy: "line-universal-copy@linebrowser.app",
  grabber: "line-media-grabber@linebrowser.app"
};

const CURRENT_VERSION = browser.runtime.getManifest().version;
const RELEASE_API = "https://api.github.com/repos/line-inc/linebrowser/releases/latest";

document.getElementById("app-version").textContent = CURRENT_VERSION;

async function setEnabled(id, enabled) {
  try {
    if (enabled) {
      await browser.management.setEnabled(id, true);
    } else {
      await browser.management.setEnabled(id, false);
    }
  } catch (error) {
    console.warn("Could not toggle", id, error);
  }
}

async function syncToggles() {
  for (const [key, id] of Object.entries(EXTENSIONS)) {
    const el = document.getElementById(key);
    try {
      const info = await browser.management.get(id);
      el.checked = info.enabled;
    } catch {
      el.disabled = true;
    }
    el.addEventListener("change", () => setEnabled(id, el.checked));
  }
}

document.getElementById("wipe").addEventListener("click", async () => {
  if (!confirm("Clear history, cookies, cache and local site data?")) return;
  await browser.browsingData.remove({ since: 0 }, {
    cache: true,
    cookies: true,
    history: true,
    localStorage: true,
    downloads: true
  });
  alert("Data burned.");
});

function parseVersion(release) {
  const candidates = [release.tag_name, release.name];
  for (const candidate of candidates) {
    if (typeof candidate !== "string") continue;
    const match = candidate.match(/(\d+)\.(\d+)\.(\d+)/);
    if (match) return match.slice(1).map(Number);
  }
  return null;
}

function compareVersions(left, right) {
  for (let index = 0; index < 3; index += 1) {
    if (left[index] !== right[index]) return left[index] - right[index];
  }
  return 0;
}

const updateButton = document.getElementById("check-updates");
const updateStatus = document.getElementById("update-status");

updateButton.addEventListener("click", async () => {
  updateButton.disabled = true;
  updateStatus.textContent = "Checking the official LineBrowser GitHub release…";

  try {
    const response = await fetch(RELEASE_API, {
      headers: { Accept: "application/vnd.github+json" }
    });
    if (!response.ok) {
      throw new Error(`GitHub returned HTTP ${response.status}`);
    }

    const release = await response.json();
    const latestVersion = parseVersion(release);
    if (!latestVersion) {
      throw new Error("The latest release does not contain a readable semantic version.");
    }

    const currentVersion = CURRENT_VERSION.split(".").map(Number);
    if (compareVersions(latestVersion, currentVersion) <= 0) {
      updateStatus.textContent = `LineBrowser ${CURRENT_VERSION} is up to date.`;
      return;
    }

    const windowsAsset = (release.assets || []).find((asset) =>
      /windows|win64|win-x64|x64|desktop/i.test(asset.name) &&
      /\.(exe|msi|zip)$/i.test(asset.name)
    );
    if (!windowsAsset) {
      updateStatus.textContent =
        `LineBrowser ${latestVersion.join(".")} is available, but this release has no Windows installer. ` +
        "The Android APK cannot update this Windows desktop browser.";
      const releaseLink = document.createElement("a");
      releaseLink.className = "repo-link";
      releaseLink.href = release.html_url;
      releaseLink.target = "_blank";
      releaseLink.rel = "noopener noreferrer";
      releaseLink.textContent = "View the GitHub release";
      updateStatus.append(" ", releaseLink);
      return;
    }

    updateStatus.textContent =
      `LineBrowser ${latestVersion.join(".")} is available for Windows. Open the release to install it.`;
    const downloadLink = document.createElement("a");
    downloadLink.className = "repo-link";
    downloadLink.href = windowsAsset.browser_download_url;
    downloadLink.target = "_blank";
    downloadLink.rel = "noopener noreferrer";
    downloadLink.textContent = `Download ${windowsAsset.name}`;
    updateStatus.append(" ", downloadLink);
  } catch (error) {
    updateStatus.textContent = `Could not check for updates: ${error.message}`;
  } finally {
    updateButton.disabled = false;
  }
});

syncToggles();
