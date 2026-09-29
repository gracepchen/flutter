import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../data/mock_portfolio.dart';
import '../../../router.dart';
import '../../../state/balance_visibility.dart';
import '../../../theme/obr_tokens.dart';
import '../../../theme/obr_typography.dart';
import '../../../util/format.dart';
import '../../../util/motion.dart';
import '../../../widgets/fade_switcher.dart';
import '../../../widgets/obr_card.dart';
import '../../../widgets/pill_toggle.dart';

/// "Financial progress": the lifetime total and a full-width bar per year,
/// with an Invested / Dividends toggle at the bottom left (as on the
/// accounts/holdings card) and one link at the bottom right.
///
/// - The ⊕ at the top right opens a sheet: One-time transfer or Recurring
///   deposit, both leading to Add funds.
/// - Invested: money put in each year; this year (to date) is highlighted.
///   Link: Contributions.
/// - Dividends: past years, this year to date (highlighted) and this year's
///   projection (dashed outline). Link: Reinvest.
/// - Amounts are masked when balances are hidden.
class FinancialProgressCard extends StatefulWidget {
  const FinancialProgressCard({super.key});

  @override
  State<FinancialProgressCard> createState() => _FinancialProgressCardState();
}

enum _BarKind { past, current, projected }

class _Bar {
  const _Bar(this.label, this.value, this.kind, {this.subLabel});

  final String label;
  final String? subLabel;
  final double value;
  final _BarKind kind;
}

class _FinancialProgressCardState extends State<FinancialProgressCard> {
  bool _dividends = false;

