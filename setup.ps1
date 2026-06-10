# =============================================================================
# Waterfront Lobby Display v2 — Full Setup Script
# Run in VS Code terminal (PowerShell) from any folder:
#   powershell -ExecutionPolicy Bypass -File setup.ps1
# =============================================================================

$ErrorActionPreference = "Stop"
$repoName = "waterfront-lobby-v2"
$ghUser   = "issamlife21-hue"

Write-Host ""
Write-Host "Waterfront Lobby Display v2 — Setup" -ForegroundColor Cyan
Write-Host "=====================================" -ForegroundColor Cyan
Write-Host ""

# ── Step 1: Check gh CLI ─────────────────────────────────────────────────────
Write-Host "[1/6] Checking GitHub CLI..." -ForegroundColor Yellow
try {
    $ghVersion = gh --version 2>&1
    Write-Host "  gh CLI found: $($ghVersion[0])" -ForegroundColor Green
} catch {
    Write-Host "  gh CLI not found. Installing via winget..." -ForegroundColor Yellow
    winget install --id GitHub.cli -e --accept-source-agreements --accept-package-agreements
    Write-Host "  Please run: gh auth login" -ForegroundColor Yellow
    Write-Host "  Then re-run this script." -ForegroundColor Yellow
    exit 1
}

# ── Step 2: Create project folder ─────────────────────────────────────────────
Write-Host "[2/6] Creating project folder..." -ForegroundColor Yellow
New-Item -ItemType Directory -Force -Path $repoName | Out-Null
Set-Location $repoName
New-Item -ItemType Directory -Force -Path "css"    | Out-Null
New-Item -ItemType Directory -Force -Path "js"     | Out-Null
New-Item -ItemType Directory -Force -Path "assets" | Out-Null
Write-Host "  Folder ready: $repoName" -ForegroundColor Green

# ── Step 3: Write all files ────────────────────────────────────────────────────
Write-Host "[3/6] Writing project files..." -ForegroundColor Yellow


Set-Content -Path 'index.html' -Encoding UTF8 -Value @'
<!DOCTYPE html>
<html lang="en" data-theme="obsidian" data-building="310">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=1920, initial-scale=1">
  <meta name="description" content="The Waterfront at Catalina Landing — Lobby Display">
  <title>The Waterfront at Catalina Landing</title>
  <link rel="preconnect" href="https://fonts.googleapis.com">
  <link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
  <link href="https://fonts.googleapis.com/css2?family=DM+Serif+Display:ital@0;1&family=Inter:wght@300;400;500;600&family=DM+Mono:ital,wght@0,400;0,500;1,400&display=swap" rel="stylesheet">
  <link rel="stylesheet" href="css/styles.css">
</head>
<body>

  <!-- ── Background ──────────────────────────────────────────────────────── -->
  <div id="bg-layer" aria-hidden="true">
    <div class="bg-slide active" id="bg-a"></div>
    <div class="bg-slide"        id="bg-b"></div>
    <div class="bg-scrim"></div>
  </div>

  <!-- ── HUD — Top ───────────────────────────────────────────────────────── -->
  <header id="hud">
    <div id="logo" role="img" aria-label="The Waterfront at Catalina Landing">
      <img id="logo-mark" src="assets/logo.svg" alt="" width="44" height="44">
      <div id="logo-text">
        <span id="logo-name">The Waterfront</span>
        <span id="logo-sub">at Catalina Landing</span>
      </div>
    </div>
    <div id="hud-clock" aria-live="polite" aria-atomic="true">
      <span id="clock-time"></span>
      <span id="clock-date"></span>
    </div>
  </header>

  <!-- ── Panel: Weather ──────────────────────────────────────────────────── -->
  <section id="panel-weather" class="panel active" aria-label="Current weather">
    <div class="panel-inner">
      <span class="eyebrow">Long Beach, California</span>
      <div class="weather-main">
        <div class="weather-temp-block">
          <span id="w-temp" aria-label="Temperature">--</span>
          <span class="weather-unit" aria-hidden="true">°F</span>
        </div>
        <div class="weather-meta">
          <span id="w-condition">Loading</span>
          <span class="weather-loc">Long Beach, CA</span>
        </div>
      </div>
      <div class="weather-stats" role="list">
        <div class="stat" role="listitem">
          <span class="stat-label">Feels like</span>
          <span class="stat-val" id="w-feels">--</span>
        </div>
        <div class="stat-div" aria-hidden="true"></div>
        <div class="stat" role="listitem">
          <span class="stat-label">Humidity</span>
          <span class="stat-val" id="w-humidity">--</span>
        </div>
        <div class="stat-div" aria-hidden="true"></div>
        <div class="stat" role="listitem">
          <span class="stat-label">Wind</span>
          <span class="stat-val" id="w-wind">--</span>
        </div>
        <div class="stat-div" aria-hidden="true"></div>
        <div class="stat" role="listitem">
          <span class="stat-label">UV Index</span>
          <span class="stat-val" id="w-uv">--</span>
        </div>
      </div>
      <div id="w-forecast" role="list" aria-label="4-day forecast"></div>
    </div>
  </section>

  <!-- ── Panel: Directory ────────────────────────────────────────────────── -->
  <section id="panel-directory" class="panel" aria-label="Building directory">
    <div class="panel-inner">
      <div class="dir-heading">
        <span class="eyebrow">Building Directory</span>
        <span class="dir-building" id="dir-building-name">310 Golden Shore</span>
      </div>
      <div class="dir-table" id="dir-list" role="list">
        <div class="dir-empty">Loading directory…</div>
      </div>
      <p class="dir-footer-text">
        Leasing Inquiries &nbsp;·&nbsp;
        <strong id="dir-phone">(424) 477-3816</strong>
      </p>
    </div>
  </section>

  <!-- ── Panel: Events ───────────────────────────────────────────────────── -->
  <section id="panel-events" class="panel" aria-label="Upcoming events">
    <div class="panel-inner">
      <div class="events-heading">
        <span class="eyebrow">At the Waterfront</span>
        <span class="events-title">Upcoming Events</span>
      </div>
      <div class="events-grid" id="events-grid" role="list">
        <div class="events-empty">Loading events…</div>
      </div>
      <p class="events-footer-text" id="events-footer">
        To post an event &nbsp;·&nbsp;
        <strong id="events-email">lobby@ticapital.com</strong>
      </p>
    </div>
  </section>

  <!-- ── Panel: Property ─────────────────────────────────────────────────── -->
  <section id="panel-property" class="panel panel-ambient" aria-label="Property">
    <div class="property-caption">
      <span class="property-cap-name" id="prop-name">The Waterfront at Catalina Landing</span>
      <span class="property-cap-addr" id="prop-addr">310 – 340 Golden Shore · Long Beach, CA</span>
    </div>
  </section>

  <!-- ── Ticker — Bottom ─────────────────────────────────────────────────── -->
  <footer id="ticker" aria-label="Status bar">
    <div class="ticker-segment">
      <span class="ticker-label">Weather</span>
      <span class="ticker-value" id="ticker-temp">--°F</span>
      <div class="ticker-sep" aria-hidden="true"></div>
      <span class="ticker-value" id="ticker-cond">--</span>
    </div>
    <div class="ticker-segment">
      <span class="ticker-label">Campus</span>
      <span class="ticker-value">310 – 340 Golden Shore · Long Beach</span>
    </div>
    <div class="ticker-segment" style="border-right:none; flex:1; justify-content:flex-end;">
      <nav id="ticker-nav" aria-label="Panel navigation">
        <button class="nav-dot active" data-panel="weather"   aria-label="Weather panel"></button>
        <button class="nav-dot"        data-panel="directory" aria-label="Directory panel"></button>
        <button class="nav-dot"        data-panel="events"    aria-label="Events panel"></button>
        <button class="nav-dot"        data-panel="property"  aria-label="Property panel"></button>
      </nav>
    </div>
  </footer>

  <!-- ── Settings gear ───────────────────────────────────────────────────── -->
  <button id="settings-trigger" aria-label="Open display settings" title="Settings">
    <svg width="19" height="19" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.6" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true">
      <circle cx="12" cy="12" r="3"/>
      <path d="M19.4 15a1.65 1.65 0 0 0 .33 1.82l.06.06a2 2 0 0 1-2.83 2.83l-.06-.06a1.65 1.65 0 0 0-1.82-.33 1.65 1.65 0 0 0-1 1.51V21a2 2 0 0 1-4 0v-.09A1.65 1.65 0 0 0 9 19.4a1.65 1.65 0 0 0-1.82.33l-.06-.06a2 2 0 0 1-2.83-2.83l.06-.06A1.65 1.65 0 0 0 4.68 15a1.65 1.65 0 0 0-1.51-1H3a2 2 0 0 1 0-4h.09A1.65 1.65 0 0 0 4.6 9a1.65 1.65 0 0 0-.33-1.82l-.06-.06a2 2 0 0 1 2.83-2.83l.06.06A1.65 1.65 0 0 0 9 4.68a1.65 1.65 0 0 0 1-1.51V3a2 2 0 0 1 4 0v.09a1.65 1.65 0 0 0 1 1.51 1.65 1.65 0 0 0 1.82-.33l.06-.06a2 2 0 0 1 2.83 2.83l-.06.06A1.65 1.65 0 0 0 19.4 9a1.65 1.65 0 0 0 1.51 1H21a2 2 0 0 1 0 4h-.09a1.65 1.65 0 0 0-1.51 1z"/>
    </svg>
  </button>

  <!-- ── Settings overlay ────────────────────────────────────────────────── -->
  <div id="settings-overlay" class="hidden" role="dialog" aria-modal="true" aria-label="Display settings">
    <div class="settings-backdrop" id="settings-backdrop"></div>
    <div class="settings-sheet">

      <div class="settings-head">
        <span class="settings-head-title">Display Settings</span>
        <button class="settings-x" id="settings-close" aria-label="Close settings">✕</button>
      </div>

      <!-- PIN gate -->
      <div id="pin-gate">
        <p class="pin-prompt">Enter PIN to access settings</p>
        <div class="pin-dots" id="pin-dots">
          <span class="pin-dot"></span>
          <span class="pin-dot"></span>
          <span class="pin-dot"></span>
          <span class="pin-dot"></span>
        </div>
        <div class="pin-pad">
          <button class="pin-key" data-d="1">1</button>
          <button class="pin-key" data-d="2">2</button>
          <button class="pin-key" data-d="3">3</button>
          <button class="pin-key" data-d="4">4</button>
          <button class="pin-key" data-d="5">5</button>
          <button class="pin-key" data-d="6">6</button>
          <button class="pin-key" data-d="7">7</button>
          <button class="pin-key" data-d="8">8</button>
          <button class="pin-key" data-d="9">9</button>
          <button class="pin-key pin-action" data-a="clear">⌫</button>
          <button class="pin-key" data-d="0">0</button>
          <button class="pin-key pin-enter pin-action" data-a="enter">→</button>
        </div>
        <p class="pin-err hidden" id="pin-err">Incorrect PIN — try again</p>
      </div>

      <!-- Settings body (unlocked) -->
      <div id="settings-body" class="hidden">

        <div class="s-section">
          <p class="s-section-title">This Screen</p>
          <div class="s-row">
            <span class="s-label">Building</span>
            <select id="s-building" class="s-select">
              <option value="310">310 Golden Shore</option>
              <option value="320">320 Golden Shore</option>
              <option value="330">330 Golden Shore</option>
              <option value="340">340 Golden Shore</option>
            </select>
          </div>
          <div class="s-row" style="padding-top: 18px;">
            <span class="s-label">Theme</span>
            <div class="theme-picker">
              <button class="theme-swatch active" data-theme="obsidian" title="Obsidian">
                <span class="theme-swatch-label">Obsidian</span>
              </button>
              <button class="theme-swatch" data-theme="stone" title="Stone">
                <span class="theme-swatch-label">Stone</span>
              </button>
              <button class="theme-swatch" data-theme="navy" title="Navy">
                <span class="theme-swatch-label">Navy</span>
              </button>
            </div>
          </div>
          <div class="s-row" style="margin-top:6px;">
            <span class="s-label">Theme mode</span>
            <select id="s-theme-mode" class="s-select">
              <option value="manual">Manual (always use selected theme)</option>
              <option value="auto">Auto (switch on schedule)</option>
            </select>
          </div>
        </div>

        <div class="s-section" id="schedule-section">
          <p class="s-section-title">Auto Schedule</p>
          <div class="s-row">
            <span class="s-label">Daytime theme</span>
            <select id="s-day-theme" class="s-select">
              <option value="stone">Stone</option>
              <option value="obsidian">Obsidian</option>
              <option value="navy">Navy</option>
            </select>
          </div>
          <div class="s-row">
            <span class="s-label">Nighttime theme</span>
            <select id="s-night-theme" class="s-select">
              <option value="obsidian">Obsidian</option>
              <option value="stone">Stone</option>
              <option value="navy">Navy</option>
            </select>
          </div>
          <div class="s-row">
            <span class="s-label">Day starts</span>
            <input type="time" id="s-wake" class="s-input" value="07:00">
          </div>
          <div class="s-row">
            <span class="s-label">Night starts</span>
            <input type="time" id="s-sleep" class="s-input" value="20:00">
          </div>
          <p class="s-hint">Auto mode switches theme automatically at these times.</p>
        </div>

        <div class="s-section">
          <p class="s-section-title">Panels</p>
          <div class="s-row">
            <span class="s-label">Show Events panel</span>
            <label class="s-switch">
              <input type="checkbox" id="s-show-events" checked>
              <span class="s-track"></span>
            </label>
          </div>
          <div class="s-row">
            <span class="s-label">Show Property panel</span>
            <label class="s-switch">
              <input type="checkbox" id="s-show-property" checked>
              <span class="s-track"></span>
            </label>
          </div>
        </div>

        <div class="s-section">
          <p class="s-section-title">Edit Building Info</p>
          <p class="s-hint" style="margin-bottom:12px;">Changes what''s displayed on screen. No code needed.</p>
          <div class="s-text-group">
            <div class="s-text-row">
              <span class="s-text-label">Logo name</span>
              <input type="text" id="info-logo-name" class="s-input s-input-wide" placeholder="The Waterfront">
            </div>
            <div class="s-text-row">
              <span class="s-text-label">Logo subtitle</span>
              <input type="text" id="info-logo-sub" class="s-input s-input-wide" placeholder="at Catalina Landing">
            </div>
            <div class="s-text-row">
              <span class="s-text-label">Leasing phone</span>
              <input type="text" id="info-phone" class="s-input s-input-wide" placeholder="(424) 477-3816">
            </div>
            <div class="s-text-row">
              <span class="s-text-label">Events email</span>
              <input type="text" id="info-email" class="s-input s-input-wide" placeholder="lobby@ticapital.com">
            </div>
            <div class="s-text-row">
              <span class="s-text-label">Property address</span>
              <input type="text" id="info-addr" class="s-input s-input-wide" placeholder="310–340 Golden Shore">
            </div>
          </div>
        </div>

        <div class="s-section">
          <p class="s-section-title">Security</p>
          <div class="s-row">
            <span class="s-label">New PIN (4 digits)</span>
            <div style="display:flex;gap:8px;align-items:center;">
              <input type="password" id="s-new-pin" class="s-input" maxlength="4" placeholder="••••" style="width:90px;">
              <button class="s-btn s-btn-inline" id="s-save-pin-btn">Save</button>
            </div>
          </div>
        </div>

        <div class="s-actions">
          <button class="s-btn s-btn-primary" id="s-save">Save &amp; Close</button>
          <button class="s-btn s-btn-danger"  id="s-reset">Reset all</button>
        </div>

      </div>
    </div>
  </div>

  <!-- ── Sleep Screen ─────────────────────────────────────────────────────── -->
  <div id="sleep-screen" class="hidden" aria-hidden="true">
    <div class="sleep-inner">
      <div class="sleep-mark"></div>
      <span class="sleep-time" id="sleep-time-display"></span>
    </div>
  </div>

  <!-- ── Scripts ─────────────────────────────────────────────────────────── -->
  <script src="js/config.js"></script>
  <script src="js/clock.js"></script>
  <script src="js/background.js"></script>
  <script src="js/weather.js"></script>
  <script src="js/directory.js"></script>
  <script src="js/events.js"></script>
  <script src="js/settings.js"></script>
  <script src="js/rotation.js"></script>
  <script src="js/main.js"></script>

