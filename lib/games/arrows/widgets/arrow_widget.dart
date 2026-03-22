import 'dart:math';
import 'package:flutter/material.dart';
import '../models/arrow_node.dart';
import '../arrows_theme.dart';

class ArrowWidget extends StatelessWidget {
  final ArrowDirection direction;
  final bool isInvalid;
  final List<Point<int>> relativeSegments;

  const ArrowWidget({
    Key? key,
    required this.direction,
    required this.relativeSegments,
    this.isInvalid = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size.infinite,
      painter: _ArrowPainter(
        color: isInvalid ? ArrowsTheme.blockedNode : ArrowsTheme.arrowUp,
        direction: direction,
        relativeSegments: relativeSegments,
      ),
    );
  }
}

class _ArrowPainter extends CustomPainter {
  final Color color;
  final ArrowDirection direction;
  final List<Point<int>> relativeSegments;
  
  _ArrowPainter({
    required this.color, 
    required this.direction,
    required this.relativeSegments,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (relativeSegments.isEmpty) return;

    final paint = Paint()
      ..color = color
      ..strokeWidth = 2.8
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..isAntiAlias = true
      ..style = PaintingStyle.stroke;

    final double cellSizeX = size.width / (relativeSegments.map((s) => s.x).reduce(max) - relativeSegments.map((s) => s.x).reduce(min) + 1);
    final double cellSizeY = size.height / (relativeSegments.map((s) => s.y).reduce(max) - relativeSegments.map((s) => s.y).reduce(min) + 1);

    final minX = relativeSegments.map((s) => s.x).reduce(min);
    final minY = relativeSegments.map((s) => s.y).reduce(min);

    // Build the entire body path first for rounded corners
    final Path bodyPath = Path();
    for (int i = 0; i < relativeSegments.length; i++) {
      final p = relativeSegments[i];
      double px = (p.x - minX + 0.5) * cellSizeX;
      double py = (p.y - minY + 0.5) * cellSizeY;
      
      if (i == 0) {
        bodyPath.moveTo(px, py);
      } else {
        bodyPath.lineTo(px, py);
      }
    }
    
    // For length 1, add a tiny tail segment so the stroke is visible
    if (relativeSegments.length == 1) {
      final p = relativeSegments.first;
      double px = (p.x - minX + 0.5) * cellSizeX;
      double py = (p.y - minY + 0.5) * cellSizeY;
      
      double tx = px, ty = py;
      const double tailLen = 6.0;
      switch (direction) {
        case ArrowDirection.up: ty += tailLen; break;
        case ArrowDirection.down: ty -= tailLen; break;
        case ArrowDirection.left: tx += tailLen; break;
        case ArrowDirection.right: tx -= tailLen; break;
      }
      bodyPath.lineTo(tx, ty);
    }

    canvas.drawPath(bodyPath, paint);

    // Draw a sharper, symmetrical filled arrowhead at the FIRST segment (the head)
    final headPoint = relativeSegments.first;
    final double headX = (headPoint.x - minX + 0.5) * cellSizeX;
    final double headY = (headPoint.y - minY + 0.5) * cellSizeY;

    final headPaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill
      ..isAntiAlias = true;

    final Path headPath = Path();
    const double headSize = 12.0;
    const double headAngle = 0.5;

    if (direction == ArrowDirection.right) {
      headPath.moveTo(headX + 2, headY);
      headPath.lineTo(headX + 2 - headSize, headY - headSize * headAngle);
      headPath.lineTo(headX + 2 - headSize, headY + headSize * headAngle);
    } else if (direction == ArrowDirection.left) {
      headPath.moveTo(headX - 2, headY);
      headPath.lineTo(headX - 2 + headSize, headY - headSize * headAngle);
      headPath.lineTo(headX - 2 + headSize, headY + headSize * headAngle);
    } else if (direction == ArrowDirection.down) {
      headPath.moveTo(headX, headY + 2);
      headPath.lineTo(headX - headSize * headAngle, headY + 2 - headSize);
      headPath.lineTo(headX + headSize * headAngle, headY + 2 - headSize);
    } else if (direction == ArrowDirection.up) {
      headPath.moveTo(headX, headY - 2);
      headPath.lineTo(headX - headSize * headAngle, headY - 2 + headSize);
      headPath.lineTo(headX + headSize * headAngle, headY - 2 + headSize);
    }
    
    headPath.close();
    canvas.drawPath(headPath, headPaint);
  }

  @override
  bool shouldRepaint(covariant _ArrowPainter oldDelegate) {
    return oldDelegate.color != color || oldDelegate.direction != direction || oldDelegate.relativeSegments != relativeSegments;
  }
}
