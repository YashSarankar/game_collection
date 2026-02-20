import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../core/models/game_model.dart';
import '../../core/services/haptic_service.dart';
import '../../core/services/sound_service.dart';
import '../../ui/widgets/game_countdown.dart';
import 'ludo_theme.dart';
import 'ludo_painter.dart';
import 'dice_widget.dart';
import 'player_panel.dart';
import 'ludo_animated_background.dart';

enum LudoGameState { selection, countdown, playing }

enum PieceStatus { locked, active, home, finished }

class LudoPiece {
  final int id;
  final int playerIndex;
  int
  position; // 0 to 57. 0 = base, 1-51 = global, 52-57 = home stretch, 58 = finished
  PieceStatus status;

  LudoPiece({
    required this.id,
    required this.playerIndex,
    this.position = 0,
    this.status = PieceStatus.locked,
  });
}

class LudoWidget extends StatefulWidget {
  final GameModel game;
  const LudoWidget({super.key, required this.game});

  @override
  State<LudoWidget> createState() => _LudoWidgetState();
}

class _LudoWidgetState extends State<LudoWidget> with TickerProviderStateMixin {
  late List<LudoPiece> pieces;
  int diceValue = 1;
  bool isRolling = false;
  int currentPlayerIndex = 0; // 0: Red, 1: Green, 2: Yellow, 3: Blue
  bool canRoll = true;
  List<int> movablePieceIndices = [];
  final math.Random _random = math.Random();
  HapticService? _hapticService;
  SoundService? _soundService;

  LudoGameState _gameState = LudoGameState.selection;
  int _playerCount = 4;
  List<int> finishedPlayers = []; // Indices of players who completed the game

  final List<Color> playerColors = LudoTheme.playerColors;
  final List<int> startGlobalIndices = [0, 13, 26, 39];
  final List<int> safeSquares = [
    0,
    8,
    13,
    21,
    26,
    34,
    39,
    47,
  ]; // Start squares + Stars

  @override
  void initState() {
    super.initState();
    _initHaptic();
  }

  Future<void> _initHaptic() async {
    _hapticService = await HapticService.getInstance();
    _soundService = await SoundService.getInstance();
  }

  void _startGame(int playerCount) {
    setState(() {
      _playerCount = playerCount;
      _gameState = LudoGameState.countdown;
    });
  }

  void _initGame() {
    pieces = [];
    List<int> activePlayers = [];
    if (_playerCount == 2) {
      activePlayers = [0, 2];
    } else if (_playerCount == 3) {
      activePlayers = [0, 1, 2];
    } else {
      activePlayers = [0, 1, 2, 3];
    }

    for (int p in activePlayers) {
      for (int i = 0; i < 4; i++) {
        pieces.add(LudoPiece(id: p * 4 + i, playerIndex: p));
      }
    }

    currentPlayerIndex = activePlayers.first;
    finishedPlayers = [];
    canRoll = true;
    movablePieceIndices = [];
    diceValue = 1;

    _soundService?.playSound('sounds/game_start.mp3');

    setState(() {
      _gameState = LudoGameState.playing;
    });
  }

  void rollDice() async {
    if (_gameState != LudoGameState.playing) return;
    if (!canRoll || isRolling) return;

    setState(() {
      isRolling = true;
      canRoll = false;
    });

    _hapticService?.light();

    int finalRoll = _random.nextInt(6) + 1;

    for (int i = 0; i < 8; i++) {
      await Future.delayed(const Duration(milliseconds: 75));
      if (mounted) {
        setState(() {
          diceValue = _random.nextInt(6) + 1;
        });
      }
    }

    if (mounted) {
      setState(() {
        diceValue = finalRoll;
        isRolling = false;
      });
    } else {
      return;
    }

    _hapticService?.medium();
    _calculateMovablePieces();
  }