</body>
</html>

'@
Write-Host '  Written: index.html' -ForegroundColor Green
Set-Content -Path 'css/styles.css' -Encoding UTF8 -Value @'
/* =============================================================================
   WATERFRONT LOBBY DISPLAY v2 — STYLES
   Samsung QM65C · 4K 65" · 500nit · 12–18ft viewing distance
   Three themes: obsidian | stone | navy
   ============================================================================= */

/* ── Google Fonts ─────────────────────────────────────────────────────────── */
@import url(''https://fonts.googleapis.com/css2?family=DM+Serif+Display:ital@0;1&family=Inter:wght@300;400;500;600&family=DM+Mono:ital,wght@0,400;0,500;1,400&display=swap'');

/* ── Design Tokens ────────────────────────────────────────────────────────── */
:root {
  /* Spacing */
  --sp-xs:  8px;
  --sp-sm:  16px;
  --sp-md:  28px;
  --sp-lg:  48px;
  --sp-xl:  72px;

  /* Type scale — distance-first, 65" at 15ft */
  --fs-hero:    clamp(100px, 10.5vw, 152px);
  --fs-display: clamp(52px,  5.4vw,  78px);
  --fs-title:   clamp(36px,  3.8vw,  54px);
  --fs-heading: clamp(26px,  2.7vw,  38px);
  --fs-body:    clamp(20px,  2.1vw,  28px);
  --fs-label:   clamp(14px,  1.4vw,  19px);
  --fs-micro:   clamp(11px,  1.1vw,  15px);

  /* Radius */
  --r-sm: 6px;
  --r-md: 12px;
  --r-lg: 20px;
  --r-xl: 32px;

  /* Transitions */
  --ease: cubic-bezier(0.4, 0, 0.2, 1);
  --t-fast: 200ms;
  --t-mid:  500ms;
  --t-slow: 1200ms;

  /* HUD heights */
  --hud-h: 76px;
  --ticker-h: 52px;
}

/* ── Theme: Obsidian (default) ────────────────────────────────────────────── */
[data-theme="obsidian"] {
  --bg:             #0B0F12;
  --bg-panel:       rgba(11, 15, 18, 0.78);
  --bg-card:        rgba(18, 24, 30, 0.88);
  --bg-input:       rgba(255,255,255,0.05);

  --text-1:         #EDE8DF;
  --text-2:         #8FA3B0;
  --text-3:         #4A606E;

  --accent:         #EEA651;
  --accent-dim:     rgba(238,166,81,0.12);
  --accent-border:  rgba(238,166,81,0.28);

  --border:         rgba(255,255,255,0.07);
  --border-md:      rgba(255,255,255,0.12);

  --hud-bg:         rgba(8, 11, 14, 0.85);
  --hud-border:     rgba(255,255,255,0.06);

  --ticker-bg:      rgba(6, 9, 11, 0.92);
  --ticker-border:  rgba(255,255,255,0.06);

  --photo-scrim: linear-gradient(
    105deg,
    rgba(11,15,18,0.92) 0%,
    rgba(11,15,18,0.65) 38%,
    rgba(11,15,18,0.18) 68%,
    rgba(11,15,18,0.0)  100%
  );

  --sleep-bg:   #000;
  --sleep-text: rgba(238,166,81,0.35);
}

/* ── Theme: Stone ─────────────────────────────────────────────────────────── */
[data-theme="stone"] {
  --bg:             #EDE8DF;
  --bg-panel:       rgba(237, 232, 223, 0.84);
  --bg-card:        rgba(255, 252, 248, 0.92);
  --bg-input:       rgba(0,0,0,0.04);

  --text-1:         #18262F;
  --text-2:         #4A606E;
  --text-3:         #96A8B2;

  --accent:         #C07D08;
  --accent-dim:     rgba(192,125,8,0.10);
  --accent-border:  rgba(192,125,8,0.24);

  --border:         rgba(24,38,47,0.09);
  --border-md:      rgba(24,38,47,0.16);

  --hud-bg:         rgba(237,232,223,0.92);
  --hud-border:     rgba(24,38,47,0.09);

  --ticker-bg:      rgba(230,225,216,0.96);
  --ticker-border:  rgba(24,38,47,0.09);

  --photo-scrim: linear-gradient(
    105deg,
    rgba(237,232,223,0.96) 0%,
    rgba(237,232,223,0.72) 38%,
    rgba(237,232,223,0.28) 68%,
    rgba(237,232,223,0.0)  100%
  );

  --sleep-bg:   #EDE8DF;
  --sleep-text: rgba(192,125,8,0.4);
}

/* ── Theme: Navy ──────────────────────────────────────────────────────────── */
[data-theme="navy"] {
  --bg:             #0D1923;
  --bg-panel:       rgba(13, 25, 35, 0.80);
  --bg-card:        rgba(16, 30, 44, 0.90);
  --bg-input:       rgba(255,255,255,0.05);

  --text-1:         #D8E8F2;
  --text-2:         #6E9CB8;
  --text-3:         #3A5F78;

  --accent:         #EEA651;
  --accent-dim:     rgba(238,166,81,0.12);
  --accent-border:  rgba(238,166,81,0.28);

  --border:         rgba(152,192,218,0.10);
  --border-md:      rgba(152,192,218,0.18);

  --hud-bg:         rgba(8, 16, 24, 0.88);
  --hud-border:     rgba(152,192,218,0.08);

  --ticker-bg:      rgba(6, 12, 18, 0.94);
  --ticker-border:  rgba(152,192,218,0.08);

  --photo-scrim: linear-gradient(
    105deg,
    rgba(13,25,35,0.94) 0%,
    rgba(13,25,35,0.68) 38%,
    rgba(13,25,35,0.20) 68%,
    rgba(13,25,35,0.0)  100%
  );

  --sleep-bg:   #06101A;
  --sleep-text: rgba(238,166,81,0.32);
}

/* ── Reset ────────────────────────────────────────────────────────────────── */
*, *::before, *::after { box-sizing: border-box; margin: 0; padding: 0; }

html, body {
  width: 100vw; height: 100vh;
  overflow: hidden;
  background: var(--bg);
  color: var(--text-1);
  font-family: ''Inter'', system-ui, sans-serif;
  font-size: 16px;
  -webkit-font-smoothing: antialiased;
  user-select: none;
  cursor: none;
  transition: background var(--t-mid) var(--ease),
              color     var(--t-mid) var(--ease);
}

/* ── Background Layer ─────────────────────────────────────────────────────── */
#bg-layer {
  position: fixed; inset: 0; z-index: 0;
  background: var(--bg);
}

.bg-slide {
  position: absolute; inset: 0;
  background-size: cover;
  background-position: center;
  opacity: 0;
  transition: opacity var(--t-slow) var(--ease);
  will-change: opacity;
}
.bg-slide.active { opacity: 1; }
.bg-slide.active { animation: kb 28s ease-in-out forwards; }

