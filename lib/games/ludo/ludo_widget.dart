import 'dart:math';
import 'package:flutter/material.dart';
import '../../core/models/game_model.dart';
import '../../core/services/haptic_service.dart';
import '../../core/services/sound_service.dart';
import '../../ui/widgets/game_countdown.dart';

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
  HapticService? _hapticService;
  SoundService? _soundService;

  LudoGameState _gameState = LudoGameState.selection;
  int _playerCount = 4;

  // Board colors
  final List<Color> playerColors = [
    Colors.red,
    Colors.green,
    Colors.yellow,
    Colors.blue,
  ];

  // Start indices on global path (0-51)
  final List<int> startGlobalIndices = [0, 13, 26, 39];

  // Safe squares (global indices)
  final List<int> safeSquares = [1, 9, 14, 22, 27, 35, 40, 48];

  @override
  void initState() {
    super.initState();
    _initHaptic();
    // Don't init game yet, wait for selection
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
    // For 2 players, we use Red (0) and Yellow (2) as they are opposite
    // For 3 players, we use Red (0), Green (1), Yellow (2)
    // For 4 players, we use all

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
    canRoll = true;
    movablePieceIndices = [];
    diceValue = 1;

    // Play game start sound
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

    // Play dice roll sound - await to ensure it plays before animation completes
    await _soundService?.playSound('sounds/dice_roll.mp3');

    // Generate final roll immediately
    int finalRoll = Random().nextInt(6) + 1;

    // Animation - 8 frames at 75ms = 600ms total for more dramatic rolling
    for (int i = 0; i < 8; i++) {
      await Future.delayed(const Duration(milliseconds: 75));
      if (mounted) {
        setState(() {
          diceValue = Random().nextInt(6) + 1;
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
      // Auto-move if only one piece can move and didn't roll a 6
      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted && movablePieceIndices.isNotEmpty) {
          _movePiece(movablePieceIndices.first);
        }
      });
    }
  }

  void _movePiece(int pieceIndex) async {
    if (!movablePieceIndices.contains(pieceIndex)) return;

    final piece = pieces[pieceIndex];
    movablePieceIndices = []; // Clear highlights

    _hapticService?.selectionClick();

    if (piece.status == PieceStatus.locked) {
      // Play move sound once when moving piece from base
      _soundService?.playMoveSound('sounds/move_piece.mp3');
      setState(() {
        piece.position = 1;
        piece.status = PieceStatus.active;
      });
      _resolveMove(
        pieceIndex,
      ); // Check for captures even on start square (though usually safe)
      return;
    }

    // Play move sound once at the start of movement
    _soundService?.playMoveSound('sounds/move_piece.mp3');

    // Incremental movement animation
    int steps = diceValue;
    for (int i = 0; i < steps; i++) {
      await Future.delayed(const Duration(milliseconds: 200));
      if (!mounted) return;
      _hapticService?.light();
      // No sound in loop - only haptic feedback
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

    // After move resolution
    _resolveMove(pieceIndex);
  }

  void _resolveMove(int pieceIndex) {
    final piece = pieces[pieceIndex];

    // Check Capture
    bool captured = false;
    if (piece.status == PieceStatus.active) {
      int globalIdx = _getGlobalIndex(piece.playerIndex, piece.position);
      if (!safeSquares.contains(globalIdx)) {
        for (var other in pieces) {
          if (other.playerIndex != piece.playerIndex &&
              other.status == PieceStatus.active &&
              _getGlobalIndex(other.playerIndex, other.position) == globalIdx) {
            // Capture!
            setState(() {
              other.position = 0;
              other.status = PieceStatus.locked;
            });
            // Play down piece sound for capture
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
    await Future.delayed(const Duration(milliseconds: 500));
    if (!mounted) return;

    List<int> activePlayers = [];
    if (_playerCount == 2) {
      activePlayers = [0, 2];
    } else if (_playerCount == 3) {
      activePlayers = [0, 1, 2];
    } else {
      activePlayers = [0, 1, 2, 3];
    }

    setState(() {
      int currentActiveIdx = activePlayers.indexOf(currentPlayerIndex);
      int nextActiveIdx = (currentActiveIdx + 1) % activePlayers.length;
      currentPlayerIndex = activePlayers[nextActiveIdx];
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
    if (finishedCount == 4) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          title: Text('Player ${_getPlayerName(currentPlayerIndex)} Wins!'),
          content: const Text('Congratulations! All tokens reached home.'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                setState(() => _gameState = LudoGameState.selection);
              },
              child: const Text('New Game'),
            ),
          ],
        ),
      );
    }
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
    final theme = Theme.of(context);

    switch (_gameState) {
      case LudoGameState.selection:
        return _buildSelectionScreen(context);
      case LudoGameState.countdown:
        return Container(
          color: Colors.black.withOpacity(0.8),
          child: GameCountdown(onFinished: _initGame),
        );
      case LudoGameState.playing:
        return Container(
          color: theme.scaffoldBackgroundColor,
          child: Column(
            children: [
              _buildHeader(context),
              Expanded(
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: AspectRatio(
                      aspectRatio: 1,
                      child: _buildBoard(context),
                    ),
                  ),
                ),
              ),
              _buildDiceArea(context),
            ],
          ),
        );
    }
  }

  Widget _buildSelectionScreen(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? [Colors.grey[900]!, Colors.black]
              : [Colors.blue[900]!, Colors.blue[400]!],
        ),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.grid_view_rounded,
              size: 80,
              color: isDark ? theme.colorScheme.primary : Colors.white,
            ),
            const SizedBox(height: 24),
            const Text(
              'Ludo Offline',
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Select Number of Players',
              style: TextStyle(fontSize: 18, color: Colors.white70),
            ),
            const SizedBox(height: 48),
            _buildPlayerOption(context, 2, '2 Players (Opposite)'),
            const SizedBox(height: 16),
            _buildPlayerOption(context, 3, '3 Players'),
            const SizedBox(height: 16),
            _buildPlayerOption(context, 4, '4 Players'),
          ],
        ),
      ),
    );
  }

  Widget _buildPlayerOption(BuildContext context, int count, String label) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return GestureDetector(
      onTap: () => _startGame(count),
      child: Container(
        width: 250,
        padding: const EdgeInsets.symmetric(vertical: 20),
        decoration: BoxDecoration(
          color: isDark ? Colors.grey[850] : Colors.white,
          borderRadius: BorderRadius.circular(15),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(isDark ? 0.4 : 0.2),
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
          ],
          border: isDark ? Border.all(color: Colors.white12) : null,
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : Colors.black87,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Ludo Master',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: theme.textTheme.titleLarge?.color,
                ),
              ),
              Text(
                'Goal: 4 tokens home',
                style: TextStyle(
                  color: theme.textTheme.bodyMedium?.color?.withOpacity(0.6),
                ),
              ),
            ],
          ),
          _buildTurnIndicator(),
        ],
      ),
    );
  }

  Widget _buildTurnIndicator() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: playerColors[currentPlayerIndex],
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 4)],
      ),
      child: Text(
        '${_getPlayerName(currentPlayerIndex).toUpperCase()}\'S TURN',
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildBoard(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final boardColor = isDark ? Colors.grey[900] : Colors.white;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? Colors.black : Colors.grey[400], // Outer frame
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.4),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 1,
            offset: const Offset(0, -2),
          ),
        ],
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? [Colors.grey[850]!, Colors.black]
              : [Colors.grey[200]!, Colors.grey[400]!],
        ),
      ),
      padding: const EdgeInsets.all(12.0), // The wood/plastic frame thickness
      child: Container(
        decoration: BoxDecoration(
          color: boardColor,
          borderRadius: BorderRadius.circular(4),
          border: Border.all(
            color: isDark ? Colors.white12 : Colors.black87,
            width: 2.0,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 4,
              offset: const Offset(1, 1),
            ),
          ],
        ),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final boardWidth = constraints.maxWidth;
            return Stack(
              children: [
                _buildGrid(context),
                ...pieces.map((p) => _buildPieceWidget(p, boardWidth)),
              ],
            );
          },
        ),
      ),
    );
  }

  int _getFlex(int index) => 1;

  Widget _buildGrid(BuildContext context) {
    return Column(
      children: List.generate(
        15,
        (r) => Expanded(
          flex: _getFlex(r),
          child: Row(
            children: List.generate(
              15,
              (c) =>
                  Expanded(flex: _getFlex(c), child: _getCell(context, r, c)),
            ),
          ),
        ),
      ),
    );
  }

  double _getPixelPos(double index, double totalSize) {
    const int totalFlex = 15;
    double unit = totalSize / totalFlex;
    int full = index.floor();
    double frac = index - full;
    double offset = 0;
    for (int i = 0; i < full && i < 15; i++) {
      offset += _getFlex(i) * unit;
    }
    if (full < 15) {
      offset += _getFlex(full) * unit * frac;
    }
    return offset;
  }

  double _getPixelSize(int index, double totalSize) {
    const int totalFlex = 15;
    return (_getFlex(index) / totalFlex) * totalSize;
  }

  Widget _getCell(BuildContext context, int r, int c) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final gridColor = isDark
        ? Colors.white.withOpacity(0.05)
        : Colors.grey[200]!;

    // Bases (Houses) - Remove internal grid look
    if (r < 6 && c < 6) return _buildHouseArea(Colors.red, r, c, 0, 0, isDark);
    if (r < 6 && c > 8)
      return _buildHouseArea(Colors.green, r, c, 0, 9, isDark);
    if (r > 8 && c < 6) return _buildHouseArea(Colors.blue, r, c, 9, 0, isDark);
    if (r > 8 && c > 8)
      return _buildHouseArea(Colors.yellow, r, c, 9, 9, isDark);

    // Center
    if (r >= 6 && r <= 8 && c >= 6 && c <= 8) {
      // Only draw the painter once for the whole 3x3 or handle borders carefully
      bool isTop = r == 6;
      bool isLeft = c == 6;
      bool isBottom = r == 8;
      bool isRight = c == 8;
      BorderSide centerSide = BorderSide(color: gridColor, width: 0.5);

      return Container(
        decoration: BoxDecoration(
          color: isDark ? Colors.grey[850] : Colors.white,
          border: Border(
            top: isTop ? centerSide : BorderSide.none,
            left: isLeft ? centerSide : BorderSide.none,
            bottom: isBottom ? centerSide : BorderSide.none,
            right: isRight ? centerSide : BorderSide.none,
          ),
        ),
        child: CustomPaint(
          painter: TrianglePainter(isDark: isDark, r: r - 6, c: c - 6),
        ),
      );
    }

    // Paths & Cells
    Color? cellColor;
    IconData? icon;

    // Home paths
    if (r == 7 && c > 0 && c < 6) cellColor = Colors.red;
    if (r == 7 && c > 8 && c < 14) cellColor = Colors.yellow;
    if (c == 7 && r > 0 && r < 6) cellColor = Colors.green;
    if (c == 7 && r > 8 && r < 14) cellColor = Colors.blue;

    // Start squares
    if (r == 6 && c == 1) {
      cellColor = Colors.red;
      icon = Icons.play_arrow_rounded;
    }
    if (r == 1 && c == 8) {
      cellColor = Colors.green;
      icon = Icons.play_arrow_rounded;
    }
    if (r == 8 && c == 13) {
      cellColor = Colors.yellow;
      icon = Icons.play_arrow_rounded;
    }
    if (r == 13 && c == 6) {
      cellColor = Colors.blue;
      icon = Icons.play_arrow_rounded;
    }

    // Safe Squares (Star markers)
    if ((r == 6 && c == 1) ||
        (r == 8 && c == 13) ||
        (r == 1 && c == 8) ||
        (r == 13 && c == 6) ||
        (r == 6 && c == 12) ||
        (r == 8 && c == 2) ||
        (r == 2 && c == 6) ||
        (r == 12 && c == 8)) {
      if (icon == null) icon = Icons.auto_awesome;
    }

    return Container(
      decoration: BoxDecoration(
        color:
            cellColor?.withOpacity(isDark ? 0.7 : 0.8) ??
            (isDark ? Colors.grey[850] : Colors.white),
        border: Border.all(color: gridColor, width: 0.5),
        gradient: cellColor == null
            ? LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: isDark
                    ? [Colors.white.withOpacity(0.05), Colors.transparent]
                    : [Colors.black.withOpacity(0.03), Colors.transparent],
              )
            : LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  cellColor.withOpacity(isDark ? 0.9 : 0.8),
                  cellColor.withOpacity(isDark ? 0.6 : 0.5),
                ],
              ),
      ),
      child: icon != null
          ? Center(
              child: Icon(
                icon,
                size: 10,
                color: (cellColor != null)
                    ? Colors.white.withOpacity(0.9)
                    : (isDark ? Colors.white24 : Colors.black12),
              ),
            )
          : null,
    );
  }

  Widget _buildHouseArea(
    Color color,
    int r,
    int c,
    int startR,
    int startC,
    bool isDark,
  ) {
    // Border logic to make 6x6 look like one unit
    BorderSide outerSide = BorderSide(
      color: isDark ? Colors.white24 : Colors.black45,
      width: 2.0,
    );

    return Container(
      decoration: BoxDecoration(
        color: color.withOpacity(isDark ? 0.2 : 0.15),
        border: Border(
          top: r == startR ? outerSide : BorderSide.none,
          left: c == startC ? outerSide : BorderSide.none,
          bottom: r == startR + 5 ? outerSide : BorderSide.none,
          right: c == startC + 5 ? outerSide : BorderSide.none,
        ),
      ),
    );
  }

  Widget _buildBaseCell(Color color, List<Color> gradient) {
    return Container(
      margin: const EdgeInsets.all(0.5),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: gradient,
        ),
      ),
    );
  }

  Widget _buildPieceWidget(LudoPiece p, double boardWidth) {
    final rc = _getRC(p);
    final pos = _getCoordinate(p, boardWidth);
    final isMovable = movablePieceIndices.contains(pieces.indexOf(p));
    final isCurrentPlayerPiece = p.playerIndex == currentPlayerIndex;

    final cellW = _getPixelSize(rc.dy.toInt(), boardWidth);
    final cellH = _getPixelSize(rc.dx.toInt(), boardWidth);
    final cellSize = min(cellW, cellH);

    final color = playerColors[p.playerIndex];

    // Create a darker version of the color for the gradient
    final hsl = HSLColor.fromColor(color);
    final darkerColor = hsl
        .withLightness((hsl.lightness - 0.2).clamp(0.0, 1.0))
        .toColor();

    // Elevation offset for current player's pieces
    final elevationOffset = isCurrentPlayerPiece ? 4.0 : 0.0;

    return AnimatedPositioned(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOutBack,
      left: pos.dx,
      top: pos.dy - elevationOffset,
      child: GestureDetector(
        onTap: () => _movePiece(pieces.indexOf(p)),
        child: SizedBox(
          width: cellSize,
          height: cellSize * 1.5, // Taller for side profile
          child: Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.bottomCenter,
            children: [
              // 3D Cylinder Base
              Positioned(
                bottom: 2 + elevationOffset,
                child: Container(
                  width: cellSize * 0.75,
                  height: cellSize * 0.5,
                  decoration: BoxDecoration(
                    color: darkerColor,
                    borderRadius: BorderRadius.circular(cellSize),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(isCurrentPlayerPiece ? 0.5 : 0.4),
                        blurRadius: isCurrentPlayerPiece ? 10 : 6,
                        offset: Offset(0, isCurrentPlayerPiece ? 6 : 4),
                      ),
                    ],
                  ),
                ),
              ),
              // Piece Top
              Positioned(
                bottom: cellSize * 0.2 + elevationOffset,
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
                  child: Stack(
                    children: [
                      // Rim depth
                      Center(
                        child: Container(
                          width: cellSize * 0.45,
                          height: cellSize * 0.45,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: Colors.black.withOpacity(0.15),
                              width: 1,
                            ),
                          ),
                        ),
                      ),
                      // Specular highlight
                      Positioned(
                        top: cellSize * 0.1,
                        left: cellSize * 0.1,
                        child: Container(
                          width: cellSize * 0.25,
                          height: cellSize * 0.15,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.all(
                              Radius.elliptical(cellSize * 1.5, cellSize),
                            ),
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Colors.white.withOpacity(0.6),
                                Colors.white.withOpacity(0.0),
                              ],
                            ),
                          ),
                        ),
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
    final rc = _getRC(p);
    final cellW = _getPixelSize(rc.dy.toInt(), boardWidth);
    final cellH = _getPixelSize(rc.dx.toInt(), boardWidth);

    // Filter pieces that share the exact same grid coordinates
    int indexAtSpot = 0;
    int totalAtSpot = 0;

    for (var other in pieces) {
      if (_getRC(other) == rc) {
        if (pieces.indexOf(other) < pieces.indexOf(p)) {
          indexAtSpot++;
        }
        totalAtSpot++;
      }
    }

    double dx = 0;
    double dy = 0;

    // Apply a small circular offset if multiple pieces are on the same cell
    if (totalAtSpot > 1) {
      double offsetRadius = min(cellW, cellH) * 0.18;
      double angle = (2 * pi / totalAtSpot) * indexAtSpot;
      dx = cos(angle) * offsetRadius;
      dy = sin(angle) * offsetRadius;
    }

    // Manual center adjustment within variable-sized cells
    double xPos =
        _getPixelPos(rc.dy, boardWidth) + (cellW / 2) - (min(cellW, cellH) / 2);
    double yPos =
        _getPixelPos(rc.dx, boardWidth) + (cellH / 2) - (min(cellW, cellH) / 2);

    return Offset(xPos + dx, yPos - (min(cellW, cellH) * 0.3) + dy);
  }

  Offset _getRC(LudoPiece p) {
    if (p.status == PieceStatus.locked) {
      // Inside base boxes
      int idx = p.id % 4;
      // Centered positions in 6x6 area (3x3 grid for slots usually 2,4 etc)
      // To center 4 pieces in 6x6, we use rows 2 & 4 and columns 2 & 4
      double rOff = (idx ~/ 2 == 0) ? 1.5 : 3.5;
      double cOff = (idx % 2 == 0) ? 1.5 : 3.5;
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

    if (p.status == PieceStatus.finished) {
      return const Offset(7, 7);
    }

    // Home paths
    if (p.position >= 52) {
      double step = (p.position - 51).toDouble();
      switch (p.playerIndex) {
        case 0:
          return Offset(7.0, step);
        case 1:
          return Offset(step, 7.0);
        case 2:
          return Offset(7.0, 14.0 - step);
        case 3:
          return Offset(14.0 - step, 7.0);
      }
    }

    // Global path mapping
    int globalIdx = _getGlobalIndex(p.playerIndex, p.position);
    return _globalToRC(globalIdx);
  }

  Offset _globalToRC(int idx) {
    // Map 0-51 to (r, c)
    // This is a manual mapping of the Ludo path
    const List<Offset> path = [
      Offset(6, 1),
      Offset(6, 2),
      Offset(6, 3),
      Offset(6, 4),
      Offset(6, 5),
      Offset(5, 6),
      Offset(4, 6),
      Offset(3, 6),
      Offset(2, 6),
      Offset(1, 6),
      Offset(0, 6),
      Offset(0, 7),
      Offset(0, 8),
      Offset(1, 8),
      Offset(2, 8),
      Offset(3, 8),
      Offset(4, 8),
      Offset(5, 8),
      Offset(6, 9),
      Offset(6, 10),
      Offset(6, 11),
      Offset(6, 12),
      Offset(6, 13),
      Offset(6, 14),
      Offset(7, 14),
      Offset(8, 14),
      Offset(8, 13),
      Offset(8, 12),
      Offset(8, 11),
      Offset(8, 10),
      Offset(8, 9),
      Offset(9, 8),
      Offset(10, 8),
      Offset(11, 8),
      Offset(12, 8),
      Offset(13, 8),
      Offset(14, 8),
      Offset(14, 7),
      Offset(14, 6),
      Offset(13, 6),
      Offset(12, 6),
      Offset(11, 6),
      Offset(10, 6),
      Offset(9, 6),
      Offset(8, 5),
      Offset(8, 4),
      Offset(8, 3),
      Offset(8, 2),
      Offset(8, 1),
      Offset(8, 0),
      Offset(7, 0),
      Offset(6, 0),
    ];
    return path[idx % 52];
  }

  Widget _buildDiceArea(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 24),
      child: Column(
        children: [
          // Professional dice container
          GestureDetector(
            onTap: canRoll && !isRolling ? rollDice : null,
            child: Container(
              width: 90,
              height: 90,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isDark ? Colors.grey[800]! : Colors.grey[300]!,
                  width: 2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 8,
                    spreadRadius: 1,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: isRolling
                  ? _buildRollingDice()
                  : _buildProfessionalDiceFace(diceValue),
            ),
          ),
          const SizedBox(height: 16),
          // Status text
          Text(
            canRoll
                ? 'Tap to Roll'
                : (movablePieceIndices.isNotEmpty
                      ? 'Select a piece'
                      : 'No moves available'),
            style: TextStyle(
              color: isDark ? Colors.white70 : Colors.grey[700],
              fontWeight: FontWeight.w600,
              fontSize: 14,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRollingDice() {
    // Simple rolling indicator - just show changing dice values
    return _buildProfessionalDiceFace(diceValue);
  }

  Widget _buildProfessionalDiceFace(int value) {
    // Professional dice face with proper dots arrangement
    return Container(
      padding: const EdgeInsets.all(12),
      child: CustomPaint(
        painter: DiceDotsPainter(value: value),
        size: const Size(66, 66),
      ),
    );
  }
}

// Professional dice dots painter
class DiceDotsPainter extends CustomPainter {
  final int value;

  DiceDotsPainter({required this.value});

  @override
  void paint(Canvas canvas, Size size) {
    final dotPaint = Paint()
      ..color = Colors.black
      ..style = PaintingStyle.fill;

    final double dotRadius = size.width * 0.08;
    final double quarterW = size.width * 0.25;
    final double halfW = size.width * 0.5;
    final double threeQuarterW = size.width * 0.75;
    final double quarterH = size.height * 0.25;
    final double halfH = size.height * 0.5;
    final double threeQuarterH = size.height * 0.75;

    // Draw dots based on dice value
    switch (value) {
      case 1:
        // Center dot
        canvas.drawCircle(Offset(halfW, halfH), dotRadius, dotPaint);
        break;
      case 2:
        // Top-right and bottom-left
        canvas.drawCircle(Offset(threeQuarterW, quarterH), dotRadius, dotPaint);
        canvas.drawCircle(Offset(quarterW, threeQuarterH), dotRadius, dotPaint);
        break;
      case 3:
        // Top-right, center, bottom-left
        canvas.drawCircle(Offset(threeQuarterW, quarterH), dotRadius, dotPaint);
        canvas.drawCircle(Offset(halfW, halfH), dotRadius, dotPaint);
        canvas.drawCircle(Offset(quarterW, threeQuarterH), dotRadius, dotPaint);
        break;
      case 4:
        // Four corners
        canvas.drawCircle(Offset(quarterW, quarterH), dotRadius, dotPaint);
        canvas.drawCircle(Offset(threeQuarterW, quarterH), dotRadius, dotPaint);
        canvas.drawCircle(Offset(quarterW, threeQuarterH), dotRadius, dotPaint);
        canvas.drawCircle(Offset(threeQuarterW, threeQuarterH), dotRadius, dotPaint);
        break;
      case 5:
        // Four corners + center
        canvas.drawCircle(Offset(quarterW, quarterH), dotRadius, dotPaint);
        canvas.drawCircle(Offset(threeQuarterW, quarterH), dotRadius, dotPaint);
        canvas.drawCircle(Offset(halfW, halfH), dotRadius, dotPaint);
        canvas.drawCircle(Offset(quarterW, threeQuarterH), dotRadius, dotPaint);
        canvas.drawCircle(Offset(threeQuarterW, threeQuarterH), dotRadius, dotPaint);
        break;
      case 6:
        // Two columns of three
        canvas.drawCircle(Offset(quarterW, quarterH), dotRadius, dotPaint);
        canvas.drawCircle(Offset(quarterW, halfH), dotRadius, dotPaint);
        canvas.drawCircle(Offset(quarterW, threeQuarterH), dotRadius, dotPaint);
        canvas.drawCircle(Offset(threeQuarterW, quarterH), dotRadius, dotPaint);
        canvas.drawCircle(Offset(threeQuarterW, halfH), dotRadius, dotPaint);
        canvas.drawCircle(Offset(threeQuarterW, threeQuarterH), dotRadius, dotPaint);
        break;
    }
  }

  @override
  bool shouldRepaint(DiceDotsPainter oldDelegate) => oldDelegate.value != value;
}

class TrianglePainter extends CustomPainter {
  final bool isDark;
  final int r;
  final int c;
  TrianglePainter({required this.isDark, required this.r, required this.c});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;

    // We are painting a 1/9th portion of the center
    // The center is 3x3. We need to know which cell we are.
    // However, it's easier to just draw the corresponding triangle for each cell.

    // r, c are 0,1,2
    // Red: Left (r=1, c=0 and nearby)
    // Green: Top (r=0, c=1 and nearby)
    // Yellow: Right (r=1, c=2 and nearby)
    // Blue: Bottom (r=2, c=1 and nearby)

    if (r == 1 && c == 0)
      paint.color = isDark ? Colors.red.withOpacity(0.8) : Colors.red;
    else if (r == 0 && c == 1)
      paint.color = isDark ? Colors.green.withOpacity(0.8) : Colors.green;
    else if (r == 1 && c == 2)
      paint.color = isDark ? Colors.yellow.withOpacity(0.8) : Colors.yellow;
    else if (r == 2 && c == 1)
      paint.color = isDark ? Colors.blue.withOpacity(0.8) : Colors.blue;
    else if (r == 1 && c == 1)
      paint.color = isDark ? Colors.grey[800]! : Colors.grey[200]!;
    else {
      // Corners
      if (r == 0 && c == 0) {
        // Top-left: half red, half green split diagonally
        _drawSplit(
          canvas,
          size,
          isDark ? Colors.green.withOpacity(0.8) : Colors.green,
          isDark ? Colors.red.withOpacity(0.8) : Colors.red,
          true,
        );
        return;
      }
      if (r == 0 && c == 2) {
        // Top-right: half green, half yellow
        _drawSplit(
          canvas,
          size,
          isDark ? Colors.green.withOpacity(0.8) : Colors.green,
          isDark ? Colors.yellow.withOpacity(0.8) : Colors.yellow,
          false,
        );
        return;
      }
      if (r == 2 && c == 0) {
        // Bottom-left: blue/red
        _drawSplit(
          canvas,
          size,
          isDark ? Colors.blue.withOpacity(0.8) : Colors.blue,
          isDark ? Colors.red.withOpacity(0.8) : Colors.red,
          false,
        );
        return;
      }
      if (r == 2 && c == 2) {
        // Bottom-right: blue/yellow
        _drawSplit(
          canvas,
          size,
          isDark ? Colors.blue.withOpacity(0.8) : Colors.blue,
          isDark ? Colors.yellow.withOpacity(0.8) : Colors.yellow,
          true,
        );
        return;
      }
      return;
    }

    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), paint);
  }

  void _drawSplit(
    Canvas canvas,
    Size size,
    Color c1,
    Color c2,
    bool mainDiagonal,
  ) {
    final paint = Paint()..style = PaintingStyle.fill;
    var path = Path();
    if (mainDiagonal) {
      paint.color = c1;
      path.moveTo(0, 0);
      path.lineTo(size.width, 0);
      path.lineTo(size.width, size.height);
      path.close();
      canvas.drawPath(path, paint);

      paint.color = c2;
      path = Path();
      path.moveTo(0, 0);
      path.lineTo(0, size.height);
      path.lineTo(size.width, size.height);
      path.close();
      canvas.drawPath(path, paint);
    } else {
      paint.color = c1;
      path.moveTo(0, 0);
      path.lineTo(size.width, 0);
      path.lineTo(0, size.height);
      path.close();
      canvas.drawPath(path, paint);

      paint.color = c2;
      path = Path();
      path.moveTo(size.width, 0);
      path.lineTo(size.width, size.height);
      path.lineTo(0, size.height);
      path.close();
      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(CustomPainter old) => false;
}
