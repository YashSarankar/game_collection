import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/models/game_model.dart';
import '../../core/services/haptic_service.dart';
import '../../ui/widgets/game_countdown.dart';
import '../../ui/widgets/game_over_dialog.dart';
import 'nine_mens_morris_logic.dart';
import 'nine_mens_morris_ai.dart';

class NineMensMorrisWidget extends StatefulWidget {
  final GameModel game;
  const NineMensMorrisWidget({super.key, required this.game});

  @override
  State<NineMensMorrisWidget> createState() => _NineMensMorrisWidgetState();
}

class _NineMensMorrisWidgetState extends State<NineMensMorrisWidget> {
  late NineMensMorrisLogic _logic;
  bool _isCountingDown = true;
  HapticService? _hapticService;
  
  bool _isAiMode = true;
  bool _isAiThinking = false;
  int _aiDifficulty = 5;

  @override
  void initState() {
    super.initState();
    _logic = NineMensMorrisLogic();
    _initHaptic();
  }

  Future<void> _initHaptic() async {
    _hapticService = await HapticService.getInstance();
  }

  void _onCountdownFinished() {
    setState(() {
      _isCountingDown = false;
    });
  }

  void _handleTap(int index) {
    if (_isCountingDown || _logic.phase == GamePhase.gameOver) return;
    if (_isAiMode && _logic.currentPlayer == Player.player2) return; // Prevent human tap during AI turn
    if (_isAiThinking) return;

    _processTap(index);
  }

  void _processTap(int index) {
    _hapticService?.light();
    _logic.handleTap(index);
    
    if (_logic.phase == GamePhase.gameOver) {
      _showGameOver();
      return;
    }
    
    // Check if it's AI turn now
    if (_isAiMode && _logic.currentPlayer == Player.player2 && _logic.phase != GamePhase.gameOver) {
      _triggerAiTurn();
    }
  }

  void _triggerAiTurn() async {
    if (!mounted) return;
    setState(() {
      _isAiThinking = true;
    });

    Map<String, dynamic> stateMap = _logic.aiStateMap;
    stateMap['difficulty'] = _aiDifficulty;
    
    List<int>? taps = await getNineMensMorrisBestMove(stateMap);
    
    if (taps != null) {
      for (int i = 0; i < taps.length; i++) {
        await Future.delayed(const Duration(milliseconds: 500));
        if (mounted) {
          _hapticService?.light();
          _logic.handleTap(taps[i]);
          setState(() {});
        }
      }
    }

    if (mounted) {
      setState(() {
        _isAiThinking = false;
      });
      if (_logic.phase == GamePhase.gameOver) {
        _showGameOver();
      }
    }
  }

