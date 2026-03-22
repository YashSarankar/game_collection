import 'dart:math';
import 'package:flutter/foundation.dart';

enum Direction { up, down, left, right }

class Game2048Engine {
  final int size;
  late List<List<int>> grid;
  int score = 0;

  List<List<int>>? previousGrid;
  int? previousScore;

  Game2048Engine({this.size = 4}) {
    initGame();
  }

  void initGame() {
    grid = List.generate(size, (_) => List.filled(size, 0));
    score = 0;
    spawnTile();
    spawnTile();
    previousGrid = null;
    previousScore = null;
  }

  void spawnTile() {
    List<Point<int>> empty = [];

    for (int i = 0; i < size; i++) {
      for (int j = 0; j < size; j++) {
        if (grid[i][j] == 0) {
          empty.add(Point(i, j));
        }
      }
    }

    if (empty.isEmpty) return;

    Point<int> p = empty[Random().nextInt(empty.length)];
    grid[p.x][p.y] = Random().nextDouble() < 0.9 ? 2 : 4;
  }

  List<int> processLine(List<int> line) {
    // Step 1: remove zeros
    List<int> newLine = line.where((x) => x != 0).toList();

    // Step 2: merge
    for (int i = 0; i < newLine.length - 1; i++) {
      if (newLine[i] == newLine[i + 1]) {
        newLine[i] *= 2;
        score += newLine[i];
        newLine[i + 1] = 0;
        i++; // skip next (IMPORTANT)
      }
    }

    // Step 3: remove zeros again
    newLine = newLine.where((x) => x != 0).toList();

    // Step 4: pad zeros
    while (newLine.length < size) {
      newLine.add(0);
    }

    return newLine;
  }

  bool moveLeft() {
    bool moved = false;
    for (int i = 0; i < size; i++) {
      List<int> newRow = processLine(grid[i]);
      if (!listEquals(grid[i], newRow)) {
        grid[i] = newRow;
        moved = true;
      }
    }
    return moved;
  }

  bool moveRight() {
    bool moved = false;
    for (int i = 0; i < size; i++) {
      List<int> reversed = grid[i].reversed.toList();
      List<int> newRow = processLine(reversed).reversed.toList();
      if (!listEquals(grid[i], newRow)) {
        grid[i] = newRow;
        moved = true;
      }
    }
    return moved;
  }

  bool moveUp() {
    bool moved = false;
    for (int col = 0; col < size; col++) {
      List<int> column = [];
      for (int row = 0; row < size; row++) {
        column.add(grid[row][col]);
      }
      List<int> newCol = processLine(column);
      for (int row = 0; row < size; row++) {
        if (grid[row][col] != newCol[row]) {
          grid[row][col] = newCol[row];
          moved = true;
        }
      }
    }
    return moved;
  }

  bool moveDown() {
    bool moved = false;
    for (int col = 0; col < size; col++) {
      List<int> column = [];
      for (int row = 0; row < size; row++) {
        column.add(grid[row][col]);
      }
      List<int> reversed = column.reversed.toList();
      List<int> newCol = processLine(reversed).reversed.toList();
      for (int row = 0; row < size; row++) {
        if (grid[row][col] != newCol[row]) {
          grid[row][col] = newCol[row];
          moved = true;
        }
      }
    }
    return moved;
  }

  bool makeMove(Direction dir) {
    saveState();
    bool moved = false;

    switch (dir) {
      case Direction.left:
        moved = moveLeft();
        break;
      case Direction.right:
        moved = moveRight();
        break;
      case Direction.up:
        moved = moveUp();
        break;
      case Direction.down:
        moved = moveDown();
        break;
    }

    if (moved) {
      spawnTile();
    }
    return moved;
  }

  bool canMove() {
    // empty cell exists
    for (var row in grid) {
      if (row.contains(0)) return true;
    }

    // horizontal check
    for (int i = 0; i < size; i++) {
      for (int j = 0; j < size - 1; j++) {
        if (grid[i][j] == grid[i][j + 1]) return true;
      }
    }

    // vertical check
    for (int j = 0; j < size; j++) {
      for (int i = 0; i < size - 1; i++) {
        if (grid[i][j] == grid[i + 1][j]) return true;
      }
    }

    return false;
  }

  bool hasWon() {
    for (var row in grid) {
      if (row.contains(2048)) return true;
    }
    return false;
  }

  void saveState() {
    previousGrid = grid.map((r) => List<int>.from(r)).toList();
    previousScore = score;
  }

  void undo() {
    if (previousGrid != null && previousScore != null) {
      grid = previousGrid!;
      score = previousScore!;
      previousGrid = null;
      previousScore = null;
    }
  }
}