  void _notBuilt(String label) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(content: Text('$label is not built yet in this prototype.')),
      );
  }

  @override
  Widget build(BuildContext context) {
    final hidden = BalanceVisibility.hiddenOf(context);

    final List<_Bar> bars;
    final double total;
    if (_dividends) {
      final past = MockPortfolio.dividendsByYear;
      bars = [
        for (final (year, v) in past) _Bar('$year', v, _BarKind.past),
        _Bar(
          '${DateTime.now().year}',
          MockPortfolio.dividendsYearToDate,
          _BarKind.current,
          subLabel: '(YTD)',
        ),
        _Bar(
          '${DateTime.now().year}',
          MockPortfolio.dividendsProjectedThisYear,
          _BarKind.projected,
          subLabel: '(projected)',
        ),
      ];
      // Earned so far: past years plus this year to date.
      total = past.fold<double>(0, (sum, e) => sum + e.$2) +
          MockPortfolio.dividendsYearToDate;
    } else {
      final years = MockPortfolio.investedByYear;
      bars = [
        for (var i = 0; i < years.length; i++)
          _Bar(
            '${years[i].$1}',
            years[i].$2,
            i == years.length - 1 ? _BarKind.current : _BarKind.past,
          ),
      ];
      total = years.fold<double>(0, (sum, e) => sum + e.$2);
    }

    final link = _dividends
        ? _ActionLink(
            key: const ValueKey('reinvest'),
            icon: Icons.currency_exchange,
            label: 'Reinvest',
            onTap: () => _notBuilt('Reinvest dividends'),
          )
        : _ActionLink(
            key: const ValueKey('contributions'),
            icon: Icons.bar_chart,
            label: 'Contributions',
            onTap: () => context.push(AppRoutes.contributions),
          );

    return ObrCard(
      padding: const EdgeInsets.fromLTRB(
        ObrSpace.s20,
        ObrSpace.s8,
        ObrSpace.s8,
        ObrSpace.s4,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Semantics(
                  header: true,
                  child: Text(
                    'Financial progress',
                    style: ObrType.headingSmSemibold,
                  ),
                ),
              ),
              IconButton(
                tooltip: 'Add money',
                onPressed: () => showAddMoneySheet(context),
                icon: const Icon(Icons.add_circle_outline),
                color: ObrColors.brand700,
                iconSize: ObrSize.s28,
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.only(right: ObrSpace.s12),
            child: FadeSwitcher(
              child: KeyedSubtree(
                key: ValueKey((_dividends, hidden)),
                child: SizedBox(
                  width: double.infinity,
                  child: _TotalLine(
                    verb: _dividends ? 'earned' : 'invested',
                    total: total,
                    hidden: hidden,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: ObrSpace.s20),
          Padding(
            padding: const EdgeInsets.only(right: ObrSpace.s12),
            child: _BarChart(
              // New key per mode replays the grow-in.
              key: ValueKey(_dividends),
              bars: bars,
              hidden: hidden,
              what: _dividends ? 'Dividends' : 'Amount invested',
            ),
          ),
          const SizedBox(height: ObrSpace.s12),
          const Divider(height: 1),
          Row(
            children: [
              PillToggle(
                leftLabel: 'Invested',
                rightLabel: 'Dividends',
                rightSelected: _dividends,
                segmentWidth: 84,
                onChanged: (v) => setState(() => _dividends = v),
              ),
              const SizedBox(width: ObrSpace.s8),
              Expanded(
                child: Align(
                  alignment: Alignment.centerRight,
                  child: FadeSwitcher(child: link),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// ⊕ on Financial progress: One-time transfer or Recurring deposit, both
/// leading to Add funds. Dark scrim keeps focus on the sheet.
Future<void> showAddMoneySheet(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    barrierColor: Colors.black.withValues(alpha: 0.6),
    backgroundColor: ObrColors.gray0,
    showDragHandle: true,
    useSafeArea: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(ObrRadius.r24)),
    ),
    builder: (sheetContext) {
      void go(String type) {
        Navigator.of(sheetContext).pop();
        context.push(
          Uri(path: AppRoutes.add, queryParameters: {'type': type}).toString(),
        );
      }

      return SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            ObrSpace.s8,
            0,
            ObrSpace.s8,
            ObrSpace.s16,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  ObrSpace.s16,
                  0,
                  ObrSpace.s16,
                  ObrSpace.s8,
                ),
                child: Semantics(
                  header: true,
                  child: Text('Add money', style: ObrType.headingSmSemibold),
                ),
              ),
              _SheetLink(
                icon: Icons.swap_horiz,
                label: 'One-time transfer',
                onTap: () => go('One-time transfer'),
              ),
              _SheetLink(
                icon: Icons.event_repeat,
                label: 'Recurring deposit',
                onTap: () => go('Recurring deposit'),
              ),
            ],
          ),
        ),
      );
    },
  );
}

class _SheetLink extends StatelessWidget {
  const _SheetLink({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      minTileHeight: ObrSize.s56,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(ObrRadius.r12),
      ),
      leading: Icon(icon, color: ObrColors.brand600),
      title: Text(
        label,
        style: ObrType.bodyLgSemibold.copyWith(color: ObrColors.gray800),
      ),
      trailing: const Icon(Icons.chevron_right, color: ObrColors.gray500),
    );
  }
}

/// "You've invested 38,170.04 CAD in all. Nice job!"
class _TotalLine extends StatelessWidget {
  const _TotalLine({
    required this.verb,
    required this.total,
    required this.hidden,
  });

  final String verb;
  final double total;
  final bool hidden;

  @override
  Widget build(BuildContext context) {
    final base = ObrType.bodyLgBook.copyWith(color: ObrColors.gray700);
    return Text.rich(
      TextSpan(
        children: [
          TextSpan(text: "You've $verb "),
          TextSpan(
            text: hidden ? hiddenAmount : formatPrice(total),
            style: ObrType.tabular(ObrType.headingMdSemibold).copyWith(
              color: ObrColors.green600,
            ),
          ),
          TextSpan(
            text: ' CAD',
            style: base.copyWith(color: ObrColors.green600),
          ),
          const TextSpan(text: ' in all. Nice job!'),
        ],
      ),
      style: base,
    );
  }
}

class _BarChart extends StatelessWidget {
  const _BarChart({
    super.key,
    required this.bars,
    required this.hidden,
    required this.what,
  });

  final List<_Bar> bars;
  final bool hidden;
  final String what;

  static const double _plotHeight = 128;