  void _showGameOver() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => GameOverDialog(
        gameId: widget.game.id,
        score: _logic.currentPlayer == Player.player1
            ? 1
            : 1, // Traditional game, just win/loss
        onRestart: () {
          Navigator.pop(context);
          _logic.reset();
          setState(() {
            _isCountingDown = true;
          });
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
    return ChangeNotifierProvider.value(
      value: _logic,
      child: Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        body: SafeArea(
          child: Column(
            children: [
              _buildHeader(context),
              Expanded(
                child: Center(
                  child: AspectRatio(
                    aspectRatio: 1,
                    child: Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Stack(
                        children: [
                          Consumer<NineMensMorrisLogic>(
                            builder: (context, logic, child) {
                              final isDark =
                                  Theme.of(context).brightness ==
                                  Brightness.dark;
                              return CustomPaint(
                                painter: NineMensMorrisPainter(
                                  logic: logic,
                                  lineColor: isDark
                                      ? Colors.white54
                                      : Colors.black45,
                                  pointColor: isDark
                                      ? Colors.white24
                                      : Colors.black12,
                                ),
                                size: Size.infinite,
                              );
                            },
                          ),
                          // Clickable points
                          LayoutBuilder(
                            builder: (context, constraints) {
                              final center = Offset(
                                constraints.maxWidth / 2,
                                constraints.maxHeight / 2,
                              );
                              final side = constraints.maxWidth;
                              return Stack(
                                children: List.generate(24, (i) {
                                  final pos = _getPointPosition(
                                    i,
                                    center,
                                    side,
                                  );
                                  return Positioned(
                                    left: pos.dx - 25,
                                    top: pos.dy - 25,
                                    child: GestureDetector(
                                      onTap: () => _handleTap(i),
                                      child: Container(
                                        width: 50,
                                        height: 50,
                                        color: Colors.transparent,
                                      ),
                                    ),
                                  );
                                }),
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              _buildFooter(context),
            ],
          ),
        ),
        floatingActionButton: _isCountingDown
            ? null
            : FloatingActionButton(
                mini: true,
                onPressed: () => _logic.reset(),
                backgroundColor: widget.game.primaryColor,
                child: const Icon(Icons.refresh),
              ),
        // Overlay for countdown
        bottomSheet: _isCountingDown
            ? Container(
                height: double.infinity,
                color: Colors.black87,
                child: GameCountdown(onFinished: _onCountdownFinished),
              )
            : null,
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        children: [
          Text(
            widget.game.title,
            style: TextStyle(
              color: isDark ? Colors.white : Colors.black87,
              fontSize: 28,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 10),
          Consumer<NineMensMorrisLogic>(
            builder: (context, logic, child) {
              return Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: logic.currentPlayer == Player.player1
                      ? Colors.blue.withOpacity(0.2)
                      : Colors.red.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: logic.currentPlayer == Player.player1
                        ? Colors.blue
                        : Colors.red,
                    width: 2,
                  ),
                ),
                child: Text(
                  logic.message,
                  style: TextStyle(
                    color: logic.currentPlayer == Player.player1
                        ? Colors.blue
                        : Colors.red,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 10),
          // AI Toggle & Difficulty
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'vs Player',
                style: TextStyle(
                  color: isDark ? Colors.white70 : Colors.black54,
                  fontWeight: !_isAiMode ? FontWeight.bold : FontWeight.normal,
                ),
              ),
              Switch(
                value: _isAiMode,
                activeColor: widget.game.primaryColor,
                onChanged: (val) {
                  if (_logic.phase != GamePhase.gameOver && !_isAiThinking) {
                    setState(() {
                      _isAiMode = val;
                      if (_isAiMode && _logic.currentPlayer == Player.player2) {
                        _triggerAiTurn();
                      }
                    });
                  }
                },
              ),
              Text(
                'vs AI',
                style: TextStyle(
                  color: isDark ? Colors.white70 : Colors.black54,
                  fontWeight: _isAiMode ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ],
          ),
          if (_isAiThinking)
            Padding(
              padding: const EdgeInsets.only(top: 8.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'AI is thinking...',
                    style: TextStyle(
                      color: isDark ? Colors.white54 : Colors.black45,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildFooter(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Consumer<NineMensMorrisLogic>(
      builder: (context, logic, child) {
        return Padding(
          padding: const EdgeInsets.all(20.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildPlayerInfo(
                "Player 1",
                Colors.blue,
                logic.p1PiecesToPlace,
                logic.p1PiecesOnBoard,
                logic.currentPlayer == Player.player1,
                isDark,
              ),
              _buildPlayerInfo(
                "Player 2",
                Colors.red,
                logic.p2PiecesToPlace,
                logic.p2PiecesOnBoard,
                logic.currentPlayer == Player.player2,
                isDark,
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildPlayerInfo(
    String name,
    Color color,
    int toPlace,
    int onBoard,
    bool isCurrent,
    bool isDark,
  ) {
    return Opacity(
      opacity: isCurrent ? 1.0 : 0.5,
      child: Column(
        children: [
          Text(
            name,
            style: TextStyle(
              color: color,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            "To Place: $toPlace",
            style: TextStyle(color: isDark ? Colors.white70 : Colors.black54),
          ),
          Text(
            "On Board: $onBoard",
            style: TextStyle(color: isDark ? Colors.white70 : Colors.black54),
          ),
        ],
      ),
    );
  }

  Offset _getPointPosition(int index, Offset center, double side) {
    final square = index ~/ 8;
    final posInSquare = index % 8;

    double factor = 0.0;
    if (square == 0) factor = 0.45; // Outer
    if (square == 1) factor = 0.30; // Middle
    if (square == 2) factor = 0.15; // Inner

    final unit = side * factor;

    switch (posInSquare) {
      case 0:
        return center + Offset(-unit, -unit);
      case 1:
        return center + Offset(0, -unit);
      case 2:
        return center + Offset(unit, -unit);
      case 3:
        return center + Offset(unit, 0);
      case 4:
        return center + Offset(unit, unit);
      case 5:
        return center + Offset(0, unit);
      case 6:
        return center + Offset(-unit, unit);
      case 7:
        return center + Offset(-unit, 0);
      default:
        return center;
    }
  }
}

class NineMensMorrisPainter extends CustomPainter {
  final NineMensMorrisLogic logic;
  final Color lineColor;
  final Color pointColor;

  NineMensMorrisPainter({
    required this.logic,
    required this.lineColor,
    required this.pointColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final side = size.width;

    final linePaint = Paint()
      ..color = lineColor
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke;

    final pointPaint = Paint()
      ..color = pointColor
      ..style = PaintingStyle.fill;

    // Draw Squares
    for (int i = 0; i < 3; i++) {
      double factor = 0.0;
      if (i == 0) factor = 0.45;
      if (i == 1) factor = 0.30;
      if (i == 2) factor = 0.15;

      final unit = side * factor;
      canvas.drawRect(
        Rect.fromCenter(center: center, width: unit * 2, height: unit * 2),
        linePaint,
      );
    }

    // Draw Connecting Lines (Midpoints)
    double far = side * 0.45;
    double near = side * 0.15;
    canvas.drawLine(
      center + Offset(0, -far),
      center + Offset(0, -near),
      linePaint,
    ); // Top
    canvas.drawLine(
      center + Offset(far, 0),
      center + Offset(near, 0),
      linePaint,
    ); // Right
    canvas.drawLine(
      center + Offset(0, far),
      center + Offset(0, near),
      linePaint,
    ); // Bottom
    canvas.drawLine(
      center + Offset(-far, 0),
      center + Offset(-near, 0),
      linePaint,
    ); // Left

    // Draw Points and Pieces
    for (int i = 0; i < 24; i++) {
      final pos = _getPointPosition(i, center, side);

      // Draw point indicator
      canvas.drawCircle(pos, 6, pointPaint);

      // Draw highlighting if selected
      if (logic.selectedIndex == i) {
        final highlightPaint = Paint()
          ..color = Colors.yellow.withOpacity(0.5)
          ..style = PaintingStyle.fill;
        canvas.drawCircle(pos, 22, highlightPaint);
      }

      // Draw pieces
      if (logic.board[i] != Player.none) {
        final piecePaint = Paint()
          ..color = logic.board[i] == Player.player1 ? Colors.blue : Colors.red
          ..style = PaintingStyle.fill;

        // Add a nice glow/shadow to pieces
        canvas.drawCircle(
          pos,
          18,
          Paint()
            ..color = Colors.black45
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4),
        );
        canvas.drawCircle(pos, 18, piecePaint);

        // Piece detail
        canvas.drawCircle(
          pos,
          14,
          Paint()
            ..color = Colors.white24
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2,
        );
      }
    }
  }

  Offset _getPointPosition(int index, Offset center, double side) {
    final square = index ~/ 8;
    final posInSquare = index % 8;

    double factor = 0.0;
    if (square == 0) factor = 0.45;
    if (square == 1) factor = 0.30;
    if (square == 2) factor = 0.15;

    final unit = side * factor;

    switch (posInSquare) {
      case 0:
        return center + Offset(-unit, -unit);
      case 1:
        return center + Offset(0, -unit);
      case 2:
        return center + Offset(unit, -unit);
      case 3:
        return center + Offset(unit, 0);
      case 4:
        return center + Offset(unit, unit);
      case 5:
        return center + Offset(0, unit);
      case 6:
        return center + Offset(-unit, unit);
      case 7:
        return center + Offset(-unit, 0);
      default:
        return center;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
