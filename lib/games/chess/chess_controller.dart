import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'chess_logic.dart';
import '../../core/services/sound_service.dart';
import '../../core/services/haptic_service.dart';

enum GameMode { pvp, vsAI, practice, tournament, puzzle }

enum AIDifficulty { easy, medium, hard, pro }

class ChessController extends ChangeNotifier {
  late ChessBoard board;
  int? selectedRow;
  int? selectedCol;
  List<Offset> validMoves = [];
  bool isGameOver = false;
  String gameStatus = "";

  GameMode mode = GameMode.vsAI;
  AIDifficulty difficulty = AIDifficulty.medium;
  bool isThinking = false;
  Map<String, int>? pendingPromotion;
  final Map<String, int> _positionHistory = {};

  // Timers
  Timer? _gameTimer;
  int whiteTime = 600; // 10 minutes default
  int blackTime = 600;

  List<PieceType> whiteCaptures = [];
  List<PieceType> blackCaptures = [];

  final SoundService? soundService;
  final HapticService? hapticService;

  ChessController({this.soundService, this.hapticService}) {
    board = ChessBoard();
    board.initializeBoard();
  }

  int initialTime = 600;

  void initGame(
    GameMode mode, {
    AIDifficulty difficulty = AIDifficulty.medium,
    int? timeSeconds,
  }) {
    this.mode = mode;
    this.difficulty = difficulty;
    if (timeSeconds != null) {
      initialTime = timeSeconds;
    }
    reset();
  }

  void reset() {
    board = ChessBoard();
    board.initializeBoard();
    selectedRow = null;
    selectedCol = null;
    validMoves = [];
    isGameOver = false;
    gameStatus = "";
    whiteCaptures = [];
    blackCaptures = [];
    whiteTime = initialTime;
    blackTime = initialTime;
    isThinking = false;
    _positionHistory.clear();
    _stopTimer();
    _updatePositionHistory();
    if (mode != GameMode.practice) {
      _startTimer();
    }
    notifyListeners();
  }

