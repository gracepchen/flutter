import 'dart:math';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../data/mock_fractional.dart';
import '../../data/mock_portfolio.dart';
import '../../router.dart';
import '../../theme/obr_tokens.dart';
import '../../theme/obr_typography.dart';

enum _TypeTab { all, stock, etf }

enum _Sort {
  symbol('Symbol'),
  name('Name');

  const _Sort(this.label);
  final String label;
}

/// Fractional Stocks/ETFs: All / Stock / ETF tabs, a symbol or company
/// search, Exchange, Market Cap and Sector filters (with Clear), a sort,
/// a paged list with Buy on each row, and page links with Next.
class FractionalScreen extends StatefulWidget {
  const FractionalScreen({super.key});

  /// Rows per page.
  static const int pageSize = 10;

  @override
  State<FractionalScreen> createState() => _FractionalScreenState();
}

class _FractionalScreenState extends State<FractionalScreen> {
  final TextEditingController _search = TextEditingController();
  final ScrollController _scroll = ScrollController();
  _TypeTab _tab = _TypeTab.all;
  String? _exchange;
  String? _marketCap;
  String? _sector;
  _Sort _sort = _Sort.symbol;
  int _page = 0;

  @override
  void dispose() {
    _search.dispose();
    _scroll.dispose();
    super.dispose();
  }

  /// Any change to what's listed goes back to page 1.
  void _update(VoidCallback change) {
    setState(() {
      change();
      _page = 0;
    });
  }

  void _clear() => _update(() {
        _search.clear();
        _exchange = null;
        _marketCap = null;
        _sector = null;
      });

  void _goToPage(int page) {
    setState(() => _page = page);
    if (_scroll.hasClients) _scroll.jumpTo(0);
  }

  List<FractionalSecurity> get _results {
    final query = _search.text.trim().toLowerCase();
    final list = MockFractional.all.where((s) {
      if (_tab == _TypeTab.stock && s.type != 'Stock') return false;
      if (_tab == _TypeTab.etf && s.type != 'ETF') return false;
      if (_exchange != null && s.exchange != _exchange) return false;
      if (_marketCap != null && s.marketCap != _marketCap) return false;
      if (_sector != null && s.sector != _sector) return false;
      if (query.isNotEmpty &&
          !s.symbol.toLowerCase().contains(query) &&
          !s.name.toLowerCase().contains(query)) {
        return false;
      }
      return true;
    }).toList()
      ..sort(
        (a, b) => _sort == _Sort.symbol
            ? a.symbol.compareTo(b.symbol)
            : a.name.compareTo(b.name),
      );
    return list;
  }

