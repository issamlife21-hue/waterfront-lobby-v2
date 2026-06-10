// directory.js — per-building directory, Sheet-synced
(function Directory() {
  'use strict';

  const listEl   = document.getElementById('dir-list');
  const labelEl  = document.getElementById('dir-building-name');
  const phoneEl  = document.getElementById('dir-phone');

  let currentBuilding = Store.get('wf_building', CONFIG.DEFAULTS.building);

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
        <span class="dir-tenant">${e.tenant}</span>
        <span class="dir-suite">${e.suite}</span>
      </div>`).join('');
  }

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
