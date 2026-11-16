// Holdings (lib/screens/holdings/holdings_screen.dart): account pills with
// the sub-account switcher, value tabs, the total, Cash and Stocks & ETFs
// accordions, a condensed account selector in the header once the pills
// scroll away, and the auto-hiding bottom bar.
(function () {
  const { h, icon, mount } = IE;
  const D = IE.data;
  const R = IE.routes;

  /** Sort options for Stocks & ETFs. Market value is the default. */
  const HoldingsSort = [
    { key: 'weight', label: 'Market value' },
    { key: 'dailyChange', label: 'Daily change $' },
    { key: 'dailyChangePercent', label: 'Daily change %' },
    { key: 'assetType', label: 'Asset type' },
    { key: 'ticker', label: 'Ticker' },
    { key: 'name', label: 'Name' },
    { key: 'quantity', label: 'Quantity' },
    { key: 'currency', label: 'Currency' },
    { key: 'price', label: 'Price' },
    { key: 'marketValueChange', label: 'Market value change' },
    { key: 'totalGain', label: 'Total gain/loss' },
  ];

  /** Which value the summary shows above the intraday change. */
  const ValueView = ['Most recent', 'Last business day', 'Book value'];

  // ── Popup menu (Flutter PopupMenuButton with checked items) ──
  /**
   * Opens a menu under [anchor]. items: [{value, label}]. Resolves with the
   * picked value, or undefined when dismissed. Shared by Activity and
   * Fractional (IE.hxPopupMenu).
   */
  function popupMenu(anchor, items, selected) {
    return new Promise((resolve) => {
      const app = document.getElementById('app');
      const a = app.getBoundingClientRect();
      const r = anchor.getBoundingClientRect();
      let done = false;
      const unregister = IE.registerOverlay(() => close());
      const catcher = h('div', { class: 'hx-menu-catcher', onclick: () => close() });
      const menu = h('div', { class: 'hx-menu', role: 'menu' }, items.map((it) => h('button', {
        type: 'button', role: 'menuitemradio', 'aria-checked': String(it.value === selected),
        class: ['hx-menu-item', it.value === selected && 'checked'],
        onclick: () => close(it.value),
      }, h('span', { class: 'hx-menu-check' }, it.value === selected ? icon('check', { size: 20 }) : null), h('span', null, it.label))));
      const left = Math.min(r.left - a.left, a.width - 248);
      menu.style.left = Math.max(8, left) + 'px';
      const top = r.bottom - a.top;
      app.append(catcher, menu);
      // Open downward; flip up if it would run off the bottom.
      const mh = menu.offsetHeight;
      if (top + mh > a.height - 8 && r.top - a.top - mh > 8) menu.style.top = (r.top - a.top - mh) + 'px';
      else menu.style.top = Math.min(top, a.height - mh - 8) + 'px';
      requestAnimationFrame(() => menu.classList.add('open'));
      function close(v) {
        if (done) return;
        done = true;
        unregister();
        catcher.remove();
        menu.remove();
        resolve(v);
      }
    });
  }
  IE.hxPopupMenu = popupMenu;

  // ── Pieces ──
  function sortRows(list, sort) {
    const desc = (x, y) => y - x;
    const byTicker = (a, b) => a.security.symbol.localeCompare(b.security.symbol);
    const l = [...list];
    switch (sort) {
      case 'weight': l.sort((a, b) => desc(a.weightPercent, b.weightPercent)); break;
      case 'dailyChange': l.sort((a, b) => desc(a.security.quote.change, b.security.quote.change)); break;
      case 'dailyChangePercent': l.sort((a, b) => desc(a.dayChangePercent, b.dayChangePercent)); break;
      case 'assetType': l.sort((a, b) => a.security.type.localeCompare(b.security.type) || byTicker(a, b)); break;
      case 'ticker': l.sort(byTicker); break;
      case 'name': l.sort((a, b) => a.security.name.localeCompare(b.security.name)); break;
      case 'quantity': l.sort((a, b) => b.shares - a.shares); break;
      case 'currency': l.sort((a, b) => a.security.currency.localeCompare(b.security.currency) || byTicker(a, b)); break;
      case 'price': l.sort((a, b) => desc(a.security.quote.price, b.security.quote.price)); break;
      case 'marketValueChange': l.sort((a, b) => desc(a.dayChangeCad, b.dayChangeCad)); break;
      case 'totalGain': l.sort((a, b) => desc(a.totalGainCad, b.totalGainCad)); break;
      default: break;
    }
    return l;
  }

  /** The placeholder row's value for the current sort. Market data stays
   *  visible when balances are hidden; the client's own amounts are masked. */
  function sortValue(hd, sort, hidden) {
    const s = hd.security;
    if (hidden && ['weight', 'quantity', 'marketValueChange', 'totalGain'].includes(sort)) return IE.HIDDEN;
    switch (sort) {
      case 'weight': return hd.weightPercent.toFixed(1) + '%';
      case 'dailyChange': return `${IE.formatSignedCad(s.quote.change)} ${s.currency}`;
      case 'dailyChangePercent': return IE.formatSignedPercent(hd.dayChangePercent);
      case 'assetType': return s.type;
      case 'ticker': return s.exchange;
      case 'name': return s.name;
      case 'quantity': return `${IE.formatWhole(hd.shares)} shares`;
      case 'currency': return s.currency;
      case 'price': return `${IE.formatPrice(s.quote.price)} ${s.currency}`;
      case 'marketValueChange': return `${IE.formatSignedCad(hd.dayChangeCad)} CAD`;
      case 'totalGain': return `${IE.formatSignedCad(hd.totalGainCad)} CAD`;
      default: return '';
    }
  }

  /** Stand-in row until the row design is decided. */
  function placeholderRow(leading, trailing, onTap) {
    return h(onTap ? 'button' : 'div', {
      type: onTap ? 'button' : null, class: ['holdings-prow', onTap && 'tappable'], onclick: onTap || null,
    },
    h('span', { class: 't-body-lg semibold' }, leading),
    h('span', { class: 'holdings-prow-tbd t-caption' }, 'Row design TBD'),
    h('span', { class: 'holdings-prow-val t-body-md tabular' }, trailing));
  }

  /** Card with a tappable header (title, value, optional change, chevron). */
  function accordion({ title, value, currency, change, changePercent, expanded, onToggle, body, hidden }) {
    const changeCls = (change || 0) >= 0 ? 'pos' : 'neg';
    const label = hidden ? `${title}, amount hidden`
      : `${title}, ${IE.formatPrice(value)} ${currency}${change == null ? '' : `, ${IE.formatSignedCad(change)} today`}`;
    return h('div', { class: 'holdings-acc' },
      h('button', { type: 'button', class: 'holdings-acc-head', 'aria-expanded': String(expanded), 'aria-label': label, onclick: onToggle },
        h('span', { class: 'holdings-acc-title t-heading-sm semibold' }, title),
        h('span', { class: 'holdings-acc-vals' },
          h('span', { class: 't-heading-xs tabular' }, `${hidden ? IE.HIDDEN : IE.formatPrice(value)} ${currency}`),
          change != null && changePercent != null
            ? h('span', { class: ['t-body-md-book tabular', changeCls] }, `${hidden ? IE.HIDDEN : IE.formatSignedCad(change)} (${IE.formatSignedPercent(changePercent)})`)
            : null),
        icon('keyboard_arrow_down', { size: 28, color: 'var(--gray-600)', class: expanded ? 'holdings-acc-chev open' : 'holdings-acc-chev' })),
      expanded ? h('div', { class: 'holdings-acc-body' }, body) : null);
  }

  function cashLink(label, onTap) {
    return h('button', { type: 'button', class: 'holdings-cash-link', onclick: onTap }, label);
  }

  // ── Screen ──
  IE.route('/holdings', (params, ctx) => {
    const accounts = D.portfolio.accounts;
    const st = {
      account: null,
      sub: 'combined',
      view: IE.store.get('holdingsView') || 0,
      cashOpen: false,
      stocksOpen: true,
      sort: 'weight',
    };
    const initial = ctx.query.get('account');
    if (initial && D.portfolio.accountNamed(initial)) {
      st.account = initial;
      const s = ctx.query.get('sub');
      st.sub = s === 'cad' || s === 'usd' ? s : 'combined';
      IE.rememberAccount(initial);
    }
    const subParam = () => (st.account ? IE.subParam(st.sub) : null);

    function selectAccount(name) {
      IE.haptic();
      IE.rememberAccount(name);
      st.account = name;
      st.sub = 'combined';
      render(true);
    }

    function openMove(exchange) {
      const currency = st.sub === 'cad' ? 'CAD' : st.sub === 'usd' ? 'USD' : null;
      const specific = st.account != null && currency != null;
      const q = {};
      if (specific) { q.account = st.account; q.currency = currency; }
      if (exchange) q[specific ? 'mode' : 'open'] = 'exchange';
      else q.open = specific ? 'options' : 'banking';
      IE.router.push(IE.withQuery(R.transfer, q));
    }

    function openSettings() {
      IE.router.push(st.account ? IE.withQuery(R.accountSettings, { account: st.account }) : R.accountSettings);
    }

    function back() {
      if (IE.navHistory.goBack({ withAccount: true, account: st.account, sub: subParam() })) return true;
      if (IE.router.canPop()) IE.router.pop(); else IE.router.go(R.home);
      return true;
    }
    ctx.setPopHandler(() => IE.navHistory.goBack({ withAccount: true, account: st.account, sub: subParam() }));

    const gear = IE.iconButton('settings', 'Account settings', openSettings);
    const filter = IE.accountFilter({
      accounts, selected: st.account, onSelected: selectAccount,
      subAccount: st.sub,
      onSubAccount: (v) => { IE.haptic(); st.sub = v; render(false); },
    });
    const filterWrap = h('div', null, filter);
    const tabs = IE.underlineTabs({
      labels: ValueView, selected: st.view,
      onSelect: (i) => { st.view = i; IE.store.set('holdingsView', i); renderSummary(); },
    });
    const summaryMount = h('div');
    const accMount = h('div', { class: 'pad-x' });
    const body = h('div', { class: 'content holdings', style: 'padding-bottom:32px' },
      filterWrap, h('div', { style: 'height:16px' }), tabs, h('div', { style: 'height:20px' }),
      summaryMount, h('div', { style: 'height:24px' }), accMount);

    const bar = IE.navBar(ctx, { current: 'holdings', account: st.account, subAccount: subParam() });
    const page = IE.chromePage(ctx, {
      title: 'Holdings',
      onBack: back,
      actions: [gear, h('span', { style: 'width:4px' })],
      body,
      bottomBar: bar,
      swapTitleAt: 56,
      condensedTitle: () => IE.condensedAccountSelector({ accounts, selected: st.account, onSelected: selectAccount }),
    });
    ctx.onDispose(IE.onHeight(filterWrap, (px) => { if (px > 0) page.setSwapAt(px); }));

    /** Totals for the selection (same arithmetic as the Flutter screen). */
    function totals() {
      const selected = st.account ? D.portfolio.accountNamed(st.account) : null;
      const scope = selected ? [selected] : accounts;
      let total = selected ? selected.value : D.portfolio.totalValue;
      let change;
      if (!selected) change = D.portfolio.series('oneDay').change;
      else { const p = selected.changePercent / 100; change = selected.value - selected.value / (1 + p); }
      let cashCad = scope.reduce((s, a) => s + a.cashCad, 0);
      let cashUsd = scope.reduce((s, a) => s + a.cashUsd, 0);
      let cashTotal = cashCad + D.market.toCad(cashUsd, 'USD');
      let stocksValue = total - cashTotal;
      const stocksChangePercent = change / (stocksValue - change) * 100;
      const sub = selected ? st.sub : 'combined';
      if (selected && sub !== 'combined') {
        const investedCad = stocksValue;
        if (sub === 'cad') { stocksValue = investedCad * (1 - selected.usdShare); cashUsd = 0; cashTotal = cashCad; }
        else { stocksValue = investedCad * selected.usdShare / D.market.usdToCad; cashCad = 0; cashTotal = cashUsd; }
        total = stocksValue + cashTotal;
        const p = stocksChangePercent / 100;
        change = stocksValue - stocksValue / (1 + p);
      }
      const currency = sub === 'usd' ? 'USD' : 'CAD';
      const changePercent = total - change === 0 ? 0 : change / (total - change) * 100;
      const held = D.holdings.all;
      const bookRatio = held.reduce((s, x) => s + x.bookValueCad, 0) / held.reduce((s, x) => s + x.marketValueCad, 0);
      const bookValue = cashTotal + stocksValue * bookRatio;
      return { selected, sub, total, change, changePercent, cashCad, cashUsd, cashTotal, stocksValue, stocksChangePercent, currency, bookValue };
    }

    function renderSummary() {
      const t = totals();
      const hidden = IE.store.get('balancesHidden');
      let shown, caption, lineChange = null, linePercent = null;
      if (st.view === 0) { shown = t.total; caption = 'Intraday change'; lineChange = t.change; linePercent = t.changePercent; }
      else if (st.view === 1) { shown = t.total - t.change; caption = `At close, ${IE.formatShortDate(D.market.usdToCadAsOf)}`; }
      else {
        shown = t.bookValue; caption = 'Unrealized gain/loss';
        lineChange = t.total - t.bookValue;
        linePercent = t.bookValue === 0 ? 0 : (t.total - t.bookValue) / t.bookValue * 100;
      }
      const up = (lineChange || 0) >= 0;
      mount(summaryMount, h('div', { class: 'holdings-summary pad-x' },
        h('div', { class: 'holdings-total-row' },
          h('div', { class: 'holdings-total', 'aria-label': hidden ? `${ValueView[st.view]} value hidden` : null },
            h('span', { class: 't-display-md semibold tabular' }, hidden ? '$' + IE.HIDDEN : IE.formatCad(shown)),
            h('span', { class: 't-body-lg semibold', style: 'color:var(--gray-700)' }, ' ' + t.currency)),
          IE.iconButton(hidden ? 'visibility_off' : 'visibility', hidden ? 'Show balance' : 'Hide balance', () => {
            IE.haptic();
            IE.store.set('balancesHidden', !IE.store.get('balancesHidden'));
          }, { color: 'var(--gray-600)' })),
        h('div', { class: 'holdings-caption' },
          h('span', { class: 't-body-md-book muted' }, caption),
          lineChange != null ? h('span', { class: ['row t-body-md semibold tabular', up ? 'pos' : 'neg'] },
            icon(up ? 'arrow_drop_up' : 'arrow_drop_down'),
            `${hidden ? IE.HIDDEN : IE.formatSignedCad(lineChange)} (${IE.formatSignedPercent(linePercent)})`) : null)));
    }

    function renderAccordions() {
      const t = totals();
      const hidden = IE.store.get('balancesHidden');
      const cashRows = [];
      if (t.sub !== 'usd') cashRows.push(placeholderRow('CAD', `${hidden ? IE.HIDDEN : IE.formatPrice(t.cashCad)} CAD`));
      if (t.sub !== 'cad') cashRows.push(placeholderRow('USD', `${hidden ? IE.HIDDEN : IE.formatPrice(t.cashUsd)} USD`));
      const cash = accordion({
        title: 'Cash', value: t.cashTotal, currency: t.currency, hidden,
        expanded: st.cashOpen, onToggle: () => { st.cashOpen = !st.cashOpen; renderAccordions(); },
        body: h('div', { class: 'col gap8' }, cashRows,
          h('div', { class: 'row', style: 'gap:24px' }, cashLink('Add cash', () => openMove(false)), cashLink('Exchange', () => openMove(true)))),
      });
      const list = t.selected ? D.holdings.inAccount(t.selected.name, t.sub === 'cad' ? 'CAD' : t.sub === 'usd' ? 'USD' : null) : D.holdings.all;
      const sorted = sortRows(list, st.sort);
      const sortLabel = HoldingsSort.find((x) => x.key === st.sort).label;
      const sortBtn = h('button', {
        type: 'button', class: 'holdings-sort', title: 'Sort holdings', 'aria-label': `Sort holdings, by ${sortLabel}`,
        onclick: async () => {
          const v = await popupMenu(sortBtn, HoldingsSort.map((x) => ({ value: x.key, label: x.label })), st.sort);
          if (v && v !== st.sort) { IE.haptic(); st.sort = v; renderAccordions(); }
        },
      }, h('span', { class: 't-body-md-book muted' }, 'Sort by ', h('span', { style: 'color:var(--gray-800)' }, sortLabel)),
      icon('keyboard_arrow_down', { color: 'var(--gray-600)' }));
      const stocks = accordion({
        title: 'Stocks & ETFs', value: t.stocksValue, currency: t.currency, change: t.change, changePercent: t.stocksChangePercent, hidden,
        expanded: st.stocksOpen, onToggle: () => { st.stocksOpen = !st.stocksOpen; renderAccordions(); },
        body: h('div', { class: 'col' }, h('div', null, sortBtn), h('div', { class: 'col gap8', style: 'margin-top:8px' },
          sorted.map((hd) => placeholderRow(hd.security.symbol, sortValue(hd, st.sort, hidden), () => IE.router.push(`${R.quote}/${hd.security.symbol}`))))),
      });
      mount(accMount, cash, h('div', { style: 'height:12px' }), stocks, h('div', { style: 'height:12px' }),
        h('button', { type: 'button', class: 'holdings-download', onclick: () => IE.notBuilt('Download holdings') },
          icon('download', { color: 'var(--brand-600)' }), h('span', { class: 't-body-lg-book' }, 'Download holdings')),
        h('div', { style: 'height:24px' }),
        IE.notice('Prototype: row designs for Cash and Stocks & ETFs are TBD, so rows are placeholders. Values are mock data.'));
    }

    function render(accountChanged) {
      const sel = st.account ? D.portfolio.accountNamed(st.account) : null;
      gear.title = sel ? `${sel.name} settings` : 'Account settings';
      gear.setAttribute('aria-label', gear.title);
      filter.update({ selected: st.account, subAccount: st.sub });
      bar.update({ account: st.account, subAccount: subParam() });
      page.setCondensedTitle(() => IE.condensedAccountSelector({ accounts, selected: st.account, onSelected: selectAccount }));
      renderSummary();
      renderAccordions();
      if (accountChanged && page.body.scrollTop > 0) {
        // Picking an account reveals its pill (scrolls back to the top), as
        // Flutter's ensureVisible does.
        page.body.scrollTo({ top: 0, behavior: IE.reduceMotion() ? 'auto' : 'smooth' });
      }
    }
    ctx.watch('balancesHidden', () => { renderSummary(); renderAccordions(); });
    render(false);
    return page.el;
  });

  IE.holdingsSorts = HoldingsSort;
})();
