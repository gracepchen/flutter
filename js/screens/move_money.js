// Move money (lib/screens/move/move_money_screen.dart).
//
// /transfer?account=&currency=&open=banking|exchange|options&mode=exchange
// - account (+ currency): preselected source, that account's CAD (or USD) side
// - mode=exchange: fills in account's exchange from currency to the other
// - open: opens the From sheet on arrival: 'banking' / 'exchange' (that tab)
//   or 'options' (account's currency side with One-time transfer /
//   Recurring deposit). Holdings' Cash links use these.
(function () {
  const { h, icon, mount } = IE;
  const D = IE.data;

  /** One side of a move: a linked bank, or one currency of an account. */
  function bankEndpoint(b) {
    return { title: b.bank, number: b.number, currency: b.currency, balance: b.balance, available: null, isBank: true };
  }
  /** [account]'s [currency] sub-account: its cash plus its share of the invested value. */
  function subEndpoint(account, currency) {
    const rate = D.market.usdToCad;
    const invested = account.value - account.cashCad - account.cashUsd * rate;
    const usd = currency === 'USD';
    return {
      title: account.name, number: account.number, currency,
      balance: usd ? account.cashUsd + invested * account.usdShare / rate : account.cashCad + invested * (1 - account.usdShare),
      available: usd ? account.cashUsd : account.cashCad,
      isBank: false,
    };
  }
  const lineOf = (e) => `${e.title} ${e.number} - (${e.currency})`;
  const sameAs = (a, b) => a.number === b.number && a.currency === b.currency;

  IE.route('/transfer', (params, ctx) => {
    const q = ctx.query;
    let from = null, to = null, mode = 'transfer'; // oneTime | recurring | transfer | exchange

    const name = q.get('account');
    const account = name ? D.portfolio.anyAccountNamed(name) : null;
    const currency = q.get('currency') === 'USD' ? 'USD' : 'CAD';
    const open = q.get('open');
    if (account && q.get('mode') === 'exchange') {
      from = subEndpoint(account, currency);
      to = subEndpoint(account, currency === 'CAD' ? 'USD' : 'CAD');
      mode = 'exchange';
    } else if (account && !open) {
      from = subEndpoint(account, currency);
    }

    const content = h('div', { class: 'content move-content' });
    const page = IE.chromePage(ctx, {
      title: 'Move money',
      topLevel: true,
      actions: [IE.iconButton('contact_support', 'Help', () => IE.notBuilt('Help'))],
      body: content,
      bottomBar: IE.navBar(ctx, { current: 'transfer' }),
    });

    // System back retraces the main pages (no Back button here).
    ctx.setPopHandler(() => IE.navHistory.goBack());

    function render() {
      const isWithdraw = from && !from.isBank && mode !== 'exchange' && (from.title === 'RRSP' || from.title === 'FHSA');
      mount(content,
        h('div', { class: 'move-label' }, 'From'),
        endpointField({ label: 'From', endpoint: from, placeholder: 'Select source', onTap: () => chooseFrom() }),
        from ? [
          h('div', { class: 'move-available' }, `${IE.formatPrice(from.available != null ? from.available : from.balance)} ${from.currency} available`),
          h('div', { class: 'move-arrow' }, icon('arrow_downward', { size: 32, color: 'var(--brand-600)' })),
          endpointField({
            label: 'To', endpoint: to, placeholder: 'Select account', placeholderCurrency: from.currency,
            // An exchange always goes to the same account's other currency.
            onTap: mode === 'exchange' ? null : chooseTo,
          }),
        ] : null,
        h('div', { style: 'height:24px' }),
        isWithdraw ? withdrawPlaceholder(from.title)
          : from && to ? detailsPlaceholder(mode)
            : IE.placeholderContent({
              title: 'Move money', showHeader: false,
              summary: 'Move money between your accounts, or bring assets over from another institution.',
              planned: [
                "Between your own Investor's Edge accounts, in CAD or USD",
                'To and from CIBC chequing and savings accounts',
                'Transfer in from another institution, in cash or in kind',
                'Currency conversion preview for CAD ↔ USD moves',
                'Confirmation screen with the estimated settlement date',
              ],
            }));
    }

    async function chooseFrom(opts = {}) {
      // Opens on the kind of source already chosen.
      const tab = opts.tab || (opts.chosen ? 'investing'
        : !from ? 'banking'
          : mode === 'exchange' ? 'exchange'
            : from.isBank ? 'banking' : 'investing');
      const pick = await IE.showSheet((close) => fromSheet({ close, initialTab: tab, initialChosen: opts.chosen || null }), { label: 'Transfer from' });
      if (!pick || !pick.from || ctx.page.isConnected === false) return;
      IE.haptic();
      from = pick.from; to = pick.to; mode = pick.mode;
      render();
    }

    async function chooseTo() {
      if (!from) return;
      const pick = await IE.showSheet((close) => toSheet({ close, from }), { label: 'Transfer to' });
      if (!pick || !pick.number) return;
      IE.haptic();
      to = pick;
      render();
    }

    render();
    if (open) {
      requestAnimationFrame(() => chooseFrom({
        tab: open === 'exchange' ? 'exchange' : null,
        chosen: open === 'options' && account ? subEndpoint(account, currency) : null,
      }));
    }
    return page.el;
  });

  /** A gray field: a flag in a white circle, the account name and balance; or an italic placeholder. */
  function endpointField({ label, endpoint: e, placeholder, placeholderCurrency, onTap }) {
    const flagCur = e ? e.currency : placeholderCurrency;
    const aria = e ? `${label}, ${e.title} ${e.number}, ${IE.formatPrice(e.balance)} ${e.currency}` : `${label}, ${placeholder}`;
    return h(onTap ? 'button' : 'div', {
      class: ['move-field', onTap && 'tappable'], type: onTap ? 'button' : null, 'aria-label': aria,
      onclick: onTap || null,
    },
    flagCur ? h('span', { class: 'move-flag-circle' }, IE.currencyFlag(flagCur)) : null,
    e ? h('span', { class: 'grow col', style: 'text-align:left' },
      h('span', { class: 't-heading-xs', style: 'color:var(--gray-900)' }, e.title),
      h('span', null,
        h('span', { class: 't-body-lg tabular' }, IE.formatPrice(e.balance)),
        h('span', { class: 't-caption', style: 'color:var(--gray-800)' }, ' ' + e.currency)))
      : h('span', { class: 'grow move-placeholder' }, placeholder));
  }

  function detailsPlaceholder(mode) {
    if (mode === 'exchange') {
      return IE.placeholderContent({
        title: 'Exchange currency', showHeader: false,
        summary: "Exchange amounts placeholder: convert cash between this account's CAD and USD sides.",
        planned: ['Amount to convert, in either currency', 'Live exchange rate and what you receive', 'Review and confirm, with the settlement date'],
      });
    }
    if (mode === 'recurring') {
      return IE.placeholderContent({
        title: 'Recurring deposit', showHeader: false,
        summary: 'Recurring deposit placeholder: set up a regular, pre-authorized move between these accounts.',
        planned: ['Amount and frequency (weekly, every two weeks, monthly)', 'Start date, and an optional end date',
          'Remaining contribution room for TFSA, RRSP and FHSA', 'Review and confirm'],
      });
    }
    return IE.placeholderContent({
      title: 'Cash transfer', showHeader: false,
      summary: 'Cash transfer placeholder: enter the amount to move between these accounts.',
      planned: ['Amount, up to the cash available', 'Remaining contribution room for TFSA, RRSP and FHSA',
        'Withholding tax note for RRSP withdrawals', 'Review and confirm, with the settlement date'],
    });
  }

  /** "Withdraw from RRSP" / "Withdraw from FHSA" placeholder. */
  function withdrawPlaceholder(type) {
    return h('div', { class: 'col' },
      h('h2', { class: 't-heading-sm semibold', style: 'margin:0 0 8px;color:var(--gray-900)' }, `Withdraw from ${type}`),
      IE.placeholderContent({
        title: `Withdraw from ${type}`, showHeader: false,
        summary: `Withdrawal placeholder: taking cash out of your ${type} has tax rules, so this flow is planned as a withdrawal rather than a plain transfer.`,
        planned: [
          'Amount, up to the cash available',
          ...(type === 'RRSP'
            ? ['Withholding tax estimate, and the net amount you receive', "Home Buyers' Plan and Lifelong Learning Plan options"]
            : ['Qualifying withdrawal check for a first home purchase', 'Tax treatment for non-qualifying withdrawals']),
          'Destination: a linked bank account or another account',
          'Review and confirm',
        ],
      }));
  }

  // ── Sheets ──

  /** Title, pills and a divider over a scrolling list of rows. */
  function sheetFrame({ title, tabs, selected, onTab, rows }) {
    return h('div', { class: 'move-sheet' },
      h('h2', { class: 'move-sheet-title' }, title),
      tabs.length ? h('div', { class: 'move-pills', role: 'tablist' }, tabs.map((t, i) => h('button', {
        type: 'button', role: 'tab', class: ['move-pill', i === selected && 'selected'], 'aria-selected': String(i === selected),
        onclick: () => { if (i !== selected) { IE.haptic(); onTab(i); } },
      }, t))) : null,
      h('div', { style: 'height:12px' }),
      h('hr', { class: 'divider' }),
      h('div', { class: 'move-sheet-rows' }, rows));
  }

  const sheetIcon = (name) => icon(name, { size: 20, color: 'var(--brand-600)' });

  function sheetRow({ title, subtitle, leading, onTap, bold = false, indent = false, aria }) {
    return h('button', { type: 'button', class: ['move-row', indent && 'indent'], onclick: onTap, 'aria-label': aria || null },
      leading ? h('span', { class: 'move-row-lead' }, leading) : null,
      h('span', { class: 'grow col', style: 'text-align:left' },
        h('span', { class: bold ? 't-body-lg semibold' : 't-body-lg', style: 'color:var(--gray-900)' }, title),
        subtitle ? h('span', { class: 't-body-md-book muted' }, subtitle) : null));
  }

  /** One account per row: name and number, then CAD / USD buttons (or Withdraw). */
  function accountCurrencyRow({ account, currencies = ['CAD', 'USD'], onPick, onWithdraw }) {
    return h('div', { class: 'move-acct-row' },
      h('span', { class: 'grow t-body-lg', style: 'color:var(--gray-800)' }, `${account.name} ${account.number}`),
      onWithdraw
        ? h('button', { type: 'button', class: 'move-row-btn', dataset: { testid: `move-${account.name}-withdraw` },
          'aria-label': `Withdraw from ${account.name} ${account.number}`, onclick: onWithdraw }, h('span', { class: 't-body-lg semibold' }, 'Withdraw'))
        : currencies.map((c) => h('button', {
          type: 'button', class: 'move-row-btn cur', dataset: { testid: `move-${account.name}-${c}` },
          'aria-label': `${account.name} ${account.number}, ${c}`, onclick: () => onPick(c),
        }, IE.currencyFlag(c), h('span', { class: 't-body-lg semibold' }, c))));
  }

  const FROM_TABS = ['banking', 'investing', 'exchange'];

  /**
   * "Transfer from": Banking, Investing and Exchange pills. Picking a bank or
   * an account side shows it alone (no pills) with One-time transfer and
   * Recurring deposit; tapping it again goes back to the list.
   */
  function fromSheet({ close, initialTab, initialChosen }) {
    const wrap = h('div');
    let tab = initialTab;
    let chosen = initialChosen;
    let bank = null;
    const notBuilt = (what) => { close(); IE.notBuilt(what); };
    const linkedSub = (b) => subEndpoint(D.portfolio.accountNamed(b.linkedAccount) || D.portfolio.accounts[0], b.currency);

    function render() {
      // A bank goes to its linked account; an account's destination is picked next.
      const to = bank ? linkedSub(bank) : null;
      let rows;
      if (chosen) {
        rows = [
          sheetRow({
            leading: h('span', { class: 'row gap4' }, icon('chevron_left', { color: 'var(--gray-700)' }), IE.currencyFlag(chosen.currency)),
            title: lineOf(chosen), bold: true, aria: `Back to accounts. Selected: ${lineOf(chosen)}`,
            onTap: () => { chosen = null; bank = null; render(); },
          }),
          sheetRow({ indent: true, leading: sheetIcon('currency_exchange'), title: 'One-time transfer',
            onTap: () => close({ from: chosen, to, mode: bank ? 'oneTime' : 'transfer' }) }),
          sheetRow({ indent: true, leading: sheetIcon('event_repeat'), title: 'Recurring deposit',
            onTap: () => close({ from: chosen, to, mode: 'recurring' }) }),
        ];
      } else if (tab === 'banking') {
        rows = [
          ...D.banks.map((b) => sheetRow({ leading: IE.currencyFlag(b.currency), title: lineOf(bankEndpoint(b)),
            onTap: () => { bank = b; chosen = bankEndpoint(b); render(); } })),
          sheetRow({ leading: sheetIcon('add_circle'), title: 'Link bank account', onTap: () => notBuilt('Linking a bank account') }),
        ];
      } else if (tab === 'investing') {
        rows = [
          ...D.portfolio.accounts.map((a) => accountCurrencyRow({
            account: a,
            onPick: (c) => { chosen = subEndpoint(a, c); render(); },
            // Cash out of an RRSP or FHSA is a withdrawal: one Withdraw button.
            onWithdraw: a.name === 'RRSP' || a.name === 'FHSA'
              ? () => close({ from: subEndpoint(a, 'CAD'), to: null, mode: 'transfer' }) : null,
          })),
          sheetRow({ leading: sheetIcon('account_balance'), title: 'Another brokerage',
            subtitle: 'CIBC brokerage, Wealthsimple, TD Direct Investing, and more',
            onTap: () => notBuilt('Transfers from another brokerage') }),
        ];
      } else {
        rows = [
          ...D.portfolio.accounts.map((a) => accountCurrencyRow({
            account: a,
            onPick: (c) => close({ from: subEndpoint(a, c), to: subEndpoint(a, c === 'CAD' ? 'USD' : 'CAD'), mode: 'exchange' }),
          })),
          sheetRow({ leading: sheetIcon('swap_vertical_circle'), title: 'Journal securities',
            subtitle: 'Swap stocks & ETFs between your CAD and USD accounts.', onTap: () => notBuilt('Journal securities') }),
        ];
      }
      mount(wrap, sheetFrame({
        title: 'Transfer from',
        // No pills while an account's options are showing.
        tabs: chosen ? [] : ['Banking', 'Investing', 'Exchange'],
        selected: FROM_TABS.indexOf(tab),
        onTab: (i) => { tab = FROM_TABS[i]; chosen = null; bank = null; render(); },
        rows,
      }));
    }
    render();
    return wrap;
  }

  /** "Transfer to": same-currency banks (not from a bank) and account sides. */
  function toSheet({ close, from }) {
    const wrap = h('div');
    const showBanking = !from.isBank;
    let tab = from.isBank ? 1 : 0;
    function render() {
      const banking = tab === 0 && showBanking;
      const rows = banking
        ? [
          ...D.banks.filter((b) => b.currency === from.currency).map((b) => sheetRow({
            leading: IE.currencyFlag(b.currency), title: lineOf(bankEndpoint(b)), onTap: () => close(bankEndpoint(b)),
          })),
          sheetRow({ leading: sheetIcon('add_circle'), title: 'Link bank account', onTap: () => { close(); IE.notBuilt('Linking a bank account'); } }),
        ]
        : D.portfolio.accounts
          .filter((a) => !sameAs(subEndpoint(a, from.currency), from))
          .map((a) => accountCurrencyRow({ account: a, currencies: [from.currency], onPick: (c) => close(subEndpoint(a, c)) }));
      mount(wrap, sheetFrame({
        title: 'Transfer to',
        tabs: showBanking ? ['Banking', 'Investing'] : ['Investing'],
        selected: showBanking ? tab : 0,
        onTab: (i) => { tab = showBanking ? i : 1; render(); },
        rows,
      }));
    }
    render();
    return wrap;
  }
})();
