// background.js — property photo slideshow, Sheet-synced
(function Background() {
  'use strict';

  const bgA = document.getElementById('bg-a');
  const bgB = document.getElementById('bg-b');

  let photos  = [...CONFIG.FALLBACK_PHOTOS];
  let idx     = 0;
  let current = 'a';
  let cycleId = null;

  // ── Preload an image then apply it ──────────────────────────────────────
  function preload(url) {
    return new Promise(resolve => {
      const img   = new Image();
      img.onload  = () => resolve(url);
      img.onerror = () => resolve(null);
      img.src     = url;
    });
  }

  async function crossfade(url) {
    const next = current === 'a' ? bgB : bgA;
    const prev = current === 'a' ? bgA : bgB;
    const ok   = await preload(url);
    if (!ok) return;                         // skip broken images silently
    next.style.backgroundImage = `url("${url}")`;
    next.classList.add('active');
    prev.classList.remove('active');
    current = current === 'a' ? 'b' : 'a';
  }

  function advance() {
    idx = (idx + 1) % (photos.length || 1);
    if (photos[idx]) crossfade(photos[idx]);
  }

  function startCycle() {
    if (cycleId) clearInterval(cycleId);
    cycleId = setInterval(advance, CONFIG.TIMING.bg_crossfade);
  }

  // ── Sheet sync ───────────────────────────────────────────────────────────
  async function syncSheet() {
    const rows = await sheetFetch(CONFIG.GIDS.backgrounds);
    if (!rows) return;

    const urls = rows
      .filter(r => {
        // Active column standard: blank = active; FALSE / 0 / NO = inactive
        const a = (r['active'] || r['Active'] || '').toString().trim().toUpperCase();
        return !(a === 'FALSE' || a === '0' || a === 'NO');
      })
      .map(r => r['url'] || r['URL'] || r['link'] || '')
      .filter(u => u.startsWith('http'));

    if (urls.length > 0) {
      photos = urls;
      Store.set('wf_photos', photos);
    }
  }

  // ── Boot ─────────────────────────────────────────────────────────────────
  const cached = Store.get('wf_photos');
  if (cached?.length) photos = cached;

  // Show first photo immediately
  if (photos[0]) crossfade(photos[0]);
  startCycle();
  syncSheet();
  setInterval(syncSheet, CONFIG.TIMING.sheet_refresh);

  // ── Expose ────────────────────────────────────────────────────────────────
  window.BG = { startCycle, stop: () => clearInterval(cycleId) };
})();
