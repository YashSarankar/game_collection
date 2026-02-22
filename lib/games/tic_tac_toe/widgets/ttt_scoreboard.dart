import 'package:flutter/material.dart';
import '../models/ttt_models.dart';
import '../models/ttt_theme.dart';
import 'ttt_components.dart';

class TTTScoreboard extends StatelessWidget {
  final TTTPlayer player1;
  final TTTPlayer player2;
  final bool isXTurn;
  final TTTTheme theme;

  const TTTScoreboard({
    super.key,
    required this.player1,
    required this.player2,
    required this.isXTurn,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _buildPlayerCard(player1, isXTurn, true),
          _buildVersus(),
          _buildPlayerCard(player2, !isXTurn, false),
        ],
      ),
    );
  }

  Widget _buildPlayerCard(TTTPlayer player, bool isActive, bool isLeft) {
    return AnimatedScale(
      duration: const Duration(milliseconds: 300),
      scale: isActive ? 1.1 : 1.0,
      child: GlassContainer(
        width: 120,
        padding: const EdgeInsets.all(12),
        opacity: isActive ? 0.2 : 0.05,
        border: Border.all(
          color: isActive ? player.color : Colors.white.withOpacity(0.1),
          width: 2,
        ),
        child: Column(
          children: [
            Text(
              player.name,
              style: TextStyle(
                color: Colors.white.withOpacity(isActive ? 1.0 : 0.6),
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 8),
            Text(
              player.score.toString(),
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w900,
                fontSize: 28,
                shadows: isActive
                    ? [Shadow(color: player.color, blurRadius: 10)]
                    : null,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVersus() {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white.withOpacity(0.1),
      ),
      child: const Text(
        'VS',
        style: TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w900,
          fontSize: 12,
        ),
      ),
    );
  }
}
