import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../router.dart';
import '../screens/search_screen.dart';
import '../state/nav_version.dart';
import '../theme/obr_tokens.dart';
import '../theme/obr_typography.dart';
import '../util/motion.dart';

/// Where the bottom bar is shown.
enum NavDestination { home, search, transfer, activity }

/// Bottom navigation for Nav/IA versions B, C and D (nothing in version A,
/// which uses Home's floating search button instead).
///
/// - B, Search with shortcuts: Home, a search bar and Shortcuts (a blurred
///   overlay with Move money, Activity and Trade).
/// - C, Search with actions: Home, a search bar, Transfers and Activity.
/// - D, Tabs: Home, Explore (blank search), Move (Transfers) and Activity.
///
/// On Search, B and C shrink (animated) to a centred row of icons with
/// Search selected.
class AppNavBar extends StatelessWidget {
  const AppNavBar({super.key, required this.current});

  final NavDestination current;

  static const double height = ObrSize.s64;

  @override
  Widget build(BuildContext context) {
    final version = NavVersionScope.versionOf(context);
    if (version == NavVersion.searchOnly) return const SizedBox.shrink();

    final Widget bar = switch (version) {
      NavVersion.tabs => _TabBar(current: current),
      _ => _SearchBarNav(version: version, current: current),
    };
    return DecoratedBox(
      decoration: const BoxDecoration(
        color: ObrColors.gray50,
        border: Border(top: BorderSide(color: ObrColors.gray200)),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(height: height, child: bar),
      ),
    );
  }
}

void _go(BuildContext context, String location) => context.go(location);

// ─── B and C: Home, search bar, actions ───────────────────────────────────

class _NavAction {
  const _NavAction(
    this.icon,
    this.tooltip,
    this.onTap, {
    this.selected = false,
    this.onTapAt,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;
  final bool selected;

  /// Used instead of [onTap] when the action needs to know where its icon
  /// is on screen (the Shortcuts overlay lines up with it).
  final void Function(Rect iconRect)? onTapAt;
}

class _SearchBarNav extends StatelessWidget {
  const _SearchBarNav({required this.version, required this.current});

  final NavVersion version;
  final NavDestination current;

  static const double _slot = ObrSize.s56;

  @override
  Widget build(BuildContext context) {
    final onSearch = current == NavDestination.search;
    final trailing = version == NavVersion.shortcuts
        ? [
            _NavAction(
              Icons.bolt_outlined,
              'Shortcuts',
              () {},
              onTapAt: (rect) => showShortcutsOverlay(context, anchor: rect),
            ),
          ]
        : [
            _NavAction(
              Icons.swap_horiz,
              'Transfers',
              () => _go(context, AppRoutes.transfer),
              selected: current == NavDestination.transfer,
            ),
            _NavAction(
              Icons.timer_outlined,
              'Activity',
              () => _go(context, AppRoutes.activity),
              selected: current == NavDestination.activity,
            ),
          ];

    // On Search the bar starts expanded and animates to the compact icons,
    // so the search bar visibly shrinks into its icon.
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: onSearch ? 1 : 0),
      duration: motionDuration(context, ObrDuration.d300),
      curve: ObrEasing.easeInOut,
      builder: (context, t, _) => LayoutBuilder(
        builder: (context, constraints) {
          final slots = (1 + trailing.length) * _slot;
          final fullPill = (constraints.maxWidth - slots - ObrSpace.s16)
              .clamp(_slot, double.infinity);
          final pillWidth = ui.lerpDouble(fullPill, _slot, t)!;
          return Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _NavIcon(
                action: _NavAction(
                  Icons.home_outlined,
                  'Home',
                  () => _go(context, AppRoutes.home),
                  selected: current == NavDestination.home,
                ),
              ),
              SizedBox(
                width: pillWidth,
                child: _MorphingSearch(
                  t: t,
                  selected: onSearch,
                  // Already on Search: bring the keyboard up instead.
                  onTap: () => onSearch
                      ? SearchScreen.focusField(context)
                      : _go(context, AppRoutes.search),
                ),
              ),
              for (final a in trailing) _NavIcon(action: a),
            ],
          );
        },
      ),
    );
  }
}

/// Search bar at t = 0, a search icon at t = 1.
class _MorphingSearch extends StatelessWidget {
  const _MorphingSearch({
    required this.t,
    required this.selected,
    required this.onTap,
  });

