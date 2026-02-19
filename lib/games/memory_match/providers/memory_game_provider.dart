import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import '../models/memory_card.dart';
import '../../../core/services/sound_service.dart';
import '../../../core/services/haptic_service.dart';

enum GameDifficulty {
  easy(4, 4),
  medium(6, 6),
  hard(8, 8);

  final int rows;
  final int cols;
  const GameDifficulty(this.rows, this.cols);
  int get totalCards => rows * cols;
}

class MemoryGameProvider extends ChangeNotifier {
  List<MemoryCard> cards = [];
  List<int> flippedIndices = [];
  List<int> wrongMatchIndices = [];
  bool isProcessing = false;
  bool isPlayer1Turn = true;
  int player1Score = 0;
  int player2Score = 0;
  int player1Combo = 0;
  int player2Combo = 0;
  int matchesFound = 0;
  bool isGameOver = false;
  GameDifficulty difficulty = GameDifficulty.easy;

  // Services
  SoundService? _soundService;
  HapticService? _hapticService;

  // Turn Timer
  int turnTimeRemaining = 15;
  Timer? _turnTimer;
  bool isSuddenDeath = false;

  bool get isSoundEnabled => _soundService?.isEnabled ?? true;

  MemoryGameProvider() {
    _initializeServices();
  }

  Future<void> _initializeServices() async {
    _soundService = await SoundService.getInstance();
    _hapticService = await HapticService.getInstance();
  }

  static const List<IconData> availableIcons = [
    Icons.star_rounded,
    Icons.favorite_rounded,
    Icons.light_mode_rounded,
    Icons.dark_mode_rounded,
    Icons.pets_rounded,
    Icons.rocket_launch_rounded,
    Icons.music_note_rounded,
    Icons.diamond_rounded,
    Icons.auto_awesome_rounded,
    Icons.celebration_rounded,
    Icons.flutter_dash_rounded,
    Icons.games_rounded,
    Icons.sports_esports_rounded,
    Icons.bolt_rounded,
    Icons.eco_rounded,
    Icons.water_drop_rounded,
    Icons.whatshot_rounded,
    Icons.ac_unit_rounded,
    Icons.egg_rounded,
    Icons.key_rounded,
    Icons.anchor_rounded,
    Icons.beach_access_rounded,
    Icons.camera_rounded,
    Icons.coffee_rounded,
    Icons.directions_bike_rounded,
    Icons.emoji_events_rounded,
    Icons.forest_rounded,
    Icons.icecream_rounded,
    Icons.landscape_rounded,
    Icons.palette_rounded,
    Icons.sailing_rounded,
    Icons.umbrella_rounded,
  ];

  static const List<Color> availableColors = [
    Colors.redAccent,
    Colors.pinkAccent,
    Colors.orangeAccent,
    Colors.purpleAccent,
    Colors.blueAccent,
    Colors.tealAccent,
    Colors.greenAccent,
    Colors.cyanAccent,
    Colors.amberAccent,
    Colors.indigoAccent,
    Colors.limeAccent,
    Colors.deepOrangeAccent,
  ];

  void startGame(GameDifficulty diff) {
    difficulty = diff;
    player1Score = 0;
    player2Score = 0;
    player1Combo = 0;
    player2Combo = 0;
    matchesFound = 0;
    isPlayer1Turn = true;
    isGameOver = false;
    isProcessing = false;
    flippedIndices = [];

    _generateCards();
    _resetTurnTimer();
    notifyListeners();
  }

  void _generateCards() {
    final int pairsCount = difficulty.totalCards ~/ 2;
    List<MemoryCard> tempCards = [];

    final random = Random();
    List<IconData> selectedIcons = List.from(availableIcons)..shuffle(random);
    List<Color> selectedColors = List.from(availableColors)..shuffle(random);

    for (int i = 0; i < pairsCount; i++) {
      final IconData icon = selectedIcons[i % selectedIcons.length];
      final Color color = selectedColors[i % selectedColors.length];

      tempCards.add(MemoryCard(id: i, icon: icon, color: color));
      tempCards.add(MemoryCard(id: i, icon: icon, color: color));
    }

    tempCards.shuffle(random);
    cards = tempCards;
  }

