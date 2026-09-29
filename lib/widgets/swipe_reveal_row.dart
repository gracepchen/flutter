import 'package:flutter/material.dart';
// CustomSemanticsAction lives in the semantics library, which material.dart
// doesn't export.
import 'package:flutter/semantics.dart';

import '../theme/obr_tokens.dart';
import '../util/motion.dart';

/// A list row that reveals actions when swiped right to left.
///
/// - [leading] (e.g. name, account number) always stays visible.
/// - [details] (figures) show while closed; [actions] slide in when open.
/// - The row keeps its closed height when open: [actions] get that height
///   with a slim gray-100 inset around them, and scale down if needed.
/// - Long-pressing a closed row opens it too, with the same animation.
/// - While open, the row is highlighted in gray-100. Swiping right or tapping
///   the row closes it; tapping a closed row calls [onTap].
/// - The parent owns which row is open, so only one is open at a time.
/// - Pass [semanticActions] so screen-reader users can reach the same actions
///   without swiping.
class SwipeRevealRow extends StatefulWidget {
  const SwipeRevealRow({
    super.key,
    required this.leading,
    required this.details,
    required this.actions,
    required this.isOpen,
    required this.onOpenChanged,
    required this.onTap,
    this.minLeadingWidth = 96,
    this.semanticActions = const {},
  });

  final Widget leading;
  final Widget details;
  final Widget actions;
  final bool isOpen;
  final ValueChanged<bool> onOpenChanged;
  final VoidCallback onTap;

  /// [leading] never gets narrower than this; [details] and [actions] get the
  /// rest and should scale down (e.g. with a FittedBox) if they need to.
  final double minLeadingWidth;

  /// Label → callback, exposed as custom screen-reader actions.
  final Map<String, VoidCallback> semanticActions;

  /// Inset of the row's content from its edges while closed. Content that
  /// should line up with the rows (e.g. a footnote) uses the same inset.
  static const double contentInset = ObrSpace.s12;

  @override
  State<SwipeRevealRow> createState() => _SwipeRevealRowState();
}

class _SwipeRevealRowState extends State<SwipeRevealRow> {
  /// Minimum drag, in logical pixels, that counts as a swipe.
  static const double _swipeDistance = 32;

  /// Minimum fling speed that counts as a swipe even when short.
  static const double _swipeVelocity = 300;

  static const double _gap = ObrSpace.s12;

  /// Inset around [SwipeRevealRow.actions] while open (top, right, bottom).
  static const double _openInset = 6;

  double _dragDx = 0;

  /// Height of the row (inside its top margin) while closed, measured after
  /// each closed layout so the open row can match it.
  final _contentKey = GlobalKey();
  double? _closedHeight;

  void _measureClosedHeight() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || widget.isOpen) return;
      _closedHeight = _contentKey.currentContext?.size?.height;
    });
  }

  void _onDragEnd(DragEndDetails details) {
    final velocity = details.primaryVelocity ?? 0;
    if (_dragDx < -_swipeDistance || velocity < -_swipeVelocity) {
      widget.onOpenChanged(true);
    } else if (_dragDx > _swipeDistance || velocity > _swipeVelocity) {
      widget.onOpenChanged(false);
    }
    _dragDx = 0;
  }

  @override
  Widget build(BuildContext context) {
    final duration = motionDuration(context, ObrDuration.d250);
    final radius = BorderRadius.circular(ObrRadius.r16);
    final open = widget.isOpen && _closedHeight != null;
    if (!widget.isOpen) _measureClosedHeight();
    final padding = open
        ? const EdgeInsets.fromLTRB(
            ObrSpace.s12,
            _openInset,
            _openInset,
            _openInset,
          )
        : const EdgeInsets.all(SwipeRevealRow.contentInset);

    return Semantics(
      customSemanticsActions: widget.semanticActions.isEmpty
          ? null
          : {
              for (final entry in widget.semanticActions.entries)
                CustomSemanticsAction(label: entry.key): entry.value,
            },
      child: GestureDetector(
        onHorizontalDragStart: (_) => _dragDx = 0,
        onHorizontalDragUpdate: (details) => _dragDx += details.delta.dx,
        onHorizontalDragEnd: _onDragEnd,
        child: AnimatedContainer(
          duration: duration,
          curve: ObrEasing.easeInOut,
          margin: const EdgeInsets.only(top: ObrSpace.s4),
          decoration: BoxDecoration(
            color: widget.isOpen ? ObrColors.gray100 : Colors.transparent,
            borderRadius: radius,
          ),
          child: Material(
            key: _contentKey,
            type: MaterialType.transparency,
            child: InkWell(
              borderRadius: radius,
              onTap: widget.isOpen
                  ? () => widget.onOpenChanged(false)
                  : widget.onTap,
              onLongPress: widget.isOpen
                  ? null
                  : () => widget.onOpenChanged(true),
              child: SizedBox(
                height: open ? _closedHeight : null,
                child: Padding(
                padding: padding,
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final trailingMax =
                        (constraints.maxWidth - widget.minLeadingWidth - _gap)
                            .clamp(0.0, double.infinity);
                    // Open: actions fill the row's height (minus the inset).
                    final trailingMaxHeight =
                        open ? constraints.maxHeight : double.infinity;
                    return Row(
                      children: [
                        Expanded(child: widget.leading),
                        const SizedBox(width: _gap),
                        ConstrainedBox(
                          constraints: BoxConstraints(
                            maxWidth: trailingMax,
                            maxHeight: trailingMaxHeight,
                          ),
                          child: AnimatedSwitcher(
                            duration: duration,
                            switchInCurve: ObrEasing.easeOut,
                            switchOutCurve: ObrEasing.easeIn,
                            transitionBuilder: (child, animation) =>
                                FadeTransition(
                              opacity: animation,
                              child: SlideTransition(
                                position: Tween<Offset>(
                                  begin: const Offset(0.3, 0),
                                  end: Offset.zero,
                                ).animate(animation),
                                child: child,
                              ),
                            ),
                            child: KeyedSubtree(
                              key: ValueKey(widget.isOpen),
                              child: widget.isOpen
                                  ? widget.actions
                                  : widget.details,
                            ),
                          ),
                        ),
                      ],
                    );
                  },
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
