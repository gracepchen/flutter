import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../../../data/mock_portfolio.dart';
import '../../../router.dart';
import '../../../state/balance_visibility.dart';
import '../../../theme/obr_tokens.dart';
import '../../../theme/obr_typography.dart';
import '../../../util/format.dart';
import '../../../util/motion.dart';
import '../../../widgets/range_selector.dart';
import 'portfolio_chart.dart';

/// Total value, change for the selected range, chart and range selector.
/// Not in a card: it sits on the page, and the chart runs edge to edge.
class PortfolioSummaryCard extends StatefulWidget {
  const PortfolioSummaryCard({super.key});

  /// How far the chart extends past each side of the content column. Matches
  /// Home's horizontal page padding.
  static const double bleed = ObrSpace.s20;

  @override
  State<PortfolioSummaryCard> createState() => _PortfolioSummaryCardState();
}

class _PortfolioSummaryCardState extends State<PortfolioSummaryCard> {
  ChartRange _range = ChartRange.oneDay;

  void _select(ChartRange range) {
    if (range == _range) return;
    HapticFeedback.selectionClick();
    setState(() => _range = range);
  }

  @override
  Widget build(BuildContext context) {
    final series = MockPortfolio.series(_range);
    final isUp = series.change >= 0;
    // OBR: green = positive. Declines use orange (caution) rather than the
    // brand red, which is reserved for primary actions.
    final changeColor = isUp ? ObrColors.green600 : ObrColors.orange700;
    final changeText = '${formatSignedCad(series.change)} '
        '(${formatSignedPercent(series.changePercent)}) ${_range.changeSuffix}';
    final spokenChange = '${isUp ? 'Up' : 'Down'} '
        '${formatCad(series.change.abs())}, '
        '${series.changePercent.abs().toStringAsFixed(2)} percent, '
        '${_range.changeSuffix}';

    final hidden = BalanceVisibility.hiddenOf(context);
    final shownChange = hidden
        ? '$hiddenAmount (${formatSignedPercent(series.changePercent)}) '
            '${_range.changeSuffix}'
        : changeText;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(child: _TotalValue(total: MockPortfolio.totalValue)),
            IconButton(
              tooltip: 'View performance',
              onPressed: () => context.push(AppRoutes.performance),
              icon: const Icon(Icons.chevron_right),
              color: ObrColors.gray700,
              iconSize: ObrSize.s28,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints.tightFor(
                width: ObrSize.s44,
                height: ObrSize.s44,
              ),
            ),
          ],
        ),
        Semantics(
          label: hidden ? 'Change hidden' : spokenChange,
          liveRegion: true,
          child: ExcludeSemantics(
            child: Row(
              children: [
                _ChangeTriangle(isUp: isUp, color: changeColor),
                const SizedBox(width: ObrSpace.s8),
                Flexible(
                  child: AnimatedSwitcher(
                    duration: motionDuration(context, ObrDuration.d200),
                    child: Text(
                      shownChange,
                      key: ValueKey((_range, hidden)),
                      style: ObrType.tabular(ObrType.bodyLgSemibold)
                          .copyWith(color: changeColor),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: ObrSpace.s16),
        // Full-bleed: the chart runs past the page's side padding to the
        // screen edges.
        LayoutBuilder(
          builder: (context, constraints) => SizedBox(
            // 50% taller than the original 84.
            height: 126,
            child: OverflowBox(
              minWidth: constraints.maxWidth + PortfolioSummaryCard.bleed * 2,
              maxWidth: constraints.maxWidth + PortfolioSummaryCard.bleed * 2,
              child: PortfolioChart(
                // New key per range replays the draw-on animation.
                key: ValueKey(_range),
                points: series.points,
                // Same neutral grays as the stock details chart.
                lineColor: ObrColors.gray700,
                fillColor: ObrColors.gray400,
                semanticLabel: 'Portfolio value chart, '
                    '${_range.spokenLabel}. $spokenChange.',
              ),
            ),
          ),
        ),
        const SizedBox(height: ObrSpace.s8),
        RangeSelector(
          labels: [for (final r in ChartRange.values) r.label],
          spokenLabels: [for (final r in ChartRange.values) r.spokenLabel],
          selectedIndex: _range.index,
          onSelected: (i) => _select(ChartRange.values[i]),
        ),
      ],
    );
  }
}

class _ChangeTriangle extends StatelessWidget {
  const _ChangeTriangle({required this.isUp, required this.color});

  final bool isUp;
  final Color color;

  @override
  Widget build(BuildContext context) => CustomPaint(
        size: const Size(14, 12),
        painter: _TrianglePainter(isUp: isUp, color: color),
      );
}

class _TrianglePainter extends CustomPainter {
  _TrianglePainter({required this.isUp, required this.color});

  final bool isUp;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final path = Path();
    if (isUp) {
      path
        ..moveTo(size.width / 2, 0)
        ..lineTo(size.width, size.height)
        ..lineTo(0, size.height);
    } else {
      path
        ..moveTo(0, 0)
        ..lineTo(size.width, 0)
        ..lineTo(size.width / 2, size.height);
    }
    path.close();
    canvas.drawPath(path, Paint()..color = color);
  }

  @override
  bool shouldRepaint(_TrianglePainter oldDelegate) =>
      oldDelegate.isUp != isUp || oldDelegate.color != color;
}

/// Total value with an eye toggle that hides the digits ($••••••). The
/// choice is shared app-wide via [BalanceVisibility], so it persists when
/// the person leaves Home and comes back.
class _TotalValue extends StatelessWidget {
  const _TotalValue({required this.total});

  final double total;

  @override
  Widget build(BuildContext context) {
    final hiddenNotifier = BalanceVisibility.of(context);
    final hidden = hiddenNotifier.value;
    final style =
        ObrType.tabular(ObrType.displayLg).copyWith(color: ObrColors.gray900);

    return Row(
      children: [
        Flexible(
          child: Semantics(
            label: hidden ? 'Total portfolio value hidden' : 'Total portfolio value',
            excludeSemantics: hidden,
            child: Text(
              hidden ? r'$••••••' : formatCad(total),
              style: style,
            ),
          ),
        ),
        const SizedBox(width: ObrSpace.s4),
        IconButton(
          tooltip: hidden ? 'Show balance' : 'Hide balance',
          onPressed: () {
            HapticFeedback.selectionClick();
            hiddenNotifier.value = !hidden;
          },
          icon: Icon(
            hidden ? Icons.visibility_off_outlined : Icons.visibility_outlined,
          ),
          color: ObrColors.gray600,
        ),
      ],
    );
  }
}
