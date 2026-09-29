import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../../data/mock_portfolio.dart';
import '../../router.dart';
import '../../state/balance_visibility.dart';
import '../../theme/obr_tokens.dart';
import '../../theme/obr_typography.dart';
import '../../util/format.dart';
import '../../util/motion.dart';
import '../../widgets/motion_animated_size.dart';
import '../../widgets/prototype_notice.dart';

/// Sort options for Stocks & ETFs. Portfolio weight % is the default.
enum HoldingsSort {
  weight('Portfolio weight %'),
  dailyChange(r'Daily change $'),
  dailyChangePercent('Daily change %'),
  assetType('Asset type'),
  ticker('Ticker'),
  name('Name'),
  quantity('Quantity'),
  currency('Currency'),
  price('Price'),
  marketValueChange('Market value change'),
  totalGain('Total gain/loss');

  const HoldingsSort(this.label);

  final String label;
}

/// Holdings across all accounts, or one account at a time.
///
/// - Account filter: pills (All, then each account's name and number), or a
///   dropdown once there are [AccountFilter.dropdownThreshold] or more
///   accounts.
/// - Total value (hidden with the shared eye toggle) and intraday change.
/// - Cash accordion, collapsed by default, with total cash in CAD.
/// - Stocks & ETFs accordion, expanded by default, with total value, today's
///   change and a Sort by menu (Portfolio weight % by default).
/// - Row designs for both accordions are TBD; placeholder rows show the
///   ticker and the current sort value so sorting can be reviewed.
class HoldingsScreen extends StatefulWidget {
  const HoldingsScreen({super.key, this.initialAccount});

  /// Account name to preselect (from tapping an account on Home), or null
  /// for All.
  final String? initialAccount;

  @override
  State<HoldingsScreen> createState() => _HoldingsScreenState();
}

class _HoldingsScreenState extends State<HoldingsScreen> {
  /// Selected account name, or null for All.
  String? _account;
  bool _cashOpen = false;
  bool _stocksOpen = true;
  HoldingsSort _sort = HoldingsSort.weight;

  @override
  void initState() {
    super.initState();
    final initial = widget.initialAccount;
    if (initial != null && MockPortfolio.accountNamed(initial) != null) {
      _account = initial;
    }
  }

  /// The gear opens the selected account's settings, or the list of
  /// accounts when All is selected.
  void _openSettings() {
    final account = _account;
    context.push(
      account == null
          ? AppRoutes.accountSettings
          : Uri(
              path: AppRoutes.accountSettings,
              queryParameters: {'account': account},
            ).toString(),
    );
  }

