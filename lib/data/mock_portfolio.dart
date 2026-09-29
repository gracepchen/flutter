import 'dart:math';

import '../util/format.dart';

/// Prototype-only data. Replace with a repository backed by the real APIs.

enum ChartRange {
  oneDay('1D', '1 day', 'today'),
  oneWeek('1W', '1 week', 'past week'),
  oneMonth('1M', '1 month', 'past month'),
  threeMonths('3M', '3 months', 'past 3 months'),
  oneYear('1Y', '1 year', 'past year'),
  all('ALL', 'all time', 'all time');

  const ChartRange(this.label, this.spokenLabel, this.changeSuffix);

  /// Short label shown on the range selector.
  final String label;

  /// Label read by screen readers.
  final String spokenLabel;

  /// Follows the change figure, as in "+$1,284.20 (+1.04%) today".
  final String changeSuffix;
}

class PortfolioSeries {
  const PortfolioSeries(this.points);

  final List<double> points;

  double get start => points.first;
  double get end => points.last;
  double get change => end - start;
  double get changePercent => start == 0 ? 0 : change / start * 100;
}

class Account {
  const Account({
    required this.name,
    required this.number,
    required this.value,
    required this.changePercent,
    required this.cashCad,
    required this.cashUsd,
  });

  final String name;

  /// Mock account number.
  final String number;
  final double value;
  final double changePercent;

  /// Uninvested cash, held separately in each currency.
  final double cashCad;
  final double cashUsd;
}

enum ActivityKind { deposit, buy, sell, dividend, transfer }

class ActivityItem {
  const ActivityItem({
    required this.kind,
    required this.title,
    required this.detail,
    required this.amount,
    this.pending = false,
  });

  final ActivityKind kind;
  final String title;
  final String detail;
  final double amount;
  final bool pending;
}

/// Delayed quote and key stats for a security. Prototype-only values.
class Quote {
  const Quote({
    required this.price,
    required this.previousClose,
    required this.bid,
    required this.bidSize,
    required this.ask,
    required this.askSize,
    required this.volume,
    required this.open,
    required this.dayLow,
    required this.dayHigh,
    required this.yearLow,
    required this.yearHigh,
  });

  final double price;
  final double previousClose;
  final double bid;
  final int bidSize;
  final double ask;
  final int askSize;
  final int volume;
  final double open;
  final double dayLow;
  final double dayHigh;
  final double yearLow;
  final double yearHigh;

  double get change => price - previousClose;
  double get changePercent => change / previousClose * 100;

  Quote copyWith({
    double? price,
    double? bid,
    int? bidSize,
    double? ask,
    int? askSize,
    int? volume,
    double? dayLow,
    double? dayHigh,
  }) =>
      Quote(
        price: price ?? this.price,
        previousClose: previousClose,
        bid: bid ?? this.bid,
        bidSize: bidSize ?? this.bidSize,
        ask: ask ?? this.ask,
        askSize: askSize ?? this.askSize,
        volume: volume ?? this.volume,
        open: open,
        dayLow: dayLow ?? this.dayLow,
        dayHigh: dayHigh ?? this.dayHigh,
        yearLow: yearLow,
        yearHigh: yearHigh,
      );
}

class Security {
  const Security({
    required this.symbol,
    required this.name,
    required this.exchange,
    required this.type,
    required this.currency,
    required this.quote,
  });

  final String symbol;
  final String name;
  final String exchange;

  /// "Stock" or "ETF".
  final String type;

  /// "CAD" or "USD".
  final String currency;
  final Quote quote;

  /// U.S.-listed (single exchange) securities can be bought in fractions.
  bool get fractional => exchange == 'NASDAQ' || exchange == 'NYSE';

  /// The same security with a newer quote (live updates on stock details).
  Security withQuote(Quote quote) => Security(
        symbol: symbol,
        name: name,
        exchange: exchange,
        type: type,
        currency: currency,
        quote: quote,
      );
}

/// Chart ranges on the security details page.
enum StockRange {
  oneDay('1D', '1 day'),
  fiveDays('5D', '5 days'),
  oneMonth('1M', '1 month'),
  threeMonths('3M', '3 months'),
  sixMonths('6M', '6 months'),
  oneYear('1Y', '1 year'),
  fiveYears('5Y', '5 years');

