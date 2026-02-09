import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'package:flutter/scheduler.dart';
import 'space_shooter_duel_logic.dart';
import '../../core/services/sound_service.dart';
import '../../ui/widgets/game_countdown.dart';
import '../../ui/widgets/game_over_dialog.dart';

class SpaceShooterDuelWidget extends StatefulWidget {
  const SpaceShooterDuelWidget({super.key});

  @override
  State<SpaceShooterDuelWidget> createState() => _SpaceShooterDuelWidgetState();
}

class _SpaceShooterDuelWidgetState extends State<SpaceShooterDuelWidget>
    with TickerProviderStateMixin {
  late SpaceShooterDuelLogic _logic;
  Ticker? _ticker;
  bool _isCountingDown = true;
  bool _gameStarted = false;
  bool _isGameOver = false;

  // Control state
  Offset _p1MoveJoystick = Offset.zero;
  Offset _p2MoveJoystick = Offset.zero;

  SoundService? _soundService;

  @override
  void initState() {
    super.initState();
    _logic = SpaceShooterDuelLogic();
    _initServices();
    _setupSoundCallbacks();
  }

  Future<void> _initServices() async {
    _soundService = await SoundService.getInstance();
  }

  void _setupSoundCallbacks() {
    _logic.onShoot = () {
      _soundService?.playMoveSound('sounds/space_shoot.mp3');
    };
  }

  void _onCountdownFinished() {
    setState(() {
      _isCountingDown = false;
      _gameStarted = true;
      _startTicker();
    });
  }

  void _startTicker() {
    _ticker = createTicker((elapsed) {
      if (!mounted || _isGameOver) return;

      final dt = 0.016; // Approx 60 FPS

      setState(() {
        _logic.handleJoystickMovePlayer1(_p1MoveJoystick, dt);
        _logic.handleJoystickMovePlayer2(
          _p2MoveJoystick * -1,
          dt,
        ); // Inverted for P2

        _logic.update(dt);

        if (_logic.player1Health <= 0 ||
            _logic.player2Health <= 0 ||
            _logic.timeRemaining <= 0) {
          _endGame();
        }
      });
    });
    _ticker!.start();
  }

  void _endGame() {
    if (_isGameOver) return;
    _isGameOver = true;
    _ticker?.stop();
    _showGameOver();
  }

  void _showGameOver() {
    String winner;
    if (_logic.player1Health > _logic.player2Health) {
      winner = 'Player 1 Wins!';
    } else if (_logic.player2Health > _logic.player1Health) {
      winner = 'Player 2 Wins!';
    } else {
      winner = 'It\'s a Draw!';
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => GameOverDialog(
        gameId: 'space_shooter',
        score: math.max(_logic.player1Health, _logic.player2Health),
        customMessage: winner,
        onRestart: () {
          Navigator.pop(context);
          _restartGame();
        },
        onHome: () {
          Navigator.pop(context);
          Navigator.pop(context);
        },
      ),
    );
  }

  void _restartGame() {
    setState(() {
      _logic = SpaceShooterDuelLogic();
      _setupSoundCallbacks(); // Re-setup sound callbacks for new logic instance
      _isCountingDown = true;
      _gameStarted = false;
      _isGameOver = false;
      _p1MoveJoystick = Offset.zero;
      _p2MoveJoystick = Offset.zero;
    });
  }

  @override
  void dispose() {
    _ticker?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0F23),
      body: LayoutBuilder(
        builder: (context, constraints) {
          _logic.screenSize = Size(constraints.maxWidth, constraints.maxHeight);

          return Stack(
            children: [
              // Background
              _buildBackground(),

              // Game Layer
              if (!_isCountingDown) _buildGameLayer(),

              // HUD
              if (_gameStarted) _buildHUD(),

              // Controls
              if (_gameStarted && !_isGameOver) _buildControls(),

              // Countdown overlay
              if (_isCountingDown)
                Container(
                  color: Colors.black54,
                  child: GameCountdown(onFinished: _onCountdownFinished),
                ),

              // Back
              if (!_gameStarted)
                Positioned(
                  top: 40,
                  left: 20,
                  child: IconButton(
                    icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildBackground() {
    return CustomPaint(painter: StarsBackgroundPainter(), size: Size.infinite);
  }

  Widget _buildHUD() {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        child: Column(
          children: [
            _buildCompactHealthBar(
              _logic.player2Health,
              Colors.pinkAccent,
              "P2",
              true,
            ),
            const SizedBox(height: 10),
            Center(child: _buildTimer()),
            const Spacer(),
            _buildCompactHealthBar(
              _logic.player1Health,
              Colors.cyanAccent,
              "P1",
              false,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTimer() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.black45,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white10),
      ),
      child: Text(
        '${_logic.timeRemaining.floor()}s',
        style: const TextStyle(
          color: Colors.white,
          fontSize: 24,
          fontWeight: FontWeight.bold,
          fontFamily: 'monospace',
        ),
      ),
    );
  }

  Widget _buildCompactHealthBar(
    int health,
    Color color,
    String label,
    bool isTop,
  ) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        if (!isTop)
          Text(
            label,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),
        Container(
          width: 200,
          height: 12,
          decoration: BoxDecoration(
            color: Colors.black54,
            borderRadius: BorderRadius.circular(6),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: health / 100,
              backgroundColor: Colors.transparent,
              valueColor: AlwaysStoppedAnimation<Color>(color),
            ),
          ),
        ),
        if (isTop)
          Text(
            label,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),
      ],
    );
  }

  Widget _buildGameLayer() {
    return Stack(
      children: [
        // Bullets
        ..._logic.bullets.map(
          (b) => Positioned(
            left: b.position.dx - 4,
            top: b.position.dy - 4,
            child: Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: b.isPlayer1 ? Colors.cyanAccent : Colors.pinkAccent,
                boxShadow: [
                  BoxShadow(
                    color: (b.isPlayer1 ? Colors.cyanAccent : Colors.pinkAccent)
                        .withOpacity(0.5),
                    blurRadius: 4,
                  ),
                ],
              ),
            ),
          ),
        ),

        // PowerUps
        ..._logic.powerUps.map(
          (pu) => Positioned(
            left: pu.position.dx - 15,
            top: pu.position.dy - 15,
            child: _buildPowerUpItem(pu),
          ),
        ),

        // Particles
        ..._logic.particles.map(
          (p) => Positioned(
            left: p.position.dx,
            top: p.position.dy,
            child: Opacity(
              opacity: p.life,
              child: Container(
                width: p.size,
                height: p.size,
                decoration: BoxDecoration(
                  color: p.color,
                  shape: BoxShape.circle,
                ),
              ),
            ),
          ),
        ),

        // Ships
        Positioned(
          left: _logic.player1Position.dx - 20,
          top: _logic.player1Position.dy - 20,
          child: _buildShipItem(
            Colors.cyanAccent,
            _logic.player1Rotation,
            _logic.player1.hasShield,
          ),
        ),
        Positioned(
          left: _logic.player2Position.dx - 20,
          top: _logic.player2Position.dy - 20,
          child: _buildShipItem(
            Colors.pinkAccent,
            _logic.player2Rotation,
            _logic.player2.hasShield,
          ),
        ),
      ],
    );
  }

  Widget _buildShipItem(Color color, double rotation, bool hasShield) {
    return Transform.rotate(
      angle: rotation + math.pi / 2, // Adjust rocket icon orientation
      child: Stack(
        alignment: Alignment.center,
        children: [
          if (hasShield)
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: Colors.blueAccent.withOpacity(0.5),
                  width: 2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.blueAccent.withOpacity(0.2),
                    blurRadius: 10,
                  ),
                ],
              ),
            ),
          Icon(Icons.rocket_launch, color: color, size: 40),
        ],
      ),
    );
  }

  Widget _buildPowerUpItem(PowerUp pu) {
    IconData icon;
    Color color;
    switch (pu.type) {
      case PowerUpType.shield:
        icon = Icons.shield;
        color = Colors.blueAccent;
        break;
      case PowerUpType.rapidFire:
        icon = Icons.flash_on;
        color = Colors.yellowAccent;
        break;
      case PowerUpType.speedBoost:
        icon = Icons.speed;
        color = Colors.greenAccent;
        break;
      case PowerUpType.spreadShot:
        icon = Icons.grain;
        color = Colors.orangeAccent;
        break;
    }
    return Container(
      width: 30,
      height: 30,
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        shape: BoxShape.circle,
        border: Border.all(color: color, width: 2),
      ),
      child: Icon(icon, color: color, size: 18),
    );
  }

  Widget _buildControls() {
    return Stack(
      children: [
        // P1 Controls
        Positioned(
          left: 20,
          bottom: 40,
          child: _buildJoystick(
            (val) => setState(() => _p1MoveJoystick = val),
            Colors.cyanAccent,
          ),
        ),
        Positioned(
          right: 20,
          bottom: 40,
          child: _buildFireButton(
            () => _logic.firePlayer1(),
            Colors.cyanAccent,
          ),
        ),

        // P2 Controls
        Positioned(
          right: 20,
          top: 40,
          child: Transform.rotate(
            angle: math.pi,
            child: _buildJoystick(
              (val) => setState(() => _p2MoveJoystick = val),
              Colors.pinkAccent,
            ),
          ),
        ),
        Positioned(
          left: 20,
          top: 40,
          child: Transform.rotate(
            angle: math.pi,
            child: _buildFireButton(
              () => _logic.firePlayer2(),
              Colors.pinkAccent,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildJoystick(Function(Offset) onUpdate, Color color) {
    return GestureDetector(
      onPanUpdate: (details) {
        final center = const Offset(60, 60);
        final delta = details.localPosition - center;
        final normalized = delta / 60.0;
        onUpdate(
          delta.distance > 60 ? normalized * (60 / delta.distance) : normalized,
        );
      },
      onPanEnd: (_) => onUpdate(Offset.zero),
      child: Container(
        width: 120,
        height: 120,
        decoration: BoxDecoration(
          color: color.withOpacity(0.05),
          shape: BoxShape.circle,
          border: Border.all(color: color.withOpacity(0.2)),
        ),
        child: Center(
          child: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: color.withOpacity(0.4),
              shape: BoxShape.circle,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFireButton(VoidCallback onFire, Color color) {
    return GestureDetector(
      onTap: () {
        _soundService?.playShootSound('sounds/space_shoot.mp3'); // Play shoot sound with instant restart
        onFire();
      },
      child: Container(
        width: 80,
        height: 80,
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          shape: BoxShape.circle,
          border: Border.all(color: color, width: 3),
          boxShadow: [BoxShadow(color: color.withOpacity(0.2), blurRadius: 15)],
        ),
        child: const Icon(Icons.ads_click, color: Colors.white, size: 36),
      ),
    );
  }
}

class StarsBackgroundPainter extends CustomPainter {
  final List<Offset> stars = List.generate(
    80,
    (index) => Offset(math.Random().nextDouble(), math.Random().nextDouble()),
  );

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.white.withOpacity(0.3);
    for (var star in stars) {
      canvas.drawCircle(
        Offset(star.dx * size.width, star.dy * size.height),
        1.5,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(StarsBackgroundPainter oldDelegate) => false;
}
