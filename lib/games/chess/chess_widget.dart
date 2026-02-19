import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:confetti/confetti.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/models/game_model.dart';
import '../../core/services/haptic_service.dart';
import '../../core/services/sound_service.dart';
import 'chess_logic.dart';
import 'chess_controller.dart';
import 'chess_board_painter.dart';
import 'chess_theme.dart';
import 'chess_piece_widget.dart';
import 'chess_menu.dart';
import 'player_panel.dart';

class ChessWidget extends StatefulWidget {
  final GameModel game;
  const ChessWidget({super.key, required this.game});

  @override
  State<ChessWidget> createState() => _ChessWidgetState();
}

class _ChessWidgetState extends State<ChessWidget> {
  late ChessController _controller;
  late ConfettiController _confettiController;
  ChessTheme _currentTheme = ChessTheme.tournamentWood;
  bool _isGameStarted = false;

  // Board tilt state
  double _tiltX = 0.0;
  double _tiltY = 0.0;

  @override
  void initState() {
    super.initState();
    _confettiController = ConfettiController(
      duration: const Duration(seconds: 3),
    );
    _initController();
  }

  Future<void> _initController() async {
    final sound = await SoundService.getInstance();
    final haptic = await HapticService.getInstance();
    _controller = ChessController(soundService: sound, hapticService: haptic);
    _controller.addListener(_onControllerUpdate);
    if (mounted) setState(() {});
  }

  void _onControllerUpdate() {
    if (_controller.isGameOver &&
        _controller.gameStatus.toLowerCase().contains("won")) {
      _confettiController.play();
    }
  }

  @override
  void dispose() {
    _controller.removeListener(_onControllerUpdate);
    _controller.dispose();
    _confettiController.dispose();
    super.dispose();
  }

