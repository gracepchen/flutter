import 'package:flutter/material.dart';

import '../theme/obr_tokens.dart';
import '../theme/obr_typography.dart';
import '../data/mock_portfolio.dart';
import '../widgets/app_nav_bar.dart';
import 'placeholder/placeholder_screen.dart';

/// Placeholder destinations for the four home quick actions
/// (Add, Transfer, Trade and Activity), plus Performance, Advanced chart and
/// Holdings.

class AddScreen extends StatelessWidget {
  const AddScreen({super.key, this.account, this.type});

  /// Preselected destination, e.g. when opened from an account's cash row.
  final String? account;

  /// "One-time transfer" or "Recurring deposit", from Financial progress.
  final String? type;

  @override
  Widget build(BuildContext context) {
    return PlaceholderScreen(
      title: 'Add funds',
      icon: Icons.add,
      summary: 'Deposit money into an Investor\'s Edge account from a linked '
          'bank account.',
      extra: _summaries([
        if (type != null) ('Deposit type', type!),
        if (account != null) ('Destination account', account!),
      ]),
      plannedItems: const [
        'Choose a destination account: TFSA, RRSP, FHSA, RESP or Non-Registered',
        'Pick a linked bank account, or link a new one',
        'Show remaining TFSA, RRSP and FHSA contribution room before confirming',
        'One-time or recurring (pre-authorized) contributions',
        'Review-and-confirm step, with biometric step-up for large amounts',
      ],
    );
  }
}

class TransferScreen extends StatelessWidget {
  const TransferScreen({super.key, this.account});

  /// Preselected source account, e.g. from an account row's Transfer.
  final String? account;

  @override
  Widget build(BuildContext context) {
    return PlaceholderScreen(
      title: 'Transfer',
      icon: Icons.swap_horiz,
      summary: 'Move money between your accounts, or bring assets over from '
          'another institution.',
      extra: _summaries([if (account != null) ('From account', account!)]),
      bottomNavigationBar:
          const AppNavBar(current: NavDestination.transfer),
      plannedItems: const [
        'Between your own Investor\'s Edge accounts, in CAD or USD',
        'To and from CIBC chequing and savings accounts',
        'Transfer in from another institution, in cash or in kind',
        'Currency conversion preview for CAD ↔ USD moves',
        'Confirmation screen with the estimated settlement date',
      ],
    );
  }
}

class TradeScreen extends StatelessWidget {
  const TradeScreen({super.key, this.symbol, this.side, this.account});

  /// Preselected security, e.g. when opened from a security's details page.
  final String? symbol;

  /// Preselected account, e.g. from an account row's Trade button.
  final String? account;

  /// "buy" or "sell" when opened from the Buy or Sell button.
  final String? side;

  @override
  Widget build(BuildContext context) {
    return PlaceholderScreen(
      title: 'Trade',
      icon: Icons.candlestick_chart_outlined,
      summary: 'Buy and sell stocks, ETFs and options on Canadian and U.S. '
          'markets.',
      extra: _summaries([
        if (account != null) ('Account', account!),
        if (symbol != null) ('Selected security', symbol!),
        if (side != null) ('Order', side == 'sell' ? 'Sell' : 'Buy'),
      ]),
      plannedItems: const [
        'Symbol search with live quote, bid/ask and day range',
        'Buy / Sell toggle: green for Buy, orange for Sell (OBR trade-flow tokens)',
        'Order types: market, limit, stop and stop-limit; day or good-till-cancelled',
        'Account picker with buying power in CAD and USD',
        'Review-and-confirm screen before the order is sent',
      ],
    );
  }
}

/// Stacks one [_SelectionSummary] per (label, value) pair, or returns null
/// when the route preselected nothing.
Widget? _summaries(List<(String, String)> items) {
  if (items.isEmpty) return null;
  return Column(
    children: [
      for (var i = 0; i < items.length; i++) ...[
        if (i > 0) const SizedBox(height: ObrSpace.s8),
        _SelectionSummary(label: items[i].$1, value: items[i].$2),
      ],
    ],
  );
}

/// Shows what the route preselected, e.g. "Selected security  XEQT".
class _SelectionSummary extends StatelessWidget {
  const _SelectionSummary({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: ObrColors.gray0,
        borderRadius: BorderRadius.circular(ObrRadius.r12),
        border: Border.all(color: ObrColors.gray200),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: ObrSpace.s16,
          vertical: ObrSpace.s12,
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: ObrType.bodyMdBook.copyWith(color: ObrColors.gray600),
              ),
            ),
            const SizedBox(width: ObrSpace.s12),
            Text(value, style: ObrType.bodyLgSemibold),
          ],
        ),
      ),
    );
  }
}

