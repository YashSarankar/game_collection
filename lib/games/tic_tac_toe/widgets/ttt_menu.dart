import 'package:flutter/material.dart';
import '../models/ttt_theme.dart';
import '../models/ttt_models.dart';
import 'ttt_components.dart';

class TTTMenu extends StatelessWidget {
  final VoidCallback onStart;
  final Function(GameMode) onModeSelect;
  final TTTTheme theme;

  const TTTMenu({
    super.key,
    required this.onStart,
    required this.onModeSelect,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Hero(
          tag: 'ttt_title',
          child: Material(
            color: Colors.transparent,
            child: NeonText(
              text: 'TIC TAC TOE',
              color: Colors.white,
              style: TextStyle(
                fontSize: 48,
                fontWeight: FontWeight.w900,
                letterSpacing: 4,
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          '2026 EDITION',
          style: TextStyle(
            color: Colors.white.withOpacity(0.5),
            fontSize: 12,
            letterSpacing: 8,
          ),
        ),
        const SizedBox(height: 60),
        _buildMenuButton(
          label: 'QUICK MATCH',
          icon: Icons.play_arrow_rounded,
          onTap: () => onModeSelect(GameMode.classic3x3),
          primary: true,
        ),
        const SizedBox(height: 16),
        _buildMenuButton(
          label: 'GAME MODES',
          icon: Icons.grid_view_rounded,
          onTap: () => _showModeSelection(context),
        ),
      ],
    );
  }

  Widget _buildMenuButton({
    required String label,
    required IconData icon,
    required VoidCallback onTap,
    bool primary = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 40),
      child: GestureDetector(
        onTap: onTap,
        child: GlassContainer(
          padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 24),
          opacity: primary ? 0.2 : 0.1,
          borderRadius: 15,
          child: Row(
            children: [
              Icon(icon, color: Colors.white, size: 28),
              const SizedBox(width: 20),
              Text(
                label,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.5,
                ),
              ),
              const Spacer(),
              const Icon(Icons.chevron_right_rounded, color: Colors.white54),
            ],
          ),
        ),
      ),
    );
  }

  void _showModeSelection(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => GlassContainer(
        borderRadius: 30,
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'SELECT GAME MODE',
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
                letterSpacing: 2,
              ),
            ),
            const SizedBox(height: 24),
            _buildModeItem(
              context,
              'Classic 3x3',
              'Relaxed gameplay',
              Icons.grid_3x3,
              GameMode.classic3x3,
            ),
            _buildModeItem(
              context,
              'Pro 4x4',
              'More strategy needed',
              Icons.grid_4x4,
              GameMode.pro4x4,
            ),
            _buildModeItem(
              context,
              'Extreme 5x5',
              'The ultimate challenge',
              Icons.grid_view_rounded,
              GameMode.pro5x5,
            ),
            _buildModeItem(
              context,
              'Timed Mode',
              '10s per move',
              Icons.timer_rounded,
              GameMode.timed,
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildModeItem(
    BuildContext context,
    String title,
    String sub,
    IconData icon,
    GameMode mode,
  ) {
    return ListTile(
      leading: Icon(icon, color: Colors.white),
      title: Text(
        title,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
        ),
      ),
      subtitle: Text(
        sub,
        style: TextStyle(color: Colors.white.withOpacity(0.6)),
      ),
      onTap: () {
        Navigator.pop(context);
        onModeSelect(mode);
      },
    );
  }
}
