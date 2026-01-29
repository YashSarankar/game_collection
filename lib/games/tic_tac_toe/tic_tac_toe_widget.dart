import 'package:flutter/material.dart';
import '../../core/models/game_model.dart';
import '../../core/constants/game_constants.dart';
import '../../core/services/haptic_service.dart';
import '../../ui/widgets/game_countdown.dart';
import '../../ui/widgets/game_over_dialog.dart';

class TicTacToeWidget extends StatefulWidget {
  final GameModel game;

  const TicTacToeWidget({super.key, required this.game});

  @override
  State<TicTacToeWidget> createState() => _TicTacToeWidgetState();
}

class _TicTacToeWidgetState extends State<TicTacToeWidget> {
  static const int gridSize = GameConstants.ticTacToeGridSize;

  late List<List<String>> board;
  bool isXTurn = true;
  bool isGameOver = false;
  bool isPlaying = false;
  bool _showCountdown = false;
  int moveCount = 0;
  String winner = '';

  HapticService? _hapticService;

  @override
  void initState() {
    super.initState();
    _initializeServices();
    _resetBoard();
  }

  Future<void> _initializeServices() async {
    _hapticService = await HapticService.getInstance();
  }

  void _resetBoard() {
    board = List.generate(gridSize, (_) => List.filled(gridSize, ''));
    isXTurn = true;
    isGameOver = false;
    moveCount = 0;
    winner = '';
  }

  void _startGame() {
    setState(() {
      _resetBoard();
      isPlaying = true;
      _showCountdown = true;
    });
  }

  void _onTileTap(int row, int col) {
    if (!isPlaying ||
        _showCountdown ||
        isGameOver ||
        board[row][col].isNotEmpty)
      return;

    _hapticService?.light();

    setState(() {
      board[row][col] = isXTurn ? 'X' : 'O';
      moveCount++;

      if (_checkWinner(row, col)) {
        isGameOver = true;
        winner = isXTurn ? 'X' : 'O';
        _hapticService?.success();
        _showGameOverDialog(winner);
      } else if (moveCount == gridSize * gridSize) {
        isGameOver = true;
        _hapticService?.medium();
        _showGameOverDialog('Draw');
      } else {
        isXTurn = !isXTurn;
      }
    });
  }

  bool _checkWinner(int row, int col) {
    final player = board[row][col];
    if (board[row].every((cell) => cell == player)) return true;
    if (board.every((r) => r[col] == player)) return true;
    if (row == col) {
      if (List.generate(
        gridSize,
        (i) => board[i][i],
      ).every((cell) => cell == player))
        return true;
    }
    if (row + col == gridSize - 1) {
      if (List.generate(
        gridSize,
        (i) => board[i][gridSize - 1 - i],
      ).every((cell) => cell == player))
        return true;
    }
    return false;
  }

  void _showGameOverDialog(String result) {
    String message = result == 'Draw' ? "It's a Draw!" : "Player $result Wins!";
    Future.delayed(const Duration(milliseconds: 500), () {
      if (!mounted) return;
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => GameOverDialog(
          gameId: widget.game.id,
          score: 0,
          customMessage: message,
          onRestart: () {
            Navigator.pop(context);
            _startGame();
          },
          onHome: () {
            Navigator.pop(context);
            Navigator.pop(context);
          },
          showRewardedAdOption: false,
        ),
      );
    });
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
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 24),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _buildPlayerIndicator('X', isXTurn, isDark),
                      const SizedBox(width: 32),
                      _buildPlayerIndicator('O', !isXTurn, isDark),
                    ],
                  ),
                ),
                Expanded(
                  child: Center(
                    child: AspectRatio(
                      aspectRatio: 1,
                      child: Container(
                        margin: const EdgeInsets.all(24),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: isDark
                              ? Colors.white.withOpacity(0.1)
                              : Colors.black.withOpacity(0.05),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Column(
                          children: List.generate(gridSize, (row) {
                            return Expanded(
                              child: Row(
                                children: List.generate(gridSize, (col) {
                                  return Expanded(
                                    child: _buildTile(row, col, isDark),
                                  );
                                }),
                              ),
                            );
                          }),
                        ),
                      ),
                    ),
                  ),
                ),
              ] else
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
                        const Text(
                          "PVP Local Multiplayer",
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey,
                            letterSpacing: 1.2,
                          ),
                        ),
                        const SizedBox(height: 32),
                        ElevatedButton(
                          onPressed: _startGame,
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 48,
                              vertical: 16,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(30),
                            ),
                          ),
                          child: const Text(
                            'Start Match',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),

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
          if (!isPlaying || isGameOver)
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
          if (isPlaying)
            Align(
              alignment: Alignment.centerRight,
              child: IconButton(
                onPressed: () {
                  _hapticService?.light();
                  _startGame();
                },
                icon: Icon(
                  Icons.refresh_rounded,
                  color: color.withOpacity(0.7),
                  size: 24,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildPlayerIndicator(String player, bool isActive, bool isDark) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      decoration: BoxDecoration(
        color: isActive
            ? (player == 'X' ? Colors.blue : Colors.red)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(30),
        border: Border.all(
          color: isActive ? Colors.transparent : Colors.grey.withOpacity(0.3),
          width: 2,
        ),
      ),
      child: Text(
        'Player $player',
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: isActive ? Colors.white : Colors.grey,
        ),
      ),
    );
  }

  Widget _buildTile(int row, int col, bool isDark) {
    final value = board[row][col];
    return GestureDetector(
      onTap: () => _onTileTap(row, col),
      child: Container(
        margin: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: isDark ? Colors.white.withOpacity(0.05) : Colors.white,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Center(
          child: value.isEmpty
              ? null
              : Icon(
                  value == 'X' ? Icons.close : Icons.circle_outlined,
                  size: 48,
                  color: value == 'X' ? Colors.blue : Colors.red,
                ),
        ),
      ),
    );
  }
}
