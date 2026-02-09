import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/models/game_model.dart';
import '../../core/constants/game_constants.dart';
import '../../core/services/haptic_service.dart';
import '../../core/services/sound_service.dart';
import '../../ui/widgets/game_countdown.dart';
import '../../ui/widgets/game_over_dialog.dart';

enum Direction { up, down, left, right }

class SnakeGameWidget extends StatefulWidget {
  final GameModel game;

  const SnakeGameWidget({super.key, required this.game});

  @override
  State<SnakeGameWidget> createState() => _SnakeGameWidgetState();
}

class _SnakeGameWidgetState extends State<SnakeGameWidget> {
  static const int gridSize = GameConstants.snakeGridSize;

  List<Point<int>> snake = [Point(10, 10)];
  Point<int> food = Point(15, 15);
  Direction direction = Direction.right;
  Direction? nextDirection;

  int score = 0;
  bool isPlaying = false;
  bool isPaused = false;
  bool isGameOver = false;
  bool _showCountdown = false;

  Timer? gameTimer;
  HapticService? _hapticService;
  SoundService? _soundService;

  @override
  void initState() {
    super.initState();
    _initializeServices();
    _generateFood();
  }

  Future<void> _initializeServices() async {
    _hapticService = await HapticService.getInstance();
    _soundService = await SoundService.getInstance();
  }

  @override
  void dispose() {
    gameTimer?.cancel();
    super.dispose();
  }

  void _startGame() {
    setState(() {
      snake = [Point(10, 10)];
      direction = Direction.right;
      nextDirection = null;
      score = 0;
      isPlaying = true;
      isPaused = false;
      isGameOver = false;
      _showCountdown = true;
    });

    _generateFood();
  }

  void _startGameLoop() {
    gameTimer?.cancel();
    gameTimer = Timer.periodic(GameConstants.snakeTickDuration, (timer) {
      if (!isPaused && isPlaying && !_showCountdown) {
        _updateGame();
      }
    });
  }

  void _updateGame() {
    if (nextDirection != null) {
      direction = nextDirection!;
      nextDirection = null;
    }

    final head = snake.first;
    Point<int> newHead;

    switch (direction) {
      case Direction.up:
        newHead = Point(head.x, head.y - 1);
        break;
      case Direction.down:
        newHead = Point(head.x, head.y + 1);
        break;
      case Direction.left:
        newHead = Point(head.x - 1, head.y);
        break;
      case Direction.right:
        newHead = Point(head.x + 1, head.y);
        break;
    }

    // Check collision with walls
    if (newHead.x < 0 ||
        newHead.x >= gridSize ||
        newHead.y < 0 ||
        newHead.y >= gridSize) {
      _endGame();
      return;
    }

    // Check collision with self
    if (snake.contains(newHead)) {
      _endGame();
      return;
    }

    setState(() {
      snake.insert(0, newHead);

      // Check if food is eaten
      if (newHead == food) {
        score += 10;
        _generateFood();
        _hapticService?.light();
        _soundService?.playMoveSound('sounds/snake_eat.mp3');
      } else {
        snake.removeLast();
      }
    });
  }

  void _generateFood() {
    // Check for win condition (snake fills entire grid)
    if (snake.length >= gridSize * gridSize) {
      isGameOver = true;
      isPlaying = false;
      _showGameOverDialog(); // Technically a win, but standard dialog for now
      return;
    }

    final random = Random();
    Point<int> newFood;

    do {
      newFood = Point(random.nextInt(gridSize), random.nextInt(gridSize));
    } while (snake.contains(newFood));

    setState(() {
      food = newFood;
    });
  }

  void _changeDirection(Direction newDirection) {
    // Prevent multiple moves in one tick to avoid 180-degree turns
    if (nextDirection != null) return;

    // Prevent reversing direction
    if ((direction == Direction.up && newDirection == Direction.down) ||
        (direction == Direction.down && newDirection == Direction.up) ||
        (direction == Direction.left && newDirection == Direction.right) ||
        (direction == Direction.right && newDirection == Direction.left)) {
      return;
    }

    nextDirection = newDirection;
  }

  void _togglePause() {
    setState(() {
      isPaused = !isPaused;
    });
    _hapticService?.light();
  }

