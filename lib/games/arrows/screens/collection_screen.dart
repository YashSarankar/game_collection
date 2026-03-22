import 'package:flutter/material.dart';
import '../controllers/game_controller.dart';
import '../arrows_theme.dart';

class CollectionScreen extends StatelessWidget {
  final GameController controller;
  final VoidCallback onSelect;

  const CollectionScreen({
    Key? key,
    required this.controller,
    required this.onSelect,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ArrowsTheme.background,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 24.0),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back_ios_new_rounded, color: ArrowsTheme.textPrimary),
                    onPressed: () => Navigator.pop(context),
                  ),
                  const Expanded(
                    child: Text(
                      'COLLECTION',
                      style: TextStyle(
                        color: ArrowsTheme.textPrimary,
                        fontSize: 28,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 2,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(width: 48), // Spacer to balance back button
                ],
              ),
            ),
            Expanded(
              child: GridView.builder(
                padding: const EdgeInsets.all(24),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 4,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                ),
                itemCount: 100, // Show 100 initial levels
                itemBuilder: (context, index) {
                  final levelId = index + 1;
                  final isUnlocked = levelId <= controller.maxUnlockedLevel;
                  
                  return GestureDetector(
                    onTap: () {
                      if (isUnlocked) {
                        controller.loadSpecificLevel(levelId);
                        onSelect();
                      }
                    },
                    child: Container(
                      decoration: BoxDecoration(
                        color: isUnlocked ? ArrowsTheme.panelBackground : Colors.white.withOpacity(0.03),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isUnlocked ? ArrowsTheme.textPrimary.withOpacity(0.3) : Colors.white10,
                        ),
                        boxShadow: isUnlocked ? [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.2),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          )
                        ] : [],
                      ),
                      child: Center(
                        child: isUnlocked 
                          ? Text(
                              '$levelId',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w900,
                                fontSize: 20,
                              ),
                            )
                          : const Icon(Icons.lock_rounded, color: Colors.white12, size: 20),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
