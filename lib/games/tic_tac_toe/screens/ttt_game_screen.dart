import 'dart:async';
import 'package:flutter/material.dart';
import '../models/ttt_models.dart';
import '../models/ttt_theme.dart';
import '../../../core/services/haptic_service.dart';
import '../widgets/ttt_components.dart';
import '../widgets/ttt_board.dart';
import '../widgets/ttt_scoreboard.dart';
import '../widgets/ttt_victory_overlay.dart';

class TTTGameScreen extends StatefulWidget {
  final TTTTheme theme;
  final GameMode mode;
  final VoidCallback onBack;

  const TTTGameScreen({
    super.key,
    required this.theme,
    required this.mode,
    required this.onBack,
  });

  @override
  State<TTTGameScreen> createState() => _TTTGameScreenState();
}

class _TTTGameScreenState extends State<TTTGameScreen> {
  late TTTGameState gameState;
  late TTTPlayer playerX;
  late TTTPlayer playerO;
  late DateTime startTime;
  HapticService? _hapticService;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _setupGame();
    _initServices();
  }

  void _setupGame() {
    int size = 3;
    if (widget.mode == GameMode.pro4x4) size = 4;
    if (widget.mode == GameMode.pro5x5) size = 5;

    gameState = TTTGameState.initial(size, widget.mode);
    playerX = TTTPlayer(
      name: 'Player 1',
      avatar: '1',
      color: widget.theme.playerXColor,
      piece: 'X',
    );
    playerO = TTTPlayer(
      name: 'Player 2',
      avatar: '2',
      color: widget.theme.playerOColor,
      piece: 'O',
    );
    startTime = DateTime.now();

    if (widget.mode == GameMode.timed) {
      _startTimer();
    }
  }

  Future<void> _initServices() async {
    _hapticService = await HapticService.getInstance();
  }

  void _startTimer() {
    _timer?.cancel();
    gameState = gameState.copyWith(timeLeft: const Duration(seconds: 10));
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (gameState.timeLeft!.inSeconds <= 0) {
        _onMove(-1, -1); // Skip turn or random move
      } else {
        setState(() {
          gameState = gameState.copyWith(
            timeLeft: gameState.timeLeft! - const Duration(seconds: 1),
          );
        });
      }
    });
  }

  void _resetGame() {
    setState(() {
      gameState = TTTGameState.initial(gameState.gridSize, widget.mode);
      startTime = DateTime.now();
      if (widget.mode == GameMode.timed) _startTimer();
    });
  }

  void _onMove(int row, int col) {
    if (gameState.winner != null || gameState.isDraw) return;
    if (row != -1 && gameState.board[row][col].isNotEmpty) return;

    _hapticService?.light();

    setState(() {
      final newBoard = List<List<String>>.from(
        gameState.board.map((r) => List<String>.from(r)),
      );
      final currentPlayer = gameState.isXTurn ? 'X' : 'O';

      if (row != -1) {
        newBoard[row][col] = currentPlayer;
      }

      final winResult = _checkWinner(newBoard, row, col, currentPlayer);

      if (winResult != null) {
        _timer?.cancel();
        gameState = gameState.copyWith(
          board: newBoard,
          winner: currentPlayer,
          winningLine: winResult,
        );
        _handleWin(currentPlayer);
      } else if (_isBoardFull(newBoard)) {
        _timer?.cancel();
        gameState = gameState.copyWith(board: newBoard, isDraw: true);
        _handleDraw();
      } else {
        gameState = gameState.copyWith(
          board: newBoard,
          isXTurn: !gameState.isXTurn,
        );
        if (widget.mode == GameMode.timed) _startTimer();
      }
    });
  }

  void _handleWin(String winner) {
    _hapticService?.success();

    setState(() {
      if (winner == 'X') {
        playerX.score++;
      } else {
        playerO.score++;
      }
    });

    // Check for series win in tournament mode (Best of 5)
    bool seriesOver = false;
    if (widget.mode == GameMode.tournament) {
      if (playerX.score >= 3 || playerO.score >= 3) seriesOver = true;
    }

    _showGameOverDialog(
      winner == 'X' ? playerX.name : playerO.name,
      seriesOver ? 'TOURNAMENT CHAMPION!' : 'Victory!',
      isSeriesWin: seriesOver,
    );
  }

  void _handleDraw() {
    _showGameOverDialog('Draw', 'No Winner!');
  }

  void _showGameOverDialog(
    String winner,
    String sub, {
    bool isSeriesWin = false,
  }) {
    showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.7),
      builder: (context) => Stack(
        children: [
          if (winner != 'Draw')
            IgnorePointer(
              child: TTTVictoryOverlay(
                color: winner == playerX.name
                    ? widget.theme.playerXColor
                    : widget.theme.playerOColor,
                winner: winner,
              ),
            ),
          _GameOverDialog(
            title: winner,
            subtitle: sub,
            onRematch: () {
              Navigator.pop(context);
              if (isSeriesWin) {
                playerX.score = 0;
                playerO.score = 0;
              }
              _resetGame();
            },
            onMenu: () {
              Navigator.pop(context);
              widget.onBack();
            },
          ),
        ],
      ),
    );
  }

  List<Offset>? _checkWinner(
    List<List<String>> board,
    int row,
    int col,
    String player,
  ) {
    if (row == -1) return null; // Timed out move
    final size = board.length;

    // Check row
    bool rowWin = true;
    for (int i = 0; i < size; i++) {
      if (board[row][i] != player) rowWin = false;
    }
    if (rowWin) {
      return List.generate(size, (i) => Offset(i.toDouble(), row.toDouble()));
    }

    // Check col
    bool colWin = true;
    for (int i = 0; i < size; i++) {
      if (board[i][col] != player) colWin = false;
    }
    if (colWin) {
      return List.generate(size, (i) => Offset(col.toDouble(), i.toDouble()));
    }

    // Check main diagonal
    if (row == col) {
      bool diagWin = true;
      for (int i = 0; i < size; i++) {
        if (board[i][i] != player) diagWin = false;
      }
      if (diagWin) {
        return List.generate(size, (i) => Offset(i.toDouble(), i.toDouble()));
      }
    }

    // Check anti diagonal
    if (row + col == size - 1) {
      bool antiDiagWin = true;
      for (int i = 0; i < size; i++) {
        if (board[i][size - 1 - i] != player) antiDiagWin = false;
      }
      if (antiDiagWin) {
        return List.generate(
          size,
          (i) => Offset((size - 1 - i).toDouble(), i.toDouble()),
        );
      }
    }

    return null;
  }

  bool _isBoardFull(List<List<String>> board) {
    for (var row in board) {
      if (row.contains('')) return false;
    }
    return true;
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        child: Column(
          children: [
            _buildTopBar(),
            TTTScoreboard(
              player1: playerX,
              player2: playerO,
              isXTurn: gameState.isXTurn,
              theme: widget.theme,
            ),
            if (gameState.timeLeft != null) _buildTimerBar(),
            const Spacer(),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: TTTBoard(
                gameState: gameState,
                theme: widget.theme,
                onMove: _onMove,
              ),
            ),
            const Spacer(),
            _buildBottomControls(),
          ],
        ),
      ),
    );
  }

  Widget _buildTopBar() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const SizedBox(width: 48), // Placeholder to keep title centered
          Text(
            widget.mode.name.replaceAll('GameMode.', '').toUpperCase(),
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              letterSpacing: 2,
            ),
          ),
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: _resetGame,
          ),
        ],
      ),
    );
  }

  Widget _buildTimerBar() {
    final progress = gameState.timeLeft!.inSeconds / 10;
    return Container(
      width: 200,
      height: 4,
      margin: const EdgeInsets.symmetric(vertical: 20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(2),
      ),
      child: FractionallySizedBox(
        alignment: Alignment.centerLeft,
        widthFactor: progress,
        child: Container(
          decoration: BoxDecoration(
            color: progress < 0.3 ? Colors.red : Colors.green,
            borderRadius: BorderRadius.circular(2),
            boxShadow: [
              BoxShadow(
                color: (progress < 0.3 ? Colors.red : Colors.green).withOpacity(
                  0.5,
                ),
                blurRadius: 5,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBottomControls() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.info_outline, color: Colors.white24, size: 16),
          const SizedBox(width: 8),
          Text(
            gameState.isXTurn ? "PLAYER 1'S TURN (X)" : "PLAYER 2'S TURN (O)",
            style: TextStyle(
              color: Colors.white.withOpacity(0.5),
              fontWeight: FontWeight.bold,
              letterSpacing: 1.2,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

class _GameOverDialog extends StatelessWidget {
  final String title;
  final String subtitle;
  final VoidCallback onRematch;
  final VoidCallback onMenu;

  const _GameOverDialog({
    required this.title,
    required this.subtitle,
    required this.onRematch,
    required this.onMenu,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.black54,
      child: Center(
        child: GlassContainer(
          width: 300,
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                subtitle.toUpperCase(),
                style: const TextStyle(
                  color: Colors.white54,
                  fontSize: 12,
                  letterSpacing: 4,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                title.toUpperCase(),
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 40),
              ElevatedButton(
                onPressed: onRematch,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: Colors.black,
                  minimumSize: const Size(double.infinity, 50),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                ),
                child: const Text(
                  'REMATCH',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: onMenu,
                child: const Text(
                  'BACK TO MENU',
                  style: TextStyle(color: Colors.white54),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
