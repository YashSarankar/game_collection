import 'package:flutter/material.dart';

enum PieceType { pawn, rook, knight, bishop, queen, king }

enum PlayerColor { white, black }

class ChessPiece {
  final PieceType type;
  final PlayerColor color;
  bool hasMoved;

  ChessPiece({required this.type, required this.color, this.hasMoved = false});

  ChessPiece copy() => ChessPiece(type: type, color: color, hasMoved: hasMoved);
}

class ChessMove {
  final int fromRow;
  final int fromCol;
  final int toRow;
  final int toCol;
  final ChessPiece pieceMoved;
  final ChessPiece? pieceCaptured;
  final bool isCastling;
  final bool isEnPassant;
  final PieceType? promotion;

  ChessMove({
    required this.fromRow,
    required this.fromCol,
    required this.toRow,
    required this.toCol,
    required this.pieceMoved,
    this.pieceCaptured,
    this.isCastling = false,
    this.isEnPassant = false,
    this.promotion,
  });
}

class ChessBoard {
  final List<List<ChessPiece?>> board;
  PlayerColor turn;
  ChessMove? lastMove;

  ChessBoard({List<List<ChessPiece?>>? board, this.turn = PlayerColor.white})
    : board = board ?? List.generate(8, (_) => List.generate(8, (_) => null));

  void initializeBoard() {
    // Pawns
    for (int i = 0; i < 8; i++) {
      board[1][i] = ChessPiece(type: PieceType.pawn, color: PlayerColor.black);
      board[6][i] = ChessPiece(type: PieceType.pawn, color: PlayerColor.white);
    }

    // Rooks
    board[0][0] = ChessPiece(type: PieceType.rook, color: PlayerColor.black);
    board[0][7] = ChessPiece(type: PieceType.rook, color: PlayerColor.black);
    board[7][0] = ChessPiece(type: PieceType.rook, color: PlayerColor.white);
    board[7][7] = ChessPiece(type: PieceType.rook, color: PlayerColor.white);

    // Knights
    board[0][1] = ChessPiece(type: PieceType.knight, color: PlayerColor.black);
    board[0][6] = ChessPiece(type: PieceType.knight, color: PlayerColor.black);
    board[7][1] = ChessPiece(type: PieceType.knight, color: PlayerColor.white);
    board[7][6] = ChessPiece(type: PieceType.knight, color: PlayerColor.white);

    // Bishops
    board[0][2] = ChessPiece(type: PieceType.bishop, color: PlayerColor.black);
    board[0][5] = ChessPiece(type: PieceType.bishop, color: PlayerColor.black);
    board[7][2] = ChessPiece(type: PieceType.bishop, color: PlayerColor.white);
    board[7][5] = ChessPiece(type: PieceType.bishop, color: PlayerColor.white);

    // Queens
    board[0][3] = ChessPiece(type: PieceType.queen, color: PlayerColor.black);
    board[7][3] = ChessPiece(type: PieceType.queen, color: PlayerColor.white);

    // Kings
    board[0][4] = ChessPiece(type: PieceType.king, color: PlayerColor.black);
    board[7][4] = ChessPiece(type: PieceType.king, color: PlayerColor.white);
  }

  bool isInBoard(int r, int c) => r >= 0 && r < 8 && c >= 0 && c < 8;

  List<Offset> getValidMoves(int r, int c) {
    ChessPiece? piece = board[r][c];
    if (piece == null || piece.color != turn) return [];

    List<Offset> rawMoves = _getRawMoves(r, c);
    List<Offset> legalMoves = [];

    for (var move in rawMoves) {
      if (_isMoveLegal(r, c, move.dx.toInt(), move.dy.toInt())) {
        legalMoves.add(move);
      }
    }

    // Special moves
    if (piece.type == PieceType.king) {
      legalMoves.addAll(_getCastlingMoves(r, c));
    }
    if (piece.type == PieceType.pawn) {
      legalMoves.addAll(_getEnPassantMoves(r, c));
    }

    return legalMoves;
  }

