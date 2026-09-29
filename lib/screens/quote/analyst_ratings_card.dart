import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../data/mock_portfolio.dart';
import '../../theme/obr_tokens.dart';
import '../../theme/obr_typography.dart';

// Rating colours follow OBR trade-flow meaning: green = Buy, orange = Sell.
const Color _buyColor = ObrColors.green600;
const Color _holdColor = ObrColors.gray600;
const Color _sellColor = ObrColors.orange700;

/// Donut of buy / hold / sell ratings, the overall consensus and the
/// percentage for each. ETFs, which have no analyst coverage, get a note.
class AnalystRatingsCard extends StatelessWidget {
  const AnalystRatingsCard({super.key, required this.security});

  final Security security;

  @override
  Widget build(BuildContext context) {
    final ratings = MockResearch.ratingsOf(security);
    final decoration = BoxDecoration(
      color: ObrColors.gray100,
      borderRadius: BorderRadius.circular(ObrRadius.r16),
    );

    if (ratings == null) {
      return DecoratedBox(
        decoration: decoration,
        child: Padding(
          padding: const EdgeInsets.all(ObrSpace.s20),
          child: Text(
            security.type == 'ETF'
                ? 'Analyst ratings aren\'t available for ETFs.'
                : 'No analyst ratings are available for ${security.symbol}.',
            style: ObrType.bodyMdBook.copyWith(color: ObrColors.gray700),
          ),
        ),
      );
    }

    final consensus = ratings.consensus;
    final consensusColor = consensus.contains('buy')
        ? _buyColor
        : consensus.contains('sell')
            ? _sellColor
            : ObrColors.gray700;

    return DecoratedBox(
      decoration: decoration,
      child: Padding(
        padding: const EdgeInsets.all(ObrSpace.s20),
        child: MergeSemantics(
          child: Row(
            children: [
              SizedBox.square(
                dimension: 112,
                child: CustomPaint(
                  painter: _DonutPainter(
                    buy: ratings.buy,
                    hold: ratings.hold,
                    sell: ratings.sell,
                  ),
                  // Number of ratings in the centre of the donut.
                  child: Semantics(
                    label: '${ratings.analysts} analyst ratings',
                    excludeSemantics: true,
                    child: Padding(
                      padding: const EdgeInsets.all(_DonutPainter.stroke + 4),
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              '${ratings.analysts}',
                              style: ObrType.tabular(ObrType.headingLg)
                                  .copyWith(color: ObrColors.gray700),
                            ),
                            Text(
                              'ratings',
                              style: ObrType.caption.copyWith(
                                color: ObrColors.gray700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: ObrSpace.s20),
              Expanded(
                child: Column(
                  children: [
                    Text(
                      consensus,
                      textAlign: TextAlign.center,
                      style: ObrType.headingLgSemibold.copyWith(
                        color: consensusColor,
                      ),
                    ),
                    const SizedBox(height: ObrSpace.s4),
                    Text(
                      'Overall analyst consensus (last 3 months).',
                      textAlign: TextAlign.center,
                      style: ObrType.bodyMdBook.copyWith(
                        color: ObrColors.gray700,
                      ),
                    ),
                    const SizedBox(height: ObrSpace.s8),
                    Wrap(
                      alignment: WrapAlignment.center,
                      spacing: ObrSpace.s12,
                      runSpacing: ObrSpace.s4,
                      children: [
                        _Legend(
                          color: _buyColor,
                          label: 'Buy ${ratings.buy}%',
                        ),
                        _Legend(
                          color: _holdColor,
                          label: 'Hold ${ratings.hold}%',
                        ),
                        _Legend(
                          color: _sellColor,
                          label: 'Sell ${ratings.sell}%',
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Legend extends StatelessWidget {
  const _Legend({required this.color, required this.label});

  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: ObrSpace.s4),
        Text(
          label,
          style: ObrType.tabular(ObrType.bodyMdBook).copyWith(
            // Hold text uses gray-700 so it clears 4.5:1 on gray-100.
            color: color == _holdColor ? ObrColors.gray700 : color,
          ),
        ),
      ],
    );
  }
}

class _DonutPainter extends CustomPainter {
  _DonutPainter({required this.buy, required this.hold, required this.sell});

  final int buy;
  final int hold;
  final int sell;

  static const double stroke = 14;
  static const double _gapRadians = 0.04;

  @override
  void paint(Canvas canvas, Size size) {
    final total = buy + hold + sell;
    if (total == 0) return;
    final rect = Rect.fromLTWH(
      stroke / 2,
      stroke / 2,
      size.width - stroke,
      size.height - stroke,
    );
    var start = -math.pi / 2;
    for (final (value, color) in [
      (buy, _buyColor),
      (sell, _sellColor),
      (hold, _holdColor),
    ]) {
      if (value == 0) continue;
      final sweep = value / total * 2 * math.pi;
      canvas.drawArc(
        rect,
        start + _gapRadians / 2,
        (sweep - _gapRadians).clamp(0.0, 2 * math.pi),
        false,
        Paint()
          ..color = color
          ..style = PaintingStyle.stroke
          ..strokeWidth = stroke,
      );
      start += sweep;
    }
  }

  @override
  bool shouldRepaint(_DonutPainter oldDelegate) =>
      oldDelegate.buy != buy ||
      oldDelegate.hold != hold ||
      oldDelegate.sell != sell;
}
