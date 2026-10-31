const blockedHosts = new Set();

async function loadSeed() {
  const url = browser.runtime.getURL("adblock_seed.txt");
  const text = await (await fetch(url)).text();
  for (const raw of text.split(/\r?\n/)) {
    const line = raw.trim();
    if (!line || line.startsWith("#")) continue;
    blockedHosts.add(line.toLowerCase());
  }
}

function hostBlocked(hostname) {
  const host = (hostname || "").toLowerCase();
  if (blockedHosts.has(host)) return true;
  for (const entry of blockedHosts) {
    if (host === entry || host.endsWith("." + entry)) return true;
  }
  return false;
}

loadSeed().then(() => {
  browser.webRequest.onBeforeRequest.addListener(
    (details) => {
      try {
        const host = new URL(details.url).hostname;
        if (hostBlocked(host)) return { cancel: true };
      } catch {
        return {};
      }
      return {};
    },
    { urls: ["<all_urls>"] },
    ["blocking"]
  );
});
