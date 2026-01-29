import 'dart:async';
import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/models/game_model.dart';
import '../../core/services/haptic_service.dart';
import '../../ui/widgets/game_countdown.dart';
import 'ping_pong_game.dart';

class PingPongWidget extends StatefulWidget {
  final GameModel game;

  const PingPongWidget({super.key, required this.game});

  @override
  State<PingPongWidget> createState() => _PingPongWidgetState();
}

class _PingPongWidgetState extends State<PingPongWidget> {
  PingPongGame? _game;
  int topScore = 0;
  int bottomScore = 0;
  HapticService? _hapticService;

  bool _isInitialized = false;
  bool _showCountdown = false;
  bool _hasStartedMatch = false;
  bool _showInitialHint = true;
  Timer? _hintTimer;

  @override
  void initState() {
    super.initState();
    _hintTimer = Timer(const Duration(seconds: 4), () {
      if (mounted) setState(() => _showInitialHint = false);
    });
  }

  @override
  void dispose() {
    _hintTimer?.cancel();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final bgColor = theme.scaffoldBackgroundColor;
    final ballColor = isDark ? Colors.white : Colors.black87;

    if (!_isInitialized) {
      _initializeGame(bgColor, ballColor);
      _isInitialized = true;
    } else if (_game != null) {
      _game!.updateColors(bgColor, ballColor);
    }
  }

  Future<void> _initializeGame(Color bgColor, Color ballColor) async {
    _hapticService = await HapticService.getInstance();
    if (!mounted) return;

    setState(() {
      _hasStartedMatch = false;
      topScore = 0;
      bottomScore = 0;
      _game = PingPongGame(
        hapticService: _hapticService,
        ballColor: ballColor,
        gameBackgroundColor: bgColor,
        onGameOver: () {
          setState(() {});
        },
        onScoreUpdate: (t, b) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              setState(() {
                topScore = t;
                bottomScore = b;
              });
            }
          });
        },
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_game == null) {
      return const Center(child: CircularProgressIndicator());
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final iconColor = isDark ? Colors.white54 : Colors.black54;
    final hintColor = isDark
        ? Colors.white.withOpacity(0.5)
        : Colors.black.withOpacity(0.5);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Stack(
        children: [
          // 1. Large Background Score Decoration
          Positioned.fill(
            child: IgnorePointer(
              child: Opacity(
                opacity: 0.08,
                child: Column(
                  children: [
                    Expanded(
                      child: Center(
                        child: Text(
                          "$topScore",
                          style: const TextStyle(
                            fontSize: 280,
                            fontWeight: FontWeight.w900,
                            color: Colors.redAccent,
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: Center(
                        child: Text(
                          "$bottomScore",
                          style: const TextStyle(
                            fontSize: 280,
                            fontWeight: FontWeight.w900,
                            color: Colors.blueAccent,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // 2. The Game
          GameWidget(game: _game!, autofocus: true),

          // 3. Real-Time High-Visibility Scoreboard
          Positioned(
            right: 20,
            top: 0,
            bottom: 0,
            child: IgnorePointer(
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildCompactScore(topScore, Colors.redAccent, "P2"),
                    Container(
                      height: 40,
                      width: 2,
                      color: isDark ? Colors.white12 : Colors.black12,
                      margin: const EdgeInsets.symmetric(vertical: 8),
                    ),
                    _buildCompactScore(bottomScore, Colors.blueAccent, "P1"),
                  ],
                ),
              ),
            ),
          ),

          // 4. UI Header
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    if (!_hasStartedMatch)
                      Align(
                        alignment: Alignment.centerLeft,
                        child: IconButton(
                          onPressed: () => Navigator.pop(context),
                          icon: Icon(
                            Icons.arrow_back_ios_new_rounded,
                            color: iconColor,
                            size: 22,
                          ),
                        ),
                      ),
                    Text(
                      widget.game.title,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: isDark ? Colors.white : Colors.black,
                        letterSpacing: -0.5,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // 5. Match Start Overlay
          if (!_game!.isGameStarted &&
              !_game!.isGameOver &&
              !_showCountdown &&
              !_game!.isPaused)
            Positioned.fill(
              child: Container(
                color: Colors.black.withOpacity(0.4),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (_showInitialHint) ...[
                        const Text(
                          "FIRST TO 7 POINTS",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 2,
                          ),
                        ),
                        const SizedBox(height: 32),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            _buildControlHint("P1: W/A/S/D", Colors.blueAccent),
                            const SizedBox(width: 20),
                            _buildControlHint("P2: ARROWS", Colors.redAccent),
                          ],
                        ),
                        const SizedBox(height: 48),
                      ],
                      GestureDetector(
                        onTap: () {
                          if (!_hasStartedMatch) {
                            setState(() {
                              _showCountdown = true;
                              _hasStartedMatch = true;
                              _showInitialHint = false;
                              _hintTimer?.cancel();
                            });
                          } else {
                            _game!.releaseBall();
                          }
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 48,
                            vertical: 20,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(40),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.3),
                                blurRadius: 20,
                                offset: const Offset(0, 10),
                              ),
                            ],
                          ),
                          child: Text(
                            _hasStartedMatch ? "SERVE BALL" : "PLAY MATCH",
                            style: TextStyle(
                              color: widget.game.primaryColor,
                              fontSize: 20,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 1,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

          // 6. Victory Screen
          if (_game!.isGameOver)
            Positioned.fill(
              child: Container(
                color: Colors.black.withOpacity(0.95),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.emoji_events,
                        color: bottomScore >= 7
                            ? Colors.blueAccent
                            : Colors.redAccent,
                        size: 100,
                      ),
                      const SizedBox(height: 24),
                      Text(
                        bottomScore >= 7 ? "P1 DOMINATION!" : "P2 DOMINATION!",
                        style: TextStyle(
                          color: bottomScore >= 7
                              ? Colors.blueAccent
                              : Colors.redAccent,
                          fontSize: 40,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        "$bottomScore - $topScore",
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 64,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 48),
                      ElevatedButton(
                        onPressed: () {
                          _game!.restartGame();
                          setState(() {});
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: Colors.black,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 40,
                            vertical: 16,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                        ),
                        child: const Text(
                          "REMATCH",
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text(
                          "EXIT TO MENU",
                          style: TextStyle(color: Colors.white54, fontSize: 16),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

          // 7. Serves / Pause Indicator
          if (_game!.isPaused && !_showCountdown && !_game!.isGameOver)
            Positioned(
              top: MediaQuery.of(context).size.height * 0.45,
              left: 0,
              right: 0,
              child: const Center(
                child: Text(
                  "READY...",
                  style: TextStyle(
                    color: Colors.white54,
                    fontSize: 40,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 4,
                  ),
                ),
              ),
            ),

          // 8. Global Countdown Overlay
          if (_showCountdown)
            Container(
              color: Colors.black54,
              child: GameCountdown(
                onFinished: () {
                  if (mounted) {
                    _game!.releaseBall();
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

  Widget _buildCompactScore(int score, Color color, String label) {
    return Container(
      width: 60,
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.5), width: 2),
      ),
      child: Column(
        children: [
          Text(
            label,
            style: TextStyle(
              color: color.withOpacity(0.6),
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            "$score",
            style: TextStyle(
              color: color,
              fontSize: 32,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildControlHint(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        border: Border.all(color: color.withOpacity(0.5)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.bold,
          fontSize: 14,
        ),
      ),
    );
  }
}
