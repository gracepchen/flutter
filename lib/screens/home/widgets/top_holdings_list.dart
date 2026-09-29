import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../../../data/mock_portfolio.dart';
import '../../../router.dart';
import '../../../state/balance_visibility.dart';
import '../../../theme/obr_tokens.dart';
import '../../../theme/obr_typography.dart';
import '../../../util/format.dart';
import '../../../widgets/fade_switcher.dart';
import '../../../widgets/swipe_reveal_row.dart';

/// The five largest positions across all accounts (ranked in CAD). Each row
/// shows the ticker and the number of shares held, then either its market
/// value with today's change or, with [showPrice], the price per share with
/// today's change, both in the security's own currency. Prices update in
/// real time (simulated: a small move every [tick]).
///
/// Tapping a row opens that security's details. Swiping a row left (or
/// long-pressing it) slides in Buy and Sell, which open Trade.
class TopHoldingsList extends StatefulWidget {
  const TopHoldingsList({super.key, this.showPrice = false});

  /// Set by the card's Total / Price toggle.
  final bool showPrice;

  static const Duration tick = Duration(seconds: 2);

  /// Widget tests turn this off so figures stay at their mock values.
  @visibleForTesting
  static bool liveUpdates = true;

  @override
  State<TopHoldingsList> createState() => _TopHoldingsListState();
}

class _TopHoldingsListState extends State<TopHoldingsList> {
  String? _openSymbol;
  final Random _random = Random(42);
  late final List<Holding> _holdings = MockHoldings.top();

  /// Live price per symbol, starting at the mock quote.
  late final Map<String, double> _prices = {
    for (final h in _holdings) h.security.symbol: h.security.quote.price,
  };
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    // Next step: subscribe to streaming quotes for these symbols.
    if (TopHoldingsList.liveUpdates) {
      _timer = Timer.periodic(TopHoldingsList.tick, (_) => _tick());
    }
  }

  void _tick() {
    setState(() {
      for (final entry in _prices.entries.toList()) {
        // Up to ±0.06% per tick, rounded to the cent.
        final next = entry.value * (1 + (_random.nextDouble() - 0.5) * 0.0012);
        _prices[entry.key] = (next * 100).roundToDouble() / 100;
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _setOpen(String? symbol) {
    if (symbol == _openSymbol) return;
    if (symbol != null) HapticFeedback.lightImpact();
    setState(() => _openSymbol = symbol);
  }

  void _openTrade(String symbol, String side) {
    _setOpen(null);
    context.push(
      Uri(
        path: AppRoutes.trade,
        queryParameters: {'symbol': symbol, 'side': side},
      ).toString(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final holding in _holdings)
          Builder(
            builder: (context) {
              final symbol = holding.security.symbol;
              return SwipeRevealRow(
                isOpen: symbol == _openSymbol,
                onOpenChanged: (open) => _setOpen(open ? symbol : null),
                onTap: () => context.push('${AppRoutes.quote}/$symbol'),
                // Monogram (40) + gap (12) + at least 72 for the name.
                minLeadingWidth: 124,
                semanticActions: {
                  'Buy $symbol': () => _openTrade(symbol, 'buy'),
                  'Sell $symbol': () => _openTrade(symbol, 'sell'),
                },
                leading: Row(
                  children: [
                    _Monogram(symbol: symbol),
                    const SizedBox(width: ObrSpace.s12),
                    Expanded(child: _NameColumn(holding: holding)),
                  ],
                ),
                details: _Figures(
                  holding: holding,
                  price: _prices[symbol]!,
                  showPrice: widget.showPrice,
                ),
                actions: _TradeButtons(
                  symbol: symbol,
                  onBuy: () => _openTrade(symbol, 'buy'),
                  onSell: () => _openTrade(symbol, 'sell'),
                ),
              );
            },
          ),
      ],
    );
  }
}

/// Stand-in for the company logo until real logos come from the data provider.
class _Monogram extends StatelessWidget {
  const _Monogram({required this.symbol});

  final String symbol;

  @override
  Widget build(BuildContext context) {
    return ExcludeSemantics(
      child: Container(
        width: ObrSize.s40,
        height: ObrSize.s40,
        alignment: Alignment.center,
        decoration: const BoxDecoration(
          color: ObrColors.gray100,
          shape: BoxShape.circle,
        ),
        child: Text(
          symbol.substring(0, 1),
          style: ObrType.bodyLgSemibold.copyWith(color: ObrColors.gray700),
        ),
      ),
    );
  }
}

class _NameColumn extends StatelessWidget {
  const _NameColumn({required this.holding});

  final Holding holding;

  @override
  Widget build(BuildContext context) {
    final hidden = BalanceVisibility.hiddenOf(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          holding.security.symbol,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: ObrType.bodyLgSemibold,
        ),
        // Shares held (hidden with balances), in place of the company name.
        Text(
          '${hidden ? hiddenAmount : formatWhole(holding.shares)} shares',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: ObrType.tabular(ObrType.bodyMdBook).copyWith(
            color: ObrColors.gray600,
          ),
        ),
      ],
    );
  }
}

