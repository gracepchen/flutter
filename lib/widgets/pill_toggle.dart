import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/obr_tokens.dart';
import '../theme/obr_typography.dart';
import '../util/motion.dart';

/// Oval two-way toggle. Tapping anywhere on it flips the value, and the dark
/// thumb slides smoothly to the other side (instantly under reduced motion).
///
/// Visually 32pt tall inside a 44pt tap target.
class PillToggle extends StatelessWidget {
  const PillToggle({
    super.key,
    required this.leftLabel,
    required this.rightLabel,
    required this.rightSelected,
    required this.onChanged,
    this.segmentWidth = 76,
  });

  final String leftLabel;
  final String rightLabel;

  /// False = left option showing, true = right option showing.
  final bool rightSelected;
  final ValueChanged<bool> onChanged;
  final double segmentWidth;

  static const double _height = ObrSize.s32;
  static const double _inset = ObrSpace.s2;

  @override
  Widget build(BuildContext context) {
    final duration = motionDuration(context, ObrDuration.d250);
    final current = rightSelected ? rightLabel : leftLabel;
    final other = rightSelected ? leftLabel : rightLabel;

    Widget label(String text, bool selected) => SizedBox(
          width: segmentWidth,
          child: Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: ObrSpace.s4),
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: AnimatedDefaultTextStyle(
                  duration: duration,
                  curve: ObrEasing.easeInOut,
                  style: ObrType.labelMd.copyWith(
                    color: selected ? ObrColors.gray0 : ObrColors.gray700,
                    fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                  ),
                  child: Text(text, maxLines: 1),
                ),
              ),
            ),
          ),
        );

    return Semantics(
      button: true,
      toggled: rightSelected,
      label: 'Showing $current. Switch to $other',
      excludeSemantics: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () {
          HapticFeedback.selectionClick();
          onChanged(!rightSelected);
        },
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: ObrSize.s44),
          child: Center(
            widthFactor: 1,
            child: Container(
              width: segmentWidth * 2 + _inset * 2,
              height: _height,
              padding: const EdgeInsets.all(_inset),
              decoration: BoxDecoration(
                color: ObrColors.gray200,
                borderRadius: BorderRadius.circular(ObrRadius.full),
              ),
              child: Stack(
                children: [
                  // The sliding thumb.
                  AnimatedAlign(
                    duration: duration,
                    curve: ObrEasing.easeInOut,
                    alignment: rightSelected
                        ? Alignment.centerRight
                        : Alignment.centerLeft,
                    child: Container(
                      width: segmentWidth,
                      height: _height - _inset * 2,
                      decoration: BoxDecoration(
                        color: ObrColors.gray700,
                        borderRadius: BorderRadius.circular(ObrRadius.full),
                      ),
                    ),
                  ),
                  Row(
                    children: [
                      label(leftLabel, !rightSelected),
                      label(rightLabel, rightSelected),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