class ActivityScreen extends StatelessWidget {
  const ActivityScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const PlaceholderScreen(
      bottomNavigationBar: AppNavBar(current: NavDestination.activity),
      title: 'Activity',
      icon: Icons.timer_outlined,
      summary: 'Track the progress of deposits, transfers, orders and account '
          'requests, and see your full transaction history.',
      plannedItems: [
        'Timeline of pending and completed requests',
        'Full transaction history: deposits, trades, dividends and transfers',
        'Filters by type: deposits, transfers, orders and account changes',
        'Push notification when a request changes state',
        'Notification deep links land here through the same auth guard as '
            'in-app navigation',
      ],
    );
  }
}

class PerformanceScreen extends StatelessWidget {
  const PerformanceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const PlaceholderScreen(
      title: 'Performance',
      icon: Icons.show_chart,
      summary: 'Your rate of return and how your balance has changed over '
          'time.',
      plannedItems: [
        'Rate of return for the whole portfolio and for each account',
        'Balance trend over time, with deposits and withdrawals marked',
        'Time ranges from 1 month to since the account opened',
      ],
    );
  }
}

class AdvancedChartScreen extends StatelessWidget {
  const AdvancedChartScreen({super.key, this.symbol});

  final String? symbol;

  @override
  Widget build(BuildContext context) {
    return PlaceholderScreen(
      title: 'Advanced chart',
      icon: Icons.query_stats,
      summary: 'A full-screen, interactive chart for deeper analysis.',
      extra: symbol == null
          ? null
          : _SelectionSummary(label: 'Selected security', value: symbol!),
      plannedItems: const [
        'Candlestick, line and area views, with landscape full-screen',
        'Technical indicators such as moving averages, RSI and MACD',
        'Drawing tools and comparison against other securities or an index',
        'Custom date ranges and intraday intervals',
      ],
    );
  }
}

class AccountSettingsScreen extends StatelessWidget {
  const AccountSettingsScreen({super.key, required this.account});

  final String account;

  @override
  Widget build(BuildContext context) {
    final number = MockPortfolio.accountNamed(account)?.number;
    return PlaceholderScreen(
      title: '$account settings',
      icon: Icons.settings_outlined,
      summary: 'Settings for this account only.',
      extra: _summaries([
        ('Account', account),
        if (number != null) ('Account number', number),
      ]),
      plannedItems: const [
        'Account nickname and the order accounts appear in',
        'Statements, trade confirmations and tax slips for this account',
        'Trading permissions, such as options and margin',
        'Beneficiary or successor holder designation (registered accounts)',
        'Contribution room and history (TFSA, RRSP, FHSA and RESP)',
        'Transfer out or close the account',
      ],
    );
  }
}

class ContributionsScreen extends StatelessWidget {
  const ContributionsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const PlaceholderScreen(
      title: 'Account contributions',
      icon: Icons.bar_chart,
      summary: 'What you\'ve put into each registered account this year, and '
          'how much room you have left.',
      plannedItems: [
        'Year-to-date contributions for TFSA, RRSP, FHSA and RESP',
        'Remaining contribution room for each account',
        'RRSP contribution deadline reminder',
        'Over-contribution warnings before a deposit goes through',
        'Contribution history by account and year',
      ],
    );
  }
}

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const PlaceholderScreen(
      title: "Notifications & What's New",
      icon: Icons.campaign_outlined,
      summary: 'Alerts about your accounts and orders, plus announcements '
          'about new features in Investor\'s Edge.',
      plannedItems: [
        'Order fills, cancellations and expiries',
        'Price alerts you\'ve set on stocks and ETFs',
        'Deposits, transfers and contributions when they settle',
        'Dividends paid and upcoming ex-dividend dates for your holdings',
        'Documents ready: statements, trade confirmations and tax slips',
        'What\'s new: feature announcements and tips',
      ],
    );
  }
}

class WatchlistsScreen extends StatelessWidget {
  const WatchlistsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const PlaceholderScreen(
      title: 'Watchlists',
      icon: Icons.star_border,
      summary: 'Securities you\'re following, grouped into lists. Content '
          'TBD.',
    );
  }
}
