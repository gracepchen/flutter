// Bottom navigation for the four Nav/IA versions (lib/widgets/app_nav_bar.dart).
//
// - A, Search only: one pill with Portfolio, Activity and Move (captions),
//   search collapsed to an icon; expanded by default. Tapping Portfolio on
//   Portfolio collapses it to Portfolio + the open search bar.
// - B, Search with shortcuts: Portfolio, a search bar and Shortcuts (a
//   blurred overlay with Move money, Activity and Trade).
// - C, Search with actions (default): Portfolio, a search bar, Move and
//   Activity, with captions.
// - D, Tabs: Portfolio, Explore, Move and Activity.
//
// On Search, B and C shrink (animated) to a centred row of icons.
//
// IE.navBar(ctx, {current, account, subAccount}) returns an element that
// re-renders when the Nav/IA version changes. current: 'home' | 'search' |
// 'transfer' | 'activity' | 'holdings' | 'watchlists' | 'performance' |
// 'contributions'. Holdings, Watchlists, Performance and Contributions
// belong to Portfolio's section.
(function () {
  const { h, icon } = IE;
  const R = IE.routes;
  const PORTFOLIO_SECTION = new Set(['home', 'holdings', 'watchlists', 'performance', 'contributions']);
  const sectionOf = (cur) => (PORTFOLIO_SECTION.has(cur) ? 'home' : cur);

  function navBar(ctx, opts) {
    const holder = h('div', { class: 'navbar-holder' });
    let o = Object.assign({ account: null, subAccount: null }, opts);

    /** Where Back should return to if the client leaves through the bar. */
    function origin() {
      const path = o.current === 'holdings' ? R.holdings : o.current === 'activity' ? R.activity : null;
      if (!path) return IE.router.location;
      return IE.withQuery(path, { account: o.account, sub: o.account ? o.subAccount : null });
    }
    function go(location) {
      IE.navHistory.record(origin(), location);
      IE.router.go(location);
    }
    function activityLocation() {
      return IE.withQuery(R.activity, { account: o.account, sub: o.account ? o.subAccount : null });
    }
    function goActivity() { if (o.current !== 'activity') go(activityLocation()); }
    /** Within Portfolio's section: Portfolio itself; else its last subpage. */
    function goPortfolio() {
      if (sectionOf(o.current) === 'home') { go(R.home); return; }
      let target = IE.navHistory.portfolioSubpage || R.home;
      if (o.current === 'activity') target = IE.withAccountOf(target, o.account, o.subAccount);
      go(target);
    }
    function onSearchTap() {
      if (o.current === 'search') { IE.focusSearchField && IE.focusSearchField(); return; }
      go(R.search);
    }

    function render() {
      const v = IE.store.get('navVersion');
      navAState = null;
      IE.mount(holder, v === 'searchOnly' ? navA() : v === 'tabs' ? tabs() : searchBarNav(v));
    }

    // ── B and C ──
    function navIcon({ name, label, onTap, selected, showLabel, testid }) {
      return h('button', {
        type: 'button', class: ['nav-icon', showLabel && 'labelled'], title: label, 'aria-label': label,
        'aria-current': selected ? 'page' : null, dataset: { nav: testid || label },
        onclick: (e) => onTap(e.currentTarget),
      },
      h('span', { class: ['nav-glyph', selected && 'selected'] }, icon(name, { size: showLabel ? 24 : 28 })),
      showLabel ? h('span', { class: 'nav-caption' }, label) : null);
    }

    function searchBarNav(version) {
      const onSearch = o.current === 'search';
      const labels = version === 'actions';
      const trailing = version === 'shortcuts'
        ? [{ name: 'bolt', label: 'Shortcuts', onTap: (btn) => showShortcuts(btn) }]
        : [
          { name: 'move_money', label: 'Move', onTap: () => go(R.transfer), selected: o.current === 'transfer' },
          { name: 'schedule', label: 'Activity', onTap: goActivity, selected: o.current === 'activity' },
        ];
      const items = [
        navIcon({ name: 'pie_chart', label: 'Portfolio', onTap: goPortfolio, selected: sectionOf(o.current) === 'home', showLabel: labels }),
        null, // search pill goes here
        ...trailing.map((t) => navIcon(Object.assign({ showLabel: labels }, t))),
      ];
      const pill = h('div', { class: 'pill' }, icon('search', { color: 'var(--gray-700)' }), h('span', { class: 'ph' }, 'Search'));
      const asIcon = h('div', { class: 'as-icon' }, h('span', { class: ['nav-glyph', onSearch && 'selected'] }, icon('search', { size: 28 })));
      const search = h('button', {
        type: 'button', class: 'nav-search', title: 'Search stocks & ETFs', 'aria-label': 'Search stocks and ETFs',
        'aria-current': onSearch ? 'page' : null, dataset: { nav: 'Search' }, onclick: onSearchTap,
      }, pill, asIcon);
      items[1] = search;
      const gaps = [];
      const row = [];
      const gap = () => { const g = h('span', { class: 'nav-gap' }); gaps.push(g); return g; };
      row.push(gap());
      items.forEach((it) => { row.push(it); row.push(gap()); });
      const bar = h('nav', { class: 'navbar', 'aria-label': 'Main' }, row);

      // t = 0: full search bar; t = 1: compact icons (Search). Arriving on
      // Search, start full and animate to compact.
      function layout(t) {
        const w = bar.clientWidth || (document.getElementById('app').clientWidth);
        const slots = (1 + trailing.length) * 56;
        const room = w - slots - 16;
        const full = Math.max(56, room * 0.75);
        const pillW = full + (56 - full) * t;
        const n = items.length;
        const g = Math.max(0, (w - slots - full - 1) / (n + 1) * (1 - t));
        search.style.width = pillW + 'px';
        gaps.forEach((x) => { x.style.width = g + 'px'; });
        pill.style.opacity = String(1 - t);
        asIcon.style.opacity = String(t);
      }
      layout(0);
      requestAnimationFrame(() => {
        // Without transitions for the first measure, then animate to the target.
        [search, ...gaps].forEach((x) => { x.style.transition = 'none'; });
        layout(0);
        void bar.offsetWidth;
        [search, ...gaps].forEach((x) => { x.style.transition = ''; });
        requestAnimationFrame(() => layout(onSearch ? 1 : 0));
      });
      const ro = window.ResizeObserver ? new ResizeObserver(() => layout(onSearch ? 1 : 0)) : null;
      if (ro) { ro.observe(bar); ctx.onDispose(() => ro.disconnect()); }
      return bar;
    }

    // ── B: Shortcuts overlay ──
    function showShortcuts(btn) {
      if (document.activeElement) document.activeElement.blur();
      const app = document.getElementById('app');
      const appRect = app.getBoundingClientRect();
      const r = btn.getBoundingClientRect();
      const anchor = { cx: r.left + r.width / 2 - appRect.left, top: r.top - appRect.top, left: r.left - appRect.left, w: r.width, h: r.height };
      const items = [
        ['move_money', 'Move money', R.transfer],
        ['schedule', 'Activity', activityLocation()],
        ['trending_up', 'Trade', R.trade],
      ];
      let done = false;
      const ov = h('div', { class: 'shortcuts-overlay', role: 'dialog', 'aria-label': 'Shortcuts' });
      // Registered with the overlay stack, so system back closes it.
      const unregister = IE.registerOverlay(() => dismiss());
      function dismiss(then) {
        if (done) return;
        done = true;
        unregister();
        ov.classList.remove('open');
        setTimeout(() => { ov.remove(); if (then) then(); }, IE.reduceMotion() ? 0 : 250);
      }
      const links = h('div', { class: 'links', style: {
        right: (appRect.width - (anchor.cx + 14 + 12)) + 'px',
        bottom: (appRect.height - anchor.top + 8) + 'px',
      } }, items.map(([ic, label, loc], i) => h('button', {
        type: 'button', class: 'shortcut-item', 'aria-label': label,
        style: { transitionDelay: ((items.length - 1 - i) * 45) + 'ms' },
        onclick: () => dismiss(() => (loc === R.trade ? IE.router.push(loc) : go(loc))),
      }, h('span', null, label), icon(ic, { size: 28, color: 'var(--gray-700)' }))));
      const closeBtn = h('div', { class: 'close', style: { left: anchor.left + 'px', top: anchor.top + 'px', width: anchor.w + 'px', height: anchor.h + 'px' } },
        IE.iconButton('close', 'Close shortcuts', () => dismiss(), { size: 28 }));
      ov.append(h('div', { class: 'scrim', onclick: () => dismiss() }), links, closeBtn);
      app.appendChild(ov);
      requestAnimationFrame(() => requestAnimationFrame(() => ov.classList.add('open')));
    }

    // ── D: tabs ──
    function tabs() {
      const sec = sectionOf(o.current);
      const t = [
        ['home', 'pie_chart', 'Portfolio', goPortfolio],
        ['search', 'search', 'Explore', onSearchTap],
        ['transfer', 'move_money', 'Move', () => go(R.transfer)],
        ['activity', 'schedule', 'Activity', goActivity],
      ];
      return h('nav', { class: 'navbar', 'aria-label': 'Main' }, t.map(([dest, ic, label, fn]) => h('button', {
        type: 'button', class: ['nav-tab', dest === sec && 'selected'], 'aria-label': label, title: label,
        'aria-current': dest === sec ? 'page' : null, dataset: { nav: label }, onclick: fn,
      }, h('span', { class: 'pillglyph' }, icon(ic, { size: 24 })), h('span', { class: 'lbl' }, label))));
    }

    // ── A ──
    let navAState = null;
    function navA() {
      let expanded = o.current !== 'home' || IE.store.get('navAExpanded');
      function onHome() {
        if (o.current === 'home') IE.store.set('navAExpanded', !IE.store.get('navAExpanded'));
        else goPortfolio();
      }
      const btn = (name, label, onTap, selected, extra) => h('button', {
        type: 'button', class: ['nav-a-btn', extra && 'extra'], title: label, 'aria-label': label,
        'aria-current': selected ? 'page' : null, dataset: { nav: label },
        tabindex: extra && !expanded ? '-1' : null, 'aria-hidden': extra && !expanded ? 'true' : null,
        onclick: onTap,
      }, icon(name, { size: expanded ? 24 : 28 }), h('span', { class: 'nav-caption' }, label));
      const group = h('div', { class: 'nav-a-group' }, h('div', { class: 'nav-a-inner' },
        btn('pie_chart', 'Portfolio', onHome, sectionOf(o.current) === 'home', false),
        btn('schedule', 'Activity', goActivity, o.current === 'activity', true),
        btn('move_money', 'Move', () => go(R.transfer), o.current === 'transfer', true)));
      const open = h('div', { class: 'open' }, icon('search', { size: 28 }), h('span', { class: 'ph' }, 'Search'));
      const closed = h('div', { class: 'closed' }, icon('search', { size: 28 }));
      const search = h('button', {
        type: 'button', class: 'nav-a-search', title: 'Search stocks & ETFs', 'aria-label': 'Search stocks and ETFs',
        'aria-current': o.current === 'search' ? 'page' : null, dataset: { nav: 'Search' }, onclick: onSearchTap,
      }, open, closed);
      const row = h('div', { class: ['nav-a-row', !expanded && 'collapsed'] }, group, search);
      const bar = h('nav', { class: 'navbar nav-a', 'aria-label': 'Main' }, row);
      function layout(t) {
        const w = (bar.clientWidth || document.getElementById('app').clientWidth) - 32;
        group.style.width = (56 + (168 - 56) * t) + 'px';
        search.style.width = ((w - 56 - 12) + (56 - (w - 56 - 12)) * t) + 'px';
        open.style.opacity = String(1 - t);
        closed.style.opacity = String(t);
      }
      layout(expanded ? 1 : 0);
      requestAnimationFrame(() => layout(expanded ? 1 : 0));
      const ro = window.ResizeObserver ? new ResizeObserver(() => layout(expanded ? 1 : 0)) : null;
      if (ro) { ro.observe(bar); ctx.onDispose(() => ro.disconnect()); }
      // Toggling on Portfolio animates in place (no rebuild).
      navAState = {
        setExpanded(v) {
          expanded = o.current !== 'home' || v;
          row.classList.toggle('collapsed', !expanded);
          group.querySelectorAll('.extra').forEach((b) => {
            b.tabIndex = expanded ? 0 : -1;
            if (expanded) b.removeAttribute('aria-hidden'); else b.setAttribute('aria-hidden', 'true');
          });
          group.querySelectorAll('.nav-a-btn .icon').forEach((i) => { i.style.fontSize = (expanded ? 24 : 28) + 'px'; });
          layout(expanded ? 1 : 0);
        },
      };
      return bar;
    }

    ctx.watch('navVersion', render);
    ctx.watch('navAExpanded', (v) => { if (IE.store.get('navVersion') === 'searchOnly' && navAState) navAState.setExpanded(v); });
    render();
    holder.update = (next) => { o = Object.assign(o, next); render(); };
    return holder;
  }

  IE.navBar = navBar;
  IE.navSectionOf = sectionOf;
})();
