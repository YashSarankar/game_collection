import 'package:flutter/material.dart';
import 'dart:math';

class DiceWidget extends StatefulWidget {
  final int value;
  final bool isRolling;
  final VoidCallback onTap;
  final bool canRoll;
  final double size;

  const DiceWidget({
    super.key,
    required this.value,
    required this.isRolling,
    required this.onTap,
    required this.canRoll,
    this.size = 70,
  });

  @override
  State<DiceWidget> createState() => _DiceWidgetState();
}

class _DiceWidgetState extends State<DiceWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
  }

  @override
  void didUpdateWidget(DiceWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isRolling && !oldWidget.isRolling) {
      _controller.repeat();
    } else if (!widget.isRolling && oldWidget.isRolling) {
      _controller.stop();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.canRoll && !widget.isRolling ? widget.onTap : null,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          double rotation = widget.isRolling ? _controller.value * 2 * pi : 0;
          double scale = widget.isRolling
              ? 0.9 + (sin(_controller.value * pi) * 0.1)
              : 1.0;

          return Transform.rotate(
            angle: rotation,
            child: Transform.scale(
              scale: scale,
              child: Container(
                width: widget.size,
                height: widget.size,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(4),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.25),
                      blurRadius: 6,
                      offset: const Offset(0, 3),
                    ),
                    const BoxShadow(
                      color: Colors.white,
                      blurRadius: 1,
                      spreadRadius: -1,
                      offset: Offset(-1, -1),
                    ),
                  ],
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Colors.white, Color(0xFFE8E8E8)],
                  ),
                ),
                child: CustomPaint(
                  painter: DiceDotsPainter(value: widget.value),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class DiceDotsPainter extends CustomPainter {
  final int value;
  DiceDotsPainter({required this.value});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF333333)
      ..style = PaintingStyle.fill;

    final double radius = size.width * 0.08;
    final double padding = size.width * 0.2;

    void drawDot(double x, double y) {
      canvas.drawCircle(Offset(x, y), radius, paint);
      // Add a small reflect to dots
      canvas.drawCircle(
        Offset(x - radius * 0.3, y - radius * 0.3),
        radius * 0.2,
        Paint()..color = Colors.white38,
      );
    }

    if (value == 1 || value == 3 || value == 5) {
      drawDot(size.width / 2, size.height / 2);
    }
    if (value > 1) {
      drawDot(padding, padding);
      drawDot(size.width - padding, size.height - padding);
    }
    if (value > 3) {
      drawDot(size.width - padding, padding);
      drawDot(padding, size.height - padding);
    }
    if (value == 6) {
      drawDot(padding, size.height / 2);
      drawDot(size.width - padding, size.height / 2);
    }
  }

  @override
  bool shouldRepaint(covariant DiceDotsPainter oldDelegate) =>
      oldDelegate.value != value;
}