  void _startTimer() {
    _gameTimer?.cancel();
    _gameTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (isGameOver) {
        timer.cancel();
        return;
      }
      if (board.turn == PlayerColor.white) {
        if (whiteTime > 0)
          whiteTime--;
        else
          _endGame("White out of time!");
      } else {
        if (blackTime > 0)
          blackTime--;
        else
          _endGame("Black out of time!");
      }
      notifyListeners();
    });
  }

  void _stopTimer() => _gameTimer?.cancel();

  void _endGame(String message) {
    isGameOver = true;
    gameStatus = message;
    _stopTimer();
    hapticService?.success();
    notifyListeners();
  }

  void onSquareTap(int r, int c) {
    if (isGameOver || isThinking) return;
    if (mode == GameMode.vsAI && board.turn == PlayerColor.black) return;

    if (selectedRow == r && selectedCol == c) {
      selectedRow = null;
      selectedCol = null;
      validMoves = [];
      notifyListeners();
      return;
    }

    if (selectedRow != null && selectedCol != null) {
      if (validMoves.any((m) => m.dx == r && m.dy == c)) {
        final piece = board.board[selectedRow!][selectedCol!];
        if (piece?.type == PieceType.pawn && (r == 0 || r == 7)) {
          pendingPromotion = {
            'fromR': selectedRow!,
            'fromC': selectedCol!,
            'toR': r,
            'toC': c,
          };
          notifyListeners();
          return;
        }
        makeMove(selectedRow!, selectedCol!, r, c);
        return;
      }
    }

    if (board.board[r][c]?.color == board.turn) {
      hapticService?.selectionClick();
      selectedRow = r;
      selectedCol = c;
      validMoves = board.getValidMoves(r, c);
      notifyListeners();
    }
  }

  void completePromotion(PieceType type) {
    if (pendingPromotion == null) return;
    makeMove(
      pendingPromotion!['fromR']!,
      pendingPromotion!['fromC']!,
      pendingPromotion!['toR']!,
      pendingPromotion!['toC']!,
      promoteTo: type,
    );
    pendingPromotion = null;
  }

  Future<void> makeMove(
    int fromR,
    int fromC,
    int toR,
    int toC, {
    PieceType? promoteTo,
  }) async {
    final targetPiece = board.board[toR][toC];
    final isCapture = targetPiece != null;

    // Logic for en passant capture detection
    final piece = board.board[fromR][fromC];
    final isEnPassant =
        piece?.type == PieceType.pawn && fromC != toC && targetPiece == null;

    if (isCapture) {
      if (targetPiece.color == PlayerColor.white) {
        blackCaptures.add(targetPiece.type);
      } else {
        whiteCaptures.add(targetPiece.type);
      }
    } else if (isEnPassant) {
      if (board.turn == PlayerColor.white) {
        whiteCaptures.add(PieceType.pawn);
      } else {
        blackCaptures.add(PieceType.pawn);
      }
    }

    board.move(fromR, fromC, toR, toC, promoteTo: promoteTo);
    selectedRow = null;
    selectedCol = null;
    validMoves = [];

    // Sound & Haptic
    if (isCapture || isEnPassant) {
      soundService?.playMoveSound('sounds/down_piece.mp3');
      hapticService?.medium();
    } else {
      soundService?.playMoveSound('sounds/move_piece.mp3');
      hapticService?.light();
    }

    _updatePositionHistory();
    _checkGameState();
    notifyListeners();

    if (!isGameOver &&
        mode == GameMode.vsAI &&
        board.turn == PlayerColor.black) {
      _triggerAIMove();
    }
  }

  void _checkGameState() {
    if (board.isCheckmate(board.turn)) {
      _endGame(
        "${board.turn == PlayerColor.white ? "Black" : "White"} won by Checkmate!",
      );
    } else if (board.isStalemate(board.turn)) {
      _endGame("Stalemate! Draw.");
    } else if (board.isCheck(board.turn)) {
      gameStatus = "Check!";
      // Using down_piece for check alert as check.mp3 is missing
      soundService?.playMoveSound('sounds/down_piece.mp3');
      hapticService?.heavy();
    } else if (_isThreefoldRepetition()) {
      _endGame("Draw by Repetition!");
    } else {
      gameStatus = "";
    }
  }

  void _updatePositionHistory() {
    String key = _getStateKey();
    _positionHistory[key] = (_positionHistory[key] ?? 0) + 1;
  }

  bool _isThreefoldRepetition() {
    return _positionHistory[_getStateKey()]! >= 3;
  }

  String _getStateKey() {
    StringBuffer sb = StringBuffer();
    sb.write("${board.turn.name}:");
    for (int r = 0; r < 8; r++) {
      for (int c = 0; c < 8; c++) {
        final p = board.board[r][c];
        if (p == null) {
          sb.write("0");
        } else {
          sb.write("${p.color.name[0]}${p.type.name[0]}");
        }
      }
    }
    return sb.toString();
  }

  Future<void> _triggerAIMove() async {
    isThinking = true;
    notifyListeners();

    // Simulate thinking time based on difficulty
    int delay = 500;
    switch (difficulty) {
      case AIDifficulty.easy:
        delay = 500;
        break;
      case AIDifficulty.medium:
        delay = 1200;
        break;
      case AIDifficulty.hard:
        delay = 2000;
        break;
      case AIDifficulty.pro:
        delay = 3000;
        break;
    }

    await Future.delayed(Duration(milliseconds: delay));

    if (isGameOver) return;

    final aiMove = _getBestMove();
    if (aiMove != null) {
      await makeMove(aiMove[0], aiMove[1], aiMove[2], aiMove[3]);
    }

    isThinking = false;
    notifyListeners();
  }

  List<int>? _getBestMove() {
    List<List<int>> allLegalMoves = [];
    for (int r = 0; r < 8; r++) {
      for (int c = 0; c < 8; c++) {
        if (board.board[r][c]?.color == PlayerColor.black) {
          var moves = board.getValidMoves(r, c);
          for (var m in moves) {
            allLegalMoves.add([r, c, m.dx.toInt(), m.dy.toInt()]);
          }
        }
      }
    }

    if (allLegalMoves.isEmpty) return null;

    // Simple heuristic-based AI
    if (difficulty == AIDifficulty.easy) {
      return allLegalMoves[Random().nextInt(allLegalMoves.length)];
    }

    // Prioritize captures and escape from check
    var captures = allLegalMoves
        .where((m) => board.board[m[2]][m[3]] != null)
        .toList();
    if (captures.isNotEmpty) {
      // Sort by piece value (if we had values)
      return captures[Random().nextInt(captures.length)];
    }

    return allLegalMoves[Random().nextInt(allLegalMoves.length)];
  }

  @override
  void dispose() {
    _gameTimer?.cancel();
    super.dispose();
  }
}
