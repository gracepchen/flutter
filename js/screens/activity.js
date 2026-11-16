// Activity (lib/screens/activity/activity_screen.dart): a top-level page
// (no Back) with account pills, Recent / History tabs, the order-type menu
// and "As of" time on Recent, placeholder content and long mock lists.
(function () {
  const { h, icon, mount } = IE;
  const D = IE.data;
  const R = IE.routes;

  const OrderFilter = [
    { key: 'all', label: 'All orders' },
    { key: 'stocks', label: 'Stocks/ETFs' },
    { key: 'transfers', label: 'Transfers/Exchanges' },
  ];

  // ── Mock orders and transactions (newest first) ──
  const ACCOUNTS = ['TFSA', 'Non-registered', 'RRSP', 'FHSA', 'RESP'];
  const SYMBOLS = ['CM', 'XEQT', 'TD', 'VFV', 'ENB', 'RY', 'AAPL', 'CNQ', 'XIC', 'NVDA',
    'BNS', 'SU', 'BMO', 'CNR', 'GOOGL', 'ATD', 'T', 'AMZN', 'BCE', 'CLS'];
  const STATUSES = ['Open', 'Filled', 'Filled', 'Partially filled', 'Filled', 'Cancelled'];
  const day = (i) => { const d = new Date(2026, 9, 19); d.setDate(d.getDate() - (i * 2 + Math.floor(i / 3))); return d; };

  const ORDERS = Array.from({ length: 24 }, (_, i) => (i % 4 === 3
    ? {
      title: i % 8 === 3 ? `Transfer $${250 * (i % 5 + 1)} CAD` : `Exchange $${100 * (i % 6 + 1)} CAD to USD`,
      account: ACCOUNTS[i % ACCOUNTS.length], date: day(i), trailing: i < 4 ? 'Pending' : 'Completed', transfer: true,
    }
    : {
      title: `${i % 2 === 0 ? 'Buy' : 'Sell'} ${(i % 7 + 1) * 5} ${SYMBOLS[i % SYMBOLS.length]}`,
      account: ACCOUNTS[i % ACCOUNTS.length], date: day(i), trailing: STATUSES[i % STATUSES.length], transfer: false,
    }));

  const TRANSACTIONS = Array.from({ length: 30 }, (_, i) => {
    const account = ACCOUNTS[i % ACCOUNTS.length];
    const date = day(i);
    switch (i % 5) {
      case 0: return { title: `Dividend ${SYMBOLS[i % SYMBOLS.length]}`, account, date, trailing: `+$${(12.4 + i * 3.17).toFixed(2)}` };
      case 1: return { title: 'Contribution', account, date, trailing: `+$${100 * (i % 4 + 1)}.00` };
      case 2: return { title: `Bought ${(i % 6 + 1) * 5} ${SYMBOLS[i % SYMBOLS.length]}`, account, date, trailing: `−$${(310.5 + i * 41.3).toFixed(2)}` };
      case 3: return { title: `Sold ${(i % 4 + 1) * 5} ${SYMBOLS[i % SYMBOLS.length]}`, account, date, trailing: `+$${(280.2 + i * 37.9).toFixed(2)}` };
      default: return { title: 'Interest', account, date, trailing: `+$${(0.42 + i * 0.11).toFixed(2)}` };
    }
  });

  function orders(account, filter) {
    return ORDERS.filter((r) => (!account || r.account === account)
      && (filter === 'all' || (filter === 'stocks' ? !r.transfer : r.transfer)));
  }
  function transactions(account) { return TRANSACTIONS.filter((r) => !account || r.account === account); }

  function mockRows(rows) {
    if (!rows.length) return h('p', { class: 't-body-md-book muted', style: 'margin:0' }, 'Nothing to show for this account.');
    return h('div', null, rows.map((r) => h('div', { class: 'activity-row' },
      h('div', { class: 'grow' },
        h('div', { class: 't-body-lg', style: 'color:var(--gray-900)' }, r.title),
        h('div', { class: 't-body-md-book muted', style: 'margin-top:2px' }, `${r.account} • ${IE.formatDate(r.date)}`)),
      h('span', { class: 't-body-md tabular', style: 'color:var(--gray-800);white-space:nowrap' }, r.trailing))));
  }

  /** Eastern time (fixed UTC−4 in the prototype; no DST handling). */
  function etTime(d) {
    const t = new Date(d.getTime() + d.getTimezoneOffset() * 60000 - 4 * 3600000);
    const hr = t.getHours() % 12 || 12;
    const p = (n) => String(n).padStart(2, '0');
    return `${hr}:${p(t.getMinutes())}:${p(t.getSeconds())}`;
  }

  IE.route('/activity', (params, ctx) => {
    const accounts = D.portfolio.accounts;
    const st = {
      account: null,
      sub: 'combined',
      tab: IE.store.get('activityTab') || 0,
      orders: 'all',
      asOf: new Date(),
    };
    const initial = ctx.query.get('account');
    if (initial && D.portfolio.accountNamed(initial)) {
      st.account = initial;
      const s = ctx.query.get('sub');
      st.sub = s === 'cad' || s === 'usd' ? s : 'combined';
      IE.rememberAccount(initial);
    }
    const history = () => st.tab === 1;
    const barSub = () => (history() && st.account ? IE.subParam(st.sub) : null);

    function selectAccount(name) {
      IE.haptic();
      IE.rememberAccount(name);
      st.account = name;
      st.sub = 'combined';
      render(true);
    }

    // System back retraces the main pages (the account follows); else the
    // router pops back to Home.
    ctx.setPopHandler(() => IE.navHistory.goBack({ withAccount: true, account: st.account, sub: barSub() }));

    const filter = IE.accountFilter({
      accounts, selected: st.account, onSelected: selectAccount, showAddAccount: false,
      subAccount: st.sub, onSubAccount: history() ? onSub : null,
    });
    function onSub(v) { IE.haptic(); st.sub = v; render(false); }
    const filterWrap = h('div', null, filter);
    const tabs = IE.underlineTabs({
      labels: ['Recent', 'History'], selected: st.tab,
      onSelect: (i) => { st.tab = i; IE.store.set('activityTab', i); render(false); },
    });
    const ordersBarMount = h('div');
    const listMount = h('div');
    const placeholder = IE.placeholderContent({
      title: 'Activity', iconName: 'schedule', showHeader: false,
      summary: 'Track the progress of deposits, transfers, orders and account requests, and see your full transaction history.',
      planned: [
        'Timeline of pending and completed requests',
        'Full transaction history: deposits, trades, dividends and transfers',
        'Filters by type: deposits, transfers, orders and account changes',
        'Push notification when a request changes state',
        'Notification deep links land here through the same auth guard as in-app navigation',
      ],
    });
    const body = h('div', { class: 'content activity', style: 'padding-bottom:32px' },
      filterWrap, h('div', { style: 'height:16px' }), tabs,
      h('div', { class: 'pad-x' }, ordersBarMount, h('div', { style: 'height:24px' }), placeholder, h('div', { style: 'height:24px' }), listMount));

    const bar = IE.navBar(ctx, { current: 'activity', account: st.account, subAccount: barSub() });
    const page = IE.chromePage(ctx, {
      title: 'Activity',
      topLevel: true,
      actions: [IE.iconButton('notifications', 'Trade fill alerts', () => IE.notBuilt('Trade fill alerts')), h('span', { style: 'width:4px' })],
      body,
      bottomBar: bar,
      swapTitleAt: 56,
      condensedTitle: () => IE.condensedAccountSelector({ accounts, selected: st.account, onSelected: selectAccount }),
    });
    ctx.onDispose(IE.onHeight(filterWrap, (px) => { if (px > 0) page.setSwapAt(px); }));

    function refresh() { IE.haptic(); st.asOf = new Date(); renderOrdersBar(); }

    function renderOrdersBar() {
      if (history()) { mount(ordersBarMount); return; }
      const label = OrderFilter.find((f) => f.key === st.orders).label;
      const btn = h('button', {
        type: 'button', class: 'activity-filter', title: 'Order type', 'aria-label': `Order type, ${label}`,
        onclick: async () => {
          const v = await IE.hxPopupMenu(btn, OrderFilter.map((f) => ({ value: f.key, label: f.label })), st.orders);
          if (v && v !== st.orders) { IE.haptic(); st.orders = v; renderOrdersBar(); renderList(); }
        },
      }, h('span', { class: 't-body-lg-book' }, label), icon('keyboard_arrow_down', { color: 'var(--gray-700)' }));
      mount(ordersBarMount, h('div', { class: 'activity-orders-bar', style: 'margin-top:8px' },
        btn,
        h('span', { class: 'activity-asof t-body-md-book tabular' }, `As of ${etTime(st.asOf)} ET`),
        h('button', { type: 'button', class: 'activity-refresh', title: 'Refresh orders', 'aria-label': 'Refresh orders', onclick: refresh },
          icon('refresh', { size: 20 }))));
    }

    function renderList() {
      mount(listMount, mockRows(history() ? transactions(st.account) : orders(st.account, st.orders)));
    }

    function render(accountChanged) {
      filter.update({ selected: st.account, subAccount: st.sub, onSubAccount: history() ? onSub : null });
      bar.update({ account: st.account, subAccount: barSub() });
      page.setCondensedTitle(() => IE.condensedAccountSelector({ accounts, selected: st.account, onSelected: selectAccount }));
      renderOrdersBar();
      renderList();
      if (accountChanged && page.body.scrollTop > 0) page.body.scrollTo({ top: 0, behavior: IE.reduceMotion() ? 'auto' : 'smooth' });
    }
    render(false);
    return page.el;
  });
})();
