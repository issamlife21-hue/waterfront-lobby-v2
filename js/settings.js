// settings.js — PIN, 6 themes, building, schedule, sliders, building info
(function Settings() {
  'use strict';

  const THEMES = ['obsidian','stone','navy','ivory','slate','midnight'];

  // ── State ─────────────────────────────────────────────────────────────────
  let pin        = Store.get('wf_pin',          CONFIG.DEFAULTS.pin);
  let building   = Store.get('wf_building',     CONFIG.DEFAULTS.building);
  let theme      = Store.get('wf_theme',        CONFIG.DEFAULTS.theme);
  let themeMode  = Store.get('wf_theme_mode',   CONFIG.DEFAULTS.theme_mode);
  let dayTheme   = Store.get('wf_day_theme',    'ivory');
  let nightTheme = Store.get('wf_night_theme',  'obsidian');
  let wakeTime   = Store.get('wf_wake',         '07:00');
  let sleepTime  = Store.get('wf_sleep',        '20:00');
  let showEvents = Store.get('wf_show_events',  CONFIG.DEFAULTS.show_events);
  let showProp   = Store.get('wf_show_property',CONFIG.DEFAULTS.show_property);
  let photoDim   = Store.get('wf_photo_dim',    55);   // 0–100
  let cardOpacity= Store.get('wf_card_opacity', 88);   // 0–100

  // Building info
  let infoLogoName = Store.get('wf_info_logo_name', CONFIG.PROPERTY.name);
  let infoLogoSub  = Store.get('wf_info_logo_sub',  CONFIG.PROPERTY.subtitle);
  let infoPhone    = Store.get('wf_info_phone',      CONFIG.PROPERTY.phone);
  let infoEmail    = Store.get('wf_info_email',      CONFIG.PROPERTY.email);
  let infoAddr     = Store.get('wf_info_addr',       CONFIG.PROPERTY.address);

  let pinBuffer = '';
  let unlocked  = false;

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
  const sWake       = document.getElementById('s-wake');
  const sSleep      = document.getElementById('s-sleep');
  const sShowEv     = document.getElementById('s-show-events');
  const sShowPr     = document.getElementById('s-show-property');
  const sNewPin     = document.getElementById('s-new-pin');
  const sSavePin    = document.getElementById('s-save-pin-btn');
  const sSave       = document.getElementById('s-save');
  const sReset      = document.getElementById('s-reset');

  // Sliders
  const sDimSlider    = document.getElementById('s-dim-slider');
  const sDimVal       = document.getElementById('s-dim-val');
  const sCardSlider   = document.getElementById('s-card-slider');
  const sCardVal      = document.getElementById('s-card-val');

  // Building info
  const iLogoName = document.getElementById('info-logo-name');
  const iLogoSub  = document.getElementById('info-logo-sub');
  const iPhone    = document.getElementById('info-phone');
  const iEmail    = document.getElementById('info-email');
  const iAddr     = document.getElementById('info-addr');

  // ── Apply CSS vars for sliders ────────────────────────────────────────────
  function applyCSSVars() {
    document.documentElement.style.setProperty('--photo-dim',    (photoDim    / 100).toFixed(2));
    document.documentElement.style.setProperty('--card-opacity', (cardOpacity / 100).toFixed(2));
  }

  // ── Apply theme ───────────────────────────────────────────────────────────
  function applyTheme(t) {
    if (!THEMES.includes(t)) t = 'obsidian';
    document.documentElement.setAttribute('data-theme', t);
  }

  function resolveAutoTheme() {
    const now  = new Date();
    const hm   = now.getHours() * 60 + now.getMinutes();
    const [wh, wm] = (wakeTime  || '07:00').split(':').map(Number);
    const [sh, sm] = (sleepTime || '20:00').split(':').map(Number);
    const wakeM  = wh * 60 + wm;
    const sleepM = sh * 60 + sm;
    const isDay  = hm >= wakeM && hm < sleepM;
    return isDay ? (dayTheme || 'ivory') : (nightTheme || 'obsidian');
  }

  function applyCurrentTheme() {
    applyTheme(themeMode === 'auto' ? resolveAutoTheme() : theme);
  }

  applyCurrentTheme();
  setInterval(applyCurrentTheme, 60000);

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

  // ── Open / close ──────────────────────────────────────────────────────────
  function openSettings() {
    overlay.classList.remove('hidden');
    pinBuffer = ''; unlocked = false;
    updateDots();
    pinGate.classList.remove('hidden');
    sBody.classList.add('hidden');
    pinErr.classList.add('hidden');
  }

  function closeSettings() {
    overlay.classList.add('hidden');
    unlocked = false; pinBuffer = '';
  }

  function populateForm() {
    if (sBldg)       sBldg.value      = building;
    if (sThemeMode)  sThemeMode.value = themeMode;
    if (sDayTheme)   sDayTheme.value  = dayTheme;
    if (sNightTheme) sNightTheme.value= nightTheme;
    if (sWake)       sWake.value      = wakeTime;
    if (sSleep)      sSleep.value     = sleepTime;
    if (sShowEv)     sShowEv.checked  = showEvents;
    if (sShowPr)     sShowPr.checked  = showProp;
    if (iLogoName)   iLogoName.value  = infoLogoName;
    if (iLogoSub)    iLogoSub.value   = infoLogoSub;
    if (iPhone)      iPhone.value     = infoPhone;
    if (iEmail)      iEmail.value     = infoEmail;
    if (iAddr)       iAddr.value      = infoAddr;

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

  // ── Theme swatches ────────────────────────────────────────────────────────
  document.querySelectorAll('.theme-swatch').forEach(sw => {
    sw.addEventListener('click', () => {
      document.querySelectorAll('.theme-swatch').forEach(s => s.classList.remove('active'));
      sw.classList.add('active');
      theme = sw.dataset.theme;
      if (themeMode === 'manual') applyTheme(theme);
    });
  });

  if (sThemeMode) {
    sThemeMode.addEventListener('change', () => {
      if (sSchedule) sSchedule.style.display = sThemeMode.value === 'auto' ? '' : 'none';
    });
  }

  // ── Live sliders ──────────────────────────────────────────────────────────
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

  // ── Save all ──────────────────────────────────────────────────────────────
  if (sSave) {
    sSave.addEventListener('click', () => {
      if (!unlocked) return;

      building   = sBldg?.value        || building;
      themeMode  = sThemeMode?.value   || themeMode;
      dayTheme   = sDayTheme?.value    || dayTheme;
      nightTheme = sNightTheme?.value  || nightTheme;
      wakeTime   = sWake?.value        || wakeTime;
      sleepTime  = sSleep?.value       || sleepTime;
      showEvents = sShowEv?.checked    ?? showEvents;
      showProp   = sShowPr?.checked    ?? showProp;
      photoDim   = parseInt(sDimSlider?.value  || photoDim,    10);
      cardOpacity= parseInt(sCardSlider?.value || cardOpacity, 10);

      infoLogoName = iLogoName?.value  || infoLogoName;
      infoLogoSub  = iLogoSub?.value   || infoLogoSub;
      infoPhone    = iPhone?.value     || infoPhone;
      infoEmail    = iEmail?.value     || infoEmail;
      infoAddr     = iAddr?.value      || infoAddr;

      Store.set('wf_building',      building);
      Store.set('wf_theme',         theme);
      Store.set('wf_theme_mode',    themeMode);
      Store.set('wf_day_theme',     dayTheme);
      Store.set('wf_night_theme',   nightTheme);
      Store.set('wf_wake',          wakeTime);
      Store.set('wf_sleep',         sleepTime);
      Store.set('wf_show_events',   showEvents);
      Store.set('wf_show_property', showProp);
      Store.set('wf_photo_dim',     photoDim);
      Store.set('wf_card_opacity',  cardOpacity);
      Store.set('wf_info_logo_name',infoLogoName);
      Store.set('wf_info_logo_sub', infoLogoSub);
      Store.set('wf_info_phone',    infoPhone);
      Store.set('wf_info_email',    infoEmail);
      Store.set('wf_info_addr',     infoAddr);

      applyCurrentTheme();
      applyBuilding(building);
      applyPanelVisibility();
      applyBuildingInfo();
      applyCSSVars();
      closeSettings();
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

  // ── Sleep screen tap to wake ──────────────────────────────────────────────
  if (sleepScreen) {
    sleepScreen.addEventListener('click', () => {
      sleepScreen.classList.add('hidden');
      setTimeout(() => { if (themeMode === 'auto') applyCurrentTheme(); }, 60000);
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
  applyBuilding(building);
  applyPanelVisibility();
  applyBuildingInfo();
  applyCSSVars();

  window.AppSettings = {
    getBuilding:   () => building,
    isEventsShown: () => showEvents,
    isPropShown:   () => showProp,
    getTheme:      () => theme,
  };
})();
