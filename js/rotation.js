// rotation.js — panel auto-rotation, nav dot highlighting, watchdog
(function Rotation() {
  'use strict';

  const ALL_PANELS = ['weather', 'directory', 'events', 'property'];
  let sequence     = [];
  let idx          = 0;
  let rotateTimer  = null;
  let watchdogTimer= null;
  let lastChange   = Date.now();

  // ── Build sequence based on enabled panels ──────────────────────────────
  function buildSequence() {
    return ALL_PANELS.filter(p => {
      if (p === 'events'   && window.AppSettings && !AppSettings.isEventsShown())  return false;
      if (p === 'property' && window.AppSettings && !AppSettings.isPropShown())    return false;
      return true;
    });
  }

  // ── Activate a panel ────────────────────────────────────────────────────
  function activate(name) {
    document.querySelectorAll('.panel').forEach(el => {
      el.classList.toggle('active', el.id === `panel-${name}`);
    });
    document.querySelectorAll('.nav-dot').forEach(dot => {
      dot.classList.toggle('active', dot.dataset.panel === name);
    });
    lastChange = Date.now();
  }

  // ── Advance ──────────────────────────────────────────────────────────────
  function advance() {
    sequence = buildSequence();
    if (!sequence.length) return;
    idx = (idx + 1) % sequence.length;
    activate(sequence[idx]);
    scheduleNext();
  }

  function scheduleNext() {
    clearTimeout(rotateTimer);
    clearTimeout(watchdogTimer);
    const name = sequence[idx] || 'weather';
    const dur  = CONFIG.TIMING[`panel_${name}`] || 13000;
    rotateTimer   = setTimeout(advance, dur);
    watchdogTimer = setTimeout(advance, dur + 6000);  // safety net
  }

  // ── Manual nav dot clicks ────────────────────────────────────────────────
  document.querySelectorAll('.nav-dot').forEach(dot => {
    dot.addEventListener('click', () => {
      const name = dot.dataset.panel;
      const i    = sequence.indexOf(name);
      if (i !== -1) { idx = i; activate(name); scheduleNext(); }
    });
  });

  // ── Watchdog: detect stuck rotation ─────────────────────────────────────
  setInterval(() => {
    const elapsed = Date.now() - lastChange;
    const name    = sequence[idx] || 'weather';
    const maxDur  = (CONFIG.TIMING[`panel_${name}`] || 13000) * 2 + 8000;
    if (elapsed > maxDur) {
      console.warn('[watchdog] rotation stuck — forcing advance');
      advance();
    }
  }, 10000);

  // ── Boot ─────────────────────────────────────────────────────────────────
  sequence = buildSequence();
  activate(sequence[0] || 'weather');
  scheduleNext();

  // ── Expose ───────────────────────────────────────────────────────────────
  window.Rotation = { activate, advance };
})();
