import 'package:flutter/material.dart';

class WaterSortBottle {
  List<Color> stack; // bottom → top
  final int capacity;

  WaterSortBottle({
    required List<Color> stack,
    this.capacity = 4,
  }) : stack = List.from(stack);

  bool get isEmpty => stack.isEmpty;
  bool get isFull => stack.length >= capacity;
  Color? get topColor => stack.isEmpty ? null : stack.last;

  int get countTopSameColor {
    if (stack.isEmpty) return 0;
    Color color = stack.last;
    int count = 0;
    for (int i = stack.length - 1; i >= 0; i--) {
      if (stack[i] == color) {
        count++;
      } else {
        break;
      }
    }
    return count;
  }

  bool get isSolved =>
      stack.isEmpty ||
      (stack.length == capacity && stack.every((c) => c == stack[0]));

  WaterSortBottle copy() => WaterSortBottle(stack: List.from(stack), capacity: capacity);

  String get id => stack.map((c) => c.value.toRadixString(16)).join(',');
}

class WaterSortMove {
  final int fromIndex;
  final int toIndex;
  final List<Color> colorsPoured;

  WaterSortMove({
    required this.fromIndex,
    required this.toIndex,
    required this.colorsPoured,
  });
}

class WaterSortLogic {
  static const List<Color> gameColors = [
    Colors.red,
    Colors.blue,
    Colors.green,
    Colors.yellow,
    Colors.purple,
    Colors.orange,
    Colors.pink,
    Colors.cyan,
    Colors.brown,
    Colors.indigo,
    Colors.teal,
    Colors.lime,
  ];

  static bool canPour(WaterSortBottle from, WaterSortBottle to) {
    if (from.isEmpty) return false;
    if (to.isFull) return false;

    // Extra Optimization: Prevent moving a perfectly sorted full bottle into an empty one
    if (from.stack.length == from.capacity &&
        from.stack.every((c) => c == from.topColor) &&
        to.isEmpty) {
      return false;
    }

    if (to.isEmpty) return true;

    return from.topColor == to.topColor;
  }

  static int calculatePourAmount(WaterSortBottle from, WaterSortBottle to) {
    if (!canPour(from, to)) return 0;
    int count = from.countTopSameColor;
    int space = to.capacity - to.stack.length;
    return count < space ? count : space;
  }

  static void pour(WaterSortBottle from, WaterSortBottle to) {
    int amount = calculatePourAmount(from, to);
    for (int i = 0; i < amount; i++) {
      to.stack.add(from.stack.removeLast());
    }
  }

  static bool isWin(List<WaterSortBottle> bottles) {
    for (var b in bottles) {
      if (b.stack.isEmpty) continue;
      if (b.stack.length != b.capacity) return false;
      Color firstColor = b.stack.first;
      if (!b.stack.every((c) => c == firstColor)) {
        return false;
      }
    }
    return true;
  }

  static List<WaterSortBottle> generateLevel(int difficulty) {
    // Difficulty 1: 3 colors, 2 empty
    // Difficulty 5: 12 colors, 2 empty
    int colorCount = 2 + difficulty; 
    if (colorCount > gameColors.length) colorCount = gameColors.length;
    
    int emptyBottles = 2;
    
    List<WaterSortBottle> bottles = [];
    bool solvable = false;
    int attempts = 0;

    while (!solvable && attempts < 100) {
      attempts++;
      List<Color> allColors = [];
      for (int i = 0; i < colorCount; i++) {
        for (int j = 0; j < 4; j++) {
          allColors.add(gameColors[i]);
        }
      }
      allColors.shuffle();

      bottles = [];
      for (int i = 0; i < colorCount; i++) {
        bottles.add(
          WaterSortBottle(
            stack: allColors.sublist(i * 4, (i + 1) * 4),
          ),
        );
      }
      for (int i = 0; i < emptyBottles; i++) {
        bottles.add(WaterSortBottle(stack: []));
      }

      if (WaterSortSolver.canBeSolved(bottles)) {
        solvable = true;
      }
    }

    return bottles;
  }
}

class WaterSortSolver {
  static bool canBeSolved(List<WaterSortBottle> initialBottles) {
    Set<String> visited = {};
    return _dfs(initialBottles, visited);
  }

  static bool _dfs(List<WaterSortBottle> current, Set<String> visited) {
    String stateKey = current.map((b) => b.id).join('|');
    if (visited.contains(stateKey)) return false;
    visited.add(stateKey);

    if (WaterSortLogic.isWin(current)) return true;

    for (int i = 0; i < current.length; i++) {
      for (int j = 0; j < current.length; j++) {
        if (i == j) continue;

        if (WaterSortLogic.canPour(current[i], current[j])) {
          var nextState = current.map((b) => b.copy()).toList();
          WaterSortLogic.pour(nextState[i], nextState[j]);
          if (_dfs(nextState, visited)) return true;
        }
      }
    }

    return false;
  }
}
