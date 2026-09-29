import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../../data/mock_portfolio.dart';
import '../../router.dart';
import '../../theme/obr_tokens.dart';
import '../../theme/obr_typography.dart';
import '../../state/nav_version.dart';
import '../../widgets/app_nav_bar.dart';
import '../../widgets/size_reporter.dart';
import 'widgets/auto_investing_card.dart';
import 'widgets/bottom_dock.dart';
import 'widgets/financial_progress_card.dart';
import 'widgets/portfolio_summary_card.dart';
import 'widgets/portfolio_tabs_card.dart';
import 'widgets/quick_actions.dart';
import 'widgets/recent_activity_card.dart';
import 'widgets/watchlists_card.dart';

/// Content column width cap. On tablets and unfolded foldables the phone
/// layout stays centred for now. The next step is a navigation rail and
/// two-pane layout at 840dp and up.
const double _maxContentWidth = 640;

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final ScrollController _scrollController = ScrollController();

  /// Recent activity's height; Watchlists matches it.
  final ValueNotifier<double?> _activityHeight = ValueNotifier(null);

  @override
  void dispose() {
    _scrollController.dispose();
    _activityHeight.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Version A: floating search button and the three action buttons.
    // B–D: a bottom bar carries search and the actions instead.
    final searchOnly =
        NavVersionScope.versionOf(context) == NavVersion.searchOnly;
    final bottomInset = MediaQuery.paddingOf(context).bottom;
    final dockClearance = searchOnly
        ? BottomDock.height + ObrSpace.s12 + bottomInset
        : 0.0;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      // Edge-to-edge with dark system icons on the light background.
      value: SystemUiOverlayStyle.dark.copyWith(
        statusBarColor: Colors.transparent,
        systemNavigationBarColor: Colors.transparent,
        systemNavigationBarContrastEnforced: false,
      ),
      child: Scaffold(
        bottomNavigationBar: searchOnly
            ? null
            : const AppNavBar(current: NavDestination.home),
        body: Stack(
          children: [
            SafeArea(
              bottom: false,
              child: Align(
                alignment: Alignment.topCenter,
                child: ConstrainedBox(
                  constraints:
                      const BoxConstraints(maxWidth: _maxContentWidth),
                  child: ListView(
                    controller: _scrollController,
                    padding: EdgeInsets.fromLTRB(
                      ObrSpace.s20,
                      ObrSpace.s16,
                      ObrSpace.s20,
                      dockClearance + ObrSpace.s32,
                    ),
                    children: [
                      const _Header(),
                      const SizedBox(height: ObrSpace.s24),
                      const PortfolioSummaryCard(),
                      const SizedBox(height: ObrSpace.s20),
                      if (searchOnly) ...[
                        const QuickActions(),
                        const SizedBox(height: ObrSpace.s16),
                      ],
                      const PortfolioTabsCard(),
                      const SizedBox(height: ObrSpace.s16),
                      SizeReporter(
                        height: _activityHeight,
                        child: const RecentActivityCard(),
                      ),
                      const SizedBox(height: ObrSpace.s16),
                      WatchlistsCard(height: _activityHeight),
                      const SizedBox(height: ObrSpace.s16),
                      const AutoInvestingCard(),
                      const SizedBox(height: ObrSpace.s16),
                      const FinancialProgressCard(),
                    ],
                  ),
                ),
              ),
            ),
            // Scroll-edge fade so content softens as it passes under the dock.
            if (searchOnly)
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              height: dockClearance + ObrSpace.s40,
              child: const IgnorePointer(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Color(0x00FAFAFA), Color(0xEBFAFAFA)],
                    ),
                  ),
                ),
              ),
            ),
            if (searchOnly)
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: Align(
                alignment: Alignment.bottomCenter,
                heightFactor: 1,
                child: ConstrainedBox(
                  constraints:
                      const BoxConstraints(maxWidth: _maxContentWidth),
                  child: const BottomDock(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header();

  static String _greeting(DateTime now) {
    if (now.hour < 12) return 'Good morning';
    if (now.hour < 18) return 'Good afternoon';
    return 'Good evening';
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Semantics(
                header: true,
                // 75% of the previous 32pt title.
                child: Text(
                  "Investor's Edge",
                  style: ObrType.headingLgSemibold.copyWith(
                    color: ObrColors.gray900,
                  ),
                ),
              ),
              const SizedBox(height: ObrSpace.s2),
              Text(
                '${_greeting(DateTime.now())}, ${MockPortfolio.firstName}.',
                style: ObrType.bodyLgBook.copyWith(color: ObrColors.gray600),
              ),
            ],
          ),
        ),
        const SizedBox(width: ObrSpace.s12),
        _HeaderButton(
          tooltip: "Notifications and what's new",
          icon: Icons.notifications_none,
          onTap: () => context.push(AppRoutes.notifications),
        ),
        const SizedBox(width: ObrSpace.s8),
        _HeaderButton(
          tooltip: 'Profile and settings',
          icon: Icons.person_outline,
          onTap: () => context.push(AppRoutes.profile),
        ),
      ],
    );
  }
}

/// Round gray icon button in the header (44pt target).
class _HeaderButton extends StatelessWidget {
  const _HeaderButton({
    required this.tooltip,
    required this.icon,
    required this.onTap,
  });

  final String tooltip;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: tooltip,
      onPressed: onTap,
      icon: Icon(icon),
      iconSize: ObrSize.s24,
      color: ObrColors.gray700,
      style: IconButton.styleFrom(
        backgroundColor: ObrColors.gray100,
        fixedSize: const Size.square(ObrSize.s44),
      ),
    );
  }
}
