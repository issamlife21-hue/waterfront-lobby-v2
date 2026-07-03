// clock.js — live clock display in HUD and sleep screen
(function Clock() {
  'use strict';

  const timeEl  = document.getElementById('clock-time');
  const dateEl  = document.getElementById('clock-date');
  const sleepEl = document.getElementById('sleep-time-display');

  const DAYS   = ['Sun','Mon','Tue','Wed','Thu','Fri','Sat'];
  const MONTHS = ['Jan','Feb','Mar','Apr','May','Jun',
                  'Jul','Aug','Sep','Oct','Nov','Dec'];

  function tick() {
    const now  = new Date();
    const h24  = now.getHours();
    const m    = pad(now.getMinutes());
    const ampm = h24 >= 12 ? 'PM' : 'AM';
    const h12  = h24 % 12 || 12;

    const timeStr = `${h12}:${m} ${ampm}`;
    const dateStr = `${DAYS[now.getDay()]}, ${MONTHS[now.getMonth()]} ${now.getDate()}`;

    if (timeEl)  timeEl.textContent = timeStr;
    if (dateEl)  dateEl.textContent = dateStr;
    if (sleepEl) sleepEl.textContent = timeStr;
  }

  tick();
  setInterval(tick, 1000);
})();