  @override
  Widget build(BuildContext context) {
    final max = bars.fold<double>(0, (m, b) => b.value > m ? b.value : m);
    final duration = motionDuration(context, ObrDuration.d600);
    final spoken = hidden
        ? '$what by year, amounts hidden'
        : '$what by year: ${[
            for (final b in bars)
              '${b.label}${b.subLabel == null ? '' : ' ${b.subLabel}'} '
                  '${formatPrice(b.value)} dollars',
          ].join(', ')}';

    // Bars have fixed heights; cap text scaling so value labels fit above.
    return MediaQuery.withClampedTextScaling(
      maxScaleFactor: 1.3,
      child: Semantics(
      label: spoken,
      excludeSemantics: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Plot area with left and bottom axis lines.
          Container(
            height: _plotHeight + 36,
            decoration: const BoxDecoration(
              border: Border(
                left: BorderSide(color: ObrColors.gray400),
                bottom: BorderSide(color: ObrColors.gray400),
              ),
            ),
            padding: const EdgeInsets.symmetric(horizontal: ObrSpace.s4),
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: duration == Duration.zero ? 1 : 0, end: 1),
              duration: duration,
              curve: ObrEasing.easeOut,
              builder: (context, progress, _) => Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  for (final bar in bars)
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: ObrSpace.s4,
                        ),
                        child: _BarColumn(
                          bar: bar,
                          height: max == 0
                              ? 0
                              : bar.value / max * _plotHeight * progress,
                          hidden: hidden,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: ObrSpace.s4),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (final bar in bars)
                Expanded(
                  child: Column(
                    children: [
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          bar.label,
                          style: ObrType.bodyMdBook.copyWith(
                            color: ObrColors.gray700,
                          ),
                        ),
                      ),
                      if (bar.subLabel != null)
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            bar.subLabel!,
                            style: ObrType.caption.copyWith(
                              color: ObrColors.gray700,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
            ],
          ),
        ],
      ),
      ),
    );
  }
}

class _BarColumn extends StatelessWidget {
  const _BarColumn({
    required this.bar,
    required this.height,
    required this.hidden,
  });

  final _Bar bar;
  final double height;
  final bool hidden;

  @override
  Widget build(BuildContext context) {
    final (fill, labelColor) = switch (bar.kind) {
      _BarKind.past => (ObrColors.gray300, ObrColors.gray800),
      _BarKind.current => (ObrColors.green100, ObrColors.green600),
      _BarKind.projected => (ObrColors.gray100, ObrColors.gray600),
    };
    final box = SizedBox(height: height, width: double.infinity);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            hidden ? '••••' : formatPrice(bar.value),
            maxLines: 1,
            style: ObrType.tabular(ObrType.labelMd).copyWith(
              color: labelColor,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        const SizedBox(height: ObrSpace.s4),
        bar.kind == _BarKind.projected
            ? CustomPaint(
                foregroundPainter: const _DashedRectPainter(
                  color: ObrColors.gray500,
                ),
                child: ColoredBox(color: fill, child: box),
              )
            : ColoredBox(color: fill, child: box),
      ],
    );
  }
}

class _DashedRectPainter extends CustomPainter {
  const _DashedRectPainter({required this.color});

  final Color color;

  static const double _dash = 3;
  static const double _gap = 3;

  @override
  void paint(Canvas canvas, Size size) {
    final path = Path()..addRect((Offset.zero & size).deflate(0.5));
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    for (final metric in path.computeMetrics()) {
      for (var d = 0.0; d < metric.length; d += _dash + _gap) {
        canvas.drawPath(metric.extractPath(d, d + _dash), paint);
      }
    }
  }

  @override
  bool shouldRepaint(_DashedRectPainter oldDelegate) =>
      oldDelegate.color != color;
}

/// Icon, label and ">" chevron, like "Add funds >".
class _ActionLink extends StatelessWidget {
  const _ActionLink({
    super.key,
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      link: true,
      label: label,
      excludeSemantics: true,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(ObrRadius.r8),
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: ObrSize.s52),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: ObrColors.gray700, size: ObrSize.s20),
              const SizedBox(width: ObrSpace.s8),
              Flexible(
                child: Text(
                  label,
                  style: ObrType.bodyLgBook.copyWith(
                    color: ObrColors.gray800,
                  ),
                ),
              ),
              const Icon(
                Icons.chevron_right,
                size: ObrSize.s20,
                color: ObrColors.gray700,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
