let tabCounter = 1;
let activeTabId = 1;

function addNewTab(url = null) {
    tabCounter++;
    const newId = tabCounter;

    // Tab bar element
    const tabBar = document.getElementById('tab-bar');
    const newTabEl = document.createElement('div');
    newTabEl.className = 'tab';
    newTabEl.setAttribute('data-tab-id', newId);
    newTabEl.innerHTML = `<span class="tab-title">Filă Nouă</span><span class="close-tab" onclick="closeTab(event, ${newId})">×</span>`;
    newTabEl.onclick = () => switchTab(newId);

    // Insert before new tab button
    tabBar.insertBefore(newTabEl, document.getElementById('new-tab-btn'));

    // Content view element
    const contentArea = document.getElementById('content-area');
    const newViewEl = document.createElement('div');
    newViewEl.className = 'browser-view';
    newViewEl.setAttribute('data-view-id', newId);

    if (url) {
        const iframe = document.createElement('iframe');
        iframe.src = url;
        newViewEl.appendChild(iframe);
    } else {
        // New tab page template
        newViewEl.innerHTML = `
            <div class="new-tab-page">
                <div class="home-logo"><div></div></div>
                <div class="home-title">Line Browser</div>
                <div class="home-subtitle">Zero Trackers · Fully On-Device · Hyper-Fast</div>
                <div class="home-search">
                    <input type="text" placeholder="Caută sau introdu adresa web..." onkeydown="handleTabSearch(event, ${newId})" />
                </div>
                <div class="home-widgets">
                    <a href="https://lineinc.ro" class="widget-card" onclick="loadUrlInTab(event, ${newId}, 'https://lineinc.ro')">
                        <strong>Line Inc. Website</strong>
                        <span>Oficial</span>
                    </a>
                    <a href="#" class="widget-card" onclick="openSettingsModal(); return false;">
                        <strong>Line Shield (AdBlock)</strong>
                        <span>Protecție activă</span>
                    </a>
                    <a href="#" class="widget-card" onclick="openSettingsModal(); return false;">
                        <strong>Seif Privat & Parole</strong>
                        <span>Criptat AES-256</span>
                    </a>
                </div>
            </div>
        `;
    }
    contentArea.appendChild(newViewEl);
    switchTab(newId);
}

function switchTab(tabId) {
    activeTabId = tabId;
    document.querySelectorAll('.tab').forEach(t => {
        if (t.getAttribute('data-tab-id') == tabId) t.classList.add('active');
        else t.classList.remove('active');
    });
    document.querySelectorAll('.browser-view').forEach(v => {
        if (v.getAttribute('data-view-id') == tabId) {
            v.classList.add('active');
            const iframe = v.querySelector('iframe');
            if (iframe) document.getElementById('url-bar').value = iframe.src;
            else document.getElementById('url-bar').value = '';
        } else {
            v.classList.remove('active');
        }
    });
}

function closeTab(event, tabId) {
    event.stopPropagation();
    const tabEl = document.querySelector(`.tab[data-tab-id="${tabId}"]`);
    const viewEl = document.querySelector(`.browser-view[data-view-id="${tabId}"]`);

    if (document.querySelectorAll('.tab').length > 1) {
        if (tabEl) tabEl.remove();
        if (viewEl) viewEl.remove();
        if (activeTabId == tabId) {
            const remaining = document.querySelectorAll('.tab');
            const lastId = remaining[remaining.length - 1].getAttribute('data-tab-id');
            switchTab(lastId);
        }
    }
}

function handleHomeSearch(e) {
    if (e.key === 'Enter') {
        let val = e.target.value.trim();
        if (val) loadUrlInActiveTabDirect(val);
    }
}

function handleTabSearch(e, tabId) {
    if (e.key === 'Enter') {
        let val = e.target.value.trim();
        if (val) loadUrlInTabDirect(tabId, val);
    }
}

