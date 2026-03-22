import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/models/game_model.dart';
import '../../core/providers/score_provider.dart';
import '../../core/services/haptic_service.dart';
import '../../core/services/sound_service.dart';
import 'game_2048_engine.dart';

class Game2048Widget extends StatefulWidget {
  final GameModel game;
  const Game2048Widget({super.key, required this.game});

  @override
  State<Game2048Widget> createState() => _Game2048WidgetState();
}

class _Game2048WidgetState extends State<Game2048Widget>
    with SingleTickerProviderStateMixin {
  late Game2048Engine engine;
  bool isGameOver = false;
  bool isGameWon = false;
  HapticService? _hapticService;
  SoundService? _soundService;

  // Timer state
  Timer? _timer;
  int _secondsElapsed = 0;
  bool _gameStarted = false;

  // Countdown state
  int _countdown = 3;
  bool _isCountingDown = true;
  Timer? _countdownTimer;

  @override
  void initState() {
    super.initState();
    _initServices();
    _startNewGame();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _countdownTimer?.cancel();
    super.dispose();
  }

  Future<void> _initServices() async {
    _hapticService = await HapticService.getInstance();
    _soundService = await SoundService.getInstance();
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      if (!isGameOver) {
        setState(() {
          _secondsElapsed++;
        });
      } else {
        timer.cancel();
      }
    });
  }

  void _startNewGame() {
    engine = Game2048Engine(size: 4);
    _secondsElapsed = 0;
    isGameOver = false;
    isGameWon = false;
    _gameStarted = false;
    _timer?.cancel();
    _startCountdown();
    setState(() {});
  }

  void _startCountdown() {
    _isCountingDown = true;
    _countdown = 3;
    _countdownTimer?.cancel();
    _soundService?.playGameStart();
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          if (_countdown > 1) {
            _countdown--;
            _hapticService?.light();
          } else {
            _isCountingDown = false;
            _hapticService?.heavy();
            timer.cancel();
          }
        });
      }
    });
  }

  void _move(Direction direction) {
    if (isGameOver || _isCountingDown) return;

    if (!_gameStarted) {
      _gameStarted = true;
      _startTimer();
    }

    int oldScore = engine.score;
    bool moved = engine.makeMove(direction);

    if (moved) {
      _hapticService?.light();
      _soundService?.playMoveSound('sounds/pop.mp3');
      
      int moveScore = engine.score - oldScore;
      
      if (engine.hasWon() && !isGameWon) {
        isGameWon = true;
        _soundService?.playSuccess();
        _showWinDialog();
      }

      if (!engine.canMove()) {
        isGameOver = true;
        _timer?.cancel();
        _hapticService?.heavy();
        _soundService?.playGameOver();
      }

      if (moveScore > 0) {
        context.read<ScoreProvider>().saveScore(widget.game.id, engine.score);
      }

      setState(() {});
    }
  }

  void _showWinDialog() {
    _hapticService?.success();
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white.withOpacity(0.9),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          '🎉 YOU WIN! 🎉',
          textAlign: TextAlign.center,
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 24),
        ),
        content: const Text(
          'You reached the 2048 tile! Can you go even further?',
          textAlign: TextAlign.center,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'KEEP PLAYING',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _startNewGame();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: widget.game.primaryColor,
            ),
            child: const Text(
              'NEW GAME',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  String _formatTime(int seconds) {
    int mins = seconds ~/ 60;
    int secs = seconds % 60;
    return '${mins.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onVerticalDragEnd: (details) {
        if (details.primaryVelocity! < -300) _move(Direction.up);
        if (details.primaryVelocity! > 300) _move(Direction.down);
      },
      onHorizontalDragEnd: (details) {
        if (details.primaryVelocity! < -300) _move(Direction.left);
        if (details.primaryVelocity! > 300) _move(Direction.right);
      },
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF1B1B1B), // Dark background for premium feel
          gradient: RadialGradient(
            center: const Alignment(0, -0.5),
            radius: 1.2,
            colors: [
              widget.game.primaryColor.withOpacity(0.08),
              const Color(0xFF0F0F0F),
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              _buildHeader(),
              _buildStatsRow(),
              Expanded(
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: AspectRatio(
                      aspectRatio: 1,
                      child: Stack(
                        children: [
                          _buildGrid(),
                          if (_isCountingDown) _buildCountdownOverlay(),
                          if (isGameOver) _buildGameOverOverlay(),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              const Padding(
                padding: EdgeInsets.only(bottom: 24.0),
                child: Text(
                  'Swipe to move and merge tiles!',
                  style: TextStyle(
                    color: Colors.grey,
                    fontWeight: FontWeight.w500,
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
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.3),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Center(
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 500),
          transitionBuilder: (child, animation) =>
              ScaleTransition(scale: animation, child: child),
          child: Text(
            '$_countdown',
            key: ValueKey<int>(_countdown),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 80,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Hero(
                  tag: 'game_title_${widget.game.id}',
                  child: Text(
                    widget.game.title,
                    style: const TextStyle(
                      fontSize: 40,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                      letterSpacing: -1,
                    ),
                  ),
                ),
                Text(
                  'MERGE TO THE PEAK',
                  style: TextStyle(
                    color: widget.game.primaryColor.withOpacity(0.8),
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 2,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () {
              _hapticService?.medium();
              _startNewGame();
            },
            icon: const Icon(Icons.refresh_rounded, size: 28),
            color: Colors.white,
            style: IconButton.styleFrom(
              backgroundColor: Colors.white.withOpacity(0.05),
              padding: const EdgeInsets.all(14),
              side: BorderSide(color: Colors.white.withOpacity(0.1)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsRow() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        children: [
          Expanded(
            child: _buildStatBox('SCORE', '${engine.score}', widget.game.primaryColor),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: _buildStatBox(
              'TIME',
              _formatTime(_secondsElapsed),
              Colors.blueGrey,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatBox(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.03),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            label,
            style: TextStyle(
              color: Colors.white.withOpacity(0.4),
              fontSize: 10,
              fontWeight: FontWeight.w900,
              letterSpacing: 2,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.w900,
              fontFamily: 'monospace',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGrid() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.03),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: GridView.builder(
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 4,
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
        ),
        itemCount: 16,
        itemBuilder: (context, index) {
          int r = index ~/ 4;
          int c = index % 4;
          int val = engine.grid[r][c];
          return _buildTile(val);
        },
      ),
    );
  }

  Widget _buildTile(int val) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeOutCubic,
      decoration: BoxDecoration(
        color: val == 0 ? Colors.white.withOpacity(0.05) : _getTileColor(val),
        borderRadius: BorderRadius.circular(12),
        border: val > 0 
          ? Border.all(color: Colors.white.withOpacity(0.1), width: 1.5)
          : Border.all(color: Colors.white.withOpacity(0.05), width: 1),
        boxShadow: val > 0
            ? [
                BoxShadow(
                  color: _getTileColor(val).withOpacity(0.3),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ]
            : null,
      ),
      child: Center(
        child: val == 0
            ? null
            : Text(
                '$val',
                style: TextStyle(
                  fontSize: val < 100
                      ? 26
                      : val < 1000
                      ? 22
                      : 18,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                  shadows: [
                    Shadow(
                      color: Colors.black.withOpacity(0.2),
                      offset: const Offset(1, 1),
                      blurRadius: 2,
                    ),
                  ],
                ),
              ),
      ),
    );
  }

  Color _getTileColor(int val) {
    switch (val) {
      case 2: return const Color(0xFF3498DB);
      case 4: return const Color(0xFF2980B9);
      case 8: return const Color(0xFF2ECC71);
      case 16: return const Color(0xFF27AE60);
      case 32: return const Color(0xFFE67E22);
      case 64: return const Color(0xFFD35400);
      case 128: return const Color(0xFFE74C3C);
      case 256: return const Color(0xFFC0392B);
      case 512: return const Color(0xFF9B59B6);
      case 1024: return const Color(0xFF8E44AD);
      case 2048: return const Color(0xFFF1C40F);
      default: return val == 0 ? Colors.transparent : const Color(0xFF2C3E50);
    }
  }

  Widget _buildGameOverOverlay() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.6),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'GAME OVER',
              style: TextStyle(
                color: Colors.white,
                fontSize: 40,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Final Score: ${engine.score}',
              style: const TextStyle(color: Colors.white70, fontSize: 18),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _startNewGame,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 16,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
              ),
              child: const Text(
                'TRY AGAIN',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
