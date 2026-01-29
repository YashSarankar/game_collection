import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import '../../core/models/game_model.dart';
import '../../core/services/haptic_service.dart';
import '../../ui/widgets/game_countdown.dart';

class MemoryMatchWidget extends StatefulWidget {
  final GameModel game;

  const MemoryMatchWidget({super.key, required this.game});

  @override
  State<MemoryMatchWidget> createState() => _MemoryMatchWidgetState();
}

class _CardItem {
  final int id;
  final IconData icon;
  final Color color;
  bool isFlipped;
  bool isMatched;

  _CardItem({
    required this.id,
    required this.icon,
    required this.color,
    this.isFlipped = false,
    this.isMatched = false,
  });
}

class _MemoryMatchWidgetState extends State<MemoryMatchWidget> {
  static const int gridSize = 4; // 4x4 grid

  List<_CardItem> cards = [];
  List<int> flippedIndices = [];

  bool isPlaying = false;
  bool isProcessing = false;
  bool _showCountdown = false;
  int matchesFound = 0;
  int moves = 0;

  HapticService? _hapticService;

  final List<IconData> _icons = [
    Icons.star,
    Icons.favorite,
    Icons.light_mode,
    Icons.dark_mode,
    Icons.pets,
    Icons.rocket_launch,
    Icons.music_note,
    Icons.diamond,
  ];

  final List<Color> _colors = [
    Colors.redAccent,
    Colors.pinkAccent,
    Colors.orangeAccent,
    Colors.purpleAccent,
    Colors.brown,
    Colors.blueAccent,
    Colors.teal,
    Colors.cyan,
  ];

  bool isPlayer1Turn = true;
  int player1Score = 0;
  int player2Score = 0;

  @override
  void initState() {
    super.initState();
    _initializeServices();
  }

  Future<void> _initializeServices() async {
    _hapticService = await HapticService.getInstance();
  }

  void _startGame() {
    setState(() {
      isPlaying = true;
      _showCountdown = true;
      player1Score = 0;
      player2Score = 0;
      isPlayer1Turn = true;
      matchesFound = 0;
      moves = 0;
      isProcessing = false;
      flippedIndices = [];

      // Create pairs
      List<_CardItem> tempCards = [];
      for (int i = 0; i < 8; i++) {
        tempCards.add(_CardItem(id: i, icon: _icons[i], color: _colors[i]));
        tempCards.add(_CardItem(id: i, icon: _icons[i], color: _colors[i]));
      }
      tempCards.shuffle(Random());
      cards = tempCards;
    });
  }

  void _onCardTap(int index) {
    if (!isPlaying ||
        _showCountdown ||
        isProcessing ||
        cards[index].isFlipped ||
        cards[index].isMatched)
      return;

    setState(() {
      cards[index].isFlipped = true;
      flippedIndices.add(index);
    });

    _hapticService?.light();

    if (flippedIndices.length == 2) {
      _checkMatch();
    }
  }

  void _checkMatch() {
    setState(() {
      isProcessing = true;
      moves++;
    });

    final index1 = flippedIndices[0];
    final index2 = flippedIndices[1];

    if (cards[index1].id == cards[index2].id) {
      Future.delayed(const Duration(milliseconds: 300), () {
        if (!mounted) return;
        setState(() {
          cards[index1].isMatched = true;
          cards[index2].isMatched = true;
          matchesFound++;
          if (isPlayer1Turn)
            player1Score++;
          else
            player2Score++;
          flippedIndices.clear();
          isProcessing = false;
        });
        _hapticService?.success();
        if (matchesFound == 8) _gameOver();
      });
    } else {
      Future.delayed(const Duration(milliseconds: 1000), () {
        if (!mounted) return;
        setState(() {
          cards[index1].isFlipped = false;
          cards[index2].isFlipped = false;
          flippedIndices.clear();
          isProcessing = false;
          isPlayer1Turn = !isPlayer1Turn;
        });
        _hapticService?.error();
      });
    }
  }

  void _gameOver() {
    setState(() => isPlaying = false);
    // ... game over logic ...
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Stack(
        children: [
          Column(
            children: [
              SafeArea(bottom: false, child: _buildHeader(isDark)),

              if (isPlaying) ...[
                // Scores
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 10,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildPlayerScore(
                        'P1',
                        player1Score,
                        isPlayer1Turn,
                        Colors.blue,
                        isDark,
                      ),
                      _buildPlayerScore(
                        'P2',
                        player2Score,
                        !isPlayer1Turn,
                        Colors.red,
                        isDark,
                      ),
                    ],
                  ),
                ),

                // Grid
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: GridView.builder(
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: gridSize,
                            crossAxisSpacing: 10,
                            mainAxisSpacing: 10,
                            childAspectRatio: 0.85,
                          ),
                      itemCount: 16,
                      itemBuilder: (context, index) =>
                          _buildCard(index, isDark),
                    ),
                  ),
                ),
              ] else if (!isPlaying)
                Expanded(
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          widget.game.icon,
                          size: 80,
                          color: Colors.blueAccent,
                        ),
                        const SizedBox(height: 24),
                        ElevatedButton(
                          onPressed: _startGame,
                          child: const Text('Start Game'),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),

          // Global Countdown Overlay
          if (_showCountdown)
            Container(
              color: Colors.black26,
              child: GameCountdown(
                onFinished: () {
                  if (mounted) {
                    Future.delayed(const Duration(milliseconds: 800), () {
                      if (mounted) setState(() => _showCountdown = false);
                    });
                  }
                },
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildHeader(bool isDark) {
    final color = isDark ? Colors.white : Colors.black;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      child: Stack(
        alignment: Alignment.center,
        children: [
          if (!isPlaying || matchesFound == 8)
            Align(
              alignment: Alignment.centerLeft,
              child: IconButton(
                onPressed: () => Navigator.pop(context),
                icon: Icon(
                  Icons.arrow_back_ios_new_rounded,
                  color: color,
                  size: 22,
                ),
              ),
            ),
          Text(
            widget.game.title,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlayerScore(
    String name,
    int score,
    bool active,
    Color color,
    bool isDark,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        color: active ? color.withOpacity(0.1) : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: active ? color : Colors.transparent,
          width: 2,
        ),
      ),
      child: Column(
        children: [
          Text(
            name,
            style: TextStyle(
              color: color,
              fontWeight: active ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          Text(
            '$score',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCard(int index, bool isDark) {
    final card = cards[index];
    return GestureDetector(
      onTap: () => _onCardTap(index),
      child: Container(
        decoration: BoxDecoration(
          color: card.isFlipped || card.isMatched
              ? Colors.white
              : Colors.grey[800],
          borderRadius: BorderRadius.circular(12),
        ),
        child: Center(
          child: card.isFlipped || card.isMatched
              ? Icon(card.icon, color: card.color, size: 30)
              : const Icon(Icons.help_outline, color: Colors.white24, size: 30),
        ),
      ),
    );
  }
}
