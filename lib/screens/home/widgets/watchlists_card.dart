import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../router.dart';
import '../../../theme/obr_tokens.dart';
import '../../../theme/obr_typography.dart';
import '../../../widgets/obr_card.dart';
import '../../../widgets/section_header.dart';

/// Watchlists: same header, "See all" link and height as Recent activity.
/// Content is TBD.
class WatchlistsCard extends StatelessWidget {
  const WatchlistsCard({super.key, required this.height});

  /// Recent activity's height, so the two cards match. Null until measured.
  final ValueNotifier<double?> height;

  /// Used for the first frame, before Recent activity has been measured.
  static const double _fallbackHeight = 280;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<double?>(
      valueListenable: height,
      builder: (context, h, _) => SizedBox(
        height: h ?? _fallbackHeight,
        child: ObrCard(
          padding: const EdgeInsets.fromLTRB(
            ObrSpace.s24,
            ObrSpace.s12,
            ObrSpace.s24,
            ObrSpace.s8,
          ),
          child: Column(
            children: [
              SectionHeader(
                title: 'Watchlists',
                seeAllSemanticLabel: 'See all watchlists',
                onSeeAll: () => context.push(AppRoutes.watchlists),
              ),
              const SizedBox(height: ObrSpace.s4),
              const Divider(),
              Expanded(
                child: Center(
                  child: Text(
                    'Content TBD',
                    style: ObrType.bodyMdBook.copyWith(
                      color: ObrColors.gray500,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