@keyframes kb {
  from { transform: scale(1.0); }
  to   { transform: scale(1.055); }
}

.bg-scrim {
  position: absolute; inset: 0; z-index: 1;
  background: var(--photo-scrim);
  transition: background var(--t-mid) var(--ease);
}

/* ── HUD — Top bar ────────────────────────────────────────────────────────── */
#hud {
  position: fixed; top: 0; left: 0; right: 0;
  height: var(--hud-h);
  z-index: 200;
  display: flex; align-items: center;
  justify-content: space-between;
  padding: 0 var(--sp-lg);
  background: var(--hud-bg);
  border-bottom: 1px solid var(--hud-border);
  backdrop-filter: blur(24px);
  -webkit-backdrop-filter: blur(24px);
}

/* Logo */
#logo {
  display: flex; align-items: center; gap: var(--sp-sm);
  text-decoration: none;
}

#logo-mark {
  width: 44px; height: 44px;
  flex-shrink: 0;
}

#logo-text { display: flex; flex-direction: column; gap: 1px; }

#logo-name {
  font-family: ''DM Serif Display'', serif;
  font-size: 22px; line-height: 1;
  color: var(--text-1);
  letter-spacing: -0.01em;
}

#logo-sub {
  font-size: var(--fs-micro);
  font-weight: 500;
  color: var(--text-2);
  letter-spacing: 0.08em;
  text-transform: uppercase;
}

/* Clock */
#hud-clock {
  display: flex; flex-direction: column;
  align-items: flex-end; gap: 2px;
}

#clock-time {
  font-family: ''DM Mono'', monospace;
  font-size: 30px; font-weight: 500;
  color: var(--text-1);
  letter-spacing: -0.03em; line-height: 1;
}

#clock-date {
  font-size: var(--fs-label);
  color: var(--text-2);
  font-weight: 400;
  letter-spacing: 0.03em;
}

/* ── Ticker — Bottom bar ──────────────────────────────────────────────────── */
#ticker {
  position: fixed; bottom: 0; left: 0; right: 0;
  height: var(--ticker-h);
  z-index: 200;
  display: flex; align-items: center;
  gap: 0;
  background: var(--ticker-bg);
  border-top: 1px solid var(--ticker-border);
  backdrop-filter: blur(24px);
  -webkit-backdrop-filter: blur(24px);
  overflow: hidden;
}

.ticker-segment {
  display: flex; align-items: center;
  gap: var(--sp-sm);
  padding: 0 var(--sp-md);
  height: 100%;
  border-right: 1px solid var(--border);
  white-space: nowrap;
}

.ticker-segment:last-child { border-right: none; flex: 1; }

.ticker-label {
  font-size: var(--fs-micro);
  font-weight: 600;
  letter-spacing: 0.12em;
  text-transform: uppercase;
  color: var(--accent);
}

.ticker-value {
  font-family: ''DM Mono'', monospace;
  font-size: var(--fs-label);
  color: var(--text-2);
}

.ticker-sep {
  width: 1px; height: 20px;
  background: var(--border-md);
  flex-shrink: 0;
}

/* Nav tabs inside ticker */
#ticker-nav {
  display: flex; align-items: center;
  gap: 4px;
  margin-left: auto;
  padding: 0 var(--sp-md);
}

.nav-dot {
  width: 7px; height: 7px;
  border-radius: 50%;
  background: var(--border-md);
  border: none;
  cursor: pointer;
  transition: background var(--t-fast), transform var(--t-fast);
  padding: 0;
}

.nav-dot.active {
  background: var(--accent);
  transform: scale(1.3);
}

/* ── Panels (shared) ──────────────────────────────────────────────────────── */
.panel {
  position: fixed;
  top: var(--hud-h); bottom: var(--ticker-h);
  left: 0; right: 0;
  z-index: 10;
  display: flex; align-items: center;
  opacity: 0;
  pointer-events: none;
  transition: opacity var(--t-mid) var(--ease);
  will-change: opacity;
}

.panel.active {
  opacity: 1;
  pointer-events: auto;
}

.panel-inner {
  width: 100%;
  padding: var(--sp-xl) var(--sp-xl);
  display: flex; flex-direction: column;
  gap: var(--sp-md);
  max-width: 1600px;
}

.eyebrow {
  font-size: var(--fs-label);
  font-weight: 600;
  letter-spacing: 0.14em;
  text-transform: uppercase;
  color: var(--accent);
  display: block;
  margin-bottom: 4px;
}

/* ── Panel: Weather ───────────────────────────────────────────────────────── */
.weather-main {
  display: flex; align-items: flex-end;
  gap: var(--sp-md);
}

.weather-temp-block {
  display: flex; align-items: flex-start;
  line-height: 1;
}

#w-temp {
  font-family: ''DM Serif Display'', serif;
  font-size: var(--fs-hero);
  color: var(--text-1);
  letter-spacing: -0.05em;
  line-height: 0.88;
}

.weather-unit {
  font-family: ''DM Serif Display'', serif;
  font-size: clamp(38px, 4vw, 58px);
  color: var(--accent);
  margin-top: 0.14em;
  letter-spacing: -0.02em;
}

.weather-meta {
  display: flex; flex-direction: column;
  gap: var(--sp-xs); padding-bottom: 0.18em;
}

#w-condition {
  font-size: var(--fs-display);
  font-weight: 300;
  color: var(--text-1);
  letter-spacing: -0.02em; line-height: 1;
}

.weather-loc {
  font-size: var(--fs-body);
  color: var(--text-2);
  font-weight: 400;
  letter-spacing: 0.04em;
}

/* Stats pill */
.weather-stats {
  display: flex; align-items: center;
  background: var(--bg-card);
  border: 1px solid var(--border);
  border-radius: var(--r-lg);
  padding: var(--sp-md) var(--sp-lg);
  width: fit-content;
}

.stat {
  display: flex; flex-direction: column;
  gap: 5px; padding: 0 var(--sp-lg);
}
.stat:first-child { padding-left: 0; }
.stat:last-child  { padding-right: 0; }

.stat-label {
  font-size: var(--fs-label);
  font-weight: 600;
  letter-spacing: 0.1em;
  text-transform: uppercase;
  color: var(--text-3);
}

.stat-val {
  font-family: ''DM Mono'', monospace;
  font-size: var(--fs-heading);
  font-weight: 500;
  color: var(--text-1);
  letter-spacing: -0.02em;
}

.stat-div {
  width: 1px; height: 44px;
  background: var(--border-md);
  flex-shrink: 0;
}

/* Forecast */
#w-forecast {
  display: flex; gap: var(--sp-sm); flex-wrap: nowrap;
}

.fc-day {
  display: flex; flex-direction: column;
  align-items: center; gap: 6px;
  background: var(--bg-card);
  border: 1px solid var(--border);
  border-radius: var(--r-md);
  padding: var(--sp-sm) var(--sp-md);
  min-width: 110px;
}

.fc-name {
  font-size: var(--fs-label);
  font-weight: 600;
  letter-spacing: 0.08em;
  text-transform: uppercase;
  color: var(--text-2);
}

.fc-icon { font-size: 26px; line-height: 1; }

.fc-temps {
  display: flex; gap: 7px;
  align-items: baseline;
}

.fc-hi {
  font-family: ''DM Mono'', monospace;
  font-size: var(--fs-body);
  font-weight: 500; color: var(--text-1);
}

.fc-lo {
  font-family: ''DM Mono'', monospace;
  font-size: var(--fs-label); color: var(--text-3);
}

/* ── Panel: Directory ─────────────────────────────────────────────────────── */
.dir-heading {
  display: flex; flex-direction: column; gap: 4px;
}

.dir-building {
  font-family: ''DM Serif Display'', serif;
  font-size: var(--fs-title);
  color: var(--text-1);
  letter-spacing: -0.02em; line-height: 1.1;
}

.dir-table {
  background: var(--bg-card);
  border: 1px solid var(--border);
  border-radius: var(--r-lg);
  overflow: hidden;
  width: fit-content;
  min-width: 580px;
}

.dir-row {
  display: grid;
  grid-template-columns: 1fr auto;
  align-items: center;
  gap: var(--sp-lg);
  padding: var(--sp-md) var(--sp-lg);
  border-bottom: 1px solid var(--border);
  transition: background var(--t-fast);
}
.dir-row:last-child { border-bottom: none; }
.dir-row:nth-child(even) { background: rgba(255,255,255,0.018); }
[data-theme="stone"] .dir-row:nth-child(even) { background: rgba(0,0,0,0.025); }

.dir-tenant {
  font-size: var(--fs-heading);
  font-weight: 400;
  color: var(--text-1);
  letter-spacing: -0.01em;
}

.dir-suite {
  font-family: ''DM Mono'', monospace;
  font-size: var(--fs-body);
  color: var(--accent);
  white-space: nowrap;
}

.dir-footer-text {
  font-size: var(--fs-label);
  color: var(--text-3);
  letter-spacing: 0.04em;
}
.dir-footer-text strong { color: var(--text-2); font-weight: 500; }

.dir-empty {
  padding: var(--sp-lg);
  font-size: var(--fs-body);
  color: var(--text-3);
  font-style: italic;
}

/* ── Panel: Events ────────────────────────────────────────────────────────── */
.events-heading {
  display: flex; flex-direction: column; gap: 4px;
}

.events-title {
  font-family: ''DM Serif Display'', serif;
  font-size: var(--fs-title);
  color: var(--text-1);
  letter-spacing: -0.02em; line-height: 1.1;
}

.events-grid {
  display: flex; gap: var(--sp-md);
}

.event-card {
  display: flex; flex-direction: column;
  gap: var(--sp-sm);
  background: var(--bg-card);
  border: 1px solid var(--border);
  border-left: 3px solid var(--accent);
  border-radius: var(--r-lg);
  padding: var(--sp-lg);
  min-width: 320px; max-width: 440px;
  flex: 1;
}

.event-dateline {
  display: flex; align-items: center;
  gap: var(--sp-sm);
}

.event-date {
  font-family: ''DM Mono'', monospace;
  font-size: var(--fs-label);
  font-weight: 500;
  color: var(--accent);
  letter-spacing: 0.06em;
  text-transform: uppercase;
}

.event-time {
  font-family: ''DM Mono'', monospace;
  font-size: var(--fs-label);
  color: var(--text-3);
}

.event-name {
  font-family: ''DM Serif Display'', serif;
  font-size: var(--fs-heading);
  color: var(--text-1);
  letter-spacing: -0.01em; line-height: 1.2;
}

.event-loc {
  font-size: var(--fs-label);
  font-weight: 500;
  color: var(--text-2);
  letter-spacing: 0.04em;
}

.event-desc {
  font-size: var(--fs-body);
  color: var(--text-2);
  font-weight: 300; line-height: 1.55;
}

.events-footer-text {
  font-size: var(--fs-label);
  color: var(--text-3); letter-spacing: 0.04em;
}
.events-footer-text strong { color: var(--text-2); font-weight: 500; }

.events-empty {
  font-size: var(--fs-body);
  color: var(--text-3); font-style: italic;
  padding: var(--sp-md) 0;
}

/* ── Panel: Property (ambient) ────────────────────────────────────────────── */
#panel-property {
  align-items: flex-end; justify-content: flex-start;
  padding: 0 var(--sp-xl) calc(var(--ticker-h) + var(--sp-lg)) var(--sp-xl);
}

.property-caption {
  display: flex; flex-direction: column; gap: 6px;
  background: var(--bg-card);
  border: 1px solid var(--border);
  border-radius: var(--r-md);
  padding: var(--sp-md) var(--sp-lg);
  width: fit-content;
}

.property-cap-name {
  font-family: ''DM Serif Display'', serif;
  font-size: var(--fs-heading);
  color: var(--text-1);
  letter-spacing: -0.01em;
}

