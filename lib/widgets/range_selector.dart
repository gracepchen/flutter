import 'package:flutter/material.dart';

import '../theme/obr_tokens.dart';
import '../theme/obr_typography.dart';
import '../util/motion.dart';

/// Row of time-range pills (1D, 1W, …) under a chart.
///
/// Every range gets an equal slot, so the row always fits its container. The
/// first and last pills sit flush with the edges, and labels shrink rather
/// than overflow on narrow screens.
class RangeSelector extends StatelessWidget {
  const RangeSelector({
    super.key,
    required this.labels,
    required this.spokenLabels,
    required this.selectedIndex,
    required this.onSelected,
  }) : assert(labels.length == spokenLabels.length);

  final List<String> labels;

  /// What screen readers say for each range, e.g. "1 week".
  final List<String> spokenLabels;
  final int selectedIndex;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    // The pills must fit one row, so cap text scaling here only.
    return MediaQuery.withClampedTextScaling(
      maxScaleFactor: 1.4,
      child: Row(
        children: [
          for (var i = 0; i < labels.length; i++)
            Expanded(
              child: _RangeChip(
                label: labels[i],
                spokenLabel: spokenLabels[i],
                selected: i == selectedIndex,
                alignment: i == 0
                    ? Alignment.centerLeft
                    : i == labels.length - 1
                        ? Alignment.centerRight
                        : Alignment.center,
                onTap: () => onSelected(i),
              ),
            ),
        ],
      ),
    );
  }
}

class _RangeChip extends StatelessWidget {
  const _RangeChip({
    required this.label,
    required this.spokenLabel,
    required this.selected,
    required this.alignment,
    required this.onTap,
  });

  final String label;
  final String spokenLabel;
  final bool selected;
  final Alignment alignment;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      label: spokenLabel,
      excludeSemantics: true,
      child: InkWell(
        onTap: onTap,
        customBorder: const StadiumBorder(),
        // The whole slot (at least 44pt tall) is the hit area around a
        // smaller visible pill.
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: ObrSize.s44),
          child: Align(
            alignment: alignment,
            child: AnimatedContainer(
              duration: motionDuration(context, ObrDuration.d200),
              curve: ObrEasing.easeInOut,
              padding: const EdgeInsets.symmetric(
                horizontal: ObrSpace.s12,
                vertical: ObrSpace.s8,
              ),
              decoration: BoxDecoration(
                color: selected ? ObrColors.gray700 : Colors.transparent,
                borderRadius: BorderRadius.circular(ObrRadius.full),
              ),
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  label,
                  maxLines: 1,
                  style: ObrType.labelMd.copyWith(
                    color: selected ? ObrColors.gray0 : ObrColors.gray600,
                    fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
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
