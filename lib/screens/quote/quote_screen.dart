import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart' show ScrollDirection;
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../widgets/motion_animated_size.dart';
import '../../data/mock_portfolio.dart';
import '../../router.dart';
import '../../state/balance_visibility.dart';
import '../../theme/obr_tokens.dart';
import '../../theme/obr_typography.dart';
import '../../util/format.dart';
import '../../util/motion.dart';
import '../../widgets/prototype_notice.dart';
import '../../widgets/range_selector.dart';
import '../home/widgets/portfolio_chart.dart';
import 'analyst_ratings_card.dart';
import 'details_tabs.dart';
import 'number_lines.dart';

/// Security details, opened from a search result.
///
/// Buy is always shown. Sell (with the number of shares held) appears only
/// when the client holds the security. Both stay pinned to the bottom.
///
/// Price, change, bid/ask and the day range update in real time (simulated:
/// a small random move every [liveTick]). The price change follows the
/// chart's selected range.
class QuoteScreen extends StatefulWidget {
  const QuoteScreen({super.key, required this.symbol});

  final String symbol;

  static const Duration liveTick = Duration(seconds: 2);

  @override
  State<QuoteScreen> createState() => _QuoteScreenState();
}

class _QuoteScreenState extends State<QuoteScreen> {
  /// As loaded; the chart history is built from this.
  Security? _base;

  /// With the latest simulated quote.
  Security? _live;
  StockRange _range = StockRange.oneDay;
  Timer? _updates;
  final Random _random = Random();

  /// Scrolled down: the top bar shows the compact logo, ticker and live
  /// price instead of Back / alerts / watchlist. Scrolling up brings the
  /// full bar back.
  bool _compact = false;

  /// Scroll distance before the compact bar can appear (roughly the height
  /// of the name and price block).
  static const double _compactAfter = 120;

  late bool _onWatchlist =
      MockPortfolio.sharesHeldOf(widget.symbol) > 0;

  bool _onScroll(ScrollNotification notification) {
    if (notification.metrics.axis != Axis.vertical ||
        notification.depth != 0) {
      return false;
    }
    var compact = _compact;
    if (notification.metrics.pixels <= _compactAfter) {
      compact = false;
    } else if (notification is UserScrollNotification) {
      if (notification.direction == ScrollDirection.reverse) {
        compact = true; // Content moving up: the reader is scrolling down.
      } else if (notification.direction == ScrollDirection.forward) {
        compact = false;
      }
    } else if (notification is ScrollUpdateNotification) {
      final delta = notification.scrollDelta ?? 0;
      if (delta > 2) compact = true;
      if (delta < -2) compact = false;
    }
    if (compact != _compact) setState(() => _compact = compact);
    return false;
  }

