function toUrl(value) {
  const q = value.trim();
  if (!q) return null;
  if (/^[a-zA-Z][a-zA-Z0-9+.-]*:/.test(q)) return q;
  if (/^[^\s]+\.[^\s]{2,}/.test(q) && !q.includes(" ")) {
    return "https://" + q;
  }
  return "https://duckduckgo.com/?q=" + encodeURIComponent(q);
}

document.getElementById("search-form").addEventListener("submit", (event) => {
  event.preventDefault();
  const url = toUrl(document.getElementById("q").value);
  if (url) location.href = url;
});

document.getElementById("downloads").addEventListener("click", (event) => {
  event.preventDefault();
  browser.tabs.create({ url: "about:downloads" });
});

document.getElementById("private").addEventListener("click", (event) => {
  event.preventDefault();
  browser.windows.create({ incognito: true });
});
