import 'package:flutter/material.dart';

class LudoTheme {
  // Vibrant & Premium Colors
  static const Color red = Color(0xFFFF4B4B);
  static const Color green = Color(0xFF2ECC71);
  static const Color yellow = Color(0xFFFFD93D);
  static const Color blue = Color(0xFF3498DB);

  static const Color redLight = Color(0xFFFF7676);
  static const Color greenLight = Color(0xFF58D68D);
  static const Color yellowLight = Color(0xFFFFE66D);
  static const Color blueLight = Color(0xFF5DADE2);

  static const Color redDark = Color(0xFFC0392B);
  static const Color greenDark = Color(0xFF27AE60);
  static const Color yellowDark = Color(0xFFF1C40F);
  static const Color blueDark = Color(0xFF2980B9);

  static const Color boardBackground = Color(0xFFF8F9FA);
  static const Color boardFrame = Color(0xFF2C3E50);
  static const Color gridLine = Color(0xFFE0E0E0);

  static const List<Color> playerColors = [red, green, yellow, blue];
  static const List<Color> playerGradientsStart = [
    redLight,
    greenLight,
    yellowLight,
    blueLight,
  ];
  static const List<Color> playerGradientsEnd = [
    redDark,
    greenDark,
    yellowDark,
    blueDark,
  ];

  // Fixed styles — no dark/light branching, designed for the background image
  static TextStyle headerStyle(BuildContext context) {
    return const TextStyle(
      fontSize: 22,
      fontWeight: FontWeight.w900,
      color: Colors.white,
      letterSpacing: 1.5,
      shadows: [
        Shadow(color: Colors.black45, offset: Offset(0, 2), blurRadius: 6),
      ],
    );
  }

  static TextStyle bodyStyle(BuildContext context) {
    return TextStyle(color: Colors.white.withOpacity(0.85), fontSize: 14);
  }

  static BoxDecoration get glassDecoration => BoxDecoration(
    color: Colors.white.withOpacity(0.1),
    borderRadius: BorderRadius.circular(20),
    border: Border.all(color: Colors.white.withOpacity(0.2)),
  );
}
