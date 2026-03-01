import 'package:flutter/material.dart';

class BrickBreakerTheme {
  final String name;
  final Color backgroundColor;
  final List<Color> brickColors;
  final Color paddleColor;
  final Color ballColor;
  final Color glowColor;

  const BrickBreakerTheme({
    required this.name,
    required this.backgroundColor,
    required this.brickColors,
    required this.paddleColor,
    required this.ballColor,
    required this.glowColor,
  });

  static BrickBreakerTheme get defaultTheme => const BrickBreakerTheme(
    name: 'Neon Cyber Arena',
    backgroundColor: Color(0xFF0D0221),
    brickColors: [
      Color(0xFF00F2FF),
      Color(0xFF0066FF),
      Color(0xFF7000FF),
      Color(0xFFFF00C8),
    ],
    paddleColor: Color(0xFF00F2FF),
    ballColor: Colors.white,
    glowColor: Color(0xFF00F2FF),
  );
}

enum PowerUpType { none } // Placeholder for removing dependencies