  const StockRange(this.label, this.spokenLabel);

  final String label;
  final String spokenLabel;
}

/// A random walk that trends upward, so [_mapShape] keeps it upright.
List<double> _randomWalk({required int seed, int length = 36}) {
  final random = Random(seed);
  var value = 0.0;
  final points = <double>[value];
  for (var i = 1; i < length; i++) {
    value += random.nextDouble() - 0.35;
    points.add(value);
  }
  if (points.last <= points.first) {
    final lift = (points.first - points.last) / (length - 1) + 0.1;
    for (var i = 0; i < length; i++) {
      points[i] += i * lift;
    }
  }
  return points;
}

/// Maps [shape] so its first point is [start] and its last is [end].
List<double> _mapShape(List<double> shape, double start, double end) {
  final s0 = shape.first;
  final span = shape.last - shape.first;
  return List.unmodifiable([
    for (final p in shape)
      span == 0 ? start : start + (p - s0) / span * (end - start),
  ]);
}

abstract final class MockPortfolio {
  static const String firstName = 'Taylor';
  static const String initials = 'T';

  static const double totalValue = 124820.42;

  // Account values add up to [totalValue], and their daily changes roughly
  // add up to the portfolio's +$1,284.20 today. Cash figures are made up.
  static const List<Account> accounts = [
    Account(
      name: 'TFSA',
      number: '58204417',
      value: 34726.81,
      changePercent: 1.2,
      cashCad: 123.52,
      cashUsd: 238.15,
    ),
    Account(
      name: 'Non-Registered',
      number: '58204425',
      value: 41240.12,
      changePercent: -0.04,
      cashCad: 1423.25,
      cashUsd: 0.00,
    ),
    Account(
      name: 'RRSP',
      number: '58204433',
      value: 30960.15,
      changePercent: 1.6,
      cashCad: 157.89,
      cashUsd: 209.63,
    ),
    Account(
      name: 'FHSA',
      number: '58204441',
      value: 4960.51,
      changePercent: 2.6,
      cashCad: 104.26,
      cashUsd: 58.44,
    ),
    Account(
      name: 'RESP',
      number: '58204458',
      value: 12932.83,
      changePercent: 2.0,
      cashCad: 4.82,
      cashUsd: 30.47,
    ),
  ];

  static Account? accountNamed(String name) {
    for (final a in accounts) {
      if (a.name == name) return a;
    }
    return null;
  }

  /// Shares held across all accounts, by symbol. Symbols not listed are
  /// not held, so their details page shows Buy only.
  static const Map<String, int> sharesHeld = {
    'CM': 250,
    'XEQT': 310,
    'VFV': 85,
    'ENB': 120,
    'AAPL': 40,
  };

  static int sharesHeldOf(String symbol) => sharesHeld[symbol] ?? 0;

  // Financial progress on Home. Years are relative to today, so the chart
  // always ends at the current year.
  static int get _year => DateTime.now().year;

  /// Money put in (deposits and transfers in), per calendar year. The last
  /// entry is this year to date.
  static List<(int, double)> get investedByYear => [
        (_year - 2, 11425.15),
        (_year - 1, 6341.97),
        (_year, 20402.92),
      ];

  /// Dividends received in past full years.
  static List<(int, double)> get dividendsByYear => [
        (_year - 2, 291.03),
        (_year - 1, 365.10),
      ];

  /// Dividends received so far this year, and projected for the full year
  /// from current holdings and announced payouts.
  static const double dividendsYearToDate = 451.92;
  static const double dividendsProjectedThisYear = 513.10;

  static const List<ActivityItem> recentActivity = [
    ActivityItem(
      kind: ActivityKind.deposit,
      title: 'Deposit initiated',
      detail: 'TFSA · Sep 22',
      amount: 1000.00,
      pending: true,
    ),
    ActivityItem(
      kind: ActivityKind.buy,
      title: 'Bought XEQT',
      detail: '25 shares · Non-Registered · Sep 19',
      amount: -812.50,
    ),
    ActivityItem(
      kind: ActivityKind.dividend,
      title: 'Dividend received',
      detail: 'ENB · RRSP · Sep 15',
      amount: 46.21,
    ),
  ];

