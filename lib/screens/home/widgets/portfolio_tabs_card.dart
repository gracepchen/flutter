import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../widgets/motion_animated_size.dart';
import '../../../data/mock_portfolio.dart';
import '../../../router.dart';
import '../../../theme/obr_tokens.dart';
import '../../../theme/obr_typography.dart';
import '../../../widgets/obr_card.dart';
import '../../../widgets/obr_segmented_control.dart';
import '../../../widgets/pill_toggle.dart';
import '../../../widgets/swipe_reveal_row.dart';
import 'accounts_list.dart';
import 'top_holdings_list.dart';

enum _Tab { accounts, holdings }

/// Accounts and Top Holdings in one card, switched by a segmented control.
/// Under the list sits the USDCAD rate; below the divider, a pill toggle on
/// the left and an "All holdings" link on the right. The toggle switches Accounts between Total and Cash only, and Top
/// Holdings between Total and Price. Each tab remembers its own choice.
class PortfolioTabsCard extends StatefulWidget {
  const PortfolioTabsCard({super.key});

  @override
  State<PortfolioTabsCard> createState() => _PortfolioTabsCardState();
}

class _PortfolioTabsCardState extends State<PortfolioTabsCard> {
  _Tab _tab = _Tab.accounts;
  bool _accountsShowCash = false;
  bool _holdingsShowPrice = false;

  void _select(_Tab tab) {
    if (tab == _tab) return;
    HapticFeedback.selectionClick();
    setState(() => _tab = tab);
  }

  @override
  Widget build(BuildContext context) {
    return ObrCard(
      padding: const EdgeInsets.fromLTRB(
        ObrSpace.s8,
        ObrSpace.s8,
        ObrSpace.s8,
        0,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ObrSegmentedControl(
            labels: const ['My accounts', 'Top holdings'],
            selectedIndex: _tab.index,
            onSelected: (i) => _select(_Tab.values[i]),
          ),
          MotionAnimatedSize(
            duration: ObrDuration.d250,
            curve: ObrEasing.easeInOut,
            alignment: Alignment.topCenter,
            // Switching tabs also resets any open (swiped) row.
            child: _tab == _Tab.accounts
                ? AccountsList(
                    key: const ValueKey('accounts'),
                    showCash: _accountsShowCash,
                  )
                : TopHoldingsList(
                    key: const ValueKey('holdings'),
                    showPrice: _holdingsShowPrice,
                  ),
          ),
          const _RateLine(),
          const Divider(),
          _Footer(
            toggle: _tab == _Tab.accounts
                ? PillToggle(
                    key: const ValueKey('accounts-toggle'),
                    leftLabel: 'Total',
                    rightLabel: 'Cash only',
                    rightSelected: _accountsShowCash,
                    onChanged: (v) => setState(() => _accountsShowCash = v),
                  )
                : PillToggle(
                    key: const ValueKey('holdings-toggle'),
                    leftLabel: 'Total',
                    rightLabel: 'Price',
                    rightSelected: _holdingsShowPrice,
                    onChanged: (v) => setState(() => _holdingsShowPrice = v),
                  ),
          ),
        ],
      ),
    );
  }
}

/// "Last updated Sep 23, 11:59pm ET" on the left, lined up with the rows'
/// names, and "USDCAD=1.40123" on the right. The rate is as of the close of
/// the last business day.
class _RateLine extends StatelessWidget {
  const _RateLine();

  @override
  Widget build(BuildContext context) {
    final asOf = MockMarket.usdToCadAsOf;
    final rate = MockMarket.usdToCad.toStringAsFixed(5);
    final base = ObrType.tabular(ObrType.caption).copyWith(
      color: ObrColors.gray600,
    );
    return Semantics(
      label: 'US dollar to Canadian dollar rate $rate, last updated '
          '${DateFormat.yMMMMd().format(asOf)}',
      excludeSemantics: true,
      child: Padding(
        // Same side insets as the rows above, so the date lines up with the
        // names and the rate with the dollar amounts.
        padding: const EdgeInsets.fromLTRB(
          SwipeRevealRow.contentInset,
          ObrSpace.s4,
          SwipeRevealRow.contentInset,
          ObrSpace.s12,
        ),
        child: Row(
          children: [
            // Expanded (not Flexible) so the date takes the leftover width
            // and the rate is pushed flush right, under the dollar amounts.
            Expanded(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(
                  'Last updated ${DateFormat.MMMd().format(asOf)}, 11:59pm ET',
                  maxLines: 1,
                  style: base.copyWith(fontStyle: FontStyle.italic),
                ),
              ),
            ),
            const SizedBox(width: ObrSpace.s12),
            Text(
              'USDCAD=$rate',
              maxLines: 1,
              style: base.copyWith(
                fontWeight: FontWeight.w600,
                color: ObrColors.gray800,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// The view toggle on the left and a link to all holdings on the right.
class _Footer extends StatelessWidget {
  const _Footer({required this.toggle});

  final Widget toggle;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        ObrSpace.s12,
        ObrSpace.s4,
        ObrSpace.s4,
        ObrSpace.s8,
      ),
      child: Row(
        children: [
          toggle,
          const Spacer(),
          Semantics(
            link: true,
            label: 'All holdings',
            excludeSemantics: true,
            child: InkWell(
              onTap: () => context.push(AppRoutes.holdings),
              borderRadius: BorderRadius.circular(ObrRadius.r8),
              child: ConstrainedBox(
                constraints: const BoxConstraints(minHeight: ObrSize.s44),
                child: Padding(
                  padding: const EdgeInsets.only(left: ObrSpace.s8),
                  // Capped width; shrinks rather than overflow on narrow
                  // phones or at large text sizes.
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 120),
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text('All holdings', style: ObrType.bodyMdBook),
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
            ),
          ),
        ],
      ),
    );
  }
}
