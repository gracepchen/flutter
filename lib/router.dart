import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'screens/account_settings_list_screen.dart';
import 'screens/action_screens.dart';
import 'screens/fractional/fractional_screen.dart';
import 'screens/holdings/holdings_screen.dart';
import 'screens/home/home_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/quote/quote_screen.dart';
import 'screens/search_screen.dart';
import 'screens/sign_on/sign_on_screen.dart';
import 'screens/sign_on/signing_in_screen.dart';
import 'theme/obr_tokens.dart';

abstract final class AppRoutes {
  static const String home = '/';
  static const String signOn = '/sign-on';
  static const String signingIn = '/signing-in';
  static const String watchlists = '/watchlists';
  static const String fractional = '/fractional';
  static const String add = '/add';
  static const String transfer = '/transfer';
  static const String trade = '/trade';
  static const String search = '/search';
  static const String holdings = '/holdings';
  static const String contributions = '/contributions';
  static const String accountSettings = '/account-settings';
  static const String activity = '/activity';
  static const String performance = '/performance';
  static const String quote = '/quote';
  static const String advancedChart = '/advanced-chart';
  static const String profile = '/profile';
  static const String notifications = '/notifications';
}

/// Every screen is declared here, so every route is deep-linkable
/// (e.g. a push notification opening `/activity`).
///
/// Next step: add a `redirect` that checks the session, with
/// `refreshListenable` on the auth state. Then every route, including deep
/// links, passes one sign-in and biometric check.
///
/// The app opens on Sign On. Tests pass [initialLocation] to start on Home.
GoRouter createRouter({String initialLocation = AppRoutes.signOn}) {
  return GoRouter(
    initialLocation: initialLocation,
    routes: [
      GoRoute(
        path: AppRoutes.signOn,
        builder: (context, state) => const SignOnScreen(),
      ),
      GoRoute(
        path: AppRoutes.signingIn,
        // Quick fade in, matching the system Face ID moment.
        pageBuilder: (context, state) => CustomTransitionPage<void>(
          key: state.pageKey,
          child: const SigningInScreen(),
          transitionDuration: MediaQuery.disableAnimationsOf(context)
              ? Duration.zero
              : ObrDuration.d200,
          transitionsBuilder: (context, animation, secondaryAnimation, child) =>
              FadeTransition(opacity: animation, child: child),
        ),
      ),
      GoRoute(
        path: AppRoutes.home,
        builder: (context, state) => const HomeScreen(),
        routes: [
          GoRoute(
            path: 'add',
            builder: (context, state) => AddScreen(
              account: state.uri.queryParameters['account'],
              type: state.uri.queryParameters['type'],
            ),
          ),
          GoRoute(
            path: 'transfer',
            builder: (context, state) => TransferScreen(
              account: state.uri.queryParameters['account'],
            ),
          ),
          GoRoute(
            path: 'trade',
            builder: (context, state) => TradeScreen(
              symbol: state.uri.queryParameters['symbol'],
              side: state.uri.queryParameters['side'],
              account: state.uri.queryParameters['account'],
            ),
          ),
          GoRoute(
            path: 'search',
            // Fade instead of a platform push, so the search pill's Hero
            // morph reads as one continuous element.
            pageBuilder: (context, state) {
              final reduceMotion = MediaQuery.disableAnimationsOf(context);
              return CustomTransitionPage<void>(
                key: state.pageKey,
                child: const SearchScreen(),
                transitionDuration:
                    reduceMotion ? Duration.zero : ObrDuration.d300,
                reverseTransitionDuration:
                    reduceMotion ? Duration.zero : ObrDuration.d250,
                transitionsBuilder:
                    (context, animation, secondaryAnimation, child) =>
                        FadeTransition(
                  opacity: CurvedAnimation(
                    parent: animation,
                    curve: ObrEasing.easeOut,
                  ),
                  child: child,
                ),
              );
            },
          ),
          GoRoute(
            path: 'quote/:symbol',
            builder: (context, state) {
              final symbol = state.pathParameters['symbol']!;
              // Keyed by symbol so opening a different security builds a
              // fresh screen instead of reusing the previous one's state.
              return QuoteScreen(key: ValueKey(symbol), symbol: symbol);
            },
          ),
          GoRoute(
            path: 'advanced-chart',
            builder: (context, state) => AdvancedChartScreen(
              symbol: state.uri.queryParameters['symbol'],
            ),
          ),
          GoRoute(
            path: 'performance',
            builder: (context, state) => const PerformanceScreen(),
          ),
          GoRoute(
            path: 'account-settings',
            // No account: the list of accounts. With ?account=: that
            // account's settings.
            builder: (context, state) {
              final account = state.uri.queryParameters['account'];
              return account == null
                  ? const AccountSettingsListScreen()
                  : AccountSettingsScreen(account: account);
            },
          ),
          GoRoute(
            path: 'contributions',
            builder: (context, state) => const ContributionsScreen(),
          ),
          GoRoute(
            path: 'holdings',
            builder: (context, state) => HoldingsScreen(
              initialAccount: state.uri.queryParameters['account'],
            ),
          ),
          GoRoute(
            path: 'fractional',
            builder: (context, state) => const FractionalScreen(),
          ),
          GoRoute(
            path: 'watchlists',
            builder: (context, state) => const WatchlistsScreen(),
          ),
          GoRoute(
            path: 'activity',
            builder: (context, state) => const ActivityScreen(),
          ),
          GoRoute(
            path: 'notifications',
            builder: (context, state) => const NotificationsScreen(),
          ),
          GoRoute(
            path: 'profile',
            builder: (context, state) => const ProfileScreen(),
          ),
        ],
      ),
    ],
  );
}
