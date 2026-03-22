import 'package:flutter/material.dart';
import 'screens/menu_screen.dart';
import 'arrows_theme.dart';

void main() {
  runApp(const ArrowsStandaloneApp());
}

class ArrowsStandaloneApp extends StatelessWidget {
  const ArrowsStandaloneApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Arrows Puzzle Escape',
      theme: ThemeData(
        scaffoldBackgroundColor: ArrowsTheme.background,
        colorScheme: const ColorScheme.dark(
          primary: ArrowsTheme.primaryButton,
          surface: ArrowsTheme.panelBackground,
          background: ArrowsTheme.background,
        ),
      ),
      home: const MenuScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}
