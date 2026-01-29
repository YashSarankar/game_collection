import 'dart:math';
import 'package:flutter/material.dart';

class SLPlayer {
  final int id;
  final String name;
  final Color color;
  int position; // 1 to 100
  bool isWinner;

  SLPlayer({
    required this.id,
    required this.name,
    required this.color,
    this.position = 0, // 0 means not yet on board (if we use start rule)
    this.isWinner = false,
  });
}

enum GameDifficulty { easy, medium, hard }

class SnakesAndLaddersLogic {
  final List<SLPlayer> players;
  final GameDifficulty difficulty;
  int currentPlayerIndex;
  late Map<int, int> snakes;
  late Map<int, int> ladders;
  bool isGameOver = false;
  int lastDiceRoll = 0;
  bool isMoving = false;

  SnakesAndLaddersLogic({required this.players, required this.difficulty})
    : currentPlayerIndex = 0 {
    _initializeBoard();
  }

  void _initializeBoard() {
    switch (difficulty) {
      case GameDifficulty.easy:
        snakes = {25: 5, 54: 34, 87: 67, 98: 79};
        ladders = {
          1: 38,
          4: 14,
          9: 31,
          21: 42,
          28: 84,
          36: 44,
          51: 67,
          71: 91,
          80: 100,
        };
        break;
      case GameDifficulty.medium:
        snakes = {
          17: 7,
          54: 34,
          62: 19,
          64: 60,
          87: 24,
          93: 73,
          95: 75,
          98: 79,
        };
        ladders = {
          1: 38,
          4: 14,
          9: 31,
          21: 42,
          28: 84,
          36: 44,
          51: 67,
          80: 100,
        };
        break;
      case GameDifficulty.hard:
        snakes = {
          17: 7,
          32: 10,
          48: 26,
          54: 34,
          62: 19,
          64: 60,
          87: 24,
          93: 73,
          95: 75,
          98: 13, // Brutal snake
          99: 5, // Top to almost bottom
        };
        ladders = {4: 14, 9: 31, 21: 42, 36: 44, 51: 67, 71: 91};
        break;
    }
  }

  SLPlayer get currentPlayer => players[currentPlayerIndex];

  /// Rolls a 6-sided die
  int rollDice() {
    lastDiceRoll = Random().nextInt(6) + 1;
    return lastDiceRoll;
  }

  /// Calculates the next position and handles overshoot
  int calculateNewPosition(int currentPos, int roll) {
    if (currentPos + roll > 100) {
      return currentPos; // Overshoot rule
    }
    return currentPos + roll;
  }

  /// Checks if the position is a snake head or ladder bottom and returns the jump destination
  int? checkJump(int position) {
    if (snakes.containsKey(position)) {
      return snakes[position];
    }
    if (ladders.containsKey(position)) {
      return ladders[position];
    }
    return null;
  }

  void nextTurn() {
    if (isGameOver) return;
    currentPlayerIndex = (currentPlayerIndex + 1) % players.length;
  }

  /// Gets (row, col) for a position (1-100)
  /// Row 0 is bottom, row 9 is top.
  /// Col 0 is left, col 9 is right.
  /// Zigzag pattern:
  /// Row 0: 1-10 (Left to Right)
  /// Row 1: 11-20 (Right to Left)
  /// Row 2: 21-30 (Left to Right)
  /// ...
  static Point<int> getCoordinates(int position) {
    if (position < 1) return const Point(0, -1); // Outside
    int zeroBased = position - 1;
    int row = zeroBased ~/ 10;
    int col = zeroBased % 10;

    if (row % 2 == 1) {
      // Odd rows (1, 3, 5, 7, 9) go Right to Left
      col = 9 - col;
    }

    return Point(col, row);
  }
}
