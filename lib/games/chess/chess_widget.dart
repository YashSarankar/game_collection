import 'dart:async';
import 'package:flutter/material.dart';
import '../../core/models/game_model.dart';
import '../../core/services/haptic_service.dart';
import '../../ui/widgets/game_over_dialog.dart';
import '../../ui/widgets/game_countdown.dart';
import 'chess_logic.dart';

class ChessWidget extends StatefulWidget {
  final GameModel game;
  const ChessWidget({super.key, required this.game});

  @override
  State<ChessWidget> createState() => _ChessWidgetState();
}

class _ChessWidgetState extends State<ChessWidget> {
  late ChessBoard chessBoard;
  int? selectedRow;
  int? selectedCol;
  List<Offset> validMoves = [];
  bool isGameOver = false;
  String gameStatus = "";

  // Game Modes
  bool _isVsAI = false;
  bool _isPractice = false;
  bool _isGameStarted = false;
  bool _isCounting = false;

  // Timer state
  Timer? _gameTimer;
  int _whiteTime = 300; // 5 minutes in seconds
  int _blackTime = 300;

  HapticService? _hapticService;

  @override
  void initState() {
    super.initState();
    _initHaptic();
    _resetBoard();
  }

  @override
  void dispose() {
    _gameTimer?.cancel();
    super.dispose();
  }

  Future<void> _initHaptic() async {
    _hapticService = await HapticService.getInstance();
  }

  void _resetBoard() {
    chessBoard = ChessBoard();
    chessBoard.initializeBoard();
    selectedRow = null;
    selectedCol = null;
    validMoves = [];
    isGameOver = false;
    gameStatus = "";

    _gameTimer?.cancel();
    _whiteTime = 300;
    _blackTime = 300;

    if (_isGameStarted && !_isVsAI && !_isPractice && !_isCounting) {
      _startTimer();
    }

    if (mounted) setState(() {});
  }

  void _startTimer() {
    _gameTimer?.cancel();
    _gameTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted || isGameOver) {
        timer.cancel();
        return;
      }

