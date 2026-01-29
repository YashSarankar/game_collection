import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import '../../core/models/game_model.dart';
import '../../core/constants/game_constants.dart';
import '../../core/services/haptic_service.dart';
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
  double y; // 1.0 to -0.2 (screen relative, starts at bottom)
  double speed;
  Color color;

  _Balloon({
    required this.id,
    required this.x,
    required this.y,
    required this.speed,
    required this.color,
  });
}

class _BalloonPopWidgetState extends State<BalloonPopWidget>
    with SingleTickerProviderStateMixin {
  late Ticker _ticker;
  final Random _random = Random();

  List<_Balloon> balloons = [];
  int score = 0;
  int lives = 3;
  bool isPlaying = false;
  bool isGameOver = false;
  bool _showCountdown = false;

  double spawnTimer = 0;
  double difficultyMultiplier = 1.0;

  HapticService? _hapticService;

  @override
  void initState() {
    super.initState();
    _initializeServices();
    _ticker = createTicker(_updateGameLoop);
    _startGame();
  }

  Future<void> _initializeServices() async {
    _hapticService = await HapticService.getInstance();
  }

  @override
  void dispose() {
    _ticker.dispose();
    super.dispose();
  }

  void _startGame() {
    setState(() {
      balloons.clear();
      score = 0;
      lives = 3;
      isPlaying = true;
      isGameOver = false;
      difficultyMultiplier = 1.0;
      _showCountdown = true;
    });
  }

  void _updateGameLoop(Duration elapsed) {
    if (!isPlaying || isGameOver || _showCountdown) return;

    // Delta time calculation could be more precise, but for 60fps Ticker it's approx 16ms
    const double dt = 0.016;

    // Spawn balloons
    spawnTimer += dt;
    // Spawn rate increases with difficulty (decrease interval)
    double spawnInterval = 1.5 / difficultyMultiplier;
    if (spawnTimer > spawnInterval) {
      _spawnBalloon();
      spawnTimer = 0;
    }

    // Increase difficulty slowly
    difficultyMultiplier += 0.0005;

    setState(() {
      // Update balloons
      for (int i = balloons.length - 1; i >= 0; i--) {
        final balloon = balloons[i];

        // Move balloon up
        balloon.y -= balloon.speed * dt * difficultyMultiplier;

        // Check if missed
        if (balloon.y < -0.2) {
          balloons.removeAt(i);
          _loseLife();
        }
      }
    });

    if (lives <= 0) {
      _endGame();
    }
  }

  void _spawnBalloon() {
    if (balloons.length >= GameConstants.balloonPopMaxBalloons) return;

    final color = GameColors
        .balloonColors[_random.nextInt(GameColors.balloonColors.length)];
    // Random x position (keep some padding from edges)
    final x = 0.1 + _random.nextDouble() * 0.8;
    // Random speed
    final speed = 0.2 + _random.nextDouble() * 0.3;

    balloons.add(
      _Balloon(
        id: DateTime.now().microsecondsSinceEpoch.toString(),
        x: x,
        y: 1.1, // Start just below screen
        speed: speed,
        color: color,
      ),
    );
  }

  void _popBalloon(int index) {
    if (isGameOver || _showCountdown) return;

    _hapticService?.light();

    setState(() {
      balloons.removeAt(index);
      score += 10;
    });
  }

  void _loseLife() {
    lives--;
    _hapticService?.error();
  }

  void _endGame() {
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
          showRewardedAdOption: true,
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0D1B2A) : Colors.lightBlue[100],
      body: Stack(
        children: [
          // Clouds Background
          Positioned(
            top: 50,
            left: 30,
            child: Icon(
              Icons.cloud,
              size: 60,
              color: Colors.white.withOpacity(isDark ? 0.1 : 0.6),
            ),
          ),
          Positioned(
            top: 150,
            right: 40,
            child: Icon(
              Icons.cloud,
              size: 80,
              color: Colors.white.withOpacity(isDark ? 0.1 : 0.5),
            ),
          ),
          // ... more clouds ...

          // Balloons
          if (isPlaying && !isGameOver)
            ...balloons.asMap().entries.map((entry) {
              final index = entry.key;
              final balloon = entry.value;
              return Positioned(
                left: MediaQuery.of(context).size.width * balloon.x - 25,
                top: MediaQuery.of(context).size.height * balloon.y,
                child: GestureDetector(
                  onTap: () => _popBalloon(index),
                  child: Container(
                    width: 50,
                    height: 70,
                    decoration: BoxDecoration(
                      color: balloon.color,
                      borderRadius: const BorderRadius.all(
                        Radius.elliptical(50, 70),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.2),
                          offset: const Offset(2, 4),
                          blurRadius: 4,
                        ),
                      ],
                    ),
                    child: Stack(
                      children: [
                        Positioned(
                          top: 10,
                          left: 10,
                          child: Container(
                            width: 10,
                            height: 20,
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.5),
                              borderRadius: const BorderRadius.all(
                                Radius.elliptical(10, 20),
                              ),
                            ),
                          ),
                        ),
                        Positioned(
                          bottom: -20,
                          left: 24,
                          child: Container(
                            width: 2,
                            height: 20,
                            color: isDark ? Colors.white24 : Colors.black26,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
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
                  Icon(widget.game.icon, size: 80, color: Colors.blueAccent),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: _startGame,
                    child: const Text('Start Game'),
                  ),
                ],
              ),
            ),

          // Global Countdown Overlay
          if (_showCountdown)
            Container(
              color: Colors.black12,
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
    );
  }

  Widget _buildHeader(bool isDark) {
    final iconColor = isDark ? Colors.white70 : Colors.black54;
    final textColor = isDark ? Colors.white : Colors.black87;
    final scoreBgColor = isDark ? Colors.white.withOpacity(0.1) : Colors.white;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      child: Stack(
        alignment: Alignment.center,
        children: [
          if (!isPlaying && !isGameOver)
            Align(
              alignment: Alignment.centerLeft,
              child: IconButton(
                onPressed: () {
                  _ticker.stop();
                  Navigator.pop(context);
                },
                icon: Icon(
                  Icons.arrow_back_ios_new_rounded,
                  color: iconColor,
                  size: 22,
                ),
              ),
            ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.favorite_rounded,
                color: Colors.redAccent,
                size: 20,
              ),
              const SizedBox(width: 6),
              Text(
                '$lives',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: textColor,
                ),
              ),
            ],
          ),
          Align(
            alignment: Alignment.centerRight,
            child: Padding(
              padding: const EdgeInsets.only(right: 12),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: scoreBgColor,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isDark
                        ? Colors.white10
                        : Colors.black.withOpacity(0.05),
                  ),
                ),
                child: Text(
                  'Score: $score',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: textColor,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
