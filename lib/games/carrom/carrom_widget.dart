import 'dart:math';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../core/models/game_model.dart';
import '../../core/providers/score_provider.dart';
import '../../core/services/haptic_service.dart';

enum CarromPieceType { black, white, queen, striker }

enum GameState { setup, playing, gameOver }

class CarromPiece {
  Offset position;
  Offset velocity;
  final CarromPieceType type;
  bool isPotted;
  final double radius;
  final double mass;

  CarromPiece({
    required this.position,
    this.velocity = Offset.zero,
    required this.type,
    this.isPotted = false,
    required this.radius,
    required this.mass,
  });
}

class Player {
  final int id;
  int score;
  final String name;
  final Color color;

  Player({
    required this.id,
    this.score = 0,
    required this.name,
    required this.color,
  });
}

class CarromWidget extends StatefulWidget {
  final GameModel game;
  const CarromWidget({super.key, required this.game});

  @override
  State<CarromWidget> createState() => _CarromWidgetState();
}

class _CarromWidgetState extends State<CarromWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  GameState _gameState = GameState.setup;
  int _playerCount = 2;
  List<Player> _players = [];
  int _currentPlayerIndex = 0;
  List<CarromPiece> _pieces = [];
  late CarromPiece _striker;

  bool _isAiming = false;
  Offset? _dragStart;
  Offset? _dragCurrent;

  HapticService? _hapticService;

  // Game constants
  final double _boardSize = 800.0;
  final double _pocketRadius = 60.0; // Significant increase for easier fouls
  final double _pieceRadius = 18.0;
  final double _queenRadius = 18.0;
  final double _strikerRadius = 25.0;
  final double _friction = 0.985;
  final double _wallBounciness = 0.7;

  bool _pottedInThisTurn = false;
  bool _strikerFoul = false;
  bool _hasShotTaken = false;

  ui.Image? _blackPieceImg;
  ui.Image? _whitePieceImg;
  ui.Image? _queenPieceImg;
  ui.Image? _strikerImg;

  @override
  void initState() {
    super.initState();
    _initHaptic();
    _loadGameAssets();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 16),
    )..addListener(_updatePhysics);
  }

  Future<void> _loadGameAssets() async {
    _blackPieceImg = await _loadUiImage('assets/images/carrom/black.png');
    _whitePieceImg = await _loadUiImage('assets/images/carrom/white.png');
    _queenPieceImg = await _loadUiImage('assets/images/carrom/queen.png');
    _strikerImg = await _loadUiImage('assets/images/carrom/striker.png');
    if (mounted) setState(() {});
  }

  Future<ui.Image> _loadUiImage(String path) async {
    final data = await rootBundle.load(path);
    final bytes = data.buffer.asUint8List();
    final codec = await ui.instantiateImageCodec(bytes);
    final frameInfo = await codec.getNextFrame();
    return frameInfo.image;
  }

  Future<void> _initHaptic() async {
    _hapticService = await HapticService.getInstance();
  }

  void _startGame(int players) {
    setState(() {
      _playerCount = players;
      _players = List.generate(
        players,
        (i) =>
            Player(id: i, name: 'Player ${i + 1}', color: _getPlayerColor(i)),
      );
      _currentPlayerIndex = 0;
      _gameState = GameState.playing;
      _initBoard();
    });
    _controller.repeat();
  }

  Color _getPlayerColor(int index) {
    switch (index) {
      case 0:
        return Colors.blue;
      case 1:
        return Colors.green;
      case 2:
        return Colors.orange;
      case 3:
        return Colors.purple;
      default:
        return Colors.blue;
    }
  }

  void _initBoard() {
    _pieces = [];
    double centerX = _boardSize / 2;
    double centerY = _boardSize / 2;

    // Add Queen
    _pieces.add(
      CarromPiece(
        position: Offset(centerX, centerY),
        type: CarromPieceType.queen,
        radius: _queenRadius,
        mass: 1.0,
      ),
    );

    // Inner Circle: 3 White, 3 Black (tight alignment)
    double r1 = _pieceRadius * 2 + 0.2; // 2r distance for tight pack
    for (int i = 0; i < 6; i++) {
      double angle = i * pi / 3;
      _pieces.add(
        CarromPiece(
          position: Offset(
            centerX + r1 * cos(angle),
            centerY + r1 * sin(angle),
          ),
          type: i % 2 == 0 ? CarromPieceType.white : CarromPieceType.black,
          radius: _pieceRadius,
          mass: 1.0,
        ),
      );
    }

    // Outer Circle: 6 White, 6 Black (tight alignment)
    // Radius calculated so 12 pieces touch each other on a circle
    double r2 = _pieceRadius * 3.864 + 0.4;
    for (int i = 0; i < 12; i++) {
      double angle = i * pi / 6 + (pi / 12);
      _pieces.add(
        CarromPiece(
          position: Offset(
            centerX + r2 * cos(angle),
            centerY + r2 * sin(angle),
          ),
          type: i % 2 == 0 ? CarromPieceType.black : CarromPieceType.white,
          radius: _pieceRadius,
          mass: 1.0,
        ),
      );
    }

    _resetStriker();
    _waitingForCover = false;
  }

  void _resetStriker() {
    double baselineOffset = 130.0;
    Offset pos;
    switch (_currentPlayerIndex) {
      case 0: // Bottom
        pos = Offset(_boardSize / 2, _boardSize - baselineOffset);
        break;
      case 1: // Top
        pos = Offset(_boardSize / 2, baselineOffset);
        break;
      case 2: // Left
        pos = Offset(baselineOffset, _boardSize / 2);
        break;
      case 3: // Right
        pos = Offset(_boardSize - baselineOffset, _boardSize / 2);
        break;
      default:
        pos = Offset(_boardSize / 2, _boardSize - baselineOffset);
    }
    _striker = CarromPiece(
      position: pos,
      type: CarromPieceType.striker,
      radius: _strikerRadius,
      mass: 2.0,
    );
    _isAiming = false;
    _pottedInThisTurn = false;
    _strikerFoul = false;
  }

  void _updatePhysics() {
    if (_isAiming || _gameState != GameState.playing) return;

    bool moving = false;
    List<CarromPiece> allPieces = [..._pieces];
    if (!_striker.isPotted) allPieces.add(_striker);

    for (var piece in allPieces) {
      if (piece.velocity.distance > 0.1) {
        moving = true;
        piece.position += piece.velocity;
        piece.velocity *= _friction;

        // Wall collisions
        double r = piece.radius;
        if (piece.position.dx < r) {
          piece.position = Offset(r, piece.position.dy);
          piece.velocity = Offset(
            -piece.velocity.dx * _wallBounciness,
            piece.velocity.dy,
          );
          _hapticService?.light();
        } else if (piece.position.dx > _boardSize - r) {
          piece.position = Offset(_boardSize - r, piece.position.dy);
          piece.velocity = Offset(
            -piece.velocity.dx * _wallBounciness,
            piece.velocity.dy,
          );
          _hapticService?.light();
        }

        if (piece.position.dy < r) {
          piece.position = Offset(piece.position.dx, r);
          piece.velocity = Offset(
            piece.velocity.dx,
            -piece.velocity.dy * _wallBounciness,
          );
          _hapticService?.light();
        } else if (piece.position.dy > _boardSize - r) {
          piece.position = Offset(piece.position.dx, _boardSize - r);
          piece.velocity = Offset(
            piece.velocity.dx,
            -piece.velocity.dy * _wallBounciness,
          );
          _hapticService?.light();
        }

        // Pocket Check
        if (_checkPocket(piece)) {
          // Handled in _checkPocket
        }
      } else {
        piece.velocity = Offset.zero;
      }
    }

    // Resolve Collisions
    for (int i = 0; i < allPieces.length; i++) {
      for (int j = i + 1; j < allPieces.length; j++) {
        _handleCollision(allPieces[i], allPieces[j]);
      }
    }

    // Check if movement stopped
    if (_hasShotTaken && !moving && _striker.velocity.distance < 0.1) {
      _onTurnEnd();
    }

    setState(() {});
  }

  bool _checkPocket(CarromPiece piece) {
    List<Offset> pockets = [
      const Offset(0, 0),
      Offset(_boardSize, 0),
      Offset(0, _boardSize),
      Offset(_boardSize, _boardSize),
    ];

    for (var pocket in pockets) {
      if ((piece.position - pocket).distance < _pocketRadius) {
        piece.isPotted = true;
        piece.velocity = Offset.zero;
        if (piece.type == CarromPieceType.striker) {
          _strikerFoul = true;
          _hapticService?.heavy();
        } else {
          _pieces.remove(piece);
          _onPiecePotted(piece);
          _pottedInThisTurn = true;
          _hapticService?.medium();
        }
        return true;
      }
    }
    return false;
  }

  bool _waitingForCover = false;

  void _onPiecePotted(CarromPiece piece) {
    int points = 0;
    switch (piece.type) {
      case CarromPieceType.black:
        points = 10;
        break;
      case CarromPieceType.white:
        points = 20;
        break;
      case CarromPieceType.queen:
        points = 50;
        _waitingForCover = true;
        break;
      default:
        break;
    }
    _players[_currentPlayerIndex].score += points;
  }

  void _handleCollision(CarromPiece p1, CarromPiece p2) {
    double distance = (p1.position - p2.position).distance;
    double minDistance = p1.radius + p2.radius;

    if (distance < minDistance) {
      // Resolve overlap
      Offset normal = (p1.position - p2.position) / distance;
      double overlap = minDistance - distance;
      p1.position += normal * (overlap * (p2.mass / (p1.mass + p2.mass)));
      p2.position -= normal * (overlap * (p1.mass / (p1.mass + p2.mass)));

      // Elastic Collision
      Offset relativeVelocity = p1.velocity - p2.velocity;
      double velocityAlongNormal =
          relativeVelocity.dx * normal.dx + relativeVelocity.dy * normal.dy;

      if (velocityAlongNormal > 0) return;

      double restitution = 0.8;
      double j = -(1 + restitution) * velocityAlongNormal;
      j /= (1 / p1.mass + 1 / p2.mass);

      Offset impulse = normal * j;
      p1.velocity += impulse / p1.mass;
      p2.velocity -= impulse / p2.mass;

      _hapticService?.light();
    }
  }

  void _onTurnEnd() {
    bool changeTurn = true;
    bool returnQueen = false;

    if (_strikerFoul) {
      _players[_currentPlayerIndex].score = max(
        0,
        _players[_currentPlayerIndex].score - 10,
      );
      if (_waitingForCover) {
        returnQueen = true;
      }
      changeTurn = true;
    } else {
      if (_pottedInThisTurn) {
        if (_waitingForCover) {
          // If Queen was potted and we now have a cover piece
          // Check if the coin potted THIS shot was the queen itself
          // (Already handled by setting _waitingForCover = true in _onPiecePotted)
          // If they potted BOTH queen and another piece in the SAME shot, cover is done.
          // We need to know if something ELSE was potted besides the queen.
          // For simplicity: if ANY piece is potted while waiting for cover, cover is successful.
          _waitingForCover = false;
        }
        changeTurn = false;
      } else {
        if (_waitingForCover) {
          returnQueen = true;
        }
        changeTurn = true;
      }
    }

    if (returnQueen) {
      _players[_currentPlayerIndex].score = max(
        0,
        _players[_currentPlayerIndex].score - 50,
      );
      _pieces.add(
        CarromPiece(
          position: Offset(_boardSize / 2, _boardSize / 2),
          type: CarromPieceType.queen,
          radius: _queenRadius,
          mass: 1.0,
        ),
      );
      _waitingForCover = false;
    }

    if (_pieces.isEmpty && !_waitingForCover) {
      _gameState = GameState.gameOver;
      _controller.stop();
      _saveFinalScore();
    } else {
      _hasShotTaken = false;
      if (changeTurn) {
        _currentPlayerIndex = (_currentPlayerIndex + 1) % _playerCount;
      }
      _resetStriker();
    }
    setState(() {});
  }

  void _saveFinalScore() {
    int maxScore = 0;
    for (var p in _players) {
      if (p.score > maxScore) maxScore = p.score;
    }
    context.read<ScoreProvider>().saveScore(widget.game.id, maxScore);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            widget.game.primaryColor.withOpacity(0.05),
            widget.game.primaryColor.withOpacity(0.15),
          ],
        ),
      ),
      child: _gameState == GameState.setup
          ? _buildSetupScreen()
          : _buildGameScreen(),
    );
  }

  Widget _buildSetupScreen() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            widget.game.title,
            style: const TextStyle(
              fontSize: 48,
              fontWeight: FontWeight.bold,
              color: Colors.brown,
            ),
          ),
          const SizedBox(height: 40),
          const Text(
            "Select Number of Players",
            style: TextStyle(fontSize: 20, color: Colors.brown),
          ),
          const SizedBox(height: 20),
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 20,
            runSpacing: 20,
            children: [2, 3, 4]
                .map(
                  (n) => ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: widget.game.primaryColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 30,
                        vertical: 20,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                    ),
                    onPressed: () => _startGame(n),
                    child: Text(
                      "$n Players",
                      style: const TextStyle(fontSize: 18),
                    ),
                  ),
                )
                .toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildGameScreen() {
    return Column(
      children: [
        _buildHeader(),
        Expanded(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Center(
                child: AspectRatio(
                  aspectRatio: 1,
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFFE4C58F),
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.5),
                            blurRadius: 20,
                            offset: const Offset(5, 15),
                          ),
                          BoxShadow(
                            color: Colors.white.withOpacity(0.2),
                            blurRadius: 10,
                            offset: const Offset(-5, -5),
                          ),
                        ],
                        border: Border.all(
                          color: const Color(0xFF3D2B1F),
                          width: 15,
                        ),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(5),
                        child: Stack(
                          children: [
                            CustomPaint(
                              painter: BoardPainter(),
                              size: Size.infinite,
                            ),
                            LayoutBuilder(
                              builder: (context, constraints) {
                                double scale =
                                    constraints.maxWidth / _boardSize;
                                return GestureDetector(
                                  onPanStart: (details) {
                                    if (_gameState != GameState.playing) return;
                                    if (_striker.velocity.distance < 0.1) {
                                      Offset localPos =
                                          details.localPosition / scale;
                                      if ((localPos - _striker.position)
                                              .distance <
                                          100) {
                                        _dragStart = localPos;
                                        _dragCurrent = localPos;
                                        _isAiming = true;
                                      }
                                    }
                                  },
                                  onPanUpdate: (details) {
                                    if (_isAiming && _dragStart != null) {
                                      setState(() {
                                        _dragCurrent =
                                            details.localPosition / scale;
                                      });
                                    }
                                  },
                                  onPanEnd: (details) {
                                    if (_isAiming &&
                                        _dragStart != null &&
                                        _dragCurrent != null) {
                                      Offset diff = _dragStart! - _dragCurrent!;
                                      double power = diff.distance;
                                      if (power > 20) {
                                        Offset dir = diff / power;
                                        double maxPower = 40.0;
                                        double speed = min(
                                          power * 0.2,
                                          maxPower,
                                        );
                                        _striker.velocity = dir * speed;
                                        _hasShotTaken = true;
                                        _hapticService?.medium();
                                      }
                                      setState(() {
                                        _isAiming = false;
                                        _dragStart = null;
                                        _dragCurrent = null;
                                      });
                                    }
                                  },
                                  child: CustomPaint(
                                    painter: GamePainter(
                                      pieces: _pieces,
                                      striker: _striker,
                                      isAiming: _isAiming,
                                      dragStart: _dragStart,
                                      dragCurrent: _dragCurrent,
                                      boardSize: _boardSize,
                                      blackImg: _blackPieceImg,
                                      whiteImg: _whitePieceImg,
                                      queenImg: _queenPieceImg,
                                      strikerImg: _strikerImg,
                                    ),
                                    size: Size.infinite,
                                  ),
                                );
                              },
                            ),
                            if (_gameState == GameState.gameOver)
                              _buildGameOverOverlay(),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        if (_striker.velocity.distance < 0.1 && _gameState == GameState.playing)
          _buildStrikerSlider(),
        _buildTurnIndicator(),
      ],
    );
  }

  Widget _buildStrikerSlider() {
    double minB = 150.0;
    double maxB = _boardSize - 150.0;

    double currentValue;
    if (_currentPlayerIndex == 0 || _currentPlayerIndex == 1) {
      currentValue = _striker.position.dx;
    } else {
      currentValue = _striker.position.dy;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 10),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            "Position Striker",
            style: TextStyle(color: Colors.brown, fontWeight: FontWeight.bold),
          ),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: widget.game.primaryColor,
              inactiveTrackColor: Colors.brown.withOpacity(0.2),
              thumbColor: widget.game.primaryColor,
              overlayColor: widget.game.primaryColor.withOpacity(0.2),
              trackHeight: 8,
            ),
            child: Slider(
              value: currentValue.clamp(minB, maxB),
              min: minB,
              max: maxB,
              onChanged: (value) {
                setState(() {
                  _moveStrikerAlongBaseline(Offset(value, value));
                });
              },
            ),
          ),
        ],
      ),
    );
  }

  void _moveStrikerAlongBaseline(Offset pos) {
    double minB = 150.0;
    double maxB = _boardSize - 150.0;
    Offset oldPos = _striker.position;
    Offset newPos = oldPos;

    switch (_currentPlayerIndex) {
      case 0:
        newPos = Offset(pos.dx.clamp(minB, maxB), oldPos.dy);
        break;
      case 1:
        newPos = Offset(pos.dx.clamp(minB, maxB), oldPos.dy);
        break;
      case 2:
        newPos = Offset(oldPos.dx, pos.dy.clamp(minB, maxB));
        break;
      case 3:
        newPos = Offset(oldPos.dx, pos.dy.clamp(minB, maxB));
        break;
    }

    // Check for overlap with other pieces
    bool overlaps = false;
    for (var piece in _pieces) {
      double minSafeDist = _striker.radius + piece.radius + 1.0;
      if ((newPos - piece.position).distance < minSafeDist) {
        overlaps = true;
        break;
      }
    }

    // Only update position if no overlap exists
    if (!overlaps) {
      _striker.position = newPos;
    }
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              if (_gameState != GameState.playing)
                IconButton(
                  icon: const Icon(Icons.arrow_back_ios, color: Colors.brown),
                  onPressed: () => Navigator.of(context).pop(),
                )
              else
                const SizedBox(width: 48), // Spacer to maintain alignment
              Text(
                widget.game.title,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.brown,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.refresh, color: Colors.brown),
                onPressed: () => setState(() => _gameState = GameState.setup),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 10,
            runSpacing: 10,
            children: _players
                .map(
                  (p) => Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: _currentPlayerIndex == p.id
                          ? p.color
                          : Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(10),
                      boxShadow: _currentPlayerIndex == p.id
                          ? [
                              BoxShadow(
                                color: p.color.withOpacity(0.4),
                                blurRadius: 8,
                              ),
                            ]
                          : null,
                    ),
                    child: Column(
                      children: [
                        Text(
                          p.name,
                          style: TextStyle(
                            color: _currentPlayerIndex == p.id
                                ? Colors.white
                                : Colors.black54,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          "${p.score}",
                          style: TextStyle(
                            color: _currentPlayerIndex == p.id
                                ? Colors.white
                                : Colors.black54,
                            fontSize: 18,
                          ),
                        ),
                      ],
                    ),
                  ),
                )
                .toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildTurnIndicator() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Text(
        "${_players[_currentPlayerIndex].name}'s Turn",
        style: TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.bold,
          color: _players[_currentPlayerIndex].color,
        ),
      ),
    );
  }

  Widget _buildGameOverOverlay() {
    Player winner = _players.reduce((a, b) => a.score > b.score ? a : b);
    return Container(
      color: Colors.black54,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              "GAME OVER",
              style: TextStyle(
                color: Colors.white,
                fontSize: 40,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              "${winner.name} Wins!",
              style: TextStyle(
                color: winner.color,
                fontSize: 30,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 30),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: widget.game.primaryColor,
                padding: const EdgeInsets.symmetric(
                  horizontal: 40,
                  vertical: 15,
                ),
              ),
              onPressed: () => setState(() => _gameState = GameState.setup),
              child: const Text(
                "Play Again",
                style: TextStyle(fontSize: 20, color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class BoardPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    double s = size.width;
    Paint linePaint = Paint()
      ..color = Colors.brown.withOpacity(0.5)
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;
    Paint thickLinePaint = Paint()
      ..color = Colors.brown
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke;
    Paint fillPaint = Paint()
      ..color = Colors.black
      ..style = PaintingStyle.fill;

    // Pockets
    double pR = 60 * (s / 800);
    canvas.drawCircle(const Offset(0, 0), pR, fillPaint);
    canvas.drawCircle(Offset(s, 0), pR, fillPaint);
    canvas.drawCircle(Offset(0, s), pR, fillPaint);
    canvas.drawCircle(Offset(s, s), pR, fillPaint);

    // Center circles
    canvas.drawCircle(Offset(s / 2, s / 2), 20 * (s / 800), thickLinePaint);
    canvas.drawCircle(Offset(s / 2, s / 2), 80 * (s / 800), linePaint);

    // Diagonal lines from pockets
    double dOff = 50 * (s / 800);
    canvas.drawLine(
      Offset(dOff, dOff),
      Offset(s / 2 - 100 * (s / 800), s / 2 - 100 * (s / 800)),
      linePaint,
    );
    canvas.drawLine(
      Offset(s - dOff, dOff),
      Offset(s / 2 + 100 * (s / 800), s / 2 - 100 * (s / 800)),
      linePaint,
    );
    canvas.drawLine(
      Offset(dOff, s - dOff),
      Offset(s / 2 - 100 * (s / 800), s / 2 + 100 * (s / 800)),
      linePaint,
    );
    canvas.drawLine(
      Offset(s - dOff, s - dOff),
      Offset(s / 2 + 100 * (s / 800), s / 2 + 100 * (s / 800)),
      linePaint,
    );

    // rim shadow
    Paint rimShadowPaint = Paint()
      ..color = Colors.black.withOpacity(0.2)
      ..style = PaintingStyle.fill;
    canvas.drawRect(Rect.fromLTRB(0, 0, s, 20 * (s / 800)), rimShadowPaint);
    canvas.drawRect(Rect.fromLTRB(0, s - 20 * (s / 800), s, s), rimShadowPaint);
    canvas.drawRect(Rect.fromLTRB(0, 0, 20 * (s / 800), s), rimShadowPaint);
    canvas.drawRect(Rect.fromLTRB(s - 20 * (s / 800), 0, s, s), rimShadowPaint);

    // Baselines (Two parallel lines)
    double baselineOffset = 130 * (s / 800);
    double padding = 150 * (s / 800);
    double lineGap = 30 * (s / 800);

    // Bottom
    _drawBaseline(
      canvas,
      Offset(padding, s - baselineOffset),
      Offset(s - padding, s - baselineOffset),
      lineGap,
      thickLinePaint,
      s,
    );
    // Top
    _drawBaseline(
      canvas,
      Offset(padding, baselineOffset),
      Offset(s - padding, baselineOffset),
      -lineGap,
      thickLinePaint,
      s,
    );
    // Left
    _drawBaselineSide(
      canvas,
      Offset(baselineOffset, padding),
      Offset(baselineOffset, s - padding),
      -lineGap,
      thickLinePaint,
      s,
    );
    // Right
    _drawBaselineSide(
      canvas,
      Offset(s - baselineOffset, padding),
      Offset(s - baselineOffset, s - padding),
      lineGap,
      thickLinePaint,
      s,
    );
  }

  void _drawBaseline(
    Canvas canvas,
    Offset start,
    Offset end,
    double gap,
    Paint paint,
    double s,
  ) {
    canvas.drawLine(start, end, paint);
    canvas.drawLine(
      Offset(start.dx, start.dy + gap),
      Offset(end.dx, end.dy + gap),
      paint,
    );
    canvas.drawCircle(
      Offset(start.dx, start.dy + gap / 2),
      gap.abs() / 2,
      paint,
    );
    canvas.drawCircle(Offset(end.dx, end.dy + gap / 2), gap.abs() / 2, paint);
    // Outer circles decoration
    canvas.drawCircle(
      Offset(start.dx, start.dy + gap / 2),
      gap.abs() / 1.5,
      Paint()
        ..color = paint.color.withOpacity(0.2)
        ..style = PaintingStyle.stroke,
    );
    canvas.drawCircle(
      Offset(end.dx, end.dy + gap / 2),
      gap.abs() / 1.5,
      Paint()
        ..color = paint.color.withOpacity(0.2)
        ..style = PaintingStyle.stroke,
    );
  }

  void _drawBaselineSide(
    Canvas canvas,
    Offset start,
    Offset end,
    double gap,
    Paint paint,
    double s,
  ) {
    canvas.drawLine(start, end, paint);
    canvas.drawLine(
      Offset(start.dx + gap, start.dy),
      Offset(end.dx + gap, end.dy),
      paint,
    );
    canvas.drawCircle(
      Offset(start.dx + gap / 2, start.dy),
      gap.abs() / 2,
      paint,
    );
    canvas.drawCircle(Offset(end.dx + gap / 2, end.dy), gap.abs() / 2, paint);
    // Outer circles decoration
    canvas.drawCircle(
      Offset(start.dx + gap / 2, start.dy),
      gap.abs() / 1.5,
      Paint()
        ..color = paint.color.withOpacity(0.2)
        ..style = PaintingStyle.stroke,
    );
    canvas.drawCircle(
      Offset(end.dx + gap / 2, end.dy),
      gap.abs() / 1.5,
      Paint()
        ..color = paint.color.withOpacity(0.2)
        ..style = PaintingStyle.stroke,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class GamePainter extends CustomPainter {
  final List<CarromPiece> pieces;
  final CarromPiece striker;
  final bool isAiming;
  final Offset? dragStart;
  final Offset? dragCurrent;
  final double boardSize;
  final ui.Image? blackImg;
  final ui.Image? whiteImg;
  final ui.Image? queenImg;
  final ui.Image? strikerImg;

  GamePainter({
    required this.pieces,
    required this.striker,
    required this.isAiming,
    required this.dragStart,
    required this.dragCurrent,
    required this.boardSize,
    this.blackImg,
    this.whiteImg,
    this.queenImg,
    this.strikerImg,
  });

  @override
  void paint(Canvas canvas, Size size) {
    double scale = size.width / boardSize;

    // Draw Pieces
    for (var piece in pieces) {
      _drawPiece(canvas, piece, scale);
    }

    // Draw Striker
    _drawPiece(canvas, striker, scale);

    // Draw Aim Line & Arrow
    if (isAiming && dragStart != null && dragCurrent != null) {
      Offset diff = (dragStart! - dragCurrent!);
      if (diff.distance > 20) {
        double angle = atan2(diff.dy, diff.dx);

        // Power Radius (Visualizing speed around striker)
        Paint radiusPaint = Paint()
          ..color = Colors.red.withOpacity(0.15)
          ..style = PaintingStyle.fill;
        Paint radiusBorderPaint = Paint()
          ..color = Colors.red.withOpacity(0.3)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1 * scale;

        double indicatorRadius = min(diff.distance * 0.4, 90.0) * scale;
        canvas.drawCircle(
          striker.position * scale,
          indicatorRadius,
          radiusPaint,
        );
        canvas.drawCircle(
          striker.position * scale,
          indicatorRadius,
          radiusBorderPaint,
        );

        // Aim Arrow
        Paint aimPaint = Paint()
          ..color = Colors.red.withOpacity(0.7)
          ..strokeWidth = 3 * scale
          ..strokeCap = StrokeCap.round
          ..style = PaintingStyle.stroke;

        Offset start = striker.position * scale;
        Offset dir = diff / diff.distance;
        Offset end = start + dir * indicatorRadius;

        canvas.drawLine(start, end, aimPaint);

        // Arrow Head
        double headSize = 15 * scale;
        Path headPath = Path();
        headPath.moveTo(
          end.dx - headSize * cos(angle - pi / 6),
          end.dy - headSize * sin(angle - pi / 6),
        );
        headPath.lineTo(end.dx, end.dy);
        headPath.lineTo(
          end.dx - headSize * cos(angle + pi / 6),
          end.dy - headSize * sin(angle + pi / 6),
        );
        canvas.drawPath(headPath, aimPaint);
      }
    }
  }

  void _drawPiece(Canvas canvas, CarromPiece piece, double scale) {
    ui.Image? img;
    switch (piece.type) {
      case CarromPieceType.black:
        img = blackImg;
        break;
      case CarromPieceType.white:
        img = whiteImg;
        break;
      case CarromPieceType.queen:
        img = queenImg;
        break;
      case CarromPieceType.striker:
        img = strikerImg;
        break;
    }

    if (img != null) {
      // Draw Shadow
      canvas.drawCircle(
        piece.position * scale + Offset(3 * scale, 3 * scale),
        piece.radius * scale,
        Paint()
          ..color = Colors.black45
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4),
      );

      // Draw Image with circular mask to remove white background
      canvas.save();
      Path clipPath = Path()
        ..addOval(
          Rect.fromCircle(
            center: piece.position * scale,
            radius:
                (piece.radius - 1.5) *
                scale, // Increased inset for cleaner background removal
          ),
        );
      canvas.clipPath(clipPath);

      Rect dest = Rect.fromCircle(
        center: piece.position * scale,
        radius:
            piece.radius * 1.25 * scale, // Increased zoom to 25% to hide whites
      );
      paintImage(
        canvas: canvas,
        rect: dest,
        image: img,
        fit: BoxFit.cover,
        filterQuality: FilterQuality.high,
      );
      canvas.restore();
      return;
    }

    Paint piecePaint = Paint()..style = PaintingStyle.fill;
    Paint borderPaint = Paint()
      ..color = Colors.black45
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1 * scale;

    // 3D effect with radial gradient
    List<Color> colors;
    switch (piece.type) {
      case CarromPieceType.black:
        colors = [Colors.grey[800]!, Colors.black];
        break;
      case CarromPieceType.white:
        colors = [Colors.white, Colors.grey[300]!];
        break;
      case CarromPieceType.queen:
        colors = [Colors.pink[300]!, Colors.pink[800]!];
        break;
      case CarromPieceType.striker:
        colors = [Colors.red[300]!, Colors.red[900]!];
        break;
    }

    piecePaint.shader =
        RadialGradient(
          center: const Alignment(-0.3, -0.3),
          colors: colors,
        ).createShader(
          Rect.fromCircle(
            center: piece.position * scale,
            radius: piece.radius * scale,
          ),
        );

    // Shadow
    canvas.drawCircle(
      piece.position * scale + Offset(2 * scale, 2 * scale),
      piece.radius * scale,
      Paint()
        ..color = Colors.black26
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2),
    );

    canvas.drawCircle(piece.position * scale, piece.radius * scale, piecePaint);
    canvas.drawCircle(
      piece.position * scale,
      piece.radius * scale,
      borderPaint,
    );

    if (piece.type == CarromPieceType.striker) {
      canvas.drawCircle(
        piece.position * scale,
        (piece.radius - 4) * scale,
        Paint()
          ..color = Colors.white54
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2 * scale,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
