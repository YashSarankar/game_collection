import 'dart:math';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/models/game_model.dart';
import '../../core/providers/score_provider.dart';
import '../../core/services/haptic_service.dart';
import '../../core/services/sound_service.dart';

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
  SoundService? _soundService;
  late AnimationController _winController;

  // Countdown state
  int _countdown = 3;
  bool _isCountingDown = true;
  Timer? _countdownTimer;

  @override
  void initState() {
    super.initState();
    _initServices();
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

  Future<void> _initServices() async {
    _hapticService = await HapticService.getInstance();
    _soundService = await SoundService.getInstance();
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
      _soundService?.playMoveSound('sounds/pop.mp3');
      setState(() {
        tiles[emptyIndex] = tiles[index];
        tiles[index] = 0;
        moves++;
        _checkSolved();
      });

      if (isSolved) {
        _hapticService?.success();
        _soundService?.playSuccess();
        _winController.forward();
        context.read<ScoreProvider>().saveScore(widget.game.id, moves);
      }
    } else {
      _hapticService?.error();
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
    isSolved =
        true; // The last tile is implicitly zero if all others are correct
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
      padding: const EdgeInsets.fromLTRB(24, 60, 24, 32),
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
                      fontSize: 34,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                      letterSpacing: -1,
                    ),
                  ),
                ),
                Container(
                  margin: const EdgeInsets.only(top: 4),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: widget.game.primaryColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: widget.game.primaryColor.withOpacity(0.2)),
                        ),
                        child: const Text(
                          'BRAIN GYM CHALLENGE',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.5,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.05),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Row(
                          children: [
                            Icon(Icons.trending_up, color: Colors.white54, size: 12),
                            SizedBox(width: 4),
                            Text(
                              'ORDER: 1-15',
                              style: TextStyle(color: Colors.white54, fontSize: 8, fontWeight: FontWeight.w900),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          _buildScoreCard(),
        ],
      ),
    );
  }

  Widget _buildScoreCard() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            'MOVES',
            style: TextStyle(
              color: widget.game.primaryColor.withOpacity(0.8),
              fontSize: 10,
              fontWeight: FontWeight.w900,
              letterSpacing: 2,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '$moves',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 32,
              fontWeight: FontWeight.w900,
              fontFamily: 'monospace',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGrid(BoxConstraints constraints) {
    // Calculate sizing with safety margin to prevent edge clipping
    double spacing = 10.0;
    double totalSpacing = spacing * (size + 1);
    double gridSize = constraints.maxWidth;
    // We subtract an extra 4 pixels of "safe area" to prevent edge bleed
    double tileSize = (gridSize - totalSpacing - 4) / size;
    double offsetAdjustment = 2.0; // Half of our safe area to center the grid

    return Container(
      padding: EdgeInsets.all(spacing),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.02),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Stack(
        clipBehavior:
            Clip.none, // Allow elastic bounce to briefly go outside if needed
        children: [
          // Grid placeholders
          for (int i = 0; i < size * size; i++)
            Positioned(
              left: offsetAdjustment + (i % size) * (tileSize + spacing),
              top: offsetAdjustment + (i ~/ size) * (tileSize + spacing),
              child: Container(
                width: tileSize,
                height: tileSize,
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.white.withOpacity(0.03)),
                ),
                child: Center(
                  child: Text(
                    i == 15 ? "" : "${i + 1}",
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.03),
                      fontSize: tileSize * 0.35,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ),
            ),
          // Actual tiles
          for (int i = 0; i < tiles.length; i++)
            if (tiles[i] != 0)
              _buildAnimatedTile(
                tiles[i],
                i,
                tileSize,
                spacing,
                offsetAdjustment,
              )
            else if (isSolved)
              _buildSolvedEmptyTile(i, tileSize, spacing, offsetAdjustment),
        ],
      ),
    );
  }

  Widget _buildSolvedEmptyTile(
    int index,
    double tileSize,
    double spacing,
    double offset,
  ) {
    return Positioned(
      left: offset + (index % size) * (tileSize + spacing),
      top: offset + (index ~/ size) * (tileSize + spacing),
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0.0, end: 1.0),
        duration: const Duration(milliseconds: 800),
        builder: (context, value, child) {
          return Transform.scale(
            scale: value,
            child: Container(
              width: tileSize,
              height: tileSize,
              decoration: BoxDecoration(
                color: widget.game.primaryColor.withOpacity(0.3 * value),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: widget.game.primaryColor.withOpacity(0.5 * value),
                ),
              ),
              child: Center(
                child: Icon(
                  Icons.star_rounded,
                  color: Colors.white.withOpacity(0.8 * value),
                  size: tileSize * 0.5,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildAnimatedTile(
    int value,
    int index,
    double tileSize,
    double spacing,
    double offset,
  ) {
    return AnimatedPositioned(
      duration: const Duration(milliseconds: 300),
      curve: Curves.elasticOut,
      left: offset + (index % size) * (tileSize + spacing),
      top: offset + (index ~/ size) * (tileSize + spacing),
      child: GestureDetector(
        onTap: () => _onTileTap(index),
        child: Container(
          width: tileSize,
          height: tileSize,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                widget.game.primaryColor.withOpacity(0.9),
                widget.game.secondaryColor,
              ],
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: widget.game.primaryColor.withOpacity(0.3),
                blurRadius: 12,
                offset: const Offset(4, 4),
              ),
              BoxShadow(
                color: Colors.white.withOpacity(0.1),
                blurRadius: 2,
                offset: const Offset(-2, -2),
              ),
            ],
          ),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white.withOpacity(0.2)),
            ),
            child: Center(
              child: FittedBox(
                fit: BoxFit.contain,
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Text(
                    '$value',
                    style: TextStyle(
                      fontSize: tileSize * 0.38,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                      shadows: [
                        Shadow(
                          color: Colors.black.withOpacity(0.3),
                          offset: const Offset(1, 1),
                          blurRadius: 4,
                        ),
                      ],
                    ),
                  ),
                ),
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
