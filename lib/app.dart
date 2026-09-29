import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:quick_actions/quick_actions.dart';

import 'app_shortcuts.dart';
import 'router.dart';
import 'state/app_session.dart';
import 'state/balance_visibility.dart';
import 'state/nav_version.dart';
import 'state/recent_searches.dart';
import 'theme/obr_theme.dart';

class InvestorsEdgeApp extends StatefulWidget {
  const InvestorsEdgeApp({super.key, this.initialLocation = AppRoutes.signOn});

  /// Where the app opens: Sign On in the app, Home in most widget tests.
  /// Starting anywhere other than Sign On counts as signed on.
  final String initialLocation;

  @override
  State<InvestorsEdgeApp> createState() => InvestorsEdgeAppState();
}

class InvestorsEdgeAppState extends State<InvestorsEdgeApp> {
  // Owned by the app instance (not a global) so tests and hot restarts
  // always start from a fresh navigation stack.
  late final GoRouter _router =
      createRouter(initialLocation: widget.initialLocation);

  late final AppSession _session =
      AppSession(signedIn: widget.initialLocation != AppRoutes.signOn);

  /// Hide-balances toggle, shared app-wide (see [BalanceVisibility]).
  final ValueNotifier<bool> _balancesHidden = ValueNotifier(false);

  /// Navigation scheme under test, switched in Profile & Settings.
  final ValueNotifier<NavVersion> _navVersion =
      ValueNotifier(NavVersion.searchOnly);

  /// For widget tests that jump straight to a navigation version.
  @visibleForTesting
  ValueNotifier<NavVersion> get navVersion => _navVersion;

  /// Recent searches, shared by every visit to Search.
  final RecentSearches _recentSearches = RecentSearches();

  @override
  void initState() {
    super.initState();
    _setUpShortcuts();
  }

  /// Registers the launcher-icon shortcuts. Platforms without the plugin
  /// (widget tests, web, desktop) are skipped.
  Future<void> _setUpShortcuts() async {
    const quickActions = QuickActions();
    try {
      await quickActions.initialize(handleShortcut);
      await quickActions.setShortcutItems([
        for (final s in AppShortcut.values)
          ShortcutItem(type: s.type, localizedTitle: s.title),
      ]);
    } on MissingPluginException {
      // No platform implementation (tests, web, desktop).
    } on PlatformException {
      // Shortcuts are a nicety; never block the app on them.
    }
  }

  /// Opens a shortcut's destination. Signed on: straight there (with Home
  /// underneath, so Back returns Home). Signed out: Sign On first, then the
  /// destination after the signing-in screen.
  void handleShortcut(String type) {
    final shortcut = AppShortcut.fromType(type);
    if (shortcut == null) return;
    if (_session.signedIn) {
      _router.go(shortcut.location);
    } else {
      _session.pendingLocation = shortcut.location;
      _router.go(AppRoutes.signOn);
    }
  }

  @override
  void dispose() {
    _router.dispose();
    _session.dispose();
    _balancesHidden.dispose();
    _recentSearches.dispose();
    _navVersion.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: "Investor's Edge",
      debugShowCheckedModeBanner: false,
      theme: ObrTheme.light(),
      routerConfig: _router,
      builder: (context, child) => AppSessionScope(
        session: _session,
        child: RecentSearchesScope(
          searches: _recentSearches,
          child: NavVersionScope(
            version: _navVersion,
            child: BalanceVisibility(hidden: _balancesHidden, child: child!),
          ),
        ),
      ),
    );
  }
}
