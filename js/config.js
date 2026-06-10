// =============================================================================
// WATERFRONT LOBBY DISPLAY v2 — CONFIG
// =============================================================================
// This is the ONLY file you need to edit for ownership transfer or rebranding.
// All property info, Sheet IDs, GIDs, and constants live here.
// =============================================================================

const CONFIG = {

  // ── Property Info (shown on screen) ────────────────────────────────────────
  PROPERTY: {
    name:       'The Waterfront',
    subtitle:   'at Catalina Landing',
    address:    '310 – 340 Golden Shore  ·  Long Beach, CA 90802',
    phone:      '(424) 477-3816',
    email:      'lobby@ticapital.com',
    managed_by: 'TI Capital',
  },

  // ── Buildings ───────────────────────────────────────────────────────────────
  BUILDINGS: {
    '310': '310 Golden Shore',
    '320': '320 Golden Shore',
    '330': '330 Golden Shore',
    '340': '340 Golden Shore',
  },

  // ── Google Sheet ────────────────────────────────────────────────────────────
  // To transfer ownership: update SHEET_ID to the new sheet's ID.
  // GIDs are found in the tab URL: ...spreadsheets/d/SHEET_ID/edit#gid=GID
  SHEET_ID: '17Uze4Qz_0cXsnj4KS4cFmabK67F_jGG0PR_vtnegrK4',

  GIDS: {
    directory_310: '1627497967',  // Directory_310 tab
    directory_320: '702701545',   // Directory_320 tab
    directory_330: '1856569291',  // Directory_330 tab
    directory_340: '1644683988',  // Directory_340 tab
    events:        '871114333',   // Events tab
    backgrounds:   '589321751',   // Backgrounds tab
    settings:      '2028632494',  // Settings tab (sleep/wake schedule)
  },

  // ── Weather (Open-Meteo, free, no key needed) ───────────────────────────────
  WEATHER: {
    lat:      33.7701,
    lon:      -118.1937,
    timezone: 'America/Los_Angeles',
    units:    'fahrenheit',
    wind:     'mph',
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
    theme:        'obsidian',   // obsidian | stone | navy
    building:     '310',
    pin:          '0000',
    show_events:  true,
    show_property:true,
    theme_mode:   'manual',     // manual | auto
    // Sleep/wake times are managed exclusively via the Google Sheet Settings tab.
  },

  // ── Fallback directory (if Sheet unreachable) ───────────────────────────────
  FALLBACK_DIRECTORY: {
    '310': [
      { tenant: 'Catalina Express',    suite: 'Ground Floor' },
      { tenant: 'TI Capital',          suite: 'Suite 100'    },
      { tenant: 'NRE Commercial',      suite: 'Suite 200'    },
    ],
    '320': [{ tenant: 'Leasing Available', suite: 'Contact Leasing Office' }],
    '330': [{ tenant: 'Leasing Available', suite: 'Contact Leasing Office' }],
    '340': [{ tenant: 'Leasing Available', suite: 'Contact Leasing Office' }],
  },

  // ── Fallback events ─────────────────────────────────────────────────────────
  FALLBACK_EVENTS: [
    {
      title:    'Campus Open House',
      date_str: 'Date TBD',
      time:     '',
      location: 'The Waterfront at Catalina Landing',
      desc:     'Meet our leasing team and tour available spaces.',
    },
  ],

  // ── Fallback background photos ──────────────────────────────────────────────
  FALLBACK_PHOTOS: [
    'https://i0.wp.com/hollywoodlocations.com/wp-content/uploads/2023/01/the-waterfront-at-catalina-landing-long-beach-010.jpg',
    'https://i0.wp.com/hollywoodlocations.com/wp-content/uploads/2023/01/the-waterfront-at-catalina-landing-long-beach-004.jpg',
    'https://i0.wp.com/hollywoodlocations.com/wp-content/uploads/2023/01/the-waterfront-at-catalina-landing-long-beach-007.jpg',
    'https://i0.wp.com/hollywoodlocations.com/wp-content/uploads/2023/01/the-waterfront-at-catalina-landing-long-beach-002.jpg',
    'https://i0.wp.com/hollywoodlocations.com/wp-content/uploads/2023/01/the-waterfront-at-catalina-landing-long-beach-015.jpg',
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
    const res  = await fetch(url, { signal: ctrl.signal, cache: 'no-store' });
    clearTimeout(t);
    if (!res.ok) throw new Error(`HTTP ${res.status}`);
    return csvParse(await res.text());
  } catch (e) {
    clearTimeout(t);
    console.warn(`[sheet] GID ${gid} failed:`, e.message);
    return null;
  }
}

/** Tokenize CSV text → array of rows (each an array of cell strings).
 *  Processes char-by-char, tracking quote state across line boundaries so a
 *  cell containing a newline (inside quotes) does not break row splitting.
 *  Handles "" as an escaped quote and \r\n / \n line endings. */
function csvTokenize(text) {
  const rows = [];
  let row = [];
  let cur = '';
  let q   = false;
  for (let i = 0; i < text.length; i++) {
    const c = text[i];
    if (q) {
      if (c === '"') {
        if (text[i + 1] === '"') { cur += '"'; i++; }   // escaped quote
        else q = false;
      } else {
        cur += c;
      }
    } else {
      if (c === '"')      q = true;
      else if (c === ',') { row.push(cur); cur = ''; }
      else if (c === '\n'){ row.push(cur); cur = ''; rows.push(row); row = []; }
      else if (c === '\r'){ /* ignore — \r\n handled by the \n branch */ }
      else cur += c;
    }
  }
  row.push(cur);
  rows.push(row);
  // Drop empty rows (e.g. from a trailing newline)
  return rows.filter(r => !(r.length === 1 && r[0].trim() === ''));
}

/** Parse CSV text → array of objects keyed by lowercase trimmed headers */
function csvParse(text) {
  const rows = csvTokenize(text);
  if (rows.length < 2) return [];
  const heads = rows[0].map(h => h.trim().toLowerCase());
  return rows.slice(1).map(cells => {
    const row = {};
    heads.forEach((h, i) => { row[h] = (cells[i] ?? '').trim(); });
    return row;
  }).filter(r => Object.values(r).some(v => v));
}

/** localStorage wrapper with JSON + error handling */
const Store = {
  get: (k, fb = null) => { try { const v = localStorage.getItem(k); return v !== null ? JSON.parse(v) : fb; } catch { return fb; } },
  set: (k, v)         => { try { localStorage.setItem(k, JSON.stringify(v)); } catch {} },
  del: (k)            => { try { localStorage.removeItem(k); } catch {} },
};

/** Format a date string for display e.g. "Mon, Jun 9" */
function fmtDate(str) {
  if (!str) return '';
  const d = new Date(str);
  if (isNaN(d)) return str;
  return d.toLocaleDateString('en-US', { weekday: 'short', month: 'short', day: 'numeric' });
}

/** Zero-pad */
const pad = n => String(n).padStart(2, '0');
