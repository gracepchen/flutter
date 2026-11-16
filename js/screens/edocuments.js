// eDocuments (lib/screens/edocuments_screen.dart): account pills, a document
// type dropdown, one collapsible row per year (newest first) listing that
// year's mock documents, and More information.
(function () {
  const { h, icon, mount } = IE;
  const D = IE.data;

  const TYPES = [
    { key: 'statements', label: 'Account statements' },
    { key: 'confirmations', label: 'Trade confirmations' },
    { key: 'tax', label: 'Tax documents' },
  ];
  const YEARS = [2026, 2025, 2024, 2023, 2022, 2021, 2020, 2019];

  /**
   * Made-up documents. Statements: one a month per account (this year up to
   * last month). Trade confirmations: a few a year. Tax documents: one a year
   * per account, from the year after.
   */
  function listDocs(year, type, account) {
    const now = new Date();
    const accounts = D.portfolio.accounts.filter((a) => !account || a.name === account);
    const label = (a) => `${a.name} ${a.number}`;
    if (type === 'statements') {
      const lastMonth = year < now.getFullYear() ? 12 : now.getMonth(); // getMonth() = this month - 1
      const out = [];
      for (let m = lastMonth; m >= 1; m--) for (const a of accounts) out.push({ title: `${IE.MONTHS[m - 1]} ${year} statement`, account: label(a) });
      return out;
    }
    if (type === 'confirmations') {
      // September, June, March and January (only months already past this year).
      const months = [9, 6, 3, 1];
      const out = [];
      months.forEach((m, i) => {
        if (!(year < now.getFullYear() || m < now.getMonth() + 1)) return;
        for (const a of accounts) {
          if ((year + i + parseInt(a.number, 10)) % 3 !== 0) {
            out.push({ title: `Trade confirmation, ${IE.MONTHS[m - 1]} ${10 + i * 4}, ${year}`, account: label(a) });
          }
        }
      });
      return out;
    }
    // Tax: issued the spring after the tax year.
    if (year >= now.getFullYear()) return [];
    return accounts.map((a) => ({ title: `${year} tax document`, account: label(a) }));
  }

  IE.route('/edocuments', (params, ctx) => {
    let account = null;
    let type = 'statements';
    const years = h('div', { class: 'edocs-years' });

    const filter = IE.accountFilter({
      accounts: D.portfolio.accounts,
      selected: account,
      showAddAccount: false,
      onSelected: (name) => {
        IE.haptic();
        account = name;
        filter.update({ selected: name });
        renderYears();
      },
    });

    const select = h('select', { class: 'select edocs-select', id: 'edocs-type', onchange: (e) => { IE.haptic(); type = e.target.value; renderYears(); } },
      TYPES.map((t) => h('option', { value: t.key, selected: t.key === type }, t.label)));

    function renderYears() {
      const typeLabel = TYPES.find((t) => t.key === type).label;
      // Rebuilt per filter: sections start closed.
      mount(years, YEARS.map((y) => yearSection(y, typeLabel, listDocs(y, type, account))));
    }

    function yearSection(year, typeLabel, docs) {
      let open = false;
      const chev = icon('keyboard_arrow_down', { color: 'var(--gray-800)' });
      const panel = h('div', { class: 'edocs-panel', hidden: true });
      const head = h('button', { type: 'button', class: 'edocs-year-head', 'aria-expanded': 'false', onclick: () => {
        open = !open;
        head.setAttribute('aria-expanded', String(open));
        chev.textContent = open ? 'keyboard_arrow_up' : 'keyboard_arrow_down';
        panel.hidden = !open;
        if (open && !panel.childNodes.length) {
          IE.append(panel, docs.length
            ? docs.map((d) => h('button', { type: 'button', class: 'edocs-doc', onclick: () => IE.notBuilt('Opening documents') },
              icon('picture_as_pdf', { color: 'var(--gray-700)' }),
              h('span', { class: 'grow col', style: 'text-align:left' },
                h('span', { class: 't-body-md', style: 'color:var(--gray-900)' }, d.title),
                h('span', { class: 't-caption muted' }, d.account))))
            : h('p', { class: 't-body-md-book muted', style: 'margin:0;padding:8px 12px' }, 'No documents for this year yet.'));
        }
      } }, h('span', { class: 'grow t-body-lg-book', style: 'color:var(--gray-800);text-align:left' }, `${year} ${typeLabel}`), chev);
      return h('div', { class: 'edocs-year' }, head, panel);
    }

    let moreOpen = false;
    const moreChev = icon('keyboard_arrow_down', { color: 'var(--gray-800)' });
    const morePanel = h('p', { class: 't-body-md-book muted', style: 'margin:0 0 16px', hidden: true }, 'More information: content TBD in this prototype.');
    const moreHead = h('button', { type: 'button', class: 'edocs-more-head', 'aria-expanded': 'false', onclick: () => {
      moreOpen = !moreOpen;
      morePanel.hidden = !moreOpen;
      moreChev.textContent = moreOpen ? 'keyboard_arrow_up' : 'keyboard_arrow_down';
      moreHead.setAttribute('aria-expanded', String(moreOpen));
    } }, h('span', { class: 't-body-lg-book', style: 'color:var(--gray-800)' }, 'More information'), moreChev);

    renderYears();
    const body = h('div', { class: 'content edocs-content' },
      filter,
      h('div', { class: 'pad-x', style: 'padding-top:20px' },
        h('label', { class: 't-body-md-book', for: 'edocs-type', style: 'display:block;color:var(--gray-800);margin-bottom:8px' }, 'Document type'),
        select,
        h('div', { style: 'height:24px' }),
        years,
        h('div', { style: 'height:16px' }),
        h('div', { class: 'edocs-more' }, moreHead, morePanel)));

    return IE.chromePage(ctx, {
      title: 'eDocuments',
      actions: [
        IE.iconButton('contact_support', 'Help', () => IE.router.push(IE.routes.help)),
        IE.iconButton('forward_to_inbox', 'Email preferences', () => IE.notBuilt('Email preferences')),
      ],
      body,
    }).el;
  });
})();
