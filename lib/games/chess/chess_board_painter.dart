import 'package:flutter/material.dart';
import 'chess_theme.dart';
import 'chess_logic.dart';

class ChessBoardPainter extends CustomPainter {
  final ChessBoard board;
  final ChessTheme theme;
  final int? selectedRow;
  final int? selectedCol;
  final List<Offset> validMoves;

  ChessBoardPainter({
    required this.board,
    required this.theme,
    this.selectedRow,
    this.selectedCol,
    required this.validMoves,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final squareSize = size.width / 8;
    final paint = Paint();

    // Draw board outer shadow/depth
    final outerRect = Rect.fromLTWH(-4, -4, size.width + 8, size.height + 8);
    canvas.drawRRect(
      RRect.fromRectAndRadius(outerRect, const Radius.circular(8)),
      Paint()
        ..color = Colors.black.withOpacity(0.3)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4),
    );

    for (int r = 0; r < 8; r++) {
      for (int c = 0; c < 8; c++) {
        final isDark = (r + c) % 2 != 0;
        final rect = Rect.fromLTWH(
          c * squareSize,
          r * squareSize,
          squareSize,
          squareSize,
        );

        // Base square color
        paint.color = isDark ? theme.darkSquare : theme.lightSquare;
        canvas.drawRect(rect, paint);

        // Last move highlight
        if (board.lastMove != null) {
          if ((board.lastMove!.fromRow == r && board.lastMove!.fromCol == c) ||
              (board.lastMove!.toRow == r && board.lastMove!.toCol == c)) {
            canvas.drawRect(rect, Paint()..color = theme.lastMove);
          }
        }

        // Selected square highlight
        if (selectedRow == r && selectedCol == c) {
          canvas.drawRect(
            rect,
            Paint()..color = theme.highlightMove.withOpacity(0.3),
          );
        }

        // King in check glow
        final piece = board.board[r][c];
        if (piece?.type == PieceType.king && board.isCheck(piece!.color)) {
          final center = Offset(
            c * squareSize + squareSize / 2,
            r * squareSize + squareSize / 2,
          );
          canvas.drawCircle(
            center,
            squareSize * 0.4,
            Paint()
              ..color = theme.checkGlow
              ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8),
          );
        }

        // Draw labels (only on edges)
        if (c == 0) {
          _drawText(
            canvas,
            '${8 - r}',
            Offset(2, r * squareSize + 2),
            theme.labelStyle,
          );
        }
        if (r == 7) {
          _drawText(
            canvas,
            String.fromCharCode(97 + c),
            Offset((c + 1) * squareSize - 12, size.height - 15),
            theme.labelStyle,
          );
        }
      }
    }

    // Draw valid moves indicators
    for (var move in validMoves) {
      final r = move.dx.toInt();
      final c = move.dy.toInt();
      final center = Offset(
        c * squareSize + squareSize / 2,
        r * squareSize + squareSize / 2,
      );

      if (board.board[r][c] != null) {
        // Capture indicator (ring)
        canvas.drawCircle(
          center,
          squareSize * 0.35,
          Paint()
            ..color = theme.highlightMove
            ..style = PaintingStyle.stroke
            ..strokeWidth = 3,
        );
      } else {
        // Move indicator (dot)
        canvas.drawCircle(
          center,
          squareSize * 0.12,
          Paint()..color = theme.highlightMove,
        );
      }
    }
  }

  void _drawText(Canvas canvas, String text, Offset position, TextStyle style) {
    final tp = TextPainter(
      text: TextSpan(text: text, style: style),
      textDirection: TextDirection.ltr,
    );
    tp.layout();
    tp.paint(canvas, position);
  }

  @override
  bool shouldRepaint(covariant ChessBoardPainter oldDelegate) {
    return oldDelegate.board != board ||
        oldDelegate.selectedRow != selectedRow ||
        oldDelegate.selectedCol != selectedCol ||
        oldDelegate.validMoves != validMoves ||
        oldDelegate.theme != theme;
  }
}