  /// Back to wherever this page was opened from (Search, Home, Holdings,
  /// Watchlists…). Opened directly (e.g. a deep link): Home.
  void _back() {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go(AppRoutes.home);
    }
  }

  void _toggleWatchlist() {
    HapticFeedback.lightImpact();
    setState(() => _onWatchlist = !_onWatchlist);
    final symbol = widget.symbol;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(
            _onWatchlist
                ? 'Added $symbol to your watchlist'
                : 'Removed $symbol from your watchlist',
          ),
        ),
      );
  }

  void _openAlerts() {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        const SnackBar(
          content: Text('Price alerts are not built yet in this prototype.'),
        ),
      );
  }

  @override
  void initState() {
    super.initState();
    _base = _live = MockSecurities.bySymbol(widget.symbol);
    if (_base != null) {
      // Next step: replace with a streaming quote subscription (and pause it
      // when the app is backgrounded).
      _updates = Timer.periodic(QuoteScreen.liveTick, (_) => _tick());
    }
  }

  @override
  void didUpdateWidget(QuoteScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Belt and braces with the router's key: if this state is ever reused
    // for another symbol, load that symbol and restart live updates.
    if (oldWidget.symbol != widget.symbol) {
      _updates?.cancel();
      _updates = null;
      _base = _live = MockSecurities.bySymbol(widget.symbol);
      _range = StockRange.oneDay;
      if (_base != null) {
        _updates = Timer.periodic(QuoteScreen.liveTick, (_) => _tick());
      }
    }
  }

  @override
  void dispose() {
    _updates?.cancel();
    super.dispose();
  }

  double _cents(double v) => (v * 100).roundToDouble() / 100;

  int _size() => (1 + _random.nextInt(30)) * 100;

  void _tick() {
    final base = _base!;
    final q = _live!.quote;
    // A move of up to ±0.06%, rounded to the cent, and occasionally none.
    final price = _cents(q.price * (1 + (_random.nextDouble() - 0.5) * 0.0012));
    // Keep the original spread around the new price.
    final bidGap = base.quote.price - base.quote.bid;
    final askGap = base.quote.ask - base.quote.price;
    setState(() {
      _live = base.withQuote(
        q.copyWith(
          price: price,
          bid: _cents(price - bidGap),
          ask: _cents(price + askGap),
          bidSize: _size(),
          askSize: _size(),
          volume: q.volume + (1 + _random.nextInt(20)) * 100,
          dayLow: min(q.dayLow, price),
          dayHigh: max(q.dayHigh, price),
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final base = _base;
    final security = _live;
    if (base == null || security == null) {
      return _NotFound(symbol: widget.symbol);
    }

    final sharesHeld = MockPortfolio.sharesHeldOf(security.symbol);
    final costBasis = sharesHeld > 0
        ? MockHoldings.costBasisOf(security.symbol)
        : null;
    // Change over the chart's range: from the first point of that range's
    // history to the live price.
    final rangeStart = MockMarket.series(base, _range).first;

    return Scaffold(
      body: Column(
        children: [
          _TopBar(
            security: security,
            compact: _compact,
            onWatchlist: _onWatchlist,
            onBack: _back,
            onAlerts: _openAlerts,
            onToggleWatchlist: _toggleWatchlist,
          ),
          Expanded(
            child: NotificationListener<ScrollNotification>(
              onNotification: _onScroll,
              child: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 640),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(
              ObrSpace.s20,
              ObrSpace.s8,
              ObrSpace.s20,
              ObrSpace.s32,
            ),
            children: [
              _Header(security: security),
              const SizedBox(height: ObrSpace.s16),
              _PriceCard(
                security: security,
                rangeStart: rangeStart,
                range: _range,
              ),
              // Half the usual 12pt gap: price and bid/ask read as one block.
              const SizedBox(height: 6),
              _BidAskCard(security: security),
              if (costBasis != null) ...[
                const SizedBox(height: ObrSpace.s12),
                _PositionAccordion(
                  security: security,
                  sharesHeld: sharesHeld,
                  costBasis: costBasis,
                ),
              ],
              const SizedBox(height: ObrSpace.s24),
              _ChartSection(
                security: base,
                range: _range,
                onRange: (range) {
                  HapticFeedback.selectionClick();
                  setState(() => _range = range);
                },
              ),
              const SizedBox(height: ObrSpace.s16),
              QuoteNumberLines(security: security),
              const SizedBox(height: ObrSpace.s24),
              AnalystRatingsCard(security: security),
              const SizedBox(height: ObrSpace.s24),
              QuoteDetailsTabs(security: security),
              const SizedBox(height: ObrSpace.s24),
              _MoreInformation(security: security),
              const SizedBox(height: ObrSpace.s24),
              const PrototypeNotice(
                message: 'Prototype: prices, stats, ratings, chart, stories and '
                    'events on this page are mock data.',
              ),
            ],
          ),
        ),
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: _TradeBar(
        security: security,
        sharesHeld: sharesHeld,
      ),
    );
  }
}

void _openTrade(BuildContext context, Security security, {String? side}) {
  context.push(
    Uri(
      path: AppRoutes.trade,
      queryParameters: {
        'symbol': security.symbol,
        if (side != null) 'side': side,
      },
    ).toString(),
  );
}

// ─── Header ───────────────────────────────────────────────────────────────

/// Monogram, ticker and name at the top of the page.
class _Header extends StatelessWidget {
  const _Header({required this.security});

  final Security security;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _Monogram(symbol: security.symbol, size: ObrSize.s52),
        const SizedBox(width: ObrSpace.s12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Semantics(
                header: true,
                child: Text(security.symbol, style: ObrType.headingLgSemibold),
              ),
              Text(
                security.name,
                style: ObrType.bodyLgBook.copyWith(color: ObrColors.gray600),
              ),
            ],
          ),
        ),
        if (security.fractional) ...[
          const SizedBox(width: ObrSpace.s8),
          const _FractionalTag(),
        ],
      ],
    );
  }
}

