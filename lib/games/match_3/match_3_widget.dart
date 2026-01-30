import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../core/models/game_model.dart';
import '../../core/services/haptic_service.dart';
import '../../core/services/sound_service.dart';

class Match3Widget extends StatefulWidget {
  final GameModel game;

  const Match3Widget({super.key, required this.game});

  @override
  State<Match3Widget> createState() => _Match3WidgetState();
}

class _Match3WidgetState extends State<Match3Widget>
    with TickerProviderStateMixin {
  static const int rows = 8;
  static const int cols = 8;
  static const int tileTypes = 6;

  late List<List<int>> _grid;
  int? _dragStartRow;
  int? _dragStartCol;

  int _score = 0;
  int _moves = 30;
  int _targetScore = 2000;
  int _level = 1;
  double _comboMultiplier = 1.0;

  bool _isProcessing = false;
  bool _isGameOver = false;
  bool _isLevelComplete = false;
  bool _isInitialized = false;
  bool _gameStarted = false;
  bool _isShuffling = false;

  late HapticService _hapticService;
  late SoundService _soundService;

  final List<List<Color>> _gemGradients = [
    [const Color(0xFFFF5252), const Color(0xFFD32F2F)], // Red
    [const Color(0xFF448AFF), const Color(0xFF1976D2)], // Blue
    [const Color(0xFF69F0AE), const Color(0xFF388E3C)], // Green
    [const Color(0xFFFFE57F), const Color(0xFFFBC02D)], // Yellow
    [const Color(0xFFE040FB), const Color(0xFF7B1FA2)], // Purple
    [const Color(0xFFFFAB40), const Color(0xFFE65100)], // Orange
  ];

  final List<IconData> _tileIcons = [
    Icons.favorite_rounded,
    Icons.star_rounded,
    Icons.diamond_rounded,
    Icons.brightness_7_rounded,
    Icons.bolt_rounded,
    Icons.auto_awesome_rounded,
  ];

  @override
  void initState() {
    super.initState();
    _initializeServices();
  }

  Future<void> _initializeServices() async {
    _hapticService = await HapticService.getInstance();
    _soundService = await SoundService.getInstance();
    _initGrid();
    if (mounted) {
      setState(() {
        _isInitialized = true;
      });
    }
  }

  void _initGrid() {
    _grid = List.generate(rows, (r) => List.generate(cols, (c) => -1));
    do {
      for (int r = 0; r < rows; r++) {
        for (int c = 0; c < cols; c++) {
          int type;
          do {
            type = math.Random().nextInt(tileTypes);
          } while (_isInstantMatch(r, c, type));
          _grid[r][c] = type;
        }
      }
    } while (!_hasPossibleMoves());
  }

  bool _isInstantMatch(int row, int col, int type) {
    if (row >= 2 && _grid[row - 1][col] == type && _grid[row - 2][col] == type)
      return true;
    if (col >= 2 && _grid[row][col - 1] == type && _grid[row][col - 2] == type)
      return true;
    return false;
  }

  void _onPanStart(DragStartDetails details, double tileSize) {
    if (_isProcessing || _isGameOver || _isLevelComplete) return;

    final int col = (details.localPosition.dx / tileSize).floor();
    final int row = (details.localPosition.dy / tileSize).floor();

    if (row >= 0 && row < rows && col >= 0 && col < cols) {
      _dragStartRow = row;
      _dragStartCol = col;
    }
  }

  void _onPanUpdate(DragUpdateDetails details, double tileSize) {
    if (_dragStartRow == null || _dragStartCol == null || _isProcessing) return;

    final double dx =
        details.localPosition.dx - (_dragStartCol! * tileSize + tileSize / 2);
    final double dy =
        details.localPosition.dy - (_dragStartRow! * tileSize + tileSize / 2);

    const double swipeThreshold = 0.4; // 40% of tile size
    final double threshold = tileSize * swipeThreshold;

    int targetRow = _dragStartRow!;
    int targetCol = _dragStartCol!;

    if (dx.abs() > dy.abs()) {
      if (dx.abs() > threshold) {
        targetCol = _dragStartCol! + (dx > 0 ? 1 : -1);
      }
    } else {
      if (dy.abs() > threshold) {
        targetRow = _dragStartRow! + (dy > 0 ? 1 : -1);
      }
    }

    if (targetRow != _dragStartRow || targetCol != _dragStartCol) {
      if (targetRow >= 0 &&
          targetRow < rows &&
          targetCol >= 0 &&
          targetCol < cols) {
        _swapTiles(_dragStartRow!, _dragStartCol!, targetRow, targetCol);
        _dragStartRow = null;
        _dragStartCol = null;
      }
    }
  }

  Future<void> _swapTiles(int r1, int c1, int r2, int c2) async {
    if (!_gameStarted) {
      setState(() => _gameStarted = true);
    }

    setState(() {
      _isProcessing = true;
    });

    // Swap items in grid
    int temp = _grid[r1][c1];
    _grid[r1][c1] = _grid[r2][c2];
    _grid[r2][c2] = temp;

    if (_hasMatches()) {
      _moves--;
      _comboMultiplier = 1.0;
      await _processMatches();
    } else {
      // Swap back if no match
      await Future.delayed(const Duration(milliseconds: 300));
      setState(() {
        int tempBack = _grid[r1][c1];
        _grid[r1][c1] = _grid[r2][c2];
        _grid[r2][c2] = tempBack;
      });
      _hapticService.error();
    }

    setState(() {
      _isProcessing = false;
      _checkGameState();
    });

    // After movement, check if the board is deadlocked
    if (!_isGameOver && !_isLevelComplete && !_hasPossibleMoves()) {
      _shuffleBoard();
    }
  }

  bool _hasPossibleMoves() {
    for (int r = 0; r < rows; r++) {
      for (int c = 0; c < cols; c++) {
        // Try horizontal swap
        if (c < cols - 1) {
          _swapInGrid(r, c, r, c + 1);
          if (_hasMatches()) {
            _swapInGrid(r, c, r, c + 1); // swap back
            return true;
          }
          _swapInGrid(r, c, r, c + 1); // swap back
        }
        // Try vertical swap
        if (r < rows - 1) {
          _swapInGrid(r, c, r + 1, c);
          if (_hasMatches()) {
            _swapInGrid(r, c, r + 1, c); // swap back
            return true;
          }
          _swapInGrid(r, c, r + 1, c); // swap back
        }
      }
    }
    return false;
  }

  void _swapInGrid(int r1, int c1, int r2, int c2) {
    int temp = _grid[r1][c1];
    _grid[r1][c1] = _grid[r2][c2];
    _grid[r2][c2] = temp;
  }

  Future<void> _shuffleBoard() async {
    setState(() {
      _isProcessing = true;
      _isShuffling = true;
    });
    await Future.delayed(const Duration(seconds: 1));

    _hapticService.medium();

    // Simple shuffle: just randomize until moves exist
    do {
      for (int r = 0; r < rows; r++) {
        for (int c = 0; c < cols; c++) {
          int type;
          do {
            type = math.Random().nextInt(tileTypes);
          } while (_isInstantMatch(r, c, type));
          _grid[r][c] = type;
        }
      }
    } while (!_hasPossibleMoves());

    setState(() {
      _isProcessing = false;
      _isShuffling = false;
    });
  }

  bool _hasMatches() {
    for (int r = 0; r < rows; r++) {
      for (int c = 0; c < cols; c++) {
        if (_grid[r][c] == -1) continue;
        if (c <= cols - 3 &&
            _grid[r][c] == _grid[r][c + 1] &&
            _grid[r][c] == _grid[r][c + 2])
          return true;
        if (r <= rows - 3 &&
            _grid[r][c] == _grid[r + 1][c] &&
            _grid[r][c] == _grid[r + 2][c])
          return true;
      }
    }
    return false;
  }

  Future<void> _processMatches() async {
    while (_hasMatches()) {
      List<List<bool>> matched = List.generate(
        rows,
        (r) => List.generate(cols, (c) => false),
      );

      for (int r = 0; r < rows; r++) {
        for (int c = 0; c <= cols - 3; c++) {
          int type = _grid[r][c];
          if (type != -1 &&
              _grid[r][c + 1] == type &&
              _grid[r][c + 2] == type) {
            matched[r][c] = true;
            matched[r][c + 1] = true;
            matched[r][c + 2] = true;
          }
        }
      }

      for (int r = 0; r <= rows - 3; r++) {
        for (int c = 0; c < cols; c++) {
          int type = _grid[r][c];
          if (type != -1 &&
              _grid[r + 1][c] == type &&
              _grid[r + 2][c] == type) {
            matched[r][c] = true;
            matched[r + 1][c] = true;
            matched[r + 2][c] = true;
          }
        }
      }

      int count = 0;
      for (int r = 0; r < rows; r++) {
        for (int c = 0; c < cols; c++) {
          if (matched[r][c]) {
            _grid[r][c] = -1;
            count++;
          }
        }
      }

      setState(() {
        _score += (count * 10 * _level * _comboMultiplier).round();
        _comboMultiplier += 0.5;
      });
      _hapticService.medium();
      _soundService.playPoint();
      await Future.delayed(const Duration(milliseconds: 400));

      await _fallTiles();
      await Future.delayed(const Duration(milliseconds: 400));
    }
  }

  Future<void> _fallTiles() async {
    setState(() {
      for (int c = 0; c < cols; c++) {
        int emptySpot = rows - 1;
        for (int r = rows - 1; r >= 0; r--) {
          if (_grid[r][c] != -1) {
            if (emptySpot != r) {
              _grid[emptySpot][c] = _grid[r][c];
              _grid[r][c] = -1;
            }
            emptySpot--;
          }
        }
        for (int r = emptySpot; r >= 0; r--) {
          _grid[r][c] = math.Random().nextInt(tileTypes);
        }
      }
    });
  }

  void _checkGameState() {
    if (_score >= _targetScore) {
      _isLevelComplete = true;
      _soundService.playSuccess();
    } else if (_moves <= 0) {
      _isGameOver = true;
      _soundService.playGameOver();
    }
  }

  void _resetGame() {
    setState(() {
      _score = 0;
      _moves = 30;
      _level = 1;
      _targetScore = 2000;
      _isGameOver = false;
      _isLevelComplete = false;
      _gameStarted = false;
      _initGrid();
    });
  }

  void _nextLevel() {
    setState(() {
      _level++;
      _targetScore += 1000;
      _moves = 30;
      _isLevelComplete = false;
      _initGrid();
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!_isInitialized) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final brightness = Theme.of(context).brightness;
    final isDark = brightness == Brightness.dark;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isDark
                ? [const Color(0xFF1F1C2C), const Color(0xFF121212)]
                : [const Color(0xFFE0EAFC), const Color(0xFFCFDEF3)],
          ),
        ),
        child: Stack(
          children: [
            Column(
              children: [
                _buildTopBar(isDark),
                _buildHeader(isDark),
                Expanded(child: _buildGridInteraction(isDark)),
                _buildFooter(isDark),
              ],
            ),
            if (!_gameStarted && !_isGameOver && !_isLevelComplete)
              _buildMenu(isDark),
            if (_isGameOver) _buildGameOverOverlay(isDark),
            if (_isLevelComplete) _buildLevelCompleteOverlay(isDark),
            if (_isShuffling) _buildShuffleIndicator(),
            _buildBackArrow(isDark),
          ],
        ),
      ),
    );
  }

  Widget _buildShuffleIndicator() {
    return Center(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 20),
        decoration: BoxDecoration(
          color: Colors.black87,
          borderRadius: BorderRadius.circular(40),
          border: Border.all(color: Colors.pinkAccent.withOpacity(0.5)),
          boxShadow: [
            BoxShadow(
              color: Colors.pinkAccent.withOpacity(0.3),
              blurRadius: 20,
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.shuffle_rounded,
              color: Colors.pinkAccent,
              size: 40,
            ),
            const SizedBox(height: 10),
            const Text(
              "NO MOVES!",
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w900,
                fontSize: 18,
              ),
            ),
            Text(
              "SHUFFLING BOARD...",
              style: TextStyle(
                color: Colors.white.withOpacity(0.7),
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMenu(bool isDark) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            isDark
                ? Colors.black.withOpacity(0.8)
                : Colors.white.withOpacity(0.9),
            isDark ? Colors.black : Colors.white,
          ],
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: (isDark ? Colors.white : Colors.black).withOpacity(0.05),
              border: Border.all(
                color: (isDark ? Colors.white10 : Colors.black12),
              ),
            ),
            child: Icon(
              widget.game.icon,
              size: 80,
              color: widget.game.primaryColor,
            ),
          ),
          const SizedBox(height: 30),
          Text(
            widget.game.title.toUpperCase(),
            style: TextStyle(
              color: isDark ? Colors.white : Colors.black87,
              fontSize: 54,
              fontWeight: FontWeight.w900,
              letterSpacing: 8,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            "MATCH 3 TO CLEAR",
            style: TextStyle(
              color: (isDark ? Colors.white : Colors.black).withOpacity(0.5),
              fontSize: 16,
              fontWeight: FontWeight.bold,
              letterSpacing: 2,
            ),
          ),
          const SizedBox(height: 80),
          GestureDetector(
            onTap: () {
              _soundService.playGameStart();
              setState(() => _gameStarted = true);
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 70, vertical: 22),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    widget.game.primaryColor,
                    widget.game.secondaryColor,
                  ],
                ),
                borderRadius: BorderRadius.circular(40),
                boxShadow: [
                  BoxShadow(
                    color: widget.game.primaryColor.withOpacity(0.4),
                    blurRadius: 25,
                    offset: const Offset(0, 12),
                  ),
                ],
              ),
              child: const Text(
                "PLAY NOW",
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 2,
                  color: Colors.white,
                ),
              ),
            ),
          ),
          const SizedBox(height: 40),
          Text(
            "TARGET: $_targetScore POINTS",
            style: TextStyle(
              color: (isDark ? Colors.white : Colors.black).withOpacity(0.3),
              fontSize: 14,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.2,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBackArrow(bool isDark) {
    if (_gameStarted && !_isGameOver && !_isLevelComplete) {
      return const SizedBox.shrink();
    }

    return Positioned(
      top: 10,
      left: 10,
      child: SafeArea(
        child: IconButton(
          icon: Icon(
            Icons.arrow_back_ios_new,
            color: isDark ? Colors.white : Colors.black87,
          ),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
    );
  }

  Widget _buildTopBar(bool isDark) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            IconButton(
              icon: Icon(
                Icons.refresh,
                color: isDark ? Colors.white38 : Colors.black26,
              ),
              onPressed: _resetGame,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(
          color: (isDark ? Colors.white : Colors.black).withOpacity(0.05),
          borderRadius: BorderRadius.circular(25),
          border: Border.all(color: (isDark ? Colors.white10 : Colors.black12)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _infoCard("SCORE", "$_score", Colors.pinkAccent, isDark),
            _infoCard("MOVES", "$_moves", Colors.orangeAccent, isDark),
            _infoCard("TARGET", "$_targetScore", Colors.blueAccent, isDark),
          ],
        ),
      ),
    );
  }

  Widget _infoCard(String label, String value, Color color, bool isDark) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: TextStyle(
            color: (isDark ? Colors.white : Colors.black).withOpacity(0.4),
            fontSize: 10,
            fontWeight: FontWeight.w900,
            letterSpacing: 1.5,
          ),
        ),
        const SizedBox(height: 5),
        Text(
          value,
          style: TextStyle(
            color: color,
            fontSize: 22,
            fontWeight: FontWeight.w900,
            shadows: [
              Shadow(
                color: color.withOpacity(0.3),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildGridInteraction(bool isDark) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final double tileSize = (constraints.maxWidth - 40 - 24) / cols;
        return Container(
          margin: const EdgeInsets.all(20),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: (isDark ? Colors.white : Colors.black).withOpacity(0.05),
            borderRadius: BorderRadius.circular(30),
            border: Border.all(
              color: (isDark ? Colors.white10 : Colors.black12),
              width: 2,
            ),
          ),
          child: GestureDetector(
            onPanStart: (details) => _onPanStart(details, tileSize),
            onPanUpdate: (details) => _onPanUpdate(details, tileSize),
            child: GridView.builder(
              padding: EdgeInsets.zero,
              physics: const NeverScrollableScrollPhysics(),
              shrinkWrap: true,
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: cols,
                childAspectRatio: 1,
              ),
              itemCount: rows * cols,
              itemBuilder: (context, index) {
                int r = index ~/ cols;
                int c = index % cols;
                int type = _grid[r][c];

                return AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  transitionBuilder: (child, animation) =>
                      ScaleTransition(scale: animation, child: child),
                  child: type == -1
                      ? const SizedBox.shrink()
                      : _buildGem(type, false, tileSize),
                );
              },
            ),
          ),
        );
      },
    );
  }

  Widget _buildGem(int type, bool isSelected, double tileSize) {
    final colors = _gemGradients[type];
    return Container(
      key: ValueKey('gem_$type'),
      margin: const EdgeInsets.all(4),
      child: Stack(
        children: [
          // Main Body with 3D shadow
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: colors,
              ),
              borderRadius: BorderRadius.circular(tileSize * 0.3),
              boxShadow: [
                BoxShadow(
                  color: colors[1].withOpacity(0.6),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 2,
                  offset: const Offset(0, 1),
                ),
              ],
            ),
          ),
          // Top Gloss / Specular Highlight
          Positioned(
            top: 2,
            left: 2,
            right: 2,
            child: Container(
              height: tileSize * 0.3,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.vertical(
                  top: Radius.circular(tileSize * 0.3),
                ),
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.white.withOpacity(0.6),
                    Colors.white.withOpacity(0.0),
                  ],
                ),
              ),
            ),
          ),
          // Inner Shine
          Center(
            child: Icon(
              _tileIcons[type],
              color: Colors.white.withOpacity(0.95),
              size: tileSize * 0.55,
              shadows: [
                Shadow(
                  color: Colors.black26,
                  blurRadius: 4,
                  offset: const Offset(1, 1),
                ),
              ],
            ),
          ),
          // Bottom Highlight for depth
          Positioned(
            bottom: 4,
            left: 6,
            right: 6,
            child: Container(
              height: 4,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                boxShadow: [
                  BoxShadow(
                    color: Colors.white.withOpacity(0.2),
                    blurRadius: 4,
                    spreadRadius: 1,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFooter(bool isDark) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 50),
      child: Column(
        children: [
          if (_comboMultiplier > 1.0)
            Text(
              "COMBO x${_comboMultiplier.toStringAsFixed(1)}",
              style: const TextStyle(
                color: Colors.pinkAccent,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          const SizedBox(height: 10),
          Text(
            "LEVEL $_level",
            style: TextStyle(
              color: isDark ? Colors.white12 : Colors.black12,
              fontSize: 32,
              fontWeight: FontWeight.w900,
              letterSpacing: 8,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGameOverOverlay(bool isDark) {
    return Container(
      width: double.infinity,
      color: (isDark ? Colors.black : Colors.white).withOpacity(0.95),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.sentiment_very_dissatisfied_rounded,
            size: 80,
            color: Colors.redAccent,
          ),
          const SizedBox(height: 20),
          Text(
            "GAME OVER",
            style: TextStyle(
              color: Colors.redAccent,
              fontSize: 44,
              fontWeight: FontWeight.w900,
              letterSpacing: 2,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            "SCORE: $_score",
            style: TextStyle(
              color: isDark ? Colors.white : Colors.black87,
              fontSize: 32,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 60),
          _overlayButton(
            "TRY AGAIN",
            _resetGame,
            isDark ? Colors.white : Colors.black,
            isDark ? Colors.black : Colors.white,
          ),
        ],
      ),
    );
  }

  Widget _buildLevelCompleteOverlay(bool isDark) {
    return Container(
      width: double.infinity,
      color: (isDark ? Colors.black : Colors.white).withOpacity(0.95),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.stars_rounded, size: 100, color: Colors.amber),
          const SizedBox(height: 20),
          const Text(
            "AMAZING!",
            style: TextStyle(
              color: Colors.greenAccent,
              fontSize: 48,
              fontWeight: FontWeight.w900,
              letterSpacing: 4,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            "LEVEL $_level CLEAR",
            style: TextStyle(
              color: isDark ? Colors.white70 : Colors.black54,
              fontSize: 20,
            ),
          ),
          const SizedBox(height: 60),
          _overlayButton(
            "NEXT LEVEL",
            _nextLevel,
            Colors.greenAccent,
            Colors.black,
          ),
        ],
      ),
    );
  }

  Widget _overlayButton(
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
        padding: const EdgeInsets.symmetric(horizontal: 60, vertical: 22),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(40)),
        elevation: 10,
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontWeight: FontWeight.w900,
          fontSize: 22,
          letterSpacing: 1.5,
        ),
      ),
    );
  }
}
