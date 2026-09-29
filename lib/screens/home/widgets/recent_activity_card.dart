import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../data/mock_portfolio.dart';
import '../../../router.dart';
import '../../../theme/obr_tokens.dart';
import '../../../theme/obr_typography.dart';
import '../../../util/format.dart';
import '../../../widgets/obr_card.dart';
import '../../../widgets/fade_switcher.dart';
import '../../../widgets/motion_animated_size.dart';
import '../../../widgets/pill_toggle.dart';

/// Recent activity with an All / Trades toggle at the bottom left (as on the
/// accounts/holdings card) and "See all" at the bottom right. Trades shows
/// the three most recent trades.
class RecentActivityCard extends StatefulWidget {
  const RecentActivityCard({super.key});

  @override
  State<RecentActivityCard> createState() => _RecentActivityCardState();
}

class _RecentActivityCardState extends State<RecentActivityCard> {
  bool _tradesOnly = false;

  @override
  Widget build(BuildContext context) {
    final items = _tradesOnly
        ? MockPortfolio.recentTrades.take(3).toList()
        : MockPortfolio.recentActivity;
    return ObrCard(
      padding: const EdgeInsets.fromLTRB(
        ObrSpace.s24,
        ObrSpace.s12,
        ObrSpace.s12,
        0,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.only(right: ObrSpace.s12),
            child: Semantics(
              header: true,
              child: Text('Recent activity', style: ObrType.headingMdSemibold),
            ),
          ),
          const SizedBox(height: ObrSpace.s12),
          Padding(
            padding: const EdgeInsets.only(right: ObrSpace.s12),
            child: MotionAnimatedSize(
              child: FadeSwitcher(
                child: Column(
                  key: ValueKey(_tradesOnly),
                  children: [
                    for (final item in items) ...[
                      const Divider(),
                      _ActivityRow(item: item),
                    ],
                  ],
                ),
              ),
            ),
          ),
          const Divider(),
          Padding(
            padding: const EdgeInsets.only(
              top: ObrSpace.s4,
              bottom: ObrSpace.s8,
            ),
            child: Row(
              children: [
                PillToggle(
                  leftLabel: 'All',
                  rightLabel: 'Trades',
                  rightSelected: _tradesOnly,
                  onChanged: (v) => setState(() => _tradesOnly = v),
                ),
                const Spacer(),
                Semantics(
                  link: true,
                  label: 'See all activity',
                  excludeSemantics: true,
                  child: InkWell(
                    onTap: () => context.push(AppRoutes.activity),
                    borderRadius: BorderRadius.circular(ObrRadius.r8),
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(minHeight: ObrSize.s44),
                      child: Padding(
                        padding: const EdgeInsets.only(left: ObrSpace.s8),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text('See all', style: ObrType.bodyMdBook),
                            const Icon(
                              Icons.chevron_right,
                              size: ObrSize.s20,
                              color: ObrColors.gray700,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ActivityRow extends StatelessWidget {
  const _ActivityRow({required this.item});

  final ActivityItem item;

  IconData get _icon => switch (item.kind) {
        ActivityKind.deposit => Icons.add,
        ActivityKind.buy || ActivityKind.sell =>
          Icons.candlestick_chart_outlined,
        ActivityKind.dividend => Icons.payments_outlined,
        ActivityKind.transfer => Icons.swap_horiz,
      };

  @override
  Widget build(BuildContext context) {
    final amountColor = item.pending
        ? ObrColors.gray600
        : item.amount >= 0
            ? ObrColors.green600
            : ObrColors.gray800;

    return MergeSemantics(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: ObrSpace.s12),
        child: Row(
          children: [
            Container(
              width: ObrSize.s40,
              height: ObrSize.s40,
              decoration: const BoxDecoration(
                color: ObrColors.gray100,
                shape: BoxShape.circle,
              ),
              child: Icon(_icon, color: ObrColors.gray700, size: ObrSize.s20),
            ),
            const SizedBox(width: ObrSpace.s12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Wrap(
                    spacing: ObrSpace.s8,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Text(item.title, style: ObrType.bodyLg),
                      if (item.pending) const _PendingPill(),
                    ],
                  ),
                  const SizedBox(height: ObrSpace.s2),
                  Text(
                    item.detail,
                    style: ObrType.bodyMdBook.copyWith(
                      color: ObrColors.gray600,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: ObrSpace.s12),
            Text(
              formatSignedCad(item.amount),
              style: ObrType.tabular(ObrType.bodyLg).copyWith(
                color: amountColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PendingPill extends StatelessWidget {
  const _PendingPill();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: ObrColors.blue100,
        borderRadius: BorderRadius.circular(ObrRadius.full),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: ObrSpace.s8,
          vertical: ObrSpace.s2,
        ),
        child: Text(
          'Pending',
          style: ObrType.captionSemibold.copyWith(color: ObrColors.blue800),
        ),
      ),
    );
  }
}
