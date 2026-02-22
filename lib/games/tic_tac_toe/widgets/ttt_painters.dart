import 'package:flutter/material.dart';

class WinningLinePainter extends CustomPainter {
  final List<Offset> points;
  final Color color;
  final double progress;

  WinningLinePainter({
    required this.points,
    required this.color,
    required this.progress,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (points.isEmpty) return;

    final paint = Paint()
      ..color = color
      ..strokeWidth = 10
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    final glowPaint = Paint()
      ..color = color.withOpacity(0.5)
      ..strokeWidth = 20
      ..strokeCap = StrokeCap.round
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10)
      ..style = PaintingStyle.stroke;

    final path = Path();
    path.moveTo(points.first.dx, points.first.dy);

    for (var i = 1; i < points.length; i++) {
      path.lineTo(points[i].dx, points[i].dy);
    }

    final pathMetrics = path.computeMetrics();
    for (final metric in pathMetrics) {
      final extractPath = metric.extractPath(0, metric.length * progress);
      canvas.drawPath(extractPath, glowPaint);
      canvas.drawPath(extractPath, paint);
    }
  }

  @override
  bool shouldRepaint(covariant WinningLinePainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}

class GridPaiter extends CustomPainter {
  final int size;
  final Color color;
  final double opacity;

  GridPaiter({required this.size, required this.color, this.opacity = 0.2});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color.withOpacity(opacity)
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;

    final cellWidth = size.width / this.size;
    final cellHeight = size.height / this.size;

    for (int i = 1; i < this.size; i++) {
      // Vertical lines
      canvas.drawLine(
        Offset(i * cellWidth, 10),
        Offset(i * cellWidth, size.height - 10),
        paint,
      );
      // Horizontal lines
      canvas.drawLine(
        Offset(10, i * cellHeight),
        Offset(size.width - 10, i * cellHeight),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
