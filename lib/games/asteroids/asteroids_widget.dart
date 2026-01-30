import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:provider/provider.dart';
import '../../core/models/game_model.dart';
import '../../ui/widgets/game_countdown.dart';
import '../../ui/widgets/game_over_dialog.dart';
import 'asteroids_logic.dart';

class AsteroidsWidget extends StatefulWidget {
  final GameModel game;
  const AsteroidsWidget({super.key, required this.game});

  @override
  State<AsteroidsWidget> createState() => _AsteroidsWidgetState();
}

class _AsteroidsWidgetState extends State<AsteroidsWidget>
    with SingleTickerProviderStateMixin {
  late AsteroidsLogic _logic;
  late Ticker _ticker;
  double _lastFrameTime = 0;

  // Joystick states
  Offset _joystickDelta = Offset.zero;
  bool _isCountingDown = true;

  final math.Random _random = math.Random();
  late List<_Star> _stars;

  @override
  void initState() {
    super.initState();
    _logic = AsteroidsLogic();
    _generateStars();

    _ticker = createTicker((elapsed) {
      if (_isCountingDown || !mounted) return;

      final double currentTime = elapsed.inMicroseconds / 1000000.0;
      if (_lastFrameTime == 0) {
        _lastFrameTime = currentTime;
        return;
      }
      final double dt = (currentTime - _lastFrameTime).clamp(0, 0.05);
      _lastFrameTime = currentTime;

      if (!_logic.isGameOver && !_logic.isPaused) {
        _logic.update(dt, moveVector: _joystickDelta, currentTime: currentTime);

        if (_logic.isGameOver) {
          _ticker.stop();
          _showGameOver();
        }
      }
      setState(() {});
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final size = MediaQuery.of(context).size;
      _logic.init(size);
    });
  }

  void _generateStars() {
    _stars = List.generate(
      100,
      (i) => _Star(
        Offset(_random.nextDouble(), _random.nextDouble()),
        _random.nextDouble() * 0.5 + 0.1,
        _random.nextDouble() * 1.5 + 0.5,
      ),
    );
  }

  void _onCountdownFinished() {
    setState(() {
      _isCountingDown = false;
      _ticker.start();
    });
  }

  void _showGameOver() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => GameOverDialog(
        gameId: widget.game.id,
        score: _logic.score,
        onRestart: () {
          Navigator.pop(context);
          _logic.restart();
          setState(() {
            _isCountingDown = true;
            _lastFrameTime = 0;
            _joystickDelta = Offset.zero;
          });
        },
        onHome: () {
          Navigator.pop(context);
          Navigator.pop(context);
        },
      ),
    );
  }

  @override
  void dispose() {
    _ticker.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: _logic,
      child: Scaffold(
        backgroundColor: Colors.black,
        body: Stack(
          children: [
            // Background Stars
            CustomPaint(
              painter: _StarfieldPainter(
                stars: _stars,
                bgOffset: _logic.bgOffset,
                thrustDir: _logic.ship?.velocity ?? Offset.zero,
              ),
              size: Size.infinite,
            ),

            // Game Area
            _buildScreenShakeWrapper(
              child: CustomPaint(
                painter: AsteroidsPainter(logic: _logic),
                size: Size.infinite,
              ),
            ),

            // Top HUD
            _buildPremiumHeader(),

            // Smaller joystick in bottom-right corner
            _buildJoystickControl(),

            // Pause Overlay
            _buildPauseOverlay(),

            // Initial Countdown
            if (_isCountingDown) _buildCountdownOverlay(),
          ],
        ),
      ),
    );
  }

  Widget _buildScreenShakeWrapper({required Widget child}) {
    return Transform.translate(
      offset: Offset(
        (_random.nextDouble() - 0.5) * _logic.screenShake,
        (_random.nextDouble() - 0.5) * _logic.screenShake,
      ),
      child: child,
    );
  }

  Widget _buildPremiumHeader() {
    return Positioned(
      top: 40,
      left: 20,
      right: 20,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.05),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: Colors.white.withOpacity(0.1),
                width: 1,
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'SCORE',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.5),
                        fontSize: 10,
                        letterSpacing: 2,
                      ),
                    ),
                    Text(
                      '${_logic.score}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'monospace',
                      ),
                    ),
                  ],
                ),
                Row(
                  children: List.generate(
                    3,
                    (index) => Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4.0),
                      child: Icon(
                        Icons.rocket_launch,
                        color: index < _logic.lives
                            ? Colors.cyanAccent
                            : Colors.white.withOpacity(0.1),
                        size: 20,
                      ),
                    ),
                  ),
                ),
                GestureDetector(
                  onTap: () => _logic.togglePause(),
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      _logic.isPaused
                          ? Icons.play_arrow_rounded
                          : Icons.pause_rounded,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildJoystickControl() {
    if (_isCountingDown) return const SizedBox.shrink();

    return Positioned(
      bottom: 20,
      right: 20,
      child: _Joystick(
        onChanged: (delta) {
          setState(() {
            _joystickDelta = delta;
          });
        },
      ),
    );
  }

  Widget _buildPauseOverlay() {
    if (!_logic.isPaused || _logic.isGameOver) return const SizedBox.shrink();

    return BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
      child: Container(
        color: Colors.black.withOpacity(0.4),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'PAUSED',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 48,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 4,
                  shadows: [
                    Shadow(
                      color: Colors.cyanAccent.withOpacity(0.5),
                      blurRadius: 20,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 40),
              GestureDetector(
                onTap: () => _logic.togglePause(),
                child: Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: [Colors.cyanAccent, Colors.blueAccent],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.cyanAccent.withOpacity(0.5),
                        blurRadius: 30,
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.play_arrow_rounded,
                    color: Colors.white,
                    size: 60,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCountdownOverlay() {
    return Container(
      color: Colors.black.withOpacity(0.8),
      child: GameCountdown(onFinished: _onCountdownFinished),
    );
  }
}

class _Joystick extends StatefulWidget {
  final Function(Offset) onChanged;
  const _Joystick({required this.onChanged});

  @override
  State<_Joystick> createState() => _JoystickState();
}

class _JoystickState extends State<_Joystick> {
  Offset _dragPosition = Offset.zero;
  final double _radius = 45.0;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onPanUpdate: (details) {
        setState(() {
          _dragPosition += details.delta;
          if (_dragPosition.distance > _radius) {
            _dragPosition = (_dragPosition / _dragPosition.distance) * _radius;
          }
        });
        widget.onChanged(_dragPosition / _radius);
      },
      onPanEnd: (_) {
        setState(() {
          _dragPosition = Offset.zero;
        });
        widget.onChanged(Offset.zero);
      },
      child: Container(
        width: _radius * 2.5,
        height: _radius * 2.5,
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.05),
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white.withOpacity(0.1), width: 2),
        ),
        child: Stack(
          children: [
            Center(
              child: Transform.translate(
                offset: _dragPosition,
                child: Container(
                  width: 45,
                  height: 45,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: const RadialGradient(
                      colors: [Colors.cyanAccent, Colors.blueAccent],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.cyanAccent.withOpacity(0.4),
                        blurRadius: 10,
                        spreadRadius: 1,
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.navigation_rounded,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Star {
  Offset position;
  double speed;
  double size;
  _Star(this.position, this.speed, this.size);
}

class _StarfieldPainter extends CustomPainter {
  final List<_Star> stars;
  final double bgOffset;
  final Offset thrustDir;

  _StarfieldPainter({
    required this.stars,
    required this.bgOffset,
    required this.thrustDir,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.white;
    for (var star in stars) {
      double x = star.position.dx * size.width;
      double y =
          (star.position.dy * size.height + bgOffset * star.speed * 2) %
          size.height;

      paint.color = Colors.white.withOpacity(star.speed + 0.1);
      canvas.drawCircle(Offset(x, y), star.size, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class AsteroidsPainter extends CustomPainter {
  final AsteroidsLogic logic;
  AsteroidsPainter({required this.logic});

  @override
  void paint(Canvas canvas, Size size) {
    // Draw Bullets with Glow
    for (var bullet in logic.bullets) {
      final bulletPaint = Paint()
        ..color = Colors.yellowAccent
        ..style = PaintingStyle.fill;

      canvas.drawCircle(bullet.position, 2, bulletPaint);

      canvas.drawCircle(
        bullet.position,
        4,
        Paint()
          ..color = Colors.yellowAccent.withOpacity(0.3)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2),
      );
    }

    // Draw Asteroids with Gradients
    for (var asteroid in logic.asteroids) {
      canvas.save();
      canvas.translate(asteroid.position.dx, asteroid.position.dy);
      canvas.rotate(asteroid.rotation);

      final astroColor = _getAsteroidColor(asteroid.size);
      final paint = Paint()
        ..shader =
            RadialGradient(
              colors: [astroColor.withOpacity(0.7), astroColor],
              center: const Alignment(-0.3, -0.3),
            ).createShader(
              Rect.fromCircle(center: Offset.zero, radius: asteroid.radius),
            )
        ..style = PaintingStyle.fill;

      final path = Path();
      if (asteroid.points.isNotEmpty) {
        path.moveTo(asteroid.points[0].dx, asteroid.points[0].dy);
        for (int i = 1; i < asteroid.points.length; i++) {
          path.lineTo(asteroid.points[i].dx, asteroid.points[i].dy);
        }
        path.close();
      }

      canvas.drawPath(path, paint);

      canvas.drawPath(
        path,
        Paint()
          ..color = astroColor.withOpacity(0.5)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2,
      );

      canvas.restore();
    }

    // Draw Particles
    for (var particle in logic.particles) {
      final pPaint = Paint()
        ..color = particle.color.withOpacity(particle.life.clamp(0.0, 1.0))
        ..style = PaintingStyle.fill;
      canvas.drawCircle(particle.position, 1.5, pPaint);
    }

    // Draw Ship (3D-like Metallic Fighter)
    if (logic.ship != null) {
      canvas.save();
      canvas.translate(logic.ship!.position.dx, logic.ship!.position.dy);
      canvas.rotate(logic.ship!.rotation);

      final bool invul = logic.isInvulnerable;
      final Color baseColor = invul ? Colors.blueGrey : Colors.cyanAccent;

      final shadowPath = Path()
        ..moveTo(25, 0)
        ..lineTo(-15, -18)
        ..lineTo(-15, 18)
        ..close();
      canvas.drawPath(
        shadowPath,
        Paint()
          ..color = Colors.black.withOpacity(0.5)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10),
      );

      final bodyPath = Path()
        ..moveTo(25, 0)
        ..lineTo(5, -8)
        ..lineTo(-15, -18)
        ..lineTo(-10, -5)
        ..lineTo(-15, 0)
        ..lineTo(-10, 5)
        ..lineTo(-15, 18)
        ..lineTo(5, 8)
        ..close();

      final metallicPaint = Paint()
        ..shader = LinearGradient(
          colors: [
            Colors.white,
            baseColor,
            baseColor.withOpacity(0.7),
            baseColor,
          ],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ).createShader(Rect.fromLTWH(-15, -18, 40, 36));

      canvas.drawPath(bodyPath, metallicPaint);

      final cockpitPath = Path()
        ..moveTo(10, 0)
        ..lineTo(0, -4)
        ..lineTo(-5, 0)
        ..lineTo(0, 4)
        ..close();

      canvas.drawPath(
        cockpitPath,
        Paint()
          ..shader = const LinearGradient(
            colors: [Colors.cyan, Colors.blue, Colors.black],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ).createShader(Rect.fromLTWH(-5, -4, 15, 8)),
      );

      canvas.drawCircle(
        const Offset(5, -1),
        2,
        Paint()..color = Colors.white.withOpacity(0.6),
      );

      final enginePaint = Paint()
        ..color = Colors.orangeAccent
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5);
      canvas.drawRect(const Rect.fromLTWH(-12, -4, 4, 8), enginePaint);

      if (logic.ship!.isThrusting) {
        final flamePower = logic.thrustPower;
        final flamePath = Path()
          ..moveTo(-12, -6)
          ..lineTo(
            -12 - 35 * (0.8 + math.Random().nextDouble() * 0.4) * flamePower,
            0,
          )
          ..lineTo(-12, 6);

        final flamePaint = Paint()
          ..shader =
              const RadialGradient(
                colors: [
                  Colors.white,
                  Colors.orange,
                  Colors.red,
                  Colors.transparent,
                ],
                stops: [0.0, 0.3, 0.6, 1.0],
              ).createShader(
                Rect.fromCircle(center: const Offset(-20, 0), radius: 20),
              )
          ..style = PaintingStyle.fill
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);

        canvas.drawPath(flamePath, flamePaint);

        if (math.Random().nextDouble() > 0.5) {
          canvas.drawCircle(
            const Offset(-15, 0),
            10 * flamePower,
            Paint()
              ..color = Colors.white.withOpacity(0.3)
              ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8),
          );
        }
      }

      canvas.restore();
    }
  }

  Color _getAsteroidColor(AsteroidSize size) {
    switch (size) {
      case AsteroidSize.large:
        return Colors.deepPurpleAccent;
      case AsteroidSize.medium:
        return Colors.blueGrey;
      case AsteroidSize.small:
        return Colors.blueAccent;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
