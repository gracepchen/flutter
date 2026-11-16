// App-wide state (lib/state/*): one small observable store.
//
//   IE.store.get('navVersion')            -> 'actions'
//   IE.store.set('navVersion', 'tabs')     -> notifies watchers
//   const off = IE.store.watch('balancesHidden', fn)   // call off() to stop
//
// In memory only, like the Flutter app: a reload starts fresh.
(function () {
  const values = {
    signedIn: false,
    /** Where to go after signing on instead of Home (app shortcuts). */
    pendingLocation: null,
    /** 'searchOnly' (A) | 'shortcuts' (B) | 'actions' (C, default) | 'tabs' (D) */
    navVersion: 'actions',
    /** Nav A: Portfolio, Activity and Move expanded, search collapsed. */
    navAExpanded: true,
    /** Home's display currency: 'CAD' | 'USD'. */
    displayCurrency: 'CAD',
    /** The eye toggle: hides balances app-wide. */
    balancesHidden: false,
    /** Last account picked on any page with an account picker (null: none). */
    selectedAccount: null,
    /** Recent searches, newest first, at most 6. */
    recentSearches: ['XEQT', 'VFV', 'ENB', 'CM'],
    /** Last tab picked on Holdings (value view index) and Activity. */
    holdingsView: 0,
    activityTab: 0,
  };
  const watchers = {};

  const store = {
    get(key) { return values[key]; },
    set(key, value) {
      if (values[key] === value) return;
      values[key] = value;
      (watchers[key] || []).slice().forEach((fn) => fn(value));
    },
    watch(key, fn) {
      (watchers[key] = watchers[key] || []).push(fn);
      return () => { watchers[key] = (watchers[key] || []).filter((f) => f !== fn); };
    },
  };

  /** Records an account pick (All / null leaves the last one as is). */
  function rememberAccount(name) { if (name) store.set('selectedAccount', name); }

  function addRecentSearch(symbol) {
    store.set('recentSearches', [symbol, ...values.recentSearches.filter((s) => s !== symbol)].slice(0, 6));
  }

  /** Display-currency conversion for Home totals. */
  function fromCad(cad) { return values.displayCurrency === 'USD' ? cad / IE.data.market.usdToCad : cad; }

  // ── Navigation history (lib/state/nav_history.dart) ──
  // The bottom bar replaces the page (go), so the router's own stack forgets
  // the page the client left; this keeps it, so Back on Activity, Move money
  // and Holdings returns to the last main page visited.
  const PORTFOLIO_SUBPAGES = new Set(['/holdings', '/watchlists', '/performance', '/contributions']);
  const pathOf = (loc) => loc.split('?')[0];

  const navHistory = {
    hops: [],
    /** The Portfolio subpage last left through the bar (null: Portfolio). */
    portfolioSubpage: null,
    record(from, to) {
      const fp = pathOf(from);
      if (PORTFOLIO_SUBPAGES.has(fp)) this.portfolioSubpage = from;
      else if (fp === '/') this.portfolioSubpage = null;
      if (from === to) return;
      this.hops.push({ from, to });
      if (this.hops.length > 20) this.hops.shift();
    },
    previousFor(location) {
      const last = this.hops[this.hops.length - 1];
      return last && pathOf(last.to) === pathOf(location) ? last.from : null;
    },
    /** Goes back to the page the bar was used from. False if none. */
    goBack({ withAccount = false, account = null, sub = null } = {}) {
      let previous = this.previousFor(IE.router.location);
      if (previous == null) return false;
      this.hops.pop();
      if (withAccount) previous = withAccountOf(previous, account, sub);
      IE.router.go(previous);
      return true;
    },
  };

  /** [location] with its account (and sub-account) replaced, if it's Holdings or Activity. */
  function withAccountOf(location, account, sub) {
    const p = pathOf(location);
    if (p !== '/holdings' && p !== '/activity') return location;
    return withQuery(p, { account, sub: account ? sub : null });
  }

  /** '/path' + '?a=1&b=2' (null values dropped). */
  function withQuery(path, params) {
    const q = new URLSearchParams();
    for (const [k, v] of Object.entries(params || {})) if (v != null && v !== '') q.set(k, v);
    const qs = q.toString();
    return qs ? `${path}?${qs}` : path;
  }

  Object.assign(IE, { store, rememberAccount, addRecentSearch, fromCad, navHistory, withAccountOf, withQuery, pathOf });
})();
