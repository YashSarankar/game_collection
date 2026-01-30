import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../core/models/game_model.dart';
import '../../core/services/haptic_service.dart';
import '../../core/services/sound_service.dart';

enum TugOfWarMode { vsAI, pvp }

enum AIDifficulty { easy, medium, hard }

class TugOfWarWidget extends StatefulWidget {
  final GameModel game;

  const TugOfWarWidget({super.key, required this.game});

  @override
  State<TugOfWarWidget> createState() => _TugOfWarWidgetState();
}

class _TugOfWarWidgetState extends State<TugOfWarWidget>
    with TickerProviderStateMixin {
  TugOfWarMode _mode = TugOfWarMode.pvp;
  AIDifficulty _difficulty = AIDifficulty.medium;

  bool _isPlaying = false;
  bool _isGameOver = false;
  bool _isCountingDown = false;
  int _countdownValue = 3;

  double _ropePosition = 0.5; // 0.0 = Player 1 wins, 1.0 = Player 2 wins
  int _gameTime = 15;
  int _timeRemaining = 15;
  Timer? _gameTimer;
  Timer? _aiTimer;

  String _winner = "";

  late HapticService _hapticService;
  late SoundService _soundService;
  bool _servicesInitialized = false;

  // Anti-cheese
  DateTime? _lastTapP1;
  DateTime? _lastTapP2;
  static const int minTapIntervalMs = 50; // Max 20 taps per second

  @override
  void initState() {
    super.initState();
    _initializeServices();
  }

  Future<void> _initializeServices() async {
    _hapticService = await HapticService.getInstance();
    _soundService = await SoundService.getInstance();
    if (mounted) {
      setState(() {
        _servicesInitialized = true;
      });
    }
  }

  @override
  void dispose() {
    _gameTimer?.cancel();
    _aiTimer?.cancel();
    super.dispose();
  }

  void _startCountdown() {
    setState(() {
      _isCountingDown = true;
      _countdownValue = 3;
      _isGameOver = false;
      _ropePosition = 0.5;
      _timeRemaining = _gameTime;
    });

    _hapticService.medium();

    Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      if (_countdownValue > 1) {
        setState(() {
          _countdownValue--;
        });
        _hapticService.light();
      } else {
        timer.cancel();
        _startGame();
      }
    });
  }

  void _startGame() {
    setState(() {
      _isCountingDown = false;
      _isPlaying = true;
    });

    _hapticService.heavy();
    _soundService.playGameStart();

    _gameTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      setState(() {
        if (_timeRemaining > 0) {
          _timeRemaining--;
        } else {
          _endGame();
        }
      });
    });

    if (_mode == TugOfWarMode.vsAI) {
      _startAI();
    }
  }

  void _startAI() {
    double tapRate;
    switch (_difficulty) {
      case AIDifficulty.easy:
        tapRate = 3.0; // taps per second
        break;
      case AIDifficulty.medium:
        tapRate = 5.0;
        break;
      case AIDifficulty.hard:
        tapRate = 7.5;
        break;
    }

    _aiTimer = Timer.periodic(
      Duration(milliseconds: (1000 / tapRate).round()),
      (timer) {
        if (!_isPlaying) {
          timer.cancel();
          return;
        }

        // Add some variability to AI
        if (math.Random().nextDouble() > 0.1) {
          _handleTap(2); // AI is Player 2
        }
      },
    );
  }

  void _handleTap(int player) {
    if (!_isPlaying || _isGameOver) return;

    final now = DateTime.now();
    if (player == 1) {
      if (_lastTapP1 != null &&
          now.difference(_lastTapP1!).inMilliseconds < minTapIntervalMs)
        return;
      _lastTapP1 = now;

      setState(() {
        _ropePosition -= 0.012; // Pull left
        if (_ropePosition <= 0.05) _endGame("PLAYER 1 WINS!");
      });
    } else {
      if (player == 2 && _mode == TugOfWarMode.pvp) {
        if (_lastTapP2 != null &&
            now.difference(_lastTapP2!).inMilliseconds < minTapIntervalMs)
          return;
        _lastTapP2 = now;
      }

      setState(() {
        _ropePosition += 0.012; // Pull right
        if (_ropePosition >= 0.95) {
          _endGame(_mode == TugOfWarMode.vsAI ? "AI WINS!" : "PLAYER 2 WINS!");
        }
      });
    }

    _hapticService.light();
  }

  void _endGame([String? winnerOverride]) {
    _gameTimer?.cancel();
    _aiTimer?.cancel();

    setState(() {
      _isPlaying = false;
      _isGameOver = true;
      if (winnerOverride != null) {
        _winner = winnerOverride;
      } else {
        if (_ropePosition < 0.5) {
          _winner = "PLAYER 1 WINS!";
        } else if (_ropePosition > 0.5) {
          _winner = _mode == TugOfWarMode.vsAI ? "AI WINS!" : "PLAYER 2 WINS!";
        } else {
          _winner = "IT'S A DRAW!";
        }
      }
    });

    _soundService.playGameOver();
    _hapticService.success();
  }

  @override
  Widget build(BuildContext context) {
    if (!_servicesInitialized) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          _buildGameplay(),
          if (!_isPlaying && !_isCountingDown && !_isGameOver) _buildMenu(),
          if (_isCountingDown) _buildCountdownOverlay(),
          if (_isGameOver) _buildGameOverOverlay(),
          _buildTopBar(),
        ],
      ),
    );
  }

  Widget _buildTopBar() {
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
              if (!_isPlaying && !_isCountingDown && !_isGameOver)
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.white54),
                  onPressed: () => Navigator.of(context).pop(),
                )
              else
                const SizedBox(width: 48),
              if (_isPlaying)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white10,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    "TIME: $_timeRemaining",
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                )
              else
                const SizedBox(width: 48),
              const SizedBox(width: 48),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGameplay() {
    return Column(
      children: [
        // Player 2 Side (or AI)
        Expanded(
          child: GestureDetector(
            onTapDown: (_) => _handleTap(2),
            child: Container(
              width: double.infinity,
              color: Colors.blue.withOpacity(0.8),
              child: RotatedBox(
                quarterTurns: 2,
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        _mode == TugOfWarMode.vsAI
                            ? Icons.smart_toy
                            : Icons.pan_tool_alt,
                        color: Colors.white54,
                        size: 80,
                      ),
                      const SizedBox(height: 20),
                      const Text(
                        "TAP TAP TAP!",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 2,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),

        // Rope Area
        Container(
          height: 120,
          color: Colors.grey[900],
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Central Line
              Container(width: 4, height: 120, color: Colors.white24),

              // Win Zones
              Positioned(
                left: 0,
                child: Container(
                  width: 20,
                  height: 120,
                  color: Colors.red.withOpacity(0.5),
                ),
              ),
              Positioned(
                right: 0,
                child: Container(
                  width: 20,
                  height: 120,
                  color: Colors.blue.withOpacity(0.5),
                ),
              ),

              // The Rope
              LayoutBuilder(
                builder: (context, constraints) {
                  final double ropeX = _ropePosition * constraints.maxWidth;
                  return Stack(
                    children: [
                      // Main Rope Line
                      Center(
                        child: Container(
                          height: 12,
                          color: Colors.brown[400],
                          width: double.infinity,
                        ),
                      ),

                      // The Center Marker (The "Flag")
                      AnimatedPositioned(
                        duration: const Duration(milliseconds: 50),
                        left: ropeX - 30,
                        top: 40,
                        width: 60,
                        height: 40,
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.amber,
                            borderRadius: BorderRadius.circular(8),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.amber.withOpacity(0.5),
                                blurRadius: 10,
                                spreadRadius: 2,
                              ),
                            ],
                          ),
                          child: const Icon(Icons.flag, color: Colors.black),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ],
          ),
        ),

        // Player 1 Side
        Expanded(
          child: GestureDetector(
            onTapDown: (_) => _handleTap(1),
            child: Container(
              width: double.infinity,
              color: Colors.red.withOpacity(0.8),
              child: const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.pan_tool_alt, color: Colors.white54, size: 80),
                    SizedBox(height: 20),
                    Text(
                      "TAP TAP TAP!",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 2,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMenu() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            widget.game.secondaryColor.withOpacity(0.3),
            Colors.black,
            widget.game.primaryColor.withOpacity(0.3),
          ],
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.05),
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white10),
            ),
            child: Icon(widget.game.icon, size: 70, color: Colors.amber),
          ),
          const SizedBox(height: 20),
          Text(
            widget.game.title.toUpperCase(),
            style: const TextStyle(
              fontSize: 48,
              fontWeight: FontWeight.w900,
              color: Colors.white,
              letterSpacing: 6,
            ),
          ),
          const SizedBox(height: 40),

          _menuButton("VS FRIEND", TugOfWarMode.pvp, Colors.blueAccent),
          const SizedBox(height: 16),
          _menuButton("VS AI BOT", TugOfWarMode.vsAI, Colors.redAccent),

          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            height: _mode == TugOfWarMode.vsAI ? 120 : 0,
            child: SingleChildScrollView(
              physics: const NeverScrollableScrollPhysics(),
              child: Column(
                children: [
                  const SizedBox(height: 30),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _diffButton(AIDifficulty.easy),
                      _diffButton(AIDifficulty.medium),
                      _diffButton(AIDifficulty.hard),
                    ],
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 60),
          GestureDetector(
            onTap: _startCountdown,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 60, vertical: 22),
              decoration: BoxDecoration(
                color: Colors.amber,
                borderRadius: BorderRadius.circular(35),
                boxShadow: [
                  BoxShadow(
                    color: Colors.amber.withOpacity(0.4),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: const Text(
                "START BATTLE",
                style: TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: 22,
                  color: Colors.black,
                  letterSpacing: 1.5,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _menuButton(String label, TugOfWarMode mode, Color color) {
    final isSelected = _mode == mode;
    return GestureDetector(
      onTap: () {
        _hapticService.selectionClick();
        setState(() => _mode = mode);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 240,
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: isSelected ? color : Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? Colors.white : Colors.white10,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.white60,
            fontWeight: FontWeight.w900,
            fontSize: 16,
            letterSpacing: 1.2,
          ),
        ),
      ),
    );
  }

  Widget _diffButton(AIDifficulty diff) {
    final isSelected = _difficulty == diff;
    return GestureDetector(
      onTap: () {
        _hapticService.selectionClick();
        setState(() => _difficulty = diff);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.symmetric(horizontal: 6),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: isSelected ? Colors.white : Colors.white10),
        ),
        child: Text(
          diff.name.toUpperCase(),
          style: TextStyle(
            color: isSelected ? Colors.black : Colors.white38,
            fontSize: 13,
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
    );
  }

  Widget _buildCountdownOverlay() {
    return Container(
      color: Colors.black54,
      child: Center(
        child: Text(
          "$_countdownValue",
          style: const TextStyle(
            fontSize: 150,
            fontWeight: FontWeight.w900,
            color: Colors.white,
          ),
        ),
      ),
    );
  }

  Widget _buildGameOverOverlay() {
    return Container(
      color: Colors.black.withOpacity(0.9),
      width: double.infinity,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text(
            "GAME OVER",
            style: TextStyle(
              color: Colors.white54,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            _winner,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 40,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 60),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _actionButton(
                "REMATCH",
                _startCountdown,
                Colors.amber,
                Colors.black,
              ),
              const SizedBox(width: 20),
              _actionButton(
                "MENU",
                () => setState(() => _isGameOver = false),
                Colors.white12,
                Colors.white,
              ),
            ],
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
        padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
      child: Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
    );
  }
}
