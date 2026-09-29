import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../../../router.dart';
import '../../../theme/obr_tokens.dart';
import '../../../theme/obr_typography.dart';

class _QuickActionData {
  const _QuickActionData({
    required this.icon,
    required this.label,
    required this.location,
  });

  final IconData icon;
  final String label;
  final String location;
}

/// Move money / Trade / Activity row.
class QuickActions extends StatelessWidget {
  const QuickActions({super.key});

  // Add and Transfer are combined: Transfer covers deposits too.
  static const List<_QuickActionData> _actions = [
    _QuickActionData(
      icon: Icons.swap_horiz,
      label: 'Move money',
      location: AppRoutes.transfer,
    ),
    _QuickActionData(
      icon: Icons.candlestick_chart_outlined,
      label: 'Trade',
      location: AppRoutes.trade,
    ),
    _QuickActionData(
      icon: Icons.timer_outlined,
      label: 'Activity',
      location: AppRoutes.activity,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final action in _actions)
          Expanded(child: _QuickActionButton(data: action)),
      ],
    );
  }
}

class _QuickActionButton extends StatelessWidget {
  const _QuickActionButton({required this.data});

  final _QuickActionData data;

  @override
  Widget build(BuildContext context) {
    return MergeSemantics(
      child: Semantics(
        button: true,
        child: InkWell(
          borderRadius: BorderRadius.circular(ObrRadius.r16),
          onTap: () {
            HapticFeedback.lightImpact();
            context.push(data.location);
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(
              vertical: ObrSpace.s8,
              horizontal: ObrSpace.s4,
            ),
            child: Column(
              children: [
                Container(
                  width: ObrSize.s64,
                  height: ObrSize.s64,
                  decoration: BoxDecoration(
                    color: ObrColors.gray0,
                    shape: BoxShape.circle,
                    // A hairline so the white circle reads on the page.
                    border: Border.all(color: ObrColors.gray200),
                  ),
                  child: Icon(
                    data.icon,
                    color: ObrColors.brand700,
                    size: ObrSize.s28,
                  ),
                ),
                const SizedBox(height: ObrSpace.s8),
                Text(
                  data.label,
                  textAlign: TextAlign.center,
                  style: ObrType.bodyLg,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