      if (mounted) {
        setState(() {
          if (chessBoard.turn == PlayerColor.white) {
            _whiteTime--;
            if (_whiteTime <= 0) {
              isGameOver = true;
              gameStatus = "WHITE OUT OF TIME! BLACK WINS";
              _gameTimer?.cancel();
              _showGameOverDialog();
            }
          } else {
            _blackTime--;
            if (_blackTime <= 0) {
              isGameOver = true;
              gameStatus = "BLACK OUT OF TIME! WHITE WINS";
              _gameTimer?.cancel();
              _showGameOverDialog();
            }
          }
        });
      }
    });
  }

  String _formatTime(int seconds) {
    int mins = seconds ~/ 60;
    int secs = seconds % 60;
    return "$mins:${secs.toString().padLeft(2, '0')}";
  }

  void _onSquareTap(int r, int c) {
    if (isGameOver || (_isVsAI && chessBoard.turn == PlayerColor.black)) return;

    if (selectedRow == r && selectedCol == c) {
      setState(() {
        selectedRow = null;
        selectedCol = null;
        validMoves = [];
      });
      return;
    }

    if (selectedRow != null && selectedCol != null) {
      // Try to move
      if (validMoves.any((m) => m.dx == r && m.dy == c)) {
        _makeMove(selectedRow!, selectedCol!, r, c);
        return;
      }
    }

    // Select piece
    if (chessBoard.board[r][c]?.color == chessBoard.turn) {
      _hapticService?.selectionClick();
      setState(() {
        selectedRow = r;
        selectedCol = c;
        validMoves = chessBoard.getValidMoves(r, c);
      });
    }
  }

  void _makeMove(int fromR, int fromC, int toR, int toC) {
    _hapticService?.light();

    // Check for promotion (default to queen for simplicity in this UI version)
    PieceType? promoteTo;
    if (chessBoard.board[fromR][fromC]?.type == PieceType.pawn &&
        (toR == 0 || toR == 7)) {
      promoteTo = PieceType.queen;
    }

    setState(() {
      chessBoard.move(fromR, fromC, toR, toC, promoteTo: promoteTo);
      selectedRow = null;
      selectedCol = null;
      validMoves = [];
      _checkGameState();
    });

    if (!isGameOver && _isVsAI && chessBoard.turn == PlayerColor.black) {
      // AI Move
      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted) _makeAIMove();
      });
    }
  }

  void _makeAIMove() {
    if (isGameOver) return;

    // Basic AI: Random move for now, but we can improve it
    List<List<int>> allLegalMoves = [];
    for (int r = 0; r < 8; r++) {
      for (int c = 0; c < 8; c++) {
        if (chessBoard.board[r][c]?.color == PlayerColor.black) {
          var moves = chessBoard.getValidMoves(r, c);
          for (var m in moves) {
            allLegalMoves.add([r, c, m.dx.toInt(), m.dy.toInt()]);
          }
        }
      }
    }

    if (allLegalMoves.isNotEmpty) {
      // Prioritize captures
      var captures = allLegalMoves
          .where((m) => chessBoard.board[m[2]][m[3]] != null)
          .toList();
      var finalMove = (captures.isNotEmpty)
          ? captures[DateTime.now().millisecond % captures.length]
          : allLegalMoves[DateTime.now().millisecond % allLegalMoves.length];

      _makeMove(finalMove[0], finalMove[1], finalMove[2], finalMove[3]);
    }
  }

  void _checkGameState() {
    if (chessBoard.isCheckmate(chessBoard.turn)) {
      isGameOver = true;
      gameStatus =
          "CHECKMATE! ${chessBoard.turn == PlayerColor.white ? "BLACK" : "WHITE"} WINS";
      _showGameOverDialog();
    } else if (chessBoard.isStalemate(chessBoard.turn)) {
      isGameOver = true;
      gameStatus = "STALEMATE! DRAW";
      _showGameOverDialog();
    } else if (chessBoard.isCheck(chessBoard.turn)) {
      gameStatus = "CHECK!";
    } else {
      gameStatus = "";
    }
  }

  void _showGameOverDialog() {
    _hapticService?.success();
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => GameOverDialog(
        gameId: widget.game.id,
        score: chessBoard.turn == PlayerColor.black
            ? 1000
            : 0, // Simplified score
        customMessage: gameStatus,
        onRestart: () {
          Navigator.pop(context);
          _resetBoard();
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
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    if (!_isGameStarted) return _buildStartScreen(isDark);

    if (_isCounting) {
      return Scaffold(
        backgroundColor: Colors.black,
        body: GameCountdown(
          onFinished: () {
            setState(() {
              _isCounting = false;
              if (!_isPractice && !_isVsAI) {
                _startTimer();
              }
            });
          },
        ),
      );
    }

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          widget.game.title,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: isDark ? Colors.white : Colors.black,
        leading: IconButton(
          icon: const Icon(Icons.menu),
          onPressed: () => setState(() => _isGameStarted = false),
        ),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _resetBoard),
        ],
      ),
      body: Column(
        children: [
          _buildInfoBar(isDark),
          Expanded(child: Center(child: _buildBoard())),
          _buildTurnIndicator(isDark),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildStartScreen(bool isDark) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.grid_4x4_rounded,
                size: 80,
                color: widget.game.primaryColor,
              ),
              const SizedBox(height: 24),
              const Text(
                'CHESS',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 4,
                ),
              ),
              const SizedBox(height: 40),
              _buildMenuButton("PLAYER VS PLAYER", () {
                setState(() {
                  _isVsAI = false;
                  _isPractice = false;
                  _isGameStarted = true;
                  _isCounting = true;
                  _resetBoard();
                });
              }, isDark),
              const SizedBox(height: 12),
              _buildMenuButton("PLAYER VS AI", () {
                setState(() {
                  _isVsAI = true;
                  _isPractice = false;
                  _isGameStarted = true;
                  _isCounting = true;
                  _resetBoard();
                });
              }, isDark),
              const SizedBox(height: 12),
              _buildMenuButton("PRACTICE MODE", () {
                setState(() {
                  _isVsAI = false;
                  _isPractice = true;
                  _isGameStarted = true;
                  _isCounting = true;
                  _resetBoard();
                });
              }, isDark),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMenuButton(String label, VoidCallback onTap, bool isDark) {
    return SizedBox(
      width: double.infinity,
      height: 60,
      child: ElevatedButton(
        onPressed: onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: isDark ? Colors.white10 : Colors.grey[200],
          foregroundColor: isDark ? Colors.white : Colors.black87,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: 0,
        ),
        child: Text(
          label,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  Widget _buildInfoBar(bool isDark) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            gameStatus,
            style: const TextStyle(
              color: Colors.redAccent,
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: widget.game.primaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              _isVsAI ? "VS AI" : "PVP",
              style: TextStyle(
                color: widget.game.primaryColor,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          if (!_isPractice && !_isVsAI)
            Row(
              children: [
                _buildClock(_whiteTime, Colors.white, Colors.black),
                const SizedBox(width: 8),
                _buildClock(_blackTime, Colors.black, Colors.white),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildClock(int seconds, Color bgColor, Color textColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: Colors.grey.withOpacity(0.5)),
      ),
      child: Text(
        _formatTime(seconds),
        style: TextStyle(
          color: textColor,
          fontWeight: FontWeight.bold,
          fontFamily: 'monospace',
          fontSize: 14,
        ),
      ),
    );
  }

  Widget _buildTurnIndicator(bool isDark) {
    bool isWhiteTurn = chessBoard.turn == PlayerColor.white;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
      decoration: BoxDecoration(
        color: isWhiteTurn ? Colors.white : Colors.black,
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: Colors.grey.withOpacity(0.3)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Text(
        isWhiteTurn ? "WHITE'S TURN" : "BLACK'S TURN",
        style: TextStyle(
          color: isWhiteTurn ? Colors.black : Colors.white,
          fontWeight: FontWeight.bold,
          letterSpacing: 2,
        ),
      ),
    );
  }

  Widget _buildBoard() {
    double size = MediaQuery.of(context).size.width - 32;

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        border: Border.all(color: Colors.brown[700]!, width: 4),
        borderRadius: BorderRadius.circular(4),
      ),
      child: GridView.builder(
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 8,
        ),
        itemCount: 64,
        itemBuilder: (context, index) {
          int r = index ~/ 8;
          int c = index % 8;
          bool isSelected = selectedRow == r && selectedCol == c;
          bool isValidMove = validMoves.any((m) => m.dx == r && m.dy == c);
          bool isDarkSquare = (r + c) % 2 != 0;

          return GestureDetector(
            onTap: () => _onSquareTap(r, c),
            child: Container(
              color: _getSquareColor(
                r,
                c,
                isSelected,
                isValidMove,
                isDarkSquare,
              ),
              child: Stack(
                children: [
                  if (isValidMove)
                    Center(
                      child: Container(
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                          color: (chessBoard.board[r][c] != null)
                              ? Colors.red.withOpacity(0.3)
                              : Colors.black.withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                  _buildPiece(r, c),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Color _getSquareColor(
    int r,
    int c,
    bool isSelected,
    bool isValidMove,
    bool isDark,
  ) {
    if (isSelected) return Colors.yellow.withOpacity(0.5);

    // Highlight last move
    if (chessBoard.lastMove != null) {
      if ((chessBoard.lastMove!.fromRow == r &&
              chessBoard.lastMove!.fromCol == c) ||
          (chessBoard.lastMove!.toRow == r &&
              chessBoard.lastMove!.toCol == c)) {
        return Colors.yellow.withOpacity(0.3);
      }
    }

    return isDark ? const Color(0xFFB58863) : const Color(0xFFF0D9B5);
  }

  Widget _buildPiece(int r, int c) {
    ChessPiece? piece = chessBoard.board[r][c];
    if (piece == null) return const SizedBox.shrink();

    String icon = _getPieceIcon(piece.type, piece.color);
    Color color = piece.color == PlayerColor.white
        ? Colors.white
        : Colors.black;

    double fontSize = 36;
    if (piece.type == PieceType.pawn) {
      fontSize = piece.color == PlayerColor.black ? 26 : 32;
    }

    return Center(
      child: Text(
        icon,
        style: TextStyle(
          fontSize: fontSize,
          color: color,
          shadows: [
            Shadow(
              color: piece.color == PlayerColor.white
                  ? Colors.black26
                  : Colors.white12,
              blurRadius: 2,
              offset: const Offset(1, 1),
            ),
          ],
        ),
      ),
    );
  }

  String _getPieceIcon(PieceType type, PlayerColor color) {
    if (color == PlayerColor.white) {
      switch (type) {
        case PieceType.pawn:
          return '♙';
        case PieceType.rook:
          return '♖';
        case PieceType.knight:
          return '♘';
        case PieceType.bishop:
          return '♗';
        case PieceType.queen:
          return '♕';
        case PieceType.king:
          return '♔';
      }
    } else {
      switch (type) {
        case PieceType.pawn:
          return '♟';
        case PieceType.rook:
          return '♜';
        case PieceType.knight:
          return '♞';
        case PieceType.bishop:
          return '♝';
        case PieceType.queen:
          return '♛';
        case PieceType.king:
          return '♚';
      }
    }
  }
}
