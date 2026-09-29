import 'package:flutter/widgets.dart';

/// Navigation schemes to compare, switched in Profile & Settings.
enum NavVersion {
  /// Three action buttons on Home and a floating search button.
  searchOnly('A', 'Search only'),

  /// Bottom bar: Home, search bar, Shortcuts (Move money, Activity, Trade).
  shortcuts('B', 'Search with shortcuts'),

  /// Bottom bar: Home, search bar, Transfers, Activity.
  actions('C', 'Search with actions'),

  /// Tab bar: Home, Explore, Move, Activity.
  tabs('D', 'Tabs');

  const NavVersion(this.letter, this.label);

  final String letter;
  final String label;
}

/// Makes the chosen [NavVersion] available below the router.
class NavVersionScope extends InheritedNotifier<ValueNotifier<NavVersion>> {
  const NavVersionScope({
    super.key,
    required ValueNotifier<NavVersion> version,
    required super.child,
  }) : super(notifier: version);

  /// The notifier; widgets that call this rebuild when it changes.
  static ValueNotifier<NavVersion> of(BuildContext context) => context
      .dependOnInheritedWidgetOfExactType<NavVersionScope>()!
      .notifier!;

  static NavVersion versionOf(BuildContext context) => of(context).value;
}
