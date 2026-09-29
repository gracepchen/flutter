import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme/obr_tokens.dart';

/// The Investor's Edge mark: a dark-gray square tile with a white rounded
/// diamond ring. Drawn in code so it stays sharp at any size; the launcher
/// icon (assets/icon/) uses the same proportions.
class IeMark extends StatelessWidget {
  const IeMark({super.key, this.size = 128});

  /// Side of the square tile.
  final double size;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: "Investor's Edge",
      image: true,
      child: SizedBox.square(
        dimension: size,
        child: const CustomPaint(painter: _IeMarkPainter()),
      ),
    );
  }
}

class _IeMarkPainter extends CustomPainter {
  const _IeMarkPainter();

  /// Ring's corner-to-corner span as a share of the tile.
  static const double _diagonal = 0.73;

  /// Hole side as a share of the ring's side.
  static const double _hole = 0.37;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(Offset.zero & size, Paint()..color = ObrColors.gray700);

    final side = size.width * _diagonal / math.sqrt2;
    final hole = side * _hole;
    final center = size.center(Offset.zero);

    canvas
      ..save()
      ..translate(center.dx, center.dy)
      ..rotate(math.pi / 4);
    final ring = Path()
      ..fillType = PathFillType.evenOdd
      ..addRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(center: Offset.zero, width: side, height: side),
          Radius.circular(side * 0.07),
        ),
      )
      ..addRect(
        Rect.fromCenter(center: Offset.zero, width: hole, height: hole),
      );
    canvas
      ..drawPath(ring, Paint()..color = ObrColors.gray0)
      ..restore();
  }

  @override
  bool shouldRepaint(_IeMarkPainter oldDelegate) => false;
}