  /// Most recent trades, newest first (Recent activity's Trades view).
  static const List<ActivityItem> recentTrades = [
    ActivityItem(
      kind: ActivityKind.buy,
      title: 'Bought XEQT',
      detail: '25 shares · Non-Registered · Sep 19',
      amount: -812.50,
    ),
    ActivityItem(
      kind: ActivityKind.sell,
      title: 'Sold CM',
      detail: '20 shares · TFSA · Sep 12',
      amount: 1742.60,
    ),
    ActivityItem(
      kind: ActivityKind.buy,
      title: 'Bought AAPL',
      detail: '10 shares · RRSP · Sep 3',
      amount: -3208.35,
    ),
    ActivityItem(
      kind: ActivityKind.buy,
      title: 'Bought VFV',
      detail: '15 shares · TFSA · Aug 27',
      amount: -2118.30,
    ),
  ];

  /// Portfolio value at the start of each range. The 1D figure gives the
  /// mock's "+$1,284.20 (+1.04%) today".
  static const Map<ChartRange, double> _startValues = {
    ChartRange.oneDay: 123536.22,
    ChartRange.oneWeek: 122410.80,
    ChartRange.oneMonth: 120955.10,
    ChartRange.threeMonths: 116302.44,
    ChartRange.oneYear: 104688.73,
    ChartRange.all: 62500.00,
  };

  /// Intraday shape traced from the design mock.
  static const List<double> _oneDayShape = [
    0.25, 0.40, 0.33, 0.47, 0.44, 0.62, 0.52, 0.75, 0.63, 0.30, 0.45, //
    0.38, 0.58, 0.49, 0.72, 0.66, 0.80, 0.70, 0.90, 0.98, 0.93,
  ];

  static final Map<ChartRange, PortfolioSeries> _cache = {};

  static PortfolioSeries series(ChartRange range) =>
      _cache.putIfAbsent(range, () => _build(range));

  static PortfolioSeries _build(ChartRange range) {
    final shape = range == ChartRange.oneDay
        ? _oneDayShape
        : _randomWalk(seed: 17 + range.index * 7919);
    final start = _startValues[range]!;
    const end = totalValue;

    return PortfolioSeries(_mapShape(shape, start, end));
  }
}

