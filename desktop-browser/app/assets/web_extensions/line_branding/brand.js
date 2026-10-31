(function() {
    function rebrand() {
        const walker = document.createTreeWalker(document.body || document.documentElement, NodeFilter.SHOW_TEXT, null, false);
        let node;
        while (node = walker.nextNode()) {
            if (node.nodeValue && (node.nodeValue.includes('Firefox') || node.nodeValue.includes('Mozilla'))) {
                node.nodeValue = node.nodeValue
                    .replace(/Firefox/g, 'Line Browser')
                    .replace(/Mozilla/g, 'Line Inc.')
                    .replace(/About Firefox/g, 'Despre Line Browser');
            }
        }
        if (document.title) {
            document.title = document.title.replace(/Firefox/g, 'Line Browser').replace(/Mozilla/g, 'Line Inc.');
        }
    }
    if (document.readyState === 'loading') {
        document.addEventListener('DOMContentLoaded', rebrand);
    } else {
        rebrand();
    }
    const observer = new MutationObserver(rebrand);
    observer.observe(document, { childList: true, subtree: true });
})();
