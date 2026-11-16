// Search (lib/screens/search_screen.dart and lib/screens/search/*).
//
// - Sticky Back + 64pt search pill; it tightens up with a hairline once the
//   results scroll.
// - Blank search: Recent searches (wrapped pills with live prices, max 6),
//   Markets & Movers (endless auto-scrolling ticker, then top 5 gainers and
//   losers), Watchlists, Find your next move, prototype notice.
// - Typing filters the mock securities; a result opens its details (and
//   goes first in Recent searches). Coming back clears the query and
//   refocuses the field.
// - Opens with the keyboard down, unless ?focus=1 (the Quick quote shortcut).
(function () {
  const { h, icon, mount } = IE;

  // ── Market Overview ticker ──
  const INSTRUMENTS = [
    { name: 'S&P 500', previousClose: 6745.18, startValue: 6712.40 },
    { name: 'DJIA', previousClose: 46388.02, startValue: 46210.55 },
    { name: 'NASDAQ', previousClose: 22960.71, startValue: 22815.30 },
    { name: 'Oil', previousClose: 70.88, startValue: 71.42 },
    { name: 'Gold', previousClose: 3762.10, startValue: 3785.60 },
    { name: 'S&P/TSX 60', previousClose: 1705.20, startValue: 1712.84 },
    { name: 'VIX', previousClose: 15.92, startValue: 16.84 },
    { name: 'USD/CAD', previousClose: 1.39870, startValue: 1.40123, decimals: 4 },
  ];
  const SPEED = 24; // px per second
  const COPIES = 9; // the instruments repeated; we recentre to stay endless

  /**
   * Infinite, slowly auto-scrolling carousel of market cards whose values
   * tick every 2 s. Tap to pause / play; press-and-hold pauses and resumes
   * 3 s after release; drag to scroll either way. No auto-scroll under
   * Reduce Motion.
   */
  function marketOverview(ctx) {
    const values = INSTRUMENTS.map((m) => m.startValue);
    const rnd = IE.data.seeded(7);
    const fmt = (m, v) => (m.decimals === 4 ? v.toFixed(4) : IE.formatPrice(v));
    const cards = [];
    function card(i) {
      const m = INSTRUMENTS[i];
      const el = h('div', { class: 'search-market-card' });
      cards.push({ el, i });
      paint(el, i);
      return el;
    }
    function paint(el, i) {
      const m = INSTRUMENTS[i];
      const v = values[i];
      const change = v - m.previousClose;
      const pct = change / m.previousClose * 100;
      const up = change >= 0;
      const cls = up ? 'pos' : 'neg';
      el.setAttribute('aria-label', `${m.name} ${fmt(m, v)}, ${up ? 'up' : 'down'} ${Math.abs(pct).toFixed(2)} percent`);
      mount(el,
        h('span', { class: 'name' }, m.name.toUpperCase()),
        h('span', { class: 'val tabular' }, fmt(m, v)),
        icon(up ? 'arrow_upward' : 'arrow_downward', { size: 16, class: cls }),
        h('span', { class: ['pct tabular', cls] }, Math.abs(pct).toFixed(2) + '%'),
        h('span', { class: ['chg tabular', cls] }, (up ? '' : '-') + fmt(m, Math.abs(change))));
    }
    const track = h('div', { class: 'search-market-track' });
    for (let c = 0; c < COPIES; c++) INSTRUMENTS.forEach((_, i) => track.appendChild(card(i)));
    const scroller = h('div', { class: 'search-market', role: 'marquee', 'aria-label': 'Market overview' }, track);

    let cycle = 0; // width of one full set of cards
    function measure() {
      const n = INSTRUMENTS.length;
      const first = track.children[0], next = track.children[n];
      if (first && next) cycle = next.offsetLeft - first.offsetLeft;
    }
    function recentre() {
      if (!cycle) return;
      const mid = cycle * Math.floor(COPIES / 2);
      if (scroller.scrollLeft < cycle * 1.5) scroller.scrollLeft += cycle * (Math.floor(COPIES / 2) - 1);
      else if (scroller.scrollLeft > mid + cycle * 2) scroller.scrollLeft -= cycle * (Math.floor(COPIES / 2) - 1);
    }

    let paused = false, held = false, resumeTimer = null, last = 0, raf = 0, pos = 0;
    const allowed = () => !IE.reduceMotion();
    function frame(t) {
      raf = requestAnimationFrame(frame);
      if (!last) { last = t; return; }
      const dt = (t - last) / 1000;
      last = t;
      if (paused || held || !allowed() || !ctx.isTop()) { pos = scroller.scrollLeft; return; }
      // Track a float position so slow speeds still move on high-DPI screens.
      if (Math.abs(scroller.scrollLeft - pos) > 2) pos = scroller.scrollLeft;
      pos += SPEED * dt;
      scroller.scrollLeft = pos;
      recentre();
      pos = scroller.scrollLeft + (pos - Math.round(pos));
    }
    let downAt = 0, moved = false, startX = 0;
    scroller.addEventListener('pointerdown', (e) => {
      downAt = performance.now(); moved = false; startX = e.clientX;
      clearTimeout(resumeTimer); held = true;
    });
    scroller.addEventListener('pointermove', (e) => { if (Math.abs(e.clientX - startX) > 6) moved = true; });
    const release = () => {
      clearTimeout(resumeTimer);
      resumeTimer = setTimeout(() => { held = false; last = 0; }, 3000);
    };
    scroller.addEventListener('pointerup', () => {
      // A quick tap toggles pause; a long press or drag only holds.
      if (!moved && performance.now() - downAt < 400 && allowed()) {
        clearTimeout(resumeTimer);
        paused = !paused;
        if (!paused) held = false;
        last = 0;
        return;
      }
      release();
    });
    scroller.addEventListener('pointercancel', release);
    scroller.addEventListener('scroll', () => { if (held) recentre(); }, { passive: true });

    requestAnimationFrame(() => {
      measure();
      scroller.scrollLeft = cycle * Math.floor(COPIES / 2);
      pos = scroller.scrollLeft;
      raf = requestAnimationFrame(frame);
    });
    ctx.interval(() => {
      values.forEach((v, i) => { values[i] = v * (1 + (rnd() - 0.5) * 0.0008); });
      cards.forEach(({ el, i }) => paint(el, i));
    }, 2000);
    ctx.onDispose(() => { cancelAnimationFrame(raf); clearTimeout(resumeTimer); });
    ctx.onShow(() => { measure(); last = 0; });
    return scroller;
  }

  // ── Recent searches ──
  /** Outlined pills, wrapped: ticker in bold and its live price. */
  function recentChips(ctx, onOpen) {
    const el = h('div', { class: 'search-chips' });
    const prices = {};
    const priceOf = (s) => (prices[s.symbol] == null ? (prices[s.symbol] = s.quote.price) : prices[s.symbol]);
    function render() {
      const secs = IE.store.get('recentSearches').map((sym) => IE.data.securities.bySymbol(sym)).filter(Boolean);
      mount(el, secs.map((s) => {
        const priceText = '$' + IE.formatPrice(priceOf(s));
        return h('button', { type: 'button', class: 'search-chip', title: `Open ${s.symbol}`, 'aria-label': `${s.symbol}, ${priceText}`, dataset: { symbol: s.symbol }, onclick: () => onOpen(s) },
          h('span', { class: 'sym' }, s.symbol), h('span', { class: 'price tabular' }, priceText));
      }));
    }
    ctx.watch('recentSearches', render);
    ctx.interval(() => {
      Object.keys(prices).forEach((k) => {
        const next = prices[k] * (1 + (Math.random() - 0.5) * 0.0012);
        prices[k] = Math.round(next * 100) / 100;
      });
      render();
    }, 2000);
    render();
    return el;
  }

  // ── Top movers ──
  const GAINERS = [['SHOP', 6.42], ['NVDA', 5.18], ['CLS', 4.87], ['AAPL', 3.21], ['TD', 2.64]];
  const LOSERS = [['ENB', -3.12], ['CNQ', -2.85], ['BCE', -2.40], ['MSFT', -1.96], ['RY', -1.48]];
  function topMovers(onOpen) {
    const tile = ([sym, pct]) => {
      const up = pct >= 0;
      const sec = IE.data.securities.bySymbol(sym);
      return h(sec ? 'button' : 'div', {
        type: sec ? 'button' : null, class: 'search-mover',
        'aria-label': `${sym}, ${up ? 'up' : 'down'} ${Math.abs(pct).toFixed(2)} percent`,
        onclick: sec ? () => onOpen(sec) : null,
      },
      h('span', { class: 'sym ellipsis' }, sym),
      icon(up ? 'arrow_drop_up' : 'arrow_drop_down', { size: 24, class: up ? 'pos' : 'neg' }),
      h('span', { class: ['pct tabular', up ? 'pos' : 'neg'] }, Math.abs(pct).toFixed(2) + '%'));
    };
    return h('div', { class: 'search-movers' },
      h('div', { class: 'col gap8' }, GAINERS.map(tile)),
      h('div', { class: 'col gap8' }, LOSERS.map(tile)));
  }

  // ── Find your next move ──
  function nextMoveLinks() {
    const links = [
      ['trending_up', 'Top 10 traded stocks/ETFs', null],
      ['sell', 'Commission-free ETFs', null],
      ['pie_chart', 'Fractional stocks/ETFs', IE.routes.fractional],
    ];
    return h('div', { class: 'card search-links', style: 'padding:0' }, links.map(([ic, label, to], i) => [
      i > 0 ? h('div', { class: 'divider', style: 'margin:0 16px' }) : null,
      h('button', { type: 'button', class: 'search-link', 'aria-label': label,
        onclick: () => (to ? IE.router.push(to) : IE.notBuilt(label)) },
      h('span', { class: 'circle' }, icon(ic, { size: 20 })),
      h('span', { class: 'grow t-body-lg' }, label),
      icon('chevron_right', { color: 'var(--gray-600)' })),
    ]));
  }

  const sectionLabel = (text) => h('h2', { class: 'search-label' }, text);

  IE.route('/search', (params, ctx) => {
    let query = '';
    const input = h('input', {
      type: 'search', class: 'search-input', placeholder: 'Search stock or ETF',
      'aria-label': 'Search stock or ETF', autocomplete: 'off', enterkeyhint: 'search',
    });
    const clearBtn = IE.iconButton('close', 'Clear search', () => setQuery(''), { color: 'var(--gray-600)' });
    clearBtn.style.display = 'none';
    const field = h('div', { class: 'search-pill' }, icon('search', { size: 26, color: 'var(--gray-700)' }), input, clearBtn);
    const top = h('div', { class: 'search-top' },
      IE.iconButton('arrow_back', 'Close search', () => IE.router.pop()), field);

    const body = h('div', { class: 'page-body search-body' });
    const bar = IE.navBar(ctx, { current: 'search' });
    const barHolder = h('div', { class: 'bar-holder' }, bar);
    const chrome = IE.scrollChrome(body, {
      onChange(st) {
        top.classList.toggle('condensed', st.condensed);
        barHolder.classList.toggle('hidden', st.navHidden);
      },
    });

    async function openQuote(sec) {
      input.blur();
      await IE.router.push(`${IE.routes.quote}/${sec.symbol}`);
      if (ctx.isTop()) { setQuery(''); input.focus({ preventScroll: true }); }
    }

    // Blank-search content is built once and kept (the ticker keeps going).
    const blank = h('div', { class: 'content search-content' },
      sectionLabel('RECENT SEARCHES'),
      h('div', { class: 'mt12' }, recentChips(ctx, openQuote)),
      h('div', { style: 'height:48px' }),
      sectionLabel('MARKETS & MOVERS'),
      h('div', { class: 'mt12' }, marketOverview(ctx)),
      h('div', { class: 'mt20' }, topMovers(openQuote)),
      h('div', { style: 'margin-top:32px' }, IE.watchlistsCard ? IE.watchlistsCard() : null),
      h('div', { style: 'height:32px' }),
      sectionLabel('FIND YOUR NEXT MOVE'),
      h('div', { class: 'mt12' }, nextMoveLinks()),
      h('div', { class: 'mt24' }, IE.notice('Prototype: results come from a short mock list of securities, market values are simulated, and the browse links are not built yet.')));
    const results = h('div', { class: 'content search-content' });

    function renderBody() {
      const q = query.trim();
      if (!q) {
        if (blank.parentNode !== body) mount(body, blank);
        return;
      }
      const list = IE.data.securities.search(q);
      mount(results, list.length
        ? list.map((s, i) => [
          i > 0 ? h('div', { class: 'divider' }) : null,
          h('button', { type: 'button', class: 'search-result', dataset: { symbol: s.symbol },
            onclick: () => { IE.addRecentSearch(s.symbol); openQuote(s); } },
          h('span', { class: 'sym' }, s.symbol),
          h('span', { class: 'name grow' }, s.name),
          h('span', { class: 'exch' }, s.exchange)),
        ])
        : h('p', { class: 't-body-lg-book', style: 'margin:0;color:var(--gray-700)' }, `No matches for "${q}"`));
      if (results.parentNode !== body) mount(body, results);
    }

    function setQuery(v) {
      const wasBlank = !query.trim();
      query = v;
      if (input.value !== v) input.value = v;
      clearBtn.style.display = v ? '' : 'none';
      // New results start at the top: bring the bar back.
      if (wasBlank !== !v.trim() || v.trim()) body.scrollTop = 0;
      renderBody();
      chrome.reset();
    }
    input.addEventListener('input', () => setQuery(input.value));
    input.addEventListener('keydown', (e) => { if (e.key === 'Enter') input.blur(); });

    // Tapping anywhere that isn't a control puts the keyboard away.
    body.addEventListener('pointerdown', (e) => {
      if (!e.target.closest('button, a, input')) input.blur();
    });

    IE.focusSearchField = () => input.focus({ preventScroll: true });
    ctx.onDispose(() => { if (IE.focusSearchField && IE.focusSearchField.owner === ctx) IE.focusSearchField = null; });
    IE.focusSearchField.owner = ctx;
    ctx.onShow(() => {
      IE.focusSearchField = () => input.focus({ preventScroll: true });
      IE.focusSearchField.owner = ctx;
    });

    renderBody();
    if (ctx.query.get('focus') === '1') setTimeout(() => input.focus({ preventScroll: true }), 50);

    return h('div', { class: 'col', style: 'height:100%' }, h('div', { class: 'search-top-wrap content', style: 'width:100%' }, top), body, barHolder);
  });
})();
