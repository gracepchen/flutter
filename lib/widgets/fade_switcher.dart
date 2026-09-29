import 'package:flutter/widgets.dart';

import '../theme/obr_tokens.dart';
import '../util/motion.dart';

/// Cross-fades between two versions of a right-aligned figure block, for
/// example when a toggle switches Total and Cash only. Give each version a
/// different key. Instant under reduced motion.
class FadeSwitcher extends StatelessWidget {
  const FadeSwitcher({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: motionDuration(context, ObrDuration.d200),
      switchInCurve: ObrEasing.easeOut,
      switchOutCurve: ObrEasing.easeIn,
      layoutBuilder: (current, previous) => Stack(
        alignment: Alignment.centerRight,
        children: [...previous, if (current != null) current],
      ),
      child: child,
    );
  }
}
