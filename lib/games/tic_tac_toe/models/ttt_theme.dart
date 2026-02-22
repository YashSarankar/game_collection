import 'package:flutter/material.dart';

enum TTTThemeType { neonCyber, minimalGlass, woodenClassic, space, darkRoyal }

class TTTTheme {
  final String name;
  final Color backgroundColor;
  final List<Color> backgroundGradient;
  final Color gridColor;
  final Color playerXColor;
  final Color playerOColor;
  final Color accentColor;
  final bool hasGlow;
  final String? backgroundImage;
  final String xIconPath;
  final String oIconPath;

  const TTTTheme({
    required this.name,
    required this.backgroundColor,
    required this.backgroundGradient,
    required this.gridColor,
    required this.playerXColor,
    required this.playerOColor,
    required this.accentColor,
    this.hasGlow = true,
    this.backgroundImage,
    this.xIconPath = '',
    this.oIconPath = '',
  });

  static TTTTheme neonCyber = const TTTTheme(
    name: 'Neon Cyber',
    backgroundColor: Color(0xFF0D0221),
    backgroundGradient: [
      Color(0xFF0D0221),
      Color(0xFF1B0B3B),
      Color(0xFF261447),
    ],
    gridColor: Color(0xFF00F2FF),
    playerXColor: Color(0xFFFF00E5),
    playerOColor: Color(0xFF00F2FF),
    accentColor: Color(0xFF2DE2E6),
  );

  static TTTTheme minimalGlass = const TTTTheme(
    name: 'Minimal Glass',
    backgroundColor: Color(0xFFF0F2F5),
    backgroundGradient: [
      Color(0xFFE0EAFC),
      Color(0xFFD9E2F3),
      Color(0xFFCFDEF3),
    ],
    gridColor: Colors.white,
    playerXColor: Color(0xFF667EEA),
    playerOColor: Color(0xFF764BA2),
    accentColor: Colors.white,
    hasGlow: false,
  );

  static TTTTheme woodenClassic = const TTTTheme(
    name: 'Wooden Classic',
    backgroundColor: Color(0xFF3E2723),
    backgroundGradient: [
      Color(0xFF5D4037),
      Color(0xFF4E342E),
      Color(0xFF3E2723),
    ],
    gridColor: Color(0xFFD7CCC8),
    playerXColor: Color(0xFFA1887F),
    playerOColor: Color(0xFF8D6E63),
    accentColor: Color(0xFFBCAAA4),
    hasGlow: false,
  );

  static TTTTheme space = const TTTTheme(
    name: 'Space',
    backgroundColor: Color(0xFF0B0D17),
    backgroundGradient: [
      Color(0xFF0B0D17),
      Color(0xFF101424),
      Color(0xFF1B2132),
    ],
    gridColor: Color(0xFFFFFFFF),
    playerXColor: Color(0xFFE0EAFC),
    playerOColor: Color(0xFFCFDEF3),
    accentColor: Color(0xFF9198E5),
  );

  static TTTTheme darkRoyal = const TTTTheme(
    name: 'Dark Royal',
    backgroundColor: Color(0xFF1A1A1A),
    backgroundGradient: [
      Color(0xFF1A1A1A),
      Color(0xFF252525),
      Color(0xFF2D2D2D),
    ],
    gridColor: Color(0xFFFFD700),
    playerXColor: Color(0xFFFFD700),
    playerOColor: Color(0xFFC0C0C0),
    accentColor: Color(0xFFB8860B),
  );

  static TTTTheme getTheme(TTTThemeType type) {
    switch (type) {
      case TTTThemeType.neonCyber:
        return neonCyber;
      case TTTThemeType.minimalGlass:
        return minimalGlass;
      case TTTThemeType.woodenClassic:
        return woodenClassic;
      case TTTThemeType.space:
        return space;
      case TTTThemeType.darkRoyal:
        return darkRoyal;
    }
  }
}