  final double t;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final pillOpacity = (1 - t).clamp(0.0, 1.0);
    return Tooltip(
      message: 'Search stocks & ETFs',
      child: Semantics(
        button: true,
        selected: selected,
        label: 'Search stocks and ETFs',
        excludeSemantics: true,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: onTap,
          child: SizedBox(
            height: ObrSize.s48,
            child: Stack(
              alignment: Alignment.center,
              children: [
                // The pill.
                Positioned.fill(
                  child: Opacity(
                    opacity: pillOpacity,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: ObrColors.gray0,
                        borderRadius: BorderRadius.circular(ObrRadius.full),
                        border: Border.all(color: ObrColors.gray200),
                        boxShadow: ObrShadow.s4,
                      ),
                      child: ClipRect(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: ObrSpace.s16,
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.search,
                                color: ObrColors.gray700,
                              ),
                              const SizedBox(width: ObrSpace.s8),
                              Expanded(
                                child: Text(
                                  'Search stocks & ETFs',
                                  maxLines: 1,
                                  overflow: TextOverflow.clip,
                                  softWrap: false,
                                  style: ObrType.bodyLgBook.copyWith(
                                    color: ObrColors.gray500,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                // The icon it becomes.
                Opacity(
                  opacity: t.clamp(0.0, 1.0),
                  child: _IconGlyph(icon: Icons.search, selected: selected),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _NavIcon extends StatelessWidget {
  const _NavIcon({required this.action});

  final _NavAction action;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: _SearchBarNav._slot,
      height: ObrSize.s48,
      child: Tooltip(
        message: action.tooltip,
        child: Semantics(
          button: true,
          selected: action.selected,
          label: action.tooltip,
          excludeSemantics: true,
          child: InkResponse(
            onTap: () {
              final onTapAt = action.onTapAt;
              if (onTapAt == null) {
                action.onTap();
                return;
              }
              // This icon's slot, in screen coordinates.
              final box = context.findRenderObject()! as RenderBox;
              onTapAt(box.localToGlobal(Offset.zero) & box.size);
            },
            radius: 24,
            child: Center(
              child: _IconGlyph(icon: action.icon, selected: action.selected),
            ),
          ),
        ),
      ),
    );
  }
}

/// Dark-gray outline icon; selected gets a medium-gray disc behind it.
class _IconGlyph extends StatelessWidget {
  const _IconGlyph({required this.icon, required this.selected});

  final IconData icon;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: ObrSize.s40,
      height: ObrSize.s40,
      decoration: BoxDecoration(
        // Selected: medium-gray disc behind the dark-gray icon.
        color: selected ? ObrColors.gray300 : Colors.transparent,
        shape: BoxShape.circle,
      ),
      child: Icon(icon, color: ObrColors.gray700, size: ObrSize.s28),
    );
  }
}

// ─── B: Shortcuts overlay ─────────────────────────────────────────────────

/// Blurred overlay with Move money, Activity and Trade sliding in above the
/// Shortcuts button. Tapping outside (or the close button) dismisses it.
///
/// [anchor] is the Shortcuts button's slot on screen: the close button takes
/// its place and the links' icons line up above its icon (it sits at the
/// right edge on Home and in the middle on Search).
Future<void> showShortcutsOverlay(
  BuildContext context, {
  required Rect anchor,
}) {
  // Opening or closing the menu shouldn't bring the keyboard up (on Search
  // the page stays as it is, keyboard down).
  FocusManager.instance.primaryFocus?.unfocus();
  final items = [
    (Icons.swap_horiz, 'Move money', AppRoutes.transfer),
    (Icons.timer_outlined, 'Activity', AppRoutes.activity),
    (Icons.trending_up, 'Trade', AppRoutes.trade),
  ];
  return showGeneralDialog<void>(
    context: context,
    barrierDismissible: true,
    barrierLabel: 'Close shortcuts',
    barrierColor: Colors.transparent,
    transitionDuration: motionDuration(context, ObrDuration.d300),
    pageBuilder: (dialogContext, animation, _) {
      final screen = MediaQuery.sizeOf(dialogContext);
      void open(String location) {
        Navigator.of(dialogContext).pop();
        if (location == AppRoutes.trade) {
          context.push(location);
        } else {
          context.go(location);
        }
      }

      // Dialog routes have no Material ancestor; the links and close button
      // need one for their ink splashes.
      return Material(
        type: MaterialType.transparency,
        child: Stack(
        children: [
          // Blurred, lightened backdrop; tap to close.
          Positioned.fill(
            child: GestureDetector(
              onTap: () => Navigator.of(dialogContext).pop(),
              child: FadeTransition(
                opacity: animation,
                child: BackdropFilter(
                  filter: ui.ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                  child: const ColoredBox(color: Color(0xB3FFFFFF)),
                ),
              ),
            ),
          ),
          // Each link is "label  icon" with 12pt padding; put the icon's
          // centre (14pt in from the icon's right edge) over the anchor's.
          Positioned(
            right: screen.width -
                (anchor.center.dx + ObrSize.s28 / 2 + _ShortcutItem.padding),
            bottom: screen.height - anchor.top + ObrSpace.s8,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisSize: MainAxisSize.min,
              children: [
                for (var i = 0; i < items.length; i++)
                  _ShortcutItem(
                    // Staggered: the bottom item arrives first.
                    animation: CurvedAnimation(
                      parent: animation,
                      curve: Interval(
                        (items.length - 1 - i) * 0.15,
                        1,
                        curve: ObrEasing.easeOut,
                      ),
                    ),
                    icon: items[i].$1,
                    label: items[i].$2,
                    onTap: () => open(items[i].$3),
                  ),
              ],
            ),
          ),
          // Close button where the Shortcuts button sits.
          Positioned.fromRect(
            rect: anchor,
            child: FadeTransition(
              opacity: animation,
              child: Center(
                child: IconButton(
                  tooltip: 'Close shortcuts',
                  onPressed: () => Navigator.of(dialogContext).pop(),
                  icon: const Icon(Icons.close),
                  color: ObrColors.gray700,
                  iconSize: ObrSize.s28,
                ),
              ),
            ),
          ),
        ],
        ),
      );
    },
  );
}

class _ShortcutItem extends StatelessWidget {
  static const double padding = ObrSpace.s12;

  const _ShortcutItem({
    required this.animation,
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final Animation<double> animation;
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: animation,
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0.3, 0.2),
          end: Offset.zero,
        ).animate(animation),
        child: Semantics(
          button: true,
          label: label,
          excludeSemantics: true,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(ObrRadius.r12),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: padding,
                vertical: ObrSpace.s8,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    label,
                    style: ObrType.headingSm.copyWith(
                      color: ObrColors.gray900,
                    ),
                  ),
                  const SizedBox(width: ObrSpace.s16),
                  Icon(icon, color: ObrColors.gray700, size: ObrSize.s28),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ─── D: Tabs ──────────────────────────────────────────────────────────────

class _TabBar extends StatelessWidget {
  const _TabBar({required this.current});

  final NavDestination current;

  @override
  Widget build(BuildContext context) {
    final tabs = [
      (NavDestination.home, Icons.home_outlined, 'Home', AppRoutes.home),
      (NavDestination.search, Icons.search, 'Explore', AppRoutes.search),
      (NavDestination.transfer, Icons.swap_horiz, 'Move', AppRoutes.transfer),
      (
        NavDestination.activity,
        Icons.timer_outlined,
        'Activity',
        AppRoutes.activity,
      ),
    ];
    return Row(
      children: [
        for (final (dest, icon, label, location) in tabs)
          Expanded(
            child: Semantics(
              button: true,
              selected: dest == current,
              label: label,
              excludeSemantics: true,
              child: InkResponse(
                onTap: () => dest == NavDestination.search &&
                        current == NavDestination.search
                    ? SearchScreen.focusField(context)
                    : _go(context, location),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Selected: medium-gray pill behind the dark-gray icon.
                    Container(
                      width: ObrSize.s56,
                      height: ObrSize.s32,
                      decoration: BoxDecoration(
                        color: dest == current
                            ? ObrColors.gray300
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(ObrRadius.full),
                      ),
                      child: Icon(
                        icon,
                        color: ObrColors.gray700,
                        size: ObrSize.s24,
                      ),
                    ),
                    const SizedBox(height: ObrSpace.s2),
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                      label,
                      maxLines: 1,
                      style: ObrType.labelMd.copyWith(
                        color: dest == current
                            ? ObrColors.gray900
                            : ObrColors.gray700,
                        fontWeight: dest == current
                            ? FontWeight.w600
                            : FontWeight.w400,
                      ),
                    ),
                    ),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }
}
