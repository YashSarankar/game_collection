import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/providers/score_provider.dart';
import '../../core/providers/coins_provider.dart';
import '../../core/services/ad_service.dart';
import '../../core/services/haptic_service.dart';

class GameOverDialog extends StatefulWidget {
  final String gameId;
  final int score;
  final VoidCallback onRestart;
  final VoidCallback onHome;
  final bool showRewardedAdOption;
  final String? customMessage;

  const GameOverDialog({
    super.key,
    required this.gameId,
    required this.score,
    required this.onRestart,
    required this.onHome,
    this.showRewardedAdOption = false,
    this.customMessage,
  });

  @override
  State<GameOverDialog> createState() => _GameOverDialogState();
}

class _GameOverDialogState extends State<GameOverDialog> {
  AdService? _adService;
  HapticService? _hapticService;
  bool _isNewHighScore = false;

  @override
  void initState() {
    super.initState();
    _initializeServices();
    // Only check high score if we are tracking score (no custom message)
    if (widget.customMessage == null) {
      _checkHighScore();
    }
  }

  Future<void> _initializeServices() async {
    _adService = await AdService.getInstance();
    _hapticService = await HapticService.getInstance();
  }

  Future<void> _checkHighScore() async {
    final scoreProvider = Provider.of<ScoreProvider>(context, listen: false);
    final isNew = await scoreProvider.saveScore(widget.gameId, widget.score);

    setState(() {
      _isNewHighScore = isNew;
    });

    if (isNew) {
      await _hapticService?.success();
    }
  }

  Future<void> _watchAdForReward() async {
    final canShow = _adService?.isRewardedAdReady ?? false;

    if (canShow) {
      await _adService?.showRewardedAd(
        onUserEarnedReward: (reward) async {
          // Give extra coins or retry
          final coinsProvider = Provider.of<CoinsProvider>(
            context,
            listen: false,
          );
          await coinsProvider.addCoins(50);

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('You earned 50 bonus coins!')),
            );
          }
        },
      );
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Ad not available right now')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final scoreProvider = Provider.of<ScoreProvider>(context);
    final highScore = scoreProvider.getHighScore(widget.gameId);

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              const Color(0xFFFF8C00),
              const Color(0xFFFF8C00).withOpacity(0.8),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Game Over Icon
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.sports_esports,
                size: 48,
                color: Colors.white,
              ),
            ),

            const SizedBox(height: 16),

            // Title
            const Text(
              'Game Over',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),

            const SizedBox(height: 24),

            // Score Display OR Custom Message
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: widget.customMessage != null
                  ? Column(
                      children: [
                        Text(
                          widget.customMessage!,
                          style: const TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    )
                  : Column(
                      children: [
                        const Text(
                          'Your Score',
                          style: TextStyle(fontSize: 16, color: Colors.white70),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '${widget.score}',
                          style: const TextStyle(
                            fontSize: 48,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        if (_isNewHighScore) ...[
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.amber,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.emoji_events,
                                  size: 16,
                                  color: Colors.white,
                                ),
                                SizedBox(width: 4),
                                Text(
                                  'New High Score!',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ] else ...[
                          const SizedBox(height: 8),
                          Text(
                            'Best: $highScore',
                            style: const TextStyle(
                              fontSize: 14,
                              color: Colors.white70,
                            ),
                          ),
                        ],
                      ],
                    ),
            ),

            const SizedBox(height: 24),

            // Rewarded Ad Option
            if (widget.showRewardedAdOption &&
                (_adService?.isRewardedAdReady ?? false))
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: OutlinedButton.icon(
                  onPressed: _watchAdForReward,
                  icon: const Icon(Icons.play_circle_outline),
                  label: const Text('Watch Ad for 50 Coins'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white,
                    side: const BorderSide(color: Colors.white, width: 2),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 12,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),

            // Action Buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: widget.onHome,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white,
                      side: const BorderSide(color: Colors.white, width: 2),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text('Home'),
                  ),
                ),

                const SizedBox(width: 12),

                Expanded(
                  child: ElevatedButton(
                    onPressed: widget.onRestart,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: const Color(0xFFFF8C00),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'Restart',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
