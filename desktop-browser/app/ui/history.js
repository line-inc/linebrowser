const list = document.getElementById("list");

function escapeHtml(value) {
  return String(value)
    .replaceAll("&", "&amp;")
    .replaceAll("<", "&lt;")
    .replaceAll(">", "&gt;");
}

browser.history.search({ text: "", maxResults: 200, startTime: 0 }).then((items) => {
  if (!items.length) {
    list.innerHTML = '<p class="muted">No history yet.</p>';
    return;
  }
  for (const item of items) {
    const row = document.createElement("div");
    row.className = "row";
    row.innerHTML = `<div><strong>${escapeHtml(item.title || item.url)}</strong><br><small>${escapeHtml(item.url)}</small></div>`;
    row.addEventListener("click", () => { location.href = item.url; });
    list.appendChild(row);
  }
});
