import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/models/game_model.dart';
import '../../core/providers/score_provider.dart';
import '../../core/services/haptic_service.dart';

class Game2048Widget extends StatefulWidget {
  final GameModel game;
  const Game2048Widget({super.key, required this.game});

  @override
  State<Game2048Widget> createState() => _Game2048WidgetState();
}

class _Game2048WidgetState extends State<Game2048Widget>
    with SingleTickerProviderStateMixin {
  static const int size = 4;
  late List<List<int>> grid;
  int score = 0;
  bool isGameOver = false;
  bool isGameWon = false;
  HapticService? _hapticService;

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
    _initHaptic();
    _startNewGame();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _countdownTimer?.cancel();
    super.dispose();
  }

  Future<void> _initHaptic() async {
    _hapticService = await HapticService.getInstance();
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
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
    grid = List.generate(size, (_) => List.filled(size, 0));
    score = 0;
    _secondsElapsed = 0;
    isGameOver = false;
    isGameWon = false;
    _gameStarted = false;
    _timer?.cancel();
    _addNewTile();
    _addNewTile();
    _startCountdown();
    setState(() {});
  }

  void _startCountdown() {
    _isCountingDown = true;
    _countdown = 3;
    _countdownTimer?.cancel();
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
            // Actually starting the game timer only after the first move or here?
            // Usually game timer starts on first move.
            // The existing _move logic starts the timer.
          }
        });
      }
    });
  }

  void _addNewTile() {
    List<Point<int>> emptyCells = [];
    for (int r = 0; r < size; r++) {
      for (int c = 0; c < size; c++) {
        if (grid[r][c] == 0) {
          emptyCells.add(Point(r, c));
        }
      }
    }

    if (emptyCells.isNotEmpty) {
      final randomCell = emptyCells[Random().nextInt(emptyCells.length)];
      // 90% chance for 2, 10% for 4
      grid[randomCell.x][randomCell.y] = Random().nextDouble() < 0.9 ? 2 : 4;
    }
  }

  void _move(Direction direction) {
    if (isGameOver || _isCountingDown) return;

    if (!_gameStarted) {
      _gameStarted = true;
      _startTimer();
    }

    bool moved = false;
    int moveScore = 0;

    List<List<int>> newGrid = List.generate(size, (r) => List.from(grid[r]));

    if (direction == Direction.left || direction == Direction.right) {
      for (int r = 0; r < size; r++) {
        List<int> line = newGrid[r];
        if (direction == Direction.right) line = line.reversed.toList();

        var result = _processLine(line);
        List<int> processedLine = result.line;
        moveScore += result.score;

        if (direction == Direction.right) {
          processedLine = processedLine.reversed.toList();
        }

        for (int c = 0; c < size; c++) {
          if (newGrid[r][c] != processedLine[c]) moved = true;
          newGrid[r][c] = processedLine[c];
        }
      }
    } else {
      for (int c = 0; c < size; c++) {
        List<int> line = [];
        for (int r = 0; r < size; r++) line.add(newGrid[r][c]);

        if (direction == Direction.down) line = line.reversed.toList();

        var result = _processLine(line);
        List<int> processedLine = result.line;
        moveScore += result.score;

        if (direction == Direction.down) {
          processedLine = processedLine.reversed.toList();
        }

        for (int r = 0; r < size; r++) {
          if (newGrid[r][c] != processedLine[r]) moved = true;
          newGrid[r][c] = processedLine[r];
        }
      }
    }

    if (moved) {
      _hapticService?.light();
      grid = newGrid;
      score += moveScore;
      _addNewTile();
      _checkGameOver();

      if (moveScore > 0) {
        context.read<ScoreProvider>().saveScore(widget.game.id, score);
      }

      setState(() {});
    }
  }

  LineResult _processLine(List<int> line) {
    // 1. Compression: Remove zeros
    List<int> filtered = line.where((x) => x != 0).toList();

    // 2. Merge adjacent tiles
    int lineScore = 0;
    List<int> merged = [];
    for (int i = 0; i < filtered.length; i++) {
      if (i + 1 < filtered.length && filtered[i] == filtered[i + 1]) {
        int newVal = filtered[i] * 2;
        merged.add(newVal);
        lineScore += newVal;
        if (newVal == 2048 && !isGameWon) {
          isGameWon = true;
          _showWinDialog();
        }
        i++;
      } else {
        merged.add(filtered[i]);
      }
    }

    // 3. Second Compression: Fill with zeros
    while (merged.length < size) {
      merged.add(0);
    }

    return LineResult(merged, lineScore);
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

  void _checkGameOver() {
    // Check for empty cells
    for (int r = 0; r < size; r++) {
      for (int c = 0; c < size; c++) {
        if (grid[r][c] == 0) return;
      }
    }

    // Check for possible merges
    for (int r = 0; r < size; r++) {
      for (int c = 0; c < size; c++) {
        int val = grid[r][c];
        if (r + 1 < size && grid[r + 1][c] == val) return;
        if (c + 1 < size && grid[r][c + 1] == val) return;
      }
    }

    isGameOver = true;
    _timer?.cancel();
    _hapticService?.heavy();
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
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [widget.game.primaryColor.withOpacity(0.1), Colors.white],
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
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFEDC22E),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFEDC22E).withOpacity(0.3),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: const Text(
              '2048',
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.w900,
                color: Colors.white,
              ),
            ),
          ),
          IconButton(
            onPressed: _startNewGame,
            icon: const Icon(Icons.refresh_rounded, size: 32),
            color: widget.game.primaryColor,
            style: IconButton.styleFrom(
              backgroundColor: widget.game.primaryColor.withOpacity(0.1),
              padding: const EdgeInsets.all(12),
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
            child: _buildStatBox('SCORE', '$score', widget.game.primaryColor),
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
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.2), width: 1),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.05),
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
              color: Colors.grey[600],
              fontSize: 10,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 20,
              fontWeight: FontWeight.w900,
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
        color: const Color(0xFFBBADA0),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: GridView.builder(
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: size,
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
        ),
        itemCount: size * size,
        itemBuilder: (context, index) {
          int r = index ~/ size;
          int c = index % size;
          int val = grid[r][c];
          return _buildTile(val);
        },
      ),
    );
  }

  Widget _buildTile(int val) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      curve: Curves.easeInOut,
      decoration: BoxDecoration(
        color: _getTileColor(val),
        borderRadius: BorderRadius.circular(8),
        boxShadow: val > 0
            ? [
                BoxShadow(
                  color: _getTileColor(val).withOpacity(0.3),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
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
                      ? 28
                      : val < 1000
                      ? 24
                      : 20,
                  fontWeight: FontWeight.w900,
                  color: val <= 4 ? const Color(0xFF776E65) : Colors.white,
                ),
              ),
      ),
    );
  }

  Color _getTileColor(int val) {
    switch (val) {
      case 2:
        return const Color(0xFFEEE4DA);
      case 4:
        return const Color(0xFFEDE0C8);
      case 8:
        return const Color(0xFFF2B179);
      case 16:
        return const Color(0xFFF59563);
      case 32:
        return const Color(0xFFF67C5F);
      case 64:
        return const Color(0xFFF65E3B);
      case 128:
        return const Color(0xFFEDCF72);
      case 256:
        return const Color(0xFFEDCC61);
      case 512:
        return const Color(0xFFEDC850);
      case 1024:
        return const Color(0xFFEDC53F);
      case 2048:
        return const Color(0xFFEDC22E);
      default:
        return val == 0 ? const Color(0xFFCDC1B4) : const Color(0xFF3C3A32);
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
              'Final Score: $score',
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

enum Direction { up, down, left, right }

class LineResult {
  final List<int> line;
  final int score;
  LineResult(this.line, this.score);
}
