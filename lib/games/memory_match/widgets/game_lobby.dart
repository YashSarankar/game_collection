import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/memory_game_provider.dart';

class GameLobby extends StatelessWidget {
  const GameLobby({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text(
            "Select Difficulty",
            style: TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 32),
          _DifficultyButton(
            title: "Easy",
            subtitle: "4 x 4 Grid",
            difficulty: GameDifficulty.easy,
            color: Colors.greenAccent,
          ),
          const SizedBox(height: 16),
          _DifficultyButton(
            title: "Medium",
            subtitle: "6 x 6 Grid",
            difficulty: GameDifficulty.medium,
            color: Colors.orangeAccent,
          ),
          const SizedBox(height: 16),
          _DifficultyButton(
            title: "Hard",
            subtitle: "8 x 8 Grid",
            difficulty: GameDifficulty.hard,
            color: Colors.redAccent,
          ),
        ],
      ),
    );
  }
}

class _DifficultyButton extends StatelessWidget {
  final String title;
  final String subtitle;
  final GameDifficulty difficulty;
  final Color color;

  const _DifficultyButton({
    required this.title,
    required this.subtitle,
    required this.difficulty,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
        context.read<MemoryGameProvider>().startGame(difficulty);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withOpacity(0.3), width: 2),
          gradient: LinearGradient(
            colors: [color.withOpacity(0.1), Colors.transparent],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.grid_view_rounded, color: color),
            ),
            const SizedBox(width: 20),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: color,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(subtitle, style: const TextStyle(color: Colors.white54)),
              ],
            ),
            const Spacer(),
            Icon(
              Icons.arrow_forward_ios_rounded,
              color: color.withOpacity(0.5),
              size: 16,
            ),
          ],
        ),
      ),
    );
  }
}
