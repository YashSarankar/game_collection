import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/models/game_model.dart';
import '../../core/services/haptic_service.dart';
import '../../core/services/sound_service.dart';
import '../../ui/widgets/game_countdown.dart';
import '../../ui/widgets/game_over_dialog.dart';
import 'brick_breaker_game.dart';
import 'brick_breaker_themes.dart';

class BrickBreakerWidget extends StatefulWidget {
  final GameModel game;

  const BrickBreakerWidget({super.key, required this.game});

  @override
  State<BrickBreakerWidget> createState() => _BrickBreakerWidgetState();
}

class _BrickBreakerWidgetState extends State<BrickBreakerWidget> {
  BrickBreakerGame? _game;
  int currentScore = 0;
  int currentCombo = 0;
  String levelText = "Level 1";
  Color levelColor = Colors.cyan;
  HapticService? _hapticService;
  SoundService? _soundService;

  bool _isInitialized = false;
  bool _showCountdown = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_isInitialized) {
      _initializeGame();
      _isInitialized = true;
    }
  }

  Future<void> _initializeGame() async {
    _hapticService = await HapticService.getInstance();
    _soundService = await SoundService.getInstance();

    if (!mounted) return;

    setState(() {
      _game = BrickBreakerGame(
        hapticService: _hapticService,
        soundService: _soundService,
        onGameOver: _showGameOverDialog,
        onScoreUpdate: (score) {
          if (mounted) setState(() => currentScore = score);
        },
        onComboUpdate: (combo) {
          if (mounted) setState(() => currentCombo = combo);
        },
        onLevelUpdate: (text, color) {
          if (mounted) {
            setState(() {
              levelText = text;
              levelColor = color;
            });
          }
        },
        onStartRequest: () {
          if (mounted) setState(() => _showCountdown = true);
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
            _initializeGame();
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
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final theme = BrickBreakerTheme.defaultTheme;

    return Scaffold(
      backgroundColor: theme.backgroundColor,
      body: Stack(
        children: [
          // Game Engine
          GameWidget(game: _game!),

          // minimal HUD
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 10,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'SCORE',
                          style: TextStyle(
                            fontSize: 10,
                            color: Colors.white.withOpacity(0.5),
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.2,
                          ),
                        ),
                        Text(
                          '$currentScore'.padLeft(6, '0'),
                          style: const TextStyle(
                            fontSize: 20,
                            color: Colors.white,
                            fontWeight: FontWeight.w900,
                            fontFamily: 'monospace',
                          ),
                        ),
                      ],
                    ),
                    Text(
                      levelText.toUpperCase(),
                      style: TextStyle(
                        color: levelColor,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 2,
                        shadows: [Shadow(color: levelColor, blurRadius: 10)],
                      ),
                    ).animate(key: ValueKey(levelText)).fadeIn().scale(),
                  ],
                ),
              ),
            ),
          ),

          // Combo Multiplier
          if (currentCombo > 1)
            Positioned(
              top: 100,
              right: 20,
              child: Column(
                children: [
                  Text(
                    '${currentCombo}x',
                    style: TextStyle(
                      fontSize: 36,
                      fontWeight: FontWeight.w900,
                      color: theme.glowColor,
                      fontStyle: FontStyle.italic,
                    ),
                  ).animate(key: ValueKey(currentCombo)).scale().shake(),
                ],
              ),
            ),

          // Start Overlay (Non-blocking for drags)
          if (!_game!.isGameStarted && !_game!.isGameOver && !_showCountdown)
            Positioned.fill(
              child: IgnorePointer(
                child: Container(
                  color: Colors.black26,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Spacer(),
                      const Text(
                            "TAP TO START",
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 24,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 4,
                            ),
                          )
                          .animate(onPlay: (c) => c.repeat(reverse: true))
                          .fadeOut(duration: 800.ms),
                      const SizedBox(height: 80),
                    ],
                  ),
                ),
              ),
            ),

          // Global Countdown Overlay (Non-blocking for drags)
          if (_showCountdown)
            Positioned.fill(
              child: IgnorePointer(
                ignoring:
                    false, // We want the countdown to finish, but actually the countdown is automated.
                // However, we want the GAME to handle the drag.
                // If we use IgnorePointer, the GameWidget underneath WILL get the drag.
                child: Container(
                  color: Colors.black54,
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
              ),
            ),
        ],
      ),
    );
  }
}
