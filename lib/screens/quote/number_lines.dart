import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../data/mock_portfolio.dart';
import '../../theme/obr_tokens.dart';
import '../../theme/obr_typography.dart';
import '../../util/format.dart';

const double _labelWidth = 112;
const double _barHeight = 28;

/// The day and 52-week ranges drawn as number lines (a dot marks the last
/// price and a diamond marks the open), then volume against its 3-month
/// average at the bottom.
class QuoteNumberLines extends StatelessWidget {
  const QuoteNumberLines({super.key, required this.security});

  final Security security;

  @override
  Widget build(BuildContext context) {
    final q = security.quote;
    final f = MockResearch.fundamentalsOf(security);
    final compact = NumberFormat.compact();
    final volumePercent = q.volume / f.averageVolume3m * 100;

    // Bars have fixed heights, so cap text scaling for this block only.
    return MediaQuery.withClampedTextScaling(
      maxScaleFactor: 1.3,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.only(left: _labelWidth + ObrSpace.s8),
            child: ExcludeSemantics(
              child: Text.rich(
                TextSpan(
                  children: [
                    const TextSpan(text: 'Open: '),
                    TextSpan(
                      text: formatPrice(q.open),
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        color: ObrColors.gray800,
                      ),
                    ),
                  ],
                ),
                textAlign: TextAlign.center,
                style: ObrType.tabular(ObrType.bodyMdBook).copyWith(
                  color: ObrColors.gray600,
                ),
              ),
            ),
          ),
          const SizedBox(height: ObrSpace.s4),
          _LineRow(
            label: const Text('Day range', textAlign: TextAlign.end),
            semanticLabel: 'Day range ${formatPrice(q.dayLow)} to '
                '${formatPrice(q.dayHigh)}. Open ${formatPrice(q.open)}. '
                'Last ${formatPrice(q.price)}.',
            bar: _RangeBar(
              low: q.dayLow,
              high: q.dayHigh,
              current: q.price,
              open: q.open,
            ),
          ),
          const SizedBox(height: ObrSpace.s12),
          _LineRow(
            label: const Text('52 week range', textAlign: TextAlign.end),
            semanticLabel: '52 week range ${formatPrice(q.yearLow)} to '
                '${formatPrice(q.yearHigh)}. Last ${formatPrice(q.price)}.',
            bar: _RangeBar(low: q.yearLow, high: q.yearHigh, current: q.price),
          ),
          const SizedBox(height: ObrSpace.s12),
          _LineRow(
            label: Text.rich(
              TextSpan(
                children: [
                  const TextSpan(text: 'Volume: '),
                  TextSpan(
                    text: compact.format(q.volume),
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      color: ObrColors.gray800,
                    ),
                  ),
                ],
              ),
              textAlign: TextAlign.end,
            ),
            semanticLabel: 'Volume ${compact.format(q.volume)}, '
                '${volumePercent.round()} percent of the 3 month average of '
                '${compact.format(f.averageVolume3m)}',
            bar: _VolumeBar(
              fraction: (volumePercent / 100).clamp(0.0, 1.0),
              percent: volumePercent.round(),
              average: compact.format(f.averageVolume3m),
            ),
          ),
        ],
      ),
    );
  }
}

class _LineRow extends StatelessWidget {
  const _LineRow({
    required this.label,
    required this.bar,
    required this.semanticLabel,
  });

  final Widget label;
  final Widget bar;
  final String semanticLabel;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: semanticLabel,
      excludeSemantics: true,
      child: Row(
        children: [
          SizedBox(
            width: _labelWidth,
            child: DefaultTextStyle.merge(
              style: ObrType.tabular(ObrType.bodyLgBook).copyWith(
                color: ObrColors.gray600,
              ),
              child: label,
            ),
          ),
          const SizedBox(width: ObrSpace.s8),
          Expanded(child: bar),
        ],
      ),
    );
  }
}