/// "Fractional" tag for U.S.-listed securities that can be bought in
/// fractions. Opens the list of fractional stocks and ETFs.
class _FractionalTag extends StatelessWidget {
  const _FractionalTag();

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(ObrRadius.r8);
    return Semantics(
      button: true,
      label: 'Fractional shares available. See all fractional stocks and ETFs',
      excludeSemantics: true,
      child: Material(
        color: ObrColors.gray100,
        borderRadius: radius,
        child: InkWell(
          onTap: () => context.push(AppRoutes.fractional),
          borderRadius: radius,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: ObrSize.s32),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: ObrSpace.s8,
                vertical: ObrSpace.s4,
              ),
              child: Text(
                'Fractional',
                style: ObrType.bodyLgSemibold.copyWith(
                  color: ObrColors.gray700,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Monogram stand-in for the logo. Real logos would come from the market
/// data provider.
class _Monogram extends StatelessWidget {
  const _Monogram({required this.symbol, required this.size});

  final String symbol;
  final double size;

  @override
  Widget build(BuildContext context) {
    return ExcludeSemantics(
      child: Container(
        width: size,
        height: size,
        alignment: Alignment.center,
        decoration: const BoxDecoration(
          color: ObrColors.gray100,
          shape: BoxShape.circle,
        ),
        child: Text(
          symbol.substring(0, 1),
          style: (size >= ObrSize.s52
                  ? ObrType.headingSmSemibold
                  : ObrType.bodyLgSemibold)
              .copyWith(color: ObrColors.gray700),
        ),
      ),
    );
  }
}

/// Top bar. Normally Back on the left with alerts and watchlist on the
/// right. When the reader scrolls down it swaps (fade and slide) to a compact
/// bar with the monogram, ticker and live price; scrolling up swaps back.
class _TopBar extends StatelessWidget {
  const _TopBar({
    required this.security,
    required this.compact,
    required this.onWatchlist,
    required this.onBack,
    required this.onAlerts,
    required this.onToggleWatchlist,
  });

  final Security security;
  final bool compact;
  final bool onWatchlist;
  final VoidCallback onBack;
  final VoidCallback onAlerts;
  final VoidCallback onToggleWatchlist;

  static const double height = ObrSize.s56;

  @override
  Widget build(BuildContext context) {
    final duration = motionDuration(context, ObrDuration.d200);
    final standard = Row(
      key: const ValueKey('standard'),
      children: [
        IconButton(
          tooltip: 'Back',
          onPressed: onBack,
          icon: const Icon(Icons.arrow_back),
          color: ObrColors.gray700,
        ),
        const Spacer(),
        IconButton(
          tooltip: 'Set a price alert for ${security.symbol}',
          onPressed: onAlerts,
          icon: const Icon(Icons.notifications_none),
          color: ObrColors.gray700,
        ),
        IconButton(
          tooltip: onWatchlist
              ? 'Remove ${security.symbol} from watchlist'
              : 'Add ${security.symbol} to watchlist',
          isSelected: onWatchlist,
          onPressed: onToggleWatchlist,
          icon: const Icon(Icons.star_border),
          selectedIcon: const Icon(Icons.star),
          color: ObrColors.gray700,
        ),
      ],
    );
    final compactBar = Padding(
      key: const ValueKey('compact'),
      padding: const EdgeInsets.symmetric(horizontal: ObrSpace.s20),
      child: Semantics(
        header: true,
        label: '${security.symbol} ${formatPrice(security.quote.price)} '
            '${security.currency}',
        excludeSemantics: true,
        child: Row(
          children: [
            _Monogram(symbol: security.symbol, size: 36),
            const SizedBox(width: ObrSpace.s12),
            Text(security.symbol, style: ObrType.headingSm),
            const SizedBox(width: ObrSpace.s12),
            Expanded(
              child: Align(
                alignment: Alignment.centerRight,
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text.rich(
                    TextSpan(
                      children: [
                        TextSpan(
                          text: formatPrice(security.quote.price),
                          style: ObrType.tabular(ObrType.headingSmSemibold),
                        ),
                        TextSpan(
                          text: ' ${security.currency}',
                          style: ObrType.bodyLgBook.copyWith(
                            color: ObrColors.gray600,
                          ),
                        ),
                      ],
                    ),
                    maxLines: 1,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );

    return Material(
      color: ObrColors.gray0,
      child: SafeArea(
        bottom: false,
        child: AnimatedContainer(
          duration: duration,
          height: height,
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: compact ? ObrColors.gray200 : Colors.transparent,
              ),
            ),
          ),
          child: AnimatedSwitcher(
            duration: duration,
            switchInCurve: ObrEasing.easeOut,
            switchOutCurve: ObrEasing.easeIn,
            transitionBuilder: (child, animation) => FadeTransition(
              opacity: animation,
              child: SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(0, 0.25),
                  end: Offset.zero,
                ).animate(animation),
                child: child,
              ),
            ),
            child: compact ? compactBar : standard,
          ),
        ),
      ),
    );
  }
}

// ─── Price, bid and ask (each opens Trade) ───────────────────────────────

class _OutlinedTapTarget extends StatelessWidget {
  const _OutlinedTapTarget({
    required this.child,
    required this.onTap,
    required this.semanticLabel,
  });

  final Widget child;
  final VoidCallback onTap;
  final String semanticLabel;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: semanticLabel,
      excludeSemantics: true,
      child: InkWell(onTap: onTap, child: child),
    );
  }
}

class _PriceCard extends StatelessWidget {
  const _PriceCard({
    required this.security,
    required this.rangeStart,
    required this.range,
  });

  final Security security;

  /// Price at the start of [range]; the change is measured from here.
  final double rangeStart;
  final StockRange range;


  @override
  Widget build(BuildContext context) {
    final quote = security.quote;
    final change = quote.price - rangeStart;
    final percent = rangeStart == 0 ? 0.0 : change / rangeStart * 100;
    final isUp = change >= 0;
    // OBR: green for gains, orange (caution) for declines.
    final changeColor = isUp ? ObrColors.green600 : ObrColors.orange700;
    final changeText = '${formatPrice(change.abs())} '
        '(${percent.abs().toStringAsFixed(2)}%)';

    return Material(
      color: ObrColors.gray0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(ObrRadius.r8),
        side: const BorderSide(color: ObrColors.gray200),
      ),
      clipBehavior: Clip.antiAlias,
      child: _OutlinedTapTarget(
        semanticLabel: '${security.symbol} last price '
            '${formatPrice(quote.price)} ${security.currency}, '
            '${isUp ? 'up' : 'down'} $changeText over ${range.spokenLabel}. '
            'Opens trade.',
        onTap: () => _openTrade(context, security),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: ObrSpace.s16,
            vertical: ObrSpace.s8,
          ),
          child: Wrap(
            spacing: ObrSpace.s8,
            crossAxisAlignment: WrapCrossAlignment.end,
            children: [
              Text(
                formatPrice(quote.price),
                style: ObrType.tabular(ObrType.displayMd),
              ),
              Padding(
                padding: const EdgeInsets.only(bottom: ObrSpace.s4),
                child: Text(
                  security.currency,
                  style: ObrType.bodyLgBook.copyWith(color: ObrColors.gray600),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(bottom: ObrSpace.s4),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      isUp ? Icons.arrow_upward : Icons.arrow_downward,
                      size: ObrSize.s20,
                      color: changeColor,
                    ),
                    const SizedBox(width: ObrSpace.s2),
                    Text(
                      changeText,
                      style: ObrType.tabular(ObrType.bodyLg).copyWith(
                        color: changeColor,
                      ),
                    ),
                  ],
                ),
              ),
              // Same label as the chart's range selector (1D, 5D, 1M…).
              Padding(
                padding: const EdgeInsets.only(bottom: ObrSpace.s4),
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: ObrColors.gray100,
                    borderRadius: BorderRadius.circular(ObrRadius.full),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: ObrSpace.s8,
                      vertical: ObrSpace.s2,
                    ),
                    child: Text(
                      range.label,
                      key: const ValueKey('price-period'),
                      style: ObrType.tabular(ObrType.captionSemibold).copyWith(
                        color: ObrColors.gray700,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BidAskCard extends StatelessWidget {
  const _BidAskCard({required this.security});

  final Security security;

  @override
  Widget build(BuildContext context) {
    final quote = security.quote;
    return Material(
      color: ObrColors.gray0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(ObrRadius.r8),
        side: const BorderSide(color: ObrColors.gray200),
      ),
      clipBehavior: Clip.antiAlias,
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: _QuoteSide(
                label: 'Bid',
                price: quote.bid,
                size: quote.bidSize,
                color: ObrColors.green600,
                alignEnd: false,
                onTap: () => _openTrade(context, security),
              ),
            ),
            const VerticalDivider(width: 1),
            Expanded(
              child: _QuoteSide(
                label: 'Ask',
                price: quote.ask,
                size: quote.askSize,
                color: ObrColors.orange700,
                alignEnd: true,
                onTap: () => _openTrade(context, security),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _QuoteSide extends StatelessWidget {
  const _QuoteSide({
    required this.label,
    required this.price,
    required this.size,
    required this.color,
    required this.alignEnd,
    required this.onTap,
  });

  final String label;
  final double price;
  final int size;
  final Color color;
  final bool alignEnd;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    // One line per side: "Bid   3,100 x 11.24" and "11.28 x 300   Ask".
    // The figures shrink rather than wrap if space runs out.
    final labelText = Text(
      label,
      style: ObrType.bodyMdBook.copyWith(color: ObrColors.gray600),
    );
    final figures = FittedBox(
      fit: BoxFit.scaleDown,
      alignment: alignEnd ? Alignment.centerLeft : Alignment.centerRight,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.baseline,
        textBaseline: TextBaseline.alphabetic,
        children: [
          if (!alignEnd) ...[
            _size(),
            const SizedBox(width: ObrSpace.s4),
          ],
          Text(
            formatPrice(price),
            style: ObrType.tabular(ObrType.headingXs).copyWith(color: color),
          ),
          if (alignEnd) ...[
            const SizedBox(width: ObrSpace.s4),
            _size(),
          ],
        ],
      ),
    );

    return _OutlinedTapTarget(
      semanticLabel: '$label ${formatPrice(price)}, size ${formatWhole(size)}. '
          'Opens trade.',
      onTap: onTap,
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: ObrSize.s44),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: ObrSpace.s12),
          child: Row(
            children: alignEnd
                ? [
                    Expanded(child: figures),
                    const SizedBox(width: ObrSpace.s8),
                    labelText,
                  ]
                : [
                    labelText,
                    const SizedBox(width: ObrSpace.s8),
                    Expanded(child: figures),
                  ],
          ),
        ),
      ),
    );
  }

  Widget _size() => Text(
        alignEnd ? 'x ${formatWhole(size)}' : '${formatWhole(size)} x',
        style: ObrType.tabular(ObrType.caption).copyWith(
          color: ObrColors.gray700,
        ),
      );
}

// ─── Your position ────────────────────────────────────────────────────────

/// Estimated commission to sell, used in the estimated gain/loss. Mock value.
const double _estimatedSellCommission = 6.95;

const String _gainLossTitle = 'Est. gain/loss';

const String _gainLossInfo =
    'Estimated total gain or loss if you sold all your shares at the last '
    'price, after your average cost and estimated commissions. It\'s not a '
    'realized gain or loss and will change as the price moves.';

/// Accordion for a held security. Collapsed: Est. gain/loss (live, with an
/// info icon that explains the estimate). Expanded (animated): Last bought
/// and Average cost. Amounts are masked when balances are hidden.
class _PositionAccordion extends StatefulWidget {
  const _PositionAccordion({
    required this.security,
    required this.sharesHeld,
    required this.costBasis,
  });

  final Security security;
  final int sharesHeld;
  final CostBasis costBasis;

  @override
  State<_PositionAccordion> createState() => _PositionAccordionState();
}

class _PositionAccordionState extends State<_PositionAccordion> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final security = widget.security;
    final costBasis = widget.costBasis;
    final sharesHeld = widget.sharesHeld;
    final hidden = BalanceVisibility.hiddenOf(context);
    final currency = security.currency;
    // Uses the live price, so it moves with the quote.
    final gainLoss = (security.quote.price - costBasis.averageCost) *
            sharesHeld -
        _estimatedSellCommission;
    final gainColor = gainLoss >= 0 ? ObrColors.green600 : ObrColors.orange700;
    final gainText =
        '${gainLoss < 0 ? '\u2212' : '+'}${formatWhole(gainLoss.abs().round())}';
    final date = DateFormat.yMMMd().format(costBasis.lastBuyDate);
    final radius = BorderRadius.circular(ObrRadius.r8);

    void toggle() => setState(() => _expanded = !_expanded);

    return Material(
      color: ObrColors.gray100,
      shape: RoundedRectangleBorder(
        borderRadius: radius,
        // Same thin outline as the price and bid/ask cards.
        side: const BorderSide(color: ObrColors.gray200),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          InkWell(
            onTap: toggle,
            child: ConstrainedBox(
              constraints: const BoxConstraints(minHeight: ObrSize.s64),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  ObrSpace.s20,
                  ObrSpace.s8,
                  ObrSpace.s12,
                  ObrSpace.s8,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Row(
                        children: [
                          Flexible(
                            child: Text(
                              _gainLossTitle,
                              style: ObrType.bodyLg.copyWith(
                                color: ObrColors.gray800,
                              ),
                            ),
                          ),
                          IconButton(
                            tooltip: 'About $_gainLossTitle',
                            onPressed: () => _showInfoSheet(
                              context,
                              _gainLossTitle,
                              _gainLossInfo,
                            ),
                            icon: const Icon(Icons.info_outline),
                            iconSize: ObrSize.s20,
                            color: ObrColors.brand600,
                            // Comfortable tap target around a small icon.
                            constraints: const BoxConstraints.tightFor(
                              width: ObrSize.s44,
                              height: ObrSize.s44,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Semantics(
                      label: hidden
                          ? '$_gainLossTitle hidden'
                          : '$_gainLossTitle $gainText $currency',
                      excludeSemantics: true,
                      child: Text.rich(
                        TextSpan(
                          children: [
                            TextSpan(
                              text: hidden ? hiddenAmount : gainText,
                              style: ObrType.tabular(ObrType.headingXs)
                                  .copyWith(
                                color: hidden ? ObrColors.gray800 : gainColor,
                              ),
                            ),
                            TextSpan(
                              text: ' $currency',
                              style: ObrType.bodyLgBook.copyWith(
                                color: hidden ? ObrColors.gray800 : gainColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    Semantics(
                      button: true,
                      expanded: _expanded,
                      label: _expanded
                          ? 'Hide position details'
                          : 'Show position details',
                      onTap: toggle,
                      excludeSemantics: true,
                      child: AnimatedRotation(
                        turns: _expanded ? 0.5 : 0,
                        duration: motionDuration(context, ObrDuration.d200),
                        child: const SizedBox.square(
                          dimension: ObrSize.s44,
                          child: Icon(
                            Icons.keyboard_arrow_down,
                            color: ObrColors.gray700,
                            size: ObrSize.s28,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          MotionAnimatedSize(
            child: _expanded
                ? Padding(
                    padding: const EdgeInsets.fromLTRB(
                      ObrSpace.s20,
                      0,
                      ObrSpace.s20,
                      ObrSpace.s16,
                    ),
                    child: Column(
                      children: [
                        _PositionRow(
                          label: 'Last bought',
                          detail: '${formatWhole(costBasis.lastBuyShares)} '
                              'shares on $date',
                          value: hidden
                              ? hiddenAmount
                              : formatPrice(costBasis.lastBuyPrice),
                          currency: currency,
                        ),
                        const SizedBox(height: ObrSpace.s8),
                        _PositionRow(
                          label: 'Average cost',
                          detail: '${formatWhole(sharesHeld)} shares',
                          value: hidden
                              ? hiddenAmount
                              : formatPrice(costBasis.averageCost),
                          currency: currency,
                        ),
                      ],
                    ),
                  )
                : const SizedBox(width: double.infinity),
          ),
        ],
      ),
    );
  }
}

/// Explanation for an info icon, in a bottom sheet over a dark scrim.
Future<void> _showInfoSheet(BuildContext context, String title, String body) {
  return showModalBottomSheet<void>(
    context: context,
    barrierColor: Colors.black.withValues(alpha: 0.6),
    backgroundColor: ObrColors.gray0,
    showDragHandle: true,
    useSafeArea: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(ObrRadius.r24)),
    ),
    builder: (sheetContext) => SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          ObrSpace.s24,
          0,
          ObrSpace.s24,
          ObrSpace.s24,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Semantics(
              header: true,
              child: Text(title, style: ObrType.headingSmSemibold),
            ),
            const SizedBox(height: ObrSpace.s12),
            Text(
              body,
              style: ObrType.bodyLgBook.copyWith(color: ObrColors.gray700),
            ),
            const SizedBox(height: ObrSpace.s24),
            FilledButton(
              onPressed: () => Navigator.of(sheetContext).pop(),
              style: FilledButton.styleFrom(
                backgroundColor: ObrColors.gray700,
                foregroundColor: ObrColors.gray0,
                minimumSize: const Size.fromHeight(ObrSize.s52),
                textStyle: ObrType.bodyLgSemibold,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(ObrRadius.r12),
                ),
              ),
              child: const Text('Got it'),
            ),
          ],
        ),
      ),
    ),
  );
}

/// One table row: bold label, optional italic detail or info icon, and the
/// value with its currency on the right.
class _PositionRow extends StatelessWidget {
  const _PositionRow({
    required this.label,
    required this.value,
    required this.currency,
    this.detail,
    this.info,
    this.valueColor,
  });

  final String label;
  final String? detail;

  /// Explanation; shows an info icon after the label that opens it in a
  /// bottom sheet.
  final String? info;
  final String value;
  final String currency;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    final color = valueColor ?? ObrColors.gray800;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: Wrap(
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Text.rich(
                TextSpan(
                  children: [
                    TextSpan(
                      text: label,
                      style: ObrType.bodyLgSemibold.copyWith(
                        color: ObrColors.gray800,
                      ),
                    ),
                    if (detail != null)
                      TextSpan(
                        text: ' $detail',
                        style: ObrType.bodyMdBook.copyWith(
                          color: ObrColors.gray700,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                  ],
                ),
              ),
              if (info != null)
                IconButton(
                  tooltip: 'About $label',
                  onPressed: () => _showInfoSheet(context, label, info!),
                  icon: const Icon(Icons.info_outline),
                  iconSize: ObrSize.s16,
                  color: ObrColors.brand600,
                  padding: EdgeInsets.zero,
                  // Comfortable tap target around a small icon.
                  constraints: const BoxConstraints.tightFor(
                    width: ObrSize.s32,
                    height: ObrSize.s32,
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(width: ObrSpace.s12),
        Text.rich(
          TextSpan(
            children: [
              TextSpan(
                text: value,
                style: ObrType.tabular(ObrType.bodyLgSemibold).copyWith(
                  color: color,
                ),
              ),
              TextSpan(
                text: ' $currency',
                style: ObrType.bodyLgBook.copyWith(color: color),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ─── Chart ────────────────────────────────────────────────────────────────

/// The range lives on the screen, so the price card's change follows it.
class _ChartSection extends StatelessWidget {
  const _ChartSection({
    required this.security,
    required this.range,
    required this.onRange,
  });

  final Security security;
  final StockRange range;
  final ValueChanged<StockRange> onRange;

  /// 50% taller than the previous 108.
  static const double chartHeight = 162;

  @override
  Widget build(BuildContext context) {
    final points = MockMarket.series(security, range);
    final change = points.last - points.first;
    final percent = change / points.first * 100;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        RangeSelector(
          labels: [for (final r in StockRange.values) r.label],
          spokenLabels: [for (final r in StockRange.values) r.spokenLabel],
          selectedIndex: range.index,
          onSelected: (i) => onRange(StockRange.values[i]),
        ),
        const SizedBox(height: ObrSpace.s8),
        SizedBox(
          height: chartHeight,
          child: PortfolioChart(
            key: ValueKey(range),
            points: points,
            lineColor: ObrColors.gray700,
            fillColor: ObrColors.gray400,
            semanticLabel: '${security.symbol} price chart, '
                '${range.spokenLabel}. '
                '${change >= 0 ? 'Up' : 'Down'} '
                '${percent.abs().toStringAsFixed(2)} percent.',
          ),
        ),
        const SizedBox(height: ObrSpace.s8),
        Row(
          children: [
            Semantics(
              link: true,
              child: InkWell(
                onTap: () => context.push(
                  Uri(
                    path: AppRoutes.advancedChart,
                    queryParameters: {'symbol': security.symbol},
                  ).toString(),
                ),
                borderRadius: BorderRadius.circular(ObrRadius.r4),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(minHeight: ObrSize.s44),
                  child: Center(
                    widthFactor: 1,
                    child: Text(
                      'Advanced Chart',
                      style: ObrType.bodyMd.copyWith(
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: ObrSpace.s12),
            Expanded(
              child: Text(
                'Chart data delayed by at least 15 minutes',
                textAlign: TextAlign.end,
                style: ObrType.caption.copyWith(color: ObrColors.gray600),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

// ─── More information accordion ───────────────────────────────────────────

class _MoreInformation extends StatefulWidget {
  const _MoreInformation({required this.security});

  final Security security;

  @override
  State<_MoreInformation> createState() => _MoreInformationState();
}

class _MoreInformationState extends State<_MoreInformation> {
  bool _open = false;

  @override
  Widget build(BuildContext context) {
    final security = widget.security;
    return Material(
      color: ObrColors.gray100,
      borderRadius: BorderRadius.circular(ObrRadius.r8),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Semantics(
            button: true,
            label: 'More information',
            hint: _open ? 'Collapse' : 'Expand',
            excludeSemantics: true,
            child: InkWell(
              onTap: () => setState(() => _open = !_open),
              child: ConstrainedBox(
                constraints: const BoxConstraints(minHeight: ObrSize.s56),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: ObrSpace.s20,
                  ),
                  child: Row(
                    children: [
                      Icon(
                        _open ? Icons.remove : Icons.add,
                        color: ObrColors.brand600,
                      ),
                      const SizedBox(width: ObrSpace.s16),
                      Expanded(
                        child: Text(
                          'More information',
                          style: ObrType.headingSubhead,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          MotionAnimatedSize(
            duration: ObrDuration.d250,
            curve: ObrEasing.easeInOut,
            alignment: Alignment.topCenter,
            child: _open
                ? Padding(
                    padding: const EdgeInsets.fromLTRB(
                      ObrSpace.s20,
                      0,
                      ObrSpace.s20,
                      ObrSpace.s20,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _InfoRow('Exchange', security.exchange),
                        _InfoRow('Currency', security.currency),
                        _InfoRow('Security type', security.type),
                        const SizedBox(height: ObrSpace.s8),
                        Text(
                          '[Company profile, market cap, P/E ratio, dividend '
                          'yield and upcoming events from the market data '
                          'provider]',
                          style: ObrType.bodyMdBook.copyWith(
                            color: ObrColors.gray700,
                          ),
                        ),
                      ],
                    ),
                  )
                : const SizedBox(width: double.infinity),
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow(this.label, this.value);

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return MergeSemantics(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: ObrSpace.s4),
        child: Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: ObrType.bodyMdBook.copyWith(color: ObrColors.gray600),
              ),
            ),
            Text(value, style: ObrType.bodyMd),
          ],
        ),
      ),
    );
  }
}

// ─── Sticky Buy / Sell bar ────────────────────────────────────────────────

class _TradeBar extends StatelessWidget {
  const _TradeBar({required this.security, required this.sharesHeld});

  final Security security;
  final int sharesHeld;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        color: ObrColors.gray50,
        border: Border(top: BorderSide(color: ObrColors.gray200)),
      ),
      child: SafeArea(
        top: false,
        minimum: const EdgeInsets.only(bottom: ObrSpace.s12),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            ObrSpace.s16,
            ObrSpace.s12,
            ObrSpace.s16,
            0,
          ),
          child: Row(
            children: [
              Expanded(
                child: _TradeButton(
                  label: 'Buy',
                  semanticLabel: 'Buy ${security.symbol}',
                  color: ObrColors.green600,
                  onPressed: () => _openTrade(context, security, side: 'buy'),
                ),
              ),
              if (sharesHeld > 0) ...[
                const SizedBox(width: ObrSpace.s12),
                Expanded(
                  child: _TradeButton(
                    label: 'Sell',
                    detail: '(${formatWhole(sharesHeld)} shares held)',
                    semanticLabel: 'Sell ${security.symbol}, '
                        '${formatWhole(sharesHeld)} shares held',
                    color: ObrColors.orange700,
                    onPressed: () =>
                        _openTrade(context, security, side: 'sell'),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _TradeButton extends StatelessWidget {
  const _TradeButton({
    required this.label,
    required this.semanticLabel,
    required this.color,
    required this.onPressed,
    this.detail,
  });

  final String label;
  final String? detail;
  final String semanticLabel;
  final Color color;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: semanticLabel,
      excludeSemantics: true,
      child: FilledButton(
        onPressed: onPressed,
        style: FilledButton.styleFrom(
          backgroundColor: color,
          foregroundColor: ObrColors.gray0,
          minimumSize: const Size.fromHeight(ObrSize.s56),
          padding: const EdgeInsets.symmetric(
            horizontal: ObrSpace.s12,
            vertical: ObrSpace.s8,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(ObrRadius.r12),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: ObrType.headingXs.copyWith(color: ObrColors.gray0),
            ),
            if (detail != null)
              Text(
                detail!,
                textAlign: TextAlign.center,
                style: ObrType.bodyMdBook.copyWith(color: ObrColors.gray0),
              ),
          ],
        ),
      ),
    );
  }
}

// ─── Unknown symbol ───────────────────────────────────────────────────────

class _NotFound extends StatelessWidget {
  const _NotFound({required this.symbol});

  final String symbol;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      body: Padding(
        padding: const EdgeInsets.all(ObrSpace.s20),
        child: Text(
          'No security found for "$symbol".',
          style: ObrType.bodyLgBook,
        ),
      ),
    );
  }
}
