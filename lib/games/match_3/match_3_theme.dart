import 'package:flutter/material.dart';

class Match3Theme {
  // Premium Color Palette
  static const Color primaryPink = Color(0xFFFF4081);
  static const Color accentPurple = Color(0xFF9C27B0);
  static const Color deepPurple = Color(0xFF673AB7);
  static const Color oceanBlue = Color(0xFF00BCD4);
  static const Color mintGreen = Color(0xFF4CAF50);
  static const Color sunnyYellow = Color(0xFFFFEB3B);
  static const Color juicyOrange = Color(0xFFFF9800);

  // Background Gradients
  static const List<Color> lightBgGradient = [
    Color(0xFFE0EAFC),
    Color(0xFFCFDEF3),
  ];

  static const List<Color> darkBgGradient = [
    Color(0xFF1F1C2C),
    Color(0xFF121212),
  ];

  static const List<Color> candyPinkGradient = [
    Color(0xFFFF80AB),
    Color(0xFFFF4081),
  ];
  static const List<Color> candyBlueGradient = [
    Color(0xFF80D8FF),
    Color(0xFF40C4FF),
  ];
  static const List<Color> candyGreenGradient = [
    Color(0xFFB9F6CA),
    Color(0xFF69F0AE),
  ];
  static const List<Color> candyYellowGradient = [
    Color(0xFFFFFF8D),
    Color(0xFFFFEA00),
  ];
  static const List<Color> candyPurpleGradient = [
    Color(0xFFEA80FC),
    Color(0xFFE040FB),
  ];
  static const List<Color> candyOrangeGradient = [
    Color(0xFFFFD180),
    Color(0xFFFFAB40),
  ];

  static List<List<Color>> get gemGradients => [
    candyPinkGradient, // 0: pink
    candyBlueGradient, // 1: blue
    candyGreenGradient, // 2: green
    candyYellowGradient, // 3: yellow
    candyPurpleGradient, // 4: purple
    candyOrangeGradient, // 5: orange
    [Colors.transparent, Colors.transparent], // 6: empty (fallback)
  ];

  static TextStyle get headerStyle => const TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.bold,
    color: Colors.white,
    letterSpacing: 1.2,
  );

  static TextStyle get scoreStyle => const TextStyle(
    fontSize: 32,
    fontWeight: FontWeight.w900,
    color: Colors.white,
    shadows: [
      Shadow(color: Colors.black26, blurRadius: 4, offset: Offset(0, 2)),
    ],
  );

  static BoxDecoration glassBoxDecoration({bool isDark = false}) {
    return BoxDecoration(
      color: (isDark ? Colors.black : Colors.white).withOpacity(0.15),
      borderRadius: BorderRadius.circular(20),
      border: Border.all(
        color: (isDark ? Colors.white : Colors.black).withOpacity(0.1),
        width: 1,
      ),
    );
  }
}