.property-cap-addr {
  font-size: var(--fs-label);
  color: var(--text-2);
  letter-spacing: 0.06em;
}

/* ── Settings gear trigger ────────────────────────────────────────────────── */
#settings-trigger {
  position: fixed;
  bottom: calc(var(--ticker-h) + 14px);
  right: 20px;
  z-index: 300;
  width: 42px; height: 42px;
  border-radius: 50%;
  background: var(--bg-card);
  border: 1px solid var(--border);
  color: var(--text-3);
  display: flex; align-items: center; justify-content: center;
  cursor: pointer;
  opacity: 0;
  transition: opacity var(--t-fast), color var(--t-fast), border-color var(--t-fast);
  backdrop-filter: blur(8px);
  -webkit-backdrop-filter: blur(8px);
}

body:hover #settings-trigger { opacity: 0.45; }
#settings-trigger:hover {
  opacity: 1 !important;
  color: var(--accent);
  border-color: var(--accent-border);
}

/* ── Settings overlay ─────────────────────────────────────────────────────── */
#settings-overlay {
  position: fixed; inset: 0;
  z-index: 500;
  display: flex; align-items: center; justify-content: center;
}
#settings-overlay.hidden { display: none; }

.settings-backdrop {
  position: absolute; inset: 0;
  background: rgba(0,0,0,0.55);
  backdrop-filter: blur(10px);
  -webkit-backdrop-filter: blur(10px);
}

.settings-sheet {
  position: relative; z-index: 1;
  background: var(--bg-card);
  border: 1px solid var(--border-md);
  border-radius: var(--r-xl);
  width: 520px;
  max-height: 82vh;
  overflow-y: auto;
  box-shadow: 0 40px 100px rgba(0,0,0,0.45);
}

.settings-head {
  display: flex; align-items: center;
  justify-content: space-between;
  padding: var(--sp-md) var(--sp-lg);
  border-bottom: 1px solid var(--border);
  position: sticky; top: 0;
  background: var(--bg-card);
  z-index: 2;
}

.settings-head-title {
  font-family: ''DM Serif Display'', serif;
  font-size: 24px; color: var(--text-1);
}

.settings-x {
  background: none; border: none; cursor: pointer;
  color: var(--text-3); font-size: 18px;
  width: 34px; height: 34px;
  border-radius: var(--r-sm);
  display: flex; align-items: center; justify-content: center;
  transition: color var(--t-fast), background var(--t-fast);
}
.settings-x:hover { color: var(--text-1); background: var(--border); }

/* PIN gate */
#pin-gate {
  padding: var(--sp-lg) var(--sp-lg) var(--sp-xl);
  display: flex; flex-direction: column;
  align-items: center; gap: var(--sp-md);
}

.pin-prompt {
  font-size: var(--fs-body); color: var(--text-2);
}

.pin-dots {
  display: flex; gap: var(--sp-md);
}

.pin-dot {
  width: 13px; height: 13px; border-radius: 50%;
  background: var(--border-md);
  transition: background var(--t-fast);
}
.pin-dot.on { background: var(--accent); }

.pin-pad {
  display: grid; grid-template-columns: repeat(3, 1fr);
  gap: var(--sp-xs); width: 236px;
}

.pin-key {
  height: 58px;
  border: 1px solid var(--border);
  border-radius: var(--r-md);
  background: var(--bg-panel);
  color: var(--text-1);
  font-family: ''DM Mono'', monospace;
  font-size: 22px; font-weight: 500;
  cursor: pointer;
  transition: background var(--t-fast), border-color var(--t-fast);
}
.pin-key:hover  { background: var(--bg-card); border-color: var(--border-md); }
.pin-key:active { background: var(--accent-dim); }

.pin-action { color: var(--text-2); font-size: 17px; }
.pin-enter  { background: var(--accent-dim); border-color: var(--accent-border); color: var(--accent); }

.pin-err {
  font-size: var(--fs-label); color: #e05252;
}
.pin-err.hidden { display: none; }

/* Settings sections */
#settings-body { padding: var(--sp-xs) 0 var(--sp-lg); }
#settings-body.hidden { display: none; }

.s-section {
  padding: var(--sp-md) var(--sp-lg);
  border-bottom: 1px solid var(--border);
}
.s-section:last-child { border-bottom: none; }

.s-section-title {
  font-size: var(--fs-label);
  font-weight: 600; letter-spacing: 0.1em;
  text-transform: uppercase;
  color: var(--accent);
  margin-bottom: var(--sp-md);
}

.s-row {
  display: flex; align-items: center;
  justify-content: space-between;
  gap: var(--sp-md); padding: 9px 0;
}

.s-label {
  font-size: 15px; color: var(--text-2); font-weight: 400;
}

/* Theme picker — 3 swatches */
.theme-picker {
  display: flex; gap: 8px;
}

