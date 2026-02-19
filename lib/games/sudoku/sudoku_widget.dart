import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/models/game_model.dart';
import 'providers/sudoku_provider.dart';
import 'widgets/sudoku_board.dart';
import 'widgets/game_controls.dart';
import 'widgets/daily_challenge_banner.dart';
import 'widgets/game_over_dialog.dart';
import 'sudoku_logic.dart'; // Add this for SudokuDifficulty

class SudokuWidget extends StatefulWidget {
  final GameModel game;
  const SudokuWidget({super.key, required this.game});

  @override
  State<SudokuWidget> createState() => _SudokuWidgetState();
}

class _SudokuWidgetState extends State<SudokuWidget> {
  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => SudokuProvider(),
      child: Consumer<SudokuProvider>(
        builder: (context, provider, child) {
          if (provider.isGameOver) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              _showGameOverDialog(context, provider);
            });
          }

          return Scaffold(
            body: Stack(
              children: [
                _buildBackground(context),
                SafeArea(
                  child: Column(
                    children: [
                      _buildHeader(context, provider),
                      if (provider.board.isEmpty)
                        const Expanded(child: SudokuLobby())
                      else ...[
                        _buildInfoBar(provider),
                        const DailyChallengeBanner(),
                        const Expanded(child: Center(child: SudokuBoard())),
                        const GameControls(),
                        const SizedBox(height: 16),
                        const NumberPad(),
                        const SizedBox(height: 24),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildBackground(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: isDark
              ? [const Color(0xFF121212), const Color(0xFF1E1E1E)]
              : [const Color(0xFFF8F9FA), const Color(0xFFE9ECEF)],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, SudokuProvider provider) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const SizedBox(
            width: 48,
          ), // Spacer to maintain alignment if needed, or remove
          Text(
            widget.game.title,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.2,
            ),
          ),
          IconButton(
            onPressed: () => provider.startNewGame(provider.difficulty),
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoBar(SudokuProvider provider) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _StatItem(
            label: "LEVEL",
            value: provider.difficulty.name.toUpperCase(),
          ),
          _StatItem(label: "MISTAKES", value: "${provider.mistakes}/3"),
          _StatItem(
            label: "TIME",
            value: _formatDuration(provider.elapsedTime),
          ),
        ],
      ),
    );
  }

  String _formatDuration(Duration d) {
    String twoDigits(int n) => n.toString().padLeft(2, "0");
    return "${twoDigits(d.inMinutes.remainder(60))}:${twoDigits(d.inSeconds.remainder(60))}";
  }

  void _showGameOverDialog(BuildContext context, SudokuProvider provider) {
    showGeneralDialog(
      context: context,
      barrierDismissible: false,
      barrierLabel: "GameOver",
      transitionDuration: const Duration(milliseconds: 400),
      pageBuilder: (context, anim1, anim2) => SudokuGameOverDialog(
        won: provider.won,
        difficulty: provider.difficulty.name,
        time: _formatDuration(provider.elapsedTime),
        onRestart: () {
          Navigator.pop(context);
          provider.startNewGame(provider.difficulty);
        },
      ),
      transitionBuilder: (context, anim1, anim2, child) {
        return FadeTransition(
          opacity: anim1,
          child: ScaleTransition(
            scale: CurvedAnimation(parent: anim1, curve: Curves.easeOutBack),
            child: child,
          ),
        );
      },
    );
  }
}

class _StatItem extends StatelessWidget {
  final String label;
  final String value;
  const _StatItem({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            color: isDark ? Colors.white54 : Colors.black54,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.1,
          ),
        ),
        Text(
          value,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900),
        ),
      ],
    );
  }
}

class SudokuLobby extends StatelessWidget {
  const SudokuLobby({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text(
            "Select Difficulty",
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 32),
          ...SudokuDifficulty.values.map((d) => _DifficultyCard(difficulty: d)),
        ],
      ),
    );
  }
}

class _DifficultyCard extends StatelessWidget {
  final SudokuDifficulty difficulty;
  const _DifficultyCard({required this.difficulty});

  @override
  Widget build(BuildContext context) {
    final provider = context.read<SudokuProvider>();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: InkWell(
        onTap: () => provider.startNewGame(difficulty),
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: isDark ? Colors.white.withOpacity(0.05) : Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: isDark ? Colors.white10 : Colors.black12),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blueAccent.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.grid_3x3_rounded,
                  color: Colors.blueAccent,
                ),
              ),
              const SizedBox(width: 20),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    difficulty.name.toUpperCase(),
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                  Text(
                    "${difficulty.clues} hints provided",
                    style: const TextStyle(color: Colors.grey, fontSize: 12),
                  ),
                ],
              ),
              const Spacer(),
              const Icon(Icons.play_arrow_rounded, color: Colors.blueAccent),
            ],
          ),
        ),
      ),
    );
  }
}
