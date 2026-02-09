import 'dart:async';
import 'package:flutter/material.dart';
import '../../core/models/game_model.dart';
import '../../core/services/haptic_service.dart';
import '../../core/services/sound_service.dart';
import 'air_hockey_logic.dart';
import '../../ui/widgets/game_countdown.dart';
import 'dart:ui' as ui;

class AirHockeyWidget extends StatefulWidget {
  final GameModel game;
  const AirHockeyWidget({super.key, required this.game});

  @override
  State<AirHockeyWidget> createState() => _AirHockeyWidgetState();
}

class _AirHockeyWidgetState extends State<AirHockeyWidget>
    with SingleTickerProviderStateMixin {
  late AirHockeyLogic logic;
  bool isGameStarted = false;
  bool isCountingDown = true;
  Timer? gameLoop;
  HapticService? _hapticService;
  SoundService? _soundService;

  // Multi-touch tracking
  final Map<int, bool> _touchSlots = {}; // index -> isTopPlayer
  final List<Offset> _puckTrail = [];
  bool _showGoalFlash = false;

  @override
  void initState() {
    super.initState();
    logic = AirHockeyLogic();
    _initServices();
    _setupSoundCallbacks();
  }

  Future<void> _initServices() async {
    _hapticService = await HapticService.getInstance();
    _soundService = await SoundService.getInstance();
    if (mounted) {
      setState(() {});
    }
  }

  void _setupSoundCallbacks() {
    // Sound callbacks removed - only goal sound is used
    logic.onPaddleHit = null;
    logic.onWallHit = null;
  }

  void _startGame() {
    setState(() {
      isCountingDown = false;
      isGameStarted = true;
    });

    gameLoop = Timer.periodic(const Duration(milliseconds: 16), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }

      int oldP1 = logic.player1Score;
      int oldP2 = logic.player2Score;

      setState(() {
        logic.update(0.016);
        if (_puckTrail.length > 10) _puckTrail.removeAt(0);
        _puckTrail.add(logic.puckPosition);
      });

      if (logic.player1Score != oldP1 || logic.player2Score != oldP2) {
        _hapticService?.heavy();
        _soundService?.playSound('sounds/airgoal.mp3'); // Air hockey goal sound
        _flashGoal();
        if (logic.player1Score >= 5 || logic.player2Score >= 5) {
          _showWinDialog(
            logic.player1Score >= 5 ? "Bottom Player" : "Top Player",
          );
        }
      }
    });
  }

  void _flashGoal() async {
    if (!mounted) return;
    setState(() => _showGoalFlash = true);
    await Future.delayed(const Duration(milliseconds: 200));
    if (mounted) setState(() => _showGoalFlash = false);
  }

  void _showWinDialog(String winner) {
    gameLoop?.cancel();
    showGeneralDialog(
      context: context,
      barrierDismissible: false,
      barrierLabel: "Game Over",
      barrierColor: Colors.black.withOpacity(0.5),
      transitionDuration: const Duration(milliseconds: 400),
      pageBuilder: (context, anim1, anim2) {
        return Center(
          child: ScaleTransition(
            scale: CurvedAnimation(parent: anim1, curve: Curves.easeOutBack),
            child: Material(
              color: Colors.transparent,
              child: BackdropFilter(
                filter: ui.ImageFilter.blur(sigmaX: 15, sigmaY: 15),
                child: Container(
                  width: 320,
                  padding: const EdgeInsets.all(32),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: Colors.white.withOpacity(0.2)),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: widget.game.primaryColor.withOpacity(0.2),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.emoji_events_rounded,
                          color: widget.game.primaryColor,
                          size: 48,
                        ),
                      ),
                      const SizedBox(height: 24),
                      Text(
                        "Victory!".toUpperCase(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 4,
                          decoration: TextDecoration.none,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        winner,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          decoration: TextDecoration.none,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        "${logic.player1Score} — ${logic.player2Score}",
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.7),
                          fontSize: 48,
                          fontWeight: FontWeight.w200,
                          letterSpacing: 8,
                          decoration: TextDecoration.none,
                        ),
                      ),
                      const SizedBox(height: 32),
                      Column(
                        children: [
                          _buildPremiumButton(
                            "Play Again",
                            Colors.white,
                            Colors.black,
                            () {
                              Navigator.pop(context);
                              setState(() {
                                logic.player1Score = 0;
                                logic.player2Score = 0;
                                isCountingDown = true;
                                isGameStarted = false;
                              });
                            },
                          ),
                          const SizedBox(height: 12),
                          _buildPremiumButton(
                            "Exit Game",
                            Colors.white.withOpacity(0.1),
                            Colors.white,
                            () {
                              Navigator.pop(context);
                              Navigator.pop(context);
                            },
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildPremiumButton(
    String text,
    Color bg,
    Color textCol,
    VoidCallback onTap,
  ) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: bg,
          foregroundColor: textCol,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: 0,
        ),
        child: Text(
          text,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  @override
  void dispose() {
    gameLoop?.cancel();
    super.dispose();
  }

  void _onPointerDown(PointerDownEvent event) {
    final box = context.findRenderObject() as RenderBox;
    final pos = box.globalToLocal(event.position);

    bool isTop = pos.dy < logic.tableSize.height / 2;
    _touchSlots[event.pointer] = isTop;

    if (isTop) {
      logic.movePaddle2(pos);
    } else {
      logic.movePaddle1(pos);
    }
  }

  void _onPointerMove(PointerMoveEvent event) {
    final box = context.findRenderObject() as RenderBox;
    final pos = box.globalToLocal(event.position);

    bool? isTop = _touchSlots[event.pointer];
    if (isTop == true) {
      logic.movePaddle2(pos);
    } else if (isTop == false) {
      logic.movePaddle1(pos);
    }
  }

  void _onPointerUp(PointerUpEvent event) {
    _touchSlots.remove(event.pointer);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Colors.black,
      body: LayoutBuilder(
        builder: (context, constraints) {
          if (logic.tableSize == Size.zero) {
            logic.initialize(Size(constraints.maxWidth, constraints.maxHeight));
          }

          return Stack(
            children: [
              // Rink UI
              Positioned.fill(child: _buildRink(isDark)),

              // Score Board
              _buildScoreBoard(),

              // Puck & Paddles
              Positioned.fill(
                child: Listener(
                  onPointerDown: _onPointerDown,
                  onPointerMove: _onPointerMove,
                  onPointerUp: _onPointerUp,
                  child: CustomPaint(
                    painter: AirHockeyPainter(
                      logic: logic,
                      isDark: isDark,
                      primaryColor: widget.game.primaryColor,
                      puckTrail: _puckTrail,
                    ),
                  ),
                ),
              ),

              if (_showGoalFlash)
                Positioned.fill(
                  child: Container(color: Colors.white.withOpacity(0.3)),
                ),

              // Countdown
              if (isCountingDown)
                Positioned.fill(
                  child: ClipRect(
                    child: BackdropFilter(
                      filter: ui.ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                      child: Container(
                        color: Colors.black.withOpacity(0.6),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Text(
                              "AIR HOCKEY",
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 40,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 10,
                              ),
                            ),
                            const SizedBox(height: 48),
                            const Text(
                              "FIRST TO 5 GOALS",
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 4,
                              ),
                            ),
                            const SizedBox(height: 24),
                            GameCountdown(onFinished: _startGame),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),

              // Back Button
              if (!isGameStarted || isCountingDown)
                Positioned(
                  top: 10,
                  left: 10,
                  child: SafeArea(child: const BackButton(color: Colors.white)),
                ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildRink(bool isDark) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
        border: Border.all(
          color: widget.game.primaryColor.withOpacity(0.5),
          width: 8,
        ),
      ),
      child: Stack(
        children: [
          // Grid pattern for "Table" look
          CustomPaint(
            size: Size.infinite,
            painter: TableGridPainter(isDark: isDark),
          ),
          // Center line (Glowy)
          Center(
            child: Container(
              height: 2,
              width: double.infinity,
              decoration: BoxDecoration(
                boxShadow: [
                  BoxShadow(
                    color: widget.game.primaryColor.withOpacity(0.5),
                    blurRadius: 10,
                    spreadRadius: 2,
                  ),
                ],
                color: widget.game.primaryColor.withOpacity(0.8),
              ),
            ),
          ),
          // Center circle (Glowy)
          Center(
            child: Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: widget.game.primaryColor.withOpacity(0.5),
                  width: 3,
                ),
                boxShadow: [
                  BoxShadow(
                    color: widget.game.primaryColor.withOpacity(0.2),
                    blurRadius: 15,
                    spreadRadius: 5,
                  ),
                ],
              ),
            ),
          ),
          // Top Goal Area (Red Glow)
          Align(
            alignment: Alignment.topCenter,
            child: Container(
              width: logic.goalWidth,
              height: 10,
              decoration: BoxDecoration(
                color: Colors.red,
                boxShadow: [
                  BoxShadow(
                    color: Colors.red.withOpacity(0.8),
                    blurRadius: 20,
                    spreadRadius: 5,
                  ),
                ],
                borderRadius: const BorderRadius.vertical(
                  bottom: Radius.circular(30),
                ),
              ),
            ),
          ),
          // Bottom Goal Area (Blue Glow)
          Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              width: logic.goalWidth,
              height: 10,
              decoration: BoxDecoration(
                color: Colors.blue,
                boxShadow: [
                  BoxShadow(
                    color: Colors.blue.withOpacity(0.8),
                    blurRadius: 20,
                    spreadRadius: 5,
                  ),
                ],
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(30),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScoreBoard() {
    return Center(
      child: RotatedBox(
        quarterTurns: 1,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _scoreText(logic.player2Score, Colors.red),
            const SizedBox(width: 40),
            _scoreText(logic.player1Score, Colors.blue),
          ],
        ),
      ),
    );
  }

  Widget _scoreText(int score, Color color) {
    return Text(
      "$score",
      style: TextStyle(
        fontSize: 80,
        fontWeight: FontWeight.w900,
        color: color.withOpacity(0.2),
      ),
    );
  }
}

class AirHockeyPainter extends CustomPainter {
  final AirHockeyLogic logic;
  final bool isDark;
  final Color primaryColor;
  final List<Offset> puckTrail;

  AirHockeyPainter({
    required this.logic,
    required this.isDark,
    required this.primaryColor,
    required this.puckTrail,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // 0. Puck Trail
    for (int i = 0; i < puckTrail.length; i++) {
      final double opacity = (i + 1) / puckTrail.length * 0.3;
      final double radius = (i + 1) / puckTrail.length * logic.puckRadius;
      canvas.drawCircle(
        puckTrail[i],
        radius,
        Paint()
          ..color = Colors.orange.withOpacity(opacity)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3),
      );
    }

    // 1. Puck
    final puckPaint = Paint()
      ..shader =
          RadialGradient(
            colors: [
              Colors.orange[300]!,
              Colors.orange[700]!,
              Colors.orange[900]!,
            ],
            stops: const [0.0, 0.7, 1.0],
          ).createShader(
            Rect.fromCircle(
              center: logic.puckPosition,
              radius: logic.puckRadius,
            ),
          )
      ..style = PaintingStyle.fill;

    // Puck Glow (Attractive)
    canvas.drawCircle(
      logic.puckPosition,
      logic.puckRadius + 8,
      Paint()
        ..color = Colors.orange.withOpacity(0.2)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12),
    );

    canvas.drawCircle(logic.puckPosition, logic.puckRadius, puckPaint);
    // Puck highlight
    canvas.drawCircle(
      logic.puckPosition - const Offset(3, 3),
      logic.puckRadius * 0.4,
      Paint()..color = Colors.white.withOpacity(0.4),
    );

    // 2. Paddle 1 (Bottom - Blue)
    _drawPaddle(canvas, logic.paddle1Position, Colors.blue);

    // 3. Paddle 2 (Top - Red)
    _drawPaddle(canvas, logic.paddle2Position, Colors.red);
  }

  void _drawPaddle(Canvas canvas, Offset pos, Color color) {
    // 3D Effect Layers
    final Rect paddleRect = Rect.fromCircle(
      center: pos,
      radius: logic.paddleRadius,
    );

    // 1. Bottom shadow (Depth)
    canvas.drawCircle(
      pos + const Offset(0, 6),
      logic.paddleRadius,
      Paint()
        ..color = Colors.black.withOpacity(0.5)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4),
    );

    // 2. Main rim (Metallic look)
    canvas.drawCircle(
      pos,
      logic.paddleRadius,
      Paint()
        ..shader = LinearGradient(
          colors: [color.withOpacity(0.8), color, color.withOpacity(0.6)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ).createShader(paddleRect),
    );

    // 3. Top Knob (3D handle)
    final knobRadius = logic.paddleRadius * 0.65;
    canvas.drawCircle(
      pos,
      knobRadius,
      Paint()
        ..shader = RadialGradient(
          colors: [Colors.white.withOpacity(0.2), Colors.transparent],
          center: const Alignment(-0.5, -0.5),
        ).createShader(Rect.fromCircle(center: pos, radius: knobRadius))
        ..style = PaintingStyle.fill,
    );

    // Knob outline
    canvas.drawCircle(
      pos,
      knobRadius,
      Paint()
        ..color = Colors.white.withOpacity(0.3)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );

    // 4. Center Grip
    canvas.drawCircle(
      pos,
      knobRadius * 0.4,
      Paint()
        ..color = Colors.black.withOpacity(0.2)
        ..style = PaintingStyle.fill,
    );

    // Highlight ring
    canvas.drawCircle(
      pos,
      logic.paddleRadius * 0.9,
      Paint()
        ..color = Colors.white.withOpacity(0.2)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class TableGridPainter extends CustomPainter {
  final bool isDark;
  TableGridPainter({required this.isDark});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = isDark
          ? Colors.white.withOpacity(0.05)
          : Colors.black.withOpacity(0.05)
      ..strokeWidth = 1;

    for (double i = 0; i < size.width; i += 40) {
      canvas.drawLine(Offset(i, 0), Offset(i, size.height), paint);
    }
    for (double i = 0; i < size.height; i += 40) {
      canvas.drawLine(Offset(0, i), Offset(size.width, i), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