abstract final class MockSecurities {
  // Made-up quotes for the prototype. Each is internally consistent
  // (bid < price < ask, price within the day range), but none are real.
  static const List<Security> all = [
    Security(
      symbol: 'CM',
      name: 'Canadian Imperial Bank of Commerce',
      exchange: 'TSX',
      type: 'Stock',
      currency: 'CAD',
      quote: Quote(
        price: 88.42,
        previousClose: 87.79,
        bid: 88.40,
        bidSize: 1200,
        ask: 88.44,
        askSize: 800,
        volume: 2184305,
        open: 87.95,
        dayLow: 87.71,
        dayHigh: 88.63,
        yearLow: 58.20,
        yearHigh: 90.15,
      ),
    ),
    Security(
      symbol: 'XEQT',
      name: 'iShares Core Equity ETF Portfolio',
      exchange: 'TSX',
      type: 'ETF',
      currency: 'CAD',
      quote: Quote(
        price: 32.87,
        previousClose: 32.61,
        bid: 32.86,
        bidSize: 5000,
        ask: 32.88,
        askSize: 4200,
        volume: 612480,
        open: 32.65,
        dayLow: 32.58,
        dayHigh: 32.94,
        yearLow: 27.10,
        yearHigh: 33.05,
      ),
    ),
    Security(
      symbol: 'VFV',
      name: 'Vanguard S&P 500 Index ETF',
      exchange: 'TSX',
      type: 'ETF',
      currency: 'CAD',
      quote: Quote(
        price: 148.35,
        previousClose: 149.02,
        bid: 148.31,
        bidSize: 300,
        ask: 148.39,
        askSize: 450,
        volume: 301227,
        open: 148.90,
        dayLow: 147.96,
        dayHigh: 149.20,
        yearLow: 121.44,
        yearHigh: 151.80,
      ),
    ),
    Security(
      symbol: 'ZAG',
      name: 'BMO Aggregate Bond Index ETF',
      exchange: 'TSX',
      type: 'ETF',
      currency: 'CAD',
      quote: Quote(
        price: 13.72,
        previousClose: 13.70,
        bid: 13.71,
        bidSize: 9000,
        ask: 13.73,
        askSize: 7500,
        volume: 845110,
        open: 13.70,
        dayLow: 13.68,
        dayHigh: 13.74,
        yearLow: 13.12,
        yearHigh: 14.05,
      ),
    ),
    Security(
      symbol: 'ENB',
      name: 'Enbridge Inc.',
      exchange: 'TSX',
      type: 'Stock',
      currency: 'CAD',
      quote: Quote(
        price: 58.16,
        previousClose: 58.64,
        bid: 58.14,
        bidSize: 1500,
        ask: 58.18,
        askSize: 1100,
        volume: 4012336,
        open: 58.60,
        dayLow: 57.92,
        dayHigh: 58.77,
        yearLow: 47.30,
        yearHigh: 60.12,
      ),
    ),
    Security(
      symbol: 'SHOP',
      name: 'Shopify Inc.',
      exchange: 'TSX',
      type: 'Stock',
      currency: 'CAD',
      quote: Quote(
        price: 142.80,
        previousClose: 139.95,
        bid: 142.72,
        bidSize: 200,
        ask: 142.88,
        askSize: 350,
        volume: 1650930,
        open: 140.20,
        dayLow: 139.60,
        dayHigh: 143.40,
        yearLow: 82.50,
        yearHigh: 160.25,
      ),
    ),
    Security(
      symbol: 'AAPL',
      name: 'Apple Inc.',
      exchange: 'NASDAQ',
      type: 'Stock',
      currency: 'USD',
      quote: Quote(
        price: 231.44,
        previousClose: 233.10,
        bid: 231.40,
        bidSize: 400,
        ask: 231.48,
        askSize: 600,
        volume: 48210556,
        open: 232.80,
        dayLow: 230.95,
        dayHigh: 233.55,
        yearLow: 169.21,
        yearHigh: 260.10,
      ),
    ),
    Security(
      symbol: 'MSFT',
      name: 'Microsoft Corporation',
      exchange: 'NASDAQ',
      type: 'Stock',
      currency: 'USD',
      quote: Quote(
        price: 512.30,
        previousClose: 508.75,
        bid: 512.20,
        bidSize: 300,
        ask: 512.42,
        askSize: 200,
        volume: 18344120,
        open: 509.40,
        dayLow: 507.90,
        dayHigh: 514.10,
        yearLow: 385.58,
        yearHigh: 555.45,
      ),
    ),
  ];

  static Security? bySymbol(String symbol) {
    final upper = symbol.toUpperCase();
    for (final s in all) {
      if (s.symbol == upper) return s;
    }
    return null;
  }

  static const List<String> recentSearches = ['XEQT', 'VFV', 'ENB', 'CM'];

  static List<Security> search(String query) {
    final q = query.trim().toLowerCase();
    if (q.isEmpty) return const [];
    return [
      for (final s in all)
        if (s.symbol.toLowerCase().startsWith(q) ||
            s.name.toLowerCase().contains(q))
          s,
    ];
  }
}

abstract final class MockMarket {
  /// Made-up USDCAD rate, shown under Accounts and Top Holdings and used to
  /// value U.S. holdings in CAD.
  static const double usdToCad = 1.40123;

  /// The rate is as of the last business day (weekends skipped; holidays
  /// aren't modelled in the prototype).
  static DateTime get usdToCadAsOf {
    final now = DateTime.now();
    var day = DateTime(now.year, now.month, now.day)
        .subtract(const Duration(days: 1));
    while (day.weekday == DateTime.saturday ||
        day.weekday == DateTime.sunday) {
      day = day.subtract(const Duration(days: 1));
    }
    return day;
  }

  static double toCad(double amount, String currency) =>
      currency == 'USD' ? amount * usdToCad : amount;

  static final Map<String, List<double>> _cache = {};

