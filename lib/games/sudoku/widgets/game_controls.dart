import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/sudoku_provider.dart';

class NumberPad extends StatelessWidget {
  const NumberPad({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: List.generate(
              5,
              (i) => _buildNumberButton(context, i + 1, isDark),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: List.generate(
              4,
              (i) => _buildNumberButton(context, i + 6, isDark),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNumberButton(BuildContext context, int n, bool isDark) {
    final provider = context.read<SudokuProvider>();

    return InkWell(
      onTap: () => provider.inputNumber(n),
      borderRadius: BorderRadius.circular(40),
      child: Container(
        width: 54,
        height: 54,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: isDark ? Colors.white.withOpacity(0.05) : Colors.grey[200],
          border: Border.all(
            color: isDark ? Colors.white10 : Colors.black12,
            width: 1,
          ),
        ),
        child: Center(
          child: Text(
            '$n',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.blueAccent : Colors.indigoAccent,
            ),
          ),
        ),
      ),
    );
  }
}

class GameControls extends StatelessWidget {
  const GameControls({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<SudokuProvider>();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildControlButton(
            icon: Icons.undo_rounded,
            label: "Undo",
            onTap: provider.undo,
            isDark: isDark,
          ),
          _buildControlButton(
            icon: Icons.backspace_outlined,
            label: "Erase",
            onTap: provider.erase,
            isDark: isDark,
          ),
          _buildControlButton(
            icon: provider.isNotesMode
                ? Icons.edit_rounded
                : Icons.edit_outlined,
            label: "Notes",
            onTap: provider.toggleNotesMode,
            isDark: isDark,
            isActive: provider.isNotesMode,
          ),
          _buildControlButton(
            icon: Icons.lightbulb_outline_rounded,
            label: "Hint",
            onTap: provider.useHint,
            isDark: isDark,
          ),
        ],
      ),
    );
  }

  Widget _buildControlButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    required bool isDark,
    bool isActive = false,
  }) {
    final color = isActive
        ? (isDark ? Colors.blueAccent : Colors.indigoAccent)
        : (isDark ? Colors.white70 : Colors.black54);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Column(
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 12,
                fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
