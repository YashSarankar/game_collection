import 'package:flutter/material.dart';
import '../../core/models/game_model.dart';
import 'models/ttt_models.dart';
import 'models/ttt_theme.dart';
import 'widgets/ttt_components.dart';
import 'widgets/ttt_menu.dart';
import 'screens/ttt_game_screen.dart';

class TicTacToeWidget extends StatefulWidget {
  final GameModel game;

  const TicTacToeWidget({super.key, required this.game});

  @override
  State<TicTacToeWidget> createState() => _TicTacToeWidgetState();
}

enum TTTScreen { menu, game }

class _TicTacToeWidgetState extends State<TicTacToeWidget> {
  TTTScreen _currentScreen = TTTScreen.menu;
  final TTTThemeType _themeType = TTTThemeType.neonCyber;
  GameMode _selectedMode = GameMode.classic3x3;

  void _changeScreen(TTTScreen screen) {
    setState(() {
      _currentScreen = screen;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = TTTTheme.getTheme(_themeType);

    return Scaffold(
      backgroundColor: theme.backgroundColor,
      body: AnimatedGradientBackground(
        colors: theme.backgroundGradient,
        child: Stack(
          children: [
            // Floating Particles background for all screens
            const Positioned.fill(
              child: Opacity(
                opacity: 0.1,
                child: IgnorePointer(
                  child: Center(
                    child: Hero(
                      tag: 'bg_logo',
                      child: Icon(
                        Icons.grid_3x3_rounded,
                        size: 400,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ),
            ),

            // Screen Content
            _buildActiveScreen(theme),
          ],
        ),
      ),
    );
  }

  Widget _buildActiveScreen(TTTTheme theme) {
    switch (_currentScreen) {
      case TTTScreen.menu:
        return Center(
          child: TTTMenu(
            theme: theme,
            onStart: () => _changeScreen(TTTScreen.game),
            onModeSelect: (mode) {
              setState(() => _selectedMode = mode);
              _changeScreen(TTTScreen.game);
            },
          ),
        );
      case TTTScreen.game:
        return TTTGameScreen(
          theme: theme,
          mode: _selectedMode,
          onBack: () => _changeScreen(TTTScreen.menu),
        );
    }
  }
}
