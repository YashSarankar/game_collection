import 'package:flutter/material.dart';
import '../arrows_theme.dart';

class LevelCompleteScreen extends StatelessWidget {
  final int currentLevelNum;
  final VoidCallback onNextLevel;
  final VoidCallback onCollection;
  final VoidCallback onMenu;

  const LevelCompleteScreen({
    Key? key,
    required this.currentLevelNum,
    required this.onNextLevel,
    required this.onCollection,
    required this.onMenu,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final String nextDifficulty = _getNextLevelDifficulty(currentLevelNum + 1);

    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      child: Container(
        padding: const EdgeInsets.all(32),
        decoration: ArrowsTheme.glassBox,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.emoji_events_rounded,
              color: Colors.amber,
              size: 80,
            ),
            const SizedBox(height: 24),
            const Text(
              'VICTORY!',
              style: TextStyle(
                color: ArrowsTheme.textPrimary,
                fontSize: 28,
                fontWeight: FontWeight.w900,
                letterSpacing: 2,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'NEXT LEVEL: ${currentLevelNum + 1}',
              style: const TextStyle(
                color: ArrowsTheme.textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              nextDifficulty.toUpperCase(),
              style: TextStyle(
                color: ArrowsTheme.textPrimary.withOpacity(0.6),
                fontSize: 14,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.5,
              ),
            ),
            const SizedBox(height: 40),
            Column(
              children: [
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: ArrowsTheme.primaryButton,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 16),
                    minimumSize: const Size(200, 50),
                  ),
                  onPressed: onNextLevel,
                  child: const Text('GO TO NEXT LEVEL', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                ),
                const SizedBox(height: 12),
                OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: ArrowsTheme.textPrimary,
                    side: BorderSide(color: ArrowsTheme.textPrimary.withOpacity(0.5)),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 16),
                    minimumSize: const Size(200, 50),
                  ),
                  onPressed: onCollection,
                  child: const Text('LEVEL COLLECTION', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
                const SizedBox(height: 12),
                TextButton(
                  onPressed: onMenu,
                  child: Text(
                    'BACK TO MENU',
                    style: TextStyle(
                      color: ArrowsTheme.textPrimary.withOpacity(0.6),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _getNextLevelDifficulty(int levelId) {
    if (levelId % 10 == 0) return 'Nightmare';
    if (levelId % 5 == 0) return 'Hard';
    if (levelId <= 15) return 'Easy';
    if (levelId <= 40) return 'Medium';
    return 'Hard';
  }
}
