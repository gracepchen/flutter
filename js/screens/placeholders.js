// Placeholder destinations (lib/screens/action_screens.dart,
// placeholder_screen.dart, account_settings_list_screen.dart): each states
// what the screen is for and what it's planned to hold.
(function () {
  const { h, icon } = IE;
  const D = IE.data;
  const R = IE.routes;

  /** A placeholder page: sticky condensing header, the placeholder body and
   *  (for Portfolio's pages) the bottom bar. */
  function placeholderPage(ctx, { title, iconName, initials, summary, planned, extra, footer, nav }) {
    const body = h('div', { class: 'content', style: 'padding:8px 20px 32px' },
      IE.placeholderContent({ title, iconName, initials, summary, planned, extra, footer }));
    return IE.chromePage(ctx, {
      title, body,
      bottomBar: nav ? IE.navBar(ctx, { current: nav }) : null,
    }).el;
  }
  IE.placeholderPage = placeholderPage;

  /** "Selected security   XEQT": what the route preselected. */
  function selectionSummary(label, value) {
    return h('div', { class: 'ph-summary' },
      h('span', { class: 'grow t-body-md-book muted' }, label),
      h('span', { class: 't-body-lg semibold', style: 'color:var(--gray-800)' }, value));
  }
  function summaries(items) {
    const list = items.filter(Boolean);
    return list.length ? h('div', { class: 'col gap8' }, list.map(([l, v]) => selectionSummary(l, v))) : null;
  }

  IE.route('/add', (p, ctx) => {
    const type = ctx.query.get('type');
    const account = ctx.query.get('account');
    return placeholderPage(ctx, {
      title: 'Add funds', iconName: 'add',
      summary: "Deposit money into an Investor's Edge account from a linked bank account.",
      extra: summaries([type && ['Deposit type', type], account && ['Destination account', account]]),
      planned: [
        'Choose a destination account: TFSA, RRSP, FHSA, RESP or Non-registered',
        'Pick a linked bank account, or link a new one',
        'Show remaining TFSA, RRSP and FHSA contribution room before confirming',
        'One-time or recurring (pre-authorized) contributions',
        'Review-and-confirm step, with biometric step-up for large amounts',
      ],
    });
  });

  IE.route('/trade', (p, ctx) => {
    const account = ctx.query.get('account');
    const symbol = ctx.query.get('symbol');
    const side = ctx.query.get('side');
    return placeholderPage(ctx, {
      title: 'Trade', iconName: 'trending_up',
      summary: 'Buy and sell stocks, ETFs and options on Canadian and U.S. markets.',
      extra: summaries([
        account && ['Account', account],
        symbol && ['Selected security', symbol],
        side && ['Order', side === 'sell' ? 'Sell' : 'Buy'],
      ]),
      planned: [
        'Symbol search with live quote, bid/ask and day range',
        'Buy / Sell toggle: green for Buy, orange for Sell (OBR trade-flow tokens)',
        'Order types: market, limit, stop and stop-limit; day or good-till-cancelled',
        'Account picker with buying power in CAD and USD',
        'Review-and-confirm screen before the order is sent',
      ],
    });
  });

  IE.route('/performance', (p, ctx) => placeholderPage(ctx, {
    title: 'Performance', iconName: 'show_chart', nav: 'performance',
    summary: 'Your rate of return and how your balance has changed over time.',
    planned: [
      'Rate of return for the whole portfolio and for each account',
      'Balance trend over time, with deposits and withdrawals marked',
      'Time ranges from 1 month to since the account opened',
    ],
  }));

  IE.route('/advanced-chart', (p, ctx) => {
    const symbol = ctx.query.get('symbol');
    return placeholderPage(ctx, {
      title: 'Advanced chart', iconName: 'query_stats',
      summary: 'A full-screen, interactive chart for deeper analysis.',
      extra: symbol ? selectionSummary('Selected security', symbol) : null,
      planned: [
        'Candlestick, line and area views, with landscape full-screen',
        'Technical indicators such as moving averages, RSI and MACD',
        'Drawing tools and comparison against other securities or an index',
        'Custom date ranges and intraday intervals',
      ],
    });
  });

  IE.route('/account-settings', (p, ctx) => {
    const account = ctx.query.get('account');
    if (!account) return accountSettingsList(ctx);
    const a = D.portfolio.anyAccountNamed(account);
    return placeholderPage(ctx, {
      title: `${account} settings`, iconName: 'settings',
      summary: 'Settings for this account only.',
      extra: summaries([['Account', account], a && ['Account number', a.number]]),
      planned: [
        'Account nickname and the order accounts appear in',
        'Statements, trade confirmations and tax slips for this account',
        'Trading permissions, such as options and margin',
        'Beneficiary or successor holder designation (registered accounts)',
        'Contribution room and history (TFSA, RRSP, FHSA and RESP)',
        'Transfer out or close the account',
      ],
    });
  });

  /** Account Settings: "MY ACCOUNTS" with a row per account, then "Open an account". */
  function accountSettingsList(ctx) {
    const rows = D.portfolio.accounts.map((a) => h('button', {
      type: 'button', class: 'ph-acct-row', 'aria-label': `${a.label} settings`,
      onclick: () => IE.router.push(IE.withQuery(R.accountSettings, { account: a.name })),
    }, h('span', { class: 'grow t-body-lg semibold' }, a.label), icon('chevron_right', { color: 'var(--brand-600)' })));
    const body = h('div', { class: 'content', style: 'padding:16px 20px 32px' },
      h('div', { class: 'row' },
        h('h2', { class: 'grow', style: 'margin:0;font-size:16px;line-height:20px;font-weight:500;letter-spacing:1.6px;color:var(--gray-700)' }, 'MY ACCOUNTS'),
        IE.iconButton('more_horiz', 'More options', () => IE.notBuilt('More options'), { class: 'round-gray', style: 'width:40px;height:40px' })),
      h('div', { class: 'ph-acct-list', style: 'margin-top:12px' }, rows),
      h('button', { type: 'button', class: 'ph-open', style: 'margin-top:40px', onclick: () => IE.notBuilt('Open an account') },
        h('span', { class: 'grow t-body-lg semibold' }, 'Open an account'), icon('add_circle', { color: 'var(--brand-600)' })));
    return IE.chromePage(ctx, { title: 'Account Settings', body }).el;
  }

  IE.route('/contributions', (p, ctx) => placeholderPage(ctx, {
    title: 'Account contributions', iconName: 'bar_chart', nav: 'contributions',
    summary: "What you've put into each registered account this year, and how much room you have left.",
    planned: [
      'Year-to-date contributions for TFSA, RRSP, FHSA and RESP',
      'Remaining contribution room for each account',
      'RRSP contribution deadline reminder',
      'Over-contribution warnings before a deposit goes through',
      'Contribution history by account and year',
    ],
  }));

  IE.route('/notifications', (p, ctx) => placeholderPage(ctx, {
    title: "Notifications & What's New", iconName: 'campaign',
    summary: "Alerts about your accounts and orders, plus announcements about new features in Investor's Edge.",
    planned: [
      'Order fills, cancellations and expiries',
      "Price alerts you've set on stocks and ETFs",
      'Deposits, transfers and contributions when they settle',
      'Dividends paid and upcoming ex-dividend dates for your holdings',
      'Documents ready: statements, trade confirmations and tax slips',
      "What's new: feature announcements and tips",
    ],
  }));

  IE.route('/watchlists', (p, ctx) => placeholderPage(ctx, {
    title: 'Watchlists', iconName: 'star', nav: 'watchlists',
    summary: "Securities you're following, grouped into lists. Content TBD.",
  }));
})();