.theme-swatch {
  width: 34px; height: 34px;
  border-radius: 50%;
  border: 2px solid transparent;
  cursor: pointer;
  transition: border-color var(--t-fast), transform var(--t-fast);
  position: relative;
}
.theme-swatch:hover { transform: scale(1.1); }
.theme-swatch.active { border-color: var(--accent); }
.theme-swatch[data-theme="obsidian"] { background: #0B0F12; box-shadow: 0 0 0 1px rgba(255,255,255,0.15); }
.theme-swatch[data-theme="stone"]    { background: #EDE8DF; box-shadow: 0 0 0 1px rgba(0,0,0,0.12); }
.theme-swatch[data-theme="navy"]     { background: #0D1923; box-shadow: 0 0 0 1px rgba(152,192,218,0.2); }

.theme-swatch-label {
  position: absolute; bottom: -18px; left: 50%;
  transform: translateX(-50%);
  font-size: 10px; white-space: nowrap;
  color: var(--text-3);
}

.s-select {
  background: var(--bg-input);
  border: 1px solid var(--border-md);
  border-radius: var(--r-sm);
  color: var(--text-1);
  font-family: ''Inter'', sans-serif;
  font-size: 15px; padding: 8px 12px;
  outline: none; cursor: pointer;
}
.s-select:focus { border-color: var(--accent); }

.s-input {
  background: var(--bg-input);
  border: 1px solid var(--border-md);
  border-radius: var(--r-sm);
  color: var(--text-1);
  font-family: ''DM Mono'', monospace;
  font-size: 15px; padding: 8px 12px;
  outline: none; width: 110px;
}
.s-input:focus { border-color: var(--accent); }
.s-input-wide { width: 100%; flex: 1; }

.s-hint {
  font-size: 12px; color: var(--text-3);
  margin-top: 6px; line-height: 1.5;
}

/* Toggle switch */
.s-switch { position: relative; cursor: pointer; }
.s-switch input { opacity: 0; width: 0; height: 0; position: absolute; }
.s-track {
  display: block; width: 44px; height: 24px;
  border-radius: 12px; background: var(--border-md);
  transition: background var(--t-fast);
  position: relative;
}
.s-track::after {
  content: '''';
  position: absolute; top: 3px; left: 3px;
  width: 18px; height: 18px; border-radius: 50%;
  background: var(--text-3);
  transition: transform var(--t-fast), background var(--t-fast);
}
.s-switch input:checked + .s-track { background: var(--accent-dim); border: 1px solid var(--accent-border); }
.s-switch input:checked + .s-track::after { transform: translateX(20px); background: var(--accent); }

/* Text inputs group (Edit Building Info) */
.s-text-group {
  display: flex; flex-direction: column; gap: var(--sp-xs); width: 100%;
}
.s-text-row {
  display: flex; align-items: center; gap: var(--sp-sm);
}
.s-text-label {
  font-size: 13px; color: var(--text-3);
  min-width: 110px; font-weight: 500;
  letter-spacing: 0.04em;
}

/* Buttons */
.s-actions {
  padding: var(--sp-md) var(--sp-lg) 0;
  display: flex; gap: var(--sp-sm);
}

.s-btn {
  padding: 10px 20px;
  border: 1px solid var(--border-md);
  border-radius: var(--r-sm);
  background: var(--bg-panel);
  color: var(--text-2);
  font-family: ''Inter'', sans-serif;
  font-size: 15px; cursor: pointer;
  transition: all var(--t-fast);
}
.s-btn:hover { border-color: var(--accent-border); color: var(--text-1); }

.s-btn-primary {
  background: var(--accent-dim);
  border-color: var(--accent-border);
  color: var(--accent);
}
.s-btn-primary:hover { background: var(--accent); color: var(--bg); border-color: var(--accent); }

.s-btn-danger:hover { border-color: rgba(224,82,82,0.4); color: #e05252; }

.s-btn-inline {
  padding: 7px 14px; font-size: 13px;
}

/* Scrollbar */
.settings-sheet::-webkit-scrollbar { width: 5px; }
.settings-sheet::-webkit-scrollbar-track { background: transparent; }
.settings-sheet::-webkit-scrollbar-thumb { background: var(--border-md); border-radius: 3px; }

/* ── Sleep Screen ─────────────────────────────────────────────────────────── */
#sleep-screen {
  position: fixed; inset: 0; z-index: 900;
  background: var(--sleep-bg);
  display: flex; align-items: center; justify-content: center;
}
#sleep-screen.hidden { display: none; }

.sleep-inner {
  display: flex; flex-direction: column;
  align-items: center; gap: var(--sp-lg);
}

.sleep-mark {
  width: 56px; height: 56px; border-radius: 50%;
  border: 1px solid var(--sleep-text);
  opacity: 0.5;
}

.sleep-time {
  font-family: ''DM Mono'', monospace;
  font-size: 68px; font-weight: 400;
  color: var(--sleep-text);
  letter-spacing: -0.05em;
}

/* ── Utilities ────────────────────────────────────────────────────────────── */
.hidden { display: none !important; }

/* Panel fade-in animation on activate */
@keyframes panelIn {
  from { opacity: 0; transform: translateY(10px); }
  to   { opacity: 1; transform: translateY(0); }
}
.panel.active .panel-inner {
  animation: panelIn var(--t-mid) var(--ease) both;
}

/* Reduce motion */
@media (prefers-reduced-motion: reduce) {
  .bg-slide.active { animation: none; }
  .panel.active .panel-inner { animation: none; }
}

/* ── Responsive fallback (non-4K screens) ─────────────────────────────────── */
@media (max-width: 1400px) {
  :root {
    --fs-hero:    clamp(72px, 9vw, 120px);
    --fs-display: clamp(38px, 4.5vw, 62px);
    --fs-title:   clamp(28px, 3.2vw, 44px);
    --fs-heading: clamp(20px, 2.4vw, 32px);
    --fs-body:    clamp(16px, 1.9vw, 24px);
    --fs-label:   clamp(12px, 1.3vw, 17px);
    --hud-h:      64px;
    --ticker-h:   46px;
  }
  #hud { padding: 0 var(--sp-md); }
  .panel-inner { padding: var(--sp-lg) var(--sp-lg); }
  #panel-property { padding: 0 var(--sp-lg) calc(var(--ticker-h) + var(--sp-md)) var(--sp-lg); }
}

'@
Write-Host '  Written: css/styles.css' -ForegroundColor Green
Set-Content -Path 'js/config.js' -Encoding UTF8 -Value @'
// =============================================================================
// WATERFRONT LOBBY DISPLAY v2 — CONFIG
// =============================================================================
// This is the ONLY file you need to edit for ownership transfer or rebranding.
// All property info, Sheet IDs, GIDs, and constants live here.
// =============================================================================

const CONFIG = {

  // ── Property Info (shown on screen) ────────────────────────────────────────
  PROPERTY: {
    name:       ''The Waterfront'',
    subtitle:   ''at Catalina Landing'',
    address:    ''310 – 340 Golden Shore  ·  Long Beach, CA 90802'',
    phone:      ''(424) 477-3816'',
    email:      ''lobby@ticapital.com'',
    managed_by: ''TI Capital'',
  },

  // ── Buildings ───────────────────────────────────────────────────────────────
  BUILDINGS: {
    ''310'': ''310 Golden Shore'',
    ''320'': ''320 Golden Shore'',
    ''330'': ''330 Golden Shore'',
    ''340'': ''340 Golden Shore'',
  },

  // ── Google Sheet ────────────────────────────────────────────────────────────
  // To transfer ownership: update SHEET_ID to the new sheet''s ID.
  // GIDs are found in the tab URL: ...spreadsheets/d/SHEET_ID/edit#gid=GID
  SHEET_ID: ''17Uze4Qz_0cXsnj4KS4cFmabK67F_jGG0PR_vtnegrK4'',

  GIDS: {
    directory_310: ''1001'',        // ← update after creating tab
    directory_320: ''1002'',        // ← update after creating tab
    directory_330: ''1003'',        // ← update after creating tab
    directory_340: ''1004'',        // ← update after creating tab
    events:        ''871114333'',   // existing Events tab
    backgrounds:   ''589321751'',   // existing Backgrounds tab
  },

  // ── Weather (Open-Meteo, free, no key needed) ───────────────────────────────
  WEATHER: {
    lat:      33.7701,
    lon:      -118.1937,
    timezone: ''America/Los_Angeles'',
    units:    ''fahrenheit'',
    wind:     ''mph'',
  },

  // ── Timing (milliseconds) ───────────────────────────────────────────────────
  TIMING: {
    weather_refresh:  10 * 60 * 1000,   // 10 min
    sheet_refresh:    10 * 60 * 1000,   // 10 min
    panel_weather:    13 * 1000,
    panel_directory:  16 * 1000,
    panel_events:     14 * 1000,
    panel_property:   11 * 1000,
    bg_crossfade:     12 * 1000,        // photo change interval
  },

  // ── App defaults ────────────────────────────────────────────────────────────
  DEFAULTS: {
    theme:        ''obsidian'',   // obsidian | stone | navy
    building:     ''310'',
    pin:          ''0000'',
    show_events:  true,
    show_property:true,
    sleep_time:   ''22:00'',
    wake_time:    ''07:00'',
    theme_mode:   ''manual'',     // manual | auto
  },

  // ── Fallback directory (if Sheet unreachable) ───────────────────────────────
  FALLBACK_DIRECTORY: {
    ''310'': [
      { tenant: ''Catalina Express'',    suite: ''Ground Floor'' },
      { tenant: ''TI Capital'',          suite: ''Suite 100''    },
      { tenant: ''NRE Commercial'',      suite: ''Suite 200''    },
    ],
    ''320'': [{ tenant: ''Leasing Available'', suite: ''Contact Leasing Office'' }],
    ''330'': [{ tenant: ''Leasing Available'', suite: ''Contact Leasing Office'' }],
    ''340'': [{ tenant: ''Leasing Available'', suite: ''Contact Leasing Office'' }],
  },

  // ── Fallback events ─────────────────────────────────────────────────────────
  FALLBACK_EVENTS: [
    {
      title:    ''Campus Open House'',
      date_str: ''Date TBD'',
      time:     '''',
      location: ''The Waterfront at Catalina Landing'',
      desc:     ''Meet our leasing team and tour available spaces.'',
    },
  ],

  // ── Fallback background photos ──────────────────────────────────────────────
  FALLBACK_PHOTOS: [
    ''https://i0.wp.com/hollywoodlocations.com/wp-content/uploads/2023/01/the-waterfront-at-catalina-landing-long-beach-010.jpg'',
    ''https://i0.wp.com/hollywoodlocations.com/wp-content/uploads/2023/01/the-waterfront-at-catalina-landing-long-beach-004.jpg'',
    ''https://i0.wp.com/hollywoodlocations.com/wp-content/uploads/2023/01/the-waterfront-at-catalina-landing-long-beach-007.jpg'',
    ''https://i0.wp.com/hollywoodlocations.com/wp-content/uploads/2023/01/the-waterfront-at-catalina-landing-long-beach-002.jpg'',
    ''https://i0.wp.com/hollywoodlocations.com/wp-content/uploads/2023/01/the-waterfront-at-catalina-landing-long-beach-015.jpg'',
  ],

};

// =============================================================================
// UTILITIES — shared across all modules
// =============================================================================

/** Fetch a Sheet tab as parsed CSV rows (array of header-keyed objects) */
async function sheetFetch(gid, timeoutMs = 8000) {
  const url = `https://docs.google.com/spreadsheets/d/${CONFIG.SHEET_ID}/export?format=csv&gid=${gid}`;
  const ctrl = new AbortController();
  const t    = setTimeout(() => ctrl.abort(), timeoutMs);
  try {
    const res  = await fetch(url, { signal: ctrl.signal, cache: ''no-store'' });
    clearTimeout(t);
    if (!res.ok) throw new Error(`HTTP ${res.status}`);
    return csvParse(await res.text());
  } catch (e) {
    clearTimeout(t);
    console.warn(`[sheet] GID ${gid} failed:`, e.message);
    return null;
  }
}

/** Parse CSV text → array of objects keyed by lowercase trimmed headers */
function csvParse(text) {
  const lines = text.trim().split(''\n'').map(l => l.trim()).filter(Boolean);
  if (lines.length < 2) return [];
  const heads = csvSplit(lines[0]).map(h => h.trim().toLowerCase());
  return lines.slice(1).map(line => {
    const vals = csvSplit(line);
    const row  = {};
    heads.forEach((h, i) => { row[h] = (vals[i] ?? '''').trim(); });
    return row;
  }).filter(r => Object.values(r).some(v => v));
}

/** Split one CSV line respecting quoted commas */
function csvSplit(line) {
  const out = []; let cur = '''', q = false;
  for (const c of line) {
    if (c === ''"'') { q = !q; continue; }
    if (c === '','' && !q) { out.push(cur); cur = ''''; continue; }
    cur += c;
  }
  out.push(cur);
  return out;
}

/** localStorage wrapper with JSON + error handling */
const Store = {
  get: (k, fb = null) => { try { const v = localStorage.getItem(k); return v !== null ? JSON.parse(v) : fb; } catch { return fb; } },
  set: (k, v)         => { try { localStorage.setItem(k, JSON.stringify(v)); } catch {} },
  del: (k)            => { try { localStorage.removeItem(k); } catch {} },
};

/** Format a date string for display e.g. "Mon, Jun 9" */
function fmtDate(str) {
  if (!str) return '''';
  const d = new Date(str);
  if (isNaN(d)) return str;
  return d.toLocaleDateString(''en-US'', { weekday: ''short'', month: ''short'', day: ''numeric'' });
}

/** Zero-pad */
const pad = n => String(n).padStart(2, ''0'');

'@
Write-Host '  Written: js/config.js' -ForegroundColor Green
Set-Content -Path 'js/clock.js' -Encoding UTF8 -Value @'
// clock.js — live clock display in HUD and sleep screen
(function Clock() {
  ''use strict'';

  const timeEl  = document.getElementById(''clock-time'');
  const dateEl  = document.getElementById(''clock-date'');
  const sleepEl = document.getElementById(''sleep-time-display'');

  const DAYS   = [''Sunday'',''Monday'',''Tuesday'',''Wednesday'',''Thursday'',''Friday'',''Saturday''];
  const MONTHS = [''January'',''February'',''March'',''April'',''May'',''June'',
                  ''July'',''August'',''September'',''October'',''November'',''December''];

  function tick() {
    const now  = new Date();
    const h24  = now.getHours();
    const m    = pad(now.getMinutes());
    const ampm = h24 >= 12 ? ''PM'' : ''AM'';
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

'@
Write-Host '  Written: js/clock.js' -ForegroundColor Green
Set-Content -Path 'js/background.js' -Encoding UTF8 -Value @'
// background.js — property photo slideshow, Sheet-synced
(function Background() {
  ''use strict'';

  const bgA = document.getElementById(''bg-a'');
  const bgB = document.getElementById(''bg-b'');

  let photos  = [...CONFIG.FALLBACK_PHOTOS];
  let idx     = 0;
  let current = ''a'';
  let cycleId = null;

  // ── Preload an image then apply it ──────────────────────────────────────
  function preload(url) {
    return new Promise(resolve => {
      const img   = new Image();
      img.onload  = () => resolve(url);
      img.onerror = () => resolve(null);
      img.src     = url;
    });
  }

  async function crossfade(url) {
    const next = current === ''a'' ? bgB : bgA;
    const prev = current === ''a'' ? bgA : bgB;
    const ok   = await preload(url);
    if (!ok) return;                         // skip broken images silently
    next.style.backgroundImage = `url("${url}")`;
    next.classList.add(''active'');
    prev.classList.remove(''active'');
    current = current === ''a'' ? ''b'' : ''a'';
  }

  function advance() {
    idx = (idx + 1) % (photos.length || 1);
    if (photos[idx]) crossfade(photos[idx]);
  }

  function startCycle() {
    if (cycleId) clearInterval(cycleId);
    cycleId = setInterval(advance, CONFIG.TIMING.bg_crossfade);
  }

  // ── Sheet sync ───────────────────────────────────────────────────────────
  async function syncSheet() {
    const rows = await sheetFetch(CONFIG.GIDS.backgrounds);
    if (!rows) return;

    const urls = rows
      .filter(r => {
        const a = (r[''active''] || r[''Active''] || '''').toString().toUpperCase();
        return a === ''TRUE'' || a === ''YES'' || a === ''1'';
      })
      .map(r => r[''url''] || r[''URL''] || r[''link''] || '''')
      .filter(u => u.startsWith(''http''));

    if (urls.length > 0) {
      photos = urls;
      Store.set(''wf_photos'', photos);
    }
  }

  // ── Boot ─────────────────────────────────────────────────────────────────
  const cached = Store.get(''wf_photos'');
  if (cached?.length) photos = cached;

  // Show first photo immediately
  if (photos[0]) crossfade(photos[0]);
  startCycle();
  syncSheet();
  setInterval(syncSheet, CONFIG.TIMING.sheet_refresh);

  // ── Expose ────────────────────────────────────────────────────────────────
  window.BG = { startCycle, stop: () => clearInterval(cycleId) };
})();

'@
Write-Host '  Written: js/background.js' -ForegroundColor Green
Set-Content -Path 'js/weather.js' -Encoding UTF8 -Value @'
// weather.js — Open-Meteo fetch, panel + ticker render
(function Weather() {
  ''use strict'';

  // WMO weather code → description
  const WMO_DESC = {
    0:''Clear Sky'', 1:''Mostly Clear'', 2:''Partly Cloudy'', 3:''Overcast'',
    45:''Foggy'', 48:''Freezing Fog'',
    51:''Light Drizzle'', 53:''Drizzle'', 55:''Heavy Drizzle'',
    56:''Freezing Drizzle'', 57:''Heavy Freezing Drizzle'',
    61:''Light Rain'', 63:''Rain'', 65:''Heavy Rain'',
    66:''Freezing Rain'', 67:''Heavy Freezing Rain'',
    71:''Light Snow'', 73:''Snow'', 75:''Heavy Snow'', 77:''Snow Grains'',
    80:''Rain Showers'', 81:''Showers'', 82:''Heavy Showers'',
    85:''Snow Showers'', 86:''Heavy Snow Showers'',
    95:''Thunderstorm'', 96:''Thunderstorm w/ Hail'', 99:''Heavy Thunderstorm'',
  };

  // WMO → icon character (text, no emoji for commercial displays)
  const WMO_ICON = {
    0:''☀'', 1:''🌤'', 2:''⛅'', 3:''☁'',
    45:''🌫'', 48:''🌫'',
    51:''🌦'', 53:''🌧'', 55:''🌧'', 56:''🌧'', 57:''🌧'',
    61:''🌦'', 63:''🌧'', 65:''🌧'', 66:''🌧'', 67:''🌧'',
    71:''🌨'', 73:''❄'', 75:''❄'', 77:''❄'',
    80:''🌦'', 81:''🌧'', 82:''⛈'',
    85:''🌨'', 86:''❄'',
    95:''⛈'', 96:''⛈'', 99:''⛈'',
  };

  const DAYS_S = [''Sun'',''Mon'',''Tue'',''Wed'',''Thu'',''Fri'',''Sat''];

  // DOM refs
  const tempEl   = document.getElementById(''w-temp'');
  const condEl   = document.getElementById(''w-condition'');
  const feelsEl  = document.getElementById(''w-feels'');
  const humidEl  = document.getElementById(''w-humidity'');
  const windEl   = document.getElementById(''w-wind'');
  const uvEl     = document.getElementById(''w-uv'');
  const fcEl     = document.getElementById(''w-forecast'');
  const tkTemp   = document.getElementById(''ticker-temp'');
  const tkCond   = document.getElementById(''ticker-cond'');

  // ── Build weather URL ────────────────────────────────────────────────────
  const WEATHER_URL = [
    ''https://api.open-meteo.com/v1/forecast'',
    `?latitude=${CONFIG.WEATHER.lat}`,
    `&longitude=${CONFIG.WEATHER.lon}`,
    ''&current=temperature_2m,apparent_temperature,relative_humidity_2m,wind_speed_10m,weather_code,uv_index'',
    ''&daily=weather_code,temperature_2m_max,temperature_2m_min'',
    `&temperature_unit=${CONFIG.WEATHER.units}`,
    `&wind_speed_unit=${CONFIG.WEATHER.wind}`,
    `&timezone=${encodeURIComponent(CONFIG.WEATHER.timezone)}`,
    ''&forecast_days=5'',
  ].join('''');

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
      Store.set(''wf_weather_cache'', { data, ts: Date.now() });
    } catch (e) {
      console.warn(''[weather] fetch failed:'', e.message, `retry in ${delay/1000}s`);
      setTimeout(() => fetchWeather(Math.min(delay * 2, 120000)), delay);
    }
  }

  // ── Render ────────────────────────────────────────────────────────────────
  function render(data) {
    const c    = data.current;
    const d    = data.daily;
    const code = c.weather_code;
    const temp = Math.round(c.temperature_2m);
    const desc = WMO_DESC[code] || ''Clear'';

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
          const icon = WMO_ICON[d.weather_code[i]] || ''—'';
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
        }).join('''');
    }
  }

  // ── Load cached data immediately (offline resilience) ───────────────────
  const cached = Store.get(''wf_weather_cache'');
  if (cached?.data) {
    const age = (Date.now() - cached.ts) / 60000;
    if (age < 120) render(cached.data);   // use cache up to 2 hrs old
  }

  // ── Boot ─────────────────────────────────────────────────────────────────
  fetchWeather();
  setInterval(fetchWeather, CONFIG.TIMING.weather_refresh);
})();

'@
Write-Host '  Written: js/weather.js' -ForegroundColor Green
Set-Content -Path 'js/directory.js' -Encoding UTF8 -Value @'
// directory.js — per-building directory, Sheet-synced
(function Directory() {
  ''use strict'';

  const listEl   = document.getElementById(''dir-list'');
  const labelEl  = document.getElementById(''dir-building-name'');
  const phoneEl  = document.getElementById(''dir-phone'');

  let currentBuilding = Store.get(''wf_building'', CONFIG.DEFAULTS.building);

  // GID map
  const GID_MAP = {
    ''310'': CONFIG.GIDS.directory_310,
    ''320'': CONFIG.GIDS.directory_320,
    ''330'': CONFIG.GIDS.directory_330,
    ''340'': CONFIG.GIDS.directory_340,
  };

  // ── Render ────────────────────────────────────────────────────────────────
  function render(entries) {
    if (!listEl) return;
    if (!entries?.length) {
      listEl.innerHTML = ''<div class="dir-empty">No directory entries found.</div>'';
      return;
    }
    listEl.innerHTML = entries.map(e => `
      <div class="dir-row" role="listitem">
        <span class="dir-tenant">${e.tenant}</span>
        <span class="dir-suite">${e.suite}</span>
      </div>`).join('''');
  }

  // ── Load for a building ───────────────────────────────────────────────────
  async function load(building) {
    currentBuilding = building;

    // Update label
    if (labelEl) labelEl.textContent = CONFIG.BUILDINGS[building] || `${building} Golden Shore`;

    // Update phone from stored info
    const phone = Store.get(''wf_info_phone'', CONFIG.PROPERTY.phone);
    if (phoneEl) phoneEl.textContent = phone;

    // Try cache first for instant display
    const cached = Store.get(`wf_dir_${building}`);
    if (cached?.length) render(cached);

    // Fetch from Sheet
    const gid  = GID_MAP[building];
    if (!gid) { render(CONFIG.FALLBACK_DIRECTORY[building] || []); return; }

    const rows = await sheetFetch(gid);
    if (!rows?.length) {
      // Use fallback if no cache
      if (!cached?.length) render(CONFIG.FALLBACK_DIRECTORY[building] || []);
      return;
    }

    // Flexible column name matching
    const entries = rows.map(r => ({
      tenant: r[''tenant''] || r[''name''] || r[''company''] || r[''tenant name''] || '''',
      suite:  r[''suite'']  || r[''floor''] || r[''unit'']  || r[''suite number''] || r[''suite/floor''] || '''',
    })).filter(e => e.tenant);

    render(entries);
    Store.set(`wf_dir_${building}`, entries);
  }

  // ── Public API ─────────────────────────────────────────────────────────────
  window.Directory = {
    load,
    setBuilding: b => load(b),
    refresh:     () => load(currentBuilding),
  };

  // ── Boot ──────────────────────────────────────────────────────────────────
  load(currentBuilding);
  setInterval(() => load(currentBuilding), CONFIG.TIMING.sheet_refresh);
})();

'@
Write-Host '  Written: js/directory.js' -ForegroundColor Green
Set-Content -Path 'js/events.js' -Encoding UTF8 -Value @'
// events.js — events panel, Sheet-synced
(function Events() {
  ''use strict'';

  const gridEl   = document.getElementById(''events-grid'');
  const emailEl  = document.getElementById(''events-email'');

  // ── Render ────────────────────────────────────────────────────────────────
  function render(events) {
    if (!gridEl) return;

    // Update footer email from stored info
    const email = Store.get(''wf_info_email'', CONFIG.PROPERTY.email);
    if (emailEl) emailEl.textContent = email;

    if (!events?.length) {
      gridEl.innerHTML = ''<div class="events-empty">No upcoming events scheduled.</div>'';
      return;
    }

    gridEl.innerHTML = events.slice(0, 3).map(e => `
      <div class="event-card" role="listitem">
        <div class="event-dateline">
          <span class="event-date">${e.date_str}</span>
          ${e.time ? `<span class="event-time">${e.time}</span>` : ''''}
        </div>
        <div class="event-name">${e.title}</div>
        ${e.location ? `<div class="event-loc">${e.location}</div>` : ''''}
        ${e.desc     ? `<div class="event-desc">${e.desc}</div>`    : ''''}
      </div>`).join('''');
  }

  // ── Parse Sheet rows ──────────────────────────────────────────────────────
  function parse(rows) {
    return rows
      .filter(r => {
        // Active column: TRUE / YES / 1 / empty (blank = active)
        const a = (r[''active''] || r[''Active''] || '''').toString().toUpperCase();
        return a === ''TRUE'' || a === ''YES'' || a === ''1'' || a === '''';
      })
      .map(r => ({
        title:    r[''title'']       || r[''event'']       || r[''event title''] || '''',
        date_str: fmtDate(r[''date''] || r[''Date''] || r[''event date''] || ''''),
        time:     r[''time'']        || r[''Time'']        || r[''event time'']  || '''',
        location: r[''location'']    || r[''Location'']    || r[''venue'']       || '''',
        desc:     r[''description''] || r[''Description''] || r[''desc'']        || r[''details''] || '''',
        priority: parseInt(r[''priority''] || r[''Priority''] || r[''rank''] || r[''Rank''] || ''99'', 10),
      }))
      .filter(e => e.title)
      .sort((a, b) => a.priority - b.priority);
  }

  // ── Fetch & sync ──────────────────────────────────────────────────────────
  async function refresh() {
    const rows = await sheetFetch(CONFIG.GIDS.events);

    if (rows?.length) {
      const events = parse(rows);
      render(events);
      Store.set(''wf_events'', events);
    } else {
      const cached = Store.get(''wf_events'');
      render(cached?.length ? cached : CONFIG.FALLBACK_EVENTS);
    }
  }

  // ── Boot ──────────────────────────────────────────────────────────────────
  const cached = Store.get(''wf_events'');
  if (cached?.length) render(cached);

  refresh();
  setInterval(refresh, CONFIG.TIMING.sheet_refresh);

  window.EventsPanel = { refresh };
})();

'@
Write-Host '  Written: js/events.js' -ForegroundColor Green
Set-Content -Path 'js/settings.js' -Encoding UTF8 -Value @'
// settings.js — PIN, themes, building, schedule, panel toggles, building info
(function Settings() {
  ''use strict'';

  // ── State (all from localStorage with defaults) ──────────────────────────
  let pin        = Store.get(''wf_pin'',         CONFIG.DEFAULTS.pin);
  let building   = Store.get(''wf_building'',    CONFIG.DEFAULTS.building);
  let theme      = Store.get(''wf_theme'',       CONFIG.DEFAULTS.theme);
  let themeMode  = Store.get(''wf_theme_mode'',  CONFIG.DEFAULTS.theme_mode);
  let dayTheme   = Store.get(''wf_day_theme'',   ''stone'');
  let nightTheme = Store.get(''wf_night_theme'', ''obsidian'');
  let wakeTime   = Store.get(''wf_wake'',        CONFIG.DEFAULTS.sleep_time);
  let sleepTime  = Store.get(''wf_sleep'',       CONFIG.DEFAULTS.wake_time);
  let showEvents = Store.get(''wf_show_events'', CONFIG.DEFAULTS.show_events);
  let showProp   = Store.get(''wf_show_property'', CONFIG.DEFAULTS.show_property);

  // Building info (editable on screen)
  let infoLogoName = Store.get(''wf_info_logo_name'', CONFIG.PROPERTY.name);
  let infoLogoSub  = Store.get(''wf_info_logo_sub'',  CONFIG.PROPERTY.subtitle);
  let infoPhone    = Store.get(''wf_info_phone'',      CONFIG.PROPERTY.phone);
  let infoEmail    = Store.get(''wf_info_email'',      CONFIG.PROPERTY.email);
  let infoAddr     = Store.get(''wf_info_addr'',       CONFIG.PROPERTY.address);

  let pinBuffer = '''';
  let unlocked  = false;

  // ── DOM refs ──────────────────────────────────────────────────────────────
  const overlay     = document.getElementById(''settings-overlay'');
  const trigger     = document.getElementById(''settings-trigger'');
  const closeBtn    = document.getElementById(''settings-close'');
  const backdrop    = document.getElementById(''settings-backdrop'');
  const pinGate     = document.getElementById(''pin-gate'');
  const pinDots     = document.querySelectorAll(''.pin-dot'');
  const pinErr      = document.getElementById(''pin-err'');
  const body        = document.getElementById(''settings-body'');
  const sleepScreen = document.getElementById(''sleep-screen'');

  // Settings form refs
  const sBldg       = document.getElementById(''s-building'');
  const sThemeMode  = document.getElementById(''s-theme-mode'');
  const sSchedule   = document.getElementById(''schedule-section'');
  const sDayTheme   = document.getElementById(''s-day-theme'');
  const sNightTheme = document.getElementById(''s-night-theme'');
  const sWake       = document.getElementById(''s-wake'');
  const sSleep      = document.getElementById(''s-sleep'');
  const sShowEv     = document.getElementById(''s-show-events'');
  const sShowPr     = document.getElementById(''s-show-property'');
  const sNewPin     = document.getElementById(''s-new-pin'');
  const sSavePin    = document.getElementById(''s-save-pin-btn'');
  const sSave       = document.getElementById(''s-save'');
  const sReset      = document.getElementById(''s-reset'');

  // Building info refs
  const iLogoName = document.getElementById(''info-logo-name'');
  const iLogoSub  = document.getElementById(''info-logo-sub'');
  const iPhone    = document.getElementById(''info-phone'');
  const iEmail    = document.getElementById(''info-email'');
  const iAddr     = document.getElementById(''info-addr'');

  // ── Apply theme ───────────────────────────────────────────────────────────
  function applyTheme(t) {
    document.documentElement.setAttribute(''data-theme'', t);
  }

  function resolveAutoTheme() {
    const now  = new Date();
    const hm   = now.getHours() * 60 + now.getMinutes();
    const [wh, wm] = (wakeTime  || ''07:00'').split('':'').map(Number);
    const [sh, sm] = (sleepTime || ''20:00'').split('':'').map(Number);
    const wakeM  = wh * 60 + wm;
    const sleepM = sh * 60 + sm;
    const isDay  = hm >= wakeM && hm < sleepM;
    return isDay ? (dayTheme || ''stone'') : (nightTheme || ''obsidian'');
  }

  function applyCurrentTheme() {
    if (themeMode === ''auto'') {
      applyTheme(resolveAutoTheme());
    } else {
      applyTheme(theme);
    }
  }

  // Run every minute to catch schedule transitions
  applyCurrentTheme();
  setInterval(applyCurrentTheme, 60000);

  // ── Apply building ─────────────────────────────────────────────────────────
  function applyBuilding(b) {
    document.documentElement.setAttribute(''data-building'', b);
    if (window.Directory) Directory.setBuilding(b);
  }

  // ── Apply panel visibility ─────────────────────────────────────────────────
  function applyPanelVisibility() {
    const evDot  = document.querySelector(''.nav-dot[data-panel="events"]'');
    const prDot  = document.querySelector(''.nav-dot[data-panel="property"]'');
    if (evDot) evDot.style.display  = showEvents ? '''' : ''none'';
    if (prDot) prDot.style.display  = showProp   ? '''' : ''none'';
  }

  // ── Apply building info ────────────────────────────────────────────────────
  function applyBuildingInfo() {
    const logoName = document.getElementById(''logo-name'');
    const logoSub  = document.getElementById(''logo-sub'');
    const propName = document.getElementById(''prop-name'');
    const propAddr = document.getElementById(''prop-addr'');
    const dirPhone = document.getElementById(''dir-phone'');
    const evEmail  = document.getElementById(''events-email'');

    if (logoName) logoName.textContent = infoLogoName;
    if (logoSub)  logoSub.textContent  = infoLogoSub;
    if (propName) propName.textContent = `${infoLogoName} ${infoLogoSub}`.trim();
    if (propAddr) propAddr.textContent = infoAddr;
    if (dirPhone) dirPhone.textContent = infoPhone;
    if (evEmail)  evEmail.textContent  = infoEmail;
  }

  // ── Open overlay ──────────────────────────────────────────────────────────
  function openSettings() {
    overlay.classList.remove(''hidden'');
    // Reset PIN gate
    pinBuffer = ''''; unlocked = false;
    updateDots();
    pinGate.classList.remove(''hidden'');
    body.classList.add(''hidden'');
    pinErr.classList.add(''hidden'');
  }

  // ── Close overlay ─────────────────────────────────────────────────────────
  function closeSettings() {
    overlay.classList.add(''hidden'');
    unlocked = false; pinBuffer = '''';
  }

  // ── Populate form with current values ────────────────────────────────────
  function populateForm() {
    if (sBldg)        sBldg.value       = building;
    if (sThemeMode)   sThemeMode.value  = themeMode;
    if (sDayTheme)    sDayTheme.value   = dayTheme;
    if (sNightTheme)  sNightTheme.value = nightTheme;
    if (sWake)        sWake.value       = wakeTime;
    if (sSleep)       sSleep.value      = sleepTime;
    if (sShowEv)      sShowEv.checked   = showEvents;
    if (sShowPr)      sShowPr.checked   = showProp;
    if (iLogoName)    iLogoName.value   = infoLogoName;
    if (iLogoSub)     iLogoSub.value    = infoLogoSub;
    if (iPhone)       iPhone.value      = infoPhone;
    if (iEmail)       iEmail.value      = infoEmail;
    if (iAddr)        iAddr.value       = infoAddr;

    // Theme swatches
    document.querySelectorAll(''.theme-swatch'').forEach(sw => {
      sw.classList.toggle(''active'', sw.dataset.theme === theme);
    });

    // Schedule section visibility
    if (sSchedule) sSchedule.style.display = themeMode === ''auto'' ? '''' : ''none'';
  }

  // ── PIN ───────────────────────────────────────────────────────────────────
  function updateDots() {
    pinDots.forEach((d, i) => d.classList.toggle(''on'', i < pinBuffer.length));
  }

  function checkPin() {
    if (pinBuffer === pin) {
      unlocked = true;
      pinGate.classList.add(''hidden'');
      body.classList.remove(''hidden'');
      pinErr.classList.add(''hidden'');
      populateForm();
    } else {
      pinErr.classList.remove(''hidden'');
      pinBuffer = '''';
      updateDots();
    }
  }

  document.querySelectorAll(''.pin-key'').forEach(key => {
    key.addEventListener(''click'', () => {
      const d = key.dataset.d;
      const a = key.dataset.a;
      if (d !== undefined && pinBuffer.length < 4) {
        pinBuffer += d;
        updateDots();
        if (pinBuffer.length === 4) checkPin();
      }
      if (a === ''clear'') { pinBuffer = pinBuffer.slice(0, -1); updateDots(); pinErr.classList.add(''hidden''); }
      if (a === ''enter'') checkPin();
    });
  });

  // ── Theme swatches ────────────────────────────────────────────────────────
  document.querySelectorAll(''.theme-swatch'').forEach(sw => {
    sw.addEventListener(''click'', () => {
      document.querySelectorAll(''.theme-swatch'').forEach(s => s.classList.remove(''active''));
      sw.classList.add(''active'');
      theme = sw.dataset.theme;
      if (themeMode === ''manual'') applyTheme(theme);
    });
  });

  // ── Theme mode change ─────────────────────────────────────────────────────
  if (sThemeMode) {
    sThemeMode.addEventListener(''change'', () => {
      if (sSchedule) sSchedule.style.display = sThemeMode.value === ''auto'' ? '''' : ''none'';
    });
  }

  // ── Save PIN ──────────────────────────────────────────────────────────────
  if (sSavePin) {
    sSavePin.addEventListener(''click'', () => {
      const np = (sNewPin?.value || '''').trim();
      if (/^\d{4}$/.test(np)) {
        pin = np;
        Store.set(''wf_pin'', pin);
        if (sNewPin) sNewPin.value = '''';
        sSavePin.textContent = ''Saved ✓'';
        setTimeout(() => { sSavePin.textContent = ''Save''; }, 2000);
      } else {
        if (sNewPin) sNewPin.style.outline = ''1px solid #e05252'';
        setTimeout(() => { if (sNewPin) sNewPin.style.outline = ''''; }, 1500);
      }
    });
  }

  // ── Save all ──────────────────────────────────────────────────────────────
  if (sSave) {
    sSave.addEventListener(''click'', () => {
      if (!unlocked) return;

      // Read form
      building   = sBldg?.value       || building;
      themeMode  = sThemeMode?.value  || themeMode;
      dayTheme   = sDayTheme?.value   || dayTheme;
      nightTheme = sNightTheme?.value || nightTheme;
      wakeTime   = sWake?.value       || wakeTime;
      sleepTime  = sSleep?.value      || sleepTime;
      showEvents = sShowEv?.checked   ?? showEvents;
      showProp   = sShowPr?.checked   ?? showProp;

      // Building info
      infoLogoName = iLogoName?.value || infoLogoName;
      infoLogoSub  = iLogoSub?.value  || infoLogoSub;
      infoPhone    = iPhone?.value    || infoPhone;
      infoEmail    = iEmail?.value    || infoEmail;
      infoAddr     = iAddr?.value     || infoAddr;

      // Persist
      Store.set(''wf_building'',    building);
      Store.set(''wf_theme'',       theme);
      Store.set(''wf_theme_mode'',  themeMode);
      Store.set(''wf_day_theme'',   dayTheme);
      Store.set(''wf_night_theme'', nightTheme);
      Store.set(''wf_wake'',        wakeTime);
      Store.set(''wf_sleep'',       sleepTime);
      Store.set(''wf_show_events'', showEvents);
      Store.set(''wf_show_property'', showProp);
      Store.set(''wf_info_logo_name'', infoLogoName);
      Store.set(''wf_info_logo_sub'',  infoLogoSub);
      Store.set(''wf_info_phone'',     infoPhone);
      Store.set(''wf_info_email'',     infoEmail);
      Store.set(''wf_info_addr'',      infoAddr);

      // Apply
      applyCurrentTheme();
      applyBuilding(building);
      applyPanelVisibility();
      applyBuildingInfo();
      closeSettings();
    });
  }

  // ── Reset ─────────────────────────────────────────────────────────────────
  if (sReset) {
    sReset.addEventListener(''click'', () => {
      if (!confirm(''Reset all display settings to defaults? This cannot be undone.'')) return;
      localStorage.clear();
      location.reload();
    });
  }

  // ── Open / close bindings ─────────────────────────────────────────────────
  if (trigger)  trigger.addEventListener(''click'', openSettings);
  if (closeBtn) closeBtn.addEventListener(''click'', closeSettings);
  if (backdrop) backdrop.addEventListener(''click'', closeSettings);

  // ── Sleep screen ──────────────────────────────────────────────────────────
  if (sleepScreen) {
    sleepScreen.addEventListener(''click'', () => {
      // Tap to temporarily wake
      sleepScreen.classList.add(''hidden'');
      setTimeout(() => {
        if (themeMode === ''auto'') applyCurrentTheme();
      }, 60000);
    });
  }

  // ── Cursor hiding (for permanent display) ────────────────────────────────
  let cursorTimer;
  document.addEventListener(''mousemove'', () => {
    document.body.style.cursor = ''default'';
    clearTimeout(cursorTimer);
    cursorTimer = setTimeout(() => { document.body.style.cursor = ''none''; }, 3000);
  });

  // ── Boot: apply all saved settings ────────────────────────────────────────
  applyBuilding(building);
  applyPanelVisibility();
  applyBuildingInfo();

  // ── Public ────────────────────────────────────────────────────────────────
  window.AppSettings = {
    getBuilding:    () => building,
    isEventsShown:  () => showEvents,
    isPropShown:    () => showProp,
    getTheme:       () => theme,
  };
})();

'@
Write-Host '  Written: js/settings.js' -ForegroundColor Green
Set-Content -Path 'js/rotation.js' -Encoding UTF8 -Value @'
// rotation.js — panel auto-rotation, nav dot highlighting, watchdog
(function Rotation() {
  ''use strict'';

  const ALL_PANELS = [''weather'', ''directory'', ''events'', ''property''];
  let sequence     = [];
  let idx          = 0;
  let rotateTimer  = null;
  let watchdogTimer= null;
  let lastChange   = Date.now();

  // ── Build sequence based on enabled panels ──────────────────────────────
  function buildSequence() {
    return ALL_PANELS.filter(p => {
      if (p === ''events''   && window.AppSettings && !AppSettings.isEventsShown())  return false;
      if (p === ''property'' && window.AppSettings && !AppSettings.isPropShown())    return false;
      return true;
    });
  }

  // ── Activate a panel ────────────────────────────────────────────────────
  function activate(name) {
    document.querySelectorAll(''.panel'').forEach(el => {
      el.classList.toggle(''active'', el.id === `panel-${name}`);
    });
    document.querySelectorAll(''.nav-dot'').forEach(dot => {
      dot.classList.toggle(''active'', dot.dataset.panel === name);
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
    const name = sequence[idx] || ''weather'';
    const dur  = CONFIG.TIMING[`panel_${name}`] || 13000;
    rotateTimer   = setTimeout(advance, dur);
    watchdogTimer = setTimeout(advance, dur + 6000);  // safety net
  }

  // ── Manual nav dot clicks ────────────────────────────────────────────────
  document.querySelectorAll(''.nav-dot'').forEach(dot => {
    dot.addEventListener(''click'', () => {
      const name = dot.dataset.panel;
      const i    = sequence.indexOf(name);
      if (i !== -1) { idx = i; activate(name); scheduleNext(); }
    });
  });

  // ── Watchdog: detect stuck rotation ─────────────────────────────────────
  setInterval(() => {
    const elapsed = Date.now() - lastChange;
    const name    = sequence[idx] || ''weather'';
    const maxDur  = (CONFIG.TIMING[`panel_${name}`] || 13000) * 2 + 8000;
    if (elapsed > maxDur) {
      console.warn(''[watchdog] rotation stuck — forcing advance'');
      advance();
    }
  }, 10000);

  // ── Boot ─────────────────────────────────────────────────────────────────
  sequence = buildSequence();
  activate(sequence[0] || ''weather'');
  scheduleNext();

  // ── Expose ───────────────────────────────────────────────────────────────
  window.Rotation = { activate, advance };
})();

'@
Write-Host '  Written: js/rotation.js' -ForegroundColor Green
Set-Content -Path 'js/main.js' -Encoding UTF8 -Value @'
// main.js — boot sequence, TV keep-alive, 3am self-healing reload
(function Main() {
  ''use strict'';

  // ── Screen Wake Lock (prevents TV sleep) ────────────────────────────────
  let wakeLock = null;

  async function acquireWakeLock() {
    if (!(''wakeLock'' in navigator)) return;
    try {
      wakeLock = await navigator.wakeLock.request(''screen'');
      console.info(''[wake-lock] acquired'');
      wakeLock.addEventListener(''release'', () => {
        console.info(''[wake-lock] released — reacquiring'');
        setTimeout(acquireWakeLock, 5000);
      });
    } catch (e) {
      console.warn(''[wake-lock] failed:'', e.message);
      setTimeout(acquireWakeLock, 30000);
    }
  }

  // Reacquire on visibility change (tab restored)
  document.addEventListener(''visibilitychange'', () => {
    if (document.visibilityState === ''visible'') acquireWakeLock();
  });

  acquireWakeLock();

  // ── Keep-alive: activity simulation ─────────────────────────────────────
  // Updates a hidden counter every 20s — tricks some TV firmware
  // into thinking the page is active
  const ping = document.createElement(''div'');
  ping.style.cssText = ''position:fixed;opacity:0;pointer-events:none;width:1px;height:1px;'';
  ping.setAttribute(''aria-hidden'', ''true'');
  document.body.appendChild(ping);
  let pingCount = 0;
  setInterval(() => { ping.textContent = ++pingCount; }, 20000);

  // ── Keep-alive: CSS shimmer (1px movement every 25s) ────────────────────
  // Some commercial TV OSes only keep-alive if pixels are changing
  let shimmerState = false;
  setInterval(() => {
    shimmerState = !shimmerState;
    ping.style.transform = shimmerState ? ''translateX(1px)'' : ''translateX(0)'';
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
        console.info(''[lifecycle] 3am reload — uptime:'', Math.round(uptime / 60000), ''min'');
        location.reload();
      } else {
        console.info(''[lifecycle] 3am reload skipped — uptime too low'');
        schedule3amReload();   // reschedule for next night
      }
    }, ms);

    console.info(''[lifecycle] 3am reload scheduled in'', Math.round(ms / 60000), ''min'');
  })();

  // ── Service Worker registration ──────────────────────────────────────────
  if (''serviceWorker'' in navigator) {
    window.addEventListener(''load'', () => {
      navigator.serviceWorker.register(''/sw.js'')
        .then(reg => console.info(''[sw] registered:'', reg.scope))
        .catch(e  => console.warn(''[sw] registration failed:'', e));
    });
  }

  console.info(''[main] Waterfront Lobby Display v2 — boot complete'');
})();

'@
Write-Host '  Written: js/main.js' -ForegroundColor Green
Set-Content -Path 'sw.js' -Encoding UTF8 -Value @'
// sw.js — Service Worker, offline app shell caching
// IMPORTANT: bump CACHE_VERSION on every deployment that changes any file below
const CACHE_VERSION = ''wf-v2-1'';
const CACHE_NAME    = CACHE_VERSION;

const APP_SHELL = [
  ''/'',
  ''/index.html'',
  ''/css/styles.css'',
  ''/js/config.js'',
  ''/js/clock.js'',
  ''/js/background.js'',
  ''/js/weather.js'',
  ''/js/directory.js'',
  ''/js/events.js'',
  ''/js/settings.js'',
  ''/js/rotation.js'',
  ''/js/main.js'',
  ''/assets/logo.svg'',
  ''https://fonts.googleapis.com/css2?family=DM+Serif+Display:ital@0;1&family=Inter:wght@300;400;500;600&family=DM+Mono:ital,wght@0,400;0,500;1,400&display=swap'',
];

// ── Install: cache app shell ─────────────────────────────────────────────────
self.addEventListener(''install'', e => {
  e.waitUntil(
    caches.open(CACHE_NAME)
      .then(cache => cache.addAll(APP_SHELL))
      .then(() => self.skipWaiting())
  );
});

// ── Activate: remove old caches ──────────────────────────────────────────────
self.addEventListener(''activate'', e => {
  e.waitUntil(
    caches.keys().then(keys =>
      Promise.all(keys.filter(k => k !== CACHE_NAME).map(k => caches.delete(k)))
    ).then(() => self.clients.claim())
  );
});

// ── Fetch strategy ───────────────────────────────────────────────────────────
// App shell: cache-first (instant load, works offline)
// Google Sheets + Open-Meteo: network-first (live data, never cached here)
self.addEventListener(''fetch'', e => {
  const url = e.request.url;

  // Never cache: Sheet data, weather API, external images
  const isLiveData = (
    url.includes(''docs.google.com'') ||
    url.includes(''api.open-meteo.com'') ||
    url.includes(''wp.com'') ||
    url.includes(''smushcdn'') ||
    url.includes(''hollywoodlocations'')
  );

  if (isLiveData) {
    // Network-only for live data — app handles localStorage fallback
    e.respondWith(fetch(e.request).catch(() => new Response('''', { status: 503 })));
    return;
  }

  // Cache-first for app shell
  e.respondWith(
    caches.match(e.request).then(cached => {
      if (cached) return cached;
      return fetch(e.request).then(res => {
        // Cache new app shell resources
        if (res.ok && e.request.method === ''GET'') {
          const clone = res.clone();
          caches.open(CACHE_NAME).then(c => c.put(e.request, clone));
        }
        return res;
      }).catch(() => caches.match(''/index.html''));
    })
  );
});

'@
Write-Host '  Written: sw.js' -ForegroundColor Green
Set-Content -Path 'netlify.toml' -Encoding UTF8 -Value @'
[[headers]]
  for = "/*"
  [headers.values]
    X-Frame-Options = "SAMEORIGIN"
    X-Content-Type-Options = "nosniff"
    Referrer-Policy = "strict-origin-when-cross-origin"

[[headers]]
  for = "/index.html"
  [headers.values]
    Cache-Control = "no-cache, no-store, must-revalidate"

[[headers]]
  for = "/sw.js"
  [headers.values]
    Cache-Control = "no-cache, no-store, must-revalidate"

[[headers]]
  for = "/css/*"
  [headers.values]
    Cache-Control = "public, max-age=3600"

[[headers]]
  for = "/js/*"
  [headers.values]
    Cache-Control = "public, max-age=3600"

[[headers]]
  for = "/assets/*"
  [headers.values]
    Cache-Control = "public, max-age=86400"

'@
Write-Host '  Written: netlify.toml' -ForegroundColor Green
Set-Content -Path 'assets/logo.svg' -Encoding UTF8 -Value @'
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 44 44" fill="none">
  <!-- Waterfront logo placeholder — replace this file with the real logo SVG -->
  <!-- Keep viewBox="0 0 44 44" or update CSS width/height in styles.css -->
  <circle cx="22" cy="22" r="21" stroke="currentColor" stroke-opacity="0.25" stroke-width="1"/>
  <path d="M8 26 C11 22, 15 20, 19 23 C23 26, 27 24, 31 21 C33 19.5, 35 19, 36 20"
        stroke="#EEA651" stroke-width="2" stroke-linecap="round" fill="none"/>
  <path d="M8 30 C11 26, 15 24, 19 27 C23 30, 27 28, 31 25 C33 23.5, 35 23, 36 24"
        stroke="currentColor" stroke-opacity="0.4" stroke-width="1.5" stroke-linecap="round" fill="none"/>
  <path d="M14 18 L22 12 L30 18" stroke="currentColor" stroke-opacity="0.5"
        stroke-width="1.5" stroke-linecap="round" stroke-linejoin="round" fill="none"/>
</svg>

'@
Write-Host '  Written: assets/logo.svg' -ForegroundColor Green

# ── Step 4: Git init ──────────────────────────────────────────────────────────
Write-Host "[4/6] Initializing git repository..." -ForegroundColor Yellow
git init
git add .
git commit -m "Initial commit - Waterfront Lobby Display v2"
Write-Host "  Git initialized and committed." -ForegroundColor Green

# ── Step 5: Create GitHub repo and push ───────────────────────────────────────
Write-Host "[5/6] Creating GitHub repository and pushing..." -ForegroundColor Yellow
gh repo create "$ghUser/$repoName" --public --description "Waterfront at Catalina Landing - Lobby Display v2" --source=. --remote=origin --push
Write-Host "  Pushed to github.com/$ghUser/$repoName" -ForegroundColor Green

# ── Step 6: Done ──────────────────────────────────────────────────────────────
Write-Host ""
Write-Host "[6/6] Done!" -ForegroundColor Green
Write-Host ""
Write-Host "Next steps:" -ForegroundColor Cyan
Write-Host "  1. Go to app.netlify.com" -ForegroundColor White
Write-Host "  2. Add new site > Import from GitHub > $repoName" -ForegroundColor White
Write-Host "  3. No build command. Publish directory: /" -ForegroundColor White
Write-Host "  4. Deploy site" -ForegroundColor White
Write-Host ""
Write-Host "Then come back to Claude and send the 4 directory tab GIDs." -ForegroundColor White
Write-Host ""