BoxDecoration get _barDecoration => BoxDecoration(
      color: ObrColors.gray50,
      borderRadius: BorderRadius.circular(ObrRadius.r4),
      border: Border.all(color: ObrColors.gray200),
    );

/// Filled to today's volume as a share of the 3-month average.
class _VolumeBar extends StatelessWidget {
  const _VolumeBar({
    required this.fraction,
    required this.percent,
    required this.average,
  });

  final double fraction;
  final int percent;
  final String average;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: _barHeight,
      decoration: _barDecoration,
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          FractionallySizedBox(
            widthFactor: fraction,
            heightFactor: 1,
            child: const ColoredBox(color: ObrColors.gray200),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: ObrSpace.s4),
            child: Align(
              alignment: Alignment.centerLeft,
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text.rich(
                  TextSpan(
                    children: [
                      TextSpan(
                        text: '$percent%',
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      TextSpan(text: ' vs 3 mon avg ($average)'),
                    ],
                  ),
                  maxLines: 1,
                  style: ObrType.tabular(ObrType.bodyMdBook).copyWith(
                    color: ObrColors.gray700,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Low and high at the ends; markers between them.
class _RangeBar extends StatelessWidget {
  const _RangeBar({
    required this.low,
    required this.high,
    required this.current,
    this.open,
  });

  final double low;
  final double high;
  final double current;
  final double? open;

  double _fraction(double value) =>
      high == low ? 0.5 : ((value - low) / (high - low)).clamp(0.0, 1.0);

  @override
  Widget build(BuildContext context) {
    final endStyle = ObrType.tabular(ObrType.labelMd).copyWith(
      fontWeight: FontWeight.w600,
      color: ObrColors.gray800,
    );
    return Container(
      height: _barHeight,
      decoration: _barDecoration,
      padding: const EdgeInsets.symmetric(horizontal: ObrSpace.s4),
      child: Row(
        children: [
          Text(formatPrice(low), style: endStyle),
          const SizedBox(width: ObrSpace.s8),
          Expanded(
            child: CustomPaint(
              size: const Size.fromHeight(_barHeight),
              painter: _MarkerPainter(
                current: _fraction(current),
                open: open == null ? null : _fraction(open!),
              ),
            ),
          ),
          const SizedBox(width: ObrSpace.s8),
          Text(formatPrice(high), style: endStyle),
        ],
      ),
    );
  }
}

class _MarkerPainter extends CustomPainter {
  _MarkerPainter({required this.current, this.open});

  final double current;
  final double? open;

  static const double _dotRadius = 5;
  static const double _diamond = 9;

  @override
  void paint(Canvas canvas, Size size) {
    final midY = size.height / 2;
    final divider = Paint()
      ..color = ObrColors.gray300
      ..strokeWidth = 1;
    // Dividers at the ends and the midpoint of the range.
    for (final t in const [0.0, 0.5, 1.0]) {
      final x = t * size.width;
      canvas.drawLine(Offset(x, 4), Offset(x, size.height - 4), divider);
    }

    double xFor(double t) =>
        _dotRadius + t * (size.width - _dotRadius * 2).clamp(0.0, double.infinity);

    if (open != null) {
      final center = Offset(xFor(open!), midY);
      final path = Path()
        ..moveTo(center.dx, center.dy - _diamond / 2)
        ..lineTo(center.dx + _diamond / 2, center.dy)
        ..lineTo(center.dx, center.dy + _diamond / 2)
        ..lineTo(center.dx - _diamond / 2, center.dy)
        ..close();
      canvas.drawPath(path, Paint()..color = ObrColors.gray500);
    }

    canvas.drawCircle(
      Offset(xFor(current), midY),
      _dotRadius,
      Paint()..color = ObrColors.gray800,
    );
  }

  @override
  bool shouldRepaint(_MarkerPainter oldDelegate) =>
      oldDelegate.current != current || oldDelegate.open != open;
}
