import 'package:flutter/widgets.dart';

/// Whether balances are hidden (the eye toggle on Home).
///
/// The notifier lives in the app, above the router, so the choice survives
/// navigating away from Home and back until the person changes it. It is
/// in-memory only and resets when the app restarts; persist it (for example
/// with shared_preferences) if it should survive restarts.
class BalanceVisibility extends InheritedNotifier<ValueNotifier<bool>> {
  const BalanceVisibility({
    super.key,
    required ValueNotifier<bool> hidden,
    required super.child,
  }) : super(notifier: hidden);

  /// The notifier; read `.value` for the current state and set it to change.
  /// Widgets that call this rebuild when it changes.
  static ValueNotifier<bool> of(BuildContext context) => context
      .dependOnInheritedWidgetOfExactType<BalanceVisibility>()!
      .notifier!;

  /// Whether balances are hidden. Widgets that call this rebuild when it
  /// changes.
  static bool hiddenOf(BuildContext context) => of(context).value;
}

/// Stand-in shown for a hidden amount.
const String hiddenAmount = '••••••';

