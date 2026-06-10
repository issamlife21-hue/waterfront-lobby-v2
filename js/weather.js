// weather.js — Open-Meteo fetch, panel + ticker render
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

  // WMO → icon character (text, no emoji for commercial displays)
  const WMO_ICON = {
    0:'☀', 1:'🌤', 2:'⛅', 3:'☁',
    45:'🌫', 48:'🌫',
    51:'🌦', 53:'🌧', 55:'🌧', 56:'🌧', 57:'🌧',
    61:'🌦', 63:'🌧', 65:'🌧', 66:'🌧', 67:'🌧',
    71:'🌨', 73:'❄', 75:'❄', 77:'❄',
    80:'🌦', 81:'🌧', 82:'⛈',
    85:'🌨', 86:'❄',
    95:'⛈', 96:'⛈', 99:'⛈',
  };

  const DAYS_S = ['Sun','Mon','Tue','Wed','Thu','Fri','Sat'];

  // DOM refs
  const tempEl   = document.getElementById('w-temp');
  const condEl   = document.getElementById('w-condition');
  const feelsEl  = document.getElementById('w-feels');
  const humidEl  = document.getElementById('w-humidity');
  const windEl   = document.getElementById('w-wind');
  const uvEl     = document.getElementById('w-uv');
  const fcEl     = document.getElementById('w-forecast');
  const tkTemp   = document.getElementById('ticker-temp');
  const tkCond   = document.getElementById('ticker-cond');

  // ── Build weather URL ────────────────────────────────────────────────────
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

  // ── Fetch with exponential backoff ──────────────────────────────────────
  async function fetchWeather(delay = 30000) {
    try {
      const ctrl = new AbortController();
      const t    = setTimeout(() => ctrl.abort(), 9000);
      const res  = await fetch(WEATHER_URL, { signal: ctrl.signal });
      clearTimeout(t);
      if (!res.ok) throw new Error(`HTTP ${res.status}`);
      const data = await res.json();
      render(data);
      Store.set('wf_weather_cache', { data, ts: Date.now() });
    } catch (e) {
      console.warn('[weather] fetch failed:', e.message, `retry in ${delay/1000}s`);
      setTimeout(() => fetchWeather(Math.min(delay * 2, 120000)), delay);
    }
  }

  // ── Render ────────────────────────────────────────────────────────────────
  function render(data) {
    const c    = data.current;
    const d    = data.daily;
    const code = c.weather_code;
    const temp = Math.round(c.temperature_2m);
    const desc = WMO_DESC[code] || 'Clear';

    // Panel
    if (tempEl)  tempEl.textContent  = temp;
    if (condEl)  condEl.textContent  = desc;
    if (feelsEl) feelsEl.textContent = `${Math.round(c.apparent_temperature)}°`;
    if (humidEl) humidEl.textContent = `${Math.round(c.relative_humidity_2m)}%`;
    if (windEl)  windEl.textContent  = `${Math.round(c.wind_speed_10m)} mph`;
    if (uvEl)    uvEl.textContent    = Math.round(c.uv_index ?? 0);

    // Ticker
    if (tkTemp) tkTemp.textContent = `${temp}°F`;
    if (tkCond) tkCond.textContent = desc;

    // Forecast (days 1–4, skip today=0)
    if (fcEl && d) {
      const today = new Date().getDay();
      fcEl.innerHTML = Array.from({ length: 4 }, (_, i) => i + 1)
        .filter(i => d.time[i])
        .map(i => {
          const icon = WMO_ICON[d.weather_code[i]] || '—';
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

  // ── Load cached data immediately (offline resilience) ───────────────────
  const cached = Store.get('wf_weather_cache');
  if (cached?.data) {
    const age = (Date.now() - cached.ts) / 60000;
    if (age < 120) render(cached.data);   // use cache up to 2 hrs old
  }

  // ── Boot ─────────────────────────────────────────────────────────────────
  fetchWeather();
  setInterval(fetchWeather, CONFIG.TIMING.weather_refresh);
})();
