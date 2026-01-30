import 'package:flutter/material.dart';

enum Player { none, player1, player2 }

enum GamePhase { placement, movement, flying, gameOver }

class NineMensMorrisLogic extends ChangeNotifier {
  List<Player> board = List.generate(24, (_) => Player.none);
  Player currentPlayer = Player.player1;
  GamePhase phase = GamePhase.placement;

  int p1PiecesToPlace = 9;
  int p2PiecesToPlace = 9;
  int p1PiecesOnBoard = 0;
  int p2PiecesOnBoard = 0;

  int? selectedIndex;
  bool awaitingRemoval = false;
  String message = "Player 1: Place a piece";

  // Define the 24 points and their connections
  // Indices:
  // Outer Square: 0 (TL), 1 (TM), 2 (TR), 3 (MR), 4 (BR), 5 (BM), 6 (BL), 7 (ML)
  // Middle Square: 8 (TL), 9 (TM), 10 (TR), 11 (MR), 12 (BR), 13 (BM), 14 (BL), 15 (ML)
  // Inner Square: 16 (TL), 17 (TM), 18 (TR), 19 (MR), 20 (BR), 21 (BM), 22 (BL), 23 (ML)

  static const List<List<int>> adjacents = [
    [1, 7], // 0
    [0, 2, 9], // 1
    [1, 3], // 2
    [2, 4, 11], // 3
    [3, 5], // 4
    [4, 6, 13], // 5
    [5, 7], // 6
    [0, 6, 15], // 7
    [9, 15], // 8
    [1, 8, 10, 17], // 9
    [9, 11], // 10
    [3, 10, 12, 19], // 11
    [11, 13], // 12
    [5, 12, 14, 21], // 13
    [13, 15], // 14
    [7, 8, 14, 23], // 15
    [17, 23], // 16
    [9, 16, 18], // 17
    [17, 19], // 18
    [11, 18, 20], // 19
    [19, 21], // 20
    [13, 20, 22], // 21
    [21, 23], // 22
    [15, 16, 22], // 23
  ];

  static const List<List<int>> mills = [
    [0, 1, 2], [8, 9, 10], [16, 17, 18], // Top rows
    [7, 15, 23], [19, 11, 3], // Middle rows (horiz)
    [22, 21, 20], [14, 13, 12], [6, 5, 4], // Bottom rows
    [0, 7, 6], [8, 15, 14], [16, 23, 22], // Left columns
    [1, 9, 17], [21, 13, 5], // Middle columns (vert)
    [2, 3, 4], [10, 11, 12], [18, 19, 20], // Right columns
  ];

  void handleTap(int index) {
    if (phase == GamePhase.gameOver) return;

    if (awaitingRemoval) {
      _handleRemoval(index);
    } else if (phase == GamePhase.placement) {
      _handlePlacement(index);
    } else {
      _handleMovement(index);
    }
    notifyListeners();
  }

  void _handlePlacement(int index) {
    if (board[index] != Player.none) return;

    board[index] = currentPlayer;
    if (currentPlayer == Player.player1) {
      p1PiecesToPlace--;
      p1PiecesOnBoard++;
    } else {
      p2PiecesToPlace--;
      p2PiecesOnBoard++;
    }

    if (_isMill(index, currentPlayer)) {
      awaitingRemoval = true;
      message = "Mill formed! Remove an opponent's piece.";
    } else {
      _togglePlayer();
    }

    if (p1PiecesToPlace == 0 && p2PiecesToPlace == 0 && !awaitingRemoval) {
      if (phase == GamePhase.placement) {
        phase = GamePhase.movement;
      }
    }
    _checkGameOver();
  }

  void _handleMovement(int index) {
    if (selectedIndex == null) {
      if (board[index] == currentPlayer) {
        selectedIndex = index;
        message = "Select destination";
      }
    } else {
      if (index == selectedIndex) {
        selectedIndex = null;
        message = "Select a piece to move";
        return;
      }

      if (board[index] != Player.none) {
        if (board[index] == currentPlayer) {
          selectedIndex = index;
        }
        return;
      }

      bool isFlying =
          (currentPlayer == Player.player1 && p1PiecesOnBoard == 3) ||
          (currentPlayer == Player.player2 && p2PiecesOnBoard == 3);

      if (isFlying || adjacents[selectedIndex!].contains(index)) {
        board[index] = currentPlayer;
        board[selectedIndex!] = Player.none;
        selectedIndex = null;

        if (_isMill(index, currentPlayer)) {
          awaitingRemoval = true;
          message = "Mill formed! Remove an opponent's piece.";
        } else {
          _togglePlayer();
        }
        _checkGameOver();
      }
    }
  }