/// Market value and today's change (Total), or price per share and today's
/// change per share (Price), in the security's own currency.
class _Figures extends StatelessWidget {
  const _Figures({
    required this.holding,
    required this.price,
    required this.showPrice,
  });

  final Holding holding;

  /// Live price per share.
  final double price;
  final bool showPrice;

  @override
  Widget build(BuildContext context) {
    final hidden = BalanceVisibility.hiddenOf(context);
    final security = holding.security;
    final currency = security.currency;
    final previousClose = security.quote.previousClose;
    final changePerShare = price - previousClose;
    final percent = changePerShare / previousClose * 100;
    final isUp = changePerShare >= 0;
    // OBR: green for gains, orange (caution) for declines.
    final changeColor = isUp ? ObrColors.green600 : ObrColors.orange700;

    // Total: the client's own amounts (masked when hidden). Price: market
    // data, always shown.
    final double main;
    final double change;
    final bool mask;
    if (showPrice) {
      main = price;
      change = changePerShare;
      mask = false;
    } else {
      main = price * holding.shares;
      change = changePerShare * holding.shares;
      mask = hidden;
    }

    final figures = Column(
      key: ValueKey(showPrice),
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text(
          '${mask ? hiddenAmount : formatPrice(main)} $currency',
          // 2pt larger than body-lg (16), same 24pt line height.
          style: ObrType.tabular(ObrType.bodyLgSemibold).copyWith(
            fontSize: 18,
            height: 24 / 18,
          ),
        ),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isUp ? Icons.arrow_upward : Icons.arrow_downward,
              size: ObrSize.s16,
              color: changeColor,
            ),
            const SizedBox(width: ObrSpace.s2),
            Text(
              '${mask ? hiddenAmount : formatPrice(change.abs())} '
              '(${percent.abs().toStringAsFixed(2)}%)',
              style: ObrType.tabular(ObrType.bodyMdBook).copyWith(
                color: changeColor,
              ),
            ),
          ],
        ),
      ],
    );

    return FittedBox(
      fit: BoxFit.scaleDown,
      alignment: Alignment.centerRight,
      child: FadeSwitcher(child: figures),
    );
  }
}

class _TradeButtons extends StatelessWidget {
  const _TradeButtons({
    required this.symbol,
    required this.onBuy,
    required this.onSell,
  });

  final String symbol;
  final VoidCallback onBuy;
  final VoidCallback onSell;

  @override
  Widget build(BuildContext context) {
    ButtonStyle style(Color color) => FilledButton.styleFrom(
          backgroundColor: color,
          foregroundColor: ObrColors.gray0,
          minimumSize: const Size(72, ObrSize.s44),
          padding: const EdgeInsets.symmetric(horizontal: ObrSpace.s16),
          textStyle: ObrType.bodyLgSemibold,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(ObrRadius.r12),
          ),
        );

    return FittedBox(
      fit: BoxFit.scaleDown,
      alignment: Alignment.centerRight,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Semantics(
            label: 'Buy $symbol',
            excludeSemantics: true,
            button: true,
            child: FilledButton(
              onPressed: onBuy,
              style: style(ObrColors.green600),
              child: const Text('Buy'),
            ),
          ),
          const SizedBox(width: ObrSpace.s8),
          Semantics(
            label: 'Sell $symbol',
            excludeSemantics: true,
            button: true,
            child: FilledButton(
              onPressed: onSell,
              style: style(ObrColors.orange700),
              child: const Text('Sell'),
            ),
          ),
        ],
      ),
    );
  }
}