  List<Offset> _getRawMoves(int r, int c) {
    ChessPiece piece = board[r][c]!;
    List<Offset> moves = [];

    switch (piece.type) {
      case PieceType.pawn:
        int dir = piece.color == PlayerColor.white ? -1 : 1;
        // Forward
        if (isInBoard(r + dir, c) && board[r + dir][c] == null) {
          moves.add(Offset((r + dir).toDouble(), c.toDouble()));
          // First move 2 squares
          if ((piece.color == PlayerColor.white && r == 6) ||
              (piece.color == PlayerColor.black && r == 1)) {
            if (board[r + dir * 2][c] == null) {
              moves.add(Offset((r + dir * 2).toDouble(), c.toDouble()));
            }
          }
        }
        // Capture
        for (int dc in [-1, 1]) {
          if (isInBoard(r + dir, c + dc)) {
            ChessPiece? target = board[r + dir][c + dc];
            if (target != null && target.color != piece.color) {
              moves.add(Offset((r + dir).toDouble(), (c + dc).toDouble()));
            }
          }
        }
        break;

      case PieceType.rook:
        _addLinearMoves(moves, r, c, [
          [1, 0],
          [-1, 0],
          [0, 1],
          [0, -1],
        ]);
        break;

      case PieceType.bishop:
        _addLinearMoves(moves, r, c, [
          [1, 1],
          [1, -1],
          [-1, 1],
          [-1, -1],
        ]);
        break;

      case PieceType.knight:
        List<List<int>> jumps = [
          [2, 1],
          [2, -1],
          [-2, 1],
          [-2, -1],
          [1, 2],
          [1, -2],
          [-1, 2],
          [-1, -2],
        ];
        for (var j in jumps) {
          int nr = r + j[0];
          int nc = c + j[1];
          if (isInBoard(nr, nc)) {
            if (board[nr][nc] == null || board[nr][nc]!.color != piece.color) {
              moves.add(Offset(nr.toDouble(), nc.toDouble()));
            }
          }
        }
        break;

      case PieceType.queen:
        _addLinearMoves(moves, r, c, [
          [1, 0],
          [-1, 0],
          [0, 1],
          [0, -1],
          [1, 1],
          [1, -1],
          [-1, 1],
          [-1, -1],
        ]);
        break;

      case PieceType.king:
        for (int dr = -1; dr <= 1; dr++) {
          for (int dc = -1; dc <= 1; dc++) {
            if (dr == 0 && dc == 0) continue;
            int nr = r + dr;
            int nc = c + dc;
            if (isInBoard(nr, nc)) {
              if (board[nr][nc] == null ||
                  board[nr][nc]!.color != piece.color) {
                moves.add(Offset(nr.toDouble(), nc.toDouble()));
              }
            }
          }
        }
        break;
    }

    return moves;
  }

  void _addLinearMoves(List<Offset> moves, int r, int c, List<List<int>> dirs) {
    ChessPiece piece = board[r][c]!;
    for (var d in dirs) {
      int nr = r + d[0];
      int nc = c + d[1];
      while (isInBoard(nr, nc)) {
        if (board[nr][nc] == null) {
          moves.add(Offset(nr.toDouble(), nc.toDouble()));
        } else {
          if (board[nr][nc]!.color != piece.color) {
            moves.add(Offset(nr.toDouble(), nc.toDouble()));
          }
          break;
        }
        nr += d[0];
        nc += d[1];
      }
    }
  }

  bool _isMoveLegal(int fromR, int fromC, int toR, int toC) {
    ChessPiece? movedPiece = board[fromR][fromC];
    ChessPiece? capturedPiece = board[toR][toC];

    // Simulate
    board[toR][toC] = movedPiece;
    board[fromR][fromC] = null;

    bool isSafe = !isCheck(movedPiece!.color);

    // Revert
    board[fromR][fromC] = movedPiece;
    board[toR][toC] = capturedPiece;

    return isSafe;
  }

  bool isCheck(PlayerColor color) {
    // Find King
    int kr = -1, kc = -1;
    for (int r = 0; r < 8; r++) {
      for (int c = 0; c < 8; c++) {
        if (board[r][c]?.type == PieceType.king &&
            board[r][c]?.color == color) {
          kr = r;
          kc = c;
          break;
        }
      }
    }

    // Check if any opponent piece can hit kr, kc
    PlayerColor opponent = color == PlayerColor.white
        ? PlayerColor.black
        : PlayerColor.white;
    for (int r = 0; r < 8; r++) {
      for (int c = 0; c < 8; c++) {
        if (board[r][c]?.color == opponent) {
          // Special case for pawns since they capture diagonally
          if (board[r][c]?.type == PieceType.pawn) {
            int dir = opponent == PlayerColor.white ? -1 : 1;
            if (r + dir == kr && (c - 1 == kc || c + 1 == kc)) return true;
          } else {
            // Use _getRawMoves to see if they can land on kr, kc
            // Note: _getRawMoves doesn't filter by king safety, which is correct here
            if (_getRawMoves(
              r,
              c,
            ).contains(Offset(kr.toDouble(), kc.toDouble()))) {
              return true;
            }
          }
        }
      }
    }
    return false;
  }

