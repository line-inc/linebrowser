(function() {
    function rebrand() {
        const walker = document.createTreeWalker(document.body || document.documentElement, NodeFilter.SHOW_TEXT, null, false);
        let node;
        while (node = walker.nextNode()) {
            if (node.nodeValue) {
                let v = node.nodeValue;
                if (v.includes('Firefox') || v.includes('Mozilla') || v.includes('About Firefox')) {
                    node.nodeValue = v
                        .replace(/About Firefox/g, 'Despre Line Browser')
                        .replace(/Firefox/g, 'Line Browser')
                        .replace(/Mozilla/g, 'Line Inc.')
                        .replace(/More from Mozilla/g, 'Line Inc. Community')
                        .replace(/Firefox Labs/g, 'Line Labs')
                        .replace(/Firefox support/g, 'Line Support');
                }
            }
        }

        // Hide unwanted sidebar items in about:preferences
        const unWantedSelectors = [
            '#category-firefox-labs',
            '#category-more-from-mozilla',
            '#category-support',
            'div[data-category="firefox-labs"]',
            'div[data-category="more-from-mozilla"]'
        ];
        unWantedSelectors.forEach(sel => {
            document.querySelectorAll(sel).forEach(el => el.style.display = 'none');
        });

        // Replace shortcut tiles on about:newtab containing Firefox
        document.querySelectorAll('.top-site-outer, .tile').forEach(tile => {
            const titleEl = tile.querySelector('.title');
            if (titleEl && titleEl.textContent.includes('Firefox')) {
                titleEl.textContent = 'Line Extensions';
            }
        });

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
