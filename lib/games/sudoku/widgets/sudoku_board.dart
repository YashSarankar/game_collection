import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/sudoku_provider.dart';
import '../models/sudoku_cell.dart';

class SudokuBoard extends StatelessWidget {
  const SudokuBoard({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<SudokuProvider>();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AspectRatio(
      aspectRatio: 1,
      child: Container(
        margin: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: isDark ? Colors.grey[900] : Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 20,
              spreadRadius: 5,
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Stack(
            children: [
              // Grid Background highlights
              CustomPaint(
                size: Size.infinite,
                painter: BoardPainter(
                  selectedRow: provider.selectedRow,
                  selectedCol: provider.selectedCol,
                  board: provider.board,
                  isDark: isDark,
                ),
              ),
              // Numbers & Notes
              GridView.builder(
                padding: EdgeInsets.zero,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 9,
                ),
                itemCount: 81,
                itemBuilder: (context, index) {
                  final r = index ~/ 9;
                  final c = index % 9;
                  return _CellWidget(cell: provider.board[r][c]);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CellWidget extends StatelessWidget {
  final SudokuCell cell;
  const _CellWidget({required this.cell});

  @override
  Widget build(BuildContext context) {
    final provider = context.read<SudokuProvider>();
    final isSelected =
        provider.selectedRow == cell.row && provider.selectedCol == cell.col;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTap: () => provider.selectCell(cell.row, cell.col),
      child: Container(
        color: Colors.transparent,
        child: Center(
          child: cell.value != 0
              ? AnimatedScale(
                  scale: 1.0,
                  duration: const Duration(milliseconds: 200),
                  child: Text(
                    '${cell.value}',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: cell.isInitial
                          ? FontWeight.w900
                          : FontWeight.w400,
                      color: _getCellTextColor(cell, isSelected, isDark),
                    ),
                  ),
                )
              : _buildNotes(cell, isDark),
        ),
      ),
    );
  }

  Widget _buildNotes(SudokuCell cell, bool isDark) {
    if (cell.notes.isEmpty) return const SizedBox.shrink();
    return GridView.builder(
      padding: const EdgeInsets.all(2),
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
      ),
      itemCount: 9,
      itemBuilder: (context, index) {
        final n = index + 1;
        return Center(
          child: Text(
            cell.notes.contains(n) ? '$n' : '',
            style: TextStyle(
              fontSize: 8,
              color: isDark ? Colors.white38 : Colors.black38,
            ),
          ),
        );
      },
    );
  }

  Color _getCellTextColor(SudokuCell cell, bool isSelected, bool isDark) {
    if (cell.isError) return Colors.redAccent;
    if (cell.isInitial) return isDark ? Colors.white : Colors.black;
    return isDark ? Colors.blueAccent : Colors.indigoAccent;
  }
}

class BoardPainter extends CustomPainter {
  final int? selectedRow;
  final int? selectedCol;
  final List<List<SudokuCell>> board;
  final bool isDark;

  BoardPainter({
    required this.selectedRow,
    required this.selectedCol,
    required this.board,
    required this.isDark,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final double cellSize = size.width / 9;
    final paint = Paint()..style = PaintingStyle.fill;

    // 1. Highlight selected row/col/box
    if (selectedRow != null && selectedCol != null) {
      paint.color = isDark
          ? Colors.blue.withOpacity(0.1)
          : Colors.blue.withOpacity(0.05);

      // Row highlight
      canvas.drawRect(
        Rect.fromLTWH(0, selectedRow! * cellSize, size.width, cellSize),
        paint,
      );

      // Col highlight
      canvas.drawRect(
        Rect.fromLTWH(selectedCol! * cellSize, 0, cellSize, size.height),
        paint,
      );

      // Box highlight
      final boxR = (selectedRow! ~/ 3) * 3;
      final boxC = (selectedCol! ~/ 3) * 3;
      canvas.drawRect(
        Rect.fromLTWH(
          boxC * cellSize,
          boxR * cellSize,
          cellSize * 3,
          cellSize * 3,
        ),
        paint,
      );

      // Same number highlight
      final selectedValue = board[selectedRow!][selectedCol!].value;
      if (selectedValue != 0) {
        paint.color = isDark
            ? Colors.blue.withOpacity(0.25)
            : Colors.blue.withOpacity(0.15);
        for (int r = 0; r < 9; r++) {
          for (int c = 0; c < 9; c++) {
            if (board[r][c].value == selectedValue &&
                (r != selectedRow || c != selectedCol)) {
              canvas.drawRect(
                Rect.fromLTWH(c * cellSize, r * cellSize, cellSize, cellSize),
                paint,
              );
            }
          }
        }
      }

      // Selected cell highlight (stronger)
      paint.color = isDark
          ? Colors.blue.withOpacity(0.4)
          : Colors.blue.withOpacity(0.25);
      canvas.drawRect(
        Rect.fromLTWH(
          selectedCol! * cellSize,
          selectedRow! * cellSize,
          cellSize,
          cellSize,
        ),
        paint,
      );
    }

    // 2. Draw Grid Lines
    final linePaint = Paint()
      ..color = isDark ? Colors.white10 : Colors.black12
      ..strokeWidth = 1;

    for (int i = 1; i < 9; i++) {
      if (i % 3 == 0) continue; // Bold lines later
      canvas.drawLine(
        Offset(i * cellSize, 0),
        Offset(i * cellSize, size.height),
        linePaint,
      );
      canvas.drawLine(
        Offset(0, i * cellSize),
        Offset(size.width, i * cellSize),
        linePaint,
      );
    }

    // 3. Draw Bold Lines (3x3 sections)
    linePaint.color = isDark ? Colors.white38 : Colors.black38;
    linePaint.strokeWidth = 2.5;
    for (int i = 3; i < 9; i += 3) {
      canvas.drawLine(
        Offset(i * cellSize, 0),
        Offset(i * cellSize, size.height),
        linePaint,
      );
      canvas.drawLine(
        Offset(0, i * cellSize),
        Offset(size.width, i * cellSize),
        linePaint,
      );
    }
  }

  @override
  bool shouldRepaint(BoardPainter oldDelegate) =>
      oldDelegate.selectedRow != selectedRow ||
      oldDelegate.selectedCol != selectedCol;
}
