import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';

import '../../data/mock_portfolio.dart';
import '../../state/recent_searches.dart';
import '../../theme/obr_tokens.dart';
import '../../theme/obr_typography.dart';
import '../../util/format.dart';

/// Recent searches as a one-row, horizontally scrolling carousel of
/// outlined pills: the ticker in bold and its live price in a lighter weight
/// ("XEQT  $32.87"), newest first. Prices tick every [tick] (simulated).
/// Tapping a pill calls [onOpen] with that security.
class RecentSearchChips extends StatefulWidget {
  const RecentSearchChips({super.key, required this.onOpen});

  final ValueChanged<Security> onOpen;

  static const Duration tick = Duration(seconds: 2);

  @override
  State<RecentSearchChips> createState() => _RecentSearchChipsState();
}

class _RecentSearchChipsState extends State<RecentSearchChips> {
  final Random _random = Random();
  /// Live prices by symbol; a symbol added later starts at its quote.
  final Map<String, double> _prices = {};
  Timer? _timer;

  double _priceOf(Security security) =>
      _prices.putIfAbsent(security.symbol, () => security.quote.price);

  @override
  void initState() {
    super.initState();
    // Next step: subscribe to streaming quotes for these symbols.
    _timer = Timer.periodic(RecentSearchChips.tick, (_) => _update());
  }

  void _update() {
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

  @override
  Widget build(BuildContext context) {
    final securities = [
      for (final symbol in RecentSearchesScope.of(context).value)
        if (MockSecurities.bySymbol(symbol) case final security?) security,
    ];
    // At most five pills, so build them all (a lazy list would skip the
    // off-screen ones) in one horizontally scrolling row.
    return SizedBox(
      height: ObrSize.s44,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        // Pills scroll out under the page's side padding to the screen edge,
        // like the Market overview cards.
        clipBehavior: Clip.none,
        child: Row(
          children: [
            for (var i = 0; i < securities.length; i++) ...[
              if (i > 0) const SizedBox(width: ObrSpace.s8),
              _Pill(
                key: ValueKey(securities[i].symbol),
                symbol: securities[i].symbol,
                price: _priceOf(securities[i]),
                onTap: () => widget.onOpen(securities[i]),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill({
    super.key,
    required this.symbol,
    required this.price,
    required this.onTap,
  });

  final String symbol;
  final double price;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final priceText = '\$${formatPrice(price)}';
    return Tooltip(
      message: 'Open $symbol',
      child: Semantics(
        button: true,
        label: '$symbol, $priceText',
        excludeSemantics: true,
        child: Material(
          color: ObrColors.gray0,
          shape: const StadiumBorder(
            side: BorderSide(color: ObrColors.gray400),
          ),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: onTap,
            child: ConstrainedBox(
              constraints: const BoxConstraints(minHeight: ObrSize.s44),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: ObrSpace.s16),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      symbol,
                      style: ObrType.bodyLgSemibold.copyWith(
                        color: ObrColors.gray900,
                      ),
                    ),
                    const SizedBox(width: ObrSpace.s8),
                    Text(
                      priceText,
                      style: ObrType.tabular(ObrType.bodyLgBook).copyWith(
                        color: ObrColors.gray600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
