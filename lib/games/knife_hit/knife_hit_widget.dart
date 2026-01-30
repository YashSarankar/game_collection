import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../core/models/game_model.dart';
import '../../core/services/haptic_service.dart';
import '../../core/services/sound_service.dart';

class KnifeHitWidget extends StatefulWidget {
  final GameModel game;

  const KnifeHitWidget({super.key, required this.game});

  @override
  State<KnifeHitWidget> createState() => _KnifeHitWidgetState();
}

class _KnifeHitWidgetState extends State<KnifeHitWidget>
    with TickerProviderStateMixin {
  // Game States
  bool _isPlaying = false;
  bool _isGameOver = false;
  bool _isLevelComplete = false;
  bool _isInitialized = false;

  // Level Stats
  int _currentLevel = 1;
  int _knivesLeft = 7;
  int _totalKnivesForLevel = 7;
  int _score = 0;

  // Animation Controllers
  late AnimationController _shakeController;
  late AnimationController _rotationController;
  late AnimationController _knifeThrowController;

  // Game Objects
  final List<double> _knivesOnLog = []; // Angles of knives stuck on log
  final List<_WoodChip> _chips = []; // Particle effect
  bool _isKnifeFlying = false;

  // Rotation properties
  double _rotationSpeed = 2.0; // Radians per second
  int _rotationDirection = 1; // 1 for clockwise, -1 for counter-clockwise
  double _currentRotationAngle = 0.0;
  DateTime? _lastFrameTime;

  late HapticService _hapticService;
  late SoundService _soundService;

  @override
  void initState() {
    super.initState();
    _initializeServices();

    _shakeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
    );

    _rotationController = AnimationController(
      vsync: this,
      duration: const Duration(
        seconds: 3600,
      ), // Very long duration for continuous loop
    )..addListener(_updateRotation);

    _knifeThrowController =
        AnimationController(
          vsync: this,
          duration: const Duration(milliseconds: 120),
        )..addStatusListener((status) {
          if (status == AnimationStatus.completed) {
            _onKnifeHit();
          }
        });
  }

  Future<void> _initializeServices() async {
    _hapticService = await HapticService.getInstance();
    _soundService = await SoundService.getInstance();
    if (mounted) {
      setState(() {
        _isInitialized = true;
      });
    }
  }

  @override
  void dispose() {
    _rotationController.removeListener(_updateRotation);
    _rotationController.dispose();
    _knifeThrowController.dispose();
    _shakeController.dispose();
    super.dispose();
  }

  void _updateRotation() {
    if (!_isPlaying || _isGameOver || _isLevelComplete) return;

    final now = DateTime.now();
    if (_lastFrameTime == null) {
      _lastFrameTime = now;
      return;
    }

    final double deltaTime =
        now.difference(_lastFrameTime!).inMicroseconds / 1000000.0;
    _lastFrameTime = now;

    setState(() {
      _currentRotationAngle +=
          (_rotationSpeed * _rotationDirection) * deltaTime;

      // Dynamic difficulty: random direction changes at higher levels
      if (_currentLevel > 2 && math.Random().nextDouble() < 0.005) {
        _rotationDirection *= -1;
      }

      // Dynamic difficulty: variable speeds
      if (_currentLevel > 4) {
        double oscillation = math.sin(now.millisecondsSinceEpoch / 500.0);
        _rotationSpeed = (2.0 + oscillation + (_currentLevel * 0.2)).clamp(
          1.5,
          7.0,
        );
      }

      // Update chips particles
      for (int i = _chips.length - 1; i >= 0; i--) {
        _chips[i].update(deltaTime);
        if (_chips[i].life <= 0) _chips.removeAt(i);
      }
    });
  }

  void _startGame() {
    _resetLevel(1);
    setState(() {
      _isPlaying = true;
      _isGameOver = false;
      _score = 0;
      _chips.clear();
      _lastFrameTime = DateTime.now();
    });
    _rotationController.repeat();
    _soundService.playGameStart();
  }

  void _resetLevel(int level) {
    setState(() {
      _currentLevel = level;
      _totalKnivesForLevel = 5 + (level * 1);
      _knivesLeft = _totalKnivesForLevel;
      _knivesOnLog.clear();
      _isLevelComplete = false;
      _isGameOver = false;
      _isKnifeFlying = false;
      _rotationSpeed = 1.5 + (level * 0.3);
      _rotationDirection = 1;

      // Pre-populate some knives at higher levels
      if (level > 3) {
        int startingKnives = math.min((level / 2).floor(), 4);
        for (int i = 0; i < startingKnives; i++) {
          _knivesOnLog.add(math.Random().nextDouble() * 2 * math.pi);
        }
      }
    });
    _rotationController.repeat();
  }

  void _throwKnife() {
    // Robustness: Only allow throw if not already flying and game is active
    if (!_isPlaying || _isKnifeFlying || _isGameOver || _isLevelComplete)
      return;

    setState(() {
      _isKnifeFlying = true;
    });
    _knifeThrowController.forward(from: 0.0);
  }

  void _onKnifeHit() {
    if (!mounted) return;

    setState(() {
      _isKnifeFlying = false;

      // Normalized hit angle calculation (Correcting for rotation to stay at the bottom)
      double hitAngle = -_currentRotationAngle;
      hitAngle = hitAngle % (2 * math.pi);
      if (hitAngle < 0) hitAngle += 2 * math.pi;

      bool collision = false;
      const double knifeThreshold = 0.22; // Arc-based collision distance

      for (double knifeAngle in _knivesOnLog) {
        double diff = (hitAngle - knifeAngle).abs();
        if (diff > math.pi) diff = 2 * math.pi - diff;
        if (diff < knifeThreshold) {
          collision = true;
          break;
        }
      }

      if (collision) {
        _endGame();
      } else {
        _knivesOnLog.add(hitAngle);
        _knivesLeft--;
        _score += 10;
        _hapticService.heavy();
        _soundService.playPoint();
        _shakeController
            .forward(from: 0)
            .then((_) => _shakeController.reverse());

        // Spawn particles
        for (int i = 0; i < 8; i++) {
          _chips.add(_WoodChip());
        }

        if (_knivesLeft <= 0) {
          _completeLevel();
        }
      }
    });
  }

  void _completeLevel() {
    setState(() {
      _isLevelComplete = true;
    });
    _hapticService.success();
    _soundService.playSuccess();

    Future.delayed(const Duration(milliseconds: 800), () {
      if (mounted && _isPlaying && _isLevelComplete) {
        _resetLevel(_currentLevel + 1);
      }
    });
  }

  void _endGame() {
    setState(() {
      _isPlaying = false;
      _isGameOver = true;
    });
    _rotationController.stop();
    _hapticService.error();
    _soundService.playGameOver();
  }

  @override
  Widget build(BuildContext context) {
    if (!_isInitialized) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final brightness = Theme.of(context).brightness;
    final isDark = brightness == Brightness.dark;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: isDark
                ? [
                    const Color(0xFF0F0C29),
                    const Color(0xFF302B63),
                    const Color(0xFF24243E),
                  ]
                : [const Color(0xFFECE9E6), const Color(0xFFFFFFFF)],
          ),
        ),
        child: AnimatedBuilder(
          animation: _shakeController,
          builder: (context, child) {
            final double shake =
                math.sin(_shakeController.value * math.pi * 10) * 8;
            return Transform.translate(offset: Offset(0, shake), child: child);
          },
          child: Stack(
            children: [
              _buildGameArea(isDark),
              _buildUI(isDark),
              _buildTopBar(isDark),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTopBar(bool isDark) {
    return Positioned(
      top: 10,
      left: 0,
      right: 0,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Hide back button during active level to avoid accidents
              if (!_isPlaying && !_isGameOver && !_isLevelComplete)
                IconButton(
                  icon: Icon(
                    Icons.close,
                    color: isDark ? Colors.white54 : Colors.black54,
                  ),
                  onPressed: () => Navigator.of(context).pop(),
                )
              else
                const SizedBox(width: 48),

              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: (isDark ? Colors.white : Colors.black).withOpacity(
                    0.05,
                  ),
                  borderRadius: BorderRadius.circular(25),
                  border: Border.all(
                    color: (isDark ? Colors.white10 : Colors.black),
                  ),
                ),
                child: Text(
                  "LEVEL $_currentLevel",
                  style: TextStyle(
                    color: isDark ? Colors.white : Colors.black,
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 2,
                  ),
                ),
              ),

              IconButton(
                icon: Icon(
                  Icons.refresh,
                  color: isDark ? Colors.white24 : Colors.black26,
                ),
                onPressed: () {
                  _rotationController.stop();
                  _resetLevel(1);
                  setState(() {
                    _isPlaying = false;
                    _isGameOver = false;
                    _score = 0;
                    _chips.clear();
                  });
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildUI(bool isDark) {
    return Stack(
      children: [
        if (!_isPlaying &&
            !_isGameOver &&
            !_isLevelComplete &&
            _knivesOnLog.isEmpty)
          _buildMenu(isDark),

        if (_isGameOver) _buildGameOverOverlay(isDark),

        // Score display with 3D shadow
        Positioned(
          top: 120,
          left: 0,
          right: 0,
          child: Center(
            child: Text(
              "$_score",
              style: TextStyle(
                color: isDark ? Colors.white : Colors.black87,
                fontSize: 80,
                fontWeight: FontWeight.w900,
                shadows: [
                  Shadow(
                    color: (isDark ? Colors.black : Colors.blue).withOpacity(
                      0.3,
                    ),
                    blurRadius: 15,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
            ),
          ),
        ),

        // Knives indicator (Vertical rack)
        Positioned(
          bottom: 120,
          left: 30,
          child: Column(
            children: List.generate(_totalKnivesForLevel, (index) {
              bool isUsed = index >= _knivesLeft;
              return Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Transform.rotate(
                  angle: -math.pi / 4,
                  child: Icon(
                    Icons.colorize_rounded,
                    color: isUsed
                        ? (isDark ? Colors.white12 : Colors.black12)
                        : (isDark ? Colors.white70 : Colors.black87),
                    size: 28,
                  ),
                ),
              );
            }).reversed.toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildMenu(bool isDark) {
    return Container(
      width: double.infinity,
      color: Colors.black.withOpacity(0.85),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _build3DLogPreview(),
          const SizedBox(height: 40),
          Text(
            widget.game.title.toUpperCase(),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 54,
              fontWeight: FontWeight.w900,
              letterSpacing: 8,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            "PRECISION IS EVERYTHING",
            style: TextStyle(
              color: Colors.white.withOpacity(0.5),
              fontSize: 16,
              fontWeight: FontWeight.bold,
              letterSpacing: 2,
            ),
          ),
          const SizedBox(height: 80),
          GestureDetector(
            onTap: _startGame,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 70, vertical: 22),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Colors.orange, Colors.deepOrange],
                ),
                borderRadius: BorderRadius.circular(40),
                boxShadow: [
                  BoxShadow(
                    color: Colors.orange.withOpacity(0.4),
                    blurRadius: 25,
                    offset: const Offset(0, 12),
                  ),
                ],
              ),
              child: const Text(
                "PLAY NOW",
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 2,
                  color: Colors.black,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _build3DLogPreview() {
    return Container(
      width: 150,
      height: 150,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: const Color(0xFF5D4037),
        boxShadow: [
          BoxShadow(
            color: Colors.orange.withOpacity(0.3),
            blurRadius: 40,
            spreadRadius: 10,
          ),
        ],
        border: Border.all(color: Colors.white24, width: 2),
      ),
      child: const Icon(
        Icons.ads_click_rounded,
        size: 80,
        color: Colors.orange,
      ),
    );
  }

  Widget _buildGameOverOverlay(bool isDark) {
    return Container(
      width: double.infinity,
      color: (isDark ? Colors.black : Colors.white).withOpacity(0.95),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.sentiment_very_dissatisfied_rounded,
            size: 80,
            color: Colors.redAccent,
          ),
          const SizedBox(height: 20),
          const Text(
            "GAME OVER",
            style: TextStyle(
              color: Colors.redAccent,
              fontSize: 44,
              fontWeight: FontWeight.w900,
              letterSpacing: 2,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            "SCORE: $_score",
            style: TextStyle(
              color: isDark ? Colors.white : Colors.black87,
              fontSize: 32,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 80),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _actionButton(
                "TRY AGAIN",
                _startGame,
                isDark ? Colors.white : Colors.black,
                isDark ? Colors.black : Colors.white,
              ),
              const SizedBox(width: 20),
              _actionButton(
                "MENU",
                () => setState(() => _isGameOver = false),
                isDark ? Colors.white12 : Colors.black12,
                isDark ? Colors.white : Colors.black,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildGameArea(bool isDark) {
    return GestureDetector(
      onTap: _throwKnife,
      behavior: HitTestBehavior.opaque,
      child: SizedBox.expand(
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Wood chips (Particles)
            ..._chips.map(
              (chip) => Positioned(
                left: MediaQuery.of(context).size.width / 2 + chip.x,
                top: MediaQuery.of(context).size.height / 2 + chip.y,
                child: Transform.rotate(
                  angle: chip.rotation,
                  child: Container(
                    width: chip.size,
                    height: chip.size,
                    decoration: BoxDecoration(
                      color: const Color(0xFF8D6E63).withOpacity(chip.life),
                      borderRadius: BorderRadius.circular(1),
                    ),
                  ),
                ),
              ),
            ),

            _buildRotatingLog(isDark),

            if (_isKnifeFlying) _buildFlyingKnife(isDark),

            // Bottom knife ready to be thrown
            if (!_isKnifeFlying &&
                _isPlaying &&
                !_isGameOver &&
                !_isLevelComplete)
              Positioned(bottom: 120, child: _buildKnifeWidget(isDark: isDark)),
          ],
        ),
      ),
    );
  }

  Widget _buildRotatingLog(bool isDark) {
    return Stack(
      alignment: Alignment.center,
      children: [
        // 3D Styled Rotating Log
        Transform.rotate(
          angle: _currentRotationAngle,
          child: Container(
            width: 220,
            height: 220,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0xFF5D4037),
              border: Border.all(color: const Color(0xFF3E2723), width: 12),
              boxShadow: [
                BoxShadow(
                  color: (isDark ? Colors.black : Colors.brown).withOpacity(
                    0.5,
                  ),
                  blurRadius: 30,
                  offset: const Offset(10, 10),
                ),
                BoxShadow(
                  color: Colors.white.withOpacity(0.1),
                  blurRadius: 5,
                  offset: const Offset(-4, -4),
                ),
              ],
              gradient: const RadialGradient(
                colors: [Color(0xFF8D6E63), Color(0xFF5D4037)],
                stops: [0.6, 1.0],
              ),
            ),
            child: _buildLogTexture(),
          ),
        ),

        // Knives stuck in log
        ..._knivesOnLog.map((angle) {
          return Transform.rotate(
            angle: _currentRotationAngle + angle,
            child: Transform.translate(
              offset: const Offset(0, 110),
              child: _buildKnifeWidget(isDark: isDark, isStuck: true),
            ),
          );
        }),
      ],
    );
  }

  Widget _buildLogTexture() {
    return CustomPaint(
      painter: _WoodGrainPainter(),
      child: Center(
        child: Container(
          width: 160,
          height: 160,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: const Color(0xFF3E2723).withOpacity(0.1),
              width: 2,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFlyingKnife(bool isDark) {
    return AnimatedBuilder(
      animation: _knifeThrowController,
      builder: (context, child) {
        const double startY = 320.0;
        const double endY = 110.0;
        double currentY =
            startY - (startY - endY) * _knifeThrowController.value;

        return Transform.translate(
          offset: Offset(0, currentY),
          child: _buildKnifeWidget(isDark: isDark),
        );
      },
    );
  }

  Widget _buildKnifeWidget({required bool isDark, bool isStuck = false}) {
    return Container(
      width: 16,
      height: 80,
      decoration: BoxDecoration(
        color: Colors.transparent,
        boxShadow: isStuck
            ? []
            : [
                BoxShadow(
                  color: Colors.black.withOpacity(0.4),
                  blurRadius: 6,
                  offset: const Offset(5, 5),
                ),
              ],
      ),
      child: Column(
        children: [
          // Blade (Metallic Chrome Effect)
          Container(
            width: 14,
            height: 55,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
                colors: [
                  const Color(0xFFE0E0E0),
                  const Color(0xFFFFFFFF),
                  const Color(0xFF9E9E9E),
                ],
                stops: const [0.0, 0.4, 1.0],
              ),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(10),
                bottom: Radius.circular(2),
              ),
              border: Border.all(color: Colors.black26, width: 0.5),
            ),
          ),
          // Hilt / Handle
          Container(
            width: 20,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.orangeAccent,
              borderRadius: BorderRadius.circular(2),
              boxShadow: const [
                BoxShadow(color: Colors.black45, blurRadius: 2),
              ],
            ),
          ),
          Container(
            width: 12,
            height: 21,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF3E2723), Color(0xFF5D4037)],
              ),
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: Colors.black38, width: 0.5),
            ),
          ),
        ],
      ),
    );
  }

  Widget _actionButton(
    String label,
    VoidCallback onTap,
    Color bgColor,
    Color textColor,
  ) {
    return ElevatedButton(
      onPressed: onTap,
      style: ElevatedButton.styleFrom(
        backgroundColor: bgColor,
        foregroundColor: textColor,
        padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 20),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(40)),
        elevation: 15,
        shadowColor: bgColor.withOpacity(0.4),
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w900,
          letterSpacing: 1.5,
        ),
      ),
    );
  }
}

class _WoodGrainPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF3E2723).withOpacity(0.12)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5;

    final center = Offset(size.width / 2, size.height / 2);
    // Concentric rings
    for (int i = 1; i < 7; i++) {
      canvas.drawCircle(center, (size.width / 2) * (i / 7), paint);
    }

    // Vertical Grains
    final random = math.Random(5678);
    for (int i = 0; i < 15; i++) {
      double angle = random.nextDouble() * math.pi * 2;
      double r = (size.width / 5) + random.nextDouble() * (size.width / 3);
      canvas.drawLine(
        Offset(
          center.dx + math.cos(angle) * r,
          center.dy + math.sin(angle) * r,
        ),
        Offset(
          center.dx + math.cos(angle) * (r + 25),
          center.dy + math.sin(angle) * (r + 25),
        ),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _WoodChip {
  double x = 0;
  double y = 0;
  double vx = math.Random().nextDouble() * 15 - 7.5;
  double vy = math.Random().nextDouble() * -10 - 5;
  double rotation = math.Random().nextDouble() * math.pi * 2;
  double vr = math.Random().nextDouble() * 0.4 - 0.2;
  double size = math.Random().nextDouble() * 8 + 4;
  double life = 1.0;

  void update(double dt) {
    x += vx * dt * 60;
    y += vy * dt * 60;
    vy += 0.8; // Gravity
    rotation += vr;
    life -= 0.04;
  }
}
