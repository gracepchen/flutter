import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../router.dart';
import '../../../theme/obr_tokens.dart';
import '../../../theme/obr_typography.dart';

/// Shared by the app-bar search pill and the search screen's field, so the
/// pill morphs into the search field on navigation.
const String searchHeroTag = 'search-bar';

/// Floating search button at the bottom left of Home. Tapping it opens the
/// blank search page (recent searches, market overview, ideas) with the
/// field focused.
///
/// This is a single-destination starting point. When more top-level
/// destinations exist, move them into this dock and put it in a
/// go_router StatefulShellRoute so each tab keeps its own stack.
class BottomDock extends StatelessWidget {
  const BottomDock({super.key});

  static const double height = ObrSize.s64;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      minimum: const EdgeInsets.only(bottom: ObrSpace.s12),
      child: const Padding(
        padding: EdgeInsets.symmetric(horizontal: ObrSpace.s16),
        child: Align(
          alignment: Alignment.centerLeft,
          child: _SearchButton(),
        ),
      ),
    );
  }
}

class _SearchButton extends StatelessWidget {
  const _SearchButton();

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: 'Search stocks and ETFs',
      child: Semantics(
        button: true,
        label: 'Search stocks and ETFs',
        excludeSemantics: true,
        child: DecoratedBox(
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            boxShadow: ObrShadow.s4,
          ),
          child: Material(
            color: ObrColors.gray700,
            shape: const CircleBorder(
              side: BorderSide(
                color: ObrColors.gray100,
                width: ObrBorderWidth.w4,
              ),
            ),
            child: InkWell(
              customBorder: const CircleBorder(),
              onTap: () => context.push(AppRoutes.search),
              child: const SizedBox.square(
                dimension: BottomDock.height,
                child: Icon(
                  Icons.search,
                  color: ObrColors.gray0,
                  size: ObrSize.s28,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Search pill used in app bars (e.g. stock details). It morphs into the
/// search field on navigation (shared Hero).
class SearchPill extends StatelessWidget {
  const SearchPill({super.key, this.height = BottomDock.height});

  /// Pill height; 52 in the stock details app bar.
  final double height;

  @override
  Widget build(BuildContext context) {
    return Hero(
      tag: searchHeroTag,
      child: SearchPillSurface(
        height: height,
        child: Semantics(
          button: true,
          label: 'Search stock or ETF',
          excludeSemantics: true,
          child: InkWell(
            customBorder: const StadiumBorder(),
            onTap: () => context.push(AppRoutes.search),
            child: const SearchPillLabel(),
          ),
        ),
      ),
    );
  }
}

/// Glass pill: frosted translucent white (alpha-white-85 over blur-22),
/// gray-200 hairline and shadow-4.
class SearchPillSurface extends StatelessWidget {
  const SearchPillSurface({
    super.key,
    required this.child,
    this.opaque = false,
    this.height = BottomDock.height,
  });

  final Widget child;
  final bool opaque;
  final double height;

  @override
  Widget build(BuildContext context) {
    const radius = BorderRadius.all(Radius.circular(ObrRadius.full));
    return DecoratedBox(
      decoration: const BoxDecoration(
        borderRadius: radius,
        boxShadow: ObrShadow.s4,
      ),
      child: ClipRRect(
        borderRadius: radius,
        child: BackdropFilter(
          filter: ui.ImageFilter.blur(
            sigmaX: ObrBlur.b22,
            sigmaY: ObrBlur.b22,
          ),
          child: Material(
            color: opaque ? ObrColors.gray0 : ObrColors.alphaWhite85,
            shape: const StadiumBorder(
              side: BorderSide(color: ObrColors.gray200),
            ),
            child: SizedBox(height: height, child: child),
          ),
        ),
      ),
    );
  }
}

class SearchPillLabel extends StatelessWidget {
  const SearchPillLabel({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: ObrSpace.s24),
      child: Row(
        children: [
          const Icon(Icons.search, color: ObrColors.gray700, size: 26),
          const SizedBox(width: ObrSpace.s12),
          Flexible(
            child: Text(
              'Search stock or ETF',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              // Placeholder text: lighter than entered text.
              style: ObrType.bodyLgBook.copyWith(color: ObrColors.gray500),
            ),
          ),
        ],
      ),
    );
  }
}
