// A small router with the same shape as the Flutter app's GoRouter setup.
//
// - Routes under Home ('/holdings', '/activity', …) sit on top of Home:
//   go('/holdings') gives the stack ['/', '/holdings'], so Back returns Home.
// - go() replaces the stack (the bottom bar uses it); push() adds a page on
//   top and returns a Promise that resolves (with pop's result) when it's
//   popped; pop() removes the top page.
// - Pages under the top stay alive (hidden), so they keep their scroll
//   position and state, as in Flutter.
// - Browser Back (and Android's back gesture in a mobile browser) acts as the
//   system back: it closes a sheet or dialog first, then asks the top page
//   (its pop handler, like PopScope) before popping.
//
// Screens register with IE.route(pattern, factory). factory(params, ctx)
// returns the page's root element. ctx:
//   ctx.location, ctx.query (URLSearchParams), ctx.params ({symbol})
//   ctx.onDispose(fn)   cleanup when the page is removed
//   ctx.onShow(fn)      runs when the page becomes the top page again
//   ctx.setPopHandler(fn)  fn() returns true if it handled system back
//   ctx.watch(key, fn)  IE.store.watch, auto-removed on dispose
//   ctx.interval(fn, ms) setInterval, auto-cleared on dispose
//   ctx.isTop()
(function () {
  const routes = [];
  /** Top-level routes: everything else sits on top of Home ('/'). */
  const TOP_LEVEL = new Set(['/sign-on', '/signing-in', '/']);

  function route(pattern, factory) {
    const parts = pattern.split('/').filter(Boolean);
    routes.push({ pattern, parts, factory });
  }

  function match(location) {
    const path = location.split('?')[0];
    const segs = path.split('/').filter(Boolean);
    for (const r of routes) {
      if (r.parts.length !== segs.length) continue;
      const params = {};
      let ok = true;
      r.parts.forEach((p, i) => {
        if (p.startsWith(':')) params[p.slice(1)] = decodeURIComponent(segs[i]);
        else if (p !== segs[i]) ok = false;
      });
      if (ok) return { route: r, params };
    }
    return null;
  }

  let root = null;
  const stack = [];

  function build(location) {
    const m = match(location) || match('/');
    const el = document.createElement('div');
    el.className = 'page';
    const disposers = [];
    const showers = [];
    const page = { location, el, popHandler: null, disposed: false };
    const ctx = {
      location,
      query: new URLSearchParams(location.split('?')[1] || ''),
      params: m.params,
      page: el,
      onDispose(fn) { disposers.push(fn); },
      onShow(fn) { showers.push(fn); },
      setPopHandler(fn) { page.popHandler = fn; },
      watch(key, fn) { disposers.push(IE.store.watch(key, fn)); },
      interval(fn, ms) { const id = setInterval(fn, ms); disposers.push(() => clearInterval(id)); return id; },
      timeout(fn, ms) { const id = setTimeout(fn, ms); disposers.push(() => clearTimeout(id)); return id; },
      isTop() { return stack[stack.length - 1] === page; },
    };
    page.ctx = ctx;
    page.show = () => showers.forEach((f) => f());
    page.dispose = () => {
      if (page.disposed) return;
      page.disposed = true;
      disposers.forEach((f) => { try { f(); } catch (e) { console.error(e); } });
      el.remove();
      if (page.resolve) page.resolve(page.result);
    };
    const content = m.route.factory(m.params, ctx);
    if (content) el.appendChild(content);
    return page;
  }

  function targetStack(location) {
    const path = location.split('?')[0];
    if (TOP_LEVEL.has(path)) return [location];
    return ['/', location];
  }

  function present(prevTop) {
    stack.forEach((p, i) => { p.el.hidden = i !== stack.length - 1; });
    const top = stack[stack.length - 1];
    if (top !== prevTop) {
      if (!IE.reduceMotion()) {
        top.el.classList.add('entering');
        requestAnimationFrame(() => requestAnimationFrame(() => top.el.classList.remove('entering')));
      }
      top.show();
    }
    syncHash();
  }

  function go(location) {
    IE.closeOverlays && IE.closeOverlays();
    const prevTop = stack[stack.length - 1];
    const wanted = targetStack(location);
    // Keep pages that are already in place at the same depth.
    const keep = [];
    for (let i = 0; i < wanted.length; i++) {
      if (stack[i] && stack[i].location === wanted[i] && keep.length === i) keep.push(stack[i]);
      else break;
    }
    stack.slice(keep.length).forEach((p) => p.dispose());
    stack.length = keep.length;
    for (let i = keep.length; i < wanted.length; i++) {
      const p = build(wanted[i]);
      root.appendChild(p.el);
      stack.push(p);
    }
    present(prevTop);
  }

  function push(location) {
    IE.closeOverlays && IE.closeOverlays();
    const prevTop = stack[stack.length - 1];
    const p = build(location);
    root.appendChild(p.el);
    stack.push(p);
    present(prevTop);
    return new Promise((resolve) => { p.resolve = resolve; });
  }

  function pop(result) {
    if (stack.length <= 1) return false;
    const prevTop = stack.pop();
    prevTop.result = result;
    prevTop.dispose();
    present(prevTop);
    return true;
  }

  function canPop() { return stack.length > 1; }

  /** Android-style back: overlays first, then the page's pop handler. */
  function systemBack() {
    if (IE.closeTopOverlay && IE.closeTopOverlay()) return;
    const top = stack[stack.length - 1];
    if (top && top.popHandler && top.popHandler()) return;
    pop();
  }

  let syncing = false;
  function syncHash() {
    try {
      syncing = true;
      history.replaceState({ ie: true }, '', '#' + router.location);
    } catch (_) { /* sandboxed iframes may refuse */ }
    syncing = false;
  }

  function start(el, initial) {
    root = el;
    go(initial);
    // Browser Back = system back. Keep one entry in hand to catch it.
    try {
      history.pushState({ ie: true }, '', '#' + router.location);
      window.addEventListener('popstate', () => {
        if (syncing) return;
        systemBack();
        try { history.pushState({ ie: true }, '', '#' + router.location); } catch (_) { /* ignore */ }
      });
    } catch (_) { /* ignore */ }
  }

  const router = {
    go, push, pop, canPop, systemBack, start,
    get location() { return stack.length ? stack[stack.length - 1].location : '/'; },
    get stack() { return stack.map((p) => p.location); },
    get top() { return stack[stack.length - 1]; },
  };

  IE.route = route;
  IE.router = router;

  // Paths used across the app (lib/router.dart AppRoutes).
  IE.routes = {
    home: '/', signOn: '/sign-on', signingIn: '/signing-in', watchlists: '/watchlists',
    fractional: '/fractional', add: '/add', transfer: '/transfer', trade: '/trade', search: '/search',
    holdings: '/holdings', contributions: '/contributions', accountSettings: '/account-settings',
    activity: '/activity', performance: '/performance', quote: '/quote', advancedChart: '/advanced-chart',
    profile: '/profile', notifications: '/notifications', help: '/help', eDocuments: '/edocuments',
    contactUs: '/contact-us',
  };
})();