  void _resetTurnTimer() {
    _turnTimer?.cancel();
    turnTimeRemaining = 15;
    _turnTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (turnTimeRemaining > 0) {
        turnTimeRemaining--;
        notifyListeners();
      } else {
        _switchTurn();
      }
    });

    if (matchesFound >= (difficulty.totalCards ~/ 2) - 2 && !isSuddenDeath) {
      isSuddenDeath = true;
      _soundService?.playSound('sounds/sudden_death.mp3'); // If exists
    }
  }

  void _switchTurn() {
    isPlayer1Turn = !isPlayer1Turn;
    if (isPlayer1Turn)
      player1Combo = 0;
    else
      player2Combo = 0;
    _resetTurnTimer();
    if (isSuddenDeath) turnTimeRemaining = 8; // Faster turns in sudden death
    notifyListeners();
  }

  bool onCardTap(int index) {
    if (isGameOver ||
        isProcessing ||
        cards[index].isFlipped ||
        cards[index].isMatched) {
      return false;
    }

    _hapticService?.light();
    _soundService?.playPop();

    cards[index].isFlipped = true;
    flippedIndices.add(index);
    notifyListeners();

    if (flippedIndices.length == 2) {
      _checkMatch();
    }
    return true;
  }

  void _checkMatch() {
    isProcessing = true;
    notifyListeners();

    final int index1 = flippedIndices[0];
    final int index2 = flippedIndices[1];

    if (cards[index1].id == cards[index2].id) {
      // It's a match!
      Timer(const Duration(milliseconds: 500), () {
        cards[index1].isMatched = true;
        cards[index2].isMatched = true;
        matchesFound++;

        _soundService?.playSuccess();
        _hapticService?.success();

        int points = 10;
        if (isPlayer1Turn) {
          player1Combo++;
          points += (player1Combo - 1) * 5; // Bonus for combo
          player1Score += points;
          if (player1Combo > 1) _soundService?.playPoint();
        } else {
          player2Combo++;
          points += (player2Combo - 1) * 5;
          player2Score += points;
          if (player2Combo > 1) _soundService?.playPoint();
        }

        flippedIndices.clear();
        isProcessing = false;

        if (matchesFound == difficulty.totalCards ~/ 2) {
          _endGame();
        } else {
          // Player who matched gets to go again, reset timer
          _resetTurnTimer();
        }
        notifyListeners();
      });
    } else {
      // Not a match
      wrongMatchIndices = [index1, index2];
      _soundService?.playError();
      _hapticService?.error();
      notifyListeners();

      Timer(const Duration(milliseconds: 1000), () {
        cards[index1].isFlipped = false;
        cards[index2].isFlipped = false;
        flippedIndices.clear();
        wrongMatchIndices.clear();
        isProcessing = false;
        _switchTurn();
        notifyListeners();
      });
    }
  }

  void usePowerUpReveal() {
    if (isProcessing || isGameOver) return;

    isProcessing = true;
    List<int> previouslyFlipped = cards
        .asMap()
        .entries
        .where((e) => e.value.isFlipped && !e.value.isMatched)
        .map((e) => e.key)
        .toList();

    for (var card in cards) {
      if (!card.isMatched) card.isFlipped = true;
    }
    notifyListeners();

    Timer(const Duration(seconds: 3), () {
      for (int i = 0; i < cards.length; i++) {
        if (!cards[i].isMatched && !previouslyFlipped.contains(i)) {
          cards[i].isFlipped = false;
        }
      }
      isProcessing = false;
      notifyListeners();
    });
  }

  void useHint() {
    if (isProcessing || isGameOver) return;

    // Find an unmatched pair
    List<int> unmatchedIds = cards
        .where((c) => !c.isMatched)
        .map((c) => c.id)
        .toSet()
        .toList();

    if (unmatchedIds.isEmpty) return;

    int targetId = unmatchedIds[Random().nextInt(unmatchedIds.length)];
    List<int> pairIndices = [];
    for (int i = 0; i < cards.length; i++) {
      if (cards[i].id == targetId) pairIndices.add(i);
    }

    isProcessing = true;
    for (int idx in pairIndices) {
      cards[idx].isFlipped = true;
    }
    notifyListeners();

    Timer(const Duration(seconds: 2), () {
      for (int idx in pairIndices) {
        if (!cards[idx].isMatched) cards[idx].isFlipped = false;
      }
      isProcessing = false;
      notifyListeners();
    });
  }

  void _endGame() {
    isGameOver = true;
    _turnTimer?.cancel();
    _soundService?.playGameOver();
    notifyListeners();
  }

  void toggleSound() async {
    if (_soundService != null) {
      await _soundService!.setSoundEnabled(!_soundService!.isEnabled);
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _turnTimer?.cancel();
    super.dispose();
  }
}
