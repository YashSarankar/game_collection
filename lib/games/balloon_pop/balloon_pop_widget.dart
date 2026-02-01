import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import '../../core/models/game_model.dart';
import '../../core/constants/game_constants.dart';
import '../../core/services/haptic_service.dart';
import '../../core/services/sound_service.dart';
import '../../ui/widgets/game_countdown.dart';
import '../../ui/widgets/game_over_dialog.dart';

class BalloonPopWidget extends StatefulWidget {
  final GameModel game;

  const BalloonPopWidget({super.key, required this.game});

  @override
  State<BalloonPopWidget> createState() => _BalloonPopWidgetState();
}

class _Balloon {
  final String id;
  double x; // 0.0 to 1.0 (screen relative)
  double y; // 1.1 to -0.2 (screen relative)
  double speed;
  Color color;
  double radius;

  _Balloon({
    required this.id,
    required this.x,
    required this.y,
    required this.speed,
    required this.color,
    this.radius = 35,
  });
}

class _Particle {
  double x;
  double y;
  double vx;
  double vy;
  double life; // 1.0 to 0.0
  Color color;
  double size;

  _Particle({
    required this.x,
    required this.y,
    required this.vx,
    required this.vy,
    required this.color,
    this.life = 1.0,
    this.size = 4.0,
  });

  void update(double dt) {
    x += vx * dt;
    y += vy * dt;
    vy += 500 * dt; // Gravity
    life -= 2.0 * dt; // Fade out
  }
}

