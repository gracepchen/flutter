import 'package:flutter/material.dart';

import '../../theme/obr_tokens.dart';
import '../../theme/obr_typography.dart';
import '../../widgets/obr_card.dart';

/// "Find your next move" browse links. Not built yet: each shows a short
/// "coming soon" message instead of navigating.
class NextMoveLinks extends StatelessWidget {
  const NextMoveLinks({super.key});

  static const List<(IconData, String)> _links = [
    (Icons.trending_up, 'Top 10 traded stocks/ETFs'),
    (Icons.local_offer_outlined, 'Commission-free ETFs'),
    (Icons.pie_chart_outline, 'Fractional stocks/ETFs'),
  ];

  void _notBuilt(BuildContext context, String label) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(content: Text('$label is not built yet in this prototype.')),
      );
  }

  @override
  Widget build(BuildContext context) {
    return ObrCard(
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          for (var i = 0; i < _links.length; i++) ...[
            if (i > 0) const Divider(indent: ObrSpace.s16, endIndent: ObrSpace.s16),
            Semantics(
              link: true,
              label: _links[i].$2,
              excludeSemantics: true,
              child: InkWell(
                onTap: () => _notBuilt(context, _links[i].$2),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(minHeight: ObrSize.s56),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: ObrSpace.s16,
                      vertical: ObrSpace.s12,
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: ObrSize.s40,
                          height: ObrSize.s40,
                          decoration: const BoxDecoration(
                            color: ObrColors.gray100,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            _links[i].$1,
                            color: ObrColors.gray700,
                            size: ObrSize.s20,
                          ),
                        ),
                        const SizedBox(width: ObrSpace.s12),
                        Expanded(
                          child: Text(_links[i].$2, style: ObrType.bodyLg),
                        ),
                        const Icon(
                          Icons.chevron_right,
                          color: ObrColors.gray600,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
