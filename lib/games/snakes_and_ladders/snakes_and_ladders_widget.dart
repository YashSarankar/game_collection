import 'dart:math';
import 'package:flutter/material.dart';
import '../../core/models/game_model.dart';
import '../../core/services/haptic_service.dart';
import '../../core/services/sound_service.dart';
import 'snakes_and_ladders_logic.dart';
import '../../ui/widgets/game_countdown.dart';
import '../../ui/widgets/game_over_dialog.dart';

enum GameState { selection, countdown, playing, won }

class SnakesAndLaddersWidget extends StatefulWidget {
  final GameModel game;
  const SnakesAndLaddersWidget({super.key, required this.game});

  @override
  State<SnakesAndLaddersWidget> createState() => _SnakesAndLaddersWidgetState();
}

class _SnakesAndLaddersWidgetState extends State<SnakesAndLaddersWidget>
    with TickerProviderStateMixin {
  late SnakesAndLaddersLogic logic;
  GameState gameState = GameState.selection;
  int playerCount = 2;
  GameDifficulty selectedDifficulty = GameDifficulty.medium;
  bool isRolling = false;
  int diceValue = 1;
  bool canRoll = true;
  HapticService? _hapticService;
  SoundService? _soundService;
  late AnimationController _diceController;

  @override
  void initState() {
    super.initState();
    _initServices();
    _diceController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
  }

  Future<void> _initServices() async {
    _hapticService = await HapticService.getInstance();
    _soundService = await SoundService.getInstance();
  }

  @override
  void dispose() {
    _diceController.dispose();
    super.dispose();
  }

  void _startGame() {
    setState(() {
      gameState = GameState.countdown;
    });
  }

  void _initGame() {
    final colors = [
      const Color(0xFFFF3B30),
      const Color(0xFF007AFF),
      const Color(0xFF34C759),
      const Color(0xFFFF9500),
    ];
    final names = ["Red", "Blue", "Green", "Orange"];
    final players = List.generate(
      playerCount,
      (i) => SLPlayer(id: i, name: names[i], color: colors[i]),
    );
    logic = SnakesAndLaddersLogic(
      players: players,
      difficulty: selectedDifficulty,
    );
    setState(() {
      gameState = GameState.playing;
    });
  }

  void _rollDice() async {
    if (!canRoll || isRolling || gameState != GameState.playing) return;

    setState(() {
      isRolling = true;
      canRoll = false;
    });

    _hapticService?.light();

    _diceController.repeat();

    for (int i = 0; i < 8; i++) {
      await Future.delayed(const Duration(milliseconds: 100));
      if (mounted) {
        setState(() {
          diceValue = Random().nextInt(6) + 1;
        });
      }
    }

    int finalRoll = logic.rollDice();
    _diceController.stop();

    if (mounted) {
      setState(() {
        diceValue = finalRoll;
        isRolling = false;
      });
    } else {
      return;
    }

    _hapticService?.medium();
    _movePlayer();
  }

  void _movePlayer() async {
    final player = logic.currentPlayer;
    int roll = diceValue;
    int oldPos = player.position;
    int targetPos = logic.calculateNewPosition(oldPos, roll);

    if (targetPos == oldPos) {
      await Future.delayed(const Duration(milliseconds: 500));
      if (mounted) _nextTurn();
      return;
    }

    // Play move sound at the start of movement
    _soundService?.playMoveSound('sounds/move_piece.mp3');

    for (int i = oldPos + 1; i <= targetPos; i++) {
      await Future.delayed(const Duration(milliseconds: 300));
      if (!mounted) return;
      setState(() {
        player.position = i;
      });
      _hapticService?.light();
    }

    if (player.position == 100) {
      setState(() {
        player.isWinner = true;
        gameState = GameState.won;
      });
      _hapticService?.heavy();
      _showGameOver();
      return;
    }

    int? jumpPos = logic.checkJump(player.position);
    if (jumpPos != null) {
      await Future.delayed(const Duration(milliseconds: 500));
      if (!mounted) return;
      setState(() {
        player.position = jumpPos;
      });
      _hapticService?.medium();

      if (player.position == 100) {
        setState(() {
          player.isWinner = true;
          gameState = GameState.won;
        });
        _hapticService?.heavy();
        _showGameOver();
        return;
      }
    }

    if (diceValue == 6) {
      setState(() => canRoll = true);
    } else {
      _nextTurn();
    }
  }

  void _nextTurn() {
    setState(() {
      logic.nextTurn();
      canRoll = true;
    });
  }

  void _showGameOver() {
    final winner = logic.players.firstWhere((p) => p.isWinner);
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => GameOverDialog(
        gameId: widget.game.id,
        score: 100,
        customMessage: "${winner.name} Player Wins!",
        onRestart: () {
          Navigator.pop(context);
          setState(() => gameState = GameState.selection);
        },
        onHome: () {
          Navigator.pop(context);
          Navigator.pop(context);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    switch (gameState) {
      case GameState.selection:
        return _buildSelectionScreen();
      case GameState.countdown:
        return Container(
          color: Colors.black.withOpacity(0.9),
          child: GameCountdown(onFinished: _initGame),
        );
      case GameState.playing:
        return _buildPlayScreen();
      case GameState.won:
        return _buildPlayScreen(); // Keep showing board behind win dialog
    }
  }

  Widget _buildSelectionScreen() {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: Stack(
        children: [
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
                    padding: const EdgeInsets.fromLTRB(24, 30, 24, 20),
                    child: Column(
                      children: [
                        Container(
                          width: 80,
                          height: 80,
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
                        const SizedBox(height: 16),
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
                          "Race to the top!",
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
                        _sectionLabel("PLAYER COUNT"),
                        _iosSettingsGroup([
                          _settingsRow(
                            "2 Players",
                            Icons.person_rounded,
                            playerCount == 2,
                            () => setState(() => playerCount = 2),
                          ),
                          _divider(),
                          _settingsRow(
                            "3 Players",
                            Icons.people_rounded,
                            playerCount == 3,
                            () => setState(() => playerCount = 3),
                          ),
                          _divider(),
                          _settingsRow(
                            "4 Players",
                            Icons.groups_rounded,
                            playerCount == 4,
                            () => setState(() => playerCount = 4),
                          ),
                        ], isDark),

                        _sectionLabel("DIFFICULTY (JUMPS)"),
                        _iosSettingsGroup([
                          _settingsRow(
                            "Classic",
                            Icons.eco_outlined,
                            selectedDifficulty == GameDifficulty.easy,
                            () => setState(
                              () => selectedDifficulty = GameDifficulty.easy,
                            ),
                          ),
                          _divider(),
                          _settingsRow(
                            "Mixed",
                            Icons.shuffle_rounded,
                            selectedDifficulty == GameDifficulty.medium,
                            () => setState(
                              () => selectedDifficulty = GameDifficulty.medium,
                            ),
                          ),
                          _divider(),
                          _settingsRow(
                            "Chaotic",
                            Icons.whatshot_rounded,
                            selectedDifficulty == GameDifficulty.hard,
                            () => setState(
                              () => selectedDifficulty = GameDifficulty.hard,
                            ),
                          ),
                        ], isDark),

                        const SizedBox(height: 32),

                        GestureDetector(
                          onTap: _startGame,
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
                                "Start Race",
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
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
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 6),
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

  Widget _buildPlayScreen() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      backgroundColor: isDark
          ? const Color(0xFF0F0F0F)
          : const Color(0xFFF9F9F9),
      body: SafeArea(
        child: Column(
          children: [
            _buildGameHeader(isDark),
            _buildTurnIndicator(isDark),
            const Spacer(),
            Center(
              child: AspectRatio(
                aspectRatio: 1,
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: _buildBoard(),
                ),
              ),
            ),
            const Spacer(),
            _buildDiceArea(isDark),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildGameHeader(bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          // Hide back button during active gameplay
          SizedBox(
            width: 24,
            child: gameState == GameState.won
                ? GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Icon(
                      Icons.arrow_back_ios_new_rounded,
                      color: isDark ? Colors.white70 : Colors.black87,
                    ),
                  )
                : const SizedBox.shrink(),
          ),
          const Spacer(),
          Text(
            "SNAKES & LADDERS",
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              letterSpacing: 1,
              color: isDark ? Colors.white : Colors.black87,
            ),
          ),
          const Spacer(),
          GestureDetector(
            onTap: () => setState(() => gameState = GameState.selection),
            child: Icon(
              Icons.refresh_rounded,
              color: isDark ? Colors.white70 : Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTurnIndicator(bool isDark) {
    final player = logic.currentPlayer;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      decoration: BoxDecoration(
        color: player.color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(100),
        border: Border.all(color: player.color.withOpacity(0.3), width: 1),
      ),
      child: Text(
        "${player.name.toUpperCase()}'S TURN",
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w800,
          color: player.color,
          letterSpacing: 1,
        ),
      ),
    );
  }

  Widget _buildBoard() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final double boardSize = constraints.maxWidth;
        final double cellSize = boardSize / 10;

        return Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          clipBehavior: Clip.antiAlias,
          child: Stack(
            children: [
              _buildGridBackground(boardSize),
              CustomPaint(
                size: Size(boardSize, boardSize),
                painter: SnakesLaddersPainter(
                  snakes: logic.snakes,
                  ladders: logic.ladders,
                  cellSize: cellSize,
                ),
              ),
              ...logic.players.map((p) => _buildPlayerToken(p, cellSize)),
            ],
          ),
        );
      },
    );
  }

  Widget _buildGridBackground(double size) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      width: size,
      height: size,
      color: isDark ? const Color(0xFF1C1C1E) : Colors.white,
      child: GridView.builder(
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 10,
        ),
        itemCount: 100,
        itemBuilder: (context, index) {
          int r = index ~/ 10;
          int c = index % 10;
          int boardRow = 9 - r;
          int boardCol = c;
          if (boardRow % 2 == 1) boardCol = 9 - c;
          int position = boardRow * 10 + boardCol + 1;

          bool isEven = (r + c) % 2 == 0;
          Color color = isEven
              ? (isDark ? const Color(0xFF2C2C2E) : const Color(0xFFF2F2F7))
              : (isDark ? const Color(0xFF1C1C1E) : Colors.white);

          return Container(
            decoration: BoxDecoration(
              color: color,
              border: Border.all(
                color: isDark
                    ? Colors.white.withOpacity(0.05)
                    : Colors.black.withOpacity(0.05),
                width: 0.5,
              ),
            ),
            child: Center(
              child: Text(
                '$position',
                style: TextStyle(
                  fontSize: 10,
                  color: isDark ? Colors.white10 : Colors.black12,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildPlayerToken(SLPlayer player, double cellSize) {
    if (player.position == 0) return const SizedBox.shrink();
    final coords = SnakesAndLaddersLogic.getCoordinates(player.position);
    final playersAtPos = logic.players
        .where((p) => p.position == player.position)
        .toList();
    final playerIndexAtPos = playersAtPos.indexOf(player);

    double offsetSide =
        (playerIndexAtPos % 2 == 0 ? 1 : -1) * (cellSize * 0.15);
    double offsetUp = (playerIndexAtPos < 2 ? 0 : 1) * (cellSize * 0.15);

    return AnimatedPositioned(
      duration: const Duration(milliseconds: 400),
      curve: Curves.elasticOut,
      left: coords.x * cellSize + (cellSize / 2 - 12) + offsetSide,
      bottom: coords.y * cellSize + (cellSize / 2 - 12) + offsetUp,
      child: Container(
        width: 24,
        height: 24,
        decoration: BoxDecoration(
          color: player.color,
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white, width: 2),
          boxShadow: [
            BoxShadow(
              color: player.color.withOpacity(0.4),
              blurRadius: 8,
              spreadRadius: 1,
            ),
          ],
        ),
        child: Center(
          child: Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.3),
              shape: BoxShape.circle,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDiceArea(bool isDark) {
    final player = logic.currentPlayer;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        children: [
          _buildDice(diceValue, isDark),
          const SizedBox(width: 20),
          Expanded(
            child: GestureDetector(
              onTap: canRoll && !isRolling ? _rollDice : null,
              child: Container(
                height: 60,
                decoration: BoxDecoration(
                  color: player.color,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: player.color.withOpacity(0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Center(
                  child: Text(
                    isRolling ? "ROLLING..." : "ROLL DICE",
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDice(int value, bool isDark) {
    return Container(
      width: 60,
      height: 60,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF2C2C2E) : Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 10),
        ],
      ),
      child: CustomPaint(painter: DicePainter(value, isDark)),
    );
  }

  Widget _buildWinScreen() {
    return const SizedBox.shrink(); // Handled by _showGameOver dialog
  }
}

class DicePainter extends CustomPainter {
  final int value;
  final bool isDark;
  DicePainter(this.value, this.isDark);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = isDark ? Colors.white : Colors.black87
      ..style = PaintingStyle.fill;

    final double center = size.width / 2;
    final double left = size.width * 0.25;
    final double right = size.width * 0.75;
    final double top = size.height * 0.25;
    final double bottom = size.height * 0.75;
    final double radius = size.width * 0.08;

    void drawDot(double x, double y) =>
        canvas.drawCircle(Offset(x, y), radius, paint);

    if (value == 1) {
      drawDot(center, center);
    } else if (value == 2) {
      drawDot(left, top);
      drawDot(right, bottom);
    } else if (value == 3) {
      drawDot(left, top);
      drawDot(center, center);
      drawDot(right, bottom);
    } else if (value == 4) {
      drawDot(left, top);
      drawDot(right, top);
      drawDot(left, bottom);
      drawDot(right, bottom);
    } else if (value == 5) {
      drawDot(left, top);
      drawDot(right, top);
      drawDot(center, center);
      drawDot(left, bottom);
      drawDot(right, bottom);
    } else {
      drawDot(left, top);
      drawDot(right, top);
      drawDot(left, center);
      drawDot(right, center);
      drawDot(left, bottom);
      drawDot(right, bottom);
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => true;
}

class SnakesLaddersPainter extends CustomPainter {
  final Map<int, int> snakes;
  final Map<int, int> ladders;
  final double cellSize;

  SnakesLaddersPainter({
    required this.snakes,
    required this.ladders,
    required this.cellSize,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Draw Ladders
    final ladderPaint = Paint()
      ..color = Colors.brown[400]!
      ..strokeWidth = 4
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final ladderRungPaint = Paint()
      ..color = Colors.brown[400]!
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    ladders.forEach((start, end) {
      final startPt = _getCenter(start, size);
      final endPt = _getCenter(end, size);

      final dx = endPt.dx - startPt.dx;
      final dy = endPt.dy - startPt.dy;
      final distance = sqrt(dx * dx + dy * dy);

      // ladder width
      final nx = -dy / distance * 8;
      final ny = dx / distance * 8;

      canvas.drawLine(
        Offset(startPt.dx + nx, startPt.dy + ny),
        Offset(endPt.dx + nx, endPt.dy + ny),
        ladderPaint,
      );
      canvas.drawLine(
        Offset(startPt.dx - nx, startPt.dy - ny),
        Offset(endPt.dx - nx, endPt.dy - ny),
        ladderPaint,
      );

      int rungs = (distance / 12).floor();
      for (int i = 1; i < rungs; i++) {
        double t = i / rungs;
        double px = startPt.dx + dx * t;
        double py = startPt.dy + dy * t;
        canvas.drawLine(
          Offset(px + nx, py + ny),
          Offset(px - nx, py - ny),
          ladderRungPaint,
        );
      }
    });

    // Draw Snakes
    final snakePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    snakes.forEach((head, tail) {
      final headPt = _getCenter(head, size);
      final tailPt = _getCenter(tail, size);

      final path = Path();
      path.moveTo(headPt.dx, headPt.dy);

      final dx = tailPt.dx - headPt.dx;
      final dy = tailPt.dy - headPt.dy;

      final cp1 = Offset(
        headPt.dx + dx * 0.25 + dy * 0.2,
        headPt.dy + dy * 0.25 - dx * 0.2,
      );
      final cp2 = Offset(
        headPt.dx + dx * 0.75 - dy * 0.2,
        headPt.dy + dy * 0.75 + dx * 0.2,
      );

      path.cubicTo(cp1.dx, cp1.dy, cp2.dx, cp2.dy, tailPt.dx, tailPt.dy);

      // Draw shadow
      canvas.drawPath(
        path,
        snakePaint
          ..color = Colors.black.withOpacity(0.2)
          ..strokeWidth = 10,
      );

      // Draw body
      canvas.drawPath(
        path,
        snakePaint
          ..color = Colors.green[600]!
          ..strokeWidth = 8,
      );

      // Draw head/eyes
      final eyePaint = Paint()..color = Colors.white;
      canvas.drawCircle(Offset(headPt.dx - 2, headPt.dy), 2, eyePaint);
      canvas.drawCircle(Offset(headPt.dx + 2, headPt.dy), 2, eyePaint);

      final pupilPaint = Paint()..color = Colors.black;
      canvas.drawCircle(Offset(headPt.dx - 2, headPt.dy), 1, pupilPaint);
      canvas.drawCircle(Offset(headPt.dx + 2, headPt.dy), 1, pupilPaint);
    });
  }

  Offset _getCenter(int position, Size size) {
    final coords = SnakesAndLaddersLogic.getCoordinates(position);
    return Offset(
      coords.x * cellSize + cellSize / 2,
      size.height - (coords.y * cellSize + cellSize / 2),
    );
  }

  @override
  bool shouldRepaint(covariant SnakesLaddersPainter oldDelegate) => false;
}
