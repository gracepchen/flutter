import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../../router.dart';
import '../../state/app_session.dart';
import '../../theme/obr_tokens.dart';
import '../../widgets/ie_logo.dart';

/// Signing in: the Investor's Edge mark turning slowly clockwise on light
/// gray. After [duration] it signs the session on and goes to Home (or to
/// the app shortcut's destination, if one is waiting), replacing the
/// sign-on screens so Back doesn't return to them. Under Reduce Motion the
/// mark stays still.
class SigningInScreen extends StatefulWidget {
  const SigningInScreen({super.key});

  static const Duration duration = Duration(milliseconds: 900);

  /// One full turn.
  static const Duration spinPeriod = Duration(seconds: 4);

  @override
  State<SigningInScreen> createState() => _SigningInScreenState();
}

class _SigningInScreenState extends State<SigningInScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _spin = AnimationController(
    vsync: this,
    duration: SigningInScreen.spinPeriod,
  );
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    // Next step: replace with real authentication (e.g. local_auth and a
    // session check), then go Home on success.
    _timer = Timer(SigningInScreen.duration, () {
      if (!mounted) return;
      final session = AppSessionScope.read(context)..signIn();
      context.go(session.takePendingLocation() ?? AppRoutes.home);
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.disableAnimationsOf(context)) {
      _spin.stop();
    } else if (!_spin.isAnimating) {
      _spin.repeat();
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _spin.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark.copyWith(
        statusBarColor: Colors.transparent,
      ),
      child: Scaffold(
        backgroundColor: ObrColors.gray100,
        body: Center(
          child: Semantics(
            liveRegion: true,
            label: 'Signing on',
            child: RotationTransition(
              // Positive turns are clockwise.
              turns: _spin,
              child: const IeMark(size: 128),
            ),
          ),
        ),
      ),
    );
  }
}