  void _endGame() {
    gameTimer?.cancel();
    setState(() {
      isPlaying = false;
      isGameOver = true;
    });
    _hapticService?.error();

    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) {
        _showGameOverDialog();
      }
    });
  }

  void _showGameOverDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => GameOverDialog(
        gameId: widget.game.id,
        score: score,
        onRestart: () {
          Navigator.pop(context);
          _startGame();
        },
        onHome: () {
          Navigator.pop(context);
          Navigator.pop(context);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AnnotatedRegion(
      value: SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
        systemNavigationBarColor: Theme.of(context).scaffoldBackgroundColor,
        systemNavigationBarIconBrightness: isDark
            ? Brightness.light
            : Brightness.dark,
      ),
      child: Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        body: Column(
          children: [
            SafeArea(bottom: false, child: _buildHeader(isDark)),

            // Game Area
            Expanded(
              child: Center(
                child: AspectRatio(
                  aspectRatio: 1,
                  child: Container(
                    margin: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF1A1A2E) : Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: GameColors.snakeGreen,
                        width: 2,
                      ),
                      boxShadow: isDark
                          ? []
                          : [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.1),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                    ),
                    child: Stack(
                      children: [
                        !isPlaying && !isGameOver
                            ? _buildStartScreen(isDark)
                            : _buildGameGrid(isDark),
                        if (_showCountdown)
                          Container(
                            decoration: BoxDecoration(
                              color: Colors.black26,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: GameCountdown(
                              onFinished: () {
                                if (mounted) {
                                  _startGameLoop();
                                  Future.delayed(
                                    const Duration(milliseconds: 800),
                                    () {
                                      if (mounted) {
                                        setState(() => _showCountdown = false);
                                      }
                                    },
                                  );
                                }
                              },
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ),

            // Controls
            if (isPlaying) _buildControls(isDark),
          ],
        ),
      ),
    );
  }

  Widget _buildControls(bool isDark) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 40, top: 10),
      child: Container(
        decoration: BoxDecoration(
          color: isDark
              ? Colors.white.withOpacity(0.05)
              : Colors.black.withOpacity(0.03),
          borderRadius: BorderRadius.circular(30),
        ),
        padding: const EdgeInsets.all(10),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildControlButton(
              Icons.keyboard_arrow_up_rounded,
              Direction.up,
              isDark,
            ),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildControlButton(
                  Icons.keyboard_arrow_left_rounded,
                  Direction.left,
                  isDark,
                ),
                // Center button (can be pause or empty)
                Container(
                  width: 70,
                  height: 70,
                  margin: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: isDark
                        ? Colors.white.withOpacity(0.05)
                        : Colors.black.withOpacity(0.03),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: IconButton(
                    onPressed: _togglePause,
                    icon: Icon(
                      isPaused ? Icons.play_arrow_rounded : Icons.pause_rounded,
                      size: 32,
                      color: isDark ? Colors.white54 : Colors.black45,
                    ),
                  ),
                ),
                _buildControlButton(
                  Icons.keyboard_arrow_right_rounded,
                  Direction.right,
                  isDark,
                ),
              ],
            ),
            _buildControlButton(
              Icons.keyboard_arrow_down_rounded,
              Direction.down,
              isDark,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildControlButton(IconData icon, Direction dir, bool isDark) {
    return GestureDetector(
      onTapDown: (_) {
        _changeDirection(dir);
        _hapticService?.light(); // Add haptic feedback for button press
      },
      child: Container(
        margin: const EdgeInsets.all(4),
        width: 80,
        height: 80,
        decoration: BoxDecoration(
          color: isDark
              ? Colors.white.withOpacity(0.12)
              : Colors.black.withOpacity(0.06),
          borderRadius: BorderRadius.circular(24), // Squircle shape
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Icon(
          icon,
          size: 40,
          color: isDark ? Colors.white : Colors.black87,
        ),
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
          // Back Button on the left
          if (!isPlaying && !isGameOver)
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

          // Centered Title
          Text(
            widget.game.title,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: color,
              letterSpacing: -0.5,
            ),
          ),

          // Score Chip on the right
          Align(
            alignment: Alignment.centerRight,
            child: Padding(
              padding: const EdgeInsets.only(right: 8),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: GameColors.snakeGreen.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: GameColors.snakeGreen.withOpacity(0.3),
                    width: 1,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.stars_rounded,
                      color: GameColors.snakeGreen,
                      size: 16,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '$score',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: GameColors.snakeGreen,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStartScreen(bool isDark) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(widget.game.icon, size: 80, color: GameColors.snakeGreen),
          const SizedBox(height: 24),
          Text(
            'Tap to Start',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : Colors.black,
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _startGame,
            style: ElevatedButton.styleFrom(
              backgroundColor: GameColors.snakeGreen,
              padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text(
              'Start Game',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGameGrid(bool isDark) {
    return GridView.builder(
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: gridSize,
      ),
      itemCount: gridSize * gridSize,
      itemBuilder: (context, index) {
        final x = index % gridSize;
        final y = index ~/ gridSize;
        final point = Point(x, y);

        final isSnakeHead = snake.isNotEmpty && point == snake.first;
        final isSnakeBody = snake.contains(point) && !isSnakeHead;
        final isFood = point == food;

        // Grid lines for better visibility in light mode
        final isEven = (x + y) % 2 == 0;
        final gridColor = isDark
            ? Colors.transparent
            : (isEven ? Colors.grey.withOpacity(0.05) : Colors.transparent);

        return Container(
          margin: const EdgeInsets.all(0.5),
          decoration: BoxDecoration(
            color: isSnakeHead
                ? GameColors.snakeGreen
                : isSnakeBody
                ? GameColors.snakeGreen.withOpacity(0.7)
                : isFood
                ? GameColors.snakeFood
                : gridColor,
            borderRadius: BorderRadius.circular(2),
          ),
        );
      },
    );
  }
}
