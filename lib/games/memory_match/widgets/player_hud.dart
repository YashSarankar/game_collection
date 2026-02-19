import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/memory_game_provider.dart';

class PlayerHUD extends StatelessWidget {
  const PlayerHUD({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<MemoryGameProvider>();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          // Player 1
          Expanded(
            child: _PlayerScoreCard(
              name: "Player 1",
              score: provider.player1Score,
              combo: provider.player1Combo,
              isActive: provider.isPlayer1Turn,
              color: Colors.blueAccent,
              alignment: Alignment.centerLeft,
            ),
          ),

          // Timer
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withOpacity(0.1),
              border: Border.all(color: Colors.white24),
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                CircularProgressIndicator(
                  value: provider.turnTimeRemaining / 15,
                  strokeWidth: 4,
                  backgroundColor: Colors.white10,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    provider.isPlayer1Turn
                        ? Colors.blueAccent
                        : Colors.redAccent,
                  ),
                ),
                Text(
                  "${provider.turnTimeRemaining}",
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),

          // Player 2
          Expanded(
            child: _PlayerScoreCard(
              name: "Player 2",
              score: provider.player2Score,
              combo: provider.player2Combo,
              isActive: !provider.isPlayer1Turn,
              color: Colors.redAccent,
              alignment: Alignment.centerRight,
            ),
          ),
        ],
      ),
    );
  }
}

class _PlayerScoreCard extends StatelessWidget {
  final String name;
  final int score;
  final int combo;
  final bool isActive;
  final Color color;
  final Alignment alignment;

  const _PlayerScoreCard({
    required this.name,
    required this.score,
    required this.combo,
    required this.isActive,
    required this.color,
    required this.alignment,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isActive ? color.withOpacity(0.2) : Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isActive ? color : Colors.white10, width: 2),
        boxShadow: isActive
            ? [
                BoxShadow(
                  color: color.withOpacity(0.3),
                  blurRadius: 10,
                  spreadRadius: -2,
                ),
              ]
            : [],
      ),
      child: Column(
        crossAxisAlignment: alignment == Alignment.centerLeft
            ? CrossAxisAlignment.start
            : CrossAxisAlignment.end,
        children: [
          Text(
            name,
            style: TextStyle(
              color: isActive ? color : Colors.white60,
              fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                "$score",
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                  fontSize: 24,
                ),
              ),
              if (combo > 1) ...[
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.orangeAccent,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    "x$combo",
                    style: const TextStyle(
                      color: Colors.black,
                      fontWeight: FontWeight.bold,
                      fontSize: 10,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}
