// directory.js — per-building directory, Sheet-synced
(function Directory() {
  'use strict';

  const listEl   = document.getElementById('dir-list');
  const labelEl  = document.getElementById('dir-building-name');
  const phoneEl  = document.getElementById('dir-phone');
  const qrEl     = document.getElementById('dir-qr');

  let currentBuilding = Store.get('wf_building', CONFIG.DEFAULTS.building);

  // ── Escape Sheet-sourced values before inserting into innerHTML ───────────
  function esc(str) {
    const d = document.createElement('div');
    d.textContent = str == null ? '' : str;
    return d.innerHTML;
  }

  // GID map
  const GID_MAP = {
    '310': CONFIG.GIDS.directory_310,
    '320': CONFIG.GIDS.directory_320,
    '330': CONFIG.GIDS.directory_330,
    '340': CONFIG.GIDS.directory_340,
  };

  // ── Render ────────────────────────────────────────────────────────────────
  function render(entries) {
    if (!listEl) return;
    if (!entries?.length) {
      listEl.innerHTML = '<div class="dir-empty">No directory entries found.</div>';
      return;
    }
    listEl.innerHTML = entries.map(e => `
      <div class="dir-row" role="listitem">
        <span class="dir-tenant">${esc(e.tenant)}</span>
        <span class="dir-suite">${esc(e.suite)}</span>
      </div>`).join('');
  }

  // ── Leasing QR (static placeholder pattern, accent-tinted) ────────────────
  function renderQR() {
    if (!qrEl) return;
    const N = 21;
    let rects = '';
    const finder = (ox, oy) => {
      let s = '';
      for (let y = 0; y < 7; y++) for (let x = 0; x < 7; x++) {
        const ring   = (x === 0 || x === 6 || y === 0 || y === 6);
        const center = (x >= 2 && x <= 4 && y >= 2 && y <= 4);
        if (ring || center) s += `<rect x="${ox + x}" y="${oy + y}" width="1" height="1"/>`;
      }
      return s;
    };
    const inFinder = (x, y) => (x < 8 && y < 8) || (x > 12 && y < 8) || (x < 8 && y > 12);
    rects += finder(0, 0) + finder(14, 0) + finder(0, 14);
    for (let y = 0; y < N; y++) for (let x = 0; x < N; x++) {
      if (inFinder(x, y)) continue;
      if (((x * 3 + y * 7 + x * y) % 5) === 0) rects += `<rect x="${x}" y="${y}" width="1" height="1"/>`;
    }
    qrEl.innerHTML =
      `<svg viewBox="0 0 21 21" fill="currentColor" aria-hidden="true" shape-rendering="crispEdges">${rects}</svg>` +
      `<span class="dir-qr-label">Scan to contact leasing</span>`;
  }
  renderQR();

  // ── Load for a building ───────────────────────────────────────────────────
  async function load(building) {
    currentBuilding = building;

    // Update label
    if (labelEl) labelEl.textContent = CONFIG.BUILDINGS[building] || `${building} Golden Shore`;

    // Update phone from stored info
    const phone = Store.get('wf_info_phone', CONFIG.PROPERTY.phone);
    if (phoneEl) phoneEl.textContent = phone;

    // Try cache first for instant display
    const cached = Store.get(`wf_dir_${building}`);
    if (cached?.length) render(cached);

    // Fetch from Sheet
    const gid  = GID_MAP[building];
    if (!gid) { render(CONFIG.FALLBACK_DIRECTORY[building] || []); return; }

    const rows = await sheetFetch(gid);
    if (!rows?.length) {
      // Use fallback if no cache
      if (!cached?.length) render(CONFIG.FALLBACK_DIRECTORY[building] || []);
      return;
    }

    // Flexible column name matching
    const entries = rows.map(r => ({
      tenant: r['tenant'] || r['name'] || r['company'] || r['tenant name'] || '',
      suite:  r['suite']  || r['floor'] || r['unit']  || r['suite number'] || r['suite/floor'] || '',
    })).filter(e => e.tenant);

    render(entries);
    Store.set(`wf_dir_${building}`, entries);
  }

  // ── Public API ─────────────────────────────────────────────────────────────
  window.Directory = {
    load,
    setBuilding: b => load(b),
    refresh:     () => load(currentBuilding),
  };

  // ── Boot ──────────────────────────────────────────────────────────────────
  load(currentBuilding);
  setInterval(() => load(currentBuilding), CONFIG.TIMING.sheet_refresh);
})();
