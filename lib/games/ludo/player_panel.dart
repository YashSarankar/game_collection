import 'package:flutter/material.dart';
import 'ludo_theme.dart';

class PlayerPanel extends StatelessWidget {
  final int playerIndex;
  final String name;
  final bool isCurrentTurn;
  final int score;
  final List<Color> playerColors = [
    LudoTheme.red,
    LudoTheme.green,
    LudoTheme.yellow,
    LudoTheme.blue,
  ];

  final Widget? dice;

  PlayerPanel({
    super.key,
    required this.playerIndex,
    required this.name,
    required this.isCurrentTurn,
    this.score = 0,
    this.dice,
  });

  @override
  Widget build(BuildContext context) {
    final color = playerColors[playerIndex];

    return AnimatedContainer(
      duration: const Duration(milliseconds: 400),
      height: 48,
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        // Glassmorphism style — works on any background
        color: isCurrentTurn
            ? Colors.white.withOpacity(0.25)
            : Colors.white.withOpacity(0.08),
        border: Border.all(
          color: isCurrentTurn ? color : Colors.white.withOpacity(0.15),
          width: 1.5,
        ),
        boxShadow: isCurrentTurn
            ? [
                BoxShadow(
                  color: color.withOpacity(0.25),
                  blurRadius: 12,
                  spreadRadius: 1,
                ),
              ]
            : [],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Player Icon/Marker Section
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: Row(
              children: [
                Stack(
                  alignment: Alignment.center,
                  children: [
                    Icon(Icons.location_on, color: color, size: 24),
                    const Positioned(
                      top: 4,
                      child: CircleAvatar(
                        radius: 3,
                        backgroundColor: Colors.white,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Dice Slot Section
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            width: isCurrentTurn ? 40 : 32,
            height: double.infinity,
            decoration: BoxDecoration(
              color: isCurrentTurn
                  ? color.withOpacity(0.2)
                  : Colors.white.withOpacity(0.05),
              border: isCurrentTurn
                  ? Border.all(color: color.withOpacity(0.3), width: 0.5)
                  : null,
            ),
            child: Center(
              child:
                  dice ??
                  Icon(
                    Icons.casino_outlined,
                    size: 14,
                    color: Colors.white.withOpacity(0.1),
                  ),
            ),
          ),
        ],
      ),
    );
  }
}
