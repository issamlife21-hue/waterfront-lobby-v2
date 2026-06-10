// rotation.js — panel auto-rotation, nav dot highlighting, per-cycle watchdog
(function Rotation() {
  'use strict';

  const ALL_PANELS = ['weather', 'directory', 'events', 'property'];
  let sequence     = [];
  let idx          = 0;
  let rotateTimer  = null;
  let watchdogTimer= null;

  // ── Build sequence based on enabled panels ──────────────────────────────
  function buildSequence() {
    return ALL_PANELS.filter(p => {
      if (p === 'events'   && window.AppSettings && !AppSettings.isEventsShown()) return false;
      if (p === 'property' && window.AppSettings && !AppSettings.isPropShown())   return false;
      return true;
    });
  }

  // ── Activate a panel ────────────────────────────────────────────────────
  function activate(name) {
    const directional = !!(window.AppSettings &&
                           typeof AppSettings.getTransition === 'function' &&
                           AppSettings.getTransition() === 'directional');

    document.querySelectorAll('.panel').forEach(el => {
      const isTarget = el.id === `panel-${name}`;
      if (isTarget) {
        el.classList.remove('panel-leave');
        el.classList.add('active');
      } else if (el.classList.contains('active')) {
        el.classList.remove('active');
        if (directional) {
          // outgoing panel slides out to the left, then resets
          el.classList.add('panel-leave');
          setTimeout(() => el.classList.remove('panel-leave'), 400);
        }
      } else {
        el.classList.remove('panel-leave');
      }
    });

    document.querySelectorAll('.nav-dot').forEach(dot => {
      dot.classList.toggle('active', dot.dataset.panel === name);
    });
  }

  // ── Advance ──────────────────────────────────────────────────────────────
  function advance() {
    sequence = buildSequence();
    if (!sequence.length) return;
    idx = (idx + 1) % sequence.length;
    activate(sequence[idx]);
    scheduleNext();
  }

  // Per-cycle timers: rotateTimer fires the normal advance; watchdogTimer is a
  // single safety net that forces an advance if the rotate timer ever stalls.
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

  // ── Boot ─────────────────────────────────────────────────────────────────
  sequence = buildSequence();
  activate(sequence[0] || 'weather');
  scheduleNext();

  // ── Expose ───────────────────────────────────────────────────────────────
  window.Rotation = { activate, advance };
})();
