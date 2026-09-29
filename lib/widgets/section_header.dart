import 'package:flutter/material.dart';

import '../theme/obr_tokens.dart';
import '../theme/obr_typography.dart';

/// Card title with an optional "See all ›" link.
class SectionHeader extends StatelessWidget {
  const SectionHeader({
    super.key,
    required this.title,
    this.onSeeAll,
    this.seeAllSemanticLabel,
  });

  final String title;
  final VoidCallback? onSeeAll;

  /// What a screen reader says for the link, e.g. "See all accounts".
  final String? seeAllSemanticLabel;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Semantics(
            header: true,
            child: Text(title, style: ObrType.headingMdSemibold),
          ),
        ),
        if (onSeeAll != null)
          Semantics(
            button: true,
            label: seeAllSemanticLabel ?? 'See all',
            excludeSemantics: true,
            child: InkWell(
              onTap: onSeeAll,
              borderRadius: BorderRadius.circular(ObrRadius.r8),
              child: ConstrainedBox(
                constraints: const BoxConstraints(
                  minHeight: ObrSize.s44,
                  minWidth: ObrSize.s44,
                ),
                child: Padding(
                  padding: const EdgeInsets.only(left: ObrSpace.s8),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'See all',
                        style: ObrType.bodyMdBook.copyWith(
                          color: ObrColors.gray600,
                        ),
                      ),
                      const Icon(
                        Icons.chevron_right,
                        size: 18,
                        color: ObrColors.gray600,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