  void _download() {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        const SnackBar(
          content: Text('Download holdings is not built yet in this prototype.'),
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    final accounts = MockPortfolio.accounts;
    final selected =
        _account == null ? null : MockPortfolio.accountNamed(_account!);
    // Shared with Home: hidden there means hidden here, and vice versa.
    final hidden = BalanceVisibility.hiddenOf(context);

    // Totals for the selection. Cash doesn't move intraday, so today's change
    // all comes from Stocks & ETFs.
    final List<Account> scope = selected == null ? accounts : [selected];
    final total = selected?.value ?? MockPortfolio.totalValue;
    final double change;
    if (selected == null) {
      change = MockPortfolio.series(ChartRange.oneDay).change;
    } else {
      final p = selected.changePercent / 100;
      change = selected.value - selected.value / (1 + p);
    }
    final changePercent = change / (total - change) * 100;
    final cashCad = scope.fold<double>(0, (sum, a) => sum + a.cashCad);
    final cashUsd = scope.fold<double>(0, (sum, a) => sum + a.cashUsd);
    final cashTotal = cashCad + MockMarket.toCad(cashUsd, 'USD');
    final stocksValue = total - cashTotal;
    final stocksChangePercent = change / (stocksValue - change) * 100;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Holdings'),
        centerTitle: true,
        actions: [
          IconButton(
            tooltip: selected == null
                ? 'Account settings'
                : '${selected.name} settings',
            onPressed: _openSettings,
            icon: const Icon(Icons.settings_outlined),
            color: ObrColors.gray700,
          ),
          const SizedBox(width: ObrSpace.s4),
        ],
      ),
      body: SafeArea(
        top: false,
        child: Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 640),
            child: ListView(
              padding: const EdgeInsets.only(bottom: ObrSpace.s32),
              children: [
                AccountFilter(
                  accounts: accounts,
                  selected: _account,
                  onSelected: (name) {
                    HapticFeedback.selectionClick();
                    setState(() => _account = name);
                  },
                ),
                const SizedBox(height: ObrSpace.s16),
                _Summary(total: total, change: change, percent: changePercent),
                const SizedBox(height: ObrSpace.s24),
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: ObrSpace.s20,
                  ),
                  child: Column(
                    children: [
                      _Accordion(
                        title: 'Cash',
                        value: cashTotal,
                        expanded: _cashOpen,
                        onToggle: () => setState(() => _cashOpen = !_cashOpen),
                        child: Column(
                          children: [
                            _PlaceholderRow(
                              leading: 'CAD',
                              trailing: hidden
                                  ? '$hiddenAmount CAD'
                                  : '${formatPrice(cashCad)} CAD',
                            ),
                            const SizedBox(height: ObrSpace.s8),
                            _PlaceholderRow(
                              leading: 'USD',
                              trailing: hidden
                                  ? '$hiddenAmount USD'
                                  : '${formatPrice(cashUsd)} USD',
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: ObrSpace.s12),
                      _Accordion(
                        title: 'Stocks & ETFs',
                        value: stocksValue,
                        change: change,
                        changePercent: stocksChangePercent,
                        expanded: _stocksOpen,
                        onToggle: () =>
                            setState(() => _stocksOpen = !_stocksOpen),
                        child: _StocksBody(
                          sort: _sort,
                          filtered: selected != null,
                          hidden: hidden,
                          onSort: (sort) {
                            HapticFeedback.selectionClick();
                            setState(() => _sort = sort);
                          },
                        ),
                      ),
                      const SizedBox(height: ObrSpace.s12),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: _DownloadLink(onTap: _download),
                      ),
                      const SizedBox(height: ObrSpace.s24),
                      const PrototypeNotice(
                        message: 'Prototype: row designs for Cash and Stocks '
                            '& ETFs are TBD, so rows are placeholders. Values '
                            'are mock data.',
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

// ─── Account filter ───────────────────────────────────────────────────────

/// "All" plus one pill per account ("TFSA 58204417"), scrolling sideways.
/// With [dropdownThreshold] or more accounts it collapses into a dropdown.
class AccountFilter extends StatefulWidget {
  const AccountFilter({
    super.key,
    required this.accounts,
    required this.selected,
    required this.onSelected,
  });

  static const int dropdownThreshold = 6;

  final List<Account> accounts;

  /// Selected account name, or null for All.
  final String? selected;
  final ValueChanged<String?> onSelected;

  static String labelFor(Account a) => '${a.name} ${a.number}';

  /// Dropdown value for the "+ Add account" item (not an account name).
  static const String _addAccountValue = '__add_account__';

  /// "Link an existing account" or "Open a new account", over a dimmed
  /// backdrop. Neither is built yet.
  static Future<void> showAddAccountSheet(BuildContext context) {
    void notBuilt(BuildContext sheetContext, String label) {
      Navigator.of(sheetContext).pop();
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(content: Text('$label is not built yet in this prototype.')),
        );
    }

    return showModalBottomSheet<void>(
      context: context,
      // Dark scrim keeps focus on the sheet.
      barrierColor: Colors.black.withValues(alpha: 0.6),
      backgroundColor: ObrColors.gray0,
      showDragHandle: true,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(ObrRadius.r24)),
      ),
      builder: (sheetContext) => SafeArea(
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
                  child: Text('Add an account', style: ObrType.headingSmSemibold),
                ),
              ),
              _SheetOption(
                icon: Icons.link,
                label: 'Link an existing account',
                onTap: () => notBuilt(sheetContext, 'Linking an account'),
              ),
              _SheetOption(
                icon: Icons.add,
                label: 'Open a new account',
                onTap: () => notBuilt(sheetContext, 'Opening an account'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  State<AccountFilter> createState() => _AccountFilterState();
}

class _AccountFilterState extends State<AccountFilter> {
  final _selectedKey = GlobalKey();
  final ScrollController _pills = ScrollController();

  /// Scrolled to the end of the pills (or they all fit): the sticky "+"
  /// expands into the full "Add account" pill.
  bool _atEnd = false;

  void _updateAtEnd() {
    if (!_pills.hasClients || !mounted) return;
    final position = _pills.position;
    final atEnd = position.pixels >= position.maxScrollExtent - 1;
    if (atEnd != _atEnd) setState(() => _atEnd = atEnd);
  }

  @override
  void dispose() {
    _pills.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _pills.addListener(_updateAtEnd);
    WidgetsBinding.instance.addPostFrameCallback((_) => _updateAtEnd());
    // Arriving with an account preselected (e.g. RESP, far right): scroll its
    // pill into view.
    if (widget.selected != null) _revealSelected(animate: false);
  }

  @override
  void didUpdateWidget(AccountFilter oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selected != widget.selected) _revealSelected(animate: true);
  }

  void _revealSelected({required bool animate}) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final ctx = _selectedKey.currentContext;
      if (ctx == null || !mounted) return;
      Scrollable.ensureVisible(
        ctx,
        alignment: 0.5,
        duration: animate
            ? motionDuration(context, ObrDuration.d250)
            : Duration.zero,
        curve: ObrEasing.easeOut,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final accounts = widget.accounts;
    final selected = widget.selected;
    final onSelected = widget.onSelected;
    if (accounts.length >= AccountFilter.dropdownThreshold) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: ObrSpace.s20),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: ObrColors.gray0,
            borderRadius: BorderRadius.circular(ObrRadius.full),
            border: Border.all(color: ObrColors.gray300),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: ObrSpace.s20),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String?>(
                value: selected,
                isExpanded: true,
                style: ObrType.bodyLg,
                icon: const Icon(
                  Icons.keyboard_arrow_down,
                  color: ObrColors.gray700,
                ),
                items: [
                  const DropdownMenuItem<String?>(
                    value: null,
                    child: Text('All accounts'),
                  ),
                  for (final a in accounts)
                    DropdownMenuItem<String?>(
                      value: a.name,
                      child: Text(
                        AccountFilter.labelFor(a),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  DropdownMenuItem<String?>(
                    value: AccountFilter._addAccountValue,
                    child: Text(
                      '+ Add account',
                      style: ObrType.bodyLg.copyWith(color: ObrColors.gray500),
                    ),
                  ),
                ],
                onChanged: (value) {
                  if (value == AccountFilter._addAccountValue) {
                    AccountFilter.showAddAccountSheet(context);
                  } else {
                    onSelected(value);
                  }
                },
              ),
            ),
          ),
        ),
      );
    }

    final expandedWidth = _AddAccountPill.expandedWidth(context);
    final background = Theme.of(context).scaffoldBackgroundColor;
    const side = ObrSpace.s20;
    return SizedBox(
      height: ObrSize.s48,
      child: Stack(
        children: [
          NotificationListener<ScrollMetricsNotification>(
            // Pills added, removed or resized (e.g. text size): re-check.
            onNotification: (_) {
              WidgetsBinding.instance
                  .addPostFrameCallback((_) => _updateAtEnd());
              return false;
            },
            child: ListView(
              controller: _pills,
              scrollDirection: Axis.horizontal,
              // Room at the end for the expanded "Add account" pill, which
              // sits on top of the list rather than in it.
              padding: EdgeInsets.only(
                left: side,
                right: side + expandedWidth + ObrSpace.s8,
              ),
              children: [
                _AccountPill(
                  key: selected == null ? _selectedKey : null,
                  label: 'All',
                  selected: selected == null,
                  onTap: () => onSelected(null),
                ),
                for (final a in accounts) ...[
                  const SizedBox(width: ObrSpace.s8),
                  _AccountPill(
                    key: selected == a.name ? _selectedKey : null,
                    label: AccountFilter.labelFor(a),
                    selected: selected == a.name,
                    onTap: () => onSelected(a.name),
                  ),
                ],
              ],
            ),
          ),
          // Pills passing under the sticky "+" blur and fade out.
          Positioned(
            right: 0,
            top: 0,
            bottom: 0,
            width: side + _AddAccountPill.collapsedSize + ObrSpace.s24,
            child: IgnorePointer(
              child: AnimatedOpacity(
                opacity: _atEnd ? 0 : 1,
                duration: motionDuration(context, ObrDuration.d200),
                child: ClipRect(
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 3, sigmaY: 3),
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            background.withValues(alpha: 0),
                            background.withValues(alpha: 0.85),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            right: side,
            top: 0,
            bottom: 0,
            child: Center(
              child: _AddAccountPill(
                key: const ValueKey('add-account'),
                expanded: _atEnd,
                onTap: () => AccountFilter.showAddAccountSheet(context),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AccountPill extends StatelessWidget {
  const _AccountPill({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      inMutuallyExclusiveGroup: true,
      label: label,
      onTap: onTap,
      excludeSemantics: true,
      child: Material(
        color: selected ? ObrColors.gray700 : ObrColors.gray0,
        shape: StadiumBorder(
          side: BorderSide(
            color: selected ? ObrColors.gray700 : ObrColors.gray300,
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: ObrSpace.s20),
            child: Center(
              widthFactor: 1,
              child: Text(
                label,
                style: ObrType.labelLg.copyWith(
                  color: selected ? ObrColors.gray0 : ObrColors.gray800,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Summary ──────────────────────────────────────────────────────────────

class _Summary extends StatelessWidget {
  const _Summary({
    required this.total,
    required this.change,
    required this.percent,
  });

  final double total;
  final double change;
  final double percent;

  @override
  Widget build(BuildContext context) {
    final hiddenNotifier = BalanceVisibility.of(context);
    final hidden = hiddenNotifier.value;
    final isUp = change >= 0;
    final color = isUp ? ObrColors.green600 : ObrColors.orange700;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: ObrSpace.s20),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Flexible(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Semantics(
                    label: hidden ? 'Total value hidden' : null,
                    excludeSemantics: hidden,
                    child: Text.rich(
                      TextSpan(
                        children: [
                          TextSpan(
                            text: hidden ? r'$••••••' : formatCad(total),
                            style: ObrType.tabular(ObrType.displayMdSemibold),
                          ),
                          TextSpan(
                            text: ' CAD',
                            style: ObrType.bodyLgSemibold.copyWith(
                              color: ObrColors.gray700,
                            ),
                          ),
                        ],
                      ),
                      maxLines: 1,
                    ),
                  ),
                ),
              ),
              IconButton(
                tooltip: hidden ? 'Show balance' : 'Hide balance',
                onPressed: () {
                  HapticFeedback.selectionClick();
                  hiddenNotifier.value = !hidden;
                },
                icon: Icon(
                  hidden
                      ? Icons.visibility_off_outlined
                      : Icons.visibility_outlined,
                ),
                color: ObrColors.gray600,
              ),
            ],
          ),
          Semantics(
            label: 'Intraday change ${isUp ? 'up' : 'down'} '
                '${hidden ? '' : '${formatCad(change.abs())}, '}'
                '${percent.abs().toStringAsFixed(2)} percent',
            excludeSemantics: true,
            child: Wrap(
              alignment: WrapAlignment.center,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: ObrSpace.s8,
              children: [
                Text(
                  'Intraday change',
                  style: ObrType.bodyMdBook.copyWith(color: ObrColors.gray600),
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      isUp ? Icons.arrow_drop_up : Icons.arrow_drop_down,
                      color: color,
                    ),
                    Text(
                      '${hidden ? hiddenAmount : formatSignedCad(change)} '
                      '(${formatSignedPercent(percent)})',
                      style: ObrType.tabular(ObrType.bodyMd).copyWith(
                        color: color,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Accordion ────────────────────────────────────────────────────────────

class _Accordion extends StatelessWidget {
  const _Accordion({
    required this.title,
    required this.value,
    required this.expanded,
    required this.onToggle,
    required this.child,
    this.change,
    this.changePercent,
  });

  final String title;
  final double value;
  final double? change;
  final double? changePercent;
  final bool expanded;
  final VoidCallback onToggle;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final hidden = BalanceVisibility.hiddenOf(context);
    final radius = BorderRadius.circular(ObrRadius.r16);
    final changeColor = (change ?? 0) >= 0
        ? ObrColors.green600
        : ObrColors.orange700;

    return Material(
      color: ObrColors.gray0,
      shape: RoundedRectangleBorder(
        borderRadius: radius,
        side: const BorderSide(color: ObrColors.gray200),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Semantics(
            button: true,
            label: hidden
                ? '$title, amount hidden'
                : '$title, ${formatPrice(value)} CAD'
                    '${change == null ? '' : ', ${formatSignedCad(change!)} today'}',
            expanded: expanded,
            onTap: onToggle,
            excludeSemantics: true,
            child: InkWell(
              onTap: onToggle,
              child: ConstrainedBox(
                constraints: const BoxConstraints(minHeight: ObrSize.s64),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(
                    ObrSpace.s20,
                    ObrSpace.s12,
                    ObrSpace.s12,
                    ObrSpace.s12,
                  ),
                  child: Row(
                    children: [
                      // Title takes only its own width (up to half the row),
                      // so the value's Expanded runs to the chevron and the
                      // value sits flush right, however short the title.
                      ConstrainedBox(
                        constraints: BoxConstraints(
                          maxWidth: MediaQuery.sizeOf(context).width * 0.4,
                        ),
                        child: Text(title, style: ObrType.headingSmSemibold),
                      ),
                      const SizedBox(width: ObrSpace.s12),
                      Expanded(
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.centerRight,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                '${hidden ? hiddenAmount : formatPrice(value)} CAD',
                                style: ObrType.tabular(
                                  ObrType.headingXs,
                                ),
                              ),
                              if (change != null && changePercent != null)
                                Text(
                                  '${hidden ? hiddenAmount : formatSignedCad(change!)} '
                                  '(${formatSignedPercent(changePercent!)})',
                                  style: ObrType.tabular(ObrType.bodyMdBook)
                                      .copyWith(color: changeColor),
                                ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: ObrSpace.s4),
                      AnimatedRotation(
                        turns: expanded ? 0.5 : 0,
                        duration: motionDuration(context, ObrDuration.d200),
                        child: const Icon(
                          Icons.keyboard_arrow_down,
                          color: ObrColors.gray600,
                          size: ObrSize.s28,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          MotionAnimatedSize(
            child: expanded
                ? Padding(
                    padding: const EdgeInsets.fromLTRB(
                      ObrSpace.s20,
                      0,
                      ObrSpace.s20,
                      ObrSpace.s20,
                    ),
                    child: child,
                  )
                : const SizedBox(width: double.infinity),
          ),
        ],
      ),
    );
  }
}

// ─── Stocks & ETFs body ───────────────────────────────────────────────────

class _StocksBody extends StatelessWidget {
  const _StocksBody({
    required this.sort,
    required this.filtered,
    required this.hidden,
    required this.onSort,
  });

  /// Balances hidden with the eye toggle.
  final bool hidden;

  final HoldingsSort sort;

  /// True when one account is selected (per-account holdings aren't in the
  /// mock data, so all holdings are shown).
  final bool filtered;
  final ValueChanged<HoldingsSort> onSort;

  static List<Holding> _sorted(HoldingsSort sort) {
    final list = MockHoldings.all;
    int desc(double a, double b) => b.compareTo(a);
    int byTicker(Holding a, Holding b) =>
        a.security.symbol.compareTo(b.security.symbol);
    switch (sort) {
      case HoldingsSort.weight:
        list.sort((a, b) => desc(a.weightPercent, b.weightPercent));
      case HoldingsSort.dailyChange:
        list.sort((a, b) => desc(a.security.quote.change, b.security.quote.change));
      case HoldingsSort.dailyChangePercent:
        list.sort((a, b) => desc(a.dayChangePercent, b.dayChangePercent));
      case HoldingsSort.assetType:
        list.sort((a, b) {
          final c = a.security.type.compareTo(b.security.type);
          return c != 0 ? c : byTicker(a, b);
        });
      case HoldingsSort.ticker:
        list.sort(byTicker);
      case HoldingsSort.name:
        list.sort((a, b) => a.security.name.compareTo(b.security.name));
      case HoldingsSort.quantity:
        list.sort((a, b) => b.shares.compareTo(a.shares));
      case HoldingsSort.currency:
        list.sort((a, b) {
          final c = a.security.currency.compareTo(b.security.currency);
          return c != 0 ? c : byTicker(a, b);
        });
      case HoldingsSort.price:
        list.sort((a, b) => desc(a.security.quote.price, b.security.quote.price));
      case HoldingsSort.marketValueChange:
        list.sort((a, b) => desc(a.dayChangeCad, b.dayChangeCad));
      case HoldingsSort.totalGain:
        list.sort((a, b) => desc(a.totalGainCad, b.totalGainCad));
    }
    return list;
  }

  /// What the placeholder row shows on the right for the current sort.
  /// Market data (price, daily change per share, type…) stays visible when
  /// balances are hidden; the client's own amounts are masked.
  static String _sortValue(Holding h, HoldingsSort sort, bool hidden) {
    final s = h.security;
    if (hidden) {
      switch (sort) {
        case HoldingsSort.weight:
        case HoldingsSort.quantity:
        case HoldingsSort.marketValueChange:
        case HoldingsSort.totalGain:
          return hiddenAmount;
        default:
          break;
      }
    }
    return switch (sort) {
      HoldingsSort.weight => '${h.weightPercent.toStringAsFixed(1)}%',
      HoldingsSort.dailyChange =>
        '${formatSignedCad(s.quote.change)} ${s.currency}',
      HoldingsSort.dailyChangePercent =>
        formatSignedPercent(h.dayChangePercent),
      HoldingsSort.assetType => s.type,
      HoldingsSort.ticker => s.exchange,
      HoldingsSort.name => s.name,
      HoldingsSort.quantity => '${formatWhole(h.shares)} shares',
      HoldingsSort.currency => s.currency,
      HoldingsSort.price => '${formatPrice(s.quote.price)} ${s.currency}',
      HoldingsSort.marketValueChange =>
        '${formatSignedCad(h.dayChangeCad)} CAD',
      HoldingsSort.totalGain => '${formatSignedCad(h.totalGainCad)} CAD',
    };
  }

  @override
  Widget build(BuildContext context) {
    final holdings = _sorted(sort);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Align(
          alignment: Alignment.centerLeft,
          child: _SortMenu(sort: sort, onSort: onSort),
        ),
        if (filtered) ...[
          const SizedBox(height: ObrSpace.s4),
          Text(
            'Per-account holdings aren\'t in the mock data yet, so all '
            'holdings are shown.',
            style: ObrType.caption.copyWith(color: ObrColors.gray600),
          ),
        ],
        const SizedBox(height: ObrSpace.s8),
        for (var i = 0; i < holdings.length; i++) ...[
          if (i > 0) const SizedBox(height: ObrSpace.s8),
          _PlaceholderRow(
            leading: holdings[i].security.symbol,
            trailing: _sortValue(holdings[i], sort, hidden),
          ),
        ],
      ],
    );
  }
}

class _SortMenu extends StatelessWidget {
  const _SortMenu({required this.sort, required this.onSort});

  final HoldingsSort sort;
  final ValueChanged<HoldingsSort> onSort;

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<HoldingsSort>(
      tooltip: 'Sort holdings',
      initialValue: sort,
      onSelected: onSort,
      position: PopupMenuPosition.under,
      itemBuilder: (context) => [
        for (final option in HoldingsSort.values)
          CheckedPopupMenuItem<HoldingsSort>(
            value: option,
            checked: option == sort,
            child: Text(option.label),
          ),
      ],
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: ObrSize.s44),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Flexible(
              child: Text.rich(
              TextSpan(
                children: [
                  const TextSpan(text: 'Sort by '),
                  TextSpan(
                    text: sort.label,
                    style: const TextStyle(color: ObrColors.gray800),
                  ),
                ],
              ),
              style: ObrType.bodyMdBook.copyWith(color: ObrColors.gray600),
              ),
            ),
            const SizedBox(width: ObrSpace.s4),
            const Icon(
              Icons.keyboard_arrow_down,
              color: ObrColors.gray600,
            ),
          ],
        ),
      ),
    );
  }
}

/// Stand-in until the row design is decided.
class _PlaceholderRow extends StatelessWidget {
  const _PlaceholderRow({required this.leading, required this.trailing});

  final String leading;
  final String trailing;

  @override
  Widget build(BuildContext context) {
    return MergeSemantics(
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: ObrColors.gray100,
          borderRadius: BorderRadius.circular(ObrRadius.r8),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: ObrSpace.s12,
            vertical: ObrSpace.s12,
          ),
          child: Row(
            children: [
              Text(leading, style: ObrType.bodyLgSemibold),
              const SizedBox(width: ObrSpace.s8),
              Flexible(
                child: Text(
                  'Row design TBD',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: ObrType.caption.copyWith(color: ObrColors.gray600),
                ),
              ),
              const SizedBox(width: ObrSpace.s8),
              Expanded(
                child: Text(
                  trailing,
                  textAlign: TextAlign.end,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: ObrType.tabular(ObrType.bodyMd),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// "Download holdings", with a download icon in brand red.
class _DownloadLink extends StatelessWidget {
  const _DownloadLink({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      link: true,
      label: 'Download holdings',
      onTap: onTap,
      excludeSemantics: true,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(ObrRadius.r8),
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: ObrSize.s44),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: ObrSpace.s4),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.download,
                  color: ObrColors.brand600,
                  size: ObrSize.s24,
                ),
                const SizedBox(width: ObrSpace.s8),
                Flexible(
                  child: Text(
                    'Download holdings',
                    style: ObrType.bodyLgBook.copyWith(
                      color: ObrColors.gray800,
                    ),
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

/// "+ Add account": light gray with a dashed outline, last in the pill row.
/// Sticky "Add account" at the right of the pill row: a dashed "+" circle
/// while pills scroll underneath, expanding (animated) into the full
/// "+ Add account" pill at the end of the list.
class _AddAccountPill extends StatelessWidget {
  const _AddAccountPill({
    super.key,
    required this.expanded,
    required this.onTap,
  });

  final bool expanded;
  final VoidCallback onTap;

  static const double collapsedSize = ObrSize.s44;
  static const double _iconSize = ObrSize.s20;

  static TextStyle get _labelStyle =>
      ObrType.labelLg.copyWith(color: ObrColors.gray500);

  /// Width of the expanded pill at the current text size.
  static double expandedWidth(BuildContext context) {
    final painter = TextPainter(
      text: TextSpan(text: 'Add account', style: _labelStyle),
      textDirection: TextDirection.ltr,
      textScaler: MediaQuery.textScalerOf(context),
      maxLines: 1,
    )..layout();
    final width = ObrSpace.s16 + _iconSize + ObrSpace.s4 + painter.width +
        ObrSpace.s20;
    painter.dispose();
    return width;
  }

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: 'Add account',
      child: Semantics(
        button: true,
        label: 'Add account',
        onTap: onTap,
        excludeSemantics: true,
        child: CustomPaint(
          foregroundPainter: const _DashedStadiumPainter(
            color: ObrColors.gray400,
          ),
          child: Material(
            color: Theme.of(context).scaffoldBackgroundColor,
            shape: const StadiumBorder(),
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              onTap: onTap,
              child: SizedBox(
                height: collapsedSize,
                child: MotionAnimatedSize(
                  alignment: Alignment.centerRight,
                  child: Padding(
                    padding: expanded
                        ? const EdgeInsets.only(
                            left: ObrSpace.s16,
                            right: ObrSpace.s20,
                          )
                        : const EdgeInsets.symmetric(
                            horizontal: (collapsedSize - _iconSize) / 2,
                          ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.add,
                          size: _iconSize,
                          color: ObrColors.gray500,
                        ),
                        if (expanded) ...[
                          const SizedBox(width: ObrSpace.s4),
                          Text(
                            'Add account',
                            maxLines: 1,
                            softWrap: false,
                            style: _labelStyle,
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _DashedStadiumPainter extends CustomPainter {
  const _DashedStadiumPainter({required this.color});

  final Color color;

  static const double _dash = 5;
  static const double _gap = 4;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = (Offset.zero & size).deflate(0.5);
    final path = Path()
      ..addRRect(RRect.fromRectAndRadius(rect, Radius.circular(rect.height / 2)));
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
  bool shouldRepaint(_DashedStadiumPainter oldDelegate) =>
      oldDelegate.color != color;
}

class _SheetOption extends StatelessWidget {
  const _SheetOption({
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
