// weather.js — Open-Meteo weather + NOAA tides, panel + ticker render
(function Weather() {
  'use strict';

  // WMO weather code → description
  const WMO_DESC = {
    0:'Clear Sky', 1:'Mostly Clear', 2:'Partly Cloudy', 3:'Overcast',
    45:'Foggy', 48:'Freezing Fog',
    51:'Light Drizzle', 53:'Drizzle', 55:'Heavy Drizzle',
    56:'Freezing Drizzle', 57:'Heavy Freezing Drizzle',
    61:'Light Rain', 63:'Rain', 65:'Heavy Rain',
    66:'Freezing Rain', 67:'Heavy Freezing Rain',
    71:'Light Snow', 73:'Snow', 75:'Heavy Snow', 77:'Snow Grains',
    80:'Rain Showers', 81:'Showers', 82:'Heavy Showers',
    85:'Snow Showers', 86:'Heavy Snow Showers',
    95:'Thunderstorm', 96:'Thunderstorm w/ Hail', 99:'Heavy Thunderstorm',
  };

  // ── Inline SVG weather icons (stroke-based, inherit currentColor) ──────────
  const CLOUD = '<path d="M7 16h9.4a3.2 3.2 0 0 0 .3-6.4A4.6 4.6 0 0 0 7.6 8 3.5 3.5 0 0 0 7 16z"/>';
  const WX_PATHS = {
    'clear':        '<circle cx="12" cy="12" r="4"/><path d="M12 2v2M12 20v2M2 12h2M20 12h2M5 5l1.4 1.4M17.6 17.6L19 19M19 5l-1.4 1.4M6.4 17.6L5 19"/>',
    'mostly-clear': '<circle cx="8" cy="7" r="2.6"/><path d="M8 2.6v1.3M2.6 7H4M12 7h1.4M4.3 3.3l1 1M11.7 3.3l-1 1"/><path d="M8.5 19h8a3 3 0 0 0 .2-6 4 4 0 0 0-7.6-1.2A3.2 3.2 0 0 0 8.5 19z"/>',
    'partly-cloudy':'<circle cx="15" cy="8" r="2.6"/><path d="M15 3.4v1.2M19.6 8h1.2M18 5l.8-.8"/><path d="M6 19h9a3.2 3.2 0 0 0 .2-6.4A4.2 4.2 0 0 0 7 11 3.4 3.4 0 0 0 6 19z"/>',
    'overcast':     CLOUD,
    'fog':          '<path d="M7 13h10a3.4 3.4 0 0 0 .3-6.8A4.8 4.8 0 0 0 7.6 5 3.6 3.6 0 0 0 7 13z"/><path d="M4 17h16M6 20.5h12"/>',
    'drizzle':      CLOUD + '<path d="M9 18l-1 2.4M15 18l-1 2.4"/>',
    'rain':         CLOUD + '<path d="M8.5 18l-1 2.6M12 18l-1 2.6M15.5 18l-1 2.6"/>',
    'heavy-rain':   CLOUD + '<path d="M7.5 18l-1.6 3.2M11 18l-1.6 3.2M14.5 18l-1.6 3.2M18 18l-1.6 3.2"/>',
    'snow':         CLOUD + '<path d="M9 19.5h.01M13 19.5h.01M11 22h.01M15 22h.01"/>',
    'showers':      CLOUD + '<path d="M9 18l-2 3M13 18l-2 3M17 18l-2 3"/>',
    'thunderstorm': CLOUD + '<path d="M13 17.5l-3.2 4.2H13l-1 3 4-5h-3l1-2.2z" fill="currentColor" stroke="none"/>',
    'wind':         '<path d="M3 8h11a2.5 2.5 0 1 0-2.5-2.5M3 12h15a2.5 2.5 0 1 1-2.5 2.5M3 16h9"/>',
  };

  function wmoIconName(code) {
    if (code === 0) return 'clear';
    if (code === 1) return 'mostly-clear';
    if (code === 2) return 'partly-cloudy';
    if (code === 3) return 'overcast';
    if (code === 45 || code === 48) return 'fog';
    if (code >= 51 && code <= 57) return 'drizzle';
    if (code === 61 || code === 63) return 'rain';
    if (code === 65 || code === 66 || code === 67) return 'heavy-rain';
    if ((code >= 71 && code <= 77) || code === 85 || code === 86) return 'snow';
    if (code >= 80 && code <= 82) return 'showers';
    if (code >= 95) return 'thunderstorm';
    return 'overcast';
  }

  function wxSvg(name) {
    const paths = WX_PATHS[name] || WX_PATHS['overcast'];
    return `<svg class="wx-icon" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.6" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true">${paths}</svg>`;
  }

  const DAYS_S = ['Sun','Mon','Tue','Wed','Thu','Fri','Sat'];

  // DOM refs
  const tempEl   = document.getElementById('w-temp');
  const condEl   = document.getElementById('w-condition');
  const feelsEl  = document.getElementById('w-feels');
  const humidEl  = document.getElementById('w-humidity');
  const windEl   = document.getElementById('w-wind');
  const uvEl     = document.getElementById('w-uv');
  const fcEl     = document.getElementById('w-forecast');
  const statusEl = document.getElementById('w-status');
  const tideEl   = document.getElementById('w-tides');
  const tkTemp   = document.getElementById('ticker-temp');
  const tkCond   = document.getElementById('ticker-cond');

  // ── Time helpers ──────────────────────────────────────────────────────────
  function fmtClock(d) {
    let h = d.getHours();
    const m = pad(d.getMinutes());
    const ap = h >= 12 ? 'PM' : 'AM';
    h = h % 12 || 12;
    return `${h}:${m} ${ap}`;
  }
  function setStatus(text) { if (statusEl) statusEl.textContent = text || ''; }

  // ── Weather URL ───────────────────────────────────────────────────────────
  const WEATHER_URL = [
    'https://api.open-meteo.com/v1/forecast',
    `?latitude=${CONFIG.WEATHER.lat}`,
    `&longitude=${CONFIG.WEATHER.lon}`,
    '&current=temperature_2m,apparent_temperature,relative_humidity_2m,wind_speed_10m,weather_code,uv_index',
    '&daily=weather_code,temperature_2m_max,temperature_2m_min',
    `&temperature_unit=${CONFIG.WEATHER.units}`,
    `&wind_speed_unit=${CONFIG.WEATHER.wind}`,
    `&timezone=${encodeURIComponent(CONFIG.WEATHER.timezone)}`,
    '&forecast_days=5',
  ].join('');

  // ── Render weather ──────────────────────────────────────────────────────────
  function render(data) {
    const c    = data.current;
    const d    = data.daily;
    const code = c.weather_code;
    const temp = Math.round(c.temperature_2m);
    const desc = WMO_DESC[code] || 'Clear';

    if (tempEl)  tempEl.textContent  = temp;
    if (condEl)  condEl.textContent  = desc;
    if (feelsEl) feelsEl.textContent = `${Math.round(c.apparent_temperature)}°`;
    if (humidEl) humidEl.textContent = `${Math.round(c.relative_humidity_2m)}%`;
    if (windEl)  windEl.textContent  = `${Math.round(c.wind_speed_10m)} mph`;
    if (uvEl)    uvEl.textContent    = Math.round(c.uv_index ?? 0);

    if (tkTemp) tkTemp.textContent = `${temp}°F`;
    if (tkCond) tkCond.textContent = desc;

    if (fcEl && d) {
      const today = new Date().getDay();
      fcEl.innerHTML = Array.from({ length: 4 }, (_, i) => i + 1)
        .filter(i => d.time[i])
        .map(i => {
          const icon = wxSvg(wmoIconName(d.weather_code[i]));
          const hi   = Math.round(d.temperature_2m_max[i]);
          const lo   = Math.round(d.temperature_2m_min[i]);
          const day  = DAYS_S[(today + i) % 7];
          return `
            <div class="fc-day" role="listitem">
              <span class="fc-name">${day}</span>
              <span class="fc-icon" aria-hidden="true">${icon}</span>
              <div class="fc-temps">
                <span class="fc-hi">${hi}°</span>
                <span class="fc-lo">${lo}°</span>
              </div>
            </div>`;
        }).join('');
    }
  }

  // ── Offline / unavailable weather state ───────────────────────────────────
  function renderOffline(cacheTs) {
    if (tempEl)  tempEl.textContent  = '--';
    if (condEl)  condEl.textContent  = 'Weather unavailable';
    if (feelsEl) feelsEl.textContent = '--';
    if (humidEl) humidEl.textContent = '--';
    if (windEl)  windEl.textContent  = '--';
    if (uvEl)    uvEl.textContent    = '--';
    if (fcEl)    fcEl.innerHTML       = '';
    if (tkTemp)  tkTemp.textContent  = '--°F';
    if (tkCond)  tkCond.textContent  = 'Unavailable';
    setStatus(cacheTs ? `Last updated: ${fmtClock(new Date(cacheTs))}` : 'No data available');
  }

  // ── Weather scheduler — single chain, no overlap ──────────────────────────
  let weatherTimer = null;

  async function fetchWeather(backoff = 30000) {
    clearTimeout(weatherTimer);
    try {
      const ctrl = new AbortController();
      const t    = setTimeout(() => ctrl.abort(), 9000);
      const res  = await fetch(WEATHER_URL, { signal: ctrl.signal });
      clearTimeout(t);
      if (!res.ok) throw new Error(`HTTP ${res.status}`);
      const data = await res.json();
      render(data);
      const ts = Date.now();
      Store.set('wf_weather_cache', { data, ts });
      setStatus(`Updated ${fmtClock(new Date(ts))}`);
      weatherTimer = setTimeout(() => fetchWeather(30000), CONFIG.TIMING.weather_refresh);
    } catch (e) {
      console.warn('[weather] fetch failed:', e.message);
      handleFailure();
      const next = Math.min(backoff * 2, 120000);
      weatherTimer = setTimeout(() => fetchWeather(next), backoff);
    }
  }

  function handleFailure() {
    const cached = Store.get('wf_weather_cache');
    const age = cached?.ts ? (Date.now() - cached.ts) / 60000 : Infinity;
    if (cached?.data && age < 120) {
      // Recent cache (<2h) — keep showing it, just note last-updated time
      render(cached.data);
      setStatus(`Last updated: ${fmtClock(new Date(cached.ts))}`);
    } else {
      renderOffline(cached?.ts);
    }
  }

  // ── NOAA tides (station 9410660 — Los Angeles Harbor) ─────────────────────
  const TIDE_BASE    = 'https://api.tidesandcurrents.noaa.gov/api/prod/datagetter';
  const TIDE_STATION = '9410660';
  const TIDE_REFRESH = 30 * 60 * 1000;
  let tideTimer = null;

  function tideUrl(product, extra) {
    const now  = new Date();
    const tmrw = new Date(now.getTime() + 86400000);
    const ymd  = d => `${d.getFullYear()}${pad(d.getMonth() + 1)}${pad(d.getDate())}`;
    return `${TIDE_BASE}?application=waterfront-lobby&station=${TIDE_STATION}` +
           `&product=${product}&datum=MLLW&time_zone=lst_ldt&units=english&format=json` +
           `&begin_date=${ymd(now)}&end_date=${ymd(tmrw)}${extra || ''}`;
  }

  function renderTides(t) {
    if (!tideEl || !t) return;
    // Single quiet line: "Tides · High 4:12 PM · Low 10:38 PM"
    const segs = [];
    if (t.high) segs.push(`High <b>${t.high.time}</b>`);
    if (t.low)  segs.push(`Low <b>${t.low.time}</b>`);
    if (!segs.length) { tideEl.classList.add('hidden'); return; }
    tideEl.innerHTML = `<span class="tide-line">Tides · ${segs.join(' · ')}</span>`;
    tideEl.classList.remove('hidden');
  }

  async function fetchJson(url) {
    const ctrl = new AbortController();
    const t    = setTimeout(() => ctrl.abort(), 9000);
    try {
      const res = await fetch(url, { signal: ctrl.signal });
      clearTimeout(t);
      if (!res.ok) throw new Error(`HTTP ${res.status}`);
      return await res.json();
    } catch (e) {
      clearTimeout(t);
      throw e;
    }
  }

  async function fetchTides(backoff = 60000) {
    clearTimeout(tideTimer);
    try {
      const [levelRes, predRes] = await Promise.all([
        fetchJson(tideUrl('water_level', '&interval=6')).catch(() => null),
        fetchJson(tideUrl('predictions', '&interval=hilo')),
      ]);

      const tide = {};

      // Current height — last available water_level reading
      const lvl = levelRes?.data;
      if (Array.isArray(lvl) && lvl.length) {
        const v = parseFloat(lvl[lvl.length - 1].v);
        if (!isNaN(v)) tide.current = v.toFixed(1);
      }

      // Next high / low from hi-lo predictions after now
      const preds = predRes?.predictions || [];
      const now = Date.now();
      for (const p of preds) {
        const when = new Date(p.t.replace(' ', 'T')).getTime();
        if (isNaN(when) || when <= now) continue;
        const entry = { time: fmtClock(new Date(when)), ft: parseFloat(p.v).toFixed(1) };
        if (p.type === 'H' && !tide.high) tide.high = entry;
        if (p.type === 'L' && !tide.low)  tide.low  = entry;
        if (tide.high && tide.low) break;
      }

      if (tide.current != null || tide.high || tide.low) {
        renderTides(tide);
        Store.set('wf_tides_cache', { tide, ts: Date.now() });
      }
      tideTimer = setTimeout(() => fetchTides(60000), TIDE_REFRESH);
    } catch (e) {
      console.warn('[tides] fetch failed:', e.message);
      const cached = Store.get('wf_tides_cache');
      if (cached?.tide) renderTides(cached.tide);   // offline fallback
      const next = Math.min(backoff * 2, 300000);
      tideTimer = setTimeout(() => fetchTides(next), backoff);
    }
  }

  // ── Load cached weather immediately (offline resilience) ──────────────────
  const cached = Store.get('wf_weather_cache');
  if (cached?.data) {
    const age = (Date.now() - cached.ts) / 60000;
    if (age < 120) {
      render(cached.data);
      setStatus(`Last updated: ${fmtClock(new Date(cached.ts))}`);
    }
  }
  const cachedTides = Store.get('wf_tides_cache');
  if (cachedTides?.tide) renderTides(cachedTides.tide);

  // ── Boot ─────────────────────────────────────────────────────────────────
  fetchWeather();
  fetchTides();
})();
