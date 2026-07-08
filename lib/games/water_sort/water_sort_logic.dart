import 'dart:math' as math;
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
    
    // 1. Start from a solved state
    for (int i = 0; i < colorCount; i++) {
      bottles.add(WaterSortBottle(
        stack: List.filled(4, gameColors[i]),
      ));
    }
    for (int i = 0; i < emptyBottles; i++) {
      bottles.add(WaterSortBottle(stack: []));
    }

    // 2. Perform Reverse Simulation shuffles
    // This guarantees the puzzle is solvable and is O(n) instead of exponential.
    int shuffleCount = 40 + (difficulty * 25);
    int successfulShuffles = 0;
    int attempts = 0;
    math.Random rnd = math.Random();

    while (successfulShuffles < shuffleCount && attempts < 2000) {
      attempts++;
      
      // Pick a random bottle that isn't empty
      int fromIdx = rnd.nextInt(bottles.length);
      WaterSortBottle from = bottles[fromIdx];
      if (from.isEmpty) continue;
      
      Color x = from.topColor!;
      int countOfX = from.countTopSameColor;
      
      // Decide how many to reverse pour (1 to countOfX)
      int k = rnd.nextInt(countOfX) + 1;
      
      // Pick a target bottle
      int toIdx = rnd.nextInt(bottles.length);
      if (fromIdx == toIdx) continue;
      WaterSortBottle to = bottles[toIdx];
      
      // Target bottle must have at least k spaces
      int space = to.capacity - to.stack.length;
      if (space < k) continue;
      
      // Target bottle must be empty, OR its top color must NOT be X.
      // (If it was X, then they would merge when playing forward, 
      // making it impossible to guarantee exactly k items were poured)
      if (!to.isEmpty && to.topColor == x) continue;
      
      // Perform the reverse pour
      for (int i = 0; i < k; i++) {
        to.stack.add(from.stack.removeLast());
      }
      successfulShuffles++;
    }

    return bottles;
  }
}