  void _calculateMovablePieces() {
    movablePieceIndices = [];
    for (int i = 0; i < pieces.length; i++) {
      final piece = pieces[i];
      if (piece.playerIndex != currentPlayerIndex) continue;

      if (piece.status == PieceStatus.locked) {
        if (diceValue == 6) movablePieceIndices.add(i);
      } else if (piece.status == PieceStatus.active ||
          piece.status == PieceStatus.home) {
        if (piece.position + diceValue <= 57) {
          movablePieceIndices.add(i);
        } else if (piece.position + diceValue == 58) {
          movablePieceIndices.add(i);
        }
      }
    }

    if (movablePieceIndices.isEmpty) {
      _nextTurn();
    } else if (movablePieceIndices.length == 1 && diceValue != 6) {
      Future.delayed(const Duration(milliseconds: 400), () {
        if (mounted && movablePieceIndices.isNotEmpty) {
          _movePiece(movablePieceIndices.first);
        }
      });
    }
  }

  void _movePiece(int pieceIndex) async {
    if (!movablePieceIndices.contains(pieceIndex)) return;

    final piece = pieces[pieceIndex];
    movablePieceIndices = [];

    _hapticService?.selectionClick();

    if (piece.status == PieceStatus.locked) {
      _soundService?.playMoveSound('sounds/move_piece.mp3');
      setState(() {
        piece.position = 1;
        piece.status = PieceStatus.active;
      });
      _resolveMove(pieceIndex);
      return;
    }

    _soundService?.playMoveSound('sounds/move_piece.mp3');

    int steps = diceValue;
    for (int i = 0; i < steps; i++) {
      // Smoother, natural steps
      await Future.delayed(Duration(milliseconds: i == 0 ? 100 : 150));
      if (!mounted) return;
      _hapticService?.light();
      setState(() {
        piece.position++;
        if (piece.position > 51 && piece.position <= 57) {
          piece.status = PieceStatus.home;
        } else if (piece.position == 58) {
          piece.status = PieceStatus.finished;
        }
      });
      if (piece.status == PieceStatus.finished) break;
    }

    _resolveMove(pieceIndex);
  }

  void _resolveMove(int pieceIndex) {
    final piece = pieces[pieceIndex];
    bool captured = false;
    if (piece.status == PieceStatus.active) {
      int globalIdx = _getGlobalIndex(piece.playerIndex, piece.position);
      if (!safeSquares.contains(globalIdx)) {
        for (var other in pieces) {
          if (other.playerIndex != piece.playerIndex &&
              other.status == PieceStatus.active &&
              _getGlobalIndex(other.playerIndex, other.position) == globalIdx) {
            setState(() {
              other.position = 0;
              other.status = PieceStatus.locked;
            });
            _soundService?.playMoveSound('sounds/down_piece.mp3');
            captured = true;
          }
        }
      }
    }

    if (captured) {
      _hapticService?.heavy();
      _grantBonusRoll();
    } else if (piece.status == PieceStatus.finished) {
      _hapticService?.heavy();
      _checkWin();
      _grantBonusRoll();
    } else if (diceValue == 6) {
      _grantBonusRoll();
    } else {
      _nextTurn();
    }
  }

  void _grantBonusRoll() {
    setState(() {
      canRoll = true;
    });
  }

  void _nextTurn() async {
    await Future.delayed(const Duration(milliseconds: 400));
    if (!mounted) return;

    List<int> activePlayers = [];
    if (_playerCount == 2) {
      activePlayers = [0, 2];
    } else if (_playerCount == 3) {
      activePlayers = [0, 1, 2];
    } else {
      activePlayers = [0, 1, 2, 3];
    }

    // Filter out players who have already finished
    List<int> remainingPlayers = activePlayers
        .where((p) => !finishedPlayers.contains(p))
        .toList();

    if (remainingPlayers.isEmpty) return;

    setState(() {
      int currentInRemaining = remainingPlayers.indexOf(currentPlayerIndex);
      // If the current player just finished, the index might be -1.
      // We handle that by finding the next player in the rotation.
      int nextIdx;
      if (currentInRemaining == -1) {
        // Find who WOULD have been next in the full activePlayers list
        int currentInFull = activePlayers.indexOf(currentPlayerIndex);
        int searchIdx = (currentInFull + 1) % activePlayers.length;
        while (!remainingPlayers.contains(activePlayers[searchIdx])) {
          searchIdx = (searchIdx + 1) % activePlayers.length;
        }
        nextIdx = remainingPlayers.indexOf(activePlayers[searchIdx]);
      } else {
        nextIdx = (currentInRemaining + 1) % remainingPlayers.length;
      }

      currentPlayerIndex = remainingPlayers[nextIdx];
      canRoll = true;
    });
  }

