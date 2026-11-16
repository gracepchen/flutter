// Stock / ETF details (lib/screens/quote/*).
//
// - Top bar: Back, price alert, watchlist. Once the price card scrolls out
//   of view it swaps to a compact bar with the ticker and live price, and
//   swaps back only when the price card is in view again.
// - Price, change, bid/ask, day range and volume tick every 2 s (simulated).
//   The price change follows the chart's selected range.
// - Pinned to the bottom: Sell (off when not held) and Buy, each opening
//   Trade on that side.
(function () {
  const { h, icon, mount } = IE;
  const D = IE.data;

  const compactNum = new Intl.NumberFormat('en', { notation: 'compact', maximumFractionDigits: 1 });
  const compactMoney = (v) => '$' + new Intl.NumberFormat('en', { notation: 'compact', minimumFractionDigits: 2, maximumFractionDigits: 2 }).format(v);
  const NONE = '—';

  function openTrade(sec, side) {
    IE.router.push(IE.withQuery(IE.routes.trade, { symbol: sec.symbol, side }));
  }

  function monogram(symbol, size) {
    return h('div', { class: 'quote-monogram', 'aria-hidden': 'true', style: { width: size, height: size } },
      h('span', { class: size >= 52 ? 't-heading-sm semibold' : 't-body-lg semibold' }, symbol.slice(0, 1)));
  }

  /** Explanation for an info icon, in a bottom sheet. */
  function infoSheet(title, body) {
    return IE.showSheet((close) => h('div', { style: 'padding:0 24px 24px' },
      h('h2', { class: 't-heading-sm semibold', style: 'margin:0' }, title),
      h('p', { class: 't-body-lg-book', style: 'margin:12px 0 24px;color:var(--gray-700)' }, body),
      h('button', { type: 'button', class: 'btn filled block', style: 'min-height:52px;border-radius:12px', onclick: () => close() }, 'Got it')),
    { label: title });
  }

  // ── Price card + bid/ask ──
  function priceCard(sec, rangeStart, range) {
    const q = sec.quote;
    const change = q.price - rangeStart;
    const pct = rangeStart === 0 ? 0 : change / rangeStart * 100;
    const up = change >= 0;
    const changeText = `${IE.formatPrice(Math.abs(change))} (${Math.abs(pct).toFixed(2)}%)`;
    return h('button', {
      type: 'button', class: 'quote-price-card',
      'aria-label': `${sec.symbol} last price ${IE.formatPrice(q.price)} ${sec.currency}, ${up ? 'up' : 'down'} ${changeText} over ${range.spoken}. Opens trade.`,
      onclick: () => openTrade(sec),
    },
    h('span', { class: 'price tabular' }, IE.formatPrice(q.price)),
    h('span', { class: 'cur' }, sec.currency),
    h('span', { class: ['chg tabular', up ? 'pos' : 'neg'] }, icon(up ? 'arrow_upward' : 'arrow_downward', { size: 20 }), changeText),
    h('span', { class: 'period tabular', dataset: { testid: 'price-period' } }, range.label));
  }

  function bidAsk(sec) {
    const q = sec.quote;
    const side = (label, price, size, cls, end) => {
      const sizeEl = h('span', { class: 'size tabular' }, end ? `x ${IE.formatWhole(size)}` : `${IE.formatWhole(size)} x`);
      const priceEl = h('span', { class: ['p tabular', cls] }, IE.formatPrice(price));
      const lbl = h('span', { class: 'lbl' }, label);
      const figs = h('span', { class: 'figs' }, end ? [priceEl, sizeEl] : [sizeEl, priceEl]);
      return h('button', {
        type: 'button', class: ['quote-side', end && 'end'],
        'aria-label': `${label} ${IE.formatPrice(price)}, size ${IE.formatWhole(size)}. Opens trade.`,
        onclick: () => openTrade(sec),
      }, end ? [figs, lbl] : [lbl, figs]);
    };
    return h('div', { class: 'quote-bidask' },
      side('Bid', q.bid, q.bidSize, 'pos', false),
      h('div', { class: 'vdiv' }),
      side('Ask', q.ask, q.askSize, 'ask', true));
  }

  // ── Position accordion ──
  const RETURN_TITLE = 'Est. total return';
  const RETURN_INFO = "Estimated return on the shares you hold: market value at the last price minus book value (what you paid, based on your average cost). It's not a realized gain or loss, doesn't include commissions, and will change as the price moves.";

  function positionAccordion(state, sec, positions) {
    const hidden = IE.store.get('balancesHidden');
    const cur = sec.currency;
    const price = sec.quote.price;
    const total = positions.reduce((s, p) => s + price * p.shares - p.bookValue, 0);
    const color = hidden ? '' : (total >= 0 ? 'pos' : 'neg');
    const returnText = `${total < 0 ? IE.MINUS : '+'}${IE.formatWhole(Math.round(Math.abs(total)))}`;
    const toggle = () => { state.expanded = !state.expanded; state.repaint(); };
    const head = h('div', { class: 'quote-pos-head', onclick: (e) => { if (!e.target.closest('.info')) toggle(); } },
      h('div', { class: 'row grow' },
        h('span', { class: 't-body-lg', style: 'color:var(--gray-800)' }, RETURN_TITLE),
        h('button', { type: 'button', class: 'info', title: `About ${RETURN_TITLE}`, 'aria-label': `About ${RETURN_TITLE}`,
          onclick: () => infoSheet(RETURN_TITLE, RETURN_INFO) }, icon('info', { size: 20, color: 'var(--brand-600)' }))),
      h('span', { class: ['total', color], 'aria-label': hidden ? `${RETURN_TITLE} hidden` : `${RETURN_TITLE} ${returnText} ${cur}` },
        h('span', { class: 't-heading-xs tabular' }, hidden ? IE.HIDDEN : returnText),
        h('span', { class: 't-body-lg-book' }, ' ' + cur)),
      h('button', { type: 'button', class: ['chev', state.expanded && 'open'], 'aria-expanded': String(state.expanded),
        'aria-label': state.expanded ? 'Hide position details' : 'Show position details',
        onclick: (e) => { e.stopPropagation(); toggle(); } }, icon('keyboard_arrow_down', { size: 28, color: 'var(--gray-700)' })));
    const body = state.expanded ? h('div', { class: 'quote-pos-body' }, positions.map((p, i) => [
      i > 0 ? h('div', { class: 'divider', style: 'background:var(--gray-300);margin:16px 0' }) : null,
      accountBlock(p, price, hidden),
    ])) : null;
    return h('div', { class: 'quote-pos' }, head, body);
  }

  function accountBlock(p, price, hidden) {
    const market = price * p.shares;
    const book = p.bookValue;
    const gain = market - book;
    const pct = book === 0 ? 0 : gain / book * 100;
    const amount = (v) => (hidden ? IE.HIDDEN : IE.formatPrice(v));
    const fig = (label, value, cls) => h('div', { class: 'quote-fig' },
      h('span', { class: 'l' }, label), h('span', { class: ['v tabular', cls] }, value));
    return h('div', { class: 'quote-acct' },
      h('div', { class: 'row', style: 'align-items:flex-start' },
        h('div', { class: 'left', style: 'padding-top:4px' },
          h('div', { class: 't-body-lg semibold', style: 'color:var(--gray-900)' }, p.account.name),
          h('div', { class: 't-body-md-book tabular muted' }, p.account.number)),
        h('div', { class: 'grow' },
          fig('Return', hidden ? IE.HIDDEN : `${gain < 0 ? IE.MINUS : '+'}${IE.formatPrice(Math.abs(gain))} (${Math.abs(pct).toFixed(1)}%)`, hidden ? null : (gain >= 0 ? 'pos' : 'neg')),
          fig('Market value', amount(market)))),
      h('div', { class: 'row' },
        h('div', { class: 'left ellipsis' },
          h('span', { class: 't-body-lg semibold tabular' }, hidden ? IE.HIDDEN : IE.formatWhole(p.shares)),
          h('span', { class: 't-body-lg-book' }, ' shares')),
        h('div', { class: 'grow' }, fig('Average cost', amount(p.averageCost)))));
  }

  // ── Chart section ──
  function chartSection(base, rangeIdx, onRange) {
    const range = D.StockRange[rangeIdx];
    const pts = D.market.series(base, range.key);
    const change = pts[pts.length - 1] - pts[0];
    const pct = change / pts[0] * 100;
    return h('div', null,
      h('div', { style: 'height:162px' }, IE.lineChart({
        points: pts, lineColor: 'var(--gray-700)', fillColor: '#BBBCBC', height: 162,
        label: `${base.symbol} price chart, ${range.spoken}. ${change >= 0 ? 'Up' : 'Down'} ${Math.abs(pct).toFixed(2)} percent.`,
      })),
      h('div', { class: 'mt8' }, IE.rangeSelector({ ranges: D.StockRange, selected: rangeIdx, onSelect: onRange })),
      h('div', { class: 'row', style: 'margin-top:2px;gap:12px' },
        h('button', { type: 'button', class: 'link-u', onclick: () => IE.router.push(IE.withQuery(IE.routes.advancedChart, { symbol: base.symbol })) }, 'Advanced Chart'),
        h('span', { class: 'grow t-caption muted', style: 'text-align:right' }, 'Chart data delayed by at least 15 minutes')));
  }

  // ── Key stats: number lines ──
  function numberLines(sec) {
    const q = sec.quote;
    const f = D.research.fundamentalsOf(sec);
    const volPct = q.volume / f.averageVolume3m * 100;
    const frac = (v, lo, hi) => (hi === lo ? 0.5 : Math.min(1, Math.max(0, (v - lo) / (hi - lo))));
    const rangeBar = (lo, hi, cur, open) => h('div', { class: 'quote-bar range' },
      h('span', { class: 'end tabular' }, IE.formatPrice(lo)),
      h('span', { class: 'track' },
        h('span', { class: 'tick', style: 'left:0' }), h('span', { class: 'tick', style: 'left:50%' }), h('span', { class: 'tick', style: 'left:100%' }),
        open != null ? h('span', { class: 'diamond', style: { left: `calc(5px + ${frac(open, lo, hi)} * (100% - 10px))` } }) : null,
        h('span', { class: 'dot', style: { left: `calc(5px + ${frac(cur, lo, hi)} * (100% - 10px))` } })),
      h('span', { class: 'end tabular' }, IE.formatPrice(hi)));
    const row = (label, bar, aria) => h('div', { class: 'quote-line', role: 'img', 'aria-label': aria },
      h('div', { class: 'lbl tabular' }, label), h('div', { class: 'grow' }, bar));
    return h('div', { class: 'quote-lines' },
      h('div', { class: 'quote-open tabular', 'aria-hidden': 'true' }, 'Open: ', h('b', null, IE.formatPrice(q.open))),
      row('Day range', rangeBar(q.dayLow, q.dayHigh, q.price, q.open),
        `Day range ${IE.formatPrice(q.dayLow)} to ${IE.formatPrice(q.dayHigh)}. Open ${IE.formatPrice(q.open)}. Last ${IE.formatPrice(q.price)}.`),
      row('52 week range', rangeBar(q.yearLow, q.yearHigh, q.price, null),
        `52 week range ${IE.formatPrice(q.yearLow)} to ${IE.formatPrice(q.yearHigh)}. Last ${IE.formatPrice(q.price)}.`),
      row(['Volume: ', h('b', null, compactNum.format(q.volume))],
        h('div', { class: 'quote-bar vol' },
          h('span', { class: 'fill', style: { width: Math.min(100, Math.max(0, volPct)) + '%' } }),
          h('span', { class: 'txt tabular' }, h('b', null, Math.round(volPct) + '%'), ` vs 3 mon avg (${compactNum.format(f.averageVolume3m)})`)),
        `Volume ${compactNum.format(q.volume)}, ${Math.round(volPct)} percent of the 3 month average of ${compactNum.format(f.averageVolume3m)}`));
  }

  function statGrid(stats) {
    const rows = [];
    for (let i = 0; i < stats.length; i += 2) {
      rows.push(h('div', { class: 'quote-stat-row' },
        stat(stats[i]), stats[i + 1] ? stat(stats[i + 1]) : h('div')));
    }
    return h('div', { class: 'col gap16' }, rows);
  }
  function stat([label, value]) {
    return h('div', { class: 'quote-stat' },
      h('div', { class: 't-body-md-book muted' }, label),
      h('div', { class: 't-body-lg semibold tabular', style: 'margin-top:2px', 'aria-label': value === NONE ? 'Not available' : null }, value));
  }

  function fundamentals(sec) {
    const R = D.research;
    const f = R.fundamentalsOf(sec);
    const eps = R.epsTtm(sec), y = R.dividendYield(sec), payout = R.payoutRatio(sec), ex = R.nextExDividend(sec);
    const pct = (v) => (v == null ? NONE : v.toFixed(2) + '%');
    return statGrid([
      [sec.type === 'ETF' ? 'Net assets' : 'Market cap', compactMoney(f.marketCap)],
      ['Dividend / Yield', f.annualDividend > 0 ? `${IE.formatCad(f.annualDividend)} / ${pct(y)}` : NONE],
      ['P/E (TTM)', f.peTtm != null ? f.peTtm.toFixed(2) : NONE],
      ['Ex-div date', ex ? IE.formatDate(ex) : NONE],
      ['EPS (TTM)', eps == null ? NONE : IE.formatCad(eps)],
      ['Payout ratio', pct(payout)],
      ['Beta', f.beta != null ? f.beta.toFixed(2) : NONE],
      ['Dividend growth', pct(f.dividendGrowth3y)],
    ]);
  }

  // ── Analyst ratings ──
  function ratingsCard(sec) {
    const r = D.research.ratingsOf(sec);
    if (!r) {
      return h('div', { class: 'quote-ratings', style: 'display:block' }, h('p', { class: 't-body-md-book', style: 'margin:0;color:var(--gray-700)' },
        sec.type === 'ETF' ? "Analyst ratings aren't available for ETFs." : `No analyst ratings are available for ${sec.symbol}.`));
    }
    const c = r.consensus;
    const ccol = c.includes('buy') ? 'var(--green-600)' : c.includes('sell') ? 'var(--orange-700)' : 'var(--gray-700)';
    const size = 112, stroke = 14, rad = (size - stroke) / 2, cx = size / 2;
    const total = r.buy + r.hold + r.sell;
    const arcs = [];
    let start = -Math.PI / 2;
    for (const [v, col] of [[r.buy, '#0A6D42'], [r.sell, '#B73A18'], [r.hold, '#606366']]) {
      if (!v) continue;
      const sweep = v / total * 2 * Math.PI;
      const a0 = start + 0.02, a1 = start + Math.max(0.02, sweep - 0.02);
      const p = (a) => `${cx + rad * Math.cos(a)} ${cx + rad * Math.sin(a)}`;
      arcs.push(IE.s('path', { d: `M${p(a0)} A${rad} ${rad} 0 ${a1 - a0 > Math.PI ? 1 : 0} 1 ${p(a1)}`, fill: 'none', stroke: col, 'stroke-width': stroke }));
      start += sweep;
    }
    const legend = (cls, label) => h('span', { class: 'quote-legend' }, h('span', { class: ['sw', cls] }), h('span', { class: ['tabular', cls + '-t'] }, label));
    return h('div', { class: 'quote-ratings' },
      h('div', { class: 'donut', 'aria-label': `${r.analysts} analyst ratings` },
        IE.s('svg', { width: size, height: size, viewBox: `0 0 ${size} ${size}`, 'aria-hidden': 'true' }, arcs),
        h('div', { class: 'mid' }, h('span', { class: 't-heading-lg tabular' }, String(r.analysts)), h('span', { class: 't-caption' }, 'ratings'))),
      h('div', { class: 'grow center' },
        h('div', { class: 't-heading-lg semibold', style: { color: ccol } }, c),
        h('div', { class: 't-body-md-book', style: 'margin-top:4px;color:var(--gray-700)' }, 'Overall analyst consensus (last 3 months).'),
        h('div', { class: 'quote-legends' }, legend('buy', `Buy ${r.buy}%`), legend('hold', `Hold ${r.hold}%`), legend('sell', `Sell ${r.sell}%`))));
  }

  // ── News carousel (Home's promo card style) ──
  function newsCarousel(sec) {
    const times = ['15 mins ago', '1 hr ago', '3 hrs ago'];
    return h('div', null,
      h('h2', { class: 't-heading-md semibold', style: 'margin:0 0 12px' }, 'News'),
      h('div', { class: 'quote-carousel' }, times.map((t, i) => h('button', {
        type: 'button', class: 'quote-promo',
        'aria-label': `Headline placeholder: story ${i + 1} about ${sec.name}. [News provider] · ${t} ${i + 1} of ${times.length}`,
        onclick: () => IE.notBuilt('News stories'),
      },
      h('span', { class: 'circle' }, icon('article', { size: 28, color: 'var(--gray-700)' })),
      h('span', { class: 'grow col', style: 'min-width:0;text-align:left' },
        h('span', { class: 't-heading-xs clamp2' }, `Headline placeholder: story ${i + 1} about ${sec.name}`),
        h('span', { class: 't-body-md-book muted ellipsis', style: 'margin-top:4px' }, `[News provider] · ${t}`))))));
  }

  function autoInvestCard(symbol) {
    return h('div', { class: 'quote-autoinvest' },
      h('div', { class: 't-body-lg semibold', style: 'color:var(--gray-900)' }, `Set up recurring buys of ${symbol}.`),
      h('div', { class: 't-body-lg-book', style: 'margin-top:2px;color:var(--gray-800)' }, 'Build your portfolio, the easy way.'),
      h('button', { type: 'button', class: 'getstarted', 'aria-label': `Get started with Auto Invest for ${symbol}`,
        onclick: () => IE.toast('Auto Invest is not built yet in this prototype.') }, 'Get started', icon('chevron_right', { size: 20 })));
  }

  // ── Events / About ──
  function detailsTabs(sec) {
    const panel = h('div', { class: 'mt16' });
    const show = (i) => mount(panel, i === 0 ? events(sec) : about(sec));
    show(0);
    return h('div', null, IE.segmented({ labels: ['Events', 'About'], selected: 0, onSelect: show }), panel);
  }

  function about(sec) {
    const p = D.research.profileOf(sec);
    if (!p) return h('p', { class: 't-body-md-book', style: 'margin:0;color:var(--gray-700)' }, `No company profile for ${sec.symbol} yet.`);
    return h('div', null, h('p', { class: 't-body-md-book', style: 'margin:0 0 20px' }, p.description), statGrid(p.facts));
  }

  function events(sec) {
    const list = D.research.eventsOf(sec);
    if (!list.length) return h('p', { class: 't-body-md-book', style: 'margin:0;color:var(--gray-700)' }, `No upcoming or recent events for ${sec.symbol}.`);
    const t = D.today();
    const upcoming = list.filter((e) => e.date > t);
    const todays = list.filter((e) => e.date.getTime() === t.getTime());
    const past = list.filter((e) => e.date < t);
    const label = (d) => (d.getFullYear() === t.getFullYear() ? IE.formatShortDate(d) : IE.formatDate(d));
    const title = (s) => h('h3', { class: 'quote-ev-title' }, s);
    const rows = (l, isPast) => l.map((e) => h('div', { class: 'quote-ev' },
      h('div', { style: 'width:100px;flex:none' }, h('span', { class: ['quote-tag', isPast && 'past'] }, e.kind === 'earnings' ? 'Earnings' : 'Ex-dividend')),
      h('div', { class: 'date tabular' }, label(e.date)),
      h('div', { class: 'grow t-body-md-book', style: 'padding-top:2px' }, e.description)));
    return h('div', null,
      upcoming.length ? [title('Upcoming'), rows(upcoming, false)] : null,
      todays.length ? h('div', { class: 'quote-today' }, title('Today'), rows(todays, false)) : null,
      past.length ? [title('Past'), rows(past, true)] : null);
  }

  // ── Screen ──
  IE.route('/quote/:symbol', (params, ctx) => {
    const symbol = String(params.symbol || '').toUpperCase();
    const base = D.securities.bySymbol(symbol);
    const back = () => (IE.router.canPop() ? IE.router.pop() : IE.router.go(IE.routes.home));
    if (!base) {
      return h('div', { class: 'col', style: 'height:100%' },
        IE.header({ title: '', onBack: back }).el,
        h('p', { class: 't-body-lg-book', style: 'margin:0;padding:20px' }, `No security found for "${params.symbol}".`));
    }

    let live = base;
    let rangeIdx = 0;
    let compact = false;
    let onWatchlist = D.portfolio.sharesHeldOf(symbol) > 0;
    const positions = D.holdings.positionsOf(symbol);
    const posState = { expanded: false, repaint: () => paintPosition() };

    // Top bar.
    const backBtn = IE.iconButton('arrow_back', 'Back', back);
    const alertBtn = IE.iconButton('notifications', `Set a price alert for ${symbol}`, () => IE.notBuilt('Price alerts'));
    const starBtn = h('button', { type: 'button', class: 'icon-btn', onclick: () => {
      onWatchlist = !onWatchlist;
      IE.haptic();
      paintStar();
      IE.toast(onWatchlist ? `Added ${symbol} to your watchlist` : `Removed ${symbol} from your watchlist`);
    } });
    function paintStar() {
      const label = onWatchlist ? `Remove ${symbol} from watchlist` : `Add ${symbol} to watchlist`;
      starBtn.title = label;
      starBtn.setAttribute('aria-label', label);
      starBtn.setAttribute('aria-pressed', String(onWatchlist));
      mount(starBtn, icon('star', { fill: onWatchlist }));
    }
    paintStar();
    const middle = h('div', { class: 'quote-compact-title' });
    const topBar = h('header', { class: 'quote-topbar' }, backBtn, middle, alertBtn, starBtn);
    function paintTop() {
      topBar.classList.toggle('compact', compact);
      mount(middle, compact ? h('span', { role: 'heading', 'aria-level': '1', 'aria-label': `${symbol} ${IE.formatPrice(live.quote.price)} ${live.currency}` },
        h('span', { class: 'sym' }, symbol), '  ', h('span', { class: 'px tabular' }, IE.formatPrice(live.quote.price))) : null);
    }

    // Dynamic sections.
    const priceSlot = h('div');
    const bidSlot = h('div', { class: 'quote-bid-slot' });
    const posSlot = h('div', { class: 'mt12' });
    const chartSlot = h('div', { class: 'mt24' });
    const linesSlot = h('div', { class: 'mt16' });
    function rangeStart() { return D.market.series(base, D.StockRange[rangeIdx].key)[0]; }
    function paintPrice() {
      mount(priceSlot, priceCard(live, rangeStart(), D.StockRange[rangeIdx]));
      mount(bidSlot, bidAsk(live));
    }
    function paintPosition() { if (positions.length) mount(posSlot, positionAccordion(posState, live, positions)); }
    function paintChart() {
      mount(chartSlot, chartSection(base, rangeIdx, (i) => { rangeIdx = i; paintChart(); paintPrice(); }));
    }
    function paintLines() { mount(linesSlot, numberLines(live)); }

    paintPrice(); paintPosition(); paintChart(); paintLines(); paintTop();
    if (!positions.length) posSlot.hidden = true;

    const content = h('div', { class: 'content quote-content' },
      h('div', { class: 'quote-header' },
        monogram(symbol, 52),
        h('div', { class: 'grow' },
          h('h1', { class: 't-heading-lg semibold', style: 'margin:0' }, symbol),
          h('div', { class: 't-body-lg-book muted' }, base.name)),
        base.fractional ? h('button', { type: 'button', class: 'quote-frac-tag',
          'aria-label': 'Fractional shares available. See all fractional stocks and ETFs',
          onclick: () => IE.router.push(IE.routes.fractional) }, 'Fractional') : null),
      h('div', { class: 'mt16' }, priceSlot),
      bidSlot,
      posSlot,
      chartSlot,
      h('h2', { class: 't-heading-md', style: 'margin:32px 0 0' }, 'Key Stats'),
      linesSlot,
      h('div', { class: 'mt24' }, fundamentals(base)),
      h('div', { class: 'mt24' }, ratingsCard(base)),
      h('div', { class: 'mt24' }, newsCarousel(base)),
      base.fractional ? h('div', { class: 'mt16' }, autoInvestCard(symbol)) : null,
      h('div', { class: 'mt24' }, detailsTabs(base)),
      h('div', { class: 'mt24' }, IE.notice('Prototype: prices, stats, ratings, chart, stories and events on this page are mock data.')));
    const body = h('div', { class: 'page-body' }, content);

    // Compact bar: once the price card is out of view; back when it's in view.
    let pending = false;
    body.addEventListener('scroll', () => {
      if (pending) return;
      pending = true;
      requestAnimationFrame(() => {
        pending = false;
        const pc = priceSlot.firstChild;
        if (!pc) return;
        const inView = pc.getBoundingClientRect().bottom > body.getBoundingClientRect().top;
        if (inView === compact) { compact = !inView; paintTop(); }
      });
    }, { passive: true });

    // Trade bar.
    const held = D.portfolio.sharesHeldOf(symbol);
    const tradeBar = h('div', { class: 'quote-tradebar' },
      h('button', { type: 'button', class: 'quote-sell', disabled: held === 0,
        'aria-label': held === 0 ? `Sell ${symbol}, none held` : `Sell ${symbol}`,
        onclick: () => { IE.haptic(); openTrade(base, 'sell'); } }, 'Sell'),
      h('button', { type: 'button', class: 'quote-buy', 'aria-label': `Buy ${symbol}`,
        onclick: () => { IE.haptic(); openTrade(base, 'buy'); } }, 'Buy'));

    // Live quote: up to ±0.06% a tick, rounded to the cent.
    const cents = (v) => Math.round(v * 100) / 100;
    const size = () => (1 + Math.floor(Math.random() * 30)) * 100;
    const bidGap = base.quote.price - base.quote.bid;
    const askGap = base.quote.ask - base.quote.price;
    ctx.interval(() => {
      const q = live.quote;
      const price = cents(q.price * (1 + (Math.random() - 0.5) * 0.0012));
      const nq = D.makeQuote(Object.assign({}, q, {
        price, bid: cents(price - bidGap), ask: cents(price + askGap),
        bidSize: size(), askSize: size(),
        volume: q.volume + (1 + Math.floor(Math.random() * 20)) * 100,
        dayLow: Math.min(q.dayLow, price), dayHigh: Math.max(q.dayHigh, price),
      }));
      live = D.withGetters(Object.assign({}, base, { quote: nq }), { get fractional() { return base.fractional; } });
      paintPrice(); paintPosition(); paintLines(); paintTop();
    }, 2000);
    ctx.watch('balancesHidden', paintPosition);

    return h('div', { class: 'col', style: 'height:100%' }, topBar, body, tradeBar);
  });
})();
