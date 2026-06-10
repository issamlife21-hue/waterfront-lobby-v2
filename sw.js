// sw.js — Service Worker, offline app shell caching
// IMPORTANT: bump CACHE_VERSION on every deployment that changes any file below
const CACHE_VERSION = 'wf-v2-4';
const CACHE_NAME    = CACHE_VERSION;

const APP_SHELL = [
  '/',
  '/index.html',
  '/css/styles.css',
  '/js/config.js',
  '/js/clock.js',
  '/js/background.js',
  '/js/weather.js',
  '/js/directory.js',
  '/js/events.js',
  '/js/settings.js',
  '/js/rotation.js',
  '/js/main.js',
  '/assets/logo.svg',
  'https://fonts.googleapis.com/css2?family=Cormorant+Garamond:wght@300;400&family=Inter:wght@300;400;500;600&family=DM+Mono:wght@400;500&display=swap',
];

// ── Install: cache app shell ─────────────────────────────────────────────────
self.addEventListener('install', e => {
  e.waitUntil(
    caches.open(CACHE_NAME)
      .then(cache => cache.addAll(APP_SHELL))
      .then(() => self.skipWaiting())
  );
});

// ── Activate: remove old caches ──────────────────────────────────────────────
self.addEventListener('activate', e => {
  e.waitUntil(
    caches.keys().then(keys =>
      Promise.all(keys.filter(k => k !== CACHE_NAME).map(k => caches.delete(k)))
    ).then(() => self.clients.claim())
  );
});

// ── Fetch strategy ───────────────────────────────────────────────────────────
// App shell: cache-first (instant load, works offline)
// Google Sheets + Open-Meteo: network-first (live data, never cached here)
self.addEventListener('fetch', e => {
  const url = e.request.url;

  // Never cache: Sheet data, weather API, external images
  const isLiveData = (
    url.includes('docs.google.com') ||
    url.includes('api.open-meteo.com') ||
    url.includes('tidesandcurrents.noaa.gov') ||
    url.includes('wp.com') ||
    url.includes('smushcdn') ||
    url.includes('hollywoodlocations')
  );

  if (isLiveData) {
    // Network-only for live data — app handles localStorage fallback
    e.respondWith(fetch(e.request).catch(() => new Response('', { status: 503 })));
    return;
  }

  // Cache-first for app shell
  e.respondWith(
    caches.match(e.request).then(cached => {
      if (cached) return cached;
      return fetch(e.request).then(res => {
        // Cache new app shell resources
        if (res.ok && e.request.method === 'GET') {
          const clone = res.clone();
          caches.open(CACHE_NAME).then(c => c.put(e.request, clone));
        }
        return res;
      }).catch(() => caches.match('/index.html'));
    })
  );
});