  void _checkWin() {
    int finishedCount = pieces
        .where(
          (p) =>
              p.playerIndex == currentPlayerIndex &&
              p.status == PieceStatus.finished,
        )
        .length;

    if (finishedCount == 4 && !finishedPlayers.contains(currentPlayerIndex)) {
      _soundService?.playSound('sounds/victory.mp3');
      setState(() {
        finishedPlayers.add(currentPlayerIndex);
      });

      // Calculate if the game is over (only one player left)
      List<int> activePlayers = _playerCount == 2
          ? [0, 2]
          : (_playerCount == 3 ? [0, 1, 2] : [0, 1, 2, 3]);
      bool isGameOver = finishedPlayers.length >= activePlayers.length - 1;

      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => _buildVictoryOverlay(isGameOver: isGameOver),
      );
    }
  }

  Widget _buildVictoryOverlay({required bool isGameOver}) {
    final winnerIndex = finishedPlayers.last;
    final color = playerColors[winnerIndex];
    final rank = finishedPlayers.length;
    final rankSuffix = ['st', 'nd', 'rd', 'th'][rank - 1];
    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      child: Container(
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.1),
          borderRadius: BorderRadius.circular(30),
          border: Border.all(color: Colors.white24),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.3),
              blurRadius: 40,
              spreadRadius: 10,
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.emoji_events_rounded,
              color: Colors.amber,
              size: 100,
            ),
            const SizedBox(height: 24),
            Text(
              rank == 1 ? 'VICTORY!' : '$rank$rankSuffix PLACE!',
              style: LudoTheme.headerStyle(context).copyWith(fontSize: 40),
            ),
            const SizedBox(height: 16),
            Text(
              '${_getPlayerName(winnerIndex)} Player is the Master!',
              textAlign: TextAlign.center,
              style: LudoTheme.bodyStyle(context).copyWith(fontSize: 18),
            ),
            const SizedBox(height: 40),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                if (isGameOver) {
                  setState(() => _gameState = LudoGameState.selection);
                } else {
                  _nextTurn();
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: color,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 40,
                  vertical: 15,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
              ),
              child: Text(
                isGameOver
                    ? 'FINISH'
                    : 'CONTINUE FOR ${rank + 1}${['st', 'nd', 'rd', 'th'][rank > 3 ? 3 : rank]}',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getPlayerName(int index) {
    switch (index) {
      case 0:
        return "Red";
      case 1:
        return "Green";
      case 2:
        return "Yellow";
      case 3:
        return "Blue";
      default:
        return "";
    }
  }

  int _getGlobalIndex(int playerIdx, int relativePos) {
    if (relativePos <= 0 || relativePos > 51) return -1;
    return (startGlobalIndices[playerIdx] + (relativePos - 1)) % 52;
  }

  @override
  Widget build(BuildContext context) {
    switch (_gameState) {
      case LudoGameState.selection:
        return _buildSelectionScreen(context);
      case LudoGameState.countdown:
        return Container(
          color: Colors.black.withOpacity(0.8),
          child: GameCountdown(onFinished: _initGame),
        );
      case LudoGameState.playing:
        return Scaffold(
          body: Stack(
            children: [
              const AnimatedLudoBackground(),
              SafeArea(
                child: Column(
                  children: [
                    _buildTopBar(context),
                    const Spacer(),
                    _buildPlayerRow([
                      0,
                      1,
                    ]), // Red (Left), Green (Right) - Top Houses
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16.0,
                        vertical: 8,
                      ),
                      child: AspectRatio(
                        aspectRatio: 1,
                        child: _buildBoard(context),
                      ),
                    ),
                    _buildPlayerRow([
                      3,
                      2,
                    ]), // Blue (Left), Yellow (Right) - Bottom Houses
                    const Spacer(),
                    _buildBottomActionArea(context),
                  ],
                ),
              ),
            ],
          ),
        );
    }
  }

  Widget _buildSelectionScreen(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          const AnimatedLudoBackground(),
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(
                  horizontal: 32.0,
                  vertical: 24.0,
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Hero(
                      tag: 'ludo_logo',
                      child: Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.12),
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white24),
                        ),
                        child: const Icon(
                          Icons.grid_view_rounded,
                          size: 60,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      'LUDO SUPREME',
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        letterSpacing: 2.0,
                        shadows: [
                          Shadow(
                            color: Colors.black45,
                            offset: Offset(0, 4),
                            blurRadius: 10,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Select Game Mode',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.white.withOpacity(0.7),
                        letterSpacing: 1.2,
                      ),
                    ),
                    const SizedBox(height: 48),
                    _buildSelectionCard(
                      context,
                      count: 2,
                      title: '2 Players',
                      subtitle: 'Classic 1vs1 Battle',
                      icon: Icons.people_outline,
                      color: LudoTheme.red,
                    ),
                    const SizedBox(height: 16),
                    _buildSelectionCard(
                      context,
                      count: 3,
                      title: '3 Players',
                      subtitle: 'Triangle Showdown',
                      icon: Icons.groups_outlined,
                      color: LudoTheme.green,
                    ),
                    const SizedBox(height: 16),
                    _buildSelectionCard(
                      context,
                      count: 4,
                      title: '4 Players',
                      subtitle: 'Full House Mayhem',
                      icon: Icons.grid_4x4_rounded,
                      color: LudoTheme.blue,
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

  Widget _buildSelectionCard(
    BuildContext context, {
    required int count,
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
  }) {
    return GestureDetector(
      onTap: () => _startGame(count),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.1),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: Colors.white.withOpacity(0.15)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [color.withOpacity(0.5), color.withOpacity(0.2)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(icon, color: Colors.white, size: 28),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.6),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              color: Colors.white.withOpacity(0.3),
              size: 16,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopBar(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: Center(
        child: Text('LUDO CLASSIC', style: LudoTheme.headerStyle(context)),
      ),
    );
  }

  Widget _buildPlayerRow(List<int> players) {
    int leftIdx = players[0];
    int rightIdx = players[1];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      child: Row(
        children: [
          Expanded(
            flex: 6,
            child: Align(
              alignment: Alignment.centerLeft,
              child: _buildPanelForIndex(leftIdx),
            ),
          ),
          const Spacer(flex: 3),
          Expanded(
            flex: 6,
            child: Align(
              alignment: Alignment.centerRight,
              child: _buildPanelForIndex(rightIdx),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPanelForIndex(int idx) {
    bool isActive = pieces.any((p) => p.playerIndex == idx);
    if (!isActive) return const SizedBox.shrink();
    bool isCurrent = currentPlayerIndex == idx;
    return PlayerPanel(
      playerIndex: idx,
      name: _getPlayerName(idx),
      isCurrentTurn: isCurrent,
      dice: isCurrent ? _buildDiceArea(context) : null,
    );
  }

  Widget _buildBoard(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 15,
            spreadRadius: 2,
          ),
        ],
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final boardWidth = constraints.maxWidth;
          return GestureDetector(
            onTapUp: (details) =>
                _handleBoardTap(details.localPosition, boardWidth),
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                CustomPaint(
                  size: Size(boardWidth, boardWidth),
                  painter: LudoBoardPainter(),
                ),
                ...pieces.map((p) => _buildPieceWidget(p, boardWidth)),
              ],
            ),
          );
        },
      ),
    );
  }

  void _handleBoardTap(Offset localPos, double boardWidth) {
    if (movablePieceIndices.isEmpty) return;

    final cellSize = boardWidth / 15;
    final tapCol = (localPos.dx / cellSize).floor();
    final tapRow = (localPos.dy / cellSize).floor();

    // Check pieces in movablePieceIndices
    for (int idx in movablePieceIndices) {
      final p = pieces[idx];
      final rc = _getRC(p);
      final pieceRow = rc.dx.floor();
      final pieceCol = rc.dy.floor();

      // Case 1: Direct cell match
      if (pieceRow == tapRow && pieceCol == tapCol) {
        _movePiece(idx);
        return;
      }

      // Case 2: House tap for locked pieces
      if (p.status == PieceStatus.locked) {
        bool inHouse = false;
        switch (p.playerIndex) {
          case 0:
            inHouse = tapRow < 6 && tapCol < 6;
            break;
          case 1:
            inHouse = tapRow < 6 && tapCol >= 9;
            break;
          case 2:
            inHouse = tapRow >= 9 && tapCol >= 9;
            break;
          case 3:
            inHouse = tapRow >= 9 && tapCol < 6;
            break;
        }
        if (inHouse) {
          _movePiece(idx);
          return;
        }
      }
    }
  }

  Widget _buildPieceWidget(LudoPiece p, double boardWidth) {
    final pos = _getCoordinate(p, boardWidth);
    final isMovable = movablePieceIndices.contains(pieces.indexOf(p));
    final isCurrentPlayerPiece = p.playerIndex == currentPlayerIndex;
    final cellSize = boardWidth / 15;
    final color = playerColors[p.playerIndex];

    final hsl = HSLColor.fromColor(color);
    final darkerColor = hsl
        .withLightness((hsl.lightness - 0.2).clamp(0.0, 1.0))
        .toColor();

    return AnimatedPositioned(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOutBack,
      left: pos.dx,
      top: pos.dy,
      child: GestureDetector(
        onTap: () => _movePiece(pieces.indexOf(p)),
        child: SizedBox(
          width: cellSize,
          height: cellSize * 1.5,
          child: Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.bottomCenter,
            children: [
              Positioned(
                bottom: 2,
                child: Container(
                  width: cellSize * 0.75,
                  height: cellSize * 0.5,
                  decoration: BoxDecoration(
                    color: darkerColor,
                    borderRadius: BorderRadius.circular(cellSize),
                  ),
                ),
              ),
              Positioned(
                bottom: cellSize * 0.2,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: isMovable ? cellSize * 0.85 : cellSize * 0.75,
                  height: isMovable ? cellSize * 0.85 : cellSize * 0.75,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      center: const Alignment(-0.35, -0.4),
                      colors: [color.withOpacity(1.0), color, darkerColor],
                      stops: const [0.0, 0.5, 1.0],
                    ),
                    border: Border.all(
                      color: Colors.white.withOpacity(0.6),
                      width: isMovable ? 2.5 : 1,
                    ),
                    boxShadow: [
                      if (isMovable)
                        BoxShadow(
                          color: color.withOpacity(0.7),
                          blurRadius: 15,
                          spreadRadius: 3,
                        ),
                      if (isCurrentPlayerPiece && !isMovable)
                        BoxShadow(
                          color: color.withOpacity(0.4),
                          blurRadius: 8,
                          spreadRadius: 1,
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Offset _getCoordinate(LudoPiece p, double boardWidth) {
    final rc = _getRC(p); // These are now cell centers (0.5 to 14.5)
    final cellSize = boardWidth / 15;

    int indexAtSpot = 0;
    int totalAtSpot = 0;
    for (var other in pieces) {
      if (_getRC(other) == rc) {
        if (pieces.indexOf(other) < pieces.indexOf(p)) indexAtSpot++;
        totalAtSpot++;
      }
    }

    double dx = 0;
    double dy = 0;
    if (totalAtSpot > 1) {
      double offsetRadius = cellSize * 0.22;
      double angle = (2 * math.pi / totalAtSpot) * indexAtSpot;
      dx = math.cos(angle) * offsetRadius;
      dy = math.sin(angle) * offsetRadius;
    }

    // Align piece center to grid center
    double xPos = (rc.dy - 0.5) * cellSize;
    double yPos = (rc.dx - 1.25) * cellSize;

    return Offset(xPos + dx, yPos + dy);
  }

  Offset _getRC(LudoPiece p) {
    if (p.status == PieceStatus.locked) {
      int idx = p.id % 4;
      // Centers in 6x6 house: 2.1 and 3.9 (closer together)
      double rOff = (idx ~/ 2 == 0) ? 2.1 : 3.9;
      double cOff = (idx % 2 == 0) ? 2.1 : 3.9;
      switch (p.playerIndex) {
        case 0:
          return Offset(rOff, cOff);
        case 1:
          return Offset(rOff, cOff + 9);
        case 2:
          return Offset(rOff + 9, cOff + 9);
        case 3:
          return Offset(rOff + 9, cOff);
      }
    }
    if (p.status == PieceStatus.finished) return const Offset(7.5, 7.5);

    if (p.position >= 52) {
      double step = (p.position - 51.5); // Center of home steps
      switch (p.playerIndex) {
        case 0:
          return Offset(7.5, step);
        case 1:
          return Offset(step, 7.5);
        case 2:
          return Offset(7.5, 15.0 - step);
        case 3:
          return Offset(15.0 - step, 7.5);
      }
    }
    int globalIdx = _getGlobalIndex(p.playerIndex, p.position);
    return _globalToRC(globalIdx);
  }

  Offset _globalToRC(int idx) {
    // Map 0-51 to (row + 0.5, col + 0.5) for cell centers
    const List<Offset> path = [
      Offset(6.5, 1.5),
      Offset(6.5, 2.5),
      Offset(6.5, 3.5),
      Offset(6.5, 4.5),
      Offset(6.5, 5.5),
      Offset(5.5, 6.5),
      Offset(4.5, 6.5),
      Offset(3.5, 6.5),
      Offset(2.5, 6.5),
      Offset(1.5, 6.5),
      Offset(0.5, 6.5),
      Offset(0.5, 7.5),
      Offset(0.5, 8.5),
      Offset(1.5, 8.5),
      Offset(2.5, 8.5),
      Offset(3.5, 8.5),
      Offset(4.5, 8.5),
      Offset(5.5, 8.5),
      Offset(6.5, 9.5),
      Offset(6.5, 10.5),
      Offset(6.5, 11.5),
      Offset(6.5, 12.5),
      Offset(6.5, 13.5),
      Offset(6.5, 14.5),
      Offset(7.5, 14.5),
      Offset(8.5, 14.5),
      Offset(8.5, 13.5),
      Offset(8.5, 12.5),
      Offset(8.5, 11.5),
      Offset(8.5, 10.5),
      Offset(8.5, 9.5),
      Offset(9.5, 8.5),
      Offset(10.5, 8.5),
      Offset(11.5, 8.5),
      Offset(12.5, 8.5),
      Offset(13.5, 8.5),
      Offset(14.5, 8.5),
      Offset(14.5, 7.5),
      Offset(14.5, 6.5),
      Offset(13.5, 6.5),
      Offset(12.5, 6.5),
      Offset(11.5, 6.5),
      Offset(10.5, 6.5),
      Offset(9.5, 6.5),
      Offset(8.5, 5.5),
      Offset(8.5, 4.5),
      Offset(8.5, 3.5),
      Offset(8.5, 2.5),
      Offset(8.5, 1.5),
      Offset(8.5, 0.5),
      Offset(7.5, 0.5),
      Offset(6.5, 0.5),
    ];
    return path[idx % 52];
  }

  Widget _buildBottomActionArea(BuildContext context) {
    final color = playerColors[currentPlayerIndex];

    return AnimatedContainer(
      duration: const Duration(milliseconds: 400),
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        border: Border(
          top: BorderSide(color: color.withOpacity(0.3), width: 1.5),
        ),
      ),
      child: Center(
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          child: Container(
            key: ValueKey(canRoll),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
            decoration: BoxDecoration(
              color: color.withOpacity(0.15),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: color.withOpacity(0.3)),
            ),
            child: Text(
              canRoll
                  ? '${_getPlayerName(currentPlayerIndex).toUpperCase()} - TAP YOUR DICE'
                  : 'MOVE YOUR PIECE',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w900,
                fontSize: 13,
                letterSpacing: 1.5,
                shadows: [
                  Shadow(
                    color: Colors.black38,
                    offset: Offset(0, 1),
                    blurRadius: 3,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDiceArea(BuildContext context) {
    return SizedBox(
      width: 38,
      height: 38,
      child: DiceWidget(
        value: diceValue,
        isRolling: isRolling,
        onTap: rollDice,
        canRoll: canRoll,
        size: 34,
      ),
    );
  }
}
