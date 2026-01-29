import 'dart:async';
import 'dart:math';
import 'dart:ui';
import 'package:flutter/material.dart';
import '../../core/models/game_model.dart';
import '../../core/services/haptic_service.dart';
import '../../ui/widgets/game_countdown.dart';
import '../../ui/widgets/game_over_dialog.dart';

enum DotsAndBoxesMode { pvp, vsAI }

enum Difficulty { easy, hard }

class DotsAndBoxesWidget extends StatefulWidget {
  final GameModel game;
  const DotsAndBoxesWidget({super.key, required this.game});

  @override
  State<DotsAndBoxesWidget> createState() => _DotsAndBoxesWidgetState();
}

class _DotsAndBoxesWidgetState extends State<DotsAndBoxesWidget>
    with TickerProviderStateMixin {
  // Game Setup
  int gridDots = 4;
  DotsAndBoxesMode mode = DotsAndBoxesMode.pvp;
  Difficulty difficulty = Difficulty.hard;
  bool gameStarted = false;
  bool showCountdown = false;

  // Game State
  late List<List<bool>> horizontalLines;
  late List<List<bool>> verticalLines;
  late List<List<int?>> boxOwners;

  int currentPlayer = 0;
  int player1Score = 0;
  int player2Score = 0;
  bool isGameOver = false;
  bool isAITurn = false;
  Move? lastMove;

  HapticService? _hapticService;

  // Animations
  late AnimationController _boardController;

  @override
  void initState() {
    super.initState();
    _initHaptic();
    _boardController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _boardController.dispose();
    super.dispose();
  }

  Future<void> _initHaptic() async {
    _hapticService = await HapticService.getInstance();
  }

  void _setupGame(int size, DotsAndBoxesMode m, Difficulty d) {
    setState(() {
      gridDots = size;
      mode = m;
      difficulty = d;
      gameStarted = true;
      showCountdown = true;
    });
  }

  void _initGameState() {
    horizontalLines = List.generate(
      gridDots,
      (_) => List.filled(gridDots - 1, false),
    );
    verticalLines = List.generate(
      gridDots - 1,
      (_) => List.filled(gridDots, false),
    );
    boxOwners = List.generate(
      gridDots - 1,
      (_) => List.filled(gridDots - 1, null),
    );

    currentPlayer = 0;
    player1Score = 0;
    player2Score = 0;
    isGameOver = false;
    isAITurn = false;
    gameStarted = true;
    showCountdown = false;
    lastMove = null;
    setState(() {});
  }

  void _handleLineTap(bool isHorizontal, int r, int c) {
    if (isGameOver || isAITurn) return;
    if (isHorizontal) {
      if (horizontalLines[r][c]) return;
    } else {
      if (verticalLines[r][c]) return;
    }

    _makeMove(isHorizontal, r, c);
  }

  void _makeMove(bool isHorizontal, int r, int c) {
    setState(() {
      lastMove = Move(isHorizontal, r, c);
      if (isHorizontal) {
        horizontalLines[r][c] = true;
      } else {
        verticalLines[r][c] = true;
      }
    });

    _hapticService?.light();

    bool boxCompleted = _checkBoxes(isHorizontal, r, c);

    if (boxCompleted) {
      _hapticService?.medium();
      if (_checkGameOver()) {
        _endGame();
      } else if (mode == DotsAndBoxesMode.vsAI && currentPlayer == 1) {
        Future.delayed(const Duration(milliseconds: 600), () {
          if (mounted) _aiMove();
        });
      }
    } else {
      setState(() {
        currentPlayer = 1 - currentPlayer;
      });

      if (mode == DotsAndBoxesMode.vsAI && currentPlayer == 1) {
        setState(() => isAITurn = true);
        Future.delayed(const Duration(milliseconds: 800), () {
          if (mounted) _aiMove();
        });
      }
    }
  }

  bool _checkBoxes(bool isHorizontal, int r, int c) {
    bool completed = false;
    List<Point<int>> boxesToCheck = [];

    if (isHorizontal) {
      if (r > 0) boxesToCheck.add(Point(r - 1, c));
      if (r < gridDots - 1) boxesToCheck.add(Point(r, c));
    } else {
      if (c > 0) boxesToCheck.add(Point(r, c - 1));
      if (c < gridDots - 1) boxesToCheck.add(Point(r, c));
    }

    for (var box in boxesToCheck) {
      if (boxOwners[box.x][box.y] == null && _isBoxComplete(box.x, box.y)) {
        setState(() {
          boxOwners[box.x][box.y] = currentPlayer;
          if (currentPlayer == 0) {
            player1Score++;
          } else {
            player2Score++;
          }
        });
        completed = true;
      }
    }

    return completed;
  }

  bool _isBoxComplete(int r, int c) {
    return horizontalLines[r][c] &&
        horizontalLines[r + 1][c] &&
        verticalLines[r][c] &&
        verticalLines[r][c + 1];
  }

  bool _checkGameOver() {
    for (int r = 0; r < gridDots - 1; r++) {
      for (int c = 0; c < gridDots - 1; c++) {
        if (boxOwners[r][c] == null) return false;
      }
    }
    return true;
  }

  void _endGame() {
    setState(() {
      isGameOver = true;
      isAITurn = false;
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => GameOverDialog(
          gameId: widget.game.id,
          score: player1Score,
          customMessage: player1Score > player2Score
              ? "Player 1 Wins!"
              : (player2Score > player1Score
                    ? (mode == DotsAndBoxesMode.vsAI
                          ? "AI Wins!"
                          : "Player 2 Wins!")
                    : "It's a Draw!"),
          onRestart: () {
            Navigator.pop(context);
            _initGameState();
          },
          onHome: () {
            Navigator.pop(context);
            Navigator.pop(context);
          },
        ),
      );
    });
  }

  void _aiMove() {
    if (isGameOver || !mounted) return;

    List<Move> winningMoves = [];
    List<Move> safeMoves = [];
    List<Move> allMoves = [];

    for (int r = 0; r < gridDots; r++) {
      for (int c = 0; c < gridDots - 1; c++) {
        if (!horizontalLines[r][c]) {
          Move m = Move(true, r, c);
          allMoves.add(m);
          if (_wouldCompleteBox(m)) {
            winningMoves.add(m);
          } else if (!_wouldCreateVulnerability(m)) {
            safeMoves.add(m);
          }
        }
      }
    }

    for (int r = 0; r < gridDots - 1; r++) {
      for (int c = 0; c < gridDots; c++) {
        if (!verticalLines[r][c]) {
          Move m = Move(false, r, c);
          allMoves.add(m);
          if (_wouldCompleteBox(m)) {
            winningMoves.add(m);
          } else if (!_wouldCreateVulnerability(m)) {
            safeMoves.add(m);
          }
        }
      }
    }

    Move selected;
    if (difficulty == Difficulty.hard) {
      if (winningMoves.isNotEmpty) {
        selected = winningMoves[Random().nextInt(winningMoves.length)];
      } else if (safeMoves.isNotEmpty) {
        selected = safeMoves[Random().nextInt(safeMoves.length)];
      } else {
        selected = allMoves[Random().nextInt(allMoves.length)];
      }
    } else {
      selected = allMoves[Random().nextInt(allMoves.length)];
    }

    setState(() {
      isAITurn = false;
    });
    _makeMove(selected.isHorizontal, selected.r, selected.c);
  }

  bool _wouldCompleteBox(Move m) {
    if (m.isHorizontal) {
      if (m.r > 0) {
        int count = 0;
        if (horizontalLines[m.r - 1][m.c]) count++;
        if (verticalLines[m.r - 1][m.c]) count++;
        if (verticalLines[m.r - 1][m.c + 1]) count++;
        if (count == 3) return true;
      }
      if (m.r < gridDots - 1) {
        int count = 0;
        if (horizontalLines[m.r + 1][m.c]) count++;
        if (verticalLines[m.r][m.c]) count++;
        if (verticalLines[m.r][m.c + 1]) count++;
        if (count == 3) return true;
      }
    } else {
      if (m.c > 0) {
        int count = 0;
        if (verticalLines[m.r][m.c - 1]) count++;
        if (horizontalLines[m.r][m.c - 1]) count++;
        if (horizontalLines[m.r + 1][m.c - 1]) count++;
        if (count == 3) return true;
      }
      if (m.c < gridDots - 1) {
        int count = 0;
        if (verticalLines[m.r][m.c + 1]) count++;
        if (horizontalLines[m.r][m.c]) count++;
        if (horizontalLines[m.r + 1][m.c]) count++;
        if (count == 3) return true;
      }
    }
    return false;
  }

  bool _wouldCreateVulnerability(Move m) {
    if (m.isHorizontal) {
      if (m.r > 0) {
        int count = 1;
        if (horizontalLines[m.r - 1][m.c]) count++;
        if (verticalLines[m.r - 1][m.c]) count++;
        if (verticalLines[m.r - 1][m.c + 1]) count++;
        if (count == 3) return true;
      }
      if (m.r < gridDots - 1) {
        int count = 1;
        if (horizontalLines[m.r + 1][m.c]) count++;
        if (verticalLines[m.r][m.c]) count++;
        if (verticalLines[m.r][m.c + 1]) count++;
        if (count == 3) return true;
      }
    } else {
      if (m.c > 0) {
        int count = 1;
        if (verticalLines[m.r][m.c - 1]) count++;
        if (horizontalLines[m.r][m.c - 1]) count++;
        if (horizontalLines[m.r + 1][m.c - 1]) count++;
        if (count == 3) return true;
      }
      if (m.c < gridDots - 1) {
        int count = 1;
        if (verticalLines[m.r][m.c + 1]) count++;
        if (horizontalLines[m.r][m.c]) count++;
        if (horizontalLines[m.r + 1][m.c]) count++;
        if (count == 3) return true;
      }
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    if (!gameStarted) return _buildSetup();
    if (showCountdown) {
      return Container(
        color: Colors.black.withOpacity(0.95),
        child: GameCountdown(onFinished: _initGameState),
      );
    }

    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark
          ? const Color(0xFF0F0F0F)
          : const Color(0xFFF9F9F9),
      body: Stack(
        children: [
          // Animated subtle background
          _buildBackground(isDark),

          SafeArea(
            child: Column(
              children: [
                _buildHeader(isDark),
                const SizedBox(height: 10),
                _buildScoreBoard(isDark),
                const Spacer(),
                _buildGameBoard(isDark),
                const Spacer(),
                _buildTurnIndicator(isDark),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBackground(bool isDark) {
    return AnimatedBuilder(
      animation: _boardController,
      builder: (context, child) {
        return Container(
          decoration: BoxDecoration(
            gradient: RadialGradient(
              center: Alignment(
                0.2 * sin(_boardController.value * 2 * pi),
                0.2 * cos(_boardController.value * 2 * pi),
              ),
              radius: 2.0,
              colors: isDark
                  ? [const Color(0xFF161625), const Color(0xFF0D0D0D)]
                  : [Colors.white, const Color(0xFFF0F0F0)],
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeader(bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          // Hide back button during active gameplay
          SizedBox(
            width: 24,
            child: !isGameOver
                ? const SizedBox.shrink()
                : GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Icon(
                      Icons.arrow_back_ios_new_rounded,
                      color: isDark ? Colors.white70 : Colors.black87,
                    ),
                  ),
          ),
          const Spacer(),
          Text(
            widget.game.title,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: isDark ? Colors.white : Colors.black87,
            ),
          ),
          const Spacer(),
          GestureDetector(
            onTap: () => setState(() => gameStarted = false),
            child: Icon(
              Icons.settings_suggest_rounded,
              color: isDark ? Colors.white70 : Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSetup() {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      body: Stack(
        children: [
          // Elegant Abstract Background for iPhone style
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: isDark
                    ? [const Color(0xFF1C1C1E), const Color(0xFF000000)]
                    : [const Color(0xFFF2F2F7), const Color(0xFFFFFFFF)],
              ),
            ),
          ),

          SafeArea(
            child: CustomScrollView(
              slivers: [
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(24, 60, 24, 40),
                    child: Column(
                      children: [
                        // iOS Style App Icon
                        Container(
                          width: 100,
                          height: 100,
                          decoration: BoxDecoration(
                            color: widget.game.primaryColor,
                            borderRadius: BorderRadius.circular(24),
                            boxShadow: [
                              BoxShadow(
                                color: widget.game.primaryColor.withOpacity(
                                  0.3,
                                ),
                                blurRadius: 20,
                                offset: const Offset(0, 10),
                              ),
                            ],
                          ),
                          child: Icon(
                            widget.game.icon,
                            size: 50,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 24),
                        Text(
                          widget.game.title,
                          style: TextStyle(
                            fontSize: 34,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -1,
                            color: isDark ? Colors.white : Colors.black,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          "Strategy meets simplicity",
                          style: TextStyle(
                            fontSize: 16,
                            color: isDark ? Colors.white54 : Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _sectionLabel("GAME MODES"),
                        _iosSettingsGroup([
                          _settingsRow(
                            "Offline PvP",
                            Icons.people_rounded,
                            mode == DotsAndBoxesMode.pvp,
                            () => setState(() => mode = DotsAndBoxesMode.pvp),
                          ),
                          _divider(),
                          _settingsRow(
                            "Player vs AI",
                            Icons.smart_toy_rounded,
                            mode == DotsAndBoxesMode.vsAI,
                            () => setState(() => mode = DotsAndBoxesMode.vsAI),
                          ),
                        ], isDark),

                        if (mode == DotsAndBoxesMode.vsAI) ...[
                          _sectionLabel("AI INTELLECT"),
                          _iosSettingsGroup([
                            _settingsRow(
                              "Novice",
                              Icons.bolt_outlined,
                              difficulty == Difficulty.easy,
                              () =>
                                  setState(() => difficulty = Difficulty.easy),
                            ),
                            _divider(),
                            _settingsRow(
                              "Expert",
                              Icons.psychology_rounded,
                              difficulty == Difficulty.hard,
                              () =>
                                  setState(() => difficulty = Difficulty.hard),
                            ),
                          ], isDark),
                        ],

                        _sectionLabel("BOARD SCALE"),
                        _iosSettingsGroup([
                          _settingsRow(
                            "4x4 Regular",
                            Icons.grid_view_rounded,
                            gridDots == 4,
                            () => setState(() => gridDots = 4),
                          ),
                          _divider(),
                          _settingsRow(
                            "6x6 Advanced",
                            Icons.apps_rounded,
                            gridDots == 6,
                            () => setState(() => gridDots = 6),
                          ),
                          _divider(),
                          _settingsRow(
                            "8x8 Intense",
                            Icons.grid_on_rounded,
                            gridDots == 8,
                            () => setState(() => gridDots = 8),
                          ),
                        ], isDark),

                        const SizedBox(height: 60),

                        // Large iPhone Style Blue Button
                        GestureDetector(
                          onTap: () => _setupGame(gridDots, mode, difficulty),
                          child: Container(
                            width: double.infinity,
                            height: 60,
                            decoration: BoxDecoration(
                              color: widget.game.primaryColor,
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                  color: widget.game.primaryColor.withOpacity(
                                    0.4,
                                  ),
                                  blurRadius: 15,
                                  offset: const Offset(0, 8),
                                ),
                              ],
                            ),
                            child: const Center(
                              child: Text(
                                "Start Match",
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 40),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionLabel(String text) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w500,
          color: Colors.grey[500],
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _iosSettingsGroup(List<Widget> children, bool isDark) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF2C2C2E) : Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(children: children),
    );
  }

  Widget _settingsRow(
    String title,
    IconData icon,
    bool isSelected,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 50,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        color: Colors.transparent,
        child: Row(
          children: [
            Icon(
              icon,
              size: 22,
              color: isSelected ? widget.game.primaryColor : Colors.grey,
            ),
            const SizedBox(width: 16),
            Text(
              title,
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w400,
                color: isSelected
                    ? widget.game.primaryColor
                    : (Theme.of(context).brightness == Brightness.dark
                          ? Colors.white
                          : Colors.black),
              ),
            ),
            const Spacer(),
            if (isSelected)
              Icon(
                Icons.check_circle_rounded,
                color: widget.game.primaryColor,
                size: 22,
              ),
          ],
        ),
      ),
    );
  }

  Widget _divider() {
    return Container(
      height: 0.5,
      margin: const EdgeInsets.only(left: 54),
      color: Colors.grey.withOpacity(0.3),
    );
  }

  Widget _buildScoreBoard(bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          _newScoreCard(
            "PLAYER 1",
            player1Score,
            Colors.redAccent,
            currentPlayer == 0,
            isDark,
          ),
          const SizedBox(width: 12),
          _newScoreCard(
            mode == DotsAndBoxesMode.vsAI ? "AI" : "PLAYER 2",
            player2Score,
            Colors.blueAccent,
            currentPlayer == 1,
            isDark,
          ),
        ],
      ),
    );
  }

  Widget _newScoreCard(
    String label,
    int score,
    Color color,
    bool isActive,
    bool isDark,
  ) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isDark ? Colors.white.withOpacity(0.05) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isActive ? color : Colors.transparent,
            width: 2,
          ),
          boxShadow: isActive
              ? [
                  BoxShadow(
                    color: color.withOpacity(0.2),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ]
              : [],
        ),
        child: Column(
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w800,
                color: isActive ? color : Colors.grey,
              ),
            ),
            Text(
              "$score",
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w900,
                color: isActive
                    ? color
                    : (isDark ? Colors.white38 : Colors.black38),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGameBoard(bool isDark) {
    return LayoutBuilder(
      builder: (context, constraints) {
        double availableSize = min(constraints.maxWidth, constraints.maxHeight);
        // Ensure vertical visibility by limiting board size
        double boardSize = availableSize * 0.9;
        double cellSize = boardSize / (gridDots - 1);
        double dotRadius = 5.0;

        return Center(
          child: Container(
            width: boardSize,
            height: boardSize,
            decoration: BoxDecoration(
              color: isDark
                  ? Colors.white.withOpacity(0.02)
                  : Colors.black.withOpacity(0.02),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Stack(
              clipBehavior: Clip
                  .none, // Allow glow and dots to bleed slightly for visibility
              children: [
                // Boxes
                for (int r = 0; r < gridDots - 1; r++)
                  for (int c = 0; c < gridDots - 1; c++)
                    Positioned(
                      left: c * cellSize + 1,
                      top: r * cellSize + 1,
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 500),
                        width: cellSize - 2,
                        height: cellSize - 2,
                        decoration: BoxDecoration(
                          color: boxOwners[r][c] == null
                              ? Colors.transparent
                              : (boxOwners[r][c] == 0
                                    ? Colors.redAccent.withOpacity(0.4)
                                    : Colors.blueAccent.withOpacity(0.4)),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: boxOwners[r][c] == null
                            ? null
                            : Center(
                                child: Text(
                                  boxOwners[r][c] == 0
                                      ? "1"
                                      : (mode == DotsAndBoxesMode.vsAI
                                            ? "A"
                                            : "2"),
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w900,
                                    fontSize: cellSize * 0.3,
                                  ),
                                ),
                              ),
                      ),
                    ),

                // Lines
                for (int r = 0; r < gridDots; r++)
                  for (int c = 0; c < gridDots - 1; c++)
                    _buildLine(true, r, c, cellSize, dotRadius, isDark),

                for (int r = 0; r < gridDots - 1; r++)
                  for (int c = 0; c < gridDots; c++)
                    _buildLine(false, r, c, cellSize, dotRadius, isDark),

                // Dots (Drawn last to be on top)
                for (int r = 0; r < gridDots; r++)
                  for (int c = 0; c < gridDots; c++)
                    Positioned(
                      left: c * cellSize - dotRadius,
                      top: r * cellSize - dotRadius,
                      child: Container(
                        width: dotRadius * 2,
                        height: dotRadius * 2,
                        decoration: BoxDecoration(
                          color: isDark ? Colors.white : Colors.black87,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: isDark ? Colors.white30 : Colors.black26,
                              blurRadius: 4,
                            ),
                          ],
                        ),
                      ),
                    ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildLine(
    bool isHorizontal,
    int r,
    int c,
    double cellSize,
    double dotRadius,
    bool isDark,
  ) {
    bool isDrawn = isHorizontal ? horizontalLines[r][c] : verticalLines[r][c];
    bool isLast =
        lastMove != null &&
        lastMove!.isHorizontal == isHorizontal &&
        lastMove!.r == r &&
        lastMove!.c == c;

    return Positioned(
      left: isHorizontal ? c * cellSize + dotRadius : c * cellSize - 10,
      top: isHorizontal ? r * cellSize - 10 : r * cellSize + dotRadius,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => _handleLineTap(isHorizontal, r, c),
        child: Container(
          width: isHorizontal ? cellSize - dotRadius * 2 : 20,
          height: isHorizontal ? 20 : cellSize - dotRadius * 2,
          alignment: Alignment.center,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            width: isHorizontal ? double.infinity : 3,
            height: isHorizontal ? 3 : double.infinity,
            decoration: BoxDecoration(
              color: isDrawn
                  ? (isLast
                        ? Colors.greenAccent
                        : (isDark ? Colors.white70 : Colors.black54))
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(2),
              boxShadow: (isDrawn && isLast)
                  ? [
                      BoxShadow(
                        color: Colors.greenAccent.withOpacity(0.8),
                        blurRadius: 10,
                      ),
                    ]
                  : [],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTurnIndicator(bool isDark) {
    if (isGameOver) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.grey.withOpacity(0.1),
          borderRadius: BorderRadius.circular(100),
        ),
        child: const Text(
          "MATCH ENDED",
          style: TextStyle(fontWeight: FontWeight.w800, letterSpacing: 1),
        ),
      );
    }

    Color turnColor = (currentPlayer == 0
        ? Colors.redAccent
        : Colors.blueAccent);
    String name = (currentPlayer == 0
        ? "PLAYER 1"
        : (mode == DotsAndBoxesMode.vsAI ? "AI SYSTEM" : "PLAYER 2"));

    return AnimatedScale(
      scale: currentPlayer == 0 ? 1.0 : 1.0,
      duration: const Duration(milliseconds: 300),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
        decoration: BoxDecoration(
          color: turnColor.withOpacity(0.1),
          borderRadius: BorderRadius.circular(100),
          border: Border.all(color: turnColor.withOpacity(0.3), width: 1),
        ),
        child: Text(
          "$name'S TURN",
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w800,
            color: turnColor,
            letterSpacing: 1,
          ),
        ),
      ),
    );
  }
}

class Move {
  final bool isHorizontal;
  final int r;
  final int c;
  Move(this.isHorizontal, this.r, this.c);
}
