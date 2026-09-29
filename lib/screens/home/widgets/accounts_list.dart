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

/// Each account with its type and number, then either its total value with
/// today's change or, with [showCash], its cash in CAD and USD.
///
/// Tapping a row opens Accounts. Swiping a row left keeps the type and number
/// and slides in Manage, Transfer and Trade (also on long press).
class AccountsList extends StatefulWidget {
  const AccountsList({super.key, this.showCash = false});

  /// Set by the card's Total / Cash only toggle.
  final bool showCash;

  @override
  State<AccountsList> createState() => _AccountsListState();
}

class _AccountsListState extends State<AccountsList> {
  String? _openAccount;

  void _setOpen(String? name) {
    if (name == _openAccount) return;
    if (name != null) HapticFeedback.lightImpact();
    setState(() => _openAccount = name);
  }

  void _go(String path, Account account) {
    _setOpen(null);
    context.push(
      Uri(path: path, queryParameters: {'account': account.name}).toString(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final account in MockPortfolio.accounts)
          SwipeRevealRow(
            isOpen: account.name == _openAccount,
            onOpenChanged: (open) => _setOpen(open ? account.name : null),
            // Opens Holdings with this account's pill selected.
            onTap: () => _go(AppRoutes.holdings, account),
            minLeadingWidth: 84,
            semanticActions: {
              'Manage ${account.name}': () =>
                  _go(AppRoutes.accountSettings, account),
              'Transfer from ${account.name}': () =>
                  _go(AppRoutes.transfer, account),
              'Trade in ${account.name}': () => _go(AppRoutes.trade, account),
            },
            leading: _AccountName(account: account),
            details: _AccountFigures(
              account: account,
              showCash: widget.showCash,
            ),
            actions: _AccountActions(
              account: account,
              onManage: () => _go(AppRoutes.accountSettings, account),
              onTransfer: () => _go(AppRoutes.transfer, account),
              onTrade: () => _go(AppRoutes.trade, account),
            ),
          ),
      ],
    );
  }
}

class _AccountName extends StatelessWidget {
  const _AccountName({required this.account});

  final Account account;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Long types such as "Non-Registered" shrink a little rather than
        // truncate on narrow phones.
        FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerLeft,
          child: Text(account.name, style: ObrType.bodyLgSemibold),
        ),
        Text(
          account.number,
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

class _AccountFigures extends StatelessWidget {
  const _AccountFigures({required this.account, required this.showCash});

  final Account account;
  final bool showCash;

  @override
  Widget build(BuildContext context) {
    final isUp = account.changePercent >= 0;
    // OBR: green for gains, orange (caution) for declines.
    final changeColor = isUp ? ObrColors.green600 : ObrColors.orange700;
    final percent = account.changePercent.abs();
    final hidden = BalanceVisibility.hiddenOf(context);

    final figures = showCash
        ? Column(
            key: const ValueKey('cash'),
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              _CashAmount(amount: account.cashCad, currency: 'CAD'),
              _CashAmount(amount: account.cashUsd, currency: 'USD'),
            ],
          )
        : Column(
            key: const ValueKey('total'),
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                hidden ? hiddenAmount : formatPrice(account.value),
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
                    '${percent.toStringAsFixed(percent < 0.1 ? 2 : 1)}%',
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

/// "238.25 CAD": amount in semibold, currency code in book weight.
class _CashAmount extends StatelessWidget {
  const _CashAmount({required this.amount, required this.currency});

  final double amount;
  final String currency;

  @override
  Widget build(BuildContext context) {
    // 2pt larger than body-md (14), same 20pt line height.
    final base = ObrType.tabular(ObrType.bodyMd).copyWith(
      fontSize: 16,
      height: 20 / 16,
      color: ObrColors.gray700,
    );
    return Text.rich(
      TextSpan(
        children: [
          TextSpan(
            text: BalanceVisibility.hiddenOf(context)
                ? hiddenAmount
                : formatPrice(amount),
            style: base.copyWith(fontWeight: FontWeight.w600),
          ),
          TextSpan(
            text: ' $currency',
            style: base.copyWith(fontWeight: FontWeight.w400),
          ),
        ],
      ),
    );
  }
}

class _AccountActions extends StatelessWidget {
  const _AccountActions({
    required this.account,
    required this.onManage,
    required this.onTransfer,
    required this.onTrade,
  });

  final Account account;
  final VoidCallback onManage;
  final VoidCallback onTransfer;
  final VoidCallback onTrade;

  @override
  Widget build(BuildContext context) {
    return FittedBox(
      fit: BoxFit.scaleDown,
      alignment: Alignment.centerRight,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _ActionTile(
            key: const ValueKey('account-action-manage'),
            icon: Icons.settings_outlined,
            label: 'Manage',
            semanticLabel: 'Manage ${account.name}',
            onTap: onManage,
          ),
          const SizedBox(width: ObrSpace.s8),
          _ActionTile(
            key: const ValueKey('account-action-transfer'),
            icon: Icons.swap_horiz,
            label: 'Transfer',
            semanticLabel: 'Transfer from ${account.name}',
            onTap: onTransfer,
          ),
          const SizedBox(width: ObrSpace.s8),
          _ActionTile(
            key: const ValueKey('account-action-trade'),
            icon: Icons.candlestick_chart_outlined,
            label: 'Trade',
            semanticLabel: 'Trade in ${account.name}',
            onTap: onTrade,
          ),
        ],
      ),
    );
  }
}

/// Icon-over-label action button, as in the mock.
class _ActionTile extends StatelessWidget {
  const _ActionTile({
    super.key,
    required this.icon,
    required this.label,
    required this.semanticLabel,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final String semanticLabel;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: semanticLabel,
      excludeSemantics: true,
      child: Material(
        // All actions share one dark gray; half the old 12pt radius.
        color: ObrColors.gray700,
        borderRadius: BorderRadius.circular(6),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: SizedBox(
            width: 76,
            height: ObrSize.s56,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, color: ObrColors.gray0, size: ObrSize.s20),
                const SizedBox(height: ObrSpace.s2),
                Text(
                  label,
                  maxLines: 1,
                  style: ObrType.captionSemibold.copyWith(
                    color: ObrColors.gray0,
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