function loadUrlInActiveTabDirect(val) {
    if (!val.startsWith('http://') && !val.startsWith('https://')) {
        if (val.includes('.') && !val.includes(' ')) val = 'https://' + val;
        else val = 'https://duckduckgo.com/?q=' + encodeURIComponent(val);
    }
    document.getElementById('url-bar').value = val;

    const viewEl = document.querySelector(`.browser-view[data-view-id="${activeTabId}"]`);
    viewEl.innerHTML = `<iframe src="${val}"></iframe>`;

    const tabEl = document.querySelector(`.tab[data-tab-id="${activeTabId}"] .tab-title`);
    if (tabEl) tabEl.textContent = val.replace('https://', '').replace('http://', '').split('/')[0];
}

function loadUrlInTabDirect(tabId, val) {
    if (!val.startsWith('http://') && !val.startsWith('https://')) {
        if (val.includes('.') && !val.includes(' ')) val = 'https://' + val;
        else val = 'https://duckduckgo.com/?q=' + encodeURIComponent(val);
    }
    const viewEl = document.querySelector(`.browser-view[data-view-id="${tabId}"]`);
    viewEl.innerHTML = `<iframe src="${val}"></iframe>`;

    const tabEl = document.querySelector(`.tab[data-tab-id="${tabId}"] .tab-title`);
    if (tabEl) tabEl.textContent = val.replace('https://', '').replace('http://', '').split('/')[0];
    switchTab(tabId);
}

function loadUrlInTab(e, tabId, url) {
    e.preventDefault();
    loadUrlInTabDirect(tabId, url);
}

function handleUrlKey(e) {
    if (e.key === 'Enter') {
        let val = e.target.value.trim();
        if (val) loadUrlInActiveTabDirect(val);
    }
}

function goBack() {
    const view = document.querySelector(`.browser-view[data-view-id="${activeTabId}"] iframe`);
    if (view && view.contentWindow) {
        try { view.contentWindow.history.back(); } catch(err) {}
    }
}

function goForward() {
    const view = document.querySelector(`.browser-view[data-view-id="${activeTabId}"] iframe`);
    if (view && view.contentWindow) {
        try { view.contentWindow.history.forward(); } catch(err) {}
    }
}

function reloadPage() {
    const view = document.querySelector(`.browser-view[data-view-id="${activeTabId}"] iframe`);
    if (view) {
        view.src = view.src;
    }
}

function goHome() {
    const viewEl = document.querySelector(`.browser-view[data-view-id="${activeTabId}"]`);
    viewEl.innerHTML = `
        <div class="new-tab-page">
            <div class="home-logo"><div></div></div>
            <div class="home-title">Line Browser</div>
            <div class="home-subtitle">Zero Trackers · Fully On-Device · Hyper-Fast</div>
            <div class="home-search">
                <input type="text" placeholder="Caută sau introdu adresa web..." onkeydown="handleTabSearch(event, ${activeTabId})" />
            </div>
            <div class="home-widgets">
                <a href="https://lineinc.ro" class="widget-card" onclick="loadUrlInTab(event, ${activeTabId}, 'https://lineinc.ro')">
                    <strong>Line Inc. Website</strong>
                    <span>Oficial</span>
                </a>
                <a href="#" class="widget-card" onclick="openSettingsModal(); return false;">
                    <strong>Line Shield (AdBlock)</strong>
                    <span>Protecție activă</span>
                </a>
                <a href="#" class="widget-card" onclick="openSettingsModal(); return false;">
                    <strong>Seif Privat & Parole</strong>
                    <span>Criptat AES-256</span>
                </a>
            </div>
        </div>
    `;
    document.getElementById('url-bar').value = '';
    const tabEl = document.querySelector(`.tab[data-tab-id="${activeTabId}"] .tab-title`);
    if (tabEl) tabEl.textContent = 'Filă Nouă';
}

function openSettingsModal() {
    document.getElementById('settings-modal').classList.add('open');
}

function closeSettingsModal() {
    document.getElementById('settings-modal').classList.remove('open');
}

function openMenu() {
    openSettingsModal();
}
