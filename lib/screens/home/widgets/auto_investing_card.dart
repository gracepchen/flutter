import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../theme/obr_tokens.dart';
import '../../../theme/obr_typography.dart';

/// "Make investing stress-free": a swipeable carousel of feature cards
/// (Auto-deposit, Reinvest dividends, Auto invest) plus an educational
/// article (What's an FHSA?).
///
/// Cards snap one at a time, and the next card peeks in from the right so
/// it's clear there's more. None are built yet; each shows a short message.
class AutoInvestingCard extends StatefulWidget {
  const AutoInvestingCard({super.key});

  @override
  State<AutoInvestingCard> createState() => _AutoInvestingCardState();
}

class _Promo {
  const _Promo(this.icon, this.title, this.description, {this.isArticle = false});

  final IconData icon;
  final String title;
  final String description;

  /// Educational content rather than a feature.
  final bool isArticle;
}

class _AutoInvestingCardState extends State<AutoInvestingCard> {
  static const List<_Promo> _promos = [
    _Promo(
      Icons.payments_outlined,
      'Auto-deposit',
      'Pay yourself first, every Monday.',
    ),
    _Promo(
      Icons.bar_chart,
      'Reinvest dividends',
      'Put your dividends back to work, ASAP.',
    ),
    _Promo(
      Icons.lightbulb_outline,
      "What's an FHSA?",
      'Break into the housing market, tax-free.',
      isArticle: true,
    ),
    _Promo(
      Icons.currency_exchange,
      'Auto invest',
      'Build your portfolio steadily over time.',
    ),
  ];

  // Each card takes ~86% of the width so the next one peeks in.
  final PageController _controller = PageController(viewportFraction: 0.86);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Grow with the system text size so titles and descriptions aren't cut.
    final height = math.max(
      112.0,
      MediaQuery.textScalerOf(context).scale(1) * 112,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Semantics(
          header: true,
          child: Text(
            'Make investing stress-free',
            style: ObrType.headingMdSemibold,
          ),
        ),
        const SizedBox(height: ObrSpace.s12),
        SizedBox(
          height: height,
          child: PageView.builder(
            controller: _controller,
            padEnds: false,
            clipBehavior: Clip.none,
            itemCount: _promos.length,
            itemBuilder: (context, index) => Padding(
              padding: const EdgeInsets.only(right: ObrSpace.s12),
              child: _PromoCard(
                promo: _promos[index],
                position: '${index + 1} of ${_promos.length}',
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _PromoCard extends StatelessWidget {
  const _PromoCard({required this.promo, required this.position});

  final _Promo promo;

  /// "2 of 4", read by screen readers.
  final String position;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(ObrRadius.r16);
    return Semantics(
      button: true,
      label: '${promo.isArticle ? 'Article: ' : ''}${promo.title}. '
          '${promo.description} $position',
      excludeSemantics: true,
      child: Material(
        color: ObrColors.gray0,
        shape: RoundedRectangleBorder(
          borderRadius: radius,
          side: const BorderSide(color: ObrColors.gray200),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () => ScaffoldMessenger.of(context)
            ..hideCurrentSnackBar()
            ..showSnackBar(
              SnackBar(
                content: Text(
                  '${promo.title} is not built yet in this prototype.',
                ),
              ),
            ),
          child: Padding(
            padding: const EdgeInsets.all(ObrSpace.s16),
            child: Row(
              children: [
                Container(
                  width: ObrSize.s64,
                  height: ObrSize.s64,
                  decoration: const BoxDecoration(
                    color: ObrColors.gray100,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    promo.icon,
                    color: ObrColors.gray700,
                    size: ObrSize.s28,
                  ),
                ),
                const SizedBox(width: ObrSpace.s16),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        promo.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: ObrType.headingXs,
                      ),
                      const SizedBox(height: ObrSpace.s8),
                      Text(
                        promo.description,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: ObrType.bodyMdBook.copyWith(
                          color: ObrColors.gray600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
