import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/memory_game_provider.dart';
import 'card_widget.dart';

class GameBoard extends StatelessWidget {
  const GameBoard({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<MemoryGameProvider>();
    final difficulty = provider.difficulty;

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final double spacing = 8.0;
          final int crossAxisCount = difficulty.cols;

          return GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: crossAxisCount,
              crossAxisSpacing: spacing,
              mainAxisSpacing: spacing,
              childAspectRatio: 0.85,
            ),
            itemCount: provider.cards.length,
            itemBuilder: (context, index) {
              return CardWidget(
                card: provider.cards[index],
                onTap: () => provider.onCardTap(index),
                isWrong: provider.wrongMatchIndices.contains(index),
              );
            },
          );
        },
      ),
    );
  }
}
