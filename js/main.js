// main.js — boot sequence, TV keep-alive, Sheet schedule, 3am self-healing reload
(function Main() {
  'use strict';

  // ── Screen Wake Lock (prevents TV sleep) ────────────────────────────────
  let wakeLock = null;

  async function acquireWakeLock() {
    if (!('wakeLock' in navigator)) return;
    try {
      wakeLock = await navigator.wakeLock.request('screen');
      console.info('[wake-lock] acquired');
      wakeLock.addEventListener('release', () => {
        console.info('[wake-lock] released — reacquiring');
        setTimeout(acquireWakeLock, 5000);
      });
    } catch (e) {
      console.warn('[wake-lock] failed:', e.message);
      setTimeout(acquireWakeLock, 30000);
    }
  }

  document.addEventListener('visibilitychange', () => {
    if (document.visibilityState === 'visible') acquireWakeLock();
  });

  acquireWakeLock();

  // ── Keep-alive: activity simulation ─────────────────────────────────────
  const ping = document.createElement('div');
  ping.style.cssText = 'position:fixed;opacity:0;pointer-events:none;width:1px;height:1px;';
  ping.setAttribute('aria-hidden', 'true');
  document.body.appendChild(ping);
  let pingCount = 0;
  setInterval(() => { ping.textContent = ++pingCount; }, 20000);

  // ── Keep-alive: CSS shimmer ──────────────────────────────────────────────
  let shimmerState = false;
  setInterval(() => {
    shimmerState = !shimmerState;
    ping.style.transform = shimmerState ? 'translateX(1px)' : 'translateX(0)';
  }, 25000);

  // ── Sheet-based sleep/wake schedule ──────────────────────────────────────
  // Reads the Settings tab from the Sheet every 10 min.
  // Sheet columns: Key | Value
  // Row 2: SLEEP | 20:00   (time display goes black)
  // Row 3: START | 06:00   (time display wakes up)
  // Monique edits these two cells to control all screens remotely.
  // Theme is NOT controlled here — set per-TV in the on-screen settings.
  async function syncSheetSchedule() {
    const rows = await sheetFetch(CONFIG.GIDS.settings);
    if (!rows || !rows.length) return;

    const map = {};
    rows.forEach(r => {
      // Match any casing of key/value columns
      const k = (r['key'] || r['Key'] || r['KEY'] || '').trim().toUpperCase();
      const v = (r['value'] || r['Value'] || r['VALUE'] || '').trim();
      if (k && v) map[k] = v;
    });

    // SLEEP = when display goes black, START = when it wakes
    if (map['SLEEP']) Store.set('wf_sheet_sleep', map['SLEEP']);
    if (map['START']) Store.set('wf_sheet_wake',  map['START']);

    applySheetSchedule();
  }

  function applySheetSchedule() {
    const sleepT = Store.get('wf_sheet_sleep');
    const wakeT  = Store.get('wf_sheet_wake');
    if (!sleepT || !wakeT) return;

    const now  = new Date();
    const hm   = now.getHours() * 60 + now.getMinutes();

    function toMinutes(t) {
      const parts = t.split(':').map(Number);
      return (parts[0] || 0) * 60 + (parts[1] || 0);
    }

    const sleepM = toMinutes(sleepT);
    const wakeM  = toMinutes(wakeT);

    // Handle midnight crossover (e.g. SLEEP=20:00, START=06:00)
    let isSleep;
    if (sleepM > wakeM) {
      isSleep = hm >= sleepM || hm < wakeM;
    } else {
      isSleep = hm >= sleepM && hm < wakeM;
    }

    const sleepScreen = document.getElementById('sleep-screen');
    if (!sleepScreen) return;

    if (isSleep) {
      sleepScreen.classList.remove('hidden');
      sleepScreen.setAttribute('aria-hidden', 'false');
    } else {
      sleepScreen.classList.add('hidden');
      sleepScreen.setAttribute('aria-hidden', 'true');
    }
  }

  syncSheetSchedule();
  setInterval(applySheetSchedule, 60000);
  setInterval(syncSheetSchedule, CONFIG.TIMING.sheet_refresh);

  // ── 3am daily self-healing reload ────────────────────────────────────────
  const MIN_UPTIME_MS = 6 * 60 * 60 * 1000;
  const bootTime      = Date.now();

  (function schedule3amReload() {
    const now    = new Date();
    const target = new Date(now);
    target.setHours(3, 0, 0, 0);
    if (target <= now) target.setDate(target.getDate() + 1);
    const ms = target - now;

    setTimeout(() => {
      const uptime = Date.now() - bootTime;
      if (uptime >= MIN_UPTIME_MS) {
        console.info('[lifecycle] 3am reload — uptime:', Math.round(uptime / 60000), 'min');
        location.reload();
      } else {
        console.info('[lifecycle] 3am reload skipped — uptime too low');
        schedule3amReload();
      }
    }, ms);

    console.info('[lifecycle] 3am reload scheduled in', Math.round(ms / 60000), 'min');
  })();

  // ── Service Worker registration ──────────────────────────────────────────
  if ('serviceWorker' in navigator) {
    window.addEventListener('load', () => {
      navigator.serviceWorker.register('/sw.js')
        .then(reg => console.info('[sw] registered:', reg.scope))
        .catch(e  => console.warn('[sw] registration failed:', e));
    });
  }

  console.info('[main] Waterfront Lobby Display v2 — boot complete');
})();
