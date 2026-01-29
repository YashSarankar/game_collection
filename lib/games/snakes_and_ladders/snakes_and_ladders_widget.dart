import 'dart:math';
import 'package:flutter/material.dart';
import '../../core/models/game_model.dart';
import '../../core/services/haptic_service.dart';
import 'snakes_and_ladders_logic.dart';
import '../../ui/widgets/game_countdown.dart';

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
    final colors = [Colors.red, Colors.blue, Colors.green, Colors.orange];
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

    // Simulating roll animation
    for (int i = 0; i < 8; i++) {
      await Future.delayed(const Duration(milliseconds: 100));
      setState(() {
        diceValue = Random().nextInt(6) + 1;
      });
    }

    int finalRoll = logic.rollDice();
    _diceController.stop();

    setState(() {
      diceValue = finalRoll;
      isRolling = false;
    });

    _hapticService?.medium();
    _movePlayer();
  }

  void _movePlayer() async {
    final player = logic.currentPlayer;
    int roll = diceValue;
    int oldPos = player.position;
    int targetPos = logic.calculateNewPosition(oldPos, roll);

    if (targetPos == oldPos) {
      // No move (overshoot)
      await Future.delayed(const Duration(milliseconds: 500));
      _nextTurn();
      return;
    }

    // Step-by-step movement
    for (int i = oldPos + 1; i <= targetPos; i++) {
      await Future.delayed(const Duration(milliseconds: 300));
      setState(() {
        player.position = i;
      });
      _hapticService?.light();
    }

    // Check for win
    if (player.position == 100) {
      setState(() {
        player.isWinner = true;
        gameState = GameState.won;
      });
      _hapticService?.heavy();
      return;
    }

    // Check for snake or ladder
    int? jumpPos = logic.checkJump(player.position);
    if (jumpPos != null) {
      await Future.delayed(const Duration(milliseconds: 500));
      // Animation for jump
      setState(() {
        player.position = jumpPos;
      });
      _hapticService?.medium();

      // Check for win after jump
      if (player.position == 100) {
        setState(() {
          player.isWinner = true;
          gameState = GameState.won;
        });
        _hapticService?.heavy();
        return;
      }
    }

    // Extra turn on 6 (Optional Rule)
    if (diceValue == 6) {
      setState(() {
        canRoll = true;
      });
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

  @override
  Widget build(BuildContext context) {
    switch (gameState) {
      case GameState.selection:
        return _buildSelectionScreen();
      case GameState.countdown:
        return Container(
          color: Colors.black.withOpacity(0.8),
          child: GameCountdown(onFinished: _initGame),
        );
      case GameState.playing:
        return _buildPlayScreen();
      case GameState.won:
        return _buildWinScreen();
    }
  }

  Widget _buildSelectionScreen() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xFF1C1C1E) : Colors.white;

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: BackButton(color: isDark ? Colors.white : Colors.black),
      ),
      extendBodyBehindAppBar: true,
      body: LayoutBuilder(
        builder: (context, constraints) {
          return SingleChildScrollView(
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: constraints.maxHeight),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  vertical: 60,
                  horizontal: 20,
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.stairs_rounded,
                      size: 80,
                      color: widget.game.primaryColor,
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'Snakes & Ladders',
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 30),
                    Text(
                      'How many players?',
                      style: TextStyle(
                        fontSize: 18,
                        color: isDark ? Colors.white70 : Colors.black54,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [2, 3, 4].map((count) {
                        bool isSelected = playerCount == count;
                        return Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          child: ElevatedButton(
                            onPressed: () =>
                                setState(() => playerCount = count),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: isSelected
                                  ? widget.game.primaryColor
                                  : (isDark
                                        ? Colors.white12
                                        : Colors.grey[200]),
                              foregroundColor: isSelected
                                  ? Colors.white
                                  : (isDark ? Colors.white70 : Colors.black87),
                              padding: const EdgeInsets.all(16),
                              shape: const CircleBorder(),
                              elevation: isSelected ? 4 : 0,
                            ),
                            child: Text(
                              '$count',
                              style: const TextStyle(fontSize: 18),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 30),
                    Text(
                      'Difficulty Level',
                      style: TextStyle(
                        fontSize: 18,
                        color: isDark ? Colors.white70 : Colors.black54,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Column(
                      children: GameDifficulty.values.map((diff) {
                        bool isSelected = selectedDifficulty == diff;
                        return Padding(
                          padding: const EdgeInsets.symmetric(
                            vertical: 4,
                            horizontal: 40,
                          ),
                          child: SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: () =>
                                  setState(() => selectedDifficulty = diff),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: isSelected
                                    ? widget.game.primaryColor
                                    : (isDark
                                          ? Colors.white12
                                          : Colors.grey[200]),
                                foregroundColor: isSelected
                                    ? Colors.white
                                    : (isDark
                                          ? Colors.white70
                                          : Colors.black87),
                                padding: const EdgeInsets.symmetric(
                                  vertical: 12,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                elevation: isSelected ? 4 : 0,
                              ),
                              child: Text(
                                diff.name.toUpperCase(),
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 40),
                    ElevatedButton(
                      onPressed: _startGame,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.amber,
                        foregroundColor: Colors.black,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 60,
                          vertical: 15,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                        elevation: 10,
                      ),
                      child: const Text(
                        'START GAME',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildPlayScreen() {
    return Column(
      children: [
        _buildHeader(),
        Expanded(
          child: Center(
            child: AspectRatio(aspectRatio: 1, child: _buildBoard()),
          ),
        ),
        _buildDiceArea(),
      ],
    );
  }

  Widget _buildHeader() {
    final player = logic.currentPlayer;
    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        mainAxisAlignment:
            MainAxisAlignment.center, // Center the turn indicator
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            decoration: BoxDecoration(
              color: player.color,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(color: player.color.withOpacity(0.4), blurRadius: 10),
              ],
            ),
            child: Text(
              "${player.name}'s Turn",
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBoard() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final double boardSize = constraints.maxWidth;
        final double cellSize = boardSize / 10;

        return Stack(
          children: [
            // Grid Background
            _buildGridBackground(boardSize),
            // Snakes and Ladders
            CustomPaint(
              size: Size(boardSize, boardSize),
              painter: SnakesLaddersPainter(
                snakes: logic.snakes,
                ladders: logic.ladders,
                cellSize: cellSize,
              ),
            ),
            // Player Tokens
            ...logic.players.map((p) => _buildPlayerToken(p, cellSize)),
          ],
        );
      },
    );
  }

  Widget _buildGridBackground(double size) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: isDark ? Colors.grey[900] : Colors.white,
        border: Border.all(color: Colors.black, width: 2),
      ),
      child: GridView.builder(
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 10,
        ),
        itemCount: 100,
        itemBuilder: (context, index) {
          // Grid is 10x10. We need to map index to board position.
          // Visual grid index 0 is top-left, 99 is bottom-right.
          // Board position 1 is bottom-left, 100 is top-left or top-right.

          // Let's calculate the position number for this cell (r, c)
          int r = index ~/ 10;
          int c = index % 10;

          // Row 0 (top) is board row 9. Row 9 (bottom) is board row 0.
          int boardRow = 9 - r;
          int boardCol = c;
          if (boardRow % 2 == 1) {
            boardCol = 9 - c;
          }
          int position = boardRow * 10 + boardCol + 1;

          bool isEven = (r + c) % 2 == 0;
          Color color = isEven
              ? (isDark ? Colors.grey[850]! : Colors.blueGrey[50]!)
              : (isDark ? Colors.grey[900]! : Colors.white);

          return Container(
            decoration: BoxDecoration(
              color: color,
              border: Border.all(
                color: isDark ? Colors.white10 : Colors.black12,
                width: 0.5,
              ),
            ),
            child: Center(
              child: Text(
                '$position',
                style: TextStyle(
                  fontSize: 10,
                  color: isDark ? Colors.white38 : Colors.black26,
                  fontWeight: FontWeight.bold,
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
          gradient: RadialGradient(
            colors: [player.color.withOpacity(0.8), player.color],
            center: const Alignment(-0.3, -0.3),
          ),
          border: Border.all(color: Colors.white, width: 2),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
            BoxShadow(
              color: player.color.withOpacity(0.5),
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

  Widget _buildDiceArea() {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildDice(diceValue),
          ElevatedButton(
            onPressed: canRoll && !isRolling ? _rollDice : null,
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
              backgroundColor: logic.currentPlayer.color,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30),
              ),
            ),
            child: Text(
              isRolling ? "Rolling..." : "Roll Dice",
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDice(int value) {
    return Container(
      width: 60,
      height: 60,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            spreadRadius: 2,
          ),
        ],
        border: Border.all(color: Colors.grey[300]!, width: 2),
      ),
      child: CustomPaint(painter: DicePainter(value)),
    );
  }

  Widget _buildWinScreen() {
    final winner = logic.players.firstWhere((p) => p.isWinner);
    return Container(
      width: double.infinity,
      color: Colors.black87,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.emoji_events_rounded,
            color: Colors.amber,
            size: 100,
          ),
          const SizedBox(height: 20),
          Text(
            '${winner.name} Wins!',
            style: const TextStyle(
              fontSize: 40,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 40),
          ElevatedButton(
            onPressed: () {
              setState(() {
                gameState = GameState.selection;
              });
            },
            child: const Text('Play Again'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'Back to Menu',
              style: TextStyle(color: Colors.white70),
            ),
          ),
        ],
      ),
    );
  }
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
    ladders.forEach((start, end) {
      final startPos = SnakesAndLaddersLogic.getCoordinates(start);
      final endPos = SnakesAndLaddersLogic.getCoordinates(end);

      final p1 = Offset(
        startPos.x * cellSize + cellSize / 2,
        size.height - (startPos.y * cellSize + cellSize / 2),
      );
      final p2 = Offset(
        endPos.x * cellSize + cellSize / 2,
        size.height - (endPos.y * cellSize + cellSize / 2),
      );

      final angle = (p2 - p1).direction;
      final perpAngle = angle + pi / 2;
      final offset = Offset(cos(perpAngle), sin(perpAngle)) * (cellSize * 0.22);

      // 1. Ladder Shadow
      final shadowPaint = Paint()
        ..color = Colors.black.withOpacity(0.15)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 5
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3);
      canvas.drawLine(
        p1 - offset + const Offset(2, 2),
        p2 - offset + const Offset(2, 2),
        shadowPaint,
      );
      canvas.drawLine(
        p1 + offset + const Offset(2, 2),
        p2 + offset + const Offset(2, 2),
        shadowPaint,
      );

      // 2. Ladder Rails (3D look with gradient)
      final railPaint = Paint()
        ..shader = LinearGradient(
          colors: [Colors.brown[700]!, Colors.brown[400]!, Colors.brown[800]!],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ).createShader(Rect.fromPoints(p1 - offset, p2 + offset))
        ..style = PaintingStyle.stroke
        ..strokeWidth = 6
        ..strokeCap = StrokeCap.round;

      canvas.drawLine(p1 - offset, p2 - offset, railPaint);
      canvas.drawLine(p1 + offset, p2 + offset, railPaint);

      // 3. Rungs
      int rungs = (p2 - p1).distance ~/ (cellSize * 0.35);
      final rungPaint = Paint()
        ..color = Colors.brown[600]!
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3
        ..strokeCap = StrokeCap.round;

      for (int i = 1; i <= rungs; i++) {
        final t = i / (rungs + 1);
        final rungP = Offset.lerp(p1, p2, t)!;
        canvas.drawLine(rungP - offset, rungP + offset, rungPaint);
        // Rung highlight
        canvas.drawLine(
          rungP - offset + const Offset(0, -1),
          rungP + offset + const Offset(0, -1),
          Paint()
            ..color = Colors.white.withOpacity(0.2)
            ..strokeWidth = 1,
        );
      }
    });

    // Draw Snakes
    snakes.forEach((head, tail) {
      final headPos = SnakesAndLaddersLogic.getCoordinates(head);
      final tailPos = SnakesAndLaddersLogic.getCoordinates(tail);

      final pHead = Offset(
        headPos.x * cellSize + cellSize / 2,
        size.height - (headPos.y * cellSize + cellSize / 2),
      );
      final pTail = Offset(
        tailPos.x * cellSize + cellSize / 2,
        size.height - (tailPos.y * cellSize + cellSize / 2),
      );

      // Better wavy path using Cubic Bezier
      final double dist = (pHead - pTail).distance;
      final Offset dir = (pTail - pHead) / dist;
      final Offset perp = Offset(-dir.dy, dir.dx) * (cellSize * 0.7);

      final path = Path();
      path.moveTo(pHead.dx, pHead.dy);

      final cp1 = Offset.lerp(pHead, pTail, 0.3)! + perp;
      final cp2 = Offset.lerp(pHead, pTail, 0.7)! - perp;

      path.cubicTo(cp1.dx, cp1.dy, cp2.dx, cp2.dy, pTail.dx, pTail.dy);

      // 1. Wide Shadow for depth
      canvas.drawPath(
        path,
        Paint()
          ..color = Colors.black.withOpacity(0.15)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 12
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5),
      );

      // 2. Main Body with Gradient
      final bodyPaint = Paint()
        ..shader = LinearGradient(
          colors: [
            Colors.green[800]!,
            Colors.green[400]!,
            Colors.green[900]!,
            Colors.teal[900]!,
          ],
          stops: const [0.0, 0.3, 0.7, 1.0],
        ).createShader(path.getBounds())
        ..style = PaintingStyle.stroke
        ..strokeWidth = 8
        ..strokeCap = StrokeCap.round;

      canvas.drawPath(path, bodyPaint);

      // 3. Scale-like pattern (dashed highlights)

      // We can't easily dash a path with basic Paint, so we draw a thinner highlight
      canvas.drawPath(
        path,
        Paint()
          ..color = Colors.white.withOpacity(0.2)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2
          ..strokeCap = StrokeCap.round,
      );

      // 4. Head Details (3D effect)
      final headPaint = Paint()
        ..color = Colors.green[900]!
        ..style = PaintingStyle.fill;

      // Snake head shape
      canvas.drawCircle(pHead, 7, headPaint);

      // Eyes
      final eyeColor = Colors.white;
      canvas.drawCircle(
        pHead + Offset(-dir.dy * 3, dir.dx * 3) - dir * 2,
        2.5,
        Paint()..color = eyeColor,
      );
      canvas.drawCircle(
        pHead + Offset(dir.dy * 3, -dir.dx * 3) - dir * 2,
        2.5,
        Paint()..color = eyeColor,
      );

      // Pupils
      canvas.drawCircle(
        pHead + Offset(-dir.dy * 3, dir.dx * 3) - dir * 2,
        1,
        Paint()..color = Colors.black,
      );
      canvas.drawCircle(
        pHead + Offset(dir.dy * 3, -dir.dx * 3) - dir * 2,
        1,
        Paint()..color = Colors.black,
      );

      // Tongue (Artistic touch)
      final tonguePaint = Paint()
        ..color = Colors.red
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5;
      final tongueStart = pHead - dir * 7;
      final tongueEnd = pHead - dir * 12;
      canvas.drawLine(tongueStart, tongueEnd, tonguePaint);
      canvas.drawLine(
        tongueEnd,
        tongueEnd + Offset(-dir.dy * 2 - dir.dx * 2, dir.dx * 2 - dir.dy * 2),
        tonguePaint,
      );
      canvas.drawLine(
        tongueEnd,
        tongueEnd + Offset(dir.dy * 2 - dir.dx * 2, -dir.dx * 2 - dir.dy * 2),
        tonguePaint,
      );
    });
  }

  @override
  bool shouldRepaint(covariant SnakesLaddersPainter oldDelegate) => false;
}

class DicePainter extends CustomPainter {
  final int value;
  DicePainter(this.value);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.black
      ..style = PaintingStyle.fill;

    final double mid = size.width / 2;
    final double q1 = size.width * 0.25;
    final double q3 = size.width * 0.75;
    final double radius = size.width * 0.08;

    void drawDot(double x, double y) {
      canvas.drawCircle(Offset(x, y), radius, paint);
    }

    if (value % 2 == 1) drawDot(mid, mid);
    if (value >= 2) {
      drawDot(q1, q1);
      drawDot(q3, q3);
    }
    if (value >= 4) {
      drawDot(q1, q3);
      drawDot(q3, q1);
    }
    if (value == 6) {
      drawDot(q1, mid);
      drawDot(q3, mid);
    }
  }

  @override
  bool shouldRepaint(covariant DicePainter oldDelegate) =>
      oldDelegate.value != value;
}