  /// Price history for [security] over [range], ending at the current price.
  /// 1D starts at the previous close; longer ranges start at a seeded,
  /// made-up earlier price.
  static List<double> series(Security security, StockRange range) =>
      _cache.putIfAbsent(
        '${security.symbol}/${range.name}',
        () => _build(security, range),
      );

  static List<double> _build(Security security, StockRange range) {
    final symbolSeed = security.symbol.codeUnits
        .fold<int>(0, (seed, unit) => (seed * 31 + unit) % 1000003);
    final seed = symbolSeed + range.index * 7919;
    final random = Random(seed);
    final end = security.quote.price;
    final start = range == StockRange.oneDay
        ? security.quote.previousClose
        // Somewhere from 6% above to 14% below today, widening with range.
        : end *
            (1 - (random.nextDouble() * 0.20 - 0.06) * (1 + range.index * 0.4));
    return _mapShape(_randomWalk(seed: seed, length: 44), start, end);
  }
}

/// One position, summed across all accounts, valued in CAD.
class Holding {
  const Holding({
    required this.security,
    required this.shares,
    required this.marketValueCad,
    required this.dayChangeCad,
    required this.bookValueCad,
  });

  final Security security;
  final int shares;
  final double marketValueCad;
  final double dayChangeCad;

  /// What was paid for the position, in CAD.
  final double bookValueCad;

  /// Unrealized gain or loss since purchase, in CAD.
  double get totalGainCad => marketValueCad - bookValueCad;

  double get dayChangePercent => security.quote.changePercent;

  /// Share of the whole portfolio's value.
  double get weightPercent =>
      marketValueCad / MockPortfolio.totalValue * 100;
}

/// Average cost and the most recent buy for a held security, in the
/// security's own currency.
class CostBasis {
  const CostBasis({
    required this.averageCost,
    required this.lastBuyShares,
    required this.lastBuyPrice,
    required this.lastBuyDate,
  });

  /// Average cost per share across all shares held.
  final double averageCost;
  final int lastBuyShares;
  final double lastBuyPrice;
  final DateTime lastBuyDate;
}

abstract final class MockHoldings {
  /// Made-up cost basis for each held security. Book value comes from the
  /// average cost, so Total gain/loss on Holdings agrees with it.
  static final Map<String, CostBasis> costBasis = {
    'CM': CostBasis(
      averageCost: 72.47,
      lastBuyShares: 50,
      lastBuyPrice: 84.10,
      lastBuyDate: DateTime(2026, 8, 14),
    ),
    'AAPL': CostBasis(
      averageCost: 164.14,
      lastBuyShares: 10,
      lastBuyPrice: 205.60,
      lastBuyDate: DateTime(2026, 5, 8),
    ),
    'VFV': CostBasis(
      averageCost: 125.72,
      lastBuyShares: 15,
      lastBuyPrice: 141.22,
      lastBuyDate: DateTime(2026, 7, 3),
    ),
    'XEQT': CostBasis(
      averageCost: 29.35,
      lastBuyShares: 60,
      lastBuyPrice: 32.05,
      lastBuyDate: DateTime(2026, 9, 2),
    ),
    'ENB': CostBasis(
      averageCost: 59.12,
      lastBuyShares: 60,
      lastBuyPrice: 55.14,
      lastBuyDate: DateTime(2026, 6, 26),
    ),
  };

  static CostBasis? costBasisOf(String symbol) => costBasis[symbol];

  /// Every held security, largest market value first.
  static List<Holding> get all {
    final holdings = [
      for (final entry in MockPortfolio.sharesHeld.entries)
        if (MockSecurities.bySymbol(entry.key) case final security?)
          Holding(
            security: security,
            shares: entry.value,
            marketValueCad: MockMarket.toCad(
              security.quote.price * entry.value,
              security.currency,
            ),
            dayChangeCad: MockMarket.toCad(
              security.quote.change * entry.value,
              security.currency,
            ),
            bookValueCad: MockMarket.toCad(
              (costBasis[entry.key]?.averageCost ?? security.quote.price) *
                  entry.value,
              security.currency,
            ),
          ),
    ]..sort((a, b) => b.marketValueCad.compareTo(a.marketValueCad));
    return holdings;
  }