  void move(int fromR, int fromC, int toR, int toC, {PieceType? promoteTo}) {
    ChessPiece piece = board[fromR][fromC]!;

    // Check for castling
    bool isCastling = piece.type == PieceType.king && (toC - fromC).abs() == 2;
    if (isCastling) {
      int rookFromC = (toC > fromC) ? 7 : 0;
      int rookToC = (toC > fromC) ? 5 : 3;
      board[toR][rookToC] = board[toR][rookFromC];
      board[toR][rookFromC] = null;
      board[toR][rookToC]!.hasMoved = true;
    }

    // Check for en passant
    bool isEnPassant =
        piece.type == PieceType.pawn && fromC != toC && board[toR][toC] == null;
    if (isEnPassant) {
      board[fromR][toC] = null;
    }

    lastMove = ChessMove(
      fromRow: fromR,
      fromCol: fromC,
      toRow: toR,
      toCol: toC,
      pieceMoved: piece,
      pieceCaptured: board[toR][toC],
      isCastling: isCastling,
      isEnPassant: isEnPassant,
      promotion: promoteTo,
    );

    board[toR][toC] = piece;
    board[fromR][fromC] = null;
    piece.hasMoved = true;

    // Promotion
    if (piece.type == PieceType.pawn && (toR == 0 || toR == 7)) {
      board[toR][toC] = ChessPiece(
        type: promoteTo ?? PieceType.queen,
        color: piece.color,
        hasMoved: true,
      );
    }

    turn = turn == PlayerColor.white ? PlayerColor.black : PlayerColor.white;
  }

  List<Offset> _getCastlingMoves(int r, int c) {
    List<Offset> moves = [];
    ChessPiece king = board[r][c]!;
    if (king.hasMoved || isCheck(king.color)) return [];

    // Kingside
    if (board[r][7]?.type == PieceType.rook && !board[r][7]!.hasMoved) {
      if (board[r][5] == null && board[r][6] == null) {
        if (_isMoveLegal(r, c, r, 5) && _isMoveLegal(r, c, r, 6)) {
          moves.add(Offset(r.toDouble(), 6));
        }
      }
    }
    // Queenside
    if (board[r][0]?.type == PieceType.rook && !board[r][0]!.hasMoved) {
      if (board[r][1] == null && board[r][2] == null && board[r][3] == null) {
        if (_isMoveLegal(r, c, r, 3) && _isMoveLegal(r, c, r, 2)) {
          moves.add(Offset(r.toDouble(), 2));
        }
      }
    }
    return moves;
  }

  List<Offset> _getEnPassantMoves(int r, int c) {
    List<Offset> moves = [];
    if (lastMove == null) return [];
    ChessPiece pawn = board[r][c]!;

    if (lastMove!.pieceMoved.type == PieceType.pawn &&
        (lastMove!.toRow - lastMove!.fromRow).abs() == 2) {
      if (lastMove!.toRow == r && (lastMove!.toCol - c).abs() == 1) {
        int dir = pawn.color == PlayerColor.white ? -1 : 1;
        moves.add(Offset((r + dir).toDouble(), lastMove!.toCol.toDouble()));
      }
    }
    return moves;
  }

  bool isCheckmate(PlayerColor color) {
    if (!isCheck(color)) return false;
    return _hasNoLegalMoves(color);
  }

  bool isStalemate(PlayerColor color) {
    if (isCheck(color)) return false;
    return _hasNoLegalMoves(color);
  }

  bool _hasNoLegalMoves(PlayerColor color) {
    for (int r = 0; r < 8; r++) {
      for (int c = 0; c < 8; c++) {
        if (board[r][c]?.color == color) {
          if (getValidMoves(r, c).isNotEmpty) return false;
        }
      }
    }
    return true;
  }
}
