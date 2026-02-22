import 'package:flutter/material.dart';
import '../models/ttt_models.dart';
import '../models/ttt_theme.dart';
import 'ttt_piece.dart';
import 'ttt_painters.dart';

class TTTBoard extends StatefulWidget {
  final TTTGameState gameState;
  final TTTTheme theme;
  final Function(int, int) onMove;

  const TTTBoard({
    super.key,
    required this.gameState,
    required this.theme,
    required this.onMove,
  });

  @override
  State<TTTBoard> createState() => _TTTBoardState();
}

class _TTTBoardState extends State<TTTBoard>
    with SingleTickerProviderStateMixin {
  late AnimationController _lineController;
  late Animation<double> _lineAnimation;

  @override
  void initState() {
    super.initState();
    _lineController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _lineAnimation = CurvedAnimation(
      parent: _lineController,
      curve: Curves.easeInOut,
    );
  }

  @override
  void didUpdateWidget(TTTBoard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.gameState.winningLine != null &&
        oldWidget.gameState.winningLine == null) {
      _lineController.forward();
    } else if (widget.gameState.winningLine == null) {
      _lineController.reset();
    }
  }

  @override
  void dispose() {
    _lineController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = widget.gameState.gridSize;

    return AspectRatio(
      aspectRatio: 1,
      child: Stack(
        children: [
          // 3D Depth Shadow Effect
          Positioned(
            top: 10,
            left: 5,
            right: 5,
            bottom: -5,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.3),
                borderRadius: BorderRadius.circular(20),
              ),
            ),
          ),

          // Main Board
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: widget.theme.backgroundColor.withOpacity(0.8),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: widget.theme.gridColor.withOpacity(0.3),
              ),
            ),
            child: CustomPaint(
              painter: GridPaiter(size: size, color: widget.theme.gridColor),
              child: Column(
                children: List.generate(size, (row) {
                  return Expanded(
                    child: Row(
                      children: List.generate(size, (col) {
                        return Expanded(
                          child: GestureDetector(
                            onTap: () => widget.onMove(row, col),
                            behavior: HitTestBehavior.opaque,
                            child: Center(
                              child: widget.gameState.board[row][col].isEmpty
                                  ? null
                                  : TTTPiece(
                                      type: widget.gameState.board[row][col],
                                      theme: widget.theme,
                                    ),
                            ),
                          ),
                        );
                      }),
                    ),
                  );
                }),
              ),
            ),
          ),

          // Winning Line Overlay
          if (widget.gameState.winningLine != null)
            LayoutBuilder(
              builder: (context, constraints) {
                final cellWidth = constraints.maxWidth / size;
                final cellHeight = constraints.maxHeight / size;

                final points = widget.gameState.winningLine!.map((p) {
                  return Offset(
                    p.dx * cellWidth + cellWidth / 2,
                    p.dy * cellHeight + cellHeight / 2,
                  );
                }).toList();

                return AnimatedBuilder(
                  animation: _lineAnimation,
                  builder: (context, child) {
                    return CustomPaint(
                      size: Size(constraints.maxWidth, constraints.maxHeight),
                      painter: WinningLinePainter(
                        points: points,
                        color: widget.gameState.winner == 'X'
                            ? widget.theme.playerXColor
                            : widget.theme.playerOColor,
                        progress: _lineAnimation.value,
                      ),
                    );
                  },
                );
              },
            ),
        ],
      ),
    );
  }
}