  static List<Holding> top([int count = 5]) => all.take(count).toList();
}

// ─── Research: fundamentals, analyst ratings and events ────────────────────

/// Key stats inputs for a security. Derived figures (EPS, yield, payout
/// ratio) are computed from these so they always agree with the price.
class Fundamentals {
  const Fundamentals({
    required this.marketCap,
    required this.averageVolume3m,
    this.peTtm,
    this.beta,
    this.annualDividend = 0,
    this.dividendGrowth3y,
    this.earningsInDays,
    this.exDividendInDays,
  });

  /// Market cap for stocks; net assets for ETFs. In the security's currency.
  final double marketCap;

  /// Average daily volume over the last 3 months.
  final int averageVolume3m;
  final double? peTtm;
  final double? beta;

  /// Annual dividend per share; 0 for non-payers.
  final double annualDividend;

  /// Annualized dividend growth over 3 years, in percent.
  final double? dividendGrowth3y;

  /// Days from today to the next earnings release (stocks only). Relative,
  /// so the Events list always has upcoming and past entries.
  final int? earningsInDays;

  /// Days from today to the next ex-dividend date (payers only).
  final int? exDividendInDays;
}

class AnalystRatings {
  const AnalystRatings({
    required this.analysts,
    required this.buy,
    required this.hold,
    required this.sell,
  });

  final int analysts;

  /// Percentages; they add up to 100.
  final int buy;
  final int hold;
  final int sell;

  /// Overall consensus from the net of buy and sell ratings:
  /// Strong buy, Moderate buy, Hold, Moderate sell or Strong sell.
  String get consensus {
    final net = (buy - sell) / 100;
    if (net > 0.6) return 'Strong buy';
    if (net >= 0.2) return 'Moderate buy';
    if (net > -0.2) return 'Hold';
    if (net > -0.6) return 'Moderate sell';
    return 'Strong sell';
  }
}

enum StockEventKind { earnings, exDividend }

class StockEvent {
  const StockEvent({
    required this.date,
    required this.kind,
    required this.description,
  });

  final DateTime date;
  final StockEventKind kind;
  final String description;
}

abstract final class MockResearch {
  static const Map<String, Fundamentals> _fundamentals = {
    'CM': Fundamentals(
      marketCap: 83.1e9,
      averageVolume3m: 2910000,
      peTtm: 12.1,
      beta: 1.08,
      annualDividend: 3.88,
      dividendGrowth3y: 5.2,
      earningsInDays: 63,
      exDividendInDays: 0,
    ),
    'XEQT': Fundamentals(
      marketCap: 8.4e9,
      averageVolume3m: 540000,
      beta: 0.95,
      annualDividend: 0.61,
      dividendGrowth3y: 7.4,
      exDividendInDays: 89,
    ),
    'VFV': Fundamentals(
      marketCap: 18.7e9,
      averageVolume3m: 420000,
      beta: 1.00,
      annualDividend: 1.51,
      dividendGrowth3y: 6.1,
      exDividendInDays: 5,
    ),
    'ZAG': Fundamentals(
      marketCap: 9.6e9,
      averageVolume3m: 1050000,
      beta: 0.23,
      annualDividend: 0.44,
      dividendGrowth3y: 2.0,
      exDividendInDays: 5,
    ),
    'ENB': Fundamentals(
      marketCap: 126.8e9,
      averageVolume3m: 5300000,
      peTtm: 20.4,
      beta: 0.87,
      annualDividend: 3.77,
      dividendGrowth3y: 3.1,
      earningsInDays: 42,
      exDividendInDays: 51,
    ),
    'SHOP': Fundamentals(
      marketCap: 185.6e9,
      averageVolume3m: 1900000,
      peTtm: 78.5,
      beta: 2.34,
      earningsInDays: 36,
    ),
    'AAPL': Fundamentals(
      marketCap: 3.44e12,
      averageVolume3m: 52700000,
      peTtm: 35.2,
      beta: 1.21,
      annualDividend: 1.04,
      dividendGrowth3y: 4.2,
      earningsInDays: 35,
      exDividendInDays: 44,
    ),
    'MSFT': Fundamentals(
      marketCap: 3.81e12,
      averageVolume3m: 21400000,
      peTtm: 37.6,
      beta: 0.91,
      annualDividend: 3.32,
      dividendGrowth3y: 10.2,
      earningsInDays: 33,
      exDividendInDays: 56,
    ),
  };

