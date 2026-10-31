const list = document.getElementById("list");

function addRow(node) {
  if (node.url) {
    const row = document.createElement("div");
    row.className = "row";
    row.innerHTML = `<div><strong>${escapeHtml(node.title || node.url)}</strong><br><small>${escapeHtml(node.url)}</small></div>`;
    row.addEventListener("click", () => { location.href = node.url; });
    list.appendChild(row);
  }
  (node.children || []).forEach(addRow);
}

function escapeHtml(value) {
  return String(value)
    .replaceAll("&", "&amp;")
    .replaceAll("<", "&lt;")
    .replaceAll(">", "&gt;");
}

browser.bookmarks.getTree().then((tree) => {
  tree.forEach(addRow);
  if (!list.children.length) {
    list.innerHTML = '<p class="muted">No bookmarks yet.</p>';
  }
});