  @override
  Widget build(BuildContext context) {
    final results = _results;
    final int pageCount =
        max(1, (results.length / FractionalScreen.pageSize).ceil());
    final int page = min(_page, pageCount - 1);
    final start = page * FractionalScreen.pageSize;
    final pageItems = results
        .skip(start)
        .take(FractionalScreen.pageSize)
        .toList();

    return Scaffold(
      backgroundColor: ObrColors.gray0,
      appBar: AppBar(
        title: const Text('Fractional Stocks/ETFs'),
        centerTitle: true,
        backgroundColor: ObrColors.gray0,
        shape: const Border(bottom: BorderSide(color: ObrColors.gray200)),
      ),
      body: Column(
        children: [
          _Tabs(
            selected: _tab,
            onSelected: (tab) => _update(() => _tab = tab),
          ),
          Expanded(
            child: ListView(
              controller: _scroll,
              padding: const EdgeInsets.fromLTRB(
                ObrSpace.s16,
                ObrSpace.s12,
                ObrSpace.s16,
                ObrSpace.s16,
              ),
              children: [
                TextField(
                  controller: _search,
                  onChanged: (_) => _update(() {}),
                  textInputAction: TextInputAction.search,
                  decoration: InputDecoration(
                    hintText: 'Enter symbol or company',
                    hintStyle: ObrType.bodyLgBook.copyWith(
                      color: ObrColors.gray500,
                    ),
                    prefixIcon: const Icon(
                      Icons.search,
                      color: ObrColors.gray700,
                    ),
                    isDense: true,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(ObrRadius.r4),
                      borderSide: const BorderSide(color: ObrColors.gray300),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(ObrRadius.r4),
                      borderSide: const BorderSide(color: ObrColors.gray300),
                    ),
                  ),
                ),
                const SizedBox(height: ObrSpace.s16),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: _Filter(
                        label: 'Exchange',
                        anyLabel: 'All',
                        options: MockFractional.exchanges,
                        value: _exchange,
                        onChanged: (v) => _update(() => _exchange = v),
                      ),
                    ),
                    const SizedBox(width: ObrSpace.s8),
                    Expanded(
                      child: _Filter(
                        label: 'Market Cap',
                        anyLabel: 'Any size',
                        options: MockFractional.marketCaps,
                        value: _marketCap,
                        onChanged: (v) => _update(() => _marketCap = v),
                      ),
                    ),
                    const SizedBox(width: ObrSpace.s8),
                    Expanded(
                      child: _Filter(
                        label: 'Sector',
                        anyLabel: 'All',
                        options: MockFractional.sectors,
                        value: _sector,
                        onChanged: (v) => _update(() => _sector = v),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: ObrSpace.s12),
                Align(
                  alignment: Alignment.centerLeft,
                  child: FilledButton(
                    onPressed: _clear,
                    style: FilledButton.styleFrom(
                      backgroundColor: ObrColors.gray100,
                      foregroundColor: ObrColors.gray800,
                      minimumSize: const Size(96, ObrSize.s44),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(ObrRadius.r4),
                      ),
                    ),
                    child: const Text('Clear'),
                  ),
                ),
                const SizedBox(height: ObrSpace.s12),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        '${pageItems.length} of ${results.length} securities',
                        style: ObrType.bodyMdBook.copyWith(
                          color: ObrColors.gray600,
                        ),
                      ),
                    ),
                    PopupMenuButton<_Sort>(
                      tooltip: 'Sort securities',
                      initialValue: _sort,
                      position: PopupMenuPosition.under,
                      onSelected: (v) => _update(() => _sort = v),
                      itemBuilder: (context) => [
                        for (final s in _Sort.values)
                          CheckedPopupMenuItem(
                            value: s,
                            checked: s == _sort,
                            child: Text(s.label),
                          ),
                      ],
                      child: ConstrainedBox(
                        constraints:
                            const BoxConstraints(minHeight: ObrSize.s44),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'Sort by ',
                              style: ObrType.bodyMdBook.copyWith(
                                color: ObrColors.gray600,
                              ),
                            ),
                            Text(_sort.label, style: ObrType.bodyMd),
                            const Icon(
                              Icons.keyboard_arrow_down,
                              color: ObrColors.gray700,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                if (results.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      vertical: ObrSpace.s32,
                    ),
                    child: Text(
                      'No securities match. Try clearing a filter.',
                      textAlign: TextAlign.center,
                      style: ObrType.bodyLgBook.copyWith(
                        color: ObrColors.gray600,
                      ),
                    ),
                  ),
                for (final security in pageItems) _Row(security: security),
              ],
            ),
          ),
          _Pager(
            page: page,
            pageCount: pageCount,
            shown: pageItems.length,
            total: results.length,
            onPage: _goToPage,
          ),
        ],
      ),
    );
  }
}

class _Tabs extends StatelessWidget {
  const _Tabs({required this.selected, required this.onSelected});

  final _TypeTab selected;
  final ValueChanged<_TypeTab> onSelected;

