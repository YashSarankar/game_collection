import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../core/models/game_model.dart';
import '../../core/services/haptic_service.dart';
import '../../core/services/sound_service.dart';

enum GameState { idle, waiting, signal, tooEarly, result, gameOver }

enum ReactionMode { singlePlayer, battle }

class ReactionTimeBattleWidget extends StatefulWidget {
  final GameModel game;

  const ReactionTimeBattleWidget({super.key, required this.game});

  @override
  State<ReactionTimeBattleWidget> createState() =>
      _ReactionTimeBattleWidgetState();
}

class _ReactionTimeBattleWidgetState extends State<ReactionTimeBattleWidget>
    with TickerProviderStateMixin {
  ReactionMode _mode = ReactionMode.singlePlayer;
  GameState _state = GameState.idle;

  // Single Player stats
  int? _lastReactionTime;
  int? _bestReactionTime;

  // Battle stats
  int _p1Score = 0;
  int _p2Score = 0;
  int? _p1ReactionTime;
  int? _p2ReactionTime;
  bool _p1Tapped = false;
  bool _p2Tapped = false;
  final int _targetRounds = 3;
  int _currentRound = 1;
  String _roundWinner = "";

  Timer? _delayTimer;
  DateTime? _signalStartTime;

  late HapticService _hapticService;
  late SoundService _soundService;
  bool _servicesInitialized = false;

  // Animations
  late AnimationController _pulseController;
  late AnimationController _shakeController;

  @override
  void initState() {
    super.initState();
    _initializeServices();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat(reverse: true);

    _shakeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 50),
    );
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
    _delayTimer?.cancel();
    _pulseController.dispose();
    _shakeController.dispose();
    super.dispose();
  }

  void _startWaiting() {
    _delayTimer?.cancel();
    setState(() {
      _state = GameState.waiting;
      _p1Tapped = false;
      _p2Tapped = false;
      _p1ReactionTime = null;
      _p2ReactionTime = null;
      _lastReactionTime = null;
      _roundWinner = "";
    });

    final randomDelay = 1000 + math.Random().nextInt(4000); // 1-5 seconds

    // Difficulty Scaling: chance of a fake signal
    final isFakeSignal = math.Random().nextDouble() < 0.15; // 15% chance

    _delayTimer = Timer(Duration(milliseconds: randomDelay), () {
      if (mounted) {
        if (isFakeSignal) {
          _hapticService.light();
          _showFakeSignal();
        } else {
          setState(() {
            _state = GameState.signal;
            _signalStartTime = DateTime.now();
          });
          _hapticService.heavy();
          _soundService.playGameStart();
        }
      }
    });
  }

  void _showFakeSignal() {
    setState(() {
      _shakeController.forward(from: 0).then((_) => _shakeController.reverse());
    });
    _hapticService.medium();
    // Restart wait after a short delay
    Timer(const Duration(milliseconds: 500), _startWaiting);
  }

  void _handleTap(int player) {
    if (_state == GameState.idle ||
        _state == GameState.result ||
        _state == GameState.gameOver)
      return;

    if (_state == GameState.waiting) {
      // Too early
      _hapticService.error();
      _soundService.playError();
      _delayTimer?.cancel();
      setState(() {
        _state = GameState.tooEarly;
        if (_mode == ReactionMode.battle) {
          if (player == 1) {
            _p1Tapped = true;
            _p1ReactionTime = 9999;
            _roundWinner = "Player 2 Wins Round!";
            _p2Score++;
          } else {
            _p2Tapped = true;
            _p2ReactionTime = 9999;
            _roundWinner = "Player 1 Wins Round!";
            _p1Score++;
          }
          _checkMatchEnd();
        } else {
          _lastReactionTime = -1; // Indicates too early
          _roundWinner = "TOO EARLY!";
        }
      });
      return;
    }

    if (_state == GameState.signal) {
      final reactionTime = DateTime.now()
          .difference(_signalStartTime!)
          .inMilliseconds;
      _hapticService.light();
      _soundService.playPoint();

      setState(() {
        if (_mode == ReactionMode.singlePlayer) {
          _lastReactionTime = reactionTime;
          if (_bestReactionTime == null || reactionTime < _bestReactionTime!) {
            _bestReactionTime = reactionTime;
            _soundService.playSuccess();
          }
          _state = GameState.result;
        } else {
          if (player == 1 && !_p1Tapped) {
            _p1Tapped = true;
            _p1ReactionTime = reactionTime;
          } else if (player == 2 && !_p2Tapped) {
            _p2Tapped = true;
            _p2ReactionTime = reactionTime;
          }

          if (_p1Tapped && _p2Tapped) {
            if (_p1ReactionTime! < _p2ReactionTime!) {
              _p1Score++;
              _roundWinner = "Player 1 Wins Round!";
            } else if (_p2ReactionTime! < _p1ReactionTime!) {
              _p2Score++;
              _roundWinner = "Player 2 Wins Round!";
            } else {
              _roundWinner = "It's a Draw!";
            }
            _state = GameState.result;
            _checkMatchEnd();
            _soundService.playSuccess();
          }
        }
      });
    }
  }

  void _checkMatchEnd() {
    final winThreshold = (_targetRounds / 2).ceil();
    if (_p1Score >= winThreshold || _p2Score >= winThreshold) {
      _state = GameState.gameOver;
    }
  }

  void _nextRound() {
    if (_state == GameState.gameOver) {
      _resetGame();
    } else {
      _currentRound++;
      _startWaiting();
    }
  }

  void _resetGame() {
    setState(() {
      _p1Score = 0;
      _p2Score = 0;
      _currentRound = 1;
      _p1Tapped = false;
      _p2Tapped = false;
      _state = GameState.idle;
      _lastReactionTime = null;
    });
  }

  String _getScoreRating(int ms) {
    if (ms < 200) return "GODLIKE ⚡";
    if (ms < 250) return "INSANE 🔥";
    if (ms < 300) return "EXCELLENT ✨";
    if (ms < 400) return "AVERAGE 👍";
    return "SLUGGISH 🐢";
  }

  int _getPoints(int ms) {
    if (ms < 200) return 100;
    if (ms < 300) return 75;
    if (ms < 400) return 50;
    return 25;
  }

  @override
  Widget build(BuildContext context) {
    if (!_servicesInitialized) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      backgroundColor: _getBackgroundColor(),
      body: Stack(children: [_buildGameContent(), _buildTopBar()]),
    );
  }

  Color _getBackgroundColor() {
    switch (_state) {
      case GameState.waiting:
        return const Color(0xFFD32F2F); // Red
      case GameState.signal:
        return const Color(0xFF388E3C); // Green
      case GameState.tooEarly:
        return Colors.orange;
      case GameState.result:
        return const Color(0xFF1A1A1A);
      case GameState.gameOver:
        return Colors.black;
      default:
        return const Color(0xFF121212);
    }
  }

  Widget _buildTopBar() {
    return Positioned(
      top: 10,
      left: 0,
      right: 0,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              if (_state == GameState.idle)
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.white54),
                  onPressed: () => Navigator.of(context).pop(),
                )
              else
                const SizedBox(width: 48),
              if (_state == GameState.idle)
                const Text(
                  "REACTION BATTLE",
                  style: TextStyle(
                    color: Colors.white70,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 2,
                  ),
                ),
              if (_state != GameState.idle)
                IconButton(
                  icon: const Icon(Icons.refresh, color: Colors.white24),
                  onPressed: _resetGame,
                )
              else
                const SizedBox(width: 48),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGameContent() {
    if (_state == GameState.idle) {
      return _buildMenu();
    }

    if (_mode == ReactionMode.battle) {
      return _buildBattleContent();
    } else {
      return _buildSinglePlayerContent();
    }
  }

  Widget _buildMenu() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.black,
            widget.game.primaryColor.withOpacity(0.2),
            Colors.black,
          ],
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withOpacity(0.05),
              border: Border.all(color: Colors.white10),
            ),
            child: Icon(
              widget.game.icon,
              size: 50,
              color: widget.game.primaryColor,
            ),
          ),
          const SizedBox(height: 15),
          Text(
            widget.game.title.toUpperCase(),
            style: const TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.w900,
              color: Colors.white,
              letterSpacing: 2,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            widget.game.subtitle,
            style: TextStyle(
              color: Colors.white.withOpacity(0.5),
              fontSize: 14,
              letterSpacing: 1.0,
            ),
          ),
          const SizedBox(height: 40),
          _menuButton("SINGLE PLAYER", Icons.person_rounded, () {
            _soundService.playButtonClick();
            setState(() => _mode = ReactionMode.singlePlayer);
            _startWaiting();
          }, widget.game.primaryColor),
          const SizedBox(height: 12),
          _menuButton("BATTLE MODE", Icons.people_rounded, () {
            _soundService.playButtonClick();
            setState(() => _mode = ReactionMode.battle);
            _startWaiting();
          }, widget.game.secondaryColor),
          const SizedBox(height: 30),
          if (_bestReactionTime != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.05),
                borderRadius: BorderRadius.circular(30),
                border: Border.all(color: Colors.white10),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.emoji_events_rounded,
                    color: Colors.amber,
                    size: 16,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    "BEST: ${_bestReactionTime}ms",
                    style: const TextStyle(
                      color: Colors.white70,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _menuButton(
    String label,
    IconData icon,
    VoidCallback onTap,
    Color color,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 260,
        height: 55,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(15),
          gradient: LinearGradient(colors: [color, color.withOpacity(0.8)]),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.3),
              blurRadius: 15,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(15),
          child: Stack(
            children: [
              Positioned(
                right: -10,
                bottom: -10,
                child: Icon(
                  icon,
                  size: 70,
                  color: Colors.white.withOpacity(0.1),
                ),
              ),
              Center(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(icon, color: Colors.white, size: 20),
                    const SizedBox(width: 10),
                    Text(
                      label,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.0,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSinglePlayerContent() {
    return GestureDetector(
      onTap: () => _handleTap(1),
      behavior: HitTestBehavior.opaque,
      child: SizedBox.expand(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (_state == GameState.waiting) ...[
              const Text(
                "WAIT FOR GREEN...",
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 40),
              FadeTransition(
                opacity: _pulseController,
                child: Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    color: Colors.white24,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                  child: const Icon(
                    Icons.touch_app,
                    size: 60,
                    color: Colors.white54,
                  ),
                ),
              ),
            ],
            if (_state == GameState.signal) ...[
              const Text(
                "TAP!",
                style: TextStyle(
                  fontSize: 100,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                ),
              ),
            ],
            if (_state == GameState.tooEarly) ...[
              const Icon(
                Icons.warning_amber_rounded,
                size: 100,
                color: Colors.white,
              ),
              const SizedBox(height: 20),
              const Text(
                "TOO EARLY!",
                style: TextStyle(
                  fontSize: 48,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 60),
              _actionButton(
                "TRY AGAIN",
                _startWaiting,
                Colors.white,
                Colors.black,
              ),
            ],
            if (_state == GameState.result) ...[
              Text(
                "${_lastReactionTime}ms",
                style: const TextStyle(
                  fontSize: 100,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                ),
              ),
              Text(
                _getScoreRating(_lastReactionTime!),
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.amber,
                ),
              ),
              const SizedBox(height: 20),
              Text(
                "POINTS: ${_getPoints(_lastReactionTime!)}",
                style: TextStyle(
                  fontSize: 20,
                  color: Colors.white.withOpacity(0.5),
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 60),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _actionButton(
                    "RETRY",
                    _startWaiting,
                    Colors.amber,
                    Colors.black,
                  ),
                  const SizedBox(width: 20),
                  _actionButton(
                    "MENU",
                    _resetGame,
                    Colors.white24,
                    Colors.white,
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildBattleContent() {
    return Column(
      children: [
        Expanded(
          child: RotatedBox(quarterTurns: 2, child: _buildBattlePlayerZone(2)),
        ),
        Container(
          height: 80,
          color: Colors.black.withOpacity(0.9),
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _scoreDisplay(1, _p1Score, Colors.blueAccent),
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    "ROUND $_currentRound",
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                  Text(
                    "BEST OF $_targetRounds",
                    style: const TextStyle(color: Colors.white38, fontSize: 12),
                  ),
                ],
              ),
              _scoreDisplay(2, _p2Score, Colors.redAccent),
            ],
          ),
        ),
        Expanded(child: _buildBattlePlayerZone(1)),
      ],
    );
  }

  Widget _scoreDisplay(int player, int score, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.5)),
      ),
      child: Text(
        "$score",
        style: TextStyle(
          color: color,
          fontSize: 24,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }

  Widget _buildBattlePlayerZone(int player) {
    bool tapped = player == 1 ? _p1Tapped : _p2Tapped;
    int? time = player == 1 ? _p1ReactionTime : _p2ReactionTime;

    return GestureDetector(
      onTap: () => _handleTap(player),
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: double.infinity,
        color: _getBattleZoneColor(player),
        child: Center(
          child: Stack(
            alignment: Alignment.center,
            children: [
              if (_state == GameState.waiting)
                const Text(
                  "GET READY...",
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                  ),
                ),
              if (_state == GameState.signal && !tapped)
                const Text(
                  "TAP!",
                  style: TextStyle(
                    fontSize: 64,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                  ),
                ),
              if (tapped ||
                  _state == GameState.result ||
                  _state == GameState.tooEarly ||
                  _state == GameState.gameOver)
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (time != null) ...[
                      Text(
                        time == 9999 ? "TOO EARLY!" : "${time}ms",
                        style: const TextStyle(
                          fontSize: 48,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                        ),
                      ),
                      if (time != 9999)
                        Text(
                          _getScoreRating(time),
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.amber,
                          ),
                        ),
                    ],
                    if (_state == GameState.result) ...[
                      const SizedBox(height: 20),
                      Text(
                        _roundWinner,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 40),
                      _actionButton(
                        "NEXT ROUND",
                        _nextRound,
                        Colors.white,
                        Colors.black,
                      ),
                    ],
                    if (_state == GameState.tooEarly) ...[
                      const SizedBox(height: 20),
                      Text(
                        _roundWinner,
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 40),
                      _actionButton(
                        "CONTINUE",
                        _nextRound,
                        Colors.white,
                        Colors.black,
                      ),
                    ],
                    if (_state == GameState.gameOver) ...[
                      const SizedBox(height: 20),
                      Text(
                        (_p1Score > _p2Score && player == 1) ||
                                (_p2Score > _p1Score && player == 2)
                            ? "MATCH WINNER! 🏆"
                            : "MATCH LOST",
                        style: const TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 40),
                      _actionButton(
                        "PLAY AGAIN",
                        _resetGame,
                        Colors.white,
                        Colors.black,
                      ),
                    ],
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getBattleZoneColor(int player) {
    if (_state == GameState.waiting) return const Color(0xFFD32F2F);
    if (_state == GameState.signal) {
      bool tapped = player == 1 ? _p1Tapped : _p2Tapped;
      return tapped ? Colors.grey[900]! : const Color(0xFF388E3C);
    }
    if (_state == GameState.tooEarly) return Colors.orange;
    return Colors.black87;
  }

  Widget _actionButton(
    String label,
    VoidCallback onTap,
    Color bgColor,
    Color textColor,
  ) {
    return ElevatedButton(
      onPressed: onTap,
      style: ElevatedButton.styleFrom(
        backgroundColor: bgColor,
        foregroundColor: textColor,
        padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 20),
        elevation: 10,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(40)),
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w900,
          letterSpacing: 1,
        ),
      ),
    );
  }
}
