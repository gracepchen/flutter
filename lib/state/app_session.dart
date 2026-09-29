import 'package:flutter/widgets.dart';

/// Whether the client is signed on, plus where to go after signing on (for
/// app shortcuts used while signed out). In-memory only for the prototype.
class AppSession extends ChangeNotifier {
  AppSession({bool signedIn = false}) : _signedIn = signedIn;

  bool _signedIn;
  String? _pendingLocation;

  bool get signedIn => _signedIn;

  /// Where to go after signing on instead of Home, e.g. `/trade?side=buy`.
  set pendingLocation(String? location) => _pendingLocation = location;

  /// Returns the pending location (if any) and clears it.
  String? takePendingLocation() {
    final location = _pendingLocation;
    _pendingLocation = null;
    return location;
  }

  void signIn() {
    if (_signedIn) return;
    _signedIn = true;
    notifyListeners();
  }

  /// Next step: clear tokens and cached data here too.
  void signOut() {
    _pendingLocation = null;
    if (!_signedIn) return;
    _signedIn = false;
    notifyListeners();
  }
}

/// Makes the [AppSession] available below the router.
class AppSessionScope extends InheritedNotifier<AppSession> {
  const AppSessionScope({
    super.key,
    required AppSession session,
    required super.child,
  }) : super(notifier: session);

  /// The session, without rebuilding when it changes (for callbacks).
  static AppSession read(BuildContext context) => context
      .getInheritedWidgetOfExactType<AppSessionScope>()!
      .notifier!;
}