  static const _labels = {
    _TypeTab.all: 'All',
    _TypeTab.stock: 'Stock',
    _TypeTab.etf: 'ETF',
  };

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: ObrColors.gray200)),
      ),
      child: Row(
        children: [
          for (final tab in _TypeTab.values)
            Semantics(
              button: true,
              selected: tab == selected,
              inMutuallyExclusiveGroup: true,
              label: _labels[tab],
              excludeSemantics: true,
              child: InkWell(
                onTap: () => onSelected(tab),
                child: Container(
                  constraints: const BoxConstraints(minHeight: ObrSize.s48),
                  padding: const EdgeInsets.symmetric(
                    horizontal: ObrSpace.s16,
                  ),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    border: Border(
                      bottom: BorderSide(
                        color: tab == selected
                            ? ObrColors.gray800
                            : Colors.transparent,
                        width: 2,
                      ),
                    ),
                  ),
                  child: Text(
                    _labels[tab]!,
                    style: ObrType.bodyLg.copyWith(
                      color: tab == selected
                          ? ObrColors.gray900
                          : ObrColors.gray700,
                      fontWeight:
                          tab == selected ? FontWeight.w600 : FontWeight.w400,
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

/// Label over a dropdown. Null means the "any" option.
class _Filter extends StatelessWidget {
  const _Filter({
    required this.label,
    required this.anyLabel,
    required this.options,
    required this.value,
    required this.onChanged,
  });

  final String label;
  final String anyLabel;
  final List<String> options;
  final String? value;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: ObrType.bodyMdBook.copyWith(color: ObrColors.gray800)),
        const SizedBox(height: ObrSpace.s4),
        Container(
          height: ObrSize.s48,
          padding: const EdgeInsets.symmetric(horizontal: ObrSpace.s12),
          decoration: BoxDecoration(
            border: Border.all(color: ObrColors.gray300),
            borderRadius: BorderRadius.circular(ObrRadius.r4),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String?>(
              value: value,
              isExpanded: true,
              style: ObrType.bodyLgBook.copyWith(color: ObrColors.gray800),
              icon: const Icon(
                Icons.keyboard_arrow_down,
                color: ObrColors.gray700,
              ),
              items: [
                DropdownMenuItem<String?>(
                  value: null,
                  child: Text(
                    anyLabel,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                for (final o in options)
                  DropdownMenuItem<String?>(
                    value: o,
                    child: Text(
                      o,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
              ],
              onChanged: onChanged,
            ),
          ),
        ),
      ],
    );
  }
}

class _Row extends StatelessWidget {
  const _Row({required this.security});

  final FractionalSecurity security;

  void _buy(BuildContext context) {
    context.push(
      Uri(
        path: AppRoutes.trade,
        queryParameters: {'symbol': security.symbol, 'side': 'buy'},
      ).toString(),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Securities with a details page in the mock open it; others don't.
    final hasDetails = MockSecurities.bySymbol(security.symbol) != null;
    return MergeSemantics(
      child: InkWell(
        onTap: hasDetails
            ? () => context.push('${AppRoutes.quote}/${security.symbol}')
            : null,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: ObrSpace.s12),
          child: Row(
            children: [
              ExcludeSemantics(
                child: Container(
                  width: ObrSize.s44,
                  height: ObrSize.s44,
                  alignment: Alignment.center,
                  decoration: const BoxDecoration(
                    color: ObrColors.gray800,
                    shape: BoxShape.circle,
                  ),
                  child: Text(
                    security.symbol.substring(0, 1),
                    style: ObrType.bodyLgSemibold.copyWith(
                      color: ObrColors.gray0,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: ObrSpace.s12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(security.symbol, style: ObrType.bodyLgSemibold),
                    Text(
                      security.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: ObrType.bodyMdBook.copyWith(
                        color: ObrColors.gray700,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: ObrSpace.s12),
              Semantics(
                button: true,
                label: 'Buy ${security.symbol}',
                excludeSemantics: true,
                child: FilledButton(
                  onPressed: () => _buy(context),
                  style: FilledButton.styleFrom(
                    backgroundColor: ObrColors.gray700,
                    foregroundColor: ObrColors.gray0,
                    minimumSize: const Size(88, ObrSize.s44),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(ObrRadius.r4),
                    ),
                  ),
                  child: const Text('Buy'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// "1 2 3 4 … N" page links, "10 of 34 results" and Next, pinned to the
/// bottom.
class _Pager extends StatelessWidget {
  const _Pager({
    required this.page,
    required this.pageCount,
    required this.shown,
    required this.total,
    required this.onPage,
  });

  final int page;
  final int pageCount;
  final int shown;
  final int total;
  final ValueChanged<int> onPage;

  @override
  Widget build(BuildContext context) {
    // Show up to five page numbers, then an ellipsis and the last page.
    final numbers = <int?>[
      for (var i = 0; i < pageCount && i < 5; i++) i,
      if (pageCount > 6) null,
      if (pageCount > 5) pageCount - 1,
    ];
    final isLast = page >= pageCount - 1;

    return DecoratedBox(
      decoration: const BoxDecoration(
        color: ObrColors.gray0,
        border: Border(top: BorderSide(color: ObrColors.gray200)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            ObrSpace.s16,
            ObrSpace.s8,
            ObrSpace.s16,
            ObrSpace.s8,
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          for (final n in numbers)
                            n == null
                                ? const Padding(
                                    padding: EdgeInsets.symmetric(
                                      horizontal: ObrSpace.s4,
                                    ),
                                    child: Text('…'),
                                  )
                                : Semantics(
                                    button: true,
                                    selected: n == page,
                                    label: 'Page ${n + 1}',
                                    excludeSemantics: true,
                                    child: InkWell(
                                      onTap: () => onPage(n),
                                      child: ConstrainedBox(
                                        constraints: const BoxConstraints(
                                          minWidth: ObrSize.s32,
                                          minHeight: ObrSize.s32,
                                        ),
                                        child: Center(
                                          child: Text(
                                            '${n + 1}',
                                            style: n == page
                                                ? ObrType.bodyLgSemibold
                                                : ObrType.bodyLgBook.copyWith(
                                                    decoration: TextDecoration
                                                        .underline,
                                                  ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                        ],
                      ),
                    ),
                    Text(
                      '$shown of $total results',
                      style: ObrType.bodyMdBook.copyWith(
                        color: ObrColors.gray700,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: ObrSpace.s12),
              FilledButton(
                onPressed: isLast ? null : () => onPage(page + 1),
                style: FilledButton.styleFrom(
                  backgroundColor: ObrColors.gray100,
                  foregroundColor: ObrColors.gray800,
                  minimumSize: const Size(104, ObrSize.s44),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(ObrRadius.r4),
                  ),
                ),
                child: const Text('Next'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
