import 'package:flutter/material.dart';

import '../theme/obr_tokens.dart';

/// White surface with a gray-200 hairline and radius-20 corners.
/// Pass [onTap] to make the whole card one tappable target.
class ObrCard extends StatelessWidget {
  const ObrCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(ObrSpace.s24),
    this.onTap,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final content = Padding(padding: padding, child: child);
    return Material(
      color: ObrColors.gray0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(ObrRadius.r20),
        side: const BorderSide(color: ObrColors.gray200),
      ),
      clipBehavior: Clip.antiAlias,
      child: onTap == null
          ? content
          : MergeSemantics(
              child: Semantics(
                button: true,
                child: InkWell(onTap: onTap, child: content),
              ),
            ),
    );
  }
}
