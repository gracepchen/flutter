// Mock data model (lib/data/mock_portfolio.dart, mock_fractional.dart).
// Raw literals come from raw_data.js; the logic is ported here.
(function () {
  const R = IE.raw;

  // ── Seeded random (charts are made up but stable between visits) ──
  function seeded(seed) {
    let a = (seed >>> 0) || 1;
    return function () {
      a |= 0; a = (a + 0x6D2B79F5) | 0;
      let t = Math.imul(a ^ (a >>> 15), 1 | a);
      t = (t + Math.imul(t ^ (t >>> 7), 61 | t)) ^ t;
      return ((t ^ (t >>> 14)) >>> 0) / 4294967296;
    };
  }

  function densify(shape, factor = 3, seed = 5) {
    const rnd = seeded(seed);
    const span = Math.max(...shape) - Math.min(...shape);
    const out = [];
    for (let i = 0; i < shape.length - 1; i++) {
      for (let k = 0; k < factor; k++) {
        let v = shape[i] + (shape[i + 1] - shape[i]) * (k / factor);
        if (k > 0) v += (rnd() - 0.5) * span * 0.04;
        out.push(v);
      }
    }
    out.push(shape[shape.length - 1]);
    return out;
  }

  /** A random walk that trends upward. */
  function randomWalk(seed, length = 108) {
    const rnd = seeded(seed);
    let v = 0;
    const pts = [v];
    for (let i = 1; i < length; i++) { v += rnd() - 0.35; pts.push(v); }
    if (pts[pts.length - 1] <= pts[0]) {
      const lift = (pts[0] - pts[pts.length - 1]) / (length - 1) + 0.1;
      for (let i = 0; i < length; i++) pts[i] += i * lift;
    }
    return pts;
  }

  /** Maps [shape] so its first point is [start] and its last is [end]. */
  function mapShape(shape, start, end) {
    const s0 = shape[0];
    const span = shape[shape.length - 1] - s0;
    return shape.map((p) => (span === 0 ? start : start + (p - s0) / span * (end - start)));
  }

  /** Copies plain fields, then defines [getters] as live getters (a plain
   *  Object.assign would evaluate them once). */
  function withGetters(fields, getters) {
    return Object.defineProperties(Object.assign({}, fields), Object.getOwnPropertyDescriptors(getters));
  }

  // ── Enums ──
  const ChartRange = [
    { key: 'oneDay', label: '1D', spoken: '1 day', suffix: 'today' },
    { key: 'oneWeek', label: '1W', spoken: '1 week', suffix: 'past week' },
    { key: 'oneMonth', label: '1M', spoken: '1 month', suffix: 'past month' },
    { key: 'threeMonths', label: '3M', spoken: '3 months', suffix: 'past 3 months' },
    { key: 'oneYear', label: '1Y', spoken: '1 year', suffix: 'past year' },
    { key: 'all', label: 'ALL', spoken: 'all time', suffix: 'all time' },
  ];
  const StockRange = [
    { key: 'oneDay', label: '1D', spoken: '1 day' },
    { key: 'fiveDays', label: '5D', spoken: '5 days' },
    { key: 'oneMonth', label: '1M', spoken: '1 month' },
    { key: 'threeMonths', label: '3M', spoken: '3 months' },
    { key: 'sixMonths', label: '6M', spoken: '6 months' },
    { key: 'oneYear', label: '1Y', spoken: '1 year' },
    { key: 'fiveYears', label: '5Y', spoken: '5 years' },
  ];
  const AccountGroup = [
    { key: 'personal', label: 'Personal', spoken: 'Personal' },
    { key: 'poa', label: 'POA', spoken: 'Power of attorney' },
    { key: 'ta', label: 'TA', spoken: 'Trading authority' },
  ];

  // ── Accounts ──
  const usdToCad = 1.40123;
  function makeAccount(a) {
    return withGetters(Object.assign({ group: 'personal', subtype: null, usdShare: 0 }, a), {
      get buyingPower() { return this.cashCad + this.cashUsd * usdToCad; },
      /** "58204425  •  Cash", or just the number. */
      get numberLine() { return this.subtype ? `${this.number}  •  ${this.subtype}` : this.number; },
      /** "TFSA 58204417" */
      get label() { return `${this.name} ${this.number}`; },
    });
  }
  const accounts = R.accounts.map(makeAccount);
  const poaAccounts = R.poaAccounts.map((a) => makeAccount(Object.assign({ group: 'poa' }, a)));
  const taAccounts = R.taAccounts.map((a) => makeAccount(Object.assign({ group: 'ta' }, a)));

  const portfolio = {
    firstName: 'Taylor',
    lastName: 'Rutherford',
    fullName: 'Taylor Rutherford',
    investorSince: new Date(2021, 8, 5),
    initials: 'T',
    totalValue: 124820.42,
    accounts,
    poaAccounts,
    taAccounts,
    accountNamed(name) { return accounts.find((a) => a.name === name) || null; },
    accountsIn(group) { return group === 'poa' ? poaAccounts : group === 'ta' ? taAccounts : accounts; },
    anyAccountNamed(name) { return [...accounts, ...poaAccounts, ...taAccounts].find((a) => a.name === name) || null; },
    sharesHeld: R.sharesHeld,
    sharesHeldOf(symbol) { return R.sharesHeld[symbol] || 0; },
    get investedByYear() { const y = new Date().getFullYear(); return [[y - 2, 11425.15], [y - 1, 6341.97], [y, 20402.92]]; },
    get dividendsByYear() { const y = new Date().getFullYear(); return [[y - 2, 291.03], [y - 1, 365.10]]; },
    dividendsYearToDate: 451.92,
    dividendsProjectedThisYear: 513.10,
    recentActivity: R.recentActivity.map((a) => Object.assign({ pending: false }, a)),
    recentTrades: R.recentTrades.map((a) => Object.assign({ pending: false }, a)),
    _cache: {},
    /** Portfolio value series for a ChartRange key, ending at totalValue. */
    series(rangeKey) {
      if (!this._cache[rangeKey]) {
        const idx = ChartRange.findIndex((r) => r.key === rangeKey);
        const shape = rangeKey === 'oneDay' ? densify(R.oneDayShape) : randomWalk(17 + idx * 7919);
        const pts = mapShape(shape, R.startValues[rangeKey], this.totalValue);
        this._cache[rangeKey] = seriesOf(pts);
      }
      return this._cache[rangeKey];
    },
  };

  function seriesOf(points) {
    const start = points[0], end = points[points.length - 1];
    return { points, start, end, change: end - start, changePercent: start === 0 ? 0 : (end - start) / start * 100 };
  }

  // ── Securities ──
  function makeSecurity(s) {
    return withGetters(Object.assign({}, s, { quote: makeQuote(s.quote) }), {
      /** U.S.-listed (single exchange) securities can be bought in fractions. */
      get fractional() { return this.exchange === 'NASDAQ' || this.exchange === 'NYSE'; },
    });
  }
  function makeQuote(q) {
    return withGetters(q, {
      get change() { return this.price - this.previousClose; },
      get changePercent() { return (this.price - this.previousClose) / this.previousClose * 100; },
    });
  }
  const securities = R.securities.map(makeSecurity);

  const market = {
    usdToCad,
    /** The rate is as of the last business day (weekends skipped). */
    get usdToCadAsOf() {
      const d = new Date(); d.setHours(0, 0, 0, 0); d.setDate(d.getDate() - 1);
      while (d.getDay() === 0 || d.getDay() === 6) d.setDate(d.getDate() - 1);
      return d;
    },
    toCad(amount, currency) { return currency === 'USD' ? amount * usdToCad : amount; },
    _cache: {},
    /** Price history for a security over a StockRange key, ending at the price. */
    series(security, rangeKey) {
      const key = security.symbol + '/' + rangeKey;
      if (!this._cache[key]) {
        let symbolSeed = 0;
        for (const ch of security.symbol) symbolSeed = (symbolSeed * 31 + ch.charCodeAt(0)) % 1000003;
        const idx = StockRange.findIndex((r) => r.key === rangeKey);
        const seed = symbolSeed + idx * 7919;
        const rnd = seeded(seed);
        const end = security.quote.price;
        const start = rangeKey === 'oneDay'
          ? security.quote.previousClose
          : end * (1 - (rnd() * 0.20 - 0.06) * (1 + idx * 0.4));
        this._cache[key] = mapShape(randomWalk(seed, 132), start, end);
      }
      return this._cache[key];
    },
  };

  const securitiesApi = {
    all: securities,
    bySymbol(symbol) { const u = String(symbol).toUpperCase(); return securities.find((s) => s.symbol === u) || null; },
    recentSearches: ['XEQT', 'VFV', 'ENB', 'CM'],
    search(query) {
      const q = query.trim().toLowerCase();
      if (!q) return [];
      return securities.filter((s) => s.symbol.toLowerCase().startsWith(q) || s.name.toLowerCase().includes(q));
    },
  };

  // ── Holdings ──
  const costBasis = R.costBasis;
  function holding(security, shares, bookPerShare, weightBase = portfolio.totalValue) {
    const mv = market.toCad(security.quote.price * shares, security.currency);
    const book = market.toCad(bookPerShare * shares, security.currency);
    return {
      security, shares,
      marketValueCad: mv,
      dayChangeCad: market.toCad(security.quote.change * shares, security.currency),
      bookValueCad: book,
      weightBase,
      get totalGainCad() { return this.marketValueCad - this.bookValueCad; },
      get dayChangePercent() { return this.security.quote.changePercent; },
      get weightPercent() { return this.marketValueCad / this.weightBase * 100; },
    };
  }

  const holdings = {
    costBasis,
    costBasisOf(symbol) { return costBasis[symbol] || null; },
    /** Every held security, largest market value first (fresh array). */
    get all() {
      return Object.entries(R.sharesHeld)
        .map(([sym, shares]) => {
          const sec = securitiesApi.bySymbol(sym);
          if (!sec) return null;
          return holding(sec, shares, (costBasis[sym] ? costBasis[sym].averageCost : sec.quote.price));
        })
        .filter(Boolean)
        .sort((a, b) => b.marketValueCad - a.marketValueCad);
    },
    top(count = 5) { return this.all.slice(0, count); },
    /** One account's holdings, largest first; [currency] filters to CAD or USD. */
    inAccount(name, currency) {
      const account = portfolio.accountNamed(name);
      if (!account) return [];
      const out = [];
      for (const sym of Object.keys(R.splits)) {
        const sec = securitiesApi.bySymbol(sym);
        if (!sec || (currency && sec.currency !== currency)) continue;
        for (const p of this.positionsOf(sym)) {
          if (p.account.name !== name) continue;
          out.push(holding(sec, p.shares, p.averageCost, account.value));
        }
      }
      return out.sort((a, b) => b.marketValueCad - a.marketValueCad);
    },
    /** The accounts holding [symbol], with shares and average cost. */
    positionsOf(symbol) {
      const split = R.splits[symbol];
      const basis = costBasis[symbol];
      if (!split || !basis) return [];
      const spread = R.costSpread;
      const total = split.reduce((s, e) => s + e[1], 0);
      let weighted = 0;
      split.forEach((e, i) => { weighted += e[1] * spread[i % spread.length]; });
      const scale = total / weighted;
      return split.map((e, i) => {
        const account = portfolio.accountNamed(e[0]);
        if (!account) return null;
        const averageCost = basis.averageCost * spread[i % spread.length] * scale;
        return { account, shares: e[1], averageCost, get bookValue() { return this.averageCost * this.shares; } };
      }).filter(Boolean);
    },
  };

  // ── Research ──
  function today() { const d = new Date(); d.setHours(0, 0, 0, 0); return d; }
  function addDays(d, n) { const r = new Date(d); r.setDate(r.getDate() + n); return r; }
  const research = {
    profileOf(s) { return R.profiles[s.symbol] || null; },
    fundamentalsOf(s) {
      return Object.assign({ peTtm: null, beta: null, annualDividend: 0, dividendGrowth3y: null, earningsInDays: null, exDividendInDays: null }, R.fundamentals[s.symbol]);
    },
    ratingsOf(s) {
      const r = R.ratings[s.symbol];
      if (!r) return null;
      return withGetters(r, {
        get consensus() {
          const net = (this.buy - this.sell) / 100;
          if (net > 0.6) return 'Strong buy';
          if (net >= 0.2) return 'Moderate buy';
          if (net > -0.2) return 'Hold';
          if (net > -0.6) return 'Moderate sell';
          return 'Strong sell';
        },
      });
    },
    epsTtm(s) { const pe = this.fundamentalsOf(s).peTtm; return pe == null ? null : s.quote.price / pe; },
    dividendYield(s) { const d = this.fundamentalsOf(s).annualDividend; return d > 0 ? d / s.quote.price * 100 : null; },
    payoutRatio(s) {
      const d = this.fundamentalsOf(s).annualDividend; const eps = this.epsTtm(s);
      return d > 0 && eps != null && eps > 0 ? d / eps * 100 : null;
    },
    nextExDividend(s) {
      const f = this.fundamentalsOf(s);
      if (f.exDividendInDays == null || f.annualDividend <= 0) return null;
      return addDays(today(), f.exDividendInDays);
    },
    /** Upcoming and past earnings and ex-dividend dates, newest first. */
    eventsOf(s) {
      const t = today();
      const f = this.fundamentalsOf(s);
      const events = [];
      const quarterReported = (d) => { const q = Math.floor(d.getMonth() / 3); return q === 0 ? `Q4 ${d.getFullYear() - 1}` : `Q${q} ${d.getFullYear()}`; };
      if (f.earningsInDays != null) {
        const eps = this.epsTtm(s);
        for (let i = 0; i < 3; i++) {
          const date = addDays(t, f.earningsInDays - 91 * i);
          const q = quarterReported(date);
          const upcoming = date >= t;
          events.push({ date, kind: 'earnings', description: upcoming
            ? `${s.symbol} will release ${q} earnings.`
            : `${s.symbol} released ${q} earnings${eps == null ? '' : `, with EPS of ${IE.formatCad(eps / 4)} per share`}.` });
        }
      }
      const y = this.dividendYield(s);
      if (f.exDividendInDays != null && y != null) {
        const per = IE.formatCad(f.annualDividend / 4);
        for (let i = 0; i < 3; i++) {
          const date = addDays(t, f.exDividendInDays - 91 * i);
          const upcoming = date >= t;
          events.push({ date, kind: 'exDividend', description: upcoming
            ? `${s.symbol} pays a dividend of ${per} per share, yielding ${y.toFixed(2)}% a year.`
            : `${s.symbol} paid a dividend of ${per} per share.` });
        }
      }
      return events.sort((a, b) => b.date - a.date);
    },
  };

  IE.data = {
    seeded, densify, withGetters, makeQuote, randomWalk, mapShape,
    ChartRange, StockRange, AccountGroup,
    portfolio, securities: securitiesApi, market, holdings, research,
    banks: R.banks,
    fractional: { all: R.fractional, exchanges: ['NASDAQ', 'NYSE', 'NYSE Arca'], marketCaps: ['Mega', 'Large', 'Mid'], sectors: R.fractionalSectors },
    today, addDays,
  };
})();
