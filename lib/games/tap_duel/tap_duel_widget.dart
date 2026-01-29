import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../core/models/game_model.dart';
import '../../core/services/haptic_service.dart';
import '../../core/services/sound_service.dart';

enum TapDuelMode { scoreRace, timeAttack, pushBattle }

class TapDuelWidget extends StatefulWidget {
  final GameModel game;

  const TapDuelWidget({super.key, required this.game});

  @override
  State<TapDuelWidget> createState() => _TapDuelWidgetState();
}

class _TapDuelWidgetState extends State<TapDuelWidget>
    with TickerProviderStateMixin {
  int _player1Score = 0;
  int _player2Score = 0;
  bool _isGameOver = false;
  bool _isCountingDown = false;
  int _countdownValue = 3;
  TapDuelMode _mode = TapDuelMode.scoreRace;
  bool _vsAI = false;
  bool _gameStarted = false;
  String _winner = "";

  Timer? _gameTimer;
  int _secondsRemaining = 5;

  // For AI
  Timer? _aiTimer;

  // For Push Battle
  double _pushPosition = 0.5; // 0.0 = player 1 wins, 1.0 = player 2 wins

  late HapticService _hapticService;
  late SoundService _soundService;
  bool _servicesInitialized = false;

  // Animation controllers for feedback
  late AnimationController _p1PulseController;
  late AnimationController _p2PulseController;
  late AnimationController _shakeController;

  // For multi-touch prevention
  final Map<int, int> _activePointers = {}; // pointerId -> playerNum

  @override
  void initState() {
    super.initState();
    _initializeServices();

    _p1PulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
    );
    _p2PulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
    );
    _shakeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 50),
    );
  }

  Future<void> _initializeServices() async {
    _hapticService = await HapticService.getInstance();
    _soundService = await SoundService.getInstance();
    setState(() {
      _servicesInitialized = true;
    });
  }

  @override
  void dispose() {
    _gameTimer?.cancel();
    _aiTimer?.cancel();
    _p1PulseController.dispose();
    _p2PulseController.dispose();
    _shakeController.dispose();
    super.dispose();
  }

  void _startCountdown() {
    _hapticService.medium();
    setState(() {
      _isCountingDown = true;
      _countdownValue = 3;
      _gameStarted = false;
      _isGameOver = false;
      _player1Score = 0;
      _player2Score = 0;
      _pushPosition = 0.5;
      _secondsRemaining = 5;
    });

    Timer.periodic(const Duration(seconds: 1), (timer) {
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
      _gameStarted = true;
    });
    _hapticService.heavy();
    _soundService.playGameStart();

    if (_mode == TapDuelMode.timeAttack) {
      _gameTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
        setState(() {
          if (_secondsRemaining > 1) {
            _secondsRemaining--;
          } else {
            _secondsRemaining = 0;
            _endGame();
            timer.cancel();
          }
        });
      });
    }

    if (_vsAI) {
      _startAI();
    }
  }

  void _startAI() {
    _aiTimer?.cancel();
    // AI taps at variable speed between 4 and 8 taps per second
    double tapsPerSecond = 4.0 + math.Random().nextDouble() * 4.0;
    int intervalMs = (1000 / tapsPerSecond).round();

    _aiTimer = Timer.periodic(Duration(milliseconds: intervalMs), (timer) {
      if (!_gameStarted || _isGameOver) {
        timer.cancel();
        return;
      }
      _playerTap(2);
    });
  }

  void _playerTap(int player) {
    if (!_gameStarted || _isGameOver) return;

    setState(() {
      if (player == 1) {
        _player1Score++;
        _p1PulseController.forward(from: 0);
        if (_mode == TapDuelMode.pushBattle) {
          _pushPosition += 0.02;
          if (_pushPosition >= 0.98) _endGame(1);
        } else if (_mode == TapDuelMode.scoreRace && _player1Score >= 30) {
          _endGame(1);
        }
      } else {
        _player2Score++;
        _p2PulseController.forward(from: 0);
        if (_mode == TapDuelMode.pushBattle) {
          _pushPosition -= 0.02;
          if (_pushPosition <= 0.02) _endGame(2);
        } else if (_mode == TapDuelMode.scoreRace && _player2Score >= 30) {
          _endGame(2);
        }
      }
    });

    _hapticService.light();
    _shakeController.forward(from: 0).then((_) => _shakeController.reverse());
  }

  void _endGame([int? winnerOverride]) {
    _gameTimer?.cancel();
    _aiTimer?.cancel();

    int winner = 0;
    if (winnerOverride != null) {
      winner = winnerOverride;
    } else {
      if (_mode == TapDuelMode.pushBattle) {
        winner = _pushPosition > 0.5 ? 1 : 2;
      } else {
        if (_player1Score > _player2Score)
          winner = 1;
        else if (_player2Score > _player1Score)
          winner = 2;
        else
          winner = 0; // Draw
      }
    }

    setState(() {
      _isGameOver = true;
      _gameStarted = false;
      if (winner == 1)
        _winner = "PLAYER 1 WINS!";
      else if (winner == 2)
        _winner = _vsAI ? "AI WINS!" : "PLAYER 2 WINS!";
      else
        _winner = "IT'S A DRAW!";
    });

    _hapticService.success();
    _soundService.playSuccess();
  }

  @override
  Widget build(BuildContext context) {
    if (!_servicesInitialized) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      backgroundColor: Colors.black,
      body: AnimatedBuilder(
        animation: _shakeController,
        builder: (context, child) {
          final shake = math.sin(_shakeController.value * math.pi * 10) * 3;
          return Transform.translate(offset: Offset(0, shake), child: child);
        },
        child: Stack(
          children: [
            // Game Arena
            Column(
              children: [
                // Player 2 Zone (Top) - Rotated for face-to-face
                Expanded(
                  child: RotatedBox(
                    quarterTurns: 2,
                    child: _buildPlayerZone(2),
                  ),
                ),
                // Divider / Progress Bar
                _buildDivider(),
                // Player 1 Zone (Bottom)
                Expanded(child: _buildPlayerZone(1)),
              ],
            ),

            // Menu Overlay
            if (!_gameStarted && !_isCountingDown && !_isGameOver) _buildMenu(),

            // Countdown Overlay
            if (_isCountingDown) _buildCountdown(),

            // Game Over Overlay
            if (_isGameOver) _buildGameOver(),

            // Close button
            Positioned(
              top: 10,
              right: 10,
              child: IconButton(
                icon: const Icon(Icons.close, color: Colors.white54),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlayerZone(int player) {
    bool isP1 = player == 1;
    Color color = isP1 ? Colors.blue : Colors.red;
    int score = isP1 ? _player1Score : _player2Score;
    AnimationController pulseController = isP1
        ? _p1PulseController
        : _p2PulseController;

    return Listener(
      onPointerDown: (event) {
        // Prevent multi-touch on the same side
        bool hasPointerOnThisSide = _activePointers.values.contains(player);
        if (!hasPointerOnThisSide) {
          _activePointers[event.pointer] = player;
          _playerTap(player);
        }
      },
      onPointerUp: (event) {
        _activePointers.remove(event.pointer);
      },
      onPointerCancel: (event) {
        _activePointers.remove(event.pointer);
      },
      behavior: HitTestBehavior.opaque,
      child: ScaleTransition(
        scale: Tween<double>(begin: 1.0, end: 1.05).animate(
          CurvedAnimation(parent: pulseController, curve: Curves.easeOut),
        ),
        child: Container(
          width: double.infinity,
          height: double.infinity,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [color.withOpacity(0.8), color],
            ),
          ),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (_vsAI && !isP1)
                  const Icon(
                    Icons.smart_toy_rounded,
                    size: 40,
                    color: Colors.white70,
                  ),
                Text(
                  '$score',
                  style: const TextStyle(
                    fontSize: 80,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                    shadows: [
                      Shadow(
                        color: Colors.black26,
                        blurRadius: 10,
                        offset: Offset(2, 4),
                      ),
                    ],
                  ),
                ),
                if (_mode == TapDuelMode.scoreRace)
                  Text(
                    'GOAL: 30',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white.withOpacity(0.6),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDivider() {
    if (_mode == TapDuelMode.pushBattle && _gameStarted) {
      return Container(
        height: 40,
        width: double.infinity,
        color: Colors.white10,
        child: LayoutBuilder(
          builder: (context, constraints) {
            return Stack(
              children: [
                AnimatedPositioned(
                  duration: const Duration(milliseconds: 100),
                  left: _pushPosition * constraints.maxWidth - 20,
                  top: 0,
                  bottom: 0,
                  width: 40,
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.white.withOpacity(0.5),
                          blurRadius: 15,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      );
    }

    return Container(
      height: 4,
      width: double.infinity,
      color: Colors.white.withOpacity(0.3),
      child: _mode == TapDuelMode.timeAttack && _gameStarted
          ? LinearProgressIndicator(
              value: _secondsRemaining / 5,
              backgroundColor: Colors.transparent,
              valueColor: const AlwaysStoppedAnimation<Color>(Colors.yellow),
            )
          : null,
    );
  }

  Widget _buildMenu() {
    return Container(
      color: Colors.black87,
      width: double.infinity,
      child: Center(
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                'TAP DUEL',
                style: TextStyle(
                  fontSize: 48,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                  letterSpacing: 2,
                ),
              ),
              const SizedBox(height: 40),

              // Mode Selector
              const Text(
                'SELECT MODE',
                style: TextStyle(
                  color: Colors.white70,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _modeButton('RACE', TapDuelMode.scoreRace),
                  _modeButton('TIME', TapDuelMode.timeAttack),
                  _modeButton('PUSH', TapDuelMode.pushBattle),
                ],
              ),

              const SizedBox(height: 30),

              // Opponent Selector
              const Text(
                'OPPONENT',
                style: TextStyle(
                  color: Colors.white70,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _opponentButton('FRIEND', false),
                  _opponentButton('AI BOT', true),
                ],
              ),

              const SizedBox(height: 50),

              // Start Button
              GestureDetector(
                onTap: _startCountdown,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 60,
                    vertical: 20,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.greenAccent[400],
                    borderRadius: BorderRadius.circular(40),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.greenAccent.withOpacity(0.4),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: const Text(
                    'START BATTLE',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w900,
                      color: Colors.black,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _modeButton(String label, TapDuelMode mode) {
    bool isSelected = _mode == mode;
    return GestureDetector(
      onTap: () {
        _hapticService.selectionClick();
        setState(() => _mode = mode);
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : Colors.white10,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.black : Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _opponentButton(String label, bool vsAI) {
    bool isSelected = _vsAI == vsAI;
    return GestureDetector(
      onTap: () {
        _hapticService.selectionClick();
        setState(() => _vsAI = vsAI);
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 8),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : Colors.white10,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(
              vsAI ? Icons.smart_toy_rounded : Icons.people_rounded,
              color: isSelected ? Colors.black : Colors.white,
              size: 20,
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.black : Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCountdown() {
    return Container(
      color: Colors.black54,
      child: Center(
        child: Text(
          '$_countdownValue',
          style: const TextStyle(
            fontSize: 150,
            fontWeight: FontWeight.w900,
            color: Colors.white,
          ),
        ),
      ),
    );
  }

  Widget _buildGameOver() {
    return Container(
      color: Colors.black87,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'GAME OVER',
              style: TextStyle(
                fontSize: 32,
                color: Colors.white54,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              _winner,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 48,
                fontWeight: FontWeight.w900,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 50),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _actionButton(
                  'REMATCH',
                  _startCountdown,
                  Colors.greenAccent[400]!,
                ),
                const SizedBox(width: 20),
                _actionButton(
                  'MENU',
                  () => setState(() => _isGameOver = false),
                  Colors.white24,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _actionButton(String label, VoidCallback onTap, Color color) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(30),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w900,
            color: color == Colors.white24 ? Colors.white : Colors.black,
          ),
        ),
      ),
    );
  }
}
