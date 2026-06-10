// main.js — boot sequence, TV keep-alive, 3am self-healing reload
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

  // Reacquire on visibility change (tab restored)
  document.addEventListener('visibilitychange', () => {
    if (document.visibilityState === 'visible') acquireWakeLock();
  });

  acquireWakeLock();

  // ── Keep-alive: activity simulation ─────────────────────────────────────
  // Updates a hidden counter every 20s — tricks some TV firmware
  // into thinking the page is active
  const ping = document.createElement('div');
  ping.style.cssText = 'position:fixed;opacity:0;pointer-events:none;width:1px;height:1px;';
  ping.setAttribute('aria-hidden', 'true');
  document.body.appendChild(ping);
  let pingCount = 0;
  setInterval(() => { ping.textContent = ++pingCount; }, 20000);

  // ── Keep-alive: CSS shimmer (1px movement every 25s) ────────────────────
  // Some commercial TV OSes only keep-alive if pixels are changing
  let shimmerState = false;
  setInterval(() => {
    shimmerState = !shimmerState;
    ping.style.transform = shimmerState ? 'translateX(1px)' : 'translateX(0)';
  }, 25000);

  // ── 3am daily self-healing reload ────────────────────────────────────────
  // Only fires after ≥6h uptime to avoid disrupting fresh loads
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
        schedule3amReload();   // reschedule for next night
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
