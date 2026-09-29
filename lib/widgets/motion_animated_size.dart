import 'package:flutter/widgets.dart';

import '../theme/obr_tokens.dart';
import '../util/motion.dart';

/// [AnimatedSize] that respects Reduce Motion.
///
/// With animations disabled it returns [child] directly. AnimatedSize must
/// not get a zero duration: its animation then completes during layout and
/// Flutter asserts ("RenderAnimatedSize was mutated in its own
/// performLayout").
class MotionAnimatedSize extends StatelessWidget {
  const MotionAnimatedSize({
    super.key,
    required this.child,
    this.duration = ObrDuration.d250,
    this.curve = ObrEasing.easeInOut,
    this.alignment = Alignment.topCenter,
  });

  final Widget child;
  final Duration duration;
  final Curve curve;
  final AlignmentGeometry alignment;

  @override
  Widget build(BuildContext context) {
    final effective = motionDuration(context, duration);
    if (effective == Duration.zero) return child;
    return AnimatedSize(
      duration: effective,
      curve: curve,
      alignment: alignment,
      child: child,
    );
  }
}
