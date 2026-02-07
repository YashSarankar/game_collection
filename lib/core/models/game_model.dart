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
  snakesAndLadders,
  airHockey,
  tapDuel,
  dotsAndBoxes,
  spaceShooterDuel,
  tankBattle,
  asteroids,
  nineMensMorris,
  wordBattle,
  reactionTimeBattle,
  tugOfWar,
  knifeHit,
  match3,
}

/// Enum for different game categories
enum GameCategory {
  battleZone, // 🔥 The "Battle Zone"
  brainGym, // 🧩 The "Brain Gym"
  arcadeClassics, // 🕹️ The "Arcade Classics"
  boardRoom, // 🎲 The "Board Room"
}

/// Model representing a game in the collection
class GameModel {
  final String id;
  final String title;
  final String subtitle;
  final IconData icon;
  final GameType type;
  final GameCategory category;
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
    required this.category,
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
    GameCategory? category,
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
      category: category ?? this.category,
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
      category: GameCategory.arcadeClassics,
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
      category: GameCategory.boardRoom,
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
      category: GameCategory.arcadeClassics,
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
      category: GameCategory.brainGym,
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
      category: GameCategory.arcadeClassics,
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
      category: GameCategory.arcadeClassics,
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
      category: GameCategory.boardRoom,
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
      category: GameCategory.boardRoom,
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
      category: GameCategory.brainGym,
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
      category: GameCategory.brainGym,
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
      category: GameCategory.brainGym,
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
      category: GameCategory.brainGym,
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
      category: GameCategory.boardRoom,
      primaryColor: Color(0xFF795548), // Brown
      secondaryColor: Color(0xFF5D4037),
      isMultiplayer: true,
    ),
    const GameModel(
      id: 'snakes_and_ladders',
      title: 'Snakes & Ladders',
      subtitle: 'Race to the top',
      icon: Icons.stairs_rounded,
      type: GameType.snakesAndLadders,
      category: GameCategory.boardRoom,
      primaryColor: Color(0xFF9C27B0), // Purple
      secondaryColor: Color(0xFFBA68C8),
      isMultiplayer: true,
    ),
    const GameModel(
      id: 'air_hockey',
      title: 'Air Hockey',
      subtitle: 'Fast-paced table sports',
      icon: Icons.sports_hockey_rounded,
      type: GameType.airHockey,
      category: GameCategory.battleZone,
      primaryColor: Color(0xFF00B4D8), // Sky Blue
      secondaryColor: Color(0xFF90E0EF),
      isMultiplayer: true,
    ),
    const GameModel(
      id: 'tap_duel',
      title: 'Tap Duel',
      subtitle: 'Fast reflex tapping battle',
      icon: Icons.touch_app_rounded,
      type: GameType.tapDuel,
      category: GameCategory.battleZone,
      primaryColor: Color(0xFFE91E63), // Pink
      secondaryColor: Color(0xFFC2185B),
      isMultiplayer: true,
    ),
    const GameModel(
      id: 'dots_and_boxes',
      title: 'Dots & Boxes',
      subtitle: 'Claim the most boxes',
      icon: Icons.grid_on_rounded,
      type: GameType.dotsAndBoxes,
      category: GameCategory.boardRoom,
      primaryColor: Color(0xFF4CAF50), // Green
      secondaryColor: Color(0xFF81C784),
      isMultiplayer: true,
    ),
    const GameModel(
      id: 'space_shooter_duel',
      title: 'Space Shooter Duel',
      subtitle: 'High-energy space combat',
      icon: Icons.rocket_launch_rounded,
      type: GameType.spaceShooterDuel,
      category: GameCategory.battleZone,
      primaryColor: Color(0xFF7C4DFF), // Deep Purple
      secondaryColor: Color(0xFF9575CD),
      isMultiplayer: true,
    ),
    const GameModel(
      id: 'tank_battle',
      title: 'Tank Battle',
      subtitle: 'Tactical tank warfare',
      icon: Icons.military_tech_rounded,
      type: GameType.tankBattle,
      category: GameCategory.battleZone,
      primaryColor: Color(0xFF546E7A), // Blue Grey
      secondaryColor: Color(0xFF78909C),
      isMultiplayer: true,
    ),
    const GameModel(
      id: 'asteroids',
      title: 'Asteroids',
      subtitle: 'Classic space survival',
      icon: Icons.rocket_outlined,
      type: GameType.asteroids,
      category: GameCategory.arcadeClassics,
      primaryColor: Color(0xFF2C3E50), // Dark space blue
      secondaryColor: Color(0xFFBDC3C7), // Silver/Grey
      isMultiplayer: false,
    ),
    const GameModel(
      id: 'nine_mens_morris',
      title: 'Nine Men\'s Morris',
      subtitle: 'Ancient strategy board game',
      icon: Icons.grid_on_rounded,
      type: GameType.nineMensMorris,
      category: GameCategory.boardRoom,
      primaryColor: Color(0xFF8B4513), // Saddle Brown
      secondaryColor: Color(0xFFD2B48C), // Tan
      isMultiplayer: true,
    ),
    const GameModel(
      id: 'word_battle',
      title: 'Word Battle',
      subtitle: 'Make words and score points',
      icon: Icons.spellcheck_rounded,
      type: GameType.wordBattle,
      category: GameCategory.brainGym,
      primaryColor: Color(0xFF4285F4), // Google Blue
      secondaryColor: Color(0xFF34A853), // Google Green
      isMultiplayer: true,
    ),
    const GameModel(
      id: 'reaction_time_battle',
      title: 'Reaction Battle',
      subtitle: 'Test your reflexes',
      icon: Icons.flash_on_rounded,
      type: GameType.reactionTimeBattle,
      category: GameCategory.battleZone,
      primaryColor: Color(0xFFFFD700), // Gold
      secondaryColor: Color(0xFFFFA500), // Orange
      isMultiplayer: true,
    ),
    const GameModel(
      id: 'tug_of_war',
      title: 'Tug of War',
      subtitle: 'Fast tapping battle',
      icon: Icons.unfold_more_rounded,
      type: GameType.tugOfWar,
      category: GameCategory.battleZone,
      primaryColor: Color(0xFFC62828), // Deep Red
      secondaryColor: Color(0xFF1565C0), // Deep Blue
      isMultiplayer: true,
    ),
    const GameModel(
      id: 'knife_hit',
      title: 'Knife Hit',
      subtitle: 'Timing is everything',
      icon: Icons.ads_click_rounded,
      type: GameType.knifeHit,
      category: GameCategory.arcadeClassics,
      primaryColor: Color(0xFF795548), // Brown
      secondaryColor: Color(0xFFE91E63), // Pink
      isMultiplayer: false,
    ),
    const GameModel(
      id: 'match_3',
      title: 'Match 3',
      subtitle: 'Classic puzzle matching',
      icon: Icons.grid_view_rounded,
      type: GameType.match3,
      category: GameCategory.brainGym,
      primaryColor: Color(0xFFFF4081), // Pink Accent
      secondaryColor: Color(0xFF7C4DFF), // Deep Purple
      isMultiplayer: false,
    ),
  ];
}
