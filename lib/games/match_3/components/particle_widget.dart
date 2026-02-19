import 'dart:math';
import 'package:flutter/material.dart';

class ParticleEffect extends StatefulWidget {
  final Offset position;
  final Color color;
  final VoidCallback onComplete;

  const ParticleEffect({
    super.key,
    required this.position,
    required this.color,
    required this.onComplete,
  });

  @override
  State<ParticleEffect> createState() => _ParticleEffectState();
}

class _ParticleEffectState extends State<ParticleEffect>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  final List<_Particle> _particles = [];
  final Random _random = Random();

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    for (int i = 0; i < 12; i++) {
      _particles.add(
        _Particle(
          angle: _random.nextDouble() * 2 * pi,
          speed: 2.0 + _random.nextDouble() * 4.0,
          size: 4.0 + _random.nextDouble() * 6.0,
        ),
      );
    }

    _controller.forward().then((_) => widget.onComplete());
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
        return Stack(
          children: _particles.map((p) {
            final double distance = p.speed * _controller.value * 50;
            final double x = widget.position.dx + cos(p.angle) * distance;
            final double y = widget.position.dy + sin(p.angle) * distance;
            final double opacity = 1.0 - _controller.value;
            final double size = p.size * (1.0 - _controller.value);

            return Positioned(
              left: x,
              top: y,
              child: Opacity(
                opacity: opacity,
                child: Container(
                  width: size,
                  height: size,
                  decoration: BoxDecoration(
                    color: widget.color,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: widget.color.withOpacity(0.5),
                        blurRadius: 4,
                      ),
                    ],
                  ),
                ),
              ),
            );
          }).toList(),
        );
      },
    );
  }
}

class _Particle {
  final double angle;
  final double speed;
  final double size;

  _Particle({required this.angle, required this.speed, required this.size});
}
