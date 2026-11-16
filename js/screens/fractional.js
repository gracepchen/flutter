// Fractional Stocks/ETFs (lib/screens/fractional/fractional_screen.dart):
// All / Stock / ETF tabs, a symbol or company search, Exchange, Market Cap
// and Sector filters (with Clear), a sort, a paged list with Buy on each
// row, and page links with Next pinned to the bottom.
(function () {
  const { h, icon, mount } = IE;
  const D = IE.data;
  const R = IE.routes;
  const PAGE_SIZE = 10;

  IE.route('/fractional', (params, ctx) => {
    const st = { tab: 'all', query: '', exchange: null, marketCap: null, sector: null, sort: 'symbol', page: 0 };

    function results() {
      const q = st.query.trim().toLowerCase();
      return D.fractional.all.filter((s) => {
        if (st.tab === 'stock' && s.type !== 'Stock') return false;
        if (st.tab === 'etf' && s.type !== 'ETF') return false;
        if (st.exchange && s.exchange !== st.exchange) return false;
        if (st.marketCap && s.marketCap !== st.marketCap) return false;
        if (st.sector && s.sector !== st.sector) return false;
        if (q && !s.symbol.toLowerCase().includes(q) && !s.name.toLowerCase().includes(q)) return false;
        return true;
      }).sort((a, b) => (st.sort === 'symbol' ? a.symbol.localeCompare(b.symbol) : a.name.localeCompare(b.name)));
    }

    /** Any change to what's listed goes back to page 1. */
    function update(change) { change(); st.page = 0; renderAll(); }

    const tabsEl = h('div', { class: 'frac-tabs', role: 'tablist' });
    function renderTabs() {
      mount(tabsEl, [['all', 'All'], ['stock', 'Stock'], ['etf', 'ETF']].map(([k, l]) => h('button', {
        type: 'button', role: 'tab', class: ['frac-tab', st.tab === k && 'selected'], 'aria-selected': String(st.tab === k),
        onclick: () => update(() => { st.tab = k; }),
      }, l)));
    }

    const search = h('input', {
      type: 'search', placeholder: 'Enter symbol or company', 'aria-label': 'Enter symbol or company', enterkeyhint: 'search',
      oninput: (e) => update(() => { st.query = e.target.value; }),
    });

    function filter(label, anyLabel, options, key) {
      const id = 'frac-' + key;
      return h('div', null,
        h('label', { for: id }, label),
        h('select', { id, class: 'select', onchange: (e) => update(() => { st[key] = e.target.value || null; }) },
          h('option', { value: '', selected: !st[key] }, anyLabel),
          options.map((o) => h('option', { value: o, selected: st[key] === o }, o))));
    }
    const filtersEl = h('div', { class: 'frac-filters' });
    function renderFilters() {
      mount(filtersEl,
        filter('Exchange', 'All', D.fractional.exchanges, 'exchange'),
        filter('Market Cap', 'Any size', D.fractional.marketCaps, 'marketCap'),
        filter('Sector', 'All', D.fractional.sectors, 'sector'));
    }

    const countEl = h('span', { class: 'grow t-body-md-book muted' });
    const sortBtn = h('button', {
      type: 'button', class: 'holdings-sort', title: 'Sort securities',
      onclick: async () => {
        const v = await IE.hxPopupMenu(sortBtn, [{ value: 'symbol', label: 'Symbol' }, { value: 'name', label: 'Name' }], st.sort);
        if (v && v !== st.sort) update(() => { st.sort = v; });
      },
    });
    const listEl = h('div');
    const scroller = h('div', { class: 'page-body' });
    const pager = h('div', { class: 'frac-pager' });

    function row(sec) {
      const hasDetails = !!D.securities.bySymbol(sec.symbol);
      return h('div', {
        class: ['frac-row', hasDetails && 'tappable'], role: hasDetails ? 'button' : null, tabindex: hasDetails ? '0' : null,
        onclick: hasDetails ? () => IE.router.push(`${R.quote}/${sec.symbol}`) : null,
      },
      h('span', { class: 'frac-mono', 'aria-hidden': 'true' }, sec.symbol.slice(0, 1)),
      h('div', { class: 'grow' },
        h('div', { class: 't-body-lg semibold' }, sec.symbol),
        h('div', { class: 't-body-md-book ellipsis', style: 'color:var(--gray-700)' }, sec.name)),
      h('button', {
        type: 'button', class: 'frac-buy', 'aria-label': `Buy ${sec.symbol}`,
        onclick: (e) => { e.stopPropagation(); IE.router.push(IE.withQuery(R.trade, { symbol: sec.symbol, side: 'buy' })); },
      }, 'Buy'));
    }

    function renderAll() {
      renderTabs();
      const res = results();
      const pageCount = Math.max(1, Math.ceil(res.length / PAGE_SIZE));
      const page = Math.min(st.page, pageCount - 1);
      const items = res.slice(page * PAGE_SIZE, page * PAGE_SIZE + PAGE_SIZE);
      countEl.textContent = `${items.length} of ${res.length} securities`;
      mount(sortBtn, h('span', { class: 't-body-md-book muted' }, 'Sort by '), h('span', { class: 't-body-md' }, st.sort === 'symbol' ? 'Symbol' : 'Name'),
        icon('keyboard_arrow_down', { color: 'var(--gray-700)' }));
      mount(listEl,
        res.length ? null : h('p', { class: 't-body-lg-book muted center', style: 'margin:0;padding:32px 0' }, 'No securities match. Try clearing a filter.'),
        items.map(row));
      // Up to five page numbers, then an ellipsis and the last page.
      const numbers = [];
      for (let i = 0; i < pageCount && i < 5; i++) numbers.push(i);
      if (pageCount > 6) numbers.push(null);
      if (pageCount > 5) numbers.push(pageCount - 1);
      const isLast = page >= pageCount - 1;
      mount(pager,
        h('div', { class: 'grow col', style: 'align-items:center' },
          h('div', { class: 'frac-pages' }, numbers.map((n) => (n == null
            ? h('span', { style: 'padding:0 4px' }, '…')
            : h('button', {
              type: 'button', class: ['frac-page-num', n === page && 'current'], 'aria-label': `Page ${n + 1}`,
              'aria-current': n === page ? 'page' : null, onclick: () => goTo(n),
            }, String(n + 1))))),
          h('span', { class: 't-body-md-book', style: 'color:var(--gray-700)' }, `${items.length} of ${res.length} results`)),
        h('button', { type: 'button', class: 'frac-grey-btn', style: 'min-width:104px', disabled: isLast, onclick: () => goTo(page + 1) }, 'Next'));
    }
    function goTo(n) { st.page = n; renderAll(); scroller.scrollTop = 0; }

    function clear() {
      search.value = '';
      update(() => { st.query = ''; st.exchange = null; st.marketCap = null; st.sector = null; });
      renderFilters();
    }

    IE.mount(scroller, h('div', { class: 'content', style: 'padding:12px 16px 16px' },
      h('div', { class: 'frac-search' }, icon('search'), search),
      h('div', { style: 'height:16px' }), filtersEl,
      h('div', { style: 'height:12px' }), h('button', { type: 'button', class: 'frac-grey-btn', onclick: clear }, 'Clear'),
      h('div', { style: 'height:12px' }), h('div', { class: 'row' }, countEl, sortBtn),
      listEl));

    const hd = IE.header({ title: 'Fractional Stocks/ETFs' });
    renderFilters();
    renderAll();
    return h('div', { class: 'col frac-page', style: 'height:100%' }, hd.el, tabsEl, scroller, pager);
  });
})();