  /// Stocks only; ETFs have no analyst ratings.
  static const Map<String, AnalystRatings> _ratings = {
    'CM': AnalystRatings(analysts: 14, buy: 57, hold: 36, sell: 7),
    'ENB': AnalystRatings(analysts: 18, buy: 28, hold: 61, sell: 11),
    'SHOP': AnalystRatings(analysts: 42, buy: 64, hold: 31, sell: 5),
    'AAPL': AnalystRatings(analysts: 48, buy: 60, hold: 33, sell: 7),
    'MSFT': AnalystRatings(analysts: 55, buy: 91, hold: 7, sell: 2),
  };

  static Fundamentals fundamentalsOf(Security s) => _fundamentals[s.symbol]!;

  static AnalystRatings? ratingsOf(Security s) => _ratings[s.symbol];

  static double? epsTtm(Security s) {
    final pe = fundamentalsOf(s).peTtm;
    return pe == null ? null : s.quote.price / pe;
  }

  /// Percent, or null for non-payers.
  static double? dividendYield(Security s) {
    final dividend = fundamentalsOf(s).annualDividend;
    return dividend > 0 ? dividend / s.quote.price * 100 : null;
  }

  /// Percent of earnings paid out as dividends, or null if not applicable.
  static double? payoutRatio(Security s) {
    final dividend = fundamentalsOf(s).annualDividend;
    final eps = epsTtm(s);
    return dividend > 0 && eps != null && eps > 0 ? dividend / eps * 100 : null;
  }

  static DateTime _today() {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day);
  }

  /// The next ex-dividend date (today counts), or null for non-payers.
  static DateTime? nextExDividend(Security s) {
    final f = fundamentalsOf(s);
    if (f.exDividendInDays == null || f.annualDividend <= 0) return null;
    return _today().add(Duration(days: f.exDividendInDays!));
  }

  /// "Q3 2026" for a release in Oct–Dec 2026 (it reports the prior quarter).
  static String _quarterReported(DateTime release) {
    final quarter = (release.month - 1) ~/ 3;
    return quarter == 0
        ? 'Q4 ${release.year - 1}'
        : 'Q$quarter ${release.year}';
  }

  /// Upcoming and past earnings and ex-dividend dates, newest first: the
  /// next of each plus the two before it, a quarter apart.
  static List<StockEvent> eventsOf(Security s) {
    final today = _today();
    final f = fundamentalsOf(s);
    final events = <StockEvent>[];

    if (f.earningsInDays != null) {
      final eps = epsTtm(s);
      for (var i = 0; i < 3; i++) {
        final date = today.add(Duration(days: f.earningsInDays! - 91 * i));
        final quarter = _quarterReported(date);
        final upcoming = !date.isBefore(today);
        events.add(StockEvent(
          date: date,
          kind: StockEventKind.earnings,
          description: upcoming
              ? '${s.symbol} will release $quarter earnings.'
              : '${s.symbol} released $quarter earnings'
                  '${eps == null ? '' : ', with EPS of ${formatCad(eps / 4)} per share'}.',
        ));
      }
    }

    final dividendYieldPercent = dividendYield(s);
    if (f.exDividendInDays != null && dividendYieldPercent != null) {
      final perPayment = formatCad(f.annualDividend / 4);
      final yieldText = dividendYieldPercent.toStringAsFixed(2);
      for (var i = 0; i < 3; i++) {
        final date = today.add(Duration(days: f.exDividendInDays! - 91 * i));
        final upcoming = !date.isBefore(today);
        events.add(StockEvent(
          date: date,
          kind: StockEventKind.exDividend,
          description: upcoming
              ? '${s.symbol} pays a dividend of $perPayment per share, '
                  'yielding $yieldText% a year.'
              : '${s.symbol} paid a dividend of $perPayment per share.',
        ));
      }
    }

    events.sort((a, b) => b.date.compareTo(a.date));
    return events;
  }
}
