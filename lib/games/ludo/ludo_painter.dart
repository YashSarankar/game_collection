import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'ludo_theme.dart';

class LudoBoardPainter extends CustomPainter {
  LudoBoardPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final double cellSize = size.width / 15;
    final Paint paint = Paint()..style = PaintingStyle.fill;

    // Draw Board Background — warm cream tone
    paint.color = const Color(0xFFFBFBFC);
    canvas.drawRect(Offset.zero & size, paint);

    // Draw Grid Lines (Subtle)
    final gridPaint = Paint()
      ..color = Colors.black.withOpacity(0.15)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.5;

    for (int i = 0; i <= 15; i++) {
      canvas.drawLine(
        Offset(i * cellSize, 0),
        Offset(i * cellSize, size.height),
        gridPaint,
      );
      canvas.drawLine(
        Offset(0, i * cellSize),
        Offset(size.width, i * cellSize),
        gridPaint,
      );
    }

    // 1. Draw Houses (Bases)
    _drawHouse(canvas, cellSize, 0, 0, LudoTheme.red);
    _drawHouse(canvas, cellSize, 0, 9, LudoTheme.green);
    _drawHouse(canvas, cellSize, 9, 0, LudoTheme.blue);
    _drawHouse(canvas, cellSize, 9, 9, LudoTheme.yellow);

    // 2. Draw Paths (Home Strengths)
    _drawPath(canvas, cellSize, 7, 1, 5, LudoTheme.red, true);
    _drawPath(canvas, cellSize, 1, 7, 5, LudoTheme.green, false);
    _drawPath(canvas, cellSize, 9, 7, 5, LudoTheme.blue, false);
    _drawPath(canvas, cellSize, 7, 9, 5, LudoTheme.yellow, true);

    // 3. Draw Start Squares
    _drawCell(canvas, cellSize, 6, 1, LudoTheme.red, hasArrow: true);
    _drawCell(canvas, cellSize, 1, 8, LudoTheme.green, hasArrow: true);
    _drawCell(canvas, cellSize, 13, 6, LudoTheme.blue, hasArrow: true);
    _drawCell(canvas, cellSize, 8, 13, LudoTheme.yellow, hasArrow: true);

    // 4. Draw Safe Squares (Stars)
    _drawStar(canvas, cellSize, 6, 12);
    _drawStar(canvas, cellSize, 8, 2);
    _drawStar(canvas, cellSize, 2, 6);
    _drawStar(canvas, cellSize, 12, 8);

