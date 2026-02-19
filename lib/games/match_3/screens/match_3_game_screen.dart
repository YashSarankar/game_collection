import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../logic/match_3_controller.dart';
import '../components/tile_widget.dart';
import '../components/particle_widget.dart';
import '../match_3_theme.dart';
import '../models/game_event.dart';
import '../models/tile_model.dart';

class Match3GameScreen extends StatefulWidget {
  const Match3GameScreen({super.key});

  @override
  State<Match3GameScreen> createState() => _Match3GameScreenState();
}

class _Match3GameScreenState extends State<Match3GameScreen>
    with TickerProviderStateMixin {
  late Match3Controller _controller;
  int? _selectedRow;
  int? _selectedCol;

  final List<Widget> _effects = [];
  double _shakeX = 0;
  double _shakeY = 0;

  StreamSubscription? _eventSub;

  @override
  void initState() {
    super.initState();
    _controller = Match3Controller();
    _eventSub = _controller.events.listen(_handleGameEvent);
  }

  @override
  void dispose() {
    _eventSub?.cancel();
    super.dispose();
  }

  void _handleGameEvent(GameEvent event) {
    switch (event.type) {
      case GameEventType.match:
        _addParticle(event.position!, event.data as TileType);
        break;
      case GameEventType.combo:
        _addComboText(event.message!);
        break;
      case GameEventType.shake:
        _triggerShake();
        break;
      default:
        break;
    }
  }

  void _addParticle(Offset gridPos, TileType type) {
    if (!mounted) return;

    final screenWidth = MediaQuery.of(context).size.width;
    final tileSize = (screenWidth - 36) / 8;
    final gridX = 18 + gridPos.dx * tileSize + tileSize / 2;
    // Estimate Y based on known layout
    final gridY = 250 + gridPos.dy * tileSize + tileSize / 2;

    setState(() {
      final effect = ParticleEffect(
        position: Offset(gridX, gridY),
        color: Match3Theme.gemGradients[type.index][0],
        onComplete: () {
          // No easy way to remove from here without a key or ref
        },
      );
      _effects.add(effect);
    });

    // Auto remove after 1s
    Future.delayed(const Duration(seconds: 1), () {
      if (mounted)
        setState(() {
          _effects.removeAt(0);
        });
    });
  }

  void _triggerShake() async {
    for (int i = 0; i < 6; i++) {
      if (!mounted) break;
      setState(() {
        _shakeX = (math.Random().nextDouble() - 0.5) * 15;
        _shakeY = (math.Random().nextDouble() - 0.5) * 15;
      });
      await Future.delayed(const Duration(milliseconds: 30));
    }
    if (mounted) {
      setState(() {
        _shakeX = 0;
        _shakeY = 0;
      });
    }
  }

  void _addComboText(String text) {
    if (!mounted) return;
    final effect = _ComboTextEffect(
      text: text,
      onComplete: (w) {
        if (mounted) setState(() => _effects.remove(w));
      },
    );
    setState(() {
      _effects.add(effect);
    });
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: _controller,
      child: Scaffold(
        body: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: Match3Theme.darkBgGradient,
            ),
          ),
          child: Transform.translate(
            offset: Offset(_shakeX, _shakeY),
            child: Stack(
              children: [
                _buildAnimatedBackground(),

                SafeArea(
                  child: Column(
                    children: [
                      _buildTopBar(),
                      const SizedBox(height: 20),
                      _buildScoreBoard(),
                      const Spacer(),
                      _buildGrid(),
                      const Spacer(),
                      _buildBottomBar(),
                    ],
                  ),
                ),

                ..._effects,

                Positioned(
                  top: 10,
                  left: 10,
                  child: IconButton(
                    icon: const Icon(
                      Icons.arrow_back_ios_new,
                      color: Colors.white,
                    ),
                    onPressed: () => Navigator.pop(context),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAnimatedBackground() {
    return Stack(
      children: List.generate(5, (index) {
        return Positioned(
          left: (index * 100).toDouble(),
          top: (index * 150).toDouble(),
          child: AnimatedBuilder(
            animation: AnimationController(
              vsync: this,
              duration: Duration(seconds: 10 + index * 2),
            )..repeat(reverse: true),
            builder: (context, child) {
              return Opacity(
                opacity: 0.1,
                child: Container(
                  width: 200,
                  height: 200,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        Match3Theme.gemGradients[index % 6][0],
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        );
      }),
    );
  }

  Widget _buildTopBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text(
            "LEVEL 1",
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
              letterSpacing: 2,
            ),
          ),
          IconButton(
            icon: const Icon(Icons.settings, color: Colors.white),
            onPressed: () {},
          ),
        ],
      ),
    );
  }

  Widget _buildScoreBoard() {
    return Consumer<Match3Controller>(
      builder: (context, controller, child) {
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 20),
          padding: const EdgeInsets.all(20),
          decoration: Match3Theme.glassBoxDecoration(isDark: true),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _infoItem(
                "SCORE",
                "${controller.score}",
                Match3Theme.primaryPink,
              ),
              _infoItem(
                "MOVES",
                "${controller.moves}",
                Match3Theme.juicyOrange,
              ),
              _infoItem("TARGET", "2000", Match3Theme.oceanBlue),
            ],
          ),
        );
      },
    );
  }

  Widget _infoItem(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withOpacity(0.5),
            fontSize: 12,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            color: color,
            fontSize: 24,
            fontWeight: FontWeight.w900,
          ),
        ),
      ],
    );
  }

  Widget _buildGrid() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 10),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.3),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white10),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final double tileSize = (constraints.maxWidth - 16) / 8;
          return Consumer<Match3Controller>(
            builder: (context, controller, child) {
              return GestureDetector(
                onPanDown: (details) {
                  final int c = (details.localPosition.dx / tileSize).floor();
                  final int r = (details.localPosition.dy / tileSize).floor();
                  if (r >= 0 && r < 8 && c >= 0 && c < 8) {
                    setState(() {
                      _selectedRow = r;
                      _selectedCol = c;
                    });
                  }
                },
                onPanUpdate: (details) {
                  if (_selectedRow == null) return;

                  final double dx =
                      details.localPosition.dx -
                      (_selectedCol! * tileSize + tileSize / 2);
                  final double dy =
                      details.localPosition.dy -
                      (_selectedRow! * tileSize + tileSize / 2);

                  int targetRow = _selectedRow!;
                  int targetCol = _selectedCol!;

                  if (dx.abs() > dy.abs()) {
                    if (dx.abs() > tileSize * 0.4) {
                      targetCol = _selectedCol! + (dx > 0 ? 1 : -1);
                    }
                  } else {
                    if (dy.abs() > tileSize * 0.4) {
                      targetRow = _selectedRow! + (dy > 0 ? 1 : -1);
                    }
                  }

                  if (targetRow != _selectedRow || targetCol != _selectedCol) {
                    if (targetRow >= 0 &&
                        targetRow < 8 &&
                        targetCol >= 0 &&
                        targetCol < 8) {
                      _controller.swapTiles(
                        _selectedRow!,
                        _selectedCol!,
                        targetRow,
                        targetCol,
                      );
                      _selectedRow = null;
                      _selectedCol = null;
                    }
                  }
                },
                child: SizedBox(
                  width: constraints.maxWidth - 16,
                  height: (constraints.maxWidth - 16),
                  child: Stack(
                    children: [
                      for (int r = 0; r < 8; r++)
                        for (int c = 0; c < 8; c++)
                          Positioned(
                            left: c * tileSize,
                            top: r * tileSize,
                            child: TileWidget(
                              tile: controller.grid[r][c],
                              size: tileSize,
                              onTap: () {
                                setState(() {
                                  _selectedRow = r;
                                  _selectedCol = c;
                                });
                              },
                            ),
                          ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildBottomBar() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _boosterButton(Icons.bolt_rounded, "BOMB"),
          _boosterButton(Icons.auto_awesome_rounded, "COLOR"),
          _boosterButton(Icons.refresh_rounded, "MIX"),
        ],
      ),
    );
  }

  Widget _boosterButton(IconData icon, String label) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: Match3Theme.glassBoxDecoration(isDark: true),
          child: Icon(icon, color: Colors.white),
        ),
        const SizedBox(height: 5),
        Text(
          label,
          style: const TextStyle(
            color: Colors.white54,
            fontSize: 10,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}

class _ComboTextEffect extends StatefulWidget {
  final String text;
  final Function(Widget) onComplete;

  const _ComboTextEffect({required this.text, required this.onComplete});

  @override
  State<_ComboTextEffect> createState() => _ComboTextEffectState();
}

class _ComboTextEffectState extends State<_ComboTextEffect>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scale;
  late Animation<double> _opacity;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    );
    _scale = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween(
          begin: 0.0,
          end: 1.5,
        ).chain(CurveTween(curve: Curves.elasticOut)),
        weight: 40,
      ),
      TweenSequenceItem(tween: Tween(begin: 1.5, end: 1.2), weight: 60),
    ]).animate(_controller);
    _opacity = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(parent: _controller, curve: const Interval(0.6, 1.0)),
    );
    _controller.forward().then((_) => widget.onComplete(widget));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: FadeTransition(
        opacity: _opacity,
        child: ScaleTransition(
          scale: _scale,
          child: Text(
            widget.text,
            style: const TextStyle(
              fontSize: 48,
              fontWeight: FontWeight.w900,
              color: Colors.white,
              fontStyle: FontStyle.italic,
              shadows: [
                Shadow(color: Colors.blueAccent, blurRadius: 20),
                Shadow(color: Colors.pinkAccent, blurRadius: 10),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
