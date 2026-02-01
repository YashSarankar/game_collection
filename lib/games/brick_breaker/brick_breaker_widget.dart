import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import '../../core/models/game_model.dart';
import '../../core/services/haptic_service.dart';
import '../../ui/widgets/game_countdown.dart';
import '../../ui/widgets/game_over_dialog.dart';
import 'brick_breaker_game.dart';

class BrickBreakerWidget extends StatefulWidget {
  final GameModel game;

  const BrickBreakerWidget({super.key, required this.game});

  @override
  State<BrickBreakerWidget> createState() => _BrickBreakerWidgetState();
}

class _BrickBreakerWidgetState extends State<BrickBreakerWidget> {
  BrickBreakerGame? _game;
  int currentScore = 0;
  HapticService? _hapticService;

  bool _isInitialized = false;
  bool _showCountdown = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final ballColor = isDark ? Colors.white : Colors.black87;
    const paddleColor = Color(0xFFFF8C00);
    final bgColor = theme.scaffoldBackgroundColor;

    if (!_isInitialized) {
      _initializeGame(
        ballColor: ballColor,
        paddleColor: paddleColor,
        bgColor: bgColor,
      );
      _isInitialized = true;
    } else if (_game != null) {
      _game!.updateColors(
        ballColor: ballColor,
        paddleColor: paddleColor,
        gameBackgroundColor: bgColor,
      );
    }
  }

  Future<void> _initializeGame({
    required Color ballColor,
    required Color paddleColor,
    required Color bgColor,
  }) async {
    _hapticService = await HapticService.getInstance();

    if (!mounted) return;

    setState(() {
      _game = BrickBreakerGame(
        hapticService: _hapticService,
        ballColor: ballColor,
        paddleColor: paddleColor,
        gameBackgroundColor: bgColor,
        onGameOver: _showGameOverDialog,
        onScoreUpdate: (score) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              setState(() {
                currentScore = score;
              });
            }
          });
        },
      );
    });
  }

  void _showGameOverDialog() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => GameOverDialog(
          gameId: widget.game.id,
          score: currentScore,
          onRestart: () {
            Navigator.pop(context);
            final theme = Theme.of(context);
            final isDark = theme.brightness == Brightness.dark;
            _initializeGame(
              ballColor: isDark ? Colors.white : Colors.black87,
              paddleColor: const Color(0xFFFF8C00),
              bgColor: theme.scaffoldBackgroundColor,
            );
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
    if (_game == null) {
      return const Center(child: CircularProgressIndicator());
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : Colors.black;
    final overlayColor = isDark
        ? Colors.white.withOpacity(0.5)
        : Colors.black.withOpacity(0.5);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Stack(
        children: [
          // Game Engine
          GestureDetector(
            onTapDown: (_) {
              if (!_game!.isGameStarted &&
                  !_game!.isGameOver &&
                  !_showCountdown) {
                setState(() => _showCountdown = true);
              }
            },
            child: GameWidget(game: _game!),
          ),

          // UI Header
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
                    if (!_game!.isGameStarted && !_game!.isGameOver)
                      Align(
                        alignment: Alignment.centerLeft,
                        child: IconButton(
                          onPressed: () => Navigator.pop(context),
                          icon: Icon(
                            Icons.arrow_back_ios_new_rounded,
                            color: textColor,
                            size: 22,
                          ),
                        ),
                      ),
                    Text(
                      widget.game.title,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: textColor,
                        letterSpacing: -0.5,
                      ),
                    ),
                    Align(
                      alignment: Alignment.centerRight,
                      child: Padding(
                        padding: const EdgeInsets.only(right: 12),
                        child: Text(
                          'Score: $currentScore',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: textColor.withOpacity(0.9),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Start overlay hint
          if (!_game!.isGameStarted && !_game!.isGameOver && !_showCountdown)
            Positioned(
              bottom: 150,
              left: 0,
              right: 0,
              child: Center(
                child: Text(
                  "Tap to Start Countdown\nDrag to Move",
                  textAlign: TextAlign.center,
                  style: TextStyle(color: overlayColor, fontSize: 18),
                ),
              ),
            ),

          // Global Countdown Overlay
          if (_showCountdown)
            Container(
              color: Colors.black26,
              child: GameCountdown(
                onFinished: () {
                  if (mounted) {
                    _game!.startGame();
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
}
