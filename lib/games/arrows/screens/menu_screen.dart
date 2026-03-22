import 'package:flutter/material.dart';
import '../arrows_theme.dart';
import '../controllers/game_controller.dart';
import 'game_screen.dart';
import 'collection_screen.dart';

class MenuScreen extends StatelessWidget {
  const MenuScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ArrowsTheme.background,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 40.0),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Use an icon instead of a heavy image to keep it lightweight.
                  Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      color: ArrowsTheme.panelBackground,
                      borderRadius: BorderRadius.circular(30),
                      boxShadow: [
                        BoxShadow(
                          color: ArrowsTheme.textPrimary.withOpacity(0.2),
                          blurRadius: 30,
                          spreadRadius: 5,
                        ),
                      ],
                      border: Border.all(color: ArrowsTheme.textPrimary.withOpacity(0.5), width: 2),
                    ),
                    child: const Center(
                      child: Icon(
                        Icons.call_split_rounded,
                        color: Colors.white,
                        size: 60,
                      ),
                    ),
                  ),
                  const SizedBox(height: 40),
                  
                  const Text(
                    'ARROWS',
                    style: TextStyle(
                      color: ArrowsTheme.textPrimary,
                      fontSize: 48,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 8,
                    ),
                  ),
                  
                  const SizedBox(height: 8),
                  
                  Text(
                    'PUZZLE ESCAPE',
                    style: TextStyle(
                      color: ArrowsTheme.textSecondary.withOpacity(0.8),
                      fontSize: 18,
                      letterSpacing: 10,
                    ),
                  ),
                  
                  const SizedBox(height: 60), // Reduced from 80 to save space
                  
                  _MenuButton(
                    label: 'PLAY',
                    icon: Icons.play_arrow_rounded,
                    color: ArrowsTheme.primaryButton,
                    onTap: () {
                      final controller = GameController();
                      controller.init(1); 
                      
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => GameScreen(
                            controller: controller,
                            onBack: () => Navigator.pop(context),
                          ),
                        ),
                      );
                    },
                  ),
                  
                  const SizedBox(height: 20),
                  
                  _MenuButton(
                    label: 'COLLECTION',
                    icon: Icons.grid_view_rounded,
                    color: ArrowsTheme.panelBackground,
                    textColor: ArrowsTheme.textPrimary,
                    onTap: () {
                      final controller = GameController();
                      controller.init(1).then((_) {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => CollectionScreen(
                              controller: controller,
                              onSelect: () {
                                 Navigator.pushReplacement(
                                   context,
                                   MaterialPageRoute(
                                     builder: (context) => GameScreen(
                                       controller: controller,
                                       onBack: () => Navigator.pop(context),
                                     ),
                                   ),
                                 );
                              },
                            ),
                          ),
                        );
                      });
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _MenuButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final Color textColor;
  final VoidCallback onTap;

  const _MenuButton({
    required this.label,
    required this.icon,
    required this.color,
    this.textColor = Colors.white,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 240,
      height: 60,
      decoration: BoxDecoration(
        boxShadow: color == ArrowsTheme.panelBackground ? [] : [
          BoxShadow(
            color: color.withOpacity(0.4),
            blurRadius: 20,
            offset: const Offset(0, 5),
          )
        ],
      ),
      child: Material(
        color: color,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: textColor),
              const SizedBox(width: 12),
              Text(
                label,
                style: TextStyle(
                  color: textColor,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 2,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
