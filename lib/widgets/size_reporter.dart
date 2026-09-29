import 'package:flutter/widgets.dart';

/// Reports its child's laid-out height to [height] after each layout, so a
/// sibling can match it (e.g. Watchlists matching Recent activity).
class SizeReporter extends StatefulWidget {
  const SizeReporter({super.key, required this.height, required this.child});

  final ValueNotifier<double?> height;
  final Widget child;

  @override
  State<SizeReporter> createState() => _SizeReporterState();
}

class _SizeReporterState extends State<SizeReporter> {
  void _report() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final h = context.size?.height;
      if (h != null && h != widget.height.value) widget.height.value = h;
    });
  }

  @override
  Widget build(BuildContext context) {
    _report();
    // Re-measure when layout changes without a rebuild (e.g. text scale).
    return NotificationListener<SizeChangedLayoutNotification>(
      onNotification: (_) {
        _report();
        return false;
      },
      child: SizeChangedLayoutNotifier(child: widget.child),
    );
  }
}
