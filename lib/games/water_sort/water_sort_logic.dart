import 'dart:math';
import 'package:flutter/material.dart';

class WaterSortBottle {
  final List<Color> layers;
  final int capacity;
  final bool isMystery;

  WaterSortBottle({
    required List<Color> layers,
    this.capacity = 4,
    this.isMystery = false,
  }) : layers = List.from(layers);

  bool get isEmpty => layers.isEmpty;
  bool get isFull => layers.length >= capacity;
  Color? get topColor => layers.isEmpty ? null : layers.last;

  int get topColorCount {
    if (layers.isEmpty) return 0;
    int count = 0;
    Color color = layers.last;
    for (int i = layers.length - 1; i >= 0; i--) {
      if (layers[i] == color) {
        count++;
      } else {
        break;
      }
    }
    return count;
  }

  bool get isSolved =>
      (layers.isEmpty) ||
      (layers.length == capacity && layers.every((c) => c == layers[0]));

  WaterSortBottle copy() =>
      WaterSortBottle(layers: layers, capacity: capacity, isMystery: isMystery);
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

  static List<WaterSortBottle> generateLevel(int difficulty) {
    int colorCount = 3 + difficulty;
    if (colorCount > gameColors.length) colorCount = gameColors.length;

    // Easy (1): 2, Med (2): 2, Hard (3): 1, Expert (4): 1, Brutal (5): 0
    int emptyBottles = (difficulty >= 5) ? 1 : (difficulty >= 3 ? 1 : 2);
    bool hasMystery = difficulty >= 2;

    List<Color> allColors = [];
    for (int i = 0; i < colorCount; i++) {
      for (int j = 0; j < 4; j++) {
        allColors.add(gameColors[i]);
      }
    }

    allColors.shuffle();

    List<WaterSortBottle> bottles = [];
    for (int i = 0; i < colorCount; i++) {
      bottles.add(
        WaterSortBottle(
          layers: allColors.sublist(i * 4, (i + 1) * 4),
          isMystery: hasMystery && (i % 2 == 0),
        ),
      );
    }

    for (int i = 0; i < emptyBottles; i++) {
      bottles.add(WaterSortBottle(layers: []));
    }

    return bottles;
  }

  static bool canPour(WaterSortBottle from, WaterSortBottle to) {
    if (from.isEmpty) return false;
    if (to.isFull) return false;
    if (to.isEmpty) return true;
    return from.topColor == to.topColor;
  }

  static int calculatePourAmount(WaterSortBottle from, WaterSortBottle to) {
    int fromTopCount = from.topColorCount;
    int toRemainingSpace = to.capacity - to.layers.length;
    return min(fromTopCount, toRemainingSpace);
  }

  static bool isWin(List<WaterSortBottle> bottles) {
    return bottles.every((b) => b.isSolved);
  }
}
