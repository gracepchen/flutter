import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:investors_edge_prototype/app.dart';
import 'package:investors_edge_prototype/data/mock_portfolio.dart';
import 'package:investors_edge_prototype/router.dart';
import 'package:investors_edge_prototype/state/nav_version.dart';
import 'package:investors_edge_prototype/util/format.dart';
import 'package:investors_edge_prototype/screens/holdings/holdings_screen.dart';
import 'package:investors_edge_prototype/screens/home/widgets/financial_progress_card.dart';
import 'package:investors_edge_prototype/screens/quote/quote_screen.dart';
import 'package:investors_edge_prototype/screens/home/widgets/auto_investing_card.dart';
import 'package:investors_edge_prototype/screens/home/widgets/recent_activity_card.dart';
import 'package:investors_edge_prototype/screens/home/widgets/top_holdings_list.dart';
import 'package:investors_edge_prototype/screens/home/widgets/watchlists_card.dart';
import 'package:investors_edge_prototype/widgets/size_reporter.dart';
import 'package:investors_edge_prototype/screens/search/recent_search_chips.dart';
import 'package:investors_edge_prototype/widgets/ie_logo.dart';
import 'package:investors_edge_prototype/widgets/obr_card.dart';
import 'package:investors_edge_prototype/widgets/swipe_reveal_row.dart';

// Note: flutter test renders text in the "Ahem" test font, where every glyph
// is a full square. Text is much wider than in Whitney or Arial, so layouts
// run longer than on a device. The tests scroll to what they need instead of
// assuming positions.

Future<void> pumpApp(
  WidgetTester tester, {
  bool reduceMotion = true,
  bool liveQuotes = false,
}) async {
  // Top holdings prices tick in real time; off by default so figures stay at
  // their mock values. One test turns it on.
  TopHoldingsList.liveUpdates = liveQuotes;
  addTearDown(() => TopHoldingsList.liveUpdates = true);
  // iPhone-sized viewport: 390 × 844 logical pixels.
  tester.view.physicalSize = const Size(1170, 2532);
  tester.view.devicePixelRatio = 3.0;
  addTearDown(tester.view.reset);
  // Reduce Motion on by default: animations finish instantly and the Market
  // Overview carousel doesn't auto-scroll forever, so pumpAndSettle can
  // settle. Tests of motion itself pass reduceMotion: false.
  tester.platformDispatcher.accessibilityFeaturesTestValue =
      FakeAccessibilityFeatures(disableAnimations: reduceMotion);
  addTearDown(tester.platformDispatcher.clearAccessibilityFeaturesTestValue);
  await tester.pumpWidget(const InvestorsEdgeApp(initialLocation: AppRoutes.home));
  await tester.pumpAndSettle();
}

/// Scrolls the home list until [finder] is built, then places it about a
/// third of the way down the screen, clear of the floating bottom dock.
Future<void> bringIntoView(WidgetTester tester, Finder finder) async {
  await tester.scrollUntilVisible(
    finder,
    200,
    scrollable: find.byType(Scrollable).first,
  );
  await Scrollable.ensureVisible(tester.element(finder), alignment: 0.3);
  await tester.pumpAndSettle();
}

/// Opens search: the floating search button on Home or, on stock details
/// opened from search, Back (which returns to a blank search).
Future<void> tapSearch(WidgetTester tester) async {
  final homeButton = find.byTooltip('Search stocks and ETFs');
  await tester.tap(
    homeButton.evaluate().isNotEmpty ? homeButton : find.byTooltip('Back'),
  );
}

