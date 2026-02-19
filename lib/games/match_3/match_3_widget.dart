import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/models/game_model.dart';
import '../../core/services/haptic_service.dart';
import '../../core/services/sound_service.dart';
import 'logic/match_3_controller.dart';
import 'match_3_theme.dart';
import 'models/tile_model.dart';
import 'models/game_event.dart';
import 'components/tile_widget.dart';

// ═══════════════════════════════════════════════════════════════
// Entry point: Match3Widget
// ═══════════════════════════════════════════════════════════════
class Match3Widget extends StatefulWidget {
  final GameModel game;
  const Match3Widget({super.key, required this.game});

  @override
  State<Match3Widget> createState() => _Match3WidgetState();
}

class _Match3WidgetState extends State<Match3Widget>
    with TickerProviderStateMixin {
  // ── Services (loaded in background) ─────────────────────────
  HapticService? _haptic;
  SoundService? _sound;

  // ── Controller (initialized immediately) ─────────────────────
  late Match3Controller _ctrl;
  StreamSubscription? _eventSub;

  // ── Game state ────────────────────────────────────────────────
  int _level = 1;
  int _targetScore = 2000;
  bool _gameStarted = false;
  bool _gameOver = false;
  bool _levelComplete = false;

  // ── UI State ──────────────────────────────────────────────────
  double _shakeX = 0, _shakeY = 0;
  final List<_FloatingText> _floatingTexts = [];

  // ── Animation Controllers ─────────────────────────────────────
  late AnimationController _pulseCtrl;
  late AnimationController _bgCtrl;
  late AnimationController _scoreBarCtrl;
  late Animation<double> _scoreBarAnim;

  // ── Grid interaction ──────────────────────────────────────────
  int? _dragRow, _dragCol;

  // ── Hint state ────────────────────────────────────────────────
  Timer? _hintTimer;
  ({int r1, int c1, int r2, int c2})? _hintMove;

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..repeat(reverse: true);

    _bgCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 20),
    )..repeat();

    _scoreBarCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _scoreBarAnim = Tween<double>(
      begin: 0,
      end: 0,
    ).animate(CurvedAnimation(parent: _scoreBarCtrl, curve: Curves.easeOut));

    // Initialize game controller immediately — no async blocking
    _setupController();

    // Load services in background (optional enhancements)
    _initServicesBackground();
  }

  void _initServicesBackground() {
    HapticService.getInstance().then((h) {
      if (mounted) _haptic = h;
    });
    SoundService.getInstance().then((s) {
      if (mounted) _sound = s;
    });
  }

  void _setupController() {
    _ctrl = Match3Controller(level: _level, targetScore: _targetScore);
    _eventSub?.cancel();
    _eventSub = _ctrl.events.listen(_onGameEvent);
    _scheduleHint();
  }

  void _onGameEvent(GameEvent e) {
    if (!mounted) return;
    switch (e.type) {
      case GameEventType.match:
        _haptic?.medium();
        _sound?.playPoint();
        break;
      case GameEventType.combo:
        _haptic?.heavy();
        _addFloatingText(e.message ?? 'GREAT!', _comboColor(e.message));
        _triggerShake();
        break;
      case GameEventType.shake:
        _triggerShake();
        break;
      case GameEventType.gameOver:
        _sound?.playGameOver();
        if (mounted) setState(() => _gameOver = true);
        break;
      case GameEventType.levelComplete:
        _sound?.playSuccess();
        if (mounted) setState(() => _levelComplete = true);
        break;
      default:
        break;
    }
    // Update score bar
    _updateScoreBar();
  }

  Color _comboColor(String? msg) {
    if (msg == 'INCREDIBLE!') return const Color(0xFFFFD700);
    if (msg == 'AWESOME!') return const Color(0xFFFF80AB);
    return const Color(0xFF69F0AE);
  }

  void _updateScoreBar() {
    final newValue = (_ctrl.score / _targetScore).clamp(0.0, 1.0);
    _scoreBarAnim = Tween<double>(
      begin: _scoreBarAnim.value,
      end: newValue,
    ).animate(CurvedAnimation(parent: _scoreBarCtrl, curve: Curves.easeOut));
    _scoreBarCtrl.forward(from: 0);
  }

  void _scheduleHint() {
    _hintTimer?.cancel();
    _hintTimer = Timer(const Duration(seconds: 5), _showHint);
  }

  void _showHint() {
    final hint = _ctrl.findHintMove();
    if (hint != null && mounted) {
      setState(() => _hintMove = hint);
      Future.delayed(const Duration(seconds: 2), () {
        if (mounted) setState(() => _hintMove = null);
      });
    }
  }

  void _resetHintTimer() {
    _hintMove = null;
    _scheduleHint();
  }

  Future<void> _triggerShake() async {
    for (int i = 0; i < 5; i++) {
      if (!mounted) break;
      setState(() {
        _shakeX = (math.Random().nextDouble() - 0.5) * 14;
        _shakeY = (math.Random().nextDouble() - 0.5) * 14;
      });
      await Future.delayed(const Duration(milliseconds: 30));
    }
    if (mounted)
      setState(() {
        _shakeX = 0;
        _shakeY = 0;
      });
  }

  void _addFloatingText(String text, Color color) {
    final ft = _FloatingText(text: text, color: color, key: UniqueKey());
    setState(() => _floatingTexts.add(ft));
    Future.delayed(const Duration(milliseconds: 1200), () {
      if (mounted) setState(() => _floatingTexts.remove(ft));
    });
  }

  Future<void> _doSwap(int r1, int c1, int r2, int c2) async {
    _resetHintTimer();
    final success = await _ctrl.swapTiles(r1, c1, r2, c2);
    if (!success) {
      _haptic?.error();
    }
    if (_ctrl.score >= _targetScore) {
      await Future.delayed(const Duration(milliseconds: 300));
      if (mounted) {
        setState(() => _levelComplete = true);
        _sound?.playSuccess();
      }
    } else if (_ctrl.moves <= 0 && !_ctrl.isProcessing) {
      await Future.delayed(const Duration(milliseconds: 300));
      if (mounted) {
        setState(() => _gameOver = true);
        _sound?.playGameOver();
      }
    }
  }

  void _startGame() {
    _sound?.playGameStart();
    setState(() => _gameStarted = true);
    _scheduleHint();
  }

  void _resetGame() {
    _hintTimer?.cancel();
    _setupController();
    setState(() {
      _gameStarted = false;
      _gameOver = false;
      _levelComplete = false;
      _level = 1;
      _targetScore = 2000;
      _floatingTexts.clear();
      _hintMove = null;
    });
    _updateScoreBar();
  }

  void _nextLevel() {
    _hintTimer?.cancel();
    setState(() {
      _level++;
      _targetScore += 1500;
      _gameOver = false;
      _levelComplete = false;
      _floatingTexts.clear();
      _hintMove = null;
    });
    _setupController();
    _updateScoreBar();
  }

  @override
  void dispose() {
    _hintTimer?.cancel();
    _eventSub?.cancel();
    _pulseCtrl.dispose();
    _bgCtrl.dispose();
    _scoreBarCtrl.dispose();
    super.dispose();
  }

  // ═══════════════════════════════════════════════════════════════
  // BUILD
  // ═══════════════════════════════════════════════════════════════
  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark,
      child: Scaffold(
        backgroundColor: Colors.black,
        body: Stack(
          children: [
            // Animated background
            _AnimatedBg(controller: _bgCtrl),

            // Main game UI
            Transform.translate(
              offset: Offset(_shakeX, _shakeY),
              child: SafeArea(
                child: Column(
                  children: [
                    _buildTopBar(),
                    _buildHeader(),
                    _buildScoreBar(),
                    const SizedBox(height: 8),
                    Expanded(child: _buildGrid()),
                    _buildBoosterBar(),
                    const SizedBox(height: 10),
                  ],
                ),
              ),
            ),

            // Floating Combo Texts
            ..._floatingTexts.map((ft) => ft.build()),

            // Overlays
            if (!_gameStarted && !_gameOver && !_levelComplete)
              _buildMenuOverlay(),
            if (_gameOver) _buildGameOverOverlay(),
            if (_levelComplete) _buildLevelCompleteOverlay(),
          ],
        ),
      ),
    );
  }

  // ─── Top bar ──────────────────────────────────────────────────
  Widget _buildTopBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          ShaderMask(
            shaderCallback: (r) => const LinearGradient(
              colors: [Color(0xFFFF4081), Color(0xFF7C4DFF)],
            ).createShader(r),
            child: const Text(
              'MATCH 3',
              style: TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.w900,
                letterSpacing: 4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─── Header: score, moves, level ─────────────────────────────
  Widget _buildHeader() {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (context, _) {
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 12),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.45),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Colors.white12, width: 1),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _statChip('SCORE', '${_ctrl.score}', Match3Theme.primaryPink),
              _vertDivider(),
              _statChip('LEVEL', '$_level', const Color(0xFF69F0AE)),
              _vertDivider(),
              _statChip(
                'MOVES',
                '${_ctrl.moves}',
                _ctrl.moves <= 5 ? Colors.redAccent : Match3Theme.juicyOrange,
              ),
              _vertDivider(),
              _statChip('TARGET', '$_targetScore', Match3Theme.oceanBlue),
            ],
          ),
        );
      },
    );
  }

  Widget _statChip(String label, String value, Color color) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withOpacity(0.4),
            fontSize: 9,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.2,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            color: color,
            fontSize: 22,
            fontWeight: FontWeight.w900,
            shadows: [Shadow(color: color.withOpacity(0.5), blurRadius: 12)],
          ),
        ),
      ],
    );
  }

  Widget _vertDivider() =>
      Container(width: 1, height: 36, color: Colors.white.withOpacity(0.08));

  // ─── Score progress bar ───────────────────────────────────────
  Widget _buildScoreBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Progress',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.5),
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
              AnimatedBuilder(
                animation: _ctrl,
                builder: (context, _) => Text(
                  '${((_ctrl.score / _targetScore) * 100).clamp(0, 100).toStringAsFixed(0)}%',
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 5),
          Container(
            height: 8,
            decoration: BoxDecoration(
              color: Colors.white12,
              borderRadius: BorderRadius.circular(10),
            ),
            child: AnimatedBuilder(
              animation: _scoreBarAnim,
              builder: (context, _) => Align(
                alignment: Alignment.centerLeft,
                child: FractionallySizedBox(
                  widthFactor: _scoreBarAnim.value,
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                      gradient: const LinearGradient(
                        colors: [
                          Color(0xFFFF4081),
                          Color(0xFFE040FB),
                          Color(0xFF7C4DFF),
                        ],
                      ),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0xFFFF4081),
                          blurRadius: 10,
                          spreadRadius: 1,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─── Game grid ────────────────────────────────────────────────
  Widget _buildGrid() {
    const double gridPadding = 6.0; // inner padding of the container
    const double margin = 16.0; // horizontal margin on each side

    return LayoutBuilder(
      builder: (ctx, constraints) {
        // Grid must be square. Use the smaller of width and available height.
        final double availW = constraints.maxWidth - margin * 2;
        final double availH = constraints.maxHeight;
        final double outerSide = math.min(availW, availH);

        // Inner content area (where tiles actually live)
        final double innerSide = outerSide - gridPadding * 2;
        final double tileSize = innerSide / 8;

        return Center(
          child: AnimatedBuilder(
            animation: _ctrl,
            builder: (context, _) => Container(
              width: outerSide,
              height: outerSide,
              padding: const EdgeInsets.all(gridPadding),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.35),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.white10, width: 1.5),
                boxShadow: const [
                  BoxShadow(
                    color: Colors.black54,
                    blurRadius: 20,
                    offset: Offset(0, 8),
                  ),
                ],
              ),
              // ClipRRect ensures tiles never render outside the box
              child: ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onPanDown: (d) {
                    if (_ctrl.isProcessing || !_gameStarted) return;
                    final c = (d.localPosition.dx / tileSize).floor().clamp(
                      0,
                      7,
                    );
                    final r = (d.localPosition.dy / tileSize).floor().clamp(
                      0,
                      7,
                    );
                    setState(() {
                      _dragRow = r;
                      _dragCol = c;
                    });
                  },
                  onPanUpdate: (d) {
                    if (_dragRow == null || _ctrl.isProcessing) return;
                    final double originX = _dragCol! * tileSize + tileSize / 2;
                    final double originY = _dragRow! * tileSize + tileSize / 2;
                    final double dx = d.localPosition.dx - originX;
                    final double dy = d.localPosition.dy - originY;
                    final double thresh = tileSize * 0.42;
                    int tr = _dragRow!, tc = _dragCol!;
                    if (dx.abs() > dy.abs()) {
                      if (dx.abs() > thresh) tc += (dx > 0 ? 1 : -1);
                    } else {
                      if (dy.abs() > thresh) tr += (dy > 0 ? 1 : -1);
                    }
                    if ((tr != _dragRow || tc != _dragCol) &&
                        tr >= 0 &&
                        tr < 8 &&
                        tc >= 0 &&
                        tc < 8) {
                      final r1 = _dragRow!, c1 = _dragCol!;
                      setState(() {
                        _dragRow = null;
                        _dragCol = null;
                      });
                      _doSwap(r1, c1, tr, tc);
                    }
                  },
                  onPanCancel: () => setState(() {
                    _dragRow = null;
                    _dragCol = null;
                  }),
                  // SizedBox ensures the Stack is EXACTLY the inner content size
                  child: SizedBox(
                    width: innerSide,
                    height: innerSide,
                    child: Stack(
                      clipBehavior: Clip.hardEdge,
                      children: [
                        for (int r = 0; r < 8; r++)
                          for (int c = 0; c < 8; c++)
                            AnimatedPositioned(
                              duration: const Duration(milliseconds: 220),
                              curve: Curves.easeOutCubic,
                              left: c * tileSize,
                              top: r * tileSize,
                              width: tileSize,
                              height: tileSize,
                              child: _buildTileAt(r, c, tileSize),
                            ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildTileAt(int r, int c, double tileSize) {
    final tile = _ctrl.grid[r][c];
    final isHint =
        _hintMove != null &&
        ((r == _hintMove!.r1 && c == _hintMove!.c1) ||
            (r == _hintMove!.r2 && c == _hintMove!.c2));

    if (tile.type == TileType.empty) {
      return SizedBox(width: tileSize, height: tileSize);
    }

    return AnimatedBuilder(
      animation: _pulseCtrl,
      builder: (context, child) {
        final scale = isHint ? (1.0 + _pulseCtrl.value * 0.12) : 1.0;
        return Transform.scale(
          scale: scale,
          child: TileWidget(tile: tile, size: tileSize),
        );
      },
    );
  }

  // ─── Booster bar ──────────────────────────────────────────────
  Widget _buildBoosterBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _boosterBtn(
            Icons.auto_awesome_rounded,
            'SHUFFLE',
            const Color(0xFFFF4081),
            () {
              _ctrl.debugShuffle();
              _haptic?.heavy();
            },
          ),
          _boosterBtn(
            Icons.tune_rounded,
            'HINT',
            const Color(0xFF69F0AE),
            _showHint,
          ),
        ],
      ),
    );
  }

  Widget _boosterBtn(
    IconData icon,
    String label,
    Color color,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: color.withOpacity(0.15),
              border: Border.all(color: color.withOpacity(0.4), width: 1.5),
              boxShadow: [
                BoxShadow(color: color.withOpacity(0.3), blurRadius: 12),
              ],
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              color: color.withOpacity(0.7),
              fontSize: 9,
              fontWeight: FontWeight.w900,
              letterSpacing: 1,
            ),
          ),
        ],
      ),
    );
  }

  // ─── Menu overlay ─────────────────────────────────────────────
  Widget _buildMenuOverlay() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xEF0D0D1A), Color(0xFF080810)],
        ),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Icon
            Container(
              padding: const EdgeInsets.all(28),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const RadialGradient(
                  colors: [Color(0x44FF4081), Colors.transparent],
                ),
                border: Border.all(color: const Color(0x55FF4081), width: 2),
              ),
              child: const Icon(
                Icons.grid_view_rounded,
                size: 70,
                color: Color(0xFFFF4081),
              ),
            ),
            const SizedBox(height: 28),
            // Title
            ShaderMask(
              shaderCallback: (bounds) => const LinearGradient(
                colors: [Color(0xFFFF4081), Color(0xFF7C4DFF)],
              ).createShader(bounds),
              child: const Text(
                'MATCH 3',
                style: TextStyle(
                  fontSize: 52,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 8,
                  color: Colors.white,
                ),
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'MATCH 3 GEMS TO SCORE',
              style: TextStyle(
                color: Colors.white38,
                fontSize: 13,
                letterSpacing: 3,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 60),
            // Play button
            _PremiumButton(
              label: '▶  PLAY NOW',
              gradient: const LinearGradient(
                colors: [Color(0xFFFF4081), Color(0xFF7C4DFF)],
              ),
              onTap: _startGame,
            ),
            const SizedBox(height: 24),
            Text(
              'TARGET  •  $_targetScore POINTS  •  30 MOVES',
              style: const TextStyle(
                color: Colors.white24,
                fontSize: 11,
                letterSpacing: 1.5,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Game Over overlay ────────────────────────────────────────
  Widget _buildGameOverOverlay() {
    return _FullOverlay(
      emoji: '💔',
      title: 'GAME OVER',
      titleGradient: const [Color(0xFFFF1744), Color(0xFFFF4081)],
      subtitle: 'You ran out of moves!',
      score: _ctrl.score,
      level: _level,
      primaryLabel: '🔁  TRY AGAIN',
      primaryGradient: const LinearGradient(
        colors: [Color(0xFFFF1744), Color(0xFFFF4081)],
      ),
      onPrimary: _resetGame,
      secondaryLabel: '🏠  HOME',
      onSecondary: () => Navigator.of(context).pop(),
    );
  }

  // ─── Level Complete overlay ───────────────────────────────────
  Widget _buildLevelCompleteOverlay() {
    final stars = _ctrl.score >= _targetScore * 1.5
        ? 3
        : (_ctrl.score >= _targetScore * 1.2 ? 2 : 1);

    return _FullOverlay(
      emoji: '🎉',
      title: 'LEVEL $_level\nCOMPLETE!',
      titleGradient: const [Color(0xFFFFD700), Color(0xFFFF8800)],
      subtitle: '⭐' * stars,
      score: _ctrl.score,
      level: _level,
      primaryLabel: '➡  NEXT LEVEL',
      primaryGradient: const LinearGradient(
        colors: [Color(0xFFFFD700), Color(0xFFFF8800)],
      ),
      onPrimary: _nextLevel,
      secondaryLabel: '🏠  HOME',
      onSecondary: () => Navigator.of(context).pop(),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// Animated background
// ═══════════════════════════════════════════════════════════════
class _AnimatedBg extends StatelessWidget {
  final AnimationController controller;
  const _AnimatedBg({required this.controller});

  static const List<_BgBlob> _blobs = [
    _BgBlob(x: 0.1, y: 0.1, color: Color(0x22FF4081), size: 340),
    _BgBlob(x: 0.8, y: 0.25, color: Color(0x1A7C4DFF), size: 280),
    _BgBlob(x: 0.2, y: 0.7, color: Color(0x1840C4FF), size: 260),
    _BgBlob(x: 0.75, y: 0.75, color: Color(0x22E040FB), size: 300),
    _BgBlob(x: 0.5, y: 0.5, color: Color(0x111A1A2E), size: 500),
  ];

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (ctx, _) {
        final t = controller.value;
        return Stack(
          children: [
            Container(color: const Color(0xFF0D0D1A)),
            ..._blobs.map((b) {
              final dx = math.sin(t * math.pi * 2 + b.x * 10) * 30;
              final dy = math.cos(t * math.pi * 2 + b.y * 10) * 25;
              return Positioned(
                left: (MediaQuery.of(ctx).size.width * b.x) + dx - b.size / 2,
                top: (MediaQuery.of(ctx).size.height * b.y) + dy - b.size / 2,
                child: Container(
                  width: b.size,
                  height: b.size,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [b.color, Colors.transparent],
                    ),
                  ),
                ),
              );
            }),
          ],
        );
      },
    );
  }
}

class _BgBlob {
  final double x, y, size;
  final Color color;
  const _BgBlob({
    required this.x,
    required this.y,
    required this.color,
    required this.size,
  });
}

// ═══════════════════════════════════════════════════════════════
// Floating combo text
// ═══════════════════════════════════════════════════════════════
class _FloatingText {
  final String text;
  final Color color;
  final Key key;

  const _FloatingText({
    required this.text,
    required this.color,
    required this.key,
  });

  Widget build() {
    return _FloatingTextWidget(key: key, text: text, color: color);
  }
}

class _FloatingTextWidget extends StatefulWidget {
  final String text;
  final Color color;
  const _FloatingTextWidget({
    super.key,
    required this.text,
    required this.color,
  });

  @override
  State<_FloatingTextWidget> createState() => _FloatingTextWidgetState();
}

class _FloatingTextWidgetState extends State<_FloatingTextWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _c;
  late Animation<double> _scale, _opacity, _y;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    )..forward();
    _scale = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween(
          begin: 0.3,
          end: 1.4,
        ).chain(CurveTween(curve: Curves.elasticOut)),
        weight: 45,
      ),
      TweenSequenceItem(tween: Tween(begin: 1.4, end: 1.0), weight: 55),
    ]).animate(_c);
    _opacity = Tween<double>(
      begin: 1.0,
      end: 0.0,
    ).animate(CurvedAnimation(parent: _c, curve: const Interval(0.65, 1.0)));
    _y = Tween<double>(
      begin: 0,
      end: -70,
    ).animate(CurvedAnimation(parent: _c, curve: Curves.easeOut));
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: AnimatedBuilder(
        animation: _c,
        builder: (_, __) => Transform.translate(
          offset: Offset(0, _y.value),
          child: FadeTransition(
            opacity: _opacity,
            child: ScaleTransition(
              scale: _scale,
              child: Text(
                widget.text,
                style: TextStyle(
                  fontSize: 46,
                  fontWeight: FontWeight.w900,
                  fontStyle: FontStyle.italic,
                  color: Colors.white,
                  shadows: [
                    Shadow(
                      color: widget.color,
                      blurRadius: 22,
                      offset: Offset.zero,
                    ),
                    Shadow(
                      color: widget.color.withOpacity(0.5),
                      blurRadius: 40,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// Premium Button
// ═══════════════════════════════════════════════════════════════
class _PremiumButton extends StatefulWidget {
  final String label;
  final LinearGradient gradient;
  final VoidCallback onTap;
  const _PremiumButton({
    required this.label,
    required this.gradient,
    required this.onTap,
  });

  @override
  State<_PremiumButton> createState() => _PremiumButtonState();
}

class _PremiumButtonState extends State<_PremiumButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _c;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..repeat(reverse: true);
    _scale = Tween<double>(
      begin: 1.0,
      end: 1.04,
    ).animate(CurvedAnimation(parent: _c, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      child: ScaleTransition(
        scale: _scale,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 60, vertical: 20),
          decoration: BoxDecoration(
            gradient: widget.gradient,
            borderRadius: BorderRadius.circular(40),
            boxShadow: [
              BoxShadow(
                color: widget.gradient.colors.first.withOpacity(0.45),
                blurRadius: 28,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Text(
            widget.label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.5,
            ),
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// Full screen overlay (Game Over / Level Complete)
// ═══════════════════════════════════════════════════════════════
class _FullOverlay extends StatefulWidget {
  final String emoji, title, subtitle;
  final List<Color> titleGradient;
  final int score, level;
  final String primaryLabel, secondaryLabel;
  final LinearGradient primaryGradient;
  final VoidCallback onPrimary, onSecondary;

  const _FullOverlay({
    required this.emoji,
    required this.title,
    required this.titleGradient,
    required this.subtitle,
    required this.score,
    required this.level,
    required this.primaryLabel,
    required this.primaryGradient,
    required this.onPrimary,
    required this.secondaryLabel,
    required this.onSecondary,
  });

  @override
  State<_FullOverlay> createState() => _FullOverlayState();
}

class _FullOverlayState extends State<_FullOverlay>
    with SingleTickerProviderStateMixin {
  late AnimationController _c;
  late Animation<double> _scale, _fade;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    )..forward();
    _scale = Tween<double>(
      begin: 0.85,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _c, curve: Curves.easeOutBack));
    _fade = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _c, curve: Curves.easeIn));
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _c,
      builder: (_, child) => FadeTransition(
        opacity: _fade,
        child: Container(
          color: Colors.black.withOpacity(0.88),
          child: Center(
            child: ScaleTransition(
              scale: _scale,
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 28),
                padding: const EdgeInsets.symmetric(
                  horizontal: 30,
                  vertical: 36,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFF1A1A2E),
                  borderRadius: BorderRadius.circular(32),
                  border: Border.all(
                    color: widget.titleGradient.first.withOpacity(0.35),
                    width: 1.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: widget.titleGradient.first.withOpacity(0.2),
                      blurRadius: 40,
                      spreadRadius: 5,
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(widget.emoji, style: const TextStyle(fontSize: 52)),
                    const SizedBox(height: 16),
                    ShaderMask(
                      shaderCallback: (r) => LinearGradient(
                        colors: widget.titleGradient,
                      ).createShader(r),
                      child: Text(
                        widget.title,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 34,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                          height: 1.1,
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      widget.subtitle,
                      style: const TextStyle(fontSize: 22, letterSpacing: 2),
                    ),
                    const SizedBox(height: 24),
                    // Stats row
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 14,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.05),
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _statItem(
                            'SCORE',
                            '${widget.score}',
                            const Color(0xFFFF4081),
                          ),
                          _statItem(
                            'LEVEL',
                            '${widget.level}',
                            const Color(0xFF69F0AE),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 30),
                    _PremiumButton(
                      label: widget.primaryLabel,
                      gradient: widget.primaryGradient,
                      onTap: widget.onPrimary,
                    ),
                    const SizedBox(height: 14),
                    GestureDetector(
                      onTap: widget.onSecondary,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 50,
                          vertical: 15,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.07),
                          borderRadius: BorderRadius.circular(40),
                          border: Border.all(color: Colors.white24, width: 1),
                        ),
                        child: Text(
                          widget.secondaryLabel,
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _statItem(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withOpacity(0.4),
            fontSize: 10,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.2,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            color: color,
            fontSize: 26,
            fontWeight: FontWeight.w900,
            shadows: [Shadow(color: color, blurRadius: 12)],
          ),
        ),
      ],
    );
  }
}
