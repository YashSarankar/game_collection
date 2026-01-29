import 'package:flutter/material.dart';

/// Enum for different game types
enum GameType {
  snake,
  ticTacToe,
  brickBreaker,
  memoryMatch,
  balloonPop,
  pingPong,
  ludo,
  carrom,
  game2048,
  numberPuzzle,
  sudoku,
  waterSort,
  chess,
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
    const GameModel(
      id: 'ludo',
      title: 'Ludo',
      subtitle: 'Classic board game',
      icon: Icons.grid_view_rounded,
      type: GameType.ludo,
      primaryColor: Color(0xFF3498DB), // Blue
      secondaryColor: Color(0xFF2980B9),
      isMultiplayer: true,
    ),
    const GameModel(
      id: 'carrom',
      title: 'Carrom',
      subtitle: 'Strike the coins',
      icon: Icons.adjust_rounded,
      type: GameType.carrom,
      primaryColor: Color(0xFF8B4513), // Saddle Brown
      secondaryColor: Color(0xFFA0522D),
      isMultiplayer: true,
    ),
    const GameModel(
      id: 'game_2048',
      title: '2048',
      subtitle: 'Merge the tiles',
      icon: Icons.grid_3x3_rounded,
      type: GameType.game2048,
      primaryColor: Color(0xFFEDC22E), // 2048 Gold
      secondaryColor: Color(0xFFF2B179),
      isMultiplayer: false,
    ),
    const GameModel(
      id: 'number_puzzle',
      title: 'Number Puzzle',
      subtitle: 'Slide and solve',
      icon: Icons.filter_9_plus_rounded,
      type: GameType.numberPuzzle,
      primaryColor: Color(0xFF9B59B6), // Amethyst
      secondaryColor: Color(0xFF8E44AD),
      isMultiplayer: false,
    ),
    const GameModel(
      id: 'sudoku',
      title: 'Sudoku',
      subtitle: 'Plan with numbers',
      icon: Icons.calculate_rounded,
      type: GameType.sudoku,
      primaryColor: Color(0xFF34495E), // Wet Asphalt
      secondaryColor: Color(0xFF2C3E50),
      isMultiplayer: false,
    ),
    const GameModel(
      id: 'water_sort',
      title: 'Water Sort',
      subtitle: 'Sort the colors',
      icon: Icons.opacity_rounded,
      type: GameType.waterSort,
      primaryColor: Color(0xFF2ECC71), // Nephritis Green
      secondaryColor: Color(0xFF27AE60),
      isMultiplayer: false,
    ),
    const GameModel(
      id: 'chess',
      title: 'Chess',
      subtitle: 'The ultimate strategy',
      icon: Icons.grid_4x4_rounded,
      type: GameType.chess,
      primaryColor: Color(0xFF795548), // Brown
      secondaryColor: Color(0xFF5D4037),
      isMultiplayer: true,
    ),
  ];
}
