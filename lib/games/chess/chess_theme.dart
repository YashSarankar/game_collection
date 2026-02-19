import 'package:flutter/material.dart';

class ChessTheme {
  final String name;
  final Color darkSquare;
  final Color lightSquare;
  final Color highlightMove;
  final Color lastMove;
  final Color checkGlow;
  final List<Color> backgroundGradient;
  final TextStyle labelStyle;

  ChessTheme({
    required this.name,
    required this.darkSquare,
    required this.lightSquare,
    required this.highlightMove,
    required this.lastMove,
    required this.checkGlow,
    required this.backgroundGradient,
    required this.labelStyle,
  });

  static ChessTheme tournamentWood = ChessTheme(
    name: 'Tournament Wood',
    darkSquare: const Color(0xFFB58863),
    lightSquare: const Color(0xFFF0D9B5),
    highlightMove: Colors.greenAccent.withOpacity(0.5),
    lastMove: Colors.yellow.withOpacity(0.4),
    checkGlow: Colors.red.withOpacity(0.6),
    backgroundGradient: [const Color(0xFF2C3E50), const Color(0xFF000000)],
    labelStyle: const TextStyle(color: Colors.white70, fontSize: 12),
  );

  static ChessTheme darkMode = ChessTheme(
    name: 'Modern Dark',
    darkSquare: const Color(0xFF2A2E35),
    lightSquare: const Color(0xFF454D5A),
    highlightMove: Colors.blueAccent.withOpacity(0.5),
    lastMove: Colors.white24,
    checkGlow: Colors.redAccent.withOpacity(0.7),
    backgroundGradient: [const Color(0xFF121212), const Color(0xFF1E1E1E)],
    labelStyle: const TextStyle(color: Colors.white, fontSize: 12),
  );

  static ChessTheme forestGreen = ChessTheme(
    name: 'Forest Green',
    darkSquare: const Color(0xFF638954),
    lightSquare: const Color(0xFFEDF5E1),
    highlightMove: Colors.yellowAccent.withOpacity(0.5),
    lastMove: Colors.white.withOpacity(0.3),
    checkGlow: Colors.redAccent.withOpacity(0.7),
    backgroundGradient: [const Color(0xFF132616), const Color(0xFF000000)],
    labelStyle: const TextStyle(color: Colors.white70, fontSize: 12),
  );

  static ChessTheme classicMarble = ChessTheme(
    name: 'Classic Marble',
    darkSquare: const Color(0xFF3D3D3D),
    lightSquare: const Color(0xFFE0E0E0),
    highlightMove: Colors.indigo.withOpacity(0.4),
    lastMove: Colors.amber.withOpacity(0.4),
    checkGlow: Colors.red.withOpacity(0.5),
    backgroundGradient: [const Color(0xFFF5F5F5), const Color(0xFFBDBDBD)],
    labelStyle: const TextStyle(color: Colors.black54, fontSize: 12),
  );
}