  void _startGame(GameMode mode, AIDifficulty difficulty, {int? timeSeconds}) {
    setState(() {
      _controller.initGame(
        mode,
        difficulty: difficulty,
        timeSeconds: timeSeconds,
      );
      _isGameStarted = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!_isGameStarted) {
      return ChessMenu(
        primaryColor: widget.game.primaryColor,
        onStart: (mode, diff, {timeSeconds}) =>
            _startGame(mode, diff, timeSeconds: timeSeconds),
      );
    }

    return ChangeNotifierProvider.value(
      value: _controller,
      child: Consumer<ChessController>(
        builder: (context, controller, child) {
          return Scaffold(
            body: Stack(
              children: [
                _buildBackground(),
                SafeArea(
                  child: Column(
                    children: [
                      _buildHeader(),
                      Expanded(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            _buildPlayerPanel(PlayerColor.black),
                            const SizedBox(height: 20),
                            _buildBoard(controller),
                            const SizedBox(height: 20),
                            _buildPlayerPanel(PlayerColor.white),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                if (controller.isThinking) _buildThinkingOverlay(),
                if (controller.pendingPromotion != null)
                  _buildPromotionOverlay(controller),
                if (controller.isGameOver) _buildGameOverOverlay(controller),
                Align(
                  alignment: Alignment.topCenter,
                  child: ConfettiWidget(
                    confettiController: _confettiController,
                    blastDirectionality: BlastDirectionality.explosive,
                    shouldLoop: false,
                    colors: const [
                      Colors.green,
                      Colors.blue,
                      Colors.pink,
                      Colors.orange,
                      Colors.purple,
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

  Widget _buildBackground() {
    return Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: _currentTheme.backgroundGradient,
            ),
          ),
        )
        .animate(onPlay: (c) => c.repeat(reverse: true))
        .custom(
          duration: 10.seconds,
          builder: (context, value, child) => Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  _currentTheme.backgroundGradient[0],
                  Color.lerp(
                    _currentTheme.backgroundGradient[0],
                    _currentTheme.backgroundGradient[1],
                    value,
                  )!,
                  _currentTheme.backgroundGradient[1],
                ],
              ),
            ),
          ),
        );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const SizedBox(width: 48), // Placeholder to keep title centered
          Column(
            children: [
              Text(
                _controller.gameStatus.isEmpty
                    ? "CHESS"
                    : _controller.gameStatus.toUpperCase(),
                style: TextStyle(
                  color: _controller.gameStatus.contains("Check")
                      ? Colors.redAccent
                      : Colors.white,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 2,
                ),
              ),
              if (_controller.mode == GameMode.vsAI)
                Text(
                  "LVL: ${_controller.difficulty.name.toUpperCase()}",
                  style: const TextStyle(color: Colors.white54, fontSize: 10),
                ),
            ],
          ),
          IconButton(
            icon: const Icon(Icons.palette_outlined, color: Colors.white),
            onPressed: _showThemeSelector,
          ),
        ],
      ),
    );
  }

  Widget _buildPlayerPanel(PlayerColor color) {
    final isWhite = color == PlayerColor.white;
    final isTurn = _controller.board.turn == color;
    final time = isWhite ? _controller.whiteTime : _controller.blackTime;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: PlayerPanel(
        name: isWhite
            ? "You"
            : (_controller.mode == GameMode.vsAI ? "AI Engine" : "Opponent"),
        time: time,
        isTurn: isTurn,
        color: color,
        captures: color == PlayerColor.white
            ? _controller.whiteCaptures
            : _controller.blackCaptures,
      ),
    );
  }

  Widget _buildBoard(ChessController controller) {
    double size = MediaQuery.of(context).size.width - 32;
    double squareSize = size / 8;

    return Center(
      child: GestureDetector(
        onPanUpdate: (details) {
          setState(() {
            _tiltY += details.delta.dx * 0.0005;
            _tiltX -= details.delta.dy * 0.0005;
            _tiltX = _tiltX.clamp(-0.1, 0.1);
            _tiltY = _tiltY.clamp(-0.1, 0.1);
          });
        },
        onPanEnd: (_) => setState(() {
          _tiltX = 0;
          _tiltY = 0;
        }),
        onTapDown: (details) {
          // grid selection handled by GridView inside Stack
        },
        child: Transform(
          transform: Matrix4.identity()
            ..setEntry(3, 2, 0.001)
            ..rotateX(_tiltX)
            ..rotateY(_tiltY),
          alignment: FractionalOffset.center,
          child: Container(
            width: size,
            height: size,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Stack(
                children: [
                  CustomPaint(
                    size: Size(size, size),
                    painter: ChessBoardPainter(
                      board: controller.board,
                      theme: _currentTheme,
                      selectedRow: controller.selectedRow,
                      selectedCol: controller.selectedCol,
                      validMoves: controller.validMoves,
                    ),
                  ),
                  // Hit detection grid
                  GridView.builder(
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 8,
                        ),
                    itemCount: 64,
                    itemBuilder: (context, index) {
                      int r = index ~/ 8;
                      int c = index % 8;
                      return GestureDetector(
                        onTap: () => controller.onSquareTap(r, c),
                        child: Container(
                          color: Colors.transparent,
                          child: _buildPiece(r, c, squareSize),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPiece(int r, int c, double squareSize) {
    final piece = _controller.board.board[r][c];
    if (piece == null) return const SizedBox.shrink();

    bool isSelected =
        _controller.selectedRow == r && _controller.selectedCol == c;

    return Center(
          child: ChessPieceWidget(
            piece: piece,
            size: squareSize,
            isSelected: isSelected,
          ),
        )
        .animate(key: ValueKey("${piece.type}_${piece.color}_$r$c"))
        .fadeIn(duration: 300.ms)
        .scale(begin: const Offset(0.8, 0.8), curve: Curves.easeOutBack);
  }

  Widget _buildThinkingOverlay() {
    return Container(
      color: Colors.black26,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(color: Colors.blueAccent),
            const SizedBox(height: 16),
            const Text(
              "AI IS THINKING...",
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                letterSpacing: 2,
              ),
            ).animate(onPlay: (c) => c.repeat()).shimmer(),
          ],
        ),
      ),
    );
  }

  Widget _buildGameOverOverlay(ChessController controller) {
    return Container(
      color: Colors.black87.withOpacity(0.9),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.emoji_events, color: Colors.amber, size: 80)
                .animate()
                .scale(duration: 600.ms, curve: Curves.elasticOut)
                .shimmer(delay: 600.ms),
            const SizedBox(height: 24),
            Text(
              controller.gameStatus.toUpperCase(),
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
                letterSpacing: 2,
              ),
            ).animate().fadeIn(delay: 300.ms).slideY(begin: 0.5),
            const SizedBox(height: 40),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildActionMenuButton("REPLAY", () => _controller.reset()),
                const SizedBox(width: 16),
                _buildActionMenuButton(
                  "MENU",
                  () => setState(() => _isGameStarted = false),
                ),
              ],
            ).animate().fadeIn(delay: 600.ms),
          ],
        ),
      ),
    ).animate().fadeIn();
  }

  Widget _buildActionMenuButton(String label, VoidCallback onTap) {
    return ElevatedButton(
      onPressed: onTap,
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.blueAccent,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      child: Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
    );
  }

  void _showThemeSelector() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          color: Color(0xFF1A1A1A),
          borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              "BOARD THEMES",
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              height: 100,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: [
                  _buildThemeOption(ChessTheme.tournamentWood),
                  _buildThemeOption(ChessTheme.forestGreen),
                  _buildThemeOption(ChessTheme.darkMode),
                  _buildThemeOption(ChessTheme.classicMarble),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildThemeOption(ChessTheme theme) {
    bool isSelected = _currentTheme.name == theme.name;
    return GestureDetector(
      onTap: () {
        setState(() => _currentTheme = theme);
        Navigator.pop(context);
      },
      child: Container(
        width: 120,
        margin: const EdgeInsets.only(right: 12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? Colors.blueAccent : Colors.white10,
            width: 2,
          ),
        ),
        child: Column(
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(14),
                ),
                child: Row(
                  children: [
                    Expanded(child: Container(color: theme.lightSquare)),
                    Expanded(child: Container(color: theme.darkSquare)),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(4.0),
              child: Text(
                theme.name,
                style: const TextStyle(color: Colors.white, fontSize: 10),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPromotionOverlay(ChessController controller) {
    return Container(
      color: Colors.black54,
      child: Center(
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: const Color(0xFF1E1E1E),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Colors.white10),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.5),
                blurRadius: 20,
                spreadRadius: 5,
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                "CHOOSE PROMOTION",
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 2,
                ),
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _promotionOption(controller, PieceType.queen),
                  _promotionOption(controller, PieceType.rook),
                  _promotionOption(controller, PieceType.bishop),
                  _promotionOption(controller, PieceType.knight),
                ],
              ),
            ],
          ),
        ),
      ),
    ).animate().fadeIn();
  }

  Widget _promotionOption(ChessController controller, PieceType type) {
    // Determine color from whose turn it is
    final color = controller.board.turn;

    return GestureDetector(
      onTap: () => controller.completePromotion(type),
      child: Container(
        padding: const EdgeInsets.all(12),
        margin: const EdgeInsets.symmetric(horizontal: 8),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white10),
        ),
        child: Text(
          _getPieceIcon(type, color),
          style: TextStyle(
            fontSize: 40,
            color: color == PlayerColor.white ? Colors.white : Colors.black,
            shadows: [
              Shadow(
                color: color == PlayerColor.white
                    ? Colors.black26
                    : Colors.white38,
                blurRadius: 2,
                offset: const Offset(1, 1),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _getPieceIcon(PieceType type, PlayerColor color) {
    if (color == PlayerColor.white) {
      switch (type) {
        case PieceType.pawn:
          return '♙';
        case PieceType.rook:
          return '♖';
        case PieceType.knight:
          return '♘';
        case PieceType.bishop:
          return '♗';
        case PieceType.queen:
          return '♕';
        case PieceType.king:
          return '♔';
      }
    } else {
      switch (type) {
        case PieceType.pawn:
          return '♟';
        case PieceType.rook:
          return '♜';
        case PieceType.knight:
          return '♞';
        case PieceType.bishop:
          return '♝';
        case PieceType.queen:
          return '♛';
        case PieceType.king:
          return '♚';
      }
    }
  }
}
