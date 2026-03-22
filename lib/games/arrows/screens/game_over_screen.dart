import 'package:flutter/material.dart';
import '../arrows_theme.dart';

class GameOverScreen extends StatelessWidget {
  final VoidCallback onRetry;
  final VoidCallback onMenu;
  final VoidCallback onCollection;

  const GameOverScreen({
    Key? key,
    required this.onRetry,
    required this.onMenu,
    required this.onCollection,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
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
              Icons.heart_broken_rounded,
              color: ArrowsTheme.arrowUp,
              size: 80,
            ),
            const SizedBox(height: 24),
            const Text(
              'GAME OVER',
              style: TextStyle(
                color: ArrowsTheme.arrowUp,
                fontSize: 28,
                fontWeight: FontWeight.bold,
                letterSpacing: 2,
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'You ran out of lives!',
              style: TextStyle(
                color: ArrowsTheme.textSecondary,
                fontSize: 16,
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
                  onPressed: onCollection,
                  child: const Text('LEVEL COLLECTION', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                ),
                const SizedBox(height: 12),
                 OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: ArrowsTheme.textPrimary,
                    side: const BorderSide(color: ArrowsTheme.textPrimary),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 16),
                    minimumSize: const Size(200, 50),
                  ),
                  onPressed: onMenu,
                  child: const Text('BACK TO MENU', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
