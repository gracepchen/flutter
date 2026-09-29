import 'package:flutter/material.dart';

import '../../../theme/obr_tokens.dart';
import '../../../util/motion.dart';

/// Area line chart. It draws on from left to right when it first builds
/// (give it a new key to replay), and draws instantly under reduced motion.
class PortfolioChart extends StatelessWidget {
  const PortfolioChart({
    super.key,
    required this.points,
    required this.semanticLabel,
    this.lineColor = ObrColors.green500,
    this.fillColor = ObrColors.green300,
  });

  final List<double> points;
  final String semanticLabel;
  final Color lineColor;
  final Color fillColor;

  @override
  Widget build(BuildContext context) {
    final duration = motionDuration(context, ObrDuration.d600);
    return Semantics(
      label: semanticLabel,
      image: true,
      child: ExcludeSemantics(
        child: TweenAnimationBuilder<double>(
          tween: Tween(begin: duration == Duration.zero ? 1 : 0, end: 1),
          duration: duration,
          curve: ObrEasing.easeOut,
          builder: (context, progress, _) => CustomPaint(
            size: Size.infinite,
            painter: _ChartPainter(
              points: points,
              progress: progress,
              lineColor: lineColor,
              fillColor: fillColor,
            ),
          ),
        ),
      ),
    );
  }
}

class _ChartPainter extends CustomPainter {
  _ChartPainter({
    required this.points,
    required this.progress,
    required this.lineColor,
    required this.fillColor,
  });

  final List<double> points;
  final double progress;
  final Color lineColor;
  final Color fillColor;

  static const double _strokeWidth = 1.5;

  @override
  void paint(Canvas canvas, Size size) {
    if (points.length < 2 || size.isEmpty) return;

    var minValue = points.first;
    var maxValue = points.first;
    for (final p in points) {
      if (p < minValue) minValue = p;
      if (p > maxValue) maxValue = p;
    }
    final range = maxValue - minValue == 0 ? 1.0 : maxValue - minValue;

    // Keep the line in the top ~80% so the fill has a visible floor, as in the mock.
    const top = _strokeWidth;
    final plotHeight = size.height * 0.8 - top;
    double x(int i) => i / (points.length - 1) * size.width;
    double y(double v) => top + (1 - (v - minValue) / range) * plotHeight;

    final line = Path()..moveTo(x(0), y(points.first));
    for (var i = 1; i < points.length; i++) {
      line.lineTo(x(i), y(points[i]));
    }

    final fill = Path.from(line)
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();

    final bounds = Offset.zero & size;
    canvas.drawPath(
      fill,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            fillColor.withValues(alpha: 0.30 * progress),
            fillColor.withValues(alpha: 0.06 * progress),
          ],
        ).createShader(bounds),
    );

    final visibleLine = Path();
    for (final metric in line.computeMetrics()) {
      visibleLine.addPath(
        metric.extractPath(0, metric.length * progress),
        Offset.zero,
      );
    }
    canvas.drawPath(
      visibleLine,
      Paint()
        ..color = lineColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = _strokeWidth
        ..strokeJoin = StrokeJoin.round
        ..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(_ChartPainter oldDelegate) =>
      oldDelegate.progress != progress ||
      !identical(oldDelegate.points, points) ||
      oldDelegate.lineColor != lineColor ||
      oldDelegate.fillColor != fillColor;
}