class _BalloonPopWidgetState extends State<BalloonPopWidget>
    with SingleTickerProviderStateMixin {
  late Ticker _ticker;
  final Random _random = Random();

  List<_Balloon> balloons = [];
  List<_Particle> particles = [];
  int score = 0;
  int lives = 3;
  bool isPlaying = false;
  bool isGameOver = false;
  bool _showCountdown = false;

  double spawnTimer = 0;
  double difficultyMultiplier = 1.0;
  Duration? _lastElapsed;

  HapticService? _hapticService;
  SoundService? _soundService;

  @override
  void initState() {
    super.initState();
    _initializeServices();
    _ticker = createTicker(_updateGameLoop);
  }

  Future<void> _initializeServices() async {
    _hapticService = await HapticService.getInstance();
    _soundService = await SoundService.getInstance();
  }

  @override
  void dispose() {
    _ticker.dispose();
    super.dispose();
  }

  void _startGame() {
    setState(() {
      balloons.clear();
      particles.clear();
      score = 0;
      lives = 3;
      isPlaying = true;
      isGameOver = false;
      difficultyMultiplier = 1.0;
      _showCountdown = true;
      spawnTimer = 0;
    });
  }

  void _updateGameLoop(Duration elapsed) {
    if (!isPlaying || isGameOver || _showCountdown) {
      _lastElapsed = null;
      return;
    }

    if (_lastElapsed == null) {
      _lastElapsed = elapsed;
      return;
    }

    // Actual delta time
    final double dt =
        (elapsed.inMicroseconds - _lastElapsed!.inMicroseconds) / 1000000.0;
    _lastElapsed = elapsed;

    // Clamp dt to avoid huge jumps if there's a frame spike
    final double smoothDt = dt.clamp(0.0, 0.05);

    // Smoothly update difficulty (target based on score)
    // Decreasing the influence of score jumps by lerping
    final double targetDifficulty = 1.0 + (score / 300.0);
    difficultyMultiplier += (targetDifficulty - difficultyMultiplier) * 0.05;

    // Spawn balloons using smoothDt
    spawnTimer += smoothDt;
    // Adjust spawn rate based on difficulty
    double spawnInterval = 1.2 / (1.0 + (difficultyMultiplier - 1.0) * 0.8);
    if (spawnTimer > spawnInterval) {
      _spawnBalloon();
      spawnTimer = 0;
    }

    setState(() {
      // Update balloons
      for (int i = balloons.length - 1; i >= 0; i--) {
        final balloon = balloons[i];

        // Move balloon up using actual difficulty and dt
        // Base speed * current smoothed difficulty * delta time
        balloon.y -= balloon.speed * smoothDt * difficultyMultiplier;

        // Check if missed (Off-screen)
        if (balloon.y < -0.2) {
          balloons.removeAt(i);
          _loseLife();
        }
      }

      // Update particles using smoothDt
      for (int i = particles.length - 1; i >= 0; i--) {
        particles[i].update(smoothDt);
        if (particles[i].life <= 0) {
          particles.removeAt(i);
        }
      }
    });

    if (lives <= 0) {
      _endGame();
    }
  }

  void _spawnBalloon() {
    if (balloons.length >= GameConstants.balloonPopMaxBalloons + (score ~/ 100))
      return;

    final color = GameColors
        .balloonColors[_random.nextInt(GameColors.balloonColors.length)];
    // Random x position (keep some padding from edges)
    final x = 0.1 + _random.nextDouble() * 0.8;
    // Random speed (0.15 to 0.45 range)
    final speed = 0.15 + _random.nextDouble() * 0.3;

    balloons.add(
      _Balloon(
        id: DateTime.now().microsecondsSinceEpoch.toString(),
        x: x,
        y: 1.1, // Start just below screen
        speed: speed,
        color: color,
        radius: 35 + _random.nextDouble() * 10, // Varying sizes
      ),
    );
  }

  void _handleTap(TapDownDetails details) {
    if (!isPlaying || isGameOver || _showCountdown) return;

    final RenderBox box = context.findRenderObject() as RenderBox;
    final localPosition = box.globalToLocal(details.globalPosition);
    final size = box.size;

    // Check from top to bottom (last spawned is on top)
    for (int i = balloons.length - 1; i >= 0; i--) {
      final balloon = balloons[i];

      // The balloon's visual body is an ellipse with:
      // Width = 2 * balloon.radius
      // Height = 2.4 * balloon.radius
      // Visual top-left of body is at (balloon.x * size.width - balloon.radius, balloon.y * size.height - balloon.radius)
      // Visual center of the elliptical body:
      final centerX = balloon.x * size.width;
      final centerY =
          (balloon.y * size.height - balloon.radius) + (balloon.radius * 1.2);

      final dx = localPosition.dx - centerX;
      final dy = localPosition.dy - centerY;

      // Use elliptical distance formula: (dx/rx)^2 + (dy/ry)^2 <= 1
      // Horizontal radius (rx) = balloon.radius
      // Vertical radius (ry) = balloon.radius * 1.2
      // We use a slightly generous threshold (1.1) to ensure edges are easy to hit
      final h = dx / balloon.radius;
      final v = dy / (balloon.radius * 1.2);

      if (h * h + v * v <= 1.2) {
        _popBalloon(i, centerX, centerY);
        break; // Pop only one balloon per tap
      }
    }
  }

  void _popBalloon(int index, double x, double y) {
    final balloon = balloons[index];
    _hapticService?.light();
    _soundService?.playPop();

    // Create particles for feedback
    for (int i = 0; i < 12; i++) {
      final angle = _random.nextDouble() * pi * 2;
      final speed = 50.0 + _random.nextDouble() * 150.0;
      particles.add(
        _Particle(
          x: x,
          y: y,
          vx: cos(angle) * speed,
          vy: sin(angle) * speed,
          color: balloon.color,
          size: 3.0 + _random.nextDouble() * 4.0,
          life: 0.8 + _random.nextDouble() * 0.4,
        ),
      );
    }

    setState(() {
      balloons.removeAt(index);
      score += 10;
    });
  }

  void _loseLife() {
    setState(() {
      lives--;
    });
    _hapticService?.error();
  }

  void _endGame() {
    if (isGameOver) return;

    _ticker.stop();
    setState(() {
      isPlaying = false;
      isGameOver = true;
    });

    Future.delayed(const Duration(milliseconds: 500), () {
      if (!mounted) return;
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => GameOverDialog(
          gameId: widget.game.id,
          score: score,
          onRestart: () {
            Navigator.pop(context);
            _startGame();
          },
          onHome: () {
            Navigator.pop(context);
            Navigator.pop(context);
          },
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0D1B2A) : Colors.lightBlue[100],
      body: GestureDetector(
        onTapDown: _handleTap,
        behavior: HitTestBehavior.opaque,
        child: Stack(
          children: [
            // Clouds Background
            ..._buildClouds(isDark),

            // Particles
            CustomPaint(
              painter: _ParticlePainter(particles: particles),
              size: Size.infinite,
            ),

            // Balloons
            ...balloons.map((balloon) {
              return Positioned(
                left:
                    MediaQuery.of(context).size.width * balloon.x -
                    balloon.radius,
                top:
                    MediaQuery.of(context).size.height * balloon.y -
                    balloon.radius,
                child: _BalloonWidget(balloon: balloon, isDark: isDark),
              );
            }).toList(),

            // Header
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: SafeArea(bottom: false, child: _buildHeader(isDark)),
            ),

            // Start Screen Overlay
            if (!isPlaying && !isGameOver)
              Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        widget.game.icon,
                        size: 80,
                        color: Colors.blueAccent,
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'Balloon Pop',
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : Colors.blueGrey[900],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Pop them before they fly away!',
                      style: TextStyle(
                        fontSize: 16,
                        color: isDark ? Colors.white70 : Colors.blueGrey[600],
                      ),
                    ),
                    const SizedBox(height: 40),
                    ElevatedButton(
                      onPressed: _startGame,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blueAccent,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 48,
                          vertical: 16,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                      ),
                      child: const Text(
                        'Start Game',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

            // Global Countdown Overlay
            if (_showCountdown)
              Container(
                color: Colors.black26,
                child: GameCountdown(
                  onFinished: () {
                    if (mounted) {
                      _ticker.start();
                      Future.delayed(const Duration(milliseconds: 800), () {
                        if (mounted) setState(() => _showCountdown = false);
                      });
                    }
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildClouds(bool isDark) {
    return [
      Positioned(
        top: 100,
        left: 30,
        child: Icon(
          Icons.cloud,
          size: 60,
          color: Colors.white.withOpacity(isDark ? 0.05 : 0.6),
        ),
      ),
      Positioned(
        top: 250,
        right: 40,
        child: Icon(
          Icons.cloud,
          size: 80,
          color: Colors.white.withOpacity(isDark ? 0.05 : 0.5),
        ),
      ),
      Positioned(
        top: 450,
        left: -20,
        child: Icon(
          Icons.cloud,
          size: 100,
          color: Colors.white.withOpacity(isDark ? 0.03 : 0.4),
        ),
      ),
    ];
  }

  Widget _buildHeader(bool isDark) {
    final textColor = isDark ? Colors.white : Colors.black87;
    final headerBg = isDark ? Colors.black12 : Colors.white24;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: headerBg,
        border: Border(
          bottom: BorderSide(
            color: isDark ? Colors.white10 : Colors.black.withOpacity(0.05),
          ),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: Icon(Icons.close_rounded, color: textColor),
          ),
          Row(
            children: [
              const Icon(
                Icons.favorite_rounded,
                color: Colors.redAccent,
                size: 24,
              ),
              const SizedBox(width: 8),
              Text(
                '$lives',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: textColor,
                ),
              ),
            ],
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.blueAccent.withOpacity(0.2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              'Score: $score',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.blue[200] : Colors.blue[900],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _BalloonWidget extends StatelessWidget {
  final _Balloon balloon;
  final bool isDark;

  const _BalloonWidget({required this.balloon, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: balloon.radius * 2,
      height: balloon.radius * 2.8,
      child: Stack(
        alignment: Alignment.topCenter,
        children: [
          // Balloon Body
          Container(
            width: balloon.radius * 2,
            height: balloon.radius * 2.4,
            decoration: BoxDecoration(
              color: balloon.color,
              borderRadius: BorderRadius.all(
                Radius.elliptical(balloon.radius, balloon.radius * 1.2),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  offset: const Offset(2, 4),
                  blurRadius: 4,
                ),
              ],
              gradient: RadialGradient(
                colors: [
                  Colors.white.withOpacity(0.3),
                  balloon.color,
                  balloon.color.withOpacity(0.8),
                ],
                center: const Alignment(-0.3, -0.4),
                radius: 0.8,
              ),
            ),
          ),
          // Reflection
          Positioned(
            top: balloon.radius * 0.3,
            left: balloon.radius * 0.4,
            child: Container(
              width: balloon.radius * 0.3,
              height: balloon.radius * 0.6,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.4),
                borderRadius: BorderRadius.circular(20),
              ),
            ),
          ),
          // String
          Positioned(
            bottom: 0,
            child: Container(
              width: 2,
              height: balloon.radius * 1.0,
              color: isDark ? Colors.white24 : Colors.black26,
            ),
          ),
          // Knot
          Positioned(
            bottom: balloon.radius * 0.35,
            child: Container(
              width: 8,
              height: 4,
              decoration: BoxDecoration(
                color: balloon.color.withOpacity(0.9),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ParticlePainter extends CustomPainter {
  final List<_Particle> particles;

  _ParticlePainter({required this.particles});

  @override
  void paint(Canvas canvas, Size size) {
    for (final particle in particles) {
      final paint = Paint()
        ..color = particle.color.withOpacity(particle.life.clamp(0.0, 1.0))
        ..style = PaintingStyle.fill;

      canvas.drawCircle(Offset(particle.x, particle.y), particle.size, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _ParticlePainter oldDelegate) => true;
}