    // 5. Draw Center Winning Area
    _drawCenter(canvas, cellSize, size);
  }

  void _drawHouse(Canvas canvas, double cellSize, int r, int c, Color color) {
    final rect = Rect.fromLTWH(
      c * cellSize,
      r * cellSize,
      6 * cellSize,
      6 * cellSize,
    );

    // House Outer Border
    final paint = Paint()
      ..color = color.withOpacity(0.3)
      ..style = PaintingStyle.fill;
    canvas.drawRect(rect.deflate(2), paint);

    final borderPaint = Paint()
      ..color = color.withOpacity(0.8)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    canvas.drawRect(rect.deflate(2), borderPaint);

    // House White Circle Area
    final circleRect = rect.deflate(cellSize);
    paint.color = Colors.white70;
    canvas.drawRect(circleRect, paint);

    // Token Slots
    final slotSize = cellSize * 0.9;

    _drawTokenSlot(
      canvas,
      (r + 2.1) * cellSize,
      (c + 2.1) * cellSize,
      slotSize,
      color,
    );
    _drawTokenSlot(
      canvas,
      (r + 2.1) * cellSize,
      (c + 3.9) * cellSize,
      slotSize,
      color,
    );
    _drawTokenSlot(
      canvas,
      (r + 3.9) * cellSize,
      (c + 2.1) * cellSize,
      slotSize,
      color,
    );
    _drawTokenSlot(
      canvas,
      (r + 3.9) * cellSize,
      (c + 3.9) * cellSize,
      slotSize,
      color,
    );
  }

  void _drawTokenSlot(
    Canvas canvas,
    double centerY,
    double centerX,
    double size,
    Color color,
  ) {
    final paint = Paint()
      ..color = color.withOpacity(0.1)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(centerX, centerY), size / 2, paint);

    paint.color = color.withOpacity(0.3);
    paint.style = PaintingStyle.stroke;
    paint.strokeWidth = 1.5;
    canvas.drawCircle(Offset(centerX, centerY), size / 2, paint);
  }

  void _drawPath(
    Canvas canvas,
    double cellSize,
    int r,
    int c,
    int length,
    Color color,
    bool horizontal,
  ) {
    for (int i = 0; i < length; i++) {
      int currR = horizontal
          ? r
          : (color == LudoTheme.green ? r + i : r + length - 1 - i);
      int currC = horizontal
          ? (color == LudoTheme.red ? c + i : c + length - 1 - i)
          : c;

      _drawCell(canvas, cellSize, currR, currC, color);
    }
  }

  void _drawCell(
    Canvas canvas,
    double cellSize,
    int r,
    int c,
    Color color, {
    bool hasArrow = false,
  }) {
    final rect = Rect.fromLTWH(
      c * cellSize,
      r * cellSize,
      cellSize,
      cellSize,
    ).deflate(1);
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;
    canvas.drawRect(rect, paint);

    if (hasArrow) {
      _drawIndicatorArrow(canvas, rect, color);
    }
  }

  void _drawIndicatorArrow(Canvas canvas, Rect rect, Color color) {
    final paint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;

    final center = rect.center;
    final size = rect.width * 0.4;
    final path = Path();

    path.moveTo(center.dx - size / 2, center.dy + size / 3);
    path.lineTo(center.dx + size / 2, center.dy + size / 3);
    path.lineTo(center.dx, center.dy - size / 2);
    path.close();

    canvas.drawPath(path, paint);
  }

  void _drawStar(Canvas canvas, double cellSize, int r, int c) {
    final center = Offset((c + 0.5) * cellSize, (r + 0.5) * cellSize);
    _drawStarShape(canvas, center, cellSize * 0.35, Colors.black12);
  }

  void _drawStarShape(
    Canvas canvas,
    Offset center,
    double radius,
    Color color,
  ) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final path = Path();
    final double innerRadius = radius / 2.5;
    const int points = 5;

    for (int i = 0; i < points * 2; i++) {
      final double r = i.isEven ? radius : innerRadius;
      final double angle = (i * 3.14159 / points) - (3.14159 / 2);
      final double x = center.dx + r * math.cos(angle);
      final double y = center.dy + r * math.sin(angle);
      if (i == 0)
        path.moveTo(x, y);
      else
        path.lineTo(x, y);
    }
    path.close();
    canvas.drawPath(path, paint);
  }

  void _drawCenter(Canvas canvas, double cellSize, Size size) {
    final centerRect = Rect.fromLTWH(
      6 * cellSize,
      6 * cellSize,
      3 * cellSize,
      3 * cellSize,
    );
    final center = centerRect.center;

    // Draw 4 triangles
    _drawTriangle(
      canvas,
      center,
      Offset(6 * cellSize, 6 * cellSize),
      Offset(9 * cellSize, 6 * cellSize),
      LudoTheme.green,
    );
    _drawTriangle(
      canvas,
      center,
      Offset(9 * cellSize, 6 * cellSize),
      Offset(9 * cellSize, 9 * cellSize),
      LudoTheme.yellow,
    );
    _drawTriangle(
      canvas,
      center,
      Offset(9 * cellSize, 9 * cellSize),
      Offset(6 * cellSize, 9 * cellSize),
      LudoTheme.blue,
    );
    _drawTriangle(
      canvas,
      center,
      Offset(6 * cellSize, 9 * cellSize),
      Offset(6 * cellSize, 6 * cellSize),
      LudoTheme.red,
    );

    // Center Gloss
    final paint = Paint()
      ..shader = RadialGradient(
        colors: [Colors.white.withOpacity(0.2), Colors.transparent],
      ).createShader(centerRect)
      ..style = PaintingStyle.fill;
    canvas.drawRect(centerRect, paint);
  }

  void _drawTriangle(
    Canvas canvas,
    Offset p1,
    Offset p2,
    Offset p3,
    Color color,
  ) {
    final path = Path()
      ..moveTo(p1.dx, p1.dy)
      ..lineTo(p2.dx, p2.dy)
      ..lineTo(p3.dx, p3.dy)
      ..close();

    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
