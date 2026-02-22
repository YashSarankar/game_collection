import 'package:flutter/material.dart';

class TTTPlayer {
  final String name;
  final String avatar;
  final Color color;
  final String piece; // 'X' or 'O'
  int score;

  TTTPlayer({
    required this.name,
    required this.avatar,
    required this.color,
    required this.piece,
    this.score = 0,
  });

  TTTPlayer copyWith({
    String? name,
    String? avatar,
    Color? color,
    String? piece,
    int? score,
  }) {
    return TTTPlayer(
      name: name ?? this.name,
      avatar: avatar ?? this.avatar,
      color: color ?? this.color,
      piece: piece ?? this.piece,
      score: score ?? this.score,
    );
  }
}

enum GameMode { classic3x3, pro4x4, pro5x5, timed, speed, tournament }

class TTTGameState {
  final List<List<String>> board;
  final int gridSize;
  final bool isXTurn;
  final String? winner;
  final List<Offset>? winningLine;
  final bool isDraw;
  final Duration? timeLeft;
  final GameMode mode;

  TTTGameState({
    required this.board,
    required this.gridSize,
    required this.isXTurn,
    this.winner,
    this.winningLine,
    this.isDraw = false,
    this.timeLeft,
    this.mode = GameMode.classic3x3,
  });

  factory TTTGameState.initial(int size, GameMode mode) {
    return TTTGameState(
      board: List.generate(size, (_) => List.filled(size, '')),
      gridSize: size,
      isXTurn: true,
      mode: mode,
    );
  }

  TTTGameState copyWith({
    List<List<String>>? board,
    int? gridSize,
    bool? isXTurn,
    String? winner,
    List<Offset>? winningLine,
    bool? isDraw,
    Duration? timeLeft,
    GameMode? mode,
  }) {
    return TTTGameState(
      board: board ?? this.board,
      gridSize: gridSize ?? this.gridSize,
      isXTurn: isXTurn ?? this.isXTurn,
      winner: winner,
      winningLine: winningLine,
      isDraw: isDraw ?? this.isDraw,
      timeLeft: timeLeft,
      mode: mode ?? this.mode,
    );
  }
}
