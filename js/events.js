// events.js — events panel, Sheet-synced
(function Events() {
  'use strict';

  const gridEl   = document.getElementById('events-grid');
  const emailEl  = document.getElementById('events-email');

  // ── Escape Sheet-sourced values before inserting into innerHTML ───────────
  function esc(str) {
    const d = document.createElement('div');
    d.textContent = str == null ? '' : str;
    return d.innerHTML;
  }

  // ── Render ────────────────────────────────────────────────────────────────
  function render(events) {
    if (!gridEl) return;

    // Update footer email from stored info
    const email = Store.get('wf_info_email', CONFIG.PROPERTY.email);
    if (emailEl) emailEl.textContent = email;

    if (!events?.length) {
      gridEl.innerHTML = '<div class="events-empty">No upcoming events scheduled.</div>';
      return;
    }

    gridEl.innerHTML = events.slice(0, 3).map(e => `
      <div class="event-card" role="listitem">
        <div class="event-dateline">
          <span class="event-date">${esc(e.date_str)}</span>
          ${e.time ? `<span class="event-time">${esc(e.time)}</span>` : ''}
        </div>
        <div class="event-name">${esc(e.title)}</div>
        ${e.location ? `<div class="event-loc">${esc(e.location)}</div>` : ''}
      </div>`).join('');
  }

  // ── Parse Sheet rows ──────────────────────────────────────────────────────
  function parse(rows) {
    return rows
      .filter(r => {
        // Active column standard: blank = active; FALSE / 0 / NO = inactive
        const a = (r['active'] || r['Active'] || '').toString().trim().toUpperCase();
        return !(a === 'FALSE' || a === '0' || a === 'NO');
      })
      .map(r => ({
        title:    r['title']       || r['event']       || r['event title'] || '',
        date_str: fmtDate(r['date'] || r['Date'] || r['event date'] || ''),
        time:     r['time']        || r['Time']        || r['event time']  || '',
        location: r['location']    || r['Location']    || r['venue']       || '',
        desc:     r['description'] || r['Description'] || r['desc']        || r['details'] || '',
        priority: parseInt(r['priority'] || r['Priority'] || r['rank'] || r['Rank'] || '99', 10),
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
      Store.set('wf_events', events);
    } else {
      const cached = Store.get('wf_events');
      render(cached?.length ? cached : CONFIG.FALLBACK_EVENTS);
    }
  }

  // ── Boot ──────────────────────────────────────────────────────────────────
  const cached = Store.get('wf_events');
  if (cached?.length) render(cached);

  refresh();
  setInterval(refresh, CONFIG.TIMING.sheet_refresh);

  window.EventsPanel = { refresh };
})();
