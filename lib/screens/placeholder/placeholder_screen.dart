import 'package:flutter/material.dart';

import '../../theme/obr_tokens.dart';
import '../../theme/obr_typography.dart';
import '../../widgets/obr_card.dart';
import '../../widgets/prototype_notice.dart';

/// Shared scaffold for screens that aren't designed yet. It states what the
/// screen is for and what it's planned to hold, so reviewers can walk the
/// navigation model before the screens are designed.
class PlaceholderScreen extends StatelessWidget {
  const PlaceholderScreen({
    super.key,
    required this.title,
    this.icon,
    this.initials,
    required this.summary,
    this.plannedItems = const [],
    this.extra,
    this.footer,
    this.bottomNavigationBar,
  }) : assert(icon != null || initials != null,
            'Provide an icon or initials for the header circle.');

  final String title;
  final IconData? icon;

  /// Shown in place of [icon], e.g. the client's initial on Profile.
  final String? initials;
  final String summary;
  final List<String> plannedItems;

  /// Optional extra state passed in by the route, e.g. a preselected symbol.
  final Widget? extra;

  /// Optional widget at the very bottom, below the prototype notice.
  final Widget? footer;

  /// E.g. the Nav/IA bottom bar on Transfer and Activity.
  final Widget? bottomNavigationBar;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      bottomNavigationBar: bottomNavigationBar,
      appBar: AppBar(title: Text(title)),
      body: SafeArea(
        top: false,
        child: Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 640),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(
                ObrSpace.s20,
                ObrSpace.s8,
                ObrSpace.s20,
                ObrSpace.s32,
              ),
              children: [
                Align(
                  alignment: Alignment.centerLeft,
                  child: Container(
                    width: ObrSize.s72,
                    height: ObrSize.s72,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      // Initials match the gray avatar on Home; icons use
                      // the brand tint.
                      color: initials != null
                          ? ObrColors.gray100
                          : ObrColors.brand100,
                      shape: BoxShape.circle,
                    ),
                    child: initials != null
                        ? ExcludeSemantics(
                            child: Text(
                              initials!,
                              style: ObrType.displaySmSemibold.copyWith(
                                color: ObrColors.gray600,
                              ),
                            ),
                          )
                        : Icon(
                            icon,
                            color: ObrColors.brand700,
                            size: ObrSize.s32,
                          ),
                  ),
                ),
                const SizedBox(height: ObrSpace.s16),
                Semantics(
                  header: true,
                  child: Text(title, style: ObrType.displaySmSemibold),
                ),
                const SizedBox(height: ObrSpace.s8),
                Text(
                  summary,
                  style: ObrType.bodyLgBook.copyWith(color: ObrColors.gray700),
                ),
                if (extra != null) ...[
                  const SizedBox(height: ObrSpace.s16),
                  extra!,
                ],
                if (plannedItems.isNotEmpty) ...[
                  const SizedBox(height: ObrSpace.s24),
                  ObrCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'PLANNED FOR THIS SCREEN',
                          style: ObrType.captionSemibold.copyWith(
                            color: ObrColors.gray600,
                            letterSpacing: 1.2,
                          ),
                        ),
                        const SizedBox(height: ObrSpace.s12),
                        for (final item in plannedItems)
                          Padding(
                            padding: const EdgeInsets.only(
                              bottom: ObrSpace.s12,
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Padding(
                                  padding: const EdgeInsets.only(
                                    top: ObrSpace.s8,
                                  ),
                                  child: Container(
                                    width: 6,
                                    height: 6,
                                    decoration: const BoxDecoration(
                                      color: ObrColors.brand600,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: ObrSpace.s12),
                                Expanded(
                                  child: Text(
                                    item,
                                    style: ObrType.bodyMdBook,
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: ObrSpace.s24),
                const PrototypeNotice(
                  message: 'Prototype placeholder. This screen is not '
                      'designed or connected to live data yet.',
                ),
                if (footer != null) ...[
                  const SizedBox(height: ObrSpace.s24),
                  footer!,
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