  void _handleRemoval(int index) {
    Player opponent = currentPlayer == Player.player1
        ? Player.player2
        : Player.player1;
    if (board[index] != opponent) return;

    // Standard rule: Cannot remove from a mill unless all are in mills
    if (_isMill(index, opponent)) {
      bool allInMills = true;
      for (int i = 0; i < 24; i++) {
        if (board[i] == opponent && !_isMill(i, opponent)) {
          allInMills = false;
          break;
        }
      }
      if (!allInMills) {
        message = "Cannot remove from a mill!";
        return;
      }
    }

    board[index] = Player.none;
    if (opponent == Player.player1) {
      p1PiecesOnBoard--;
    } else {
      p2PiecesOnBoard--;
    }

    awaitingRemoval = false;

    if (p1PiecesToPlace == 0 && p2PiecesToPlace == 0) {
      if (phase == GamePhase.placement) {
        phase = GamePhase.movement;
      }
    }

    _togglePlayer();
    _checkGameOver();
  }

  void _togglePlayer() {
    currentPlayer = currentPlayer == Player.player1
        ? Player.player2
        : Player.player1;
    message =
        "${currentPlayer == Player.player1 ? 'Player 1' : 'Player 2'}'s turn";

    // Update phase if flying
    if (p1PiecesToPlace == 0 && p2PiecesToPlace == 0) {
      if (currentPlayer == Player.player1 && p1PiecesOnBoard == 3) {
        phase = GamePhase.flying;
      } else if (currentPlayer == Player.player2 && p2PiecesOnBoard == 3) {
        phase = GamePhase.flying;
      } else {
        phase = GamePhase.movement;
      }
    }
  }

  bool _isMill(int index, Player player) {
    for (var mill in mills) {
      if (mill.contains(index)) {
        if (board[mill[0]] == player &&
            board[mill[1]] == player &&
            board[mill[2]] == player) {
          return true;
        }
      }
    }
    return false;
  }

  void _checkGameOver() {
    // If a player has no pieces left at any point, they lose
    if (p1PiecesOnBoard == 0 && p1PiecesToPlace == 0) {
      phase = GamePhase.gameOver;
      message = "Player 2 Wins!";
      return;
    }
    if (p2PiecesOnBoard == 0 && p2PiecesToPlace == 0) {
      phase = GamePhase.gameOver;
      message = "Player 1 Wins!";
      return;
    }

    // Traditional Nine Men's Morris win conditions (after placement)
    if (p1PiecesToPlace == 0 && p2PiecesToPlace == 0) {
      if (p1PiecesOnBoard < 3) {
        phase = GamePhase.gameOver;
        message = "Player 2 Wins!";
      } else if (p2PiecesOnBoard < 3) {
        phase = GamePhase.gameOver;
        message = "Player 1 Wins!";
      } else if (!_hasLegalMoves(currentPlayer)) {
        phase = GamePhase.gameOver;
        message =
            "${currentPlayer == Player.player1 ? 'Player 2' : 'Player 1'} Wins! (No moves)";
      }
    }
  }

  bool _hasLegalMoves(Player player) {
    bool isFlying =
        (player == Player.player1 && p1PiecesOnBoard == 3) ||
        (player == Player.player2 && p2PiecesOnBoard == 3);
    if (isFlying) return true; // Can always fly if there's an empty space

    for (int i = 0; i < 24; i++) {
      if (board[i] == player) {
        for (int neighbor in adjacents[i]) {
          if (board[neighbor] == Player.none) return true;
        }
      }
    }
    return false;
  }

  void reset() {
    board = List.generate(24, (_) => Player.none);
    currentPlayer = Player.player1;
    phase = GamePhase.placement;
    p1PiecesToPlace = 9;
    p2PiecesToPlace = 9;
    p1PiecesOnBoard = 0;
    p2PiecesOnBoard = 0;
    selectedIndex = null;
    awaitingRemoval = false;
    message = "Player 1: Place a piece";
    notifyListeners();
  }
}
