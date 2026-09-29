import 'package:flutter/widgets.dart';

import '../data/mock_portfolio.dart';

/// Recent searches, newest first, at most [max]. Opening a security from
/// search results puts it first (moving it up if it's already listed) and
/// drops the oldest past [max]. In memory for the prototype.
class RecentSearches extends ValueNotifier<List<String>> {
  RecentSearches() : super(List.unmodifiable(MockSecurities.recentSearches));

  static const int max = 5;

  void add(String symbol) {
    value = List.unmodifiable(
      [symbol, ...value.where((s) => s != symbol)].take(max),
    );
  }
}

/// Makes [RecentSearches] available below the router.
class RecentSearchesScope extends InheritedNotifier<RecentSearches> {
  const RecentSearchesScope({
    super.key,
    required RecentSearches searches,
    required super.child,
  }) : super(notifier: searches);

  /// The list; widgets that call this rebuild when it changes.
  static RecentSearches of(BuildContext context) => context
      .dependOnInheritedWidgetOfExactType<RecentSearchesScope>()!
      .notifier!;

  /// The list, without rebuilding when it changes (for callbacks).
  static RecentSearches read(BuildContext context) => context
      .getInheritedWidgetOfExactType<RecentSearchesScope>()!
      .notifier!;
}
