// Home widgets (lib/screens/home/widgets/*): portfolio summary, accounts,
// holdings, watchlists, promo carousels, recent activity and financial
// progress, plus the swipe-reveal row (lib/widgets/swipe_reveal_row.dart).
//
// Each widget is a function (ctx) => element; ctx is the page's router ctx
// (for store watchers and timers that end with the page).
(function () {
  const { h, icon, mount } = IE;
  const D = IE.data;
  const R = IE.routes;
  const hidden = () => IE.store.get('balancesHidden');
  const q = (path, params) => IE.withQuery(path, params);

  // ── Shared parts (home_widget_parts.dart) ──

  /** "My accounts ›" link on the left, one round icon button on the right. */
  function widgetHeading({ title, label, onTitleTap, action }) {
    return h('div', { class: 'home-wh' },
      h('div', { class: 'grow' },
        h('button', { type: 'button', class: 'home-wh-link', 'aria-label': label, onclick: onTitleTap },
          h('span', { class: 'ellipsis' }, title), icon('chevron_right', { color: 'var(--gray-700)' }))),
      action || null);
  }

  function headingButton(name, label, onClick) {
    return IE.iconButton(name, label, onClick, { class: 'home-wh-btn' });
  }

  /** Gray Material-style switch with its label; tapping the label flips it. */
  function labeledSwitch(label, value, onChange) {
    const input = h('input', { type: 'checkbox', role: 'switch', class: 'home-switch-input', checked: value,
      onchange: () => { IE.haptic(); onChange(input.checked); } });
    return h('label', { class: 'home-switch' },
      h('span', { class: 't-body-md-book' }, label),
      h('span', { class: 'home-switch-track' }, input, h('span', { class: 'home-switch-thumb' })));
  }

  /** Switch on the left, the USDCAD rate and its date on the right. */
  function widgetFooter(label, value, onChange) {
    const asOf = D.market.usdToCadAsOf;
    const rate = D.market.usdToCad.toFixed(5);
    return h('div', { class: 'home-footer' },
      labeledSwitch(label, value, onChange),
      h('div', { class: 'home-rate', 'aria-label': `US dollar to Canadian dollar rate ${rate}, updated ${IE.MONTHS[asOf.getMonth()]} ${asOf.getDate()}` },
        h('div', { class: 'home-rate-main', 'aria-hidden': 'true' }, `USDCAD=${rate}`),
        h('div', { class: 'home-rate-date', 'aria-hidden': 'true' }, `Updated ${IE.formatShortDate(asOf)}`)));
  }

  /** Up/down arrow + text in the change colour. */
  function changeLine(isUp, text) {
    return h('div', { class: ['home-change', isUp ? 'pos' : 'neg'] },
      icon(isUp ? 'arrow_upward' : 'arrow_downward', { size: 16 }), h('span', { class: 'tabular' }, text));
  }

  /** Fades a new figure block in place of the old one. */
  function fadeSwap(holder, node) {
    if (!holder.firstChild || IE.reduceMotion()) { mount(holder, node); return; }
    node.classList.add('home-fade-in');
    mount(holder, node);
    requestAnimationFrame(() => requestAnimationFrame(() => node.classList.remove('home-fade-in')));
  }

  // ── Swipe-reveal row ──

  /** One row open at a time within a group. */
  function swipeGroup() {
    return {
      open: null,
      set(row) {
        if (this.open === row) return;
        const prev = this.open;
        this.open = row;
        if (prev) prev._apply(false);
        if (row) { IE.haptic(); row._apply(true); }
      },
    };
  }

  /**
   * A row that reveals actions when swiped right to left (or long-pressed).
   * [leading] always shows; [details] show while closed, [actions] while
   * open. The open row keeps its closed height and turns gray-100. Tapping
   * an open row (or swiping right) closes it; tapping a closed row calls
   * [onTap]. [flush]: actions fill the full height to the right edge.
   */
  function swipeRow({ leading, details, actions, onTap, group, minLeadingWidth = 96, flush = false, label }) {
    const trailing = h('div', { class: 'home-swipe-trailing', style: { maxWidth: `calc(100% - ${minLeadingWidth + 12}px)` } });
    const lead = h('div', { class: 'home-swipe-leading' }, leading);
    const inner = h('div', { class: 'home-swipe-inner' }, lead, trailing);
    const el = h('div', { class: ['home-swipe', flush && 'flush'], role: 'button', tabindex: '0', 'aria-label': label || null }, inner);
    let isOpen = false;
    let detailsNode = details;
    mount(trailing, detailsNode);

    function apply(open) {
      if (open === isOpen) return;
      if (open) el.style.height = el.offsetHeight + 'px';
      isOpen = open;
      el.classList.toggle('open', open);
      if (!open) el.style.height = '';
      fadeSwap(trailing, open ? actions() : detailsNode);
    }
    el._apply = apply;
    el.setDetails = (node) => { detailsNode = node; if (!isOpen) mount(trailing, node); };
    el.close = () => group.set(null);

    // Gestures: horizontal drag, long press, tap.
    let startX = 0, startY = 0, startT = 0, dragging = false, tracking = false, suppressClick = false, lpTimer = null;
    el.addEventListener('pointerdown', (e) => {
      if (e.button !== 0) return;
      tracking = true; dragging = false; suppressClick = false;
      startX = e.clientX; startY = e.clientY; startT = performance.now();
      clearTimeout(lpTimer);
      if (!isOpen) lpTimer = setTimeout(() => { if (tracking && !dragging) { suppressClick = true; group.set(el); } }, 500);
    });
    el.addEventListener('pointermove', (e) => {
      if (!tracking) return;
      const dx = e.clientX - startX, dy = e.clientY - startY;
      if (!dragging && (Math.abs(dx) > 8 || Math.abs(dy) > 8)) {
        clearTimeout(lpTimer);
        dragging = Math.abs(dx) > Math.abs(dy);
        if (!dragging) tracking = false;
      }
    });
    const end = (e) => {
      clearTimeout(lpTimer);
      if (!tracking) return;
      tracking = false;
      if (!dragging) return;
      const dx = e.clientX - startX;
      const v = dx / Math.max(1, performance.now() - startT) * 1000;
      if (dx < -32 || v < -300) group.set(el);
      else if ((dx > 32 || v > 300) && isOpen) group.set(null);
      suppressClick = true;
    };
    el.addEventListener('pointerup', end);
    el.addEventListener('pointercancel', () => { clearTimeout(lpTimer); tracking = false; });
    el.addEventListener('contextmenu', (e) => e.preventDefault());
    el.addEventListener('click', (e) => {
      if (suppressClick) { suppressClick = false; return; }
      if (e.target.closest('.home-swipe-action')) return;
      if (isOpen) group.set(null); else onTap();
    });
    el.addEventListener('keydown', (e) => {
      if (e.target !== el) return;
      if (e.key === 'Enter' || e.key === ' ') { e.preventDefault(); if (isOpen) group.set(null); else onTap(); }
      if (e.key === 'ArrowLeft' && !isOpen) group.set(el);
      if ((e.key === 'ArrowRight' || e.key === 'Escape') && isOpen) group.set(null);
    });
    return el;
  }

  // ── Portfolio summary (portfolio_summary_card.dart) ──

  function portfolioSummary(ctx) {
    let rangeIdx = 0;
    const root = h('section', { class: 'home-summary', 'aria-label': 'Portfolio value' });
    const totalRow = h('div', { class: 'home-total-row' });
    const changeHolder = h('div');
    const chartHolder = h('div', { class: 'home-chart' });
    const ranges = IE.rangeSelector({
      ranges: D.ChartRange.map((r) => ({ label: r.label, spoken: r.spoken })),
      selected: 0,
      onSelect: (i) => { rangeIdx = i; renderChange(); renderChart(); },
    });
    root.append(totalRow, changeHolder, chartHolder, h('div', { class: 'mt8' }, ranges));

    function renderTotal() {
      const cur = IE.store.get('displayCurrency');
      const hid = hidden();
      mount(totalRow,
        h('div', { class: 'home-total grow', 'aria-label': hid ? 'Total portfolio value hidden' : `Total portfolio value in ${cur}` },
          hid ? '$' + IE.HIDDEN : IE.formatCad(IE.fromCad(D.portfolio.totalValue))),
        h('button', { type: 'button', class: 'home-tag', 'aria-label': `Showing ${cur}. Switch to ${cur === 'USD' ? 'CAD' : 'USD'}`,
          onclick: () => { IE.haptic(); IE.store.set('displayCurrency', cur === 'USD' ? 'CAD' : 'USD'); } }, cur),
        h('button', { type: 'button', class: 'home-eye', title: hid ? 'Show balance' : 'Hide balance', 'aria-label': hid ? 'Show balance' : 'Hide balance',
          onclick: () => { IE.haptic(); IE.store.set('balancesHidden', !hid); } },
        icon(hid ? 'visibility_off' : 'visibility', { color: 'var(--gray-600)' })));
    }

    function renderChange() {
      const range = D.ChartRange[rangeIdx];
      const series = D.portfolio.series(range.key);
      const cur = IE.store.get('displayCurrency');
      const change = IE.fromCad(series.change);
      const isUp = series.change >= 0;
      const pct = IE.formatSignedPercent(series.changePercent);
      const text = hidden()
        ? `${IE.HIDDEN} (${pct}) ${range.suffix}`
        : `${IE.formatSignedCad(change)} (${pct}) ${range.suffix}`;
      const spoken = `${isUp ? 'Up' : 'Down'} ${IE.formatCad(Math.abs(change))} ${cur}, ${Math.abs(series.changePercent).toFixed(2)} percent, ${range.suffix}`;
      fadeSwap(changeHolder, h('button', {
        type: 'button', class: ['home-change-link', isUp ? 'pos' : 'neg'], title: 'View performance',
        'aria-label': `${hidden() ? 'Change hidden' : spoken}. View performance`,
        onclick: () => IE.router.push(R.performance),
      },
      triangle(isUp),
      h('span', { class: 'home-change-text tabular' }, text),
      icon('chevron_right', { color: 'var(--gray-700)' })));
    }

    function renderChart() {
      const range = D.ChartRange[rangeIdx];
      const series = D.portfolio.series(range.key);
      mount(chartHolder, IE.lineChart({
        points: series.points, height: 126,
        lineColor: 'var(--gray-700)', fillColor: '#BBBCBC',
        label: `Portfolio value chart, ${range.spoken}.`,
      }));
    }

    function renderAll() { renderTotal(); renderChange(); }
    ctx.watch('balancesHidden', renderAll);
    ctx.watch('displayCurrency', renderAll);
    renderAll();
    renderChart();
    return root;
  }

  function triangle(isUp) {
    return IE.s('svg', { width: 14, height: 12, viewBox: '0 0 14 12', 'aria-hidden': 'true', style: { flex: 'none' } },
      IE.s('path', { d: isUp ? 'M7 0 L14 12 L0 12 Z' : 'M0 0 L14 0 L7 12 Z', fill: 'currentColor' }));
  }

  // ── Accounts (accounts_card.dart, accounts_list.dart) ──

  function accountsCard(ctx) {
    let group = 'personal';
    let showCash = false;
    const swipe = swipeGroup();
    const listHolder = h('div', { class: 'home-rows' });

    function go(path, account) { swipe.set(null); IE.router.push(q(path, { account: account.name })); }

    function figures(a) {
      if (showCash) {
        const cash = (amt, cur) => h('div', { class: 'home-cash tabular' },
          h('span', { class: 'semibold' }, hidden() ? IE.HIDDEN : IE.formatPrice(amt)), ' ' + cur);
        return h('div', { class: 'home-figs' }, cash(a.cashCad, 'CAD'), cash(a.cashUsd, 'USD'));
      }
      const pct = Math.abs(a.changePercent);
      return h('div', { class: 'home-figs' },
        h('div', { class: 'home-amount tabular' }, hidden() ? IE.HIDDEN : IE.formatPrice(IE.fromCad(a.value))),
        changeLine(a.changePercent >= 0, `${pct.toFixed(pct < 0.1 ? 2 : 1)}%`));
    }

    function actions(a) {
      const tile = (key, ic, label, spoken, fn) => h('button', {
        type: 'button', class: 'home-swipe-action home-action-tile', 'aria-label': spoken, dataset: { testid: key },
        onclick: (e) => { e.stopPropagation(); fn(); },
      }, icon(ic, { color: 'var(--gray-700)' }), h('span', null, label));
      return h('div', { class: 'home-actions' },
        tile('account-action-manage', 'settings', 'Manage', `Manage ${a.name}`, () => go(R.accountSettings, a)),
        tile('account-action-transfer', 'move_money', 'Move', `Move money from ${a.name}`, () => go(R.transfer, a)),
        tile('account-action-trade', 'trending_up', 'Trade', `Trade in ${a.name}`, () => go(R.trade, a)));
    }

    function renderList() {
      swipe.open = null;
      const accounts = D.portfolio.accountsIn(group);
      mount(listHolder, accounts.map((a) => {
        const row = swipeRow({
          group: swipe, minLeadingWidth: 84,
          label: `${a.name} ${a.number}`,
          onTap: () => go(R.holdings, a),
          leading: h('div', { class: 'home-name' },
            h('div', { class: 'home-name-main ellipsis' }, a.name),
            h('div', { class: 'home-name-sub tabular ellipsis' }, a.numberLine)),
          details: figures(a),
          actions: () => actions(a),
        });
        row._account = a;
        return row;
      }));
    }

    function refreshFigures() {
      listHolder.querySelectorAll('.home-swipe').forEach((row) => row.setDetails(figures(row._account)));
    }

    const seg = IE.segmented({
      labels: D.AccountGroup.map((g) => g.label),
      selected: 0,
      label: 'Account type',
      radius: '12px 12px 0 0',
      onSelect: (i) => { group = D.AccountGroup[i].key; renderList(); },
    });
    const footerHolder = h('div');
    function renderFooter() {
      mount(footerHolder, widgetFooter('Cash only', showCash, (v) => { showCash = v; refreshFigures(); }));
    }
    renderList();
    renderFooter();
    ctx.watch('balancesHidden', refreshFigures);
    ctx.watch('displayCurrency', refreshFigures);
    return h('section', { class: 'home-widget', 'aria-label': 'My accounts' },
      widgetHeading({ title: 'My accounts', label: 'My accounts, view all holdings', onTitleTap: () => IE.router.push(R.holdings),
        action: headingButton('add_circle', 'Add an account', () => IE.showAddAccountSheet()) }),
      h('div', { class: 'mt2' }, seg),
      h('div', { class: 'card home-accounts-card' }, listHolder, h('hr', { class: 'divider' }), footerHolder));
  }

  // ── Holdings (holdings_card.dart, top_holdings_list.dart) ──

  const TOP_SORTS = [
    { key: 'totalValue', label: 'Total value' },
    { key: 'changePercent', label: 'Price change %' },
    { key: 'changeDollar', label: 'Price change $' },
  ];

  /** Live prices for the top holdings, shared so Home keeps them between visits. */
  const livePrices = {};
  const priceRandom = D.seeded(42);

  function holdingsCard(ctx) {
    let sort = 'totalValue';
    let showPrice = false;
    const swipe = swipeGroup();
    const all = D.holdings.all;
    for (const hd of all) if (livePrices[hd.security.symbol] == null) livePrices[hd.security.symbol] = hd.security.quote.price;
    const listHolder = h('div', { class: 'home-rows' });

    function top() {
      const sorted = all.slice();
      if (sort === 'totalValue') sorted.sort((a, b) => b.marketValueCad - a.marketValueCad);
      if (sort === 'changePercent') sorted.sort((a, b) => b.dayChangePercent - a.dayChangePercent);
      if (sort === 'changeDollar') sorted.sort((a, b) => b.dayChangeCad - a.dayChangeCad);
      return sorted.slice(0, 5);
    }

    function openTrade(symbol, side) { swipe.set(null); IE.router.push(q(R.trade, { symbol, side })); }

    function figures(hd) {
      const sec = hd.security;
      const price = livePrices[sec.symbol];
      const prev = sec.quote.previousClose;
      const perShare = price - prev;
      const pct = perShare / prev * 100;
      const mask = !showPrice && hidden();
      const main = showPrice ? price : price * hd.shares;
      const change = showPrice ? perShare : perShare * hd.shares;
      return h('div', { class: 'home-figs' },
        h('div', { class: 'home-amount tabular' }, mask ? IE.HIDDEN : IE.formatPrice(main), h('span', { class: 'home-ccy' }, ' ' + sec.currency)),
        changeLine(perShare >= 0, `${mask ? IE.HIDDEN : IE.formatPrice(Math.abs(change))} (${Math.abs(pct).toFixed(2)}%)`));
    }

    function nameColumn(hd) {
      return h('div', { class: 'home-holding-lead' },
        h('div', { class: 'home-monogram', 'aria-hidden': 'true' }, hd.security.symbol.slice(0, 1)),
        h('div', { class: 'home-name grow' },
          h('div', { class: 'home-name-main ellipsis' }, hd.security.symbol),
          h('div', { class: 'home-name-sub tabular ellipsis' }, `${hidden() ? IE.HIDDEN : IE.formatWhole(hd.shares)} shares`)));
    }

    function tradeButtons(symbol) {
      const block = (label, cls, side) => h('button', {
        type: 'button', class: ['home-swipe-action', 'home-trade-block', cls], 'aria-label': `${label} ${symbol}`,
        onclick: (e) => { e.stopPropagation(); openTrade(symbol, side); },
      }, label);
      return h('div', { class: 'home-trade-blocks' }, block('Buy', 'buy', 'buy'), block('Sell', 'sell', 'sell'));
    }

    function renderList() {
      swipe.open = null;
      mount(listHolder, top().map((hd) => {
        const sym = hd.security.symbol;
        const row = swipeRow({
          group: swipe, minLeadingWidth: 124, flush: true,
          label: `${sym}, open details`,
          onTap: () => IE.router.push(`${R.quote}/${sym}`),
          leading: nameColumn(hd),
          details: figures(hd),
          actions: () => tradeButtons(sym),
        });
        row._holding = hd;
        return row;
      }));
    }

    function refreshFigures() {
      listHolder.querySelectorAll('.home-swipe').forEach((row) => row.setDetails(figures(row._holding)));
    }

    async function chooseSort() {
      const picked = await IE.showSheet((close) => h('div', { style: 'padding:0 8px 16px' },
        h('h2', { class: 'sheet-title', style: 'padding:0 16px 8px' }, 'Sort by'),
        TOP_SORTS.map((s) => h('button', { type: 'button', class: 'sheet-option', 'aria-pressed': String(s.key === sort), onclick: () => close(s.key) },
          h('span', { class: ['lbl', s.key !== sort && 'book'] }, s.label),
          s.key === sort ? icon('check', { color: 'var(--gray-700)' }) : null))), { label: 'Sort by' });
      if (picked && picked !== sort) { IE.haptic(); sort = picked; renderList(); }
    }

    const footerHolder = h('div');
    mount(footerHolder, widgetFooter('Price', showPrice, (v) => { showPrice = v; refreshFigures(); }));
    renderList();
    ctx.watch('balancesHidden', renderList);
    // Simulated streaming quotes: up to ±0.06% every 2 seconds.
    ctx.interval(() => {
      for (const sym of Object.keys(livePrices)) {
        const next = livePrices[sym] * (1 + (priceRandom() - 0.5) * 0.0012);
        livePrices[sym] = Math.round(next * 100) / 100;
      }
      if (ctx.isTop()) refreshFigures();
    }, 2000);

    return h('section', { class: 'home-widget', 'aria-label': 'Holdings' },
      widgetHeading({ title: 'Holdings', label: 'Holdings, view all holdings', onTitleTap: () => IE.router.push(R.holdings),
        action: headingButton('unfold_more', 'Sort holdings', chooseSort) }),
      h('div', { class: 'card home-holdings-card' }, listHolder, h('hr', { class: 'divider' }), footerHolder));
  }

  // ── Watchlists (watchlists_card.dart): also used on Search ──

  function watchlistsCard() {
    return h('div', { class: 'card home-watchlists' },
      IE.sectionHeader('Watchlists', () => IE.router.push(R.watchlists), 'See all watchlists'),
      h('hr', { class: 'divider', style: 'margin-top:4px' }),
      h('div', { class: 'home-watchlists-tbd' }, 'Content TBD'));
  }

  // ── Promo carousels (auto_investing_card.dart) ──

  function promoCarousel({ title, promos }) {
    const track = h('div', { class: 'home-promos', role: 'list' }, promos.map((p, i) => h('button', {
      type: 'button', class: 'home-promo', role: 'listitem',
      'aria-label': `${p.article ? 'Article: ' : ''}${p.title}. ${p.description} ${i + 1} of ${promos.length}`,
      onclick: () => IE.notBuilt(p.title),
    },
    h('span', { class: 'home-promo-icon' }, icon(p.icon, { size: 28, color: 'var(--gray-700)' })),
    h('span', { class: 'home-promo-text' },
      h('span', { class: 'home-promo-title' }, p.title),
      h('span', { class: 'home-promo-desc' }, p.description)))));
    return h('section', { class: 'home-carousel', 'aria-label': title || 'Offers' },
      title ? h('h2', { class: 'home-section-title' }, title) : null,
      track);
  }

  function offersCarousel() {
    return promoCarousel({ promos: [
      { icon: 'sell', title: 'Your next trade', description: 'Say hello to $0 commission on select ETFs.' },
      { icon: 'school', title: 'Options Education Month', description: 'Get $100 in free options trades (and more!)' },
      { icon: 'pie_chart', title: 'Get started with $1', description: 'Trade fractional shares with $0 commission until Oct. 31, 2027.' },
    ] });
  }

  function autoInvestingCard() {
    return promoCarousel({ title: 'Make investing stress-free', promos: [
      { icon: 'payments', title: 'Auto-deposit', description: 'Pay yourself first, every Monday.' },
      { icon: 'bar_chart', title: 'Reinvest dividends', description: 'Put your dividends back to work, ASAP.' },
      { icon: 'lightbulb', title: "What's an FHSA?", description: 'Break into the housing market, tax-free.', article: true },
      { icon: 'currency_exchange', title: 'Auto invest', description: 'Build your portfolio steadily over time.' },
    ] });
  }

  // ── Recent activity (recent_activity_card.dart) ──

  const ACTIVITY_ICON = { deposit: 'add', buy: 'trending_up', sell: 'trending_up', dividend: 'payments', transfer: 'swap_horiz' };

  function recentActivityCard() {
    let tradesOnly = false;
    const listHolder = h('div');
    function renderList() {
      const items = tradesOnly ? D.portfolio.recentTrades.slice(0, 3) : D.portfolio.recentActivity;
      fadeSwap(listHolder, h('div', null, items.map((it, i) => [
        i > 0 ? h('hr', { class: 'divider' }) : null,
        h('div', { class: 'home-activity-row' },
          h('span', { class: 'home-activity-icon', 'aria-hidden': 'true' }, icon(ACTIVITY_ICON[it.kind], { size: 20, color: 'var(--gray-700)' })),
          h('div', { class: 'grow' },
            h('div', { class: 'home-activity-title' }, h('span', { class: 't-body-lg' }, it.title),
              it.pending ? h('span', { class: 'home-pending' }, 'Pending') : null),
            h('div', { class: 't-body-md-book muted mt2' }, it.detail)),
          h('div', { class: ['t-body-lg tabular home-activity-amt', it.pending ? 'muted' : it.amount >= 0 ? 'pos' : ''] }, IE.formatSignedCad(it.amount))),
      ])));
    }
    renderList();
    return h('section', { class: 'home-widget', 'aria-label': 'Recent activity' },
      widgetHeading({ title: 'Recent activity', label: 'Recent activity, view all activity', onTitleTap: () => IE.router.push(R.activity) }),
      h('div', { class: 'card home-activity-card' }, listHolder, h('hr', { class: 'divider' }),
        h('div', { class: 'home-activity-footer' }, labeledSwitch('Trades only', false, (v) => { tradesOnly = v; renderList(); }))));
  }

  // ── Financial progress (financial_progress_card.dart) ──

  function showAddMoneySheet() {
    return IE.showSheet((close) => {
      const link = (ic, label) => h('button', { type: 'button', class: 'sheet-option', onclick: () => { close(); IE.router.push(q(R.add, { type: label })); } },
        icon(ic, { color: 'var(--brand-600)' }), h('span', { class: 'lbl' }, label), icon('chevron_right', { color: 'var(--gray-500)' }));
      return h('div', { style: 'padding:0 8px 16px' },
        h('h2', { class: 'sheet-title', style: 'padding:0 16px 8px' }, 'Add money'),
        link('swap_horiz', 'One-time transfer'),
        link('event_repeat', 'Recurring deposit'));
    }, { label: 'Add money' });
  }

  function financialProgressCard(ctx) {
    let dividends = false;
    const totalHolder = h('div', { class: 'home-fp-total' });
    const chartHolder = h('div', { class: 'home-fp-chartwrap' });
    const linkHolder = h('div', { class: 'home-fp-link-holder' });

    function bars() {
      const y = new Date().getFullYear();
      if (dividends) {
        const past = D.portfolio.dividendsByYear;
        return {
          bars: [
            ...past.map(([yr, v]) => ({ label: String(yr), value: v, kind: 'past' })),
            { label: String(y), sub: '(YTD)', value: D.portfolio.dividendsYearToDate, kind: 'current' },
            { label: String(y), sub: '(projected)', value: D.portfolio.dividendsProjectedThisYear, kind: 'projected' },
          ],
          total: past.reduce((s, e) => s + e[1], 0) + D.portfolio.dividendsYearToDate,
        };
      }
      const years = D.portfolio.investedByYear;
      return {
        bars: years.map(([yr, v], i) => ({ label: String(yr), value: v, kind: i === years.length - 1 ? 'current' : 'past' })),
        total: years.reduce((s, e) => s + e[1], 0),
      };
    }

    function render(replay) {
      const { bars: list, total } = bars();
      const hid = hidden();
      fadeSwap(totalHolder, h('p', { class: 'home-fp-line' },
        `You've ${dividends ? 'earned' : 'invested'} `,
        h('span', { class: 'home-fp-amount tabular' }, hid ? IE.HIDDEN : IE.formatPrice(total)),
        h('span', { class: 'pos' }, ' CAD'),
        ' in all. Nice job!'));

      const max = Math.max(...list.map((b) => b.value));
      const what = dividends ? 'Dividends' : 'Amount invested';
      const spoken = hid ? `${what} by year, amounts hidden`
        : `${what} by year: ${list.map((b) => `${b.label}${b.sub ? ' ' + b.sub : ''} ${IE.formatPrice(b.value)} dollars`).join(', ')}`;
      const cols = list.map((b) => {
        const bar = h('div', { class: ['home-fp-bar', b.kind], style: { height: replay && !IE.reduceMotion() ? '0px' : (b.value / max * 128) + 'px' } });
        bar._target = b.value / max * 128;
        return h('div', { class: 'home-fp-col' },
          h('div', { class: ['home-fp-val tabular', b.kind] }, hid ? '••••' : IE.formatPrice(b.value)),
          bar);
      });
      const plot = h('div', { class: 'home-fp-plot' }, cols);
      const labels = h('div', { class: 'home-fp-labels' }, list.map((b) => h('div', null,
        h('div', { class: 't-body-md-book', style: 'color:var(--gray-700)' }, b.label),
        b.sub ? h('div', { class: 't-caption', style: 'color:var(--gray-700)' }, b.sub) : null)));
      mount(chartHolder, h('div', { role: 'img', 'aria-label': spoken }, plot, labels));
      if (replay && !IE.reduceMotion()) {
        requestAnimationFrame(() => requestAnimationFrame(() => {
          plot.querySelectorAll('.home-fp-bar').forEach((el) => { el.style.height = el._target + 'px'; });
        }));
      }

      fadeSwap(linkHolder, dividends
        ? actionLink('currency_exchange', 'Reinvest', () => IE.notBuilt('Reinvest dividends'))
        : actionLink('bar_chart', 'Contributions', () => IE.router.push(R.contributions)));
    }

    function actionLink(ic, label, fn) {
      return h('button', { type: 'button', class: 'home-fp-link', onclick: fn },
        icon(ic, { size: 20, color: 'var(--gray-700)' }), h('span', null, label), icon('chevron_right', { size: 20, color: 'var(--gray-700)' }));
    }

    const toggle = IE.pillToggle({ left: 'Invested', right: 'Dividends', rightSelected: false, segmentWidth: 84,
      onChange: (v) => { dividends = v; render(true); } });
    ctx.watch('balancesHidden', () => render(false));
    render(true);
    return h('section', { class: 'card home-fp', 'aria-label': 'Financial progress' },
      h('div', { class: 'row' },
        h('h2', { class: 'home-fp-title grow' }, 'Financial progress'),
        IE.iconButton('add_circle', 'Add money', showAddMoneySheet, { size: 28, color: 'var(--brand-700)' })),
      totalHolder,
      chartHolder,
      h('hr', { class: 'divider', style: 'margin-top:12px' }),
      h('div', { class: 'row home-fp-bottom' }, toggle, linkHolder));
  }

  Object.assign(IE, {
    swipeRow, swipeGroup, watchlistsCard,
    home: {
      portfolioSummary, accountsCard, holdingsCard, watchlistsCard, offersCarousel,
      recentActivityCard, autoInvestingCard, financialProgressCard, showAddMoneySheet,
      widgetHeading, labeledSwitch, widgetFooter,
    },
  });
})();
