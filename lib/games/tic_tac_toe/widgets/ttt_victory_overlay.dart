import 'dart:math';
import 'package:flutter/material.dart';

class TTTVictoryOverlay extends StatefulWidget {
  final Color color;
  final String winner;

  const TTTVictoryOverlay({
    super.key,
    required this.color,
    required this.winner,
  });

  @override
  State<TTTVictoryOverlay> createState() => _TTTVictoryOverlayState();
}

class _TTTVictoryOverlayState extends State<TTTVictoryOverlay>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  final List<Particle> particles = [];
  final Random random = Random();

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();

    for (int i = 0; i < 50; i++) {
      particles.add(Particle(random: random, color: widget.color));
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        for (var p in particles) {
          p.update();
        }
        return CustomPaint(
          painter: ParticlePainter(particles: particles),
          child: Container(),
        );
      },
    );
  }
}

class Particle {
  late double x, y;
  late double vx, vy;
  late double size;
  late Color color;
  late double opacity;

  Particle({required Random random, required this.color}) {
    x = random.nextDouble() * 400;
    y = random.nextDouble() * 800;
    vx = (random.nextDouble() - 0.5) * 5;
    vy = (random.nextDouble() - 0.5) * 5;
    size = random.nextDouble() * 5 + 2;
    opacity = random.nextDouble();
  }

  void update() {
    x += vx;
    y += vy;
    if (x < 0 || x > 400) vx *= -1;
    if (y < 0 || y > 800) vy *= -1;
  }
}

class ParticlePainter extends CustomPainter {
  final List<Particle> particles;

  ParticlePainter({required this.particles});

  @override
  void paint(Canvas canvas, Size size) {
    for (var p in particles) {
      final paint = Paint()..color = p.color.withOpacity(p.opacity);
      canvas.drawCircle(Offset(p.x, p.y), p.size, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
