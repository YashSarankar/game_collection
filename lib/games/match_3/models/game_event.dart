import 'package:flutter/material.dart';

enum GameEventType {
  match,
  swap,
  invalidSwap,
  combo,
  shake,
  specialCreated,
  gameOver,
  levelComplete,
}

class GameEvent {
  final GameEventType type;
  final Offset? position;
  final String? message;
  final dynamic data;

  GameEvent({required this.type, this.position, this.message, this.data});
}
