import 'package:flutter/material.dart';

class SketchPainter extends CustomPainter {
  final List<Sketch> sketches;

  SketchPainter({required this.sketches});

  @override
  void paint(Canvas canvas, Size size) {
    for (Sketch sketch in sketches) {
      final points = sketch.points;
      if (points.isEmpty) continue;

      final path = Path();
      path.moveTo(points[0].dx, points[0].dy);

      for (int i = 1; i < points.length; ++i) {
        path.lineTo(points[i].dx, points[i].dy);
      }

      Paint paint = Paint()
        ..color = sketch.color // Use the color from the Sketch object
        ..strokeCap = StrokeCap.round
        ..style = sketch.filled ? PaintingStyle.fill : PaintingStyle.stroke
        ..strokeWidth = sketch.size;

      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return true;
  }
}

class Sketch {
  final List<Offset> points;
  final double size;
  final bool filled;
  final Color color;

  Sketch({
    required this.points,
    required this.size,
    this.filled = false,
    required this.color,
  });
}
