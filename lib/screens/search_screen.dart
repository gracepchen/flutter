import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../data/mock_portfolio.dart';
import '../router.dart';
import '../state/recent_searches.dart';
import '../widgets/app_nav_bar.dart';
import '../theme/obr_tokens.dart';
import '../theme/obr_typography.dart';
import '../widgets/prototype_notice.dart';
import 'home/widgets/bottom_dock.dart';
import 'search/market_overview.dart';
import 'search/recent_search_chips.dart';
import 'search/next_move_links.dart';

/// Search. The home pill morphs into this field (shared Hero), results
/// filter a small mock list of securities, and a result opens its details.
class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  /// Brings the keyboard up on the Search page containing [context] (the
  /// bottom bar's search icon uses this). Does nothing elsewhere.
  static void focusField(BuildContext context) =>
      context.findAncestorStateOfType<_SearchScreenState>()?._focusField();

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _controller = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _controller.dispose();
    _focus.dispose();
    super.dispose();
  }

  void _setQuery(String value) {
    _controller.value = TextEditingValue(
      text: value,
      selection: TextSelection.collapsed(offset: value.length),
    );
    setState(() => _query = value);
  }

  final FocusNode _focus = FocusNode();

  void _focusField() {
    if (_focus.hasFocus) {
      // Focused but the keyboard was put away (e.g. Android back).
      SystemChannels.textInput.invokeMethod<void>('TextInput.show');
    } else {
      _focus.requestFocus();
    }
  }

  /// Opens the security's details on top of Search. Coming back (Back button
  /// or gesture) returns to a blank search with the field focused, ready
  /// for the next symbol.
  Future<void> _openQuote(Security security) async {
    _focus.unfocus();
    await context.push('${AppRoutes.quote}/${security.symbol}');
    if (!mounted) return;
    _setQuery('');
    _focus.requestFocus();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Nav/IA versions B–D: the bottom bar, compact here (B and C).
      bottomNavigationBar: const AppNavBar(current: NavDestination.search),
      // Tapping anywhere that isn't a control puts the keyboard away.
      body: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTap: () => _focus.unfocus(),
        child: SafeArea(
        child: Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 640),
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    ObrSpace.s8,
                    ObrSpace.s8,
                    ObrSpace.s16,
                    ObrSpace.s8,
                  ),
                  child: Row(
                    children: [
                      IconButton(
                        tooltip: 'Close search',
                        icon: const Icon(Icons.arrow_back),
                        onPressed: () => context.pop(),
                      ),
                      const SizedBox(width: ObrSpace.s4),
                      Expanded(child: _buildField()),
                    ],
                  ),
                ),
                Expanded(child: _buildBody()),
              ],
            ),
          ),
        ),
      ),
      ),
    );
  }

  Widget _buildField() {
    return Hero(
      tag: searchHeroTag,
      // Fly a static pill rather than a live TextField between routes.
      flightShuttleBuilder: (flightContext, animation, direction, fromContext,
              toContext) =>
          const SearchPillSurface(opaque: true, child: SearchPillLabel()),
      child: SearchPillSurface(
        opaque: true,
        child: Padding(
          padding: const EdgeInsets.only(left: ObrSpace.s24, right: ObrSpace.s8),
          child: Row(
            children: [
              const Icon(Icons.search, color: ObrColors.gray700, size: 26),
              const SizedBox(width: ObrSpace.s12),
              Expanded(
                child: TextField(
                  controller: _controller,
                  focusNode: _focus,
                  autofocus: true,
                  textInputAction: TextInputAction.search,
                  cursorColor: ObrColors.brand600,
                  style: ObrType.bodyLg,
                  onChanged: (value) => setState(() => _query = value),
                  decoration: InputDecoration(
                    isCollapsed: true,
                    border: InputBorder.none,
                    hintText: 'Search stock or ETF',
                    hintStyle: ObrType.bodyLgBook.copyWith(
                      color: ObrColors.gray500,
                    ),
                  ),
                ),
              ),
              if (_query.isNotEmpty)
                IconButton(
                  tooltip: 'Clear search',
                  icon: const Icon(Icons.close, color: ObrColors.gray600),
                  onPressed: () => _setQuery(''),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBody() {
    const padding = EdgeInsets.fromLTRB(
      ObrSpace.s20,
      ObrSpace.s16,
      ObrSpace.s20,
      ObrSpace.s32,
    );

    if (_query.trim().isEmpty) {
      return ListView(
        padding: padding,
        children: [
          const _SectionLabel('RECENT SEARCHES'),
          const SizedBox(height: ObrSpace.s12),
          RecentSearchChips(onOpen: _openQuote),
          const SizedBox(height: ObrSpace.s32),
          const _SectionLabel('MARKET OVERVIEW'),
          const SizedBox(height: ObrSpace.s12),
          const MarketOverviewCarousel(),
          const SizedBox(height: ObrSpace.s32),
          const _SectionLabel('FIND YOUR NEXT MOVE'),
          const SizedBox(height: ObrSpace.s12),
          const NextMoveLinks(),
          const SizedBox(height: ObrSpace.s24),
          const PrototypeNotice(
            message: 'Prototype: results come from a short mock list of '
                'securities, market values are simulated, and the browse '
                'links are not built yet.',
          ),
        ],
      );
    }

    final results = MockSecurities.search(_query);
    if (results.isEmpty) {
      return ListView(
        padding: padding,
        children: [
          Text(
            'No matches for "${_query.trim()}"',
            style: ObrType.bodyLgBook.copyWith(color: ObrColors.gray700),
          ),
        ],
      );
    }

    return ListView.separated(
      padding: padding,
      itemCount: results.length,
      separatorBuilder: (_, __) => const Divider(),
      itemBuilder: (context, index) {
        final security = results[index];
        return MergeSemantics(
          child: Semantics(
            button: true,
            child: InkWell(
              onTap: () {
                // A search result goes to the front of Recent searches.
                RecentSearchesScope.read(context).add(security.symbol);
                _openQuote(security);
              },
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: ObrSpace.s12),
                child: Row(
                  children: [
                    SizedBox(
                      width: 64,
                      child: Text(security.symbol, style: ObrType.bodyLgSemibold),
                    ),
                    Expanded(
                      child: Text(
                        security.name,
                        style: ObrType.bodyMdBook.copyWith(
                          color: ObrColors.gray700,
                        ),
                      ),
                    ),
                    const SizedBox(width: ObrSpace.s12),
                    Text(
                      security.exchange,
                      style: ObrType.caption.copyWith(color: ObrColors.gray600),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      header: true,
      child: Text(
        text,
        style: ObrType.captionSemibold.copyWith(
          color: ObrColors.gray600,
          letterSpacing: 1.2,
        ),
      ),
    );
  }
}
