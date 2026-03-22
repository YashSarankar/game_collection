import 'package:flutter/material.dart';
import '../arrows_theme.dart';

class LifeBar extends StatelessWidget {
  final int lives;
  final int maxLives;

  const LifeBar({Key? key, required this.lives, this.maxLives = 3}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(maxLives, (index) {
        bool hasLife = index < lives;
        
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4.0),
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            child: Icon(
              Icons.favorite_rounded,
              key: ValueKey('life_$index\_$hasLife'),
              color: hasLife ? ArrowsTheme.blockedNode : Colors.white.withOpacity(0.05),
              size: 24,
            ),
          ),
        );
      }),
    );
  }
}
