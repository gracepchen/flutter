import 'package:flutter/widgets.dart';

/// Returns [duration], or [Duration.zero] when the person has turned on
/// Reduce Motion (iOS) or Remove animations (Android).
///
/// Route every animation duration through this so each transition has a
/// reduced-motion path.
Duration motionDuration(BuildContext context, Duration duration) =>
    MediaQuery.disableAnimationsOf(context) ? Duration.zero : duration;
