import 'package:flutter/material.dart';

import '../theme/obr_tokens.dart';
import '../theme/obr_typography.dart';
import '../util/motion.dart';

/// Segmented control: one light-gray track with a dark-gray (gray-700) thumb
/// that slides to the selected segment (instantly under reduced motion).
/// Selected text is white semibold; the others are dark gray. Works for 2–4
/// options.
class ObrSegmentedControl extends StatelessWidget {
  const ObrSegmentedControl({
    super.key,
    required this.labels,
    required this.selectedIndex,
    required this.onSelected,
  });

  final List<String> labels;
  final int selectedIndex;
  final ValueChanged<int> onSelected;

  static const double _inset = ObrSpace.s4;

  @override
  Widget build(BuildContext context) {
    final duration = motionDuration(context, ObrDuration.d250);
    final count = labels.length;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: ObrColors.gray100,
        borderRadius: BorderRadius.circular(ObrRadius.r12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(_inset),
        child: Stack(
          children: [
            // The sliding thumb, one segment wide, behind the labels.
            Positioned.fill(
              child: AnimatedAlign(
                duration: duration,
                curve: ObrEasing.easeInOut,
                alignment: Alignment(
                  count == 1 ? 0 : -1 + 2 * selectedIndex / (count - 1),
                  0,
                ),
                child: FractionallySizedBox(
                  widthFactor: 1 / count,
                  heightFactor: 1,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: ObrColors.gray700,
                      borderRadius: BorderRadius.circular(ObrRadius.r8),
                    ),
                  ),
                ),
              ),
            ),
            Row(
              children: [
                for (var i = 0; i < count; i++)
                  Expanded(
                    child: _Segment(
                      label: labels[i],
                      selected: i == selectedIndex,
                      onTap: () => onSelected(i),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _Segment extends StatelessWidget {
  const _Segment({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(ObrRadius.r8);
    return Semantics(
      button: true,
      selected: selected,
      inMutuallyExclusiveGroup: true,
      label: label,
      excludeSemantics: true,
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          onTap: onTap,
          borderRadius: radius,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: ObrSize.s44),
            child: Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: ObrSpace.s8),
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: AnimatedDefaultTextStyle(
                    duration: motionDuration(context, ObrDuration.d250),
                    curve: ObrEasing.easeInOut,
                    style: ObrType.labelLg.copyWith(
                      color: selected ? ObrColors.gray0 : ObrColors.gray800,
                      fontWeight:
                          selected ? FontWeight.w600 : FontWeight.w400,
                    ),
                    child: Text(label, maxLines: 1),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
