import 'package:flutter/material.dart';

/// Game-specific constants and configurations
class GameConstants {
  // Snake Game
  static const int snakeGridSize = 20;
  static const Duration snakeTickDuration = Duration(milliseconds: 200);

  // Tic Tac Toe
  static const int ticTacToeGridSize = 3;

  // Brick Breaker
  static const int brickBreakerRows = 6;
  static const int brickBreakerColumns = 8;
  static const double brickBreakerPaddleWidth = 100;
  static const double brickBreakerBallRadius = 8;

  // Memory Match
  static const int memoryMatchGridSize = 4; // 4x4 = 16 cards (8 pairs)
  static const Duration memoryMatchFlipDuration = Duration(milliseconds: 300);
  static const Duration memoryMatchMismatchDelay = Duration(milliseconds: 1000);

  // Balloon Pop
  static const int balloonPopInitialSpeed = 2;
  static const int balloonPopMaxBalloons = 10;
  static const Duration balloonPopSpawnInterval = Duration(milliseconds: 1500);

  // Ping Pong
  static const double pingPongPaddleHeight = 100;
  static const double pingPongPaddleWidth = 15;
  static const double pingPongBallRadius = 8;
  static const double pingPongBallSpeed = 5;
}

/// Color schemes for games
class GameColors {
  // Primary Colors
  static const Color primary = Color(0xFFFF8C00);
  static const Color secondary = Color(0xFFFF6584);
  static const Color accent = Color(0xFF4CAF50);

  // Game-specific colors
  static const Color snakeGreen = Color(0xFFFF8C00); // Now Orange
  static const Color snakeFood = Color(0xFFFF4500);

  static const Color ticTacToeX = Color(0xFFFF6B6B);
  static const Color ticTacToeO = Color(0xFFFFD700);

  static const List<Color> brickColors = [
    Color(0xFFFF8C00),
    Color(0xFFFFD700),
    Color(0xFFFF4500),
    Color(0xFFE67E22),
    Color(0xFFD35400),
    Color(0xFFFF6B6B),
  ];

  static const List<Color> balloonColors = [
    Color(0xFFFF8C00),
    Color(0xFFFFB347),
    Color(0xFFFF6B6B),
    Color(0xFFE67E22),
    Color(0xFFFFD700),
    Color(0xFFD35400),
  ];

  // UI Colors
  static const Color cardBackground = Color(0xFFFFFFFF);
  static const Color cardBackgroundDark = Color(0xFF2C2C2C);
  static const Color gameBackground = Color(0xFF1A1A2E);
  static const Color textPrimary = Color(0xFF212121);
  static const Color textSecondary = Color(0xFF757575);
  static const Color textPrimaryDark = Color(0xFFFFFFFF);
  static const Color textSecondaryDark = Color(0xFFB0B0B0);
}
