import 'package:flutter/material.dart';

/// Enum for different game types
enum GameType {
  snake,
  ticTacToe,
  brickBreaker,
  memoryMatch,
  balloonPop,
  pingPong,
}

/// Model representing a game in the collection
class GameModel {
  final String id;
  final String title;
  final String subtitle;
  final IconData icon;
  final GameType type;
  final Color primaryColor;
  final Color secondaryColor;
  final bool isMultiplayer;
  final bool isLocked;
  final int unlockCost;

  const GameModel({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.type,
    required this.primaryColor,
    required this.secondaryColor,
    this.isMultiplayer = false,
    this.isLocked = false,
    this.unlockCost = 0,
  });

  GameModel copyWith({
    String? id,
    String? title,
    String? subtitle,
    IconData? icon,
    GameType? type,
    Color? primaryColor,
    Color? secondaryColor,
    bool? isMultiplayer,
    bool? isLocked,
    int? unlockCost,
  }) {
    return GameModel(
      id: id ?? this.id,
      title: title ?? this.title,
      subtitle: subtitle ?? this.subtitle,
      icon: icon ?? this.icon,
      type: type ?? this.type,
      primaryColor: primaryColor ?? this.primaryColor,
      secondaryColor: secondaryColor ?? this.secondaryColor,
      isMultiplayer: isMultiplayer ?? this.isMultiplayer,
      isLocked: isLocked ?? this.isLocked,
      unlockCost: unlockCost ?? this.unlockCost,
    );
  }
}

/// Predefined list of games
class GamesList {
  static final List<GameModel> allGames = [
    const GameModel(
      id: 'snake',
      title: 'Snake Game',
      subtitle: 'Classic snake adventure',
      icon: Icons.grid_4x4,
      type: GameType.snake,
      primaryColor: Color(0xFFFF8C00), // Pure Orange
      secondaryColor: Color(0xFFFFA500),
      isMultiplayer: false,
    ),
    const GameModel(
      id: 'tic_tac_toe',
      title: 'Tic Tac Toe',
      subtitle: 'Play with a friend',
      icon: Icons.tag,
      type: GameType.ticTacToe,
      primaryColor: Color(0xFFFF6B6B), // Coral/Red-Orange
      secondaryColor: Color(0xFFFF8E8E),
      isMultiplayer: true,
    ),
    const GameModel(
      id: 'brick_breaker',
      title: 'Brick Breaker',
      subtitle: 'Break all the bricks',
      icon: Icons.grid_on,
      type: GameType.brickBreaker,
      primaryColor: Color(0xFFFF4500), // Orange Red
      secondaryColor: Color(0xFFFF6347),
      isMultiplayer: false,
    ),
    const GameModel(
      id: 'memory_match',
      title: 'Memory Match',
      subtitle: 'Test your memory',
      icon: Icons.psychology,
      type: GameType.memoryMatch,
      primaryColor: Color(0xFFFFD700), // Gold/Yellow-Orange
      secondaryColor: Color(0xFFFFE44D),
      isMultiplayer: true,
    ),
    const GameModel(
      id: 'balloon_pop',
      title: 'Balloon Pop',
      subtitle: 'Pop the balloons',
      icon: Icons.bubble_chart,
      type: GameType.balloonPop,
      primaryColor: Color(0xFFE67E22), // Pumpkin Orange
      secondaryColor: Color(0xFFF39C12),
      isMultiplayer: false,
    ),
    const GameModel(
      id: 'ping_pong',
      title: 'Ping Pong',
      subtitle: 'Classic paddle game',
      icon: Icons.sports_tennis,
      type: GameType.pingPong,
      primaryColor: Color(0xFFD35400), // Deep Orange
      secondaryColor: Color(0xFFE67E22),
      isMultiplayer: true,
    ),
  ];
}
