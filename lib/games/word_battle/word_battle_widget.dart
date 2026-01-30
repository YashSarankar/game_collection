import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import '../../core/models/game_model.dart';
import '../../core/services/haptic_service.dart';
import '../../core/services/sound_service.dart';
import 'word_battle_logic.dart';

class WordBattleWidget extends StatefulWidget {
  final GameModel game;

  const WordBattleWidget({super.key, required this.game});

  @override
  State<WordBattleWidget> createState() => _WordBattleWidgetState();
}

class _WordBattleWidgetState extends State<WordBattleWidget>
    with TickerProviderStateMixin {
  late WordBattleLogic _logic;
  late HapticService _hapticService;
  late SoundService _soundService;
  bool _servicesInitialized = false;

  bool _isGameOver = false;
  bool _isPlaying = false;
  bool _isPvP = false;
  int _currentPlayer = 1; // 1 or 2
  int _p1Score = 0;
  int _p2Score = 0;
  int _secondsRemaining = 60;
  Timer? _timer;
  WordDifficulty _difficulty = WordDifficulty.normal;

  String _message = "";
  Color _messageColor = Colors.white;
  Timer? _messageTimer;

  // Animation controllers
  late AnimationController _gridController;
  late AnimationController _scorePopController;
  final List<AnimationController> _letterControllers = [];

  @override
  void initState() {
    super.initState();
    _logic = WordBattleLogic();
    _initializeServices();

    _gridController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );

    _scorePopController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );

    for (
      int i = 0;
      i < WordBattleLogic.gridSize * WordBattleLogic.gridSize;
      i++
    ) {
      _letterControllers.add(
        AnimationController(
          vsync: this,
          duration: const Duration(milliseconds: 200),
        ),
      );
    }
  }

  Future<void> _initializeServices() async {
    _hapticService = await HapticService.getInstance();
    _soundService = await SoundService.getInstance();
    if (mounted) {
      setState(() {
        _servicesInitialized = true;
      });
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _messageTimer?.cancel();
    _gridController.dispose();
    _scorePopController.dispose();
    for (var controller in _letterControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  void _startGame({bool pvp = false}) {
    setState(() {
      _isPvP = pvp;
      _isPlaying = true;
      _isGameOver = false;
      _currentPlayer = 1;
      _p1Score = 0;
      _p2Score = 0;

      // Dynamic time based on difficulty
      if (pvp) {
        _secondsRemaining = _difficulty == WordDifficulty.easy
            ? 45
            : (_difficulty == WordDifficulty.hard ? 20 : 30);
      } else {
        _secondsRemaining = _difficulty == WordDifficulty.easy
            ? 90
            : (_difficulty == WordDifficulty.hard ? 45 : 60);
      }

      _message = "";
      _logic.difficulty = _difficulty;
      _logic.generateGrid();
    });

    _gridController.forward(from: 0);
    _startTimer();
    _soundService.playGameStart();
    _hapticService.medium();
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      setState(() {
        if (_secondsRemaining > 0) {
          _secondsRemaining--;
          if (_secondsRemaining <= 10) {
            _hapticService.light();
          }
        } else {
          if (_isPvP && _currentPlayer == 1) {
            _nextTurn();
          } else {
            _endGame();
          }
        }
      });
    });
  }

  void _nextTurn() {
    _hapticService.medium();
    _soundService.playSuccess();
    setState(() {
      _currentPlayer = 2;
      _secondsRemaining = _difficulty == WordDifficulty.easy
          ? 45
          : (_difficulty == WordDifficulty.hard ? 20 : 30);
      _logic.clearSelection();
      _logic.generateGrid();
    });
    _gridController.forward(from: 0);
  }

  void _endGame() {
    _timer?.cancel();
    setState(() {
      _isPlaying = false;
      _isGameOver = true;
    });
    _soundService.playSuccess();
    _hapticService.success();
  }

  void _onLetterTap(int index) {
    if (!_isPlaying) return;

    bool added = _logic.selectLetter(index);
    if (added) {
      _hapticService.light();
      _letterControllers[index]
          .forward(from: 0)
          .then((_) => _letterControllers[index].reverse());
      setState(() {});
    }
  }

  void _submitWord() {
    if (!_isPlaying || _logic.currentWord.isEmpty) return;

    final result = _logic.submitWord();
    if (result != null) {
      if (result['valid']) {
        int wordScore = result['score'];
        setState(() {
          if (_isPvP) {
            if (_currentPlayer == 1)
              _p1Score += wordScore;
            else
              _p2Score += wordScore;
          } else {
            _p1Score += wordScore;
          }
          _showMessage("+ $wordScore ${result['word']}", Colors.greenAccent);
        });
        _scorePopController.forward(from: 0);
        _soundService.playPoint();
        _hapticService.medium();
      } else {
        setState(() {
          _showMessage(result['message'], Colors.orangeAccent);
        });
        _hapticService.error();
      }
    }
    setState(() {});
  }

  void _showHint() {
    if (!_isPlaying || _isPvP) return;

    String? hint = _logic.findAiWord();
    if (hint != null) {
      setState(() {
        _showMessage("Try: ${hint.toUpperCase()}", Colors.lightBlueAccent);
      });
      _hapticService.medium();
    } else {
      setState(() {
        _showMessage("No words found!", Colors.redAccent);
      });
      _hapticService.error();
    }
  }

  void _showMessage(String text, Color color) {
    _messageTimer?.cancel();
    setState(() {
      _message = text;
      _messageColor = color;
    });
    _messageTimer = Timer(const Duration(seconds: 2), () {
      if (mounted) {
        setState(() {
          _message = "";
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!_servicesInitialized) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              widget.game.primaryColor.withOpacity(0.8),
              widget.game.primaryColor,
              widget.game.secondaryColor,
            ],
          ),
        ),
        child: SafeArea(
          child: Stack(
            children: [
              Column(
                children: [
                  _buildHeader(),
                  const Spacer(),
                  _buildMessage(),
                  _buildCurrentWordDisplay(),
                  const SizedBox(height: 20),
                  _buildGrid(),
                  const SizedBox(height: 30),
                  _buildControls(),
                  const Spacer(),
                ],
              ),
              if (!_isPlaying && !_isGameOver) _buildStartMenu(),
              if (_isGameOver) _buildGameOver(),

              // Back Button
              if (!_isPlaying)
                Positioned(
                  top: 10,
                  left: 10,
                  child: IconButton(
                    icon: const Icon(
                      Icons.arrow_back_ios_new,
                      color: Colors.white,
                    ),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _buildScoreDisplay(1),
          _buildTimerDisplay(),
          if (_isPvP)
            _buildScoreDisplay(2)
          else
            GestureDetector(
              onTap: _showHint,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: Colors.white10,
                  borderRadius: BorderRadius.circular(15),
                ),
                child: const Row(
                  children: [
                    Icon(
                      Icons.lightbulb_outline,
                      color: Colors.yellow,
                      size: 16,
                    ),
                    SizedBox(width: 4),
                    Text(
                      "HINT",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildScoreDisplay(int player) {
    bool isActive = _isPvP && _currentPlayer == player;
    int score = (player == 1) ? _p1Score : _p2Score;

    return Column(
      children: [
        Text(
          _isPvP ? "PLAYER $player" : "SCORE",
          style: TextStyle(
            color: Colors.white.withOpacity(isActive || !_isPvP ? 1.0 : 0.5),
            fontWeight: FontWeight.bold,
            fontSize: 12,
          ),
        ),
        ScaleTransition(
          scale: Tween<double>(begin: 1.0, end: 1.2).animate(
            CurvedAnimation(
              parent: _scorePopController,
              curve: Curves.elasticOut,
            ),
          ),
          child: Text(
            "$score",
            style: TextStyle(
              color: Colors.white.withOpacity(isActive || !_isPvP ? 1.0 : 0.5),
              fontWeight: FontWeight.w900,
              fontSize: 32,
            ),
          ),
        ),
        if (isActive)
          Container(
            height: 4,
            width: 40,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
      ],
    );
  }

  Widget _buildTimerDisplay() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.black26,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Icon(
            Icons.timer,
            color: _secondsRemaining <= 10 ? Colors.redAccent : Colors.white,
            size: 20,
          ),
          const SizedBox(width: 8),
          Text(
            "$_secondsRemaining",
            style: TextStyle(
              color: _secondsRemaining <= 10 ? Colors.redAccent : Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 20,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessage() {
    return AnimatedOpacity(
      opacity: _message.isEmpty ? 0 : 1,
      duration: const Duration(milliseconds: 300),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.black45,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          _message,
          style: TextStyle(
            color: _messageColor,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
      ),
    );
  }

  Widget _buildCurrentWordDisplay() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 20),
      child: Text(
        _logic.currentWord.isEmpty
            ? "SELECT LETTERS"
            : _logic.currentWord.toUpperCase(),
        style: TextStyle(
          color: Colors.white.withOpacity(
            _logic.currentWord.isEmpty ? 0.3 : 1.0,
          ),
          fontSize: 40,
          fontWeight: FontWeight.w900,
          letterSpacing: 4,
        ),
      ),
    );
  }

  Widget _buildGrid() {
    return Container(
      width: 330,
      height: 330,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white10,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white24, width: 2),
      ),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: WordBattleLogic.gridSize,
          crossAxisSpacing: 10,
          mainAxisSpacing: 10,
        ),
        itemCount: WordBattleLogic.gridSize * WordBattleLogic.gridSize,
        itemBuilder: (context, index) {
          bool isSelected = _logic.selectedPositions.contains(index);
          bool isLastSelected =
              _logic.selectedPositions.isNotEmpty &&
              _logic.selectedPositions.last == index;

          return GestureDetector(
            onTap: () => _onLetterTap(index),
            child: ScaleTransition(
              scale: Tween<double>(begin: 1.0, end: 1.1).animate(
                CurvedAnimation(
                  parent: _letterControllers[index],
                  curve: Curves.easeOut,
                ),
              ),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                decoration: BoxDecoration(
                  color: isSelected
                      ? (isLastSelected ? Colors.white : Colors.white70)
                      : Colors.white12,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: Colors.white.withOpacity(0.3),
                            blurRadius: 8,
                            spreadRadius: 2,
                          ),
                        ]
                      : [],
                ),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        _logic.grid[index],
                        style: TextStyle(
                          color: isSelected ? Colors.black : Colors.white,
                          fontSize: 32,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      Text(
                        "${WordBattleLogic.letterValues[_logic.grid[index]] ?? 1}",
                        style: TextStyle(
                          color: isSelected ? Colors.black54 : Colors.white54,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildControls() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _circleButton(
          icon: Icons.refresh,
          onTap: () {
            _hapticService.medium();
            setState(() => _logic.clearSelection());
          },
          color: Colors.white24,
        ),
        const SizedBox(width: 10), // Reduced from 15
        GestureDetector(
          onTap: _submitWord,
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 25,
              vertical: 12,
            ), // Reduced padding
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(30),
              boxShadow: [
                BoxShadow(
                  color: Colors.black26,
                  blurRadius: 10,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: const Text(
              "SUBMIT",
              style: TextStyle(
                color: Colors.black,
                fontSize: 22,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ),
        const SizedBox(width: 15),
        _circleButton(
          icon: Icons.backspace_outlined,
          onTap: () {
            if (_logic.selectedPositions.isNotEmpty) {
              _hapticService.light();
              setState(() {
                _logic.selectedPositions.removeLast();
                _logic.currentWord = _logic.currentWord.substring(
                  0,
                  _logic.currentWord.length - 1,
                );
              });
            }
          },
          color: Colors.white24,
        ),
      ],
    );
  }

  Widget _circleButton({
    required IconData icon,
    required VoidCallback onTap,
    required Color color,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 60,
        height: 60,
        decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        child: Icon(icon, color: Colors.white, size: 30),
      ),
    );
  }

  Widget _buildStartMenu() {
    return BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
      child: Container(
        color: Colors.black.withOpacity(0.6),
        width: double.infinity,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.white.withOpacity(0.4),
                      blurRadius: 20,
                      spreadRadius: 5,
                    ),
                  ],
                ),
                child: Icon(
                  widget.game.icon,
                  size: 60,
                  color: widget.game.primaryColor,
                ),
              ),
              const SizedBox(height: 30),
              Text(
                widget.game.title.toUpperCase(),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 36,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 4,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                widget.game.subtitle,
                style: TextStyle(
                  color: Colors.white.withOpacity(0.6),
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 40),
              _buildDifficultySelector(),
              const SizedBox(height: 40),
              _menuButton(
                "SOLO MODE",
                () => _startGame(pvp: false),
                widget.game.primaryColor,
              ),
              const SizedBox(height: 16),
              _menuButton(
                "PVP BATTLE",
                () => _startGame(pvp: true),
                Colors.white.withOpacity(0.15),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDifficultySelector() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      margin: const EdgeInsets.symmetric(horizontal: 30),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(25),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: WordDifficulty.values.map((diff) {
              bool isSelected = _difficulty == diff;
              return GestureDetector(
                onTap: () {
                  _hapticService.selectionClick();
                  setState(() => _difficulty = diff);
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 18,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: isSelected ? Colors.white : Colors.transparent,
                    borderRadius: BorderRadius.circular(18),
                    boxShadow: isSelected
                        ? [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 5,
                              offset: const Offset(0, 2),
                            ),
                          ]
                        : [],
                  ),
                  child: Text(
                    diff.name.toUpperCase(),
                    style: TextStyle(
                      color: isSelected ? Colors.black : Colors.white70,
                      fontWeight: isSelected
                          ? FontWeight.bold
                          : FontWeight.w500,
                      fontSize: 13,
                      letterSpacing: 1.2,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _menuButton(String text, VoidCallback onTap, Color color) {
    bool isTransparent = color == Colors.white.withOpacity(0.15);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 280,
        height: 60,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(18),
          boxShadow: isTransparent
              ? []
              : [
                  BoxShadow(
                    color: color.withOpacity(0.3),
                    blurRadius: 15,
                    offset: const Offset(0, 8),
                  ),
                ],
        ),
        child: Center(
          child: Text(
            text,
            style: TextStyle(
              color: isTransparent ? Colors.white : Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.5,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildGameOver() {
    String winnerText = "";
    if (_isPvP) {
      if (_p1Score > _p2Score)
        winnerText = "PLAYER 1 WINS!";
      else if (_p2Score > _p1Score)
        winnerText = "PLAYER 2 WINS!";
      else
        winnerText = "IT'S A DRAW!";
    } else {
      winnerText = "SCORE: $_p1Score";
    }

    return BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
      child: Container(
        color: Colors.black.withOpacity(0.7),
        width: double.infinity,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                "GAME OVER",
                style: TextStyle(
                  color: Colors.white.withOpacity(0.6),
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 3,
                ),
              ),
              const SizedBox(height: 20),
              Text(
                winnerText,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 42,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 60),
              _menuButton(
                "PLAY AGAIN",
                () => _startGame(pvp: _isPvP),
                widget.game.primaryColor,
              ),
              const SizedBox(height: 16),
              _menuButton(
                "EXIT MENU",
                () => setState(() => _isGameOver = false),
                Colors.white.withOpacity(0.15),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