void main() {
  testWidgets('App opens on Sign On; signing-in shows for 900ms, then Home',
      (tester) async {
    tester.view.physicalSize = const Size(1170, 2532);
    tester.view.devicePixelRatio = 3.0;
    addTearDown(tester.view.reset);
    // Reduce Motion keeps the mark still, so frames settle.
    tester.platformDispatcher.accessibilityFeaturesTestValue =
        const FakeAccessibilityFeatures(disableAnimations: true);
    addTearDown(tester.platformDispatcher.clearAccessibilityFeaturesTestValue);
    await tester.pumpWidget(const InvestorsEdgeApp());
    await tester.pumpAndSettle();

    expect(find.text('Sign on'), findsOneWidget);

    await tester.tap(find.text('Sign on'));
    await tester.pump();
    await tester.pump();
    // Signing-in screen: the mark, no Home yet.
    expect(find.byType(IeMark), findsOneWidget);
    expect(find.textContaining('Taylor'), findsNothing);

    // Still signing in just before 900ms.
    await tester.pump(const Duration(milliseconds: 850));
    expect(find.byType(IeMark), findsOneWidget);

    await tester.pump(const Duration(milliseconds: 100));
    await tester.pumpAndSettle();
    expect(find.textContaining('Taylor'), findsOneWidget);
    expect(find.byType(IeMark), findsNothing);
  });

  testWidgets('Shortcut while signed on goes straight to its page',
      (tester) async {
    await pumpApp(tester);
    final app = tester.state<InvestorsEdgeAppState>(
      find.byType(InvestorsEdgeApp),
    );

    app.handleShortcut('trade');
    await tester.pumpAndSettle();
    expect(find.textContaining('Buy and sell stocks'), findsOneWidget);

    app.handleShortcut('add_funds');
    await tester.pumpAndSettle();
    expect(find.textContaining('Deposit money'), findsOneWidget);

    app.handleShortcut('view_assets');
    await tester.pumpAndSettle();
    expect(find.byType(AccountFilter), findsOneWidget);

    // Home is underneath, so Back returns there.
    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(find.textContaining('Taylor'), findsOneWidget);

    // Quick Quote: blank search with the field focused.
    app.handleShortcut('quick_quote');
    await tester.pumpAndSettle();
    expect(find.text('RECENT SEARCHES'), findsOneWidget);
    final field = tester.widget<EditableText>(find.byType(EditableText));
    expect(field.controller.text, isEmpty);
    expect(field.focusNode.hasFocus, isTrue);
  });


  testWidgets('Shortcut while signed out signs on first, then opens it',
      (tester) async {
    tester.view.physicalSize = const Size(1170, 2532);
    tester.view.devicePixelRatio = 3.0;
    addTearDown(tester.view.reset);
    tester.platformDispatcher.accessibilityFeaturesTestValue =
        const FakeAccessibilityFeatures(disableAnimations: true);
    addTearDown(tester.platformDispatcher.clearAccessibilityFeaturesTestValue);
    await tester.pumpWidget(const InvestorsEdgeApp());
    await tester.pumpAndSettle();

    tester
        .state<InvestorsEdgeAppState>(find.byType(InvestorsEdgeApp))
        .handleShortcut('trade');
    await tester.pumpAndSettle();
    expect(find.text('Sign on'), findsOneWidget);

    await tester.tap(find.text('Sign on'));
    await tester.pump();
    await tester.pump();
    expect(find.byType(IeMark), findsOneWidget);

    await tester.pump(const Duration(milliseconds: 950));
    await tester.pumpAndSettle();
    expect(find.textContaining('Buy and sell stocks'), findsOneWidget);

    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(find.textContaining('Taylor'), findsOneWidget);
  });

  testWidgets('Watchlists card sits after Recent activity at the same height',
      (tester) async {
    await pumpApp(tester);

    await bringIntoView(tester, find.text('Watchlists'));
    expect(
      tester.getTopLeft(find.text('Watchlists')).dy,
      greaterThan(tester.getTopLeft(find.text('Recent activity')).dy),
    );
    Finder cardOf(String title) => find
        .ancestor(of: find.text(title), matching: find.byType(ObrCard))
        .first;
    expect(
      tester.getSize(cardOf('Watchlists')).height,
      closeTo(tester.getSize(cardOf('Recent activity')).height, 0.5),
    );
    expect(find.text('Content TBD'), findsOneWidget);

    await tester.tap(
      find.descendant(
        of: cardOf('Watchlists'),
        matching: find.text('See all'),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Watchlists'), findsWidgets);
    expect(find.textContaining('Content TBD'), findsOneWidget);
  });

  testWidgets('Signing-in mark spins clockwise', (tester) async {
    tester.view.physicalSize = const Size(1170, 2532);
    tester.view.devicePixelRatio = 3.0;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(const InvestorsEdgeApp());
    await tester.pumpAndSettle();

    await tester.tap(find.text('Sign on'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 150));

    final spin = tester.widget<RotationTransition>(
      find.ancestor(
        of: find.byType(IeMark),
        matching: find.byType(RotationTransition),
      ),
    );
    // Positive turns = clockwise.
    expect(spin.turns.value, greaterThan(0));

    await tester.pump(const Duration(milliseconds: 800));
    await tester.pumpAndSettle();
    expect(find.textContaining('Taylor'), findsOneWidget);
  });




  testWidgets('Home renders the portfolio summary', (tester) async {
    await pumpApp(tester);

    expect(find.text("Investor's Edge"), findsOneWidget);
    expect(find.text(r'$124,820.42'), findsOneWidget);
    expect(find.text(r'+$1,284.20 (+1.04%) today'), findsOneWidget);

    await bringIntoView(tester, find.text('TFSA'));
    expect(find.text('TFSA'), findsOneWidget);
  });

  testWidgets('Chart chevron opens Performance', (tester) async {
    await pumpApp(tester);

    await tester.tap(find.byTooltip('View performance'));
    await tester.pumpAndSettle();

    expect(find.textContaining('rate of return'), findsOneWidget);
  });

  testWidgets('Range selector updates the change label', (tester) async {
    await pumpApp(tester);

    await bringIntoView(tester, find.text('1W'));
    await tester.tap(find.text('1W'));
    await tester.pumpAndSettle();

    expect(find.textContaining('past week'), findsOneWidget);
  });

  testWidgets('Quick actions open their placeholder screens', (tester) async {
    await pumpApp(tester);

    for (final (label, summaryStart) in [
      ('Move money', 'Move money between'),
      ('Trade', 'Buy and sell'),
      ('Activity', 'Track the progress'),
    ]) {
      await bringIntoView(tester, find.text(label));
      await tester.tap(find.text(label));
      await tester.pumpAndSettle();
      expect(find.textContaining(summaryStart), findsOneWidget);

      await tester.pageBack();
      await tester.pumpAndSettle();
    }
  });

  testWidgets('Accounts toggle switches between Total and Cash only',
      (tester) async {
    await pumpApp(tester);

    await bringIntoView(tester, find.text('Cash only'));
    expect(find.text('58204417'), findsOneWidget);
    expect(find.text('FHSA'), findsOneWidget);
    expect(find.text('RESP'), findsOneWidget);
    expect(find.textContaining('USDCAD=1.40123'), findsOneWidget);
    expect(find.textContaining('Last updated'), findsOneWidget);

    // Total is the default.
    expect(find.text('34,726.81'), findsOneWidget);
    expect(find.text('123.52 CAD'), findsNothing);

    // Tapping anywhere on the toggle flips it.
    await tester.tap(find.text('Total'));
    await tester.pumpAndSettle();
    expect(find.text('123.52 CAD'), findsOneWidget);
    expect(find.text('238.15 USD'), findsOneWidget);
    expect(find.text('34,726.81'), findsNothing);

    await tester.tap(find.text('Cash only'));
    await tester.pumpAndSettle();
    expect(find.text('34,726.81'), findsOneWidget);
  });

  testWidgets('Swiping an account reveals Manage, Transfer and Trade',
      (tester) async {
    await pumpApp(tester);

    await bringIntoView(tester, find.text('TFSA'));
    expect(find.text('Manage'), findsNothing);

    final row = find.ancestor(
      of: find.text('TFSA'),
      matching: find.byType(SwipeRevealRow),
    );
    final closedHeight = tester.getSize(row).height;

    await tester.drag(find.text('TFSA'), const Offset(-200, 0));
    await tester.pumpAndSettle();
    expect(find.text('Manage'), findsOneWidget);
    // Opening doesn't change the row's height.
    expect(tester.getSize(row).height, closedHeight);
    expect(
      find.byKey(const ValueKey('account-action-transfer')),
      findsOneWidget,
    );
    expect(find.byKey(const ValueKey('account-action-trade')), findsOneWidget);
    // Type and number stay visible; the figures are hidden.
    expect(find.text('58204417'), findsOneWidget);
    expect(find.text('34,726.81'), findsNothing);

    await tester.tap(find.text('Manage'));
    await tester.pumpAndSettle();
    expect(find.text('TFSA settings'), findsWidgets);

    await tester.pageBack();
    await tester.pumpAndSettle();
    await tester.drag(find.text('TFSA'), const Offset(-200, 0));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('account-action-transfer')));
    await tester.pumpAndSettle();
    expect(find.text('From account'), findsOneWidget);
  });

  testWidgets('Long-pressing an account shows its quick actions',
      (tester) async {
    await pumpApp(tester);

    await bringIntoView(tester, find.text('RRSP'));
    expect(find.text('Manage'), findsNothing);
    await tester.longPress(find.text('RRSP'));
    await tester.pumpAndSettle();
    expect(find.text('Manage'), findsOneWidget);
    expect(find.text('Transfer'), findsOneWidget);
    expect(find.text('Trade'), findsWidgets);

    // Tapping the row puts it back.
    await tester.tap(find.text('RRSP'));
    await tester.pumpAndSettle();
    expect(find.text('Manage'), findsNothing);
  });

  testWidgets('Profile switches to Nav B: bar with search and shortcuts',
      (tester) async {
    await pumpApp(tester);

    await tester.tap(find.byTooltip('Profile and settings'));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.text('B: Search with shortcuts'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    // Built but possibly still just below the screen: bring it fully on.
    await tester.ensureVisible(find.text('B: Search with shortcuts'));
    await tester.pumpAndSettle();
    expect(find.text('A: Search only'), findsOneWidget);
    await tester.tap(find.text('B: Search with shortcuts'));
    await tester.pumpAndSettle();
    await tester.pageBack();
    await tester.pumpAndSettle();

    // Bottom bar instead of the floating button and the action buttons.
    expect(find.byTooltip('Search stocks and ETFs'), findsNothing);
    expect(find.byTooltip('Search stocks & ETFs'), findsOneWidget);
    expect(find.text('Move money'), findsNothing);

    await tester.tap(find.byTooltip('Shortcuts'));
    await tester.pumpAndSettle();
    expect(find.text('Move money'), findsOneWidget);
    expect(find.text('Activity'), findsOneWidget);
    expect(find.text('Trade'), findsOneWidget);

    await tester.tap(find.text('Activity'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Track the progress'), findsOneWidget);
  });

  testWidgets('Nav C: search bar shrinks to icons on Search', (tester) async {
    await pumpApp(tester);
    tester
        .state<InvestorsEdgeAppState>(find.byType(InvestorsEdgeApp))
        .navVersion
        .value = NavVersion.actions;
    await tester.pumpAndSettle();

    expect(find.byTooltip('Transfers'), findsOneWidget);
    expect(find.byTooltip('Activity'), findsOneWidget);

    await tester.tap(find.byTooltip('Search stocks & ETFs'));
    await tester.pumpAndSettle();
    expect(find.text('RECENT SEARCHES'), findsOneWidget);
    final field = tester.widget<EditableText>(find.byType(EditableText));
    expect(field.focusNode.hasFocus, isTrue);
    // Compact bar: Home, Search, Transfers, Activity.
    expect(find.byTooltip('Home'), findsOneWidget);

    await tester.tap(find.byTooltip('Transfers'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Move money between'), findsOneWidget);
  });

  testWidgets('Nav D: tabs for Home, Explore, Move and Activity',
      (tester) async {
    await pumpApp(tester);
    tester
        .state<InvestorsEdgeAppState>(find.byType(InvestorsEdgeApp))
        .navVersion
        .value = NavVersion.tabs;
    await tester.pumpAndSettle();

    for (final label in ['Home', 'Explore', 'Move', 'Activity']) {
      expect(find.text(label), findsOneWidget, reason: label);
    }

    await tester.tap(find.text('Explore'));
    await tester.pumpAndSettle();
    expect(find.text('RECENT SEARCHES'), findsOneWidget);

    await tester.tap(find.text('Move'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Move money between'), findsOneWidget);

    await tester.tap(find.text('Home'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Taylor'), findsOneWidget);
  });

  testWidgets('Sign off on Profile returns to Sign On', (tester) async {
    await pumpApp(tester);

    await tester.tap(find.byTooltip('Profile and settings'));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.text('Sign off'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.ensureVisible(find.text('Sign off'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Sign off'));
    await tester.pumpAndSettle();

    expect(find.text('Sign on'), findsOneWidget);
    expect(find.textContaining('Taylor'), findsNothing);
  });

  testWidgets('All holdings link opens Holdings', (tester) async {
    await pumpApp(tester);

    await bringIntoView(tester, find.text('All holdings'));
    await tester.tap(find.text('All holdings'));
    await tester.pumpAndSettle();

    expect(find.byType(AccountFilter), findsOneWidget);
    expect(find.text('Stocks & ETFs'), findsOneWidget);
  });

  Future<void> openHoldings(WidgetTester tester) async {
    await bringIntoView(tester, find.text('All holdings'));
    await tester.tap(find.text('All holdings'));
    await tester.pumpAndSettle();
  }

  testWidgets('Holdings shows account pills, cash collapsed, stocks open',
      (tester) async {
    await pumpApp(tester);
    await openHoldings(tester);

    expect(find.text('All'), findsOneWidget);
    expect(find.text('TFSA 58204417'), findsOneWidget);
    expect(find.byType(DropdownButton<String?>), findsNothing);
    expect(find.text('Intraday change'), findsOneWidget);

    // Cash is collapsed: no currency rows yet.
    expect(find.text('CAD'), findsNothing);
    await tester.tap(find.text('Cash'));
    await tester.pumpAndSettle();
    expect(find.text('CAD'), findsOneWidget);

    // Stocks & ETFs is open, sorted by weight: CM (largest) first.
    expect(find.textContaining('Portfolio weight %'), findsOneWidget);
    final cmY = tester.getTopLeft(find.text('CM')).dy;
    final enbY = tester.getTopLeft(find.text('ENB')).dy;
    expect(cmY, lessThan(enbY));

    // Selecting an account shows the mock-data note.
    await tester.tap(find.text('TFSA 58204417'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Per-account holdings'), findsOneWidget);
  });

  testWidgets('Tapping an account on Home opens Holdings on that account',
      (tester) async {
    await pumpApp(tester);

    await bringIntoView(tester, find.text('RESP'));
    await tester.tap(find.text('RESP'));
    await tester.pumpAndSettle();

    expect(find.byType(AccountFilter), findsOneWidget);
    // The gear follows the selected pill.
    expect(find.byTooltip('RESP settings'), findsOneWidget);
    expect(find.textContaining('Per-account holdings'), findsOneWidget);

    await tester.tap(find.byTooltip('RESP settings'));
    await tester.pumpAndSettle();
    expect(find.text('RESP settings'), findsWidgets);
  });

  testWidgets('Holdings gear with All opens the Account Settings list',
      (tester) async {
    await pumpApp(tester);
    await openHoldings(tester);

    await tester.tap(find.byTooltip('Account settings'));
    await tester.pumpAndSettle();
    expect(find.text('Account Settings'), findsOneWidget);
    expect(find.text('MY ACCOUNTS'), findsOneWidget);
    expect(find.text('Open an account'), findsOneWidget);

    await tester.tap(find.text('FHSA 58204441'));
    await tester.pumpAndSettle();
    expect(find.text('FHSA settings'), findsWidgets);
  });

  testWidgets('Download holdings link sits below Stocks & ETFs',
      (tester) async {
    await pumpApp(tester);
    await openHoldings(tester);

    final link = find.text('Download holdings');
    await tester.scrollUntilVisible(
      link,
      200,
      scrollable: find.byType(Scrollable).first,
    );
    expect(
      tester.getTopLeft(link).dy,
      greaterThan(tester.getTopLeft(find.text('Stocks & ETFs')).dy),
    );
    await tester.tap(link);
    await tester.pump();
    expect(
      find.text('Download holdings is not built yet in this prototype.'),
      findsOneWidget,
    );
  });

  testWidgets('Add account pill opens the add-account sheet', (tester) async {
    await pumpApp(tester);
    await openHoldings(tester);

    // Sticky at the right: a "+" circle while more pills are to the right.
    final addAccount = find.byKey(const ValueKey('add-account'));
    expect(addAccount, findsOneWidget);
    expect(find.text('Add account'), findsNothing);

    // Scrolled to the end, it expands into the full pill.
    await tester.drag(
      find.descendant(
        of: find.byType(AccountFilter),
        matching: find.byType(Scrollable),
      ),
      const Offset(-3000, 0),
    );
    await tester.pumpAndSettle();
    expect(find.text('Add account'), findsOneWidget);

    await tester.tap(addAccount);
    await tester.pumpAndSettle();

    expect(find.byType(BottomSheet), findsOneWidget);
    expect(find.text('Link an existing account'), findsOneWidget);
    expect(find.text('Open a new account'), findsOneWidget);

    await tester.tap(find.text('Link an existing account'));
    await tester.pumpAndSettle();
    expect(find.byType(BottomSheet), findsNothing);
    expect(
      find.text('Linking an account is not built yet in this prototype.'),
      findsOneWidget,
    );
  });

  testWidgets('Holdings accordion values are right-aligned', (tester) async {
    await pumpApp(tester);
    await openHoldings(tester);

    // Cash's short title mustn't pull its value left: both headers' values
    // end at the same x.
    double rightOf(String prefix) => tester
        .getTopRight(find.byWidgetPredicate((w) =>
            w is Text &&
            w.data != null &&
            w.data!.endsWith(' CAD') &&
            w.data!.startsWith(prefix)))
        .dx;
    final cashTotal = MockPortfolio.accounts.fold<double>(
          0,
          (sum, a) => sum + a.cashCad,
        ) +
        MockMarket.toCad(
          MockPortfolio.accounts.fold<double>(0, (sum, a) => sum + a.cashUsd),
          'USD',
        );
    final cashLabel = formatPrice(cashTotal);
    final stocksLabel = formatPrice(MockPortfolio.totalValue - cashTotal);
    expect(rightOf(cashLabel), closeTo(rightOf(stocksLabel), 1));
  });

  testWidgets('Holdings sort menu reorders Stocks & ETFs', (tester) async {
    await pumpApp(tester);
    await openHoldings(tester);

    await tester.tap(find.byTooltip('Sort holdings'));
    await tester.pumpAndSettle();
    for (final label in [
      r'Daily change $',
      'Daily change %',
      'Asset type',
      'Ticker',
      'Name',
      'Quantity',
      'Currency',
      'Price',
      'Market value change',
      'Total gain/loss',
    ]) {
      expect(find.text(label), findsOneWidget, reason: label);
    }
    // Tap the menu item itself (its title text isn't a hit-test target).
    final tickerItem = find.widgetWithText(
      CheckedPopupMenuItem<HoldingsSort>,
      'Ticker',
    );
    await tester.ensureVisible(tickerItem);
    await tester.pumpAndSettle();
    await tester.tap(tickerItem);
    await tester.pumpAndSettle();

    expect(find.text('Sort by Ticker'), findsOneWidget);
    final aaplY = tester.getTopLeft(find.text('AAPL')).dy;
    final xeqtY = tester.getTopLeft(find.text('XEQT')).dy;
    expect(aaplY, lessThan(xeqtY));
  });

  testWidgets('Account pills become a dropdown at 6 accounts',
      (tester) async {
    Account account(int i) => Account(
          name: 'Acct$i',
          number: '1000$i',
          value: 1,
          changePercent: 0,
          cashCad: 0,
          cashUsd: 0,
        );
    Widget filter(int count) => MaterialApp(
          home: Scaffold(
            body: AccountFilter(
              accounts: [for (var i = 0; i < count; i++) account(i)],
              selected: null,
              onSelected: (_) {},
            ),
          ),
        );

    await tester.pumpWidget(filter(5));
    expect(find.byType(DropdownButton<String?>), findsNothing);
    expect(find.text('All'), findsOneWidget);

    await tester.pumpWidget(filter(6));
    expect(find.byType(DropdownButton<String?>), findsOneWidget);
    expect(find.text('All accounts'), findsOneWidget);
  });

  Future<void> showTopHoldings(WidgetTester tester) async {
    await bringIntoView(tester, find.text('Top holdings'));
    await tester.tap(find.text('Top holdings'));
    await tester.pumpAndSettle();
    await bringIntoView(tester, find.text('CM'));
  }

  testWidgets('Tapping a holding opens its details', (tester) async {
    await pumpApp(tester);
    await showTopHoldings(tester);

    expect(find.textContaining('USDCAD=1.40123'), findsOneWidget);
    await tester.tap(find.text('CM'));
    await tester.pumpAndSettle();

    // Below the chart now, so it may not be built until scrolled to.
    await bringIntoView(tester, find.text('Day range'));
    expect(find.text('Day range'), findsOneWidget);
    expect(find.text('(250 shares held)'), findsOneWidget);
  });

  testWidgets('USDCAD rate lines up with the dollar amounts',
      (tester) async {
    await pumpApp(tester);

    await bringIntoView(tester, find.text('USDCAD=1.40123'));
    final rateRight = tester.getTopRight(find.text('USDCAD=1.40123')).dx;
    final amountRight = tester.getTopRight(find.text('12,932.83')).dx;
    expect(rateRight, closeTo(amountRight, 0.5));
    // And the date lines up with the account names.
    final dateLeft = tester
        .getTopLeft(find.textContaining('Last updated'))
        .dx;
    expect(dateLeft, closeTo(tester.getTopLeft(find.text('RESP')).dx, 0.5));
  });

  testWidgets('Holdings toggle switches between Total and Price',
      (tester) async {
    await pumpApp(tester);
    await showTopHoldings(tester);

    // Shares held replace the company name.
    expect(find.text('250 shares'), findsOneWidget);
    expect(find.text('Canadian Imperial Bank of Commerce'), findsNothing);
    expect(find.text('22,105.00 CAD'), findsOneWidget);
    // U.S. listings show their value in USD (40 AAPL × 231.44).
    await bringIntoView(tester, find.text('AAPL'));
    expect(find.text('9,257.60 USD'), findsOneWidget);

    await bringIntoView(tester, find.text('Price'));
    await tester.tap(find.text('Price'));
    await tester.pumpAndSettle();
    // Price per share, in the security's currency, with today's change.
    expect(find.text('231.44 USD'), findsOneWidget);
    expect(find.text('9,257.60 USD'), findsNothing);
    expect(find.text('250 shares'), findsOneWidget);

    // Each tab remembers its own choice. The segmented control scrolled
    // off-screen while reaching the toggle, so bring it back first.
    await bringIntoView(tester, find.text('My accounts'));
    await tester.tap(find.text('My accounts'));
    await tester.pumpAndSettle();
    expect(find.text('34,726.81'), findsOneWidget);
  });

  testWidgets('Top holdings values update in real time', (tester) async {
    await pumpApp(tester, liveQuotes: true);
    await showTopHoldings(tester);

    const start = [
      '22,105.00 CAD',
      '9,257.60 USD',
    ];
    for (final text in start) {
      expect(find.text(text), findsOneWidget);
    }
    // Ten ticks of simulated quotes.
    for (var i = 0; i < 10; i++) {
      await tester.pump(TopHoldingsList.tick);
    }
    final unchanged = start.where((t) => find.text(t).evaluate().isNotEmpty);
    expect(unchanged.length, lessThan(start.length));
  });


  testWidgets('Swiping a holding left reveals Buy and Sell', (tester) async {
    await pumpApp(tester);
    await showTopHoldings(tester);
    expect(find.text('Sell'), findsNothing);

    await tester.drag(find.text('CM'), const Offset(-200, 0));
    await tester.pumpAndSettle();
    expect(find.text('Buy'), findsOneWidget);
    expect(find.text('Sell'), findsOneWidget);

    await tester.tap(find.text('Sell'));
    await tester.pumpAndSettle();
    expect(find.text('Order'), findsOneWidget);
    expect(find.text('Sell'), findsOneWidget);
  });

  testWidgets('Make investing stress-free carousel swipes between cards',
      (tester) async {
    await pumpApp(tester);

    // Order check by position in Home's list, not on screen: the cards are
    // tall in the test font, so they're never all built at once.
    final home = tester.widget<ListView>(find.byType(ListView).first);
    final children =
        (home.childrenDelegate as SliverChildListDelegate).children;
    int indexOf(bool Function(Widget) test) => children.indexWhere(test);
    final activity = indexOf(
      (w) => w is SizeReporter && w.child is RecentActivityCard,
    );
    final watchlists = indexOf((w) => w is WatchlistsCard);
    final carousel = indexOf((w) => w is AutoInvestingCard);
    expect(activity, isNonNegative);
    expect(watchlists, greaterThan(activity));
    expect(carousel, greaterThan(watchlists));

    await bringIntoView(tester, find.text('Make investing stress-free'));
    // "Reinvest dividends" also appears in Financial progress below,
    // so look only inside the carousel.
    Finder inCarousel(String text) => find.descendant(
          of: find.byType(PageView),
          matching: find.text(text),
        );

    expect(inCarousel('Auto-deposit'), findsOneWidget);
    // The second card peeks in from the right.
    expect(inCarousel('Reinvest dividends'), findsOneWidget);

    // Swipe left twice to reach the FHSA article.
    await tester.drag(inCarousel('Auto-deposit'), const Offset(-300, 0));
    await tester.pumpAndSettle();
    await tester.drag(inCarousel('Reinvest dividends'), const Offset(-300, 0));
    await tester.pumpAndSettle();
    expect(find.text("What's an FHSA?"), findsOneWidget);

    await tester.tap(find.text("What's an FHSA?"));
    await tester.pump();
    expect(
      find.text("What's an FHSA? is not built yet in this prototype."),
      findsOneWidget,
    );
  });

  Finder inProgressCard(String text) => find.descendant(
        of: find.byType(FinancialProgressCard),
        matching: find.text(text),
      );

  testWidgets('Financial progress toggles Invested and Dividends',
      (tester) async {
    await pumpApp(tester);

    await bringIntoView(tester, inProgressCard('Invested'));
    // Invested: lifetime total (sum of the yearly bars) and three years.
    expect(
      find.text("You've invested 38,170.04 CAD in all. Nice job!"),
      findsOneWidget,
    );
    expect(inProgressCard('20,402.92'), findsOneWidget);
    expect(inProgressCard('Contributions'), findsOneWidget);
    expect(inProgressCard('Reinvest'), findsNothing);

    // Dividends: earned total, year to date and projection.
    await tester.tap(inProgressCard('Invested'));
    await tester.pumpAndSettle();
    expect(
      find.text("You've earned 1,108.05 CAD in all. Nice job!"),
      findsOneWidget,
    );
    expect(inProgressCard('(YTD)'), findsOneWidget);
    expect(inProgressCard('(projected)'), findsOneWidget);
    expect(inProgressCard('513.10'), findsOneWidget);
    expect(inProgressCard('Contributions'), findsNothing);

    await tester.tap(inProgressCard('Reinvest'));
    await tester.pump();
    expect(
      find.text('Reinvest dividends is not built yet in this prototype.'),
      findsOneWidget,
    );
  });

  testWidgets('Financial progress Contributions opens its page',
      (tester) async {
    await pumpApp(tester);

    await bringIntoView(tester, inProgressCard('Contributions'));
    await tester.tap(inProgressCard('Contributions'));
    await tester.pumpAndSettle();
    expect(find.text('Account contributions'), findsWidgets);
  });

  testWidgets('Financial progress ⊕ opens the add-money sheet',
      (tester) async {
    await pumpApp(tester);

    await bringIntoView(tester, find.byTooltip('Add money'));
    await tester.tap(find.byTooltip('Add money'));
    await tester.pumpAndSettle();
    expect(find.byType(BottomSheet), findsOneWidget);
    expect(find.text('One-time transfer'), findsOneWidget);
    expect(find.text('Recurring deposit'), findsOneWidget);

    await tester.tap(find.text('Recurring deposit'));
    await tester.pumpAndSettle();
    expect(find.byType(BottomSheet), findsNothing);
    expect(find.textContaining('Deposit money'), findsOneWidget);
    expect(find.text('Recurring deposit'), findsOneWidget);
  });



  testWidgets('Bell icon opens Notifications & What\'s New',
      (tester) async {
    await pumpApp(tester);

    await tester.tap(find.byTooltip("Notifications and what's new"));
    await tester.pumpAndSettle();
    expect(find.text("Notifications & What's New"), findsWidgets);
  });

  testWidgets('Quick actions have no captions and no separate Add',
      (tester) async {
    await pumpApp(tester);

    expect(find.text('Move money'), findsOneWidget);
    expect(find.text('Deposit funds'), findsNothing);
    expect(find.text('Buy & sell'), findsNothing);
    expect(find.text('Total portfolio value'), findsNothing);
  });

  testWidgets('Profile button opens Profile & Settings', (tester) async {
    await pumpApp(tester);

    expect(find.textContaining('Taylor'), findsOneWidget);

    await tester.tap(find.byTooltip('Profile and settings'));
    await tester.pumpAndSettle();

    expect(find.text('Profile & Settings'), findsWidgets);
    expect(find.textContaining('eDocuments'), findsOneWidget);
    expect(find.textContaining('Go to CIBC Banking'), findsOneWidget);
  });

  Future<void> openQuote(WidgetTester tester, String query, String name) async {
    await tapSearch(tester);
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), query);
    await tester.pumpAndSettle();
    await tester.tap(find.text(name));
    await tester.pumpAndSettle();
  }

  testWidgets('Held security shows Buy and Sell', (tester) async {
    await pumpApp(tester);
    await openQuote(tester, 'ENB', 'Enbridge Inc.');

    // Below the chart now, so it may not be built until scrolled to.
    await bringIntoView(tester, find.text('Day range'));
    expect(find.text('Day range'), findsOneWidget);
    expect(find.text('Buy'), findsOneWidget);
    expect(find.text('Sell'), findsOneWidget);
    expect(find.text('(120 shares held)'), findsOneWidget);
  });

  testWidgets('Security not held shows Buy only', (tester) async {
    await pumpApp(tester);
    await openQuote(tester, 'SHOP', 'Shopify Inc.');

    expect(find.text('Buy'), findsOneWidget);
    expect(find.text('Sell'), findsNothing);
  });

  testWidgets('US-listed stock shows Fractional tag that opens the list',
      (tester) async {
    await pumpApp(tester);
    await openQuote(tester, 'AAPL', 'Apple Inc.');

    expect(find.text('Fractional'), findsOneWidget);
    await tester.tap(find.text('Fractional'));
    await tester.pumpAndSettle();

    expect(find.text('Fractional Stocks/ETFs'), findsOneWidget);
    expect(find.text('10 of 34 securities'), findsOneWidget);
    expect(find.text('10 of 34 results'), findsOneWidget);
    expect(find.text('AAPL'), findsOneWidget);

    // ETF tab: only ETFs.
    await tester.tap(find.text('ETF'));
    await tester.pumpAndSettle();
    expect(find.text('10 of 10 securities'), findsOneWidget);
    expect(find.text('AAPL'), findsNothing);
    expect(find.text('SPY'), findsOneWidget);

    // Search narrows the list.
    // The tab comes before the filter dropdowns that also read "All".
    await tester.tap(find.text('All').first);
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'visa');
    await tester.pumpAndSettle();
    expect(find.text('1 of 1 securities'), findsOneWidget);
    expect(find.text('Visa Inc. Class A'), findsOneWidget);
  });

  testWidgets('Canadian-listed stock has no Fractional tag', (tester) async {
    await pumpApp(tester);
    await openQuote(tester, 'ENB', 'Enbridge Inc.');
    expect(find.text('Fractional'), findsNothing);
  });

  testWidgets('Recent activity toggles All and Trades, See all bottom right',
      (tester) async {
    await pumpApp(tester);

    Finder inActivity(String text) => find.descendant(
          of: find.byType(RecentActivityCard),
          matching: find.text(text),
        );
    await bringIntoView(tester, inActivity('Trades'));
    expect(inActivity('Deposit initiated'), findsOneWidget);
    expect(inActivity('Sold CM'), findsNothing);

    await tester.tap(inActivity('Trades'));
    await tester.pumpAndSettle();
    // The three most recent trades only.
    expect(inActivity('Bought XEQT'), findsOneWidget);
    expect(inActivity('Sold CM'), findsOneWidget);
    expect(inActivity('Bought AAPL'), findsOneWidget);
    expect(inActivity('Bought VFV'), findsNothing);
    expect(inActivity('Deposit initiated'), findsNothing);

    // See all sits below the list, on the right.
    expect(
      tester.getTopLeft(inActivity('See all')).dy,
      greaterThan(tester.getTopLeft(inActivity('Bought AAPL')).dy),
    );
    await tester.tap(inActivity('See all'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Track the progress'), findsOneWidget);
  });

  testWidgets('Held security shows last buy, average cost and est. G/L',
      (tester) async {
    await pumpApp(tester);
    await openQuote(tester, 'ENB', 'Enbridge Inc.');

    // Collapsed: just the estimated gain/loss.
    expect(find.text('Est. gain/loss'), findsOneWidget);
    expect(find.textContaining('Last bought'), findsNothing);

    // Expanded: last bought and average cost.
    await tester.tap(find.text('Est. gain/loss'));
    await tester.pumpAndSettle();
    expect(find.text('Last bought 60 shares on Jun 26, 2026'), findsOneWidget);
    expect(find.text('55.14 CAD'), findsOneWidget);
    expect(find.text('Average cost 120 shares'), findsOneWidget);
    expect(find.text('59.12 CAD'), findsOneWidget);

    // The info icon explains the estimate.
    // The info icon opens the explanation in a bottom sheet.
    await tester.tap(find.byTooltip('About Est. gain/loss'));
    await tester.pumpAndSettle();
    expect(find.byType(BottomSheet), findsOneWidget);
    expect(find.textContaining('commissions'), findsOneWidget);

    await tester.tap(find.text('Got it'));
    await tester.pumpAndSettle();
    expect(find.byType(BottomSheet), findsNothing);
  });

  testWidgets('Security not held shows no position banner', (tester) async {
    await pumpApp(tester);
    await openQuote(tester, 'SHOP', 'Shopify Inc.');

    expect(find.textContaining('Last bought'), findsNothing);
  });

  testWidgets('Price change tag follows the chart range', (tester) async {
    await pumpApp(tester);
    await openQuote(tester, 'SHOP', 'Shopify Inc.');
    final tag = find.byKey(const ValueKey('price-period'));
    expect(tester.widget<Text>(tag).data, '1D');

    await bringIntoView(tester, find.text('1Y'));
    await tester.tap(find.text('1Y'));
    await tester.pumpAndSettle();

    // The price card scrolled out of the list's built range; scroll back up.
    await tester.scrollUntilVisible(
      tag,
      -200,
      scrollable: find.byType(Scrollable).first,
    );
    expect(tester.widget<Text>(tag).data, '1Y');
  });

  testWidgets('Quote keeps updating live', (tester) async {
    await pumpApp(tester);
    await openQuote(tester, 'SHOP', 'Shopify Inc.');

    // Several simulated ticks: the price and spread stay well-formed.
    for (var i = 0; i < 5; i++) {
      await tester.pump(QuoteScreen.liveTick);
    }
    expect(find.byKey(const ValueKey('price-period')), findsOneWidget);
    expect(find.text('Bid'), findsOneWidget);
    expect(find.text('Ask'), findsOneWidget);
  });

  testWidgets('Tapping the price opens Trade', (tester) async {
    await pumpApp(tester);
    await openQuote(tester, 'SHOP', 'Shopify Inc.');

    await tester.tap(find.text('142.80'));
    await tester.pumpAndSettle();

    expect(find.text('Selected security'), findsOneWidget);
    expect(find.text('SHOP'), findsOneWidget);
  });

  testWidgets('Back on stock details returns to a blank, focused search',
      (tester) async {
    await pumpApp(tester);
    await openQuote(tester, 'ENB', 'Enbridge Inc.');

    // No Home button or search bar; Back, alerts and watchlist instead.
    expect(find.byTooltip('Home'), findsNothing);
    expect(find.text('Search stock or ETF'), findsNothing);
    expect(find.byTooltip('Set a price alert for ENB'), findsOneWidget);
    expect(find.byTooltip('Remove ENB from watchlist'), findsOneWidget);

    await tester.tap(find.byTooltip('Back'));
    await tester.pumpAndSettle();
    expect(find.text('RECENT SEARCHES'), findsOneWidget);
    final field = tester.widget<EditableText>(find.byType(EditableText));
    expect(field.controller.text, isEmpty);
    expect(field.focusNode.hasFocus, isTrue);
  });

  testWidgets('Back on stock details returns to where it was opened',
      (tester) async {
    await pumpApp(tester);
    await showTopHoldings(tester);
    await tester.tap(find.text('CM'));
    await tester.pumpAndSettle();
    expect(find.text('Canadian Imperial Bank of Commerce'), findsOneWidget);

    await tester.tap(find.byTooltip('Back'));
    await tester.pumpAndSettle();
    // Back on Home, still scrolled to Top holdings (so the greeting at the
    // top isn't built): the floating search button and the CM row show.
    expect(find.byTooltip('Search stocks and ETFs'), findsOneWidget);
    expect(find.text('CM'), findsOneWidget);
    expect(find.text('Canadian Imperial Bank of Commerce'), findsNothing);
  });

  testWidgets('Scrolling down shows the compact price bar, up restores it',
      (tester) async {
    await pumpApp(tester);
    await openQuote(tester, 'SHOP', 'Shopify Inc.');
    expect(find.byTooltip('Back'), findsOneWidget);

    final list = find.byType(Scrollable).first;
    await tester.drag(list, const Offset(0, -400));
    await tester.pumpAndSettle();
    expect(find.byTooltip('Back'), findsNothing);
    expect(find.byKey(const ValueKey('compact')), findsOneWidget);

    await tester.drag(list, const Offset(0, 100));
    await tester.pumpAndSettle();
    expect(find.byTooltip('Back'), findsOneWidget);
  });


  testWidgets('Opening a second stock from search shows that stock',
      (tester) async {
    await pumpApp(tester);

    // First stock, from a recent search.
    await tapSearch(tester);
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Open XEQT'));
    await tester.pumpAndSettle();
    expect(find.text('iShares Core Equity ETF Portfolio'), findsOneWidget);

    // Back to search from stock details, then a different recent search.
    await tapSearch(tester);
    await tester.pumpAndSettle();
    // Pills are one scrolling row; bring ENB into view first.
    await tester.ensureVisible(find.byTooltip('Open ENB'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Open ENB'));
    await tester.pumpAndSettle();
    expect(find.text('Enbridge Inc.'), findsOneWidget);
    expect(find.text('iShares Core Equity ETF Portfolio'), findsNothing);

    // And a typed search.
    await tapSearch(tester);
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'SHOP');
    await tester.pumpAndSettle();
    await tester.tap(find.text('Shopify Inc.'));
    await tester.pumpAndSettle();
    expect(find.text('Shopify Inc.'), findsOneWidget);
    expect(find.text('Enbridge Inc.'), findsNothing);
  });

  testWidgets('Recent search opens stock details directly', (tester) async {
    await pumpApp(tester);
    await tapSearch(tester);
    await tester.pumpAndSettle();

    await tester.tap(find.text('XEQT'));
    await tester.pumpAndSettle();

    expect(find.text('iShares Core Equity ETF Portfolio'), findsOneWidget);
    // Below the chart now, so it may not be built until scrolled to.
    await bringIntoView(tester, find.text('Day range'));
    expect(find.text('Day range'), findsOneWidget);
  });

  testWidgets('Eye toggle hides the total and stays hidden across pages',
      (tester) async {
    await pumpApp(tester);

    expect(find.text(r'$124,820.42'), findsOneWidget);
    await tester.tap(find.byTooltip('Hide balance'));
    await tester.pumpAndSettle();
    expect(find.text(r'$124,820.42'), findsNothing);
    expect(find.text(r'$••••••'), findsOneWidget);

    // Leave Home and come back: still hidden.
    await tester.tap(find.byTooltip('View performance'));
    await tester.pumpAndSettle();
    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(find.text(r'$••••••'), findsOneWidget);

    // Holdings follows the same setting: its amounts stay hidden.
    await bringIntoView(tester, find.text('All holdings'));
    await tester.tap(find.text('All holdings'));
    await tester.pumpAndSettle();
    expect(find.byTooltip('Show balance'), findsOneWidget);
    expect(find.textContaining('124,820.42'), findsNothing);
    expect(find.text(r'$•••••• CAD'), findsOneWidget);

    // Showing them on Holdings shows them on Home too.
    await tester.tap(find.byTooltip('Show balance'));
    await tester.pumpAndSettle();
    await tester.pageBack();
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.text(r'$124,820.42'),
      -200,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text(r'$124,820.42'), findsOneWidget);
  });

  testWidgets('Stock details: ratings, number lines and detail tabs',
      (tester) async {
    await pumpApp(tester);
    await openQuote(tester, 'ENB', 'Enbridge Inc.');

    await bringIntoView(tester, find.textContaining('vs 3 mon avg'));
    expect(find.text('52 week range'), findsOneWidget);
    expect(find.textContaining('vs 3 mon avg'), findsOneWidget);

    await bringIntoView(tester, find.text('Hold'));
    expect(find.text('Buy 28%'), findsOneWidget);
    expect(find.text('18'), findsOneWidget);
    expect(find.text('ratings'), findsOneWidget);
    expect(
      find.text('Overall analyst consensus (last 3 months).'),
      findsOneWidget,
    );

    await bringIntoView(tester, find.text('Market cap'));
    expect(find.text('P/E (TTM)'), findsOneWidget);
    expect(find.text('Dividend growth (3 yr)'), findsOneWidget);

    await tester.tap(find.text('News'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Headline placeholder'), findsNWidgets(3));
    expect(find.text('TOP STORIES'), findsNothing);

    await tester.tap(find.text('Events'));
    await tester.pumpAndSettle();
    expect(find.text('Earnings'), findsNWidgets(3));
    expect(find.text('Ex-dividend'), findsNWidgets(3));
  });

  testWidgets('ETF details explain there are no analyst ratings',
      (tester) async {
    await pumpApp(tester);
    await openQuote(tester, 'XEQT', 'iShares Core Equity ETF Portfolio');

    await bringIntoView(tester, find.textContaining('ETFs'));
    expect(find.text('Net assets'), findsOneWidget);
  });

  testWidgets('Blank search shows Market Overview and browse links',
      (tester) async {
    await pumpApp(tester);
    await tapSearch(tester);
    await tester.pumpAndSettle();

    expect(find.text('MARKET OVERVIEW'), findsOneWidget);
    expect(find.text('S&P 500'), findsWidgets);
    expect(find.text('DJIA'), findsWidgets);
    expect(find.text('FIND YOUR NEXT MOVE'), findsOneWidget);

    await tester.tap(find.text('Commission-free ETFs'));
    await tester.pump();
    expect(
      find.text('Commission-free ETFs is not built yet in this prototype.'),
      findsOneWidget,
    );
  });

  testWidgets('Searched stock goes first in Recent searches, max 5',
      (tester) async {
    await pumpApp(tester);

    Finder pill(String symbol) => find.byTooltip('Open $symbol');
    Future<void> searchAndOpen(String query, String name) async {
      await tapSearch(tester);
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), query);
      await tester.pumpAndSettle();
      await tester.tap(find.text(name));
      await tester.pumpAndSettle();
    }

    // Starts with XEQT, VFV, ENB, CM.
    await searchAndOpen('SHOP', 'Shopify Inc.');
    await searchAndOpen('ZAG', 'BMO Aggregate Bond Index ETF');

    await tapSearch(tester);
    await tester.pumpAndSettle();
    // One horizontally scrolling row.
    expect(
      find.descendant(
        of: find.byType(RecentSearchChips),
        matching: find.byWidgetPredicate(
          (w) =>
              w is SingleChildScrollView &&
              w.scrollDirection == Axis.horizontal,
        ),
      ),
      findsOneWidget,
    );
    // Newest first; CM (the oldest) dropped to keep five.
    final order = ['ZAG', 'SHOP', 'XEQT', 'VFV', 'ENB'];
    expect(
      find.descendant(
        of: find.byType(RecentSearchChips),
        matching: find.byType(Tooltip),
      ),
      findsNWidgets(order.length),
    );
    for (var i = 0; i < order.length - 1; i++) {
      expect(
        tester.getTopLeft(pill(order[i])).dx,
        lessThan(tester.getTopLeft(pill(order[i + 1])).dx),
      );
    }
    await tester.drag(
      find.byType(RecentSearchChips),
      const Offset(-2000, 0),
    );
    await tester.pumpAndSettle();
    expect(pill('ENB'), findsOneWidget);
    expect(pill('CM'), findsNothing);
  });

  testWidgets('Tapping Market Overview pauses and plays it', (tester) async {
    await pumpApp(tester, reduceMotion: false);
    await tapSearch(tester);
    await tester.pump(const Duration(milliseconds: 600));
    await tester.pump(const Duration(milliseconds: 600));

    // No pause button any more.
    expect(find.byTooltip('Pause market overview'), findsNothing);

    final card = find.text('DJIA').first;
    final box = tester.renderObject<RenderBox>(card);
    double x() => box.localToGlobal(Offset.zero).dx;

    await tester.tap(card);
    await tester.pump();
    final paused = x();
    // Longer than the 3s resume-after-hold delay: still paused.
    await tester.pump(const Duration(seconds: 5));
    expect(x(), paused);

    await tester.tap(card);
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    await tester.pump(const Duration(milliseconds: 16));
    expect(x(), lessThan(paused));
  });


  testWidgets('Market Overview auto-scrolls and pauses while held',
      (tester) async {
    await pumpApp(tester, reduceMotion: false);
    await tapSearch(tester);
    // The carousel never settles while it auto-scrolls, so pump by time.
    await tester.pump(const Duration(milliseconds: 600));
    await tester.pump(const Duration(milliseconds: 600));

    // Track one specific card's render box (the list repeats, so a text
    // finder could match a different copy after scrolling).
    final box = tester.renderObject<RenderBox>(find.text('DJIA').first);
    double x() => box.localToGlobal(Offset.zero).dx;

    final before = x();
    await tester.pump(const Duration(seconds: 1));
    await tester.pump(const Duration(milliseconds: 16));
    expect(x(), lessThan(before));

    // Press and hold: it stops moving.
    final gesture =
        await tester.startGesture(box.localToGlobal(box.size.center(Offset.zero)));
    await tester.pump(const Duration(milliseconds: 16));
    final held = x();
    await tester.pump(const Duration(seconds: 1));
    expect(x(), held);
    await gesture.up();
    await tester.pump(const Duration(seconds: 4));
  });

  testWidgets('Tapping empty space on Search puts the keyboard away',
      (tester) async {
    await pumpApp(tester);
    await tapSearch(tester);
    await tester.pumpAndSettle();

    EditableText field() =>
        tester.widget<EditableText>(find.byType(EditableText));
    expect(field().focusNode.hasFocus, isTrue);

    // A label isn't tappable: tapping it dismisses the keyboard.
    await tester.tap(find.text('RECENT SEARCHES'));
    await tester.pump();
    expect(field().focusNode.hasFocus, isFalse);

    // Tapping the search bar brings it back.
    await tester.tap(find.byType(EditableText));
    await tester.pump();
    expect(field().focusNode.hasFocus, isTrue);
  });

  testWidgets('Nav C: bottom search icon on Search brings the keyboard up',
      (tester) async {
    await pumpApp(tester);
    tester
        .state<InvestorsEdgeAppState>(find.byType(InvestorsEdgeApp))
        .navVersion
        .value = NavVersion.actions;
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Search stocks & ETFs'));
    await tester.pumpAndSettle();

    EditableText field() =>
        tester.widget<EditableText>(find.byType(EditableText));
    await tester.tap(find.text('RECENT SEARCHES'));
    await tester.pump();
    expect(field().focusNode.hasFocus, isFalse);

    await tester.tap(find.byTooltip('Search stocks & ETFs'));
    await tester.pumpAndSettle();
    expect(field().focusNode.hasFocus, isTrue);
  });

  testWidgets('Nav B: opening and closing Shortcuts on Search keeps keyboard '
      'down', (tester) async {
    await pumpApp(tester);
    tester
        .state<InvestorsEdgeAppState>(find.byType(InvestorsEdgeApp))
        .navVersion
        .value = NavVersion.shortcuts;
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Search stocks & ETFs'));
    await tester.pumpAndSettle();

    EditableText field() =>
        tester.widget<EditableText>(find.byType(EditableText));
    expect(field().focusNode.hasFocus, isTrue);

    await tester.tap(find.byTooltip('Shortcuts'));
    await tester.pumpAndSettle();
    expect(field().focusNode.hasFocus, isFalse);

    await tester.tap(find.byTooltip('Close shortcuts'));
    await tester.pumpAndSettle();
    expect(find.text('RECENT SEARCHES'), findsOneWidget);
    expect(field().focusNode.hasFocus, isFalse);
  });

  testWidgets('Floating search button opens blank search, field focused',
      (tester) async {
    await pumpApp(tester);

    // No floating search bar or Home button on Home any more.
    expect(find.text('Search stock or ETF'), findsNothing);
    expect(find.byIcon(Icons.home_rounded), findsNothing);

    await tester.tap(find.byTooltip('Search stocks and ETFs'));
    await tester.pumpAndSettle();

    expect(find.text('RECENT SEARCHES'), findsOneWidget);
    expect(find.text('MARKET OVERVIEW'), findsOneWidget);
    // Recent search pills show the ticker and its live price.
    expect(find.text('XEQT'), findsOneWidget);
    expect(find.text(r'$32.87'), findsOneWidget);
    final field = tester.widget<EditableText>(find.byType(EditableText));
    expect(field.focusNode.hasFocus, isTrue);
  });
}
