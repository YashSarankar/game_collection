import 'package:flutter/material.dart';

class ArrowsTheme {
  static const Color background = Color(0xFF0F0F1A); // Deep Midnight Blue/Black
  static const Color panelBackground = Color(0xFF1A1A2E);
  
  static const Color arrowUp = Colors.white; // Pure white for maximum visibility
  static const Color arrowDown = Colors.white;
  static const Color arrowLeft = Colors.white;
  static const Color arrowRight = Colors.white;
  
  static const Color blockedNode = Color(0xFFFF4757); // Vibrant Coral Red
  static const Color textPrimary = Color(0xFFA29BFE); // Glowing Light Purple
  static const Color textSecondary = Colors.white54;

  static const Color primaryButton = Color(0xFF6C5CE7);

  static BoxDecoration glassBox = BoxDecoration(
    color: const Color(0xFF1E1E30).withOpacity(0.95),
    borderRadius: BorderRadius.circular(24),
    border: Border.all(color: Colors.white10),
    boxShadow: [
      BoxShadow(
        color: Colors.black.withOpacity(0.4),
        blurRadius: 20,
        offset: const Offset(0, 10),
      )
    ],
  );
}
