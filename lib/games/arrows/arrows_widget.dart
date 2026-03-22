import 'package:flutter/material.dart';
import '../../core/models/game_model.dart';
import 'screens/menu_screen.dart';
import 'arrows_theme.dart';

class ArrowsGameWidget extends StatelessWidget {
  final GameModel game;

  const ArrowsGameWidget({Key? key, required this.game}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // We launch into MenuScreen but keep the theme consistent with Arrows styling
    return Theme(
      data: ThemeData(
        scaffoldBackgroundColor: ArrowsTheme.background,
        colorScheme: const ColorScheme.dark(
          primary: ArrowsTheme.primaryButton,
          surface: ArrowsTheme.panelBackground,
        ),
      ),
      child: const MenuScreen(),
    );
  }
}
