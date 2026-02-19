import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/models/game_model.dart';
import 'providers/memory_game_provider.dart';
import 'widgets/game_board.dart';
import 'widgets/game_lobby.dart';
import 'widgets/player_hud.dart';
import 'widgets/game_over_dialog.dart';

class MemoryMatchWidget extends StatefulWidget {
  final GameModel game;

  const MemoryMatchWidget({super.key, required this.game});

  @override
  State<MemoryMatchWidget> createState() => _MemoryMatchWidgetState();
}

class _MemoryMatchWidgetState extends State<MemoryMatchWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _bgController;

  @override
  void initState() {
    super.initState();
    _bgController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _bgController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => MemoryGameProvider(),
      child: Consumer<MemoryGameProvider>(
        builder: (context, provider, child) {
          // Listen for game over to show dialog
          if (provider.isGameOver) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              _showGameOverDialog(context);
            });
          }

          return Scaffold(
            body: Stack(
              children: [
                // Animated Gradient Background
                _buildAnimatedBackground(),

                SafeArea(
                  child: Column(
                    children: [
                      _buildHeader(context, provider),

                      if (provider.cards.isEmpty)
                        const Expanded(child: GameLobby())
                      else ...[
                        const PlayerHUD(),
                        if (provider.isSuddenDeath) _buildSuddenDeathBanner(),
                        const Expanded(
                          child: SingleChildScrollView(child: GameBoard()),
                        ),
                        _buildBottomActions(context, provider),
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

  Widget _buildAnimatedBackground() {
    return AnimatedBuilder(
      animation: _bgController,
      builder: (context, child) {
        return Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color.lerp(
                  const Color(0xFF0F2027),
                  const Color(0xFF2C5364),
                  _bgController.value,
                )!,
                Color.lerp(
                  const Color(0xFF203A43),
                  const Color(0xFF0F2027),
                  _bgController.value,
                )!,
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeader(BuildContext context, MemoryGameProvider provider) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Center(
        child: Text(
          widget.game.title,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.2,
          ),
        ),
      ),
    );
  }

  Widget _buildBottomActions(
    BuildContext context,
    MemoryGameProvider provider,
  ) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _ActionButton(
            icon: Icons.lightbulb_outline_rounded,
            label: "Reveal",
            onTap: provider.usePowerUpReveal,
            color: Colors.amberAccent,
          ),
          _ActionButton(
            icon: Icons.auto_fix_high_rounded,
            label: "Hint",
            onTap: () {
              provider.useHint();
            },
            color: Colors.cyanAccent,
          ),
          _ActionButton(
            icon: Icons.refresh_rounded,
            label: "Reset",
            onTap: () => provider.startGame(provider.difficulty),
            color: Colors.white70,
          ),
        ],
      ),
    );
  }

  Widget _buildSuddenDeathBanner() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 8),
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.red.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.redAccent.withOpacity(0.5)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.bolt_rounded, color: Colors.redAccent, size: 20),
          const SizedBox(width: 8),
          const Text(
            "SUDDEN DEATH: 8s TURNS!",
            style: TextStyle(
              color: Colors.redAccent,
              fontWeight: FontWeight.bold,
              fontSize: 12,
              letterSpacing: 1.5,
            ),
          ),
          const SizedBox(width: 8),
          const Icon(Icons.bolt_rounded, color: Colors.redAccent, size: 20),
        ],
      ),
    );
  }

  void _showGameOverDialog(BuildContext context) {
    showGeneralDialog(
      context: context,
      barrierDismissible: false,
      barrierLabel: "GameOver",
      transitionDuration: const Duration(milliseconds: 400),
      pageBuilder: (context, anim1, anim2) => const GameOverDialog(),
      transitionBuilder: (context, anim1, anim2, child) {
        return ScaleTransition(
          scale: CurvedAnimation(parent: anim1, curve: Curves.elasticOut),
          child: FadeTransition(opacity: anim1, child: child),
        );
      },
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color color;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.05),
              shape: BoxShape.circle,
              border: Border.all(color: color.withOpacity(0.3)),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
