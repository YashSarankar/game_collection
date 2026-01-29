import 'dart:math';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/models/game_model.dart';
import '../../core/providers/score_provider.dart';
import '../../core/services/haptic_service.dart';

class NumberPuzzleWidget extends StatefulWidget {
  final GameModel game;
  const NumberPuzzleWidget({super.key, required this.game});

  @override
  State<NumberPuzzleWidget> createState() => _NumberPuzzleWidgetState();
}

class _NumberPuzzleWidgetState extends State<NumberPuzzleWidget>
    with SingleTickerProviderStateMixin {
  static const int size = 4;
  late List<int> tiles;
  int moves = 0;
  bool isSolved = false;
  HapticService? _hapticService;
  late AnimationController _winController;

  // Countdown state
  int _countdown = 3;
  bool _isCountingDown = true;
  Timer? _countdownTimer;

  @override
  void initState() {
    super.initState();
    _initHaptic();
    _winController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    _startNewGame();
  }

  @override
  void dispose() {
    _winController.dispose();
    _countdownTimer?.cancel();
    super.dispose();
  }

  Future<void> _initHaptic() async {
    _hapticService = await HapticService.getInstance();
  }

  void _startNewGame() {
    // Generate solved state: [1, 2, ..., 15, 0]
    tiles = List.generate(size * size, (index) => (index + 1) % (size * size));
    _shuffle();
    moves = 0;
    isSolved = false;
    _winController.reset();
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
          }
        });
      }
    });
  }

  void _shuffle() {
    Random random = Random();
    int emptyIndex = tiles.indexOf(0);
    for (int i = 0; i < 200; i++) {
      List<int> validMoves = [];
      int r = emptyIndex ~/ size;
      int c = emptyIndex % size;

      if (r > 0) validMoves.add(emptyIndex - size);
      if (r < size - 1) validMoves.add(emptyIndex + size);
      if (c > 0) validMoves.add(emptyIndex - 1);
      if (c < size - 1) validMoves.add(emptyIndex + 1);

      int moveToIndex = validMoves[random.nextInt(validMoves.length)];
      tiles[emptyIndex] = tiles[moveToIndex];
      tiles[moveToIndex] = 0;
      emptyIndex = moveToIndex;
    }
    _checkSolved();
  }

  void _onTileTap(int index) {
    if (isSolved || _isCountingDown) return;

    int emptyIndex = tiles.indexOf(0);
    if (_isAdjacent(index, emptyIndex)) {
      _hapticService?.light();
      setState(() {
        tiles[emptyIndex] = tiles[index];
        tiles[index] = 0;
        moves++;
        _checkSolved();
      });

      if (isSolved) {
        _hapticService?.success();
        _winController.forward();
        context.read<ScoreProvider>().saveScore(widget.game.id, moves);
      }
    }
  }

  bool _isAdjacent(int i1, int i2) {
    int r1 = i1 ~/ size, c1 = i1 % size;
    int r2 = i2 ~/ size, c2 = i2 % size;
    return (r1 == r2 && (c1 - c2).abs() == 1) ||
        (c1 == c2 && (r1 - r2).abs() == 1);
  }

  void _checkSolved() {
    for (int i = 0; i < tiles.length - 1; i++) {
      if (tiles[i] != i + 1) {
        isSolved = false;
        return;
      }
    }
    isSolved = tiles.last == 0;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [widget.game.primaryColor.withOpacity(0.1), Colors.black],
        ),
      ),
      child: Stack(
        children: [
          Column(
            children: [
              _buildHeader(),
              Expanded(
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: AspectRatio(
                      aspectRatio: 1,
                      child: LayoutBuilder(
                        builder: (context, constraints) {
                          return _buildGrid(constraints);
                        },
                      ),
                    ),
                  ),
                ),
              ),
              _buildControls(),
              const SizedBox(height: 40),
            ],
          ),
          if (_isCountingDown) _buildCountdownOverlay(),
          if (isSolved) _buildVictoryOverlay(),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 60, 24, 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.game.title,
                style: const TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  letterSpacing: -0.5,
                ),
              ),
              const Text(
                'Slide tiles to solve',
                style: TextStyle(color: Colors.white60, fontSize: 16),
              ),
            ],
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [widget.game.primaryColor, widget.game.secondaryColor],
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: widget.game.primaryColor.withOpacity(0.3),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              children: [
                const Text(
                  'MOVES',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1,
                  ),
                ),
                Text(
                  '$moves',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGrid(BoxConstraints constraints) {
    double spacing = 8.0;
    double gridSize = constraints.maxWidth;
    double tileSize = (gridSize - (spacing * (size + 1))) / size;

    return Container(
      padding: EdgeInsets.all(spacing),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: Stack(
        children: [
          for (int i = 0; i < size * size; i++)
            Positioned(
              left: (i % size) * (tileSize + spacing),
              top: (i ~/ size) * (tileSize + spacing),
              child: Container(
                width: tileSize,
                height: tileSize,
                decoration: BoxDecoration(
                  color: Colors.black26,
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          for (int i = 0; i < tiles.length; i++)
            if (tiles[i] != 0)
              _buildAnimatedTile(tiles[i], i, tileSize, spacing),
        ],
      ),
    );
  }

  Widget _buildAnimatedTile(
    int value,
    int index,
    double tileSize,
    double spacing,
  ) {
    return AnimatedPositioned(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeOutBack,
      left: (index % size) * (tileSize + spacing),
      top: (index ~/ size) * (tileSize + spacing),
      child: GestureDetector(
        onTap: () => _onTileTap(index),
        child: Container(
          width: tileSize,
          height: tileSize,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [widget.game.primaryColor, widget.game.secondaryColor],
            ),
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.4),
                blurRadius: 8,
                offset: const Offset(2, 2),
              ),
            ],
          ),
          child: Center(
            child: Text(
              '$value',
              style: TextStyle(
                fontSize: tileSize * 0.4,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildControls() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _buildActionButton(
            onPressed: _startNewGame,
            icon: Icons.refresh_rounded,
            label: 'Restart',
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required VoidCallback onPressed,
    required IconData icon,
    required String label,
  }) {
    return ElevatedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, color: Colors.white),
      label: Text(
        label,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w600,
        ),
      ),
      style: ElevatedButton.styleFrom(
        backgroundColor: widget.game.primaryColor.withOpacity(0.2),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: widget.game.primaryColor.withOpacity(0.5)),
        ),
        elevation: 0,
      ),
    );
  }

  Widget _buildCountdownOverlay() {
    return Container(
      color: Colors.black.withOpacity(0.7),
      child: Center(
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 500),
          transitionBuilder: (Widget child, Animation<double> animation) {
            return ScaleTransition(scale: animation, child: child);
          },
          child: Text(
            '$_countdown',
            key: ValueKey<int>(_countdown),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 120,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildVictoryOverlay() {
    return AnimatedBuilder(
      animation: _winController,
      builder: (context, child) {
        return Opacity(opacity: _winController.value, child: child);
      },
      child: Container(
        color: Colors.black.withOpacity(0.8),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.emoji_events_rounded,
                color: Colors.amber,
                size: 80,
              ),
              const SizedBox(height: 16),
              const Text(
                'BRILLIANT!',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 2,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Solved in $moves moves',
                style: const TextStyle(color: Colors.white70, fontSize: 18),
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: _startNewGame,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: widget.game.primaryColor,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 32,
                    vertical: 16,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: const Text(
                  'PLAY AGAIN',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
