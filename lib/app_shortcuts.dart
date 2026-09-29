import 'router.dart';

/// App shortcuts on the launcher icon (long-press on iOS and Android).
///
/// [type] is the id the OS sends back when one is tapped; [location] is
/// where it goes. Shortcuts don't get icons yet: to add them, put images in
/// the iOS asset catalog / Android drawables and pass their names as
/// `icon` in `ShortcutItem`.
enum AppShortcut {
  trade('trade', 'Trade', AppRoutes.trade),
  addFunds('add_funds', 'Add funds', AppRoutes.add),
  viewAssets('view_assets', 'My holdings', AppRoutes.holdings),
  // Search opens blank with the field focused.
  quickQuote('quick_quote', 'Quick quote', AppRoutes.search);

  const AppShortcut(this.type, this.title, this.location);

  final String type;
  final String title;
  final String location;

  static AppShortcut? fromType(String type) {
    for (final s in values) {
      if (s.type == type) return s;
    }
    return null;
  }
}
