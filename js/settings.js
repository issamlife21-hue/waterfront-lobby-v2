// settings.js — PIN, 6 themes, building, schedule, sliders, transitions, building info
// Live-preview model: every change applies immediately; Save commits to localStorage;
// Close / click-outside reverts to the last saved snapshot.
(function Settings() {
  'use strict';

  const THEMES = ['obsidian','stone','navy','ivory','slate','midnight'];

  // ── State (live / draft values) ───────────────────────────────────────────
  let pin         = Store.get('wf_pin',          CONFIG.DEFAULTS.pin);
  let building    = Store.get('wf_building',     CONFIG.DEFAULTS.building);
  let theme       = Store.get('wf_theme',        CONFIG.DEFAULTS.theme);
  let themeMode   = Store.get('wf_theme_mode',   CONFIG.DEFAULTS.theme_mode);
  let dayTheme    = Store.get('wf_day_theme',    'ivory');
  let nightTheme  = Store.get('wf_night_theme',  'obsidian');
  let showEvents  = Store.get('wf_show_events',  CONFIG.DEFAULTS.show_events);
  let showProp    = Store.get('wf_show_property',CONFIG.DEFAULTS.show_property);
  let photoDim    = Store.get('wf_photo_dim',    55);   // 0–100
  let cardOpacity = Store.get('wf_card_opacity', 88);   // 0–100
  let transition  = Store.get('wf_transition',   'simple');  // simple | directional

  // Building info
  let infoLogoName = Store.get('wf_info_logo_name', CONFIG.PROPERTY.name);
  let infoLogoSub  = Store.get('wf_info_logo_sub',  CONFIG.PROPERTY.subtitle);
  let infoPhone    = Store.get('wf_info_phone',     CONFIG.PROPERTY.phone);
  let infoEmail    = Store.get('wf_info_email',     CONFIG.PROPERTY.email);
  let infoAddr     = Store.get('wf_info_addr',      CONFIG.PROPERTY.address);

  let pinBuffer = '';
  let unlocked  = false;
  let savedState = null;   // snapshot of committed values, captured on open / save

  // ── DOM ───────────────────────────────────────────────────────────────────
  const overlay     = document.getElementById('settings-overlay');
  const trigger     = document.getElementById('settings-trigger');
  const closeBtn    = document.getElementById('settings-close');
  const backdrop    = document.getElementById('settings-backdrop');
  const pinGate     = document.getElementById('pin-gate');
  const pinDots     = document.querySelectorAll('.pin-dot');
  const pinErr      = document.getElementById('pin-err');
  const sBody       = document.getElementById('settings-body');
  const sleepScreen = document.getElementById('sleep-screen');

  // Form refs
  const sBldg       = document.getElementById('s-building');
  const sThemeMode  = document.getElementById('s-theme-mode');
  const sSchedule   = document.getElementById('schedule-section');
  const sDayTheme   = document.getElementById('s-day-theme');
  const sNightTheme = document.getElementById('s-night-theme');
  const sTransition = document.getElementById('s-transition');
  const sShowEv     = document.getElementById('s-show-events');
  const sShowPr     = document.getElementById('s-show-property');
  const sNewPin     = document.getElementById('s-new-pin');
  const sSavePin    = document.getElementById('s-save-pin-btn');
  const sSave       = document.getElementById('s-save');
  const sReset      = document.getElementById('s-reset');

  // Sliders
  const sDimSlider  = document.getElementById('s-dim-slider');
  const sDimVal     = document.getElementById('s-dim-val');
  const sCardSlider = document.getElementById('s-card-slider');
  const sCardVal    = document.getElementById('s-card-val');

  // Building info
  const iLogoName = document.getElementById('info-logo-name');
  const iLogoSub  = document.getElementById('info-logo-sub');
  const iPhone    = document.getElementById('info-phone');
  const iEmail    = document.getElementById('info-email');
  const iAddr     = document.getElementById('info-addr');

  // ── Snapshot / restore for live-preview-with-revert ───────────────────────
  function snapshot() {
    return {
      building, theme, themeMode, dayTheme, nightTheme, showEvents, showProp,
      photoDim, cardOpacity, transition,
      infoLogoName, infoLogoSub, infoPhone, infoEmail, infoAddr,
    };
  }
  function restore(s) {
    if (!s) return;
    ({
      building, theme, themeMode, dayTheme, nightTheme, showEvents, showProp,
      photoDim, cardOpacity, transition,
      infoLogoName, infoLogoSub, infoPhone, infoEmail, infoAddr,
    } = s);
  }

  // ── Apply CSS vars for sliders (cards + scrim) ────────────────────────────
  function applyCSSVars() {
    document.documentElement.style.setProperty('--photo-dim', (photoDim / 100).toFixed(2));
    const cardVal = (cardOpacity / 100).toFixed(2);
    // Read the active theme's RGB and rebuild --bg-card so cards always match the live theme
    const rgb = getComputedStyle(document.documentElement).getPropertyValue('--bg-card-rgb').trim();
    if (rgb) {
      document.documentElement.style.setProperty('--bg-card', `rgba(${rgb},${cardVal})`);
    }
  }

  // ── Apply theme ───────────────────────────────────────────────────────────
  function applyTheme(t) {
    if (!THEMES.includes(t)) t = 'obsidian';
    document.documentElement.setAttribute('data-theme', t);
    applyCSSVars();   // re-derive card color for the new theme's RGB
  }

  // Auto theme schedule reads the Sheet-managed START/SLEEP times (no on-screen fields)
  function resolveAutoTheme() {
    const now  = new Date();
    const hm   = now.getHours() * 60 + now.getMinutes();
    const [wh, wm] = (Store.get('wf_sheet_wake',  '07:00') || '07:00').split(':').map(Number);
    const [sh, sm] = (Store.get('wf_sheet_sleep', '20:00') || '20:00').split(':').map(Number);
    const wakeM  = wh * 60 + wm;
    const sleepM = sh * 60 + sm;
    const isDay  = hm >= wakeM && hm < sleepM;
    return isDay ? (dayTheme || 'ivory') : (nightTheme || 'obsidian');
  }

  function applyCurrentTheme() {
    applyTheme(themeMode === 'auto' ? resolveAutoTheme() : theme);
  }

  // ── Apply transition style ────────────────────────────────────────────────
  function applyTransition() {
    document.documentElement.setAttribute('data-transition', transition);
  }

  // ── Apply building ─────────────────────────────────────────────────────────
  function applyBuilding(b) {
    document.documentElement.setAttribute('data-building', b);
    if (window.Directory) Directory.setBuilding(b);
  }

  // ── Apply panel visibility ─────────────────────────────────────────────────
  function applyPanelVisibility() {
    const evDot = document.querySelector('.nav-dot[data-panel="events"]');
    const prDot = document.querySelector('.nav-dot[data-panel="property"]');
    if (evDot) evDot.style.display = showEvents ? '' : 'none';
    if (prDot) prDot.style.display = showProp   ? '' : 'none';
  }

  // ── Apply building info ────────────────────────────────────────────────────
  function applyBuildingInfo() {
    const n = document.getElementById('logo-name');
    const s = document.getElementById('logo-sub');
    const p = document.getElementById('prop-name');
    const a = document.getElementById('prop-addr');
    const d = document.getElementById('dir-phone');
    const e = document.getElementById('events-email');
    if (n) n.textContent = infoLogoName;
    if (s) s.textContent = infoLogoSub;
    if (p) p.textContent = `${infoLogoName} ${infoLogoSub}`.trim();
    if (a) a.textContent = infoAddr;
    if (d) d.textContent = infoPhone;
    if (e) e.textContent = infoEmail;
  }

  // ── Apply everything (used on boot, save, and revert) ─────────────────────
  function applyAll() {
    applyCurrentTheme();
    applyBuilding(building);
    applyPanelVisibility();
    applyBuildingInfo();
    applyCSSVars();
    applyTransition();
  }

  applyCurrentTheme();
  applyTransition();
  setInterval(applyCurrentTheme, 60000);

  // ── Open / close ──────────────────────────────────────────────────────────
  function openSettings() {
    savedState = snapshot();          // remember committed state for revert
    overlay.classList.remove('hidden');
    pinBuffer = ''; unlocked = false;
    updateDots();
    pinGate.classList.remove('hidden');
    sBody.classList.add('hidden');
    pinErr.classList.add('hidden');
  }

  // Close == revert to last saved state (discard unsaved live preview)
  function closeSettings() {
    restore(savedState);
    applyAll();
    overlay.classList.add('hidden');
    unlocked = false; pinBuffer = '';
  }

  function populateForm() {
    if (sBldg)       sBldg.value       = building;
    if (sThemeMode)  sThemeMode.value  = themeMode;
    if (sDayTheme)   sDayTheme.value   = dayTheme;
    if (sNightTheme) sNightTheme.value = nightTheme;
    if (sTransition) sTransition.value = transition;
    if (sShowEv)     sShowEv.checked   = showEvents;
    if (sShowPr)     sShowPr.checked   = showProp;
    if (iLogoName)   iLogoName.value   = infoLogoName;
    if (iLogoSub)    iLogoSub.value    = infoLogoSub;
    if (iPhone)      iPhone.value      = infoPhone;
    if (iEmail)      iEmail.value      = infoEmail;
    if (iAddr)       iAddr.value       = infoAddr;

    // Sliders
    if (sDimSlider)  { sDimSlider.value  = photoDim;    if (sDimVal)  sDimVal.textContent  = `${photoDim}%`;    }
    if (sCardSlider) { sCardSlider.value = cardOpacity; if (sCardVal) sCardVal.textContent = `${cardOpacity}%`; }

    // Theme swatches
    document.querySelectorAll('.theme-swatch').forEach(sw => {
      sw.classList.toggle('active', sw.dataset.theme === theme);
    });

    if (sSchedule) sSchedule.style.display = themeMode === 'auto' ? '' : 'none';
  }

  // ── PIN ───────────────────────────────────────────────────────────────────
  function updateDots() {
    pinDots.forEach((d, i) => d.classList.toggle('on', i < pinBuffer.length));
  }

  function checkPin() {
    if (pinBuffer === pin) {
      unlocked = true;
      pinGate.classList.add('hidden');
      sBody.classList.remove('hidden');
      pinErr.classList.add('hidden');
      populateForm();
    } else {
      pinErr.classList.remove('hidden');
      pinBuffer = ''; updateDots();
    }
  }

  document.querySelectorAll('.pin-key').forEach(key => {
    key.addEventListener('click', () => {
      const d = key.dataset.d;
      const a = key.dataset.a;
      if (d !== undefined && pinBuffer.length < 4) {
        pinBuffer += d; updateDots();
        if (pinBuffer.length === 4) checkPin();
      }
      if (a === 'clear') { pinBuffer = pinBuffer.slice(0, -1); updateDots(); pinErr.classList.add('hidden'); }
      if (a === 'enter') checkPin();
    });
  });

  // ── Theme swatches (live preview) ─────────────────────────────────────────
  document.querySelectorAll('.theme-swatch').forEach(sw => {
    sw.addEventListener('click', () => {
      document.querySelectorAll('.theme-swatch').forEach(s => s.classList.remove('active'));
      sw.classList.add('active');
      theme = sw.dataset.theme;
      if (themeMode === 'manual') applyTheme(theme);
    });
  });

  // ── Live preview wiring for the rest of the controls ──────────────────────
  if (sThemeMode) {
    sThemeMode.addEventListener('change', () => {
      themeMode = sThemeMode.value;
      if (sSchedule) sSchedule.style.display = themeMode === 'auto' ? '' : 'none';
      applyCurrentTheme();
    });
  }
  if (sDayTheme)   sDayTheme.addEventListener('change',  () => { dayTheme   = sDayTheme.value;   applyCurrentTheme(); });
  if (sNightTheme) sNightTheme.addEventListener('change',() => { nightTheme = sNightTheme.value; applyCurrentTheme(); });
  if (sTransition) sTransition.addEventListener('change',() => { transition = sTransition.value; applyTransition(); });
  if (sBldg)       sBldg.addEventListener('change',      () => { building   = sBldg.value;       applyBuilding(building); });
  if (sShowEv)     sShowEv.addEventListener('change',    () => { showEvents = sShowEv.checked;   applyPanelVisibility(); });
  if (sShowPr)     sShowPr.addEventListener('change',    () => { showProp   = sShowPr.checked;   applyPanelVisibility(); });

  if (iLogoName) iLogoName.addEventListener('input', () => { infoLogoName = iLogoName.value; applyBuildingInfo(); });
  if (iLogoSub)  iLogoSub.addEventListener('input',  () => { infoLogoSub  = iLogoSub.value;  applyBuildingInfo(); });
  if (iPhone)    iPhone.addEventListener('input',    () => { infoPhone    = iPhone.value;    applyBuildingInfo(); });
  if (iEmail)    iEmail.addEventListener('input',    () => { infoEmail    = iEmail.value;    applyBuildingInfo(); });
  if (iAddr)     iAddr.addEventListener('input',     () => { infoAddr     = iAddr.value;     applyBuildingInfo(); });

  // ── Live sliders (display updates in real time while dragging) ────────────
  if (sDimSlider) {
    sDimSlider.addEventListener('input', () => {
      photoDim = parseInt(sDimSlider.value, 10);
      if (sDimVal) sDimVal.textContent = `${photoDim}%`;
      applyCSSVars();
    });
  }
  if (sCardSlider) {
    sCardSlider.addEventListener('input', () => {
      cardOpacity = parseInt(sCardSlider.value, 10);
      if (sCardVal) sCardVal.textContent = `${cardOpacity}%`;
      applyCSSVars();
    });
  }

  // ── Save PIN ──────────────────────────────────────────────────────────────
  if (sSavePin) {
    sSavePin.addEventListener('click', () => {
      const np = (sNewPin?.value || '').trim();
      if (/^\d{4}$/.test(np)) {
        pin = np; Store.set('wf_pin', pin);
        if (sNewPin) sNewPin.value = '';
        sSavePin.textContent = 'Saved ✓';
        setTimeout(() => { sSavePin.textContent = 'Save'; }, 2000);
      } else {
        if (sNewPin) { sNewPin.style.outline = '1px solid #e05252'; setTimeout(() => { sNewPin.style.outline = ''; }, 1500); }
      }
    });
  }

  // ── Save all (commit live values to localStorage) ─────────────────────────
  if (sSave) {
    sSave.addEventListener('click', () => {
      if (!unlocked) return;

      Store.set('wf_building',      building);
      Store.set('wf_theme',         theme);
      Store.set('wf_theme_mode',    themeMode);
      Store.set('wf_day_theme',     dayTheme);
      Store.set('wf_night_theme',   nightTheme);
      Store.set('wf_transition',    transition);
      Store.set('wf_show_events',   showEvents);
      Store.set('wf_show_property', showProp);
      Store.set('wf_photo_dim',     photoDim);
      Store.set('wf_card_opacity',  cardOpacity);
      Store.set('wf_info_logo_name',infoLogoName);
      Store.set('wf_info_logo_sub', infoLogoSub);
      Store.set('wf_info_phone',    infoPhone);
      Store.set('wf_info_email',    infoEmail);
      Store.set('wf_info_addr',     infoAddr);

      savedState = snapshot();   // committed state is now the live state
      applyAll();
      overlay.classList.add('hidden');
      unlocked = false; pinBuffer = '';
    });
  }

  // ── Reset ─────────────────────────────────────────────────────────────────
  if (sReset) {
    sReset.addEventListener('click', () => {
      if (!confirm('Reset all display settings to defaults?')) return;
      localStorage.clear(); location.reload();
    });
  }

  // ── Open / close bindings ─────────────────────────────────────────────────
  if (trigger)  trigger.addEventListener('click', openSettings);
  if (closeBtn) closeBtn.addEventListener('click', closeSettings);
  if (backdrop) backdrop.addEventListener('click', closeSettings);

  // ── Sleep screen tap to wake (delegates to main.js manual-wake) ───────────
  if (sleepScreen) {
    sleepScreen.addEventListener('click', () => {
      if (window.Lifecycle && typeof Lifecycle.manualWake === 'function') {
        Lifecycle.manualWake();
      } else {
        sleepScreen.classList.add('hidden');
      }
    });
  }

  // ── Cursor hiding ─────────────────────────────────────────────────────────
  let cursorTimer;
  document.addEventListener('mousemove', () => {
    document.body.style.cursor = 'default';
    clearTimeout(cursorTimer);
    cursorTimer = setTimeout(() => { document.body.style.cursor = 'none'; }, 3000);
  });

  // ── Boot: apply all ───────────────────────────────────────────────────────
  applyAll();

  window.AppSettings = {
    getBuilding:    () => building,
    isEventsShown:  () => showEvents,
    isPropShown:    () => showProp,
    getTheme:       () => theme,
    getTransition:  () => transition,
  };
})();
