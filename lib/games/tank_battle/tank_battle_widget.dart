import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'package:flutter/scheduler.dart';
import 'tank_battle_logic.dart';
import '../../ui/widgets/game_countdown.dart';
import '../../ui/widgets/game_over_dialog.dart';

class TankBattleWidget extends StatefulWidget {
  const TankBattleWidget({super.key});

  @override
  State<TankBattleWidget> createState() => _TankBattleWidgetState();
}

class _TankBattleWidgetState extends State<TankBattleWidget>
    with TickerProviderStateMixin {
  late TankBattleLogic _logic;
  Ticker? _ticker;
  bool _isCountingDown = true;
  bool _gameStarted = false;
  bool _isGameOver = false;

  Offset _p1MoveJoystick = Offset.zero;
  Offset _p2MoveJoystick = Offset.zero;

  @override
  void initState() {
    super.initState();
    _logic = TankBattleLogic();
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

      final dt = 0.016;
      setState(() {
        _logic.handlePlayer1Movement(_p1MoveJoystick, dt);
        _logic.handlePlayer2Movement(
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
        gameId: 'tank_battle',
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
      _logic = TankBattleLogic();
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
      backgroundColor: const Color(0xFF121212),
      body: LayoutBuilder(
        builder: (context, constraints) {
          _logic.screenSize = Size(constraints.maxWidth, constraints.maxHeight);

          // Apply screen shake
          double shakeX =
              (math.Random().nextDouble() - 0.5) * _logic.screenShake;
          double shakeY =
              (math.Random().nextDouble() - 0.5) * _logic.screenShake;

          return Transform.translate(
            offset: Offset(shakeX, shakeY),
            child: Stack(
              children: [
                // Background
                _buildBattlefield(),

                // Game Layer
                if (!_isCountingDown) _buildGameLayer(),

                // HUD
                if (_gameStarted) _buildHUD(),

                // Controls
                if (_gameStarted && !_isGameOver) _buildControls(),

                // Countdown
                if (_isCountingDown)
                  Container(
                    color: Colors.black87,
                    child: GameCountdown(onFinished: _onCountdownFinished),
                  ),

                // Back
                if (!_gameStarted)
                  Positioned(
                    top: 40,
                    left: 20,
                    child: IconButton(
                      icon: const Icon(
                        Icons.arrow_back_ios,
                        color: Colors.white,
                      ),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildBattlefield() {
    return CustomPaint(painter: BattlefieldPainter(), size: Size.infinite);
  }

  Widget _buildHUD() {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        child: Column(
          children: [
            _buildHealthBar(_logic.player2Health, Colors.redAccent, "P2", true),
            const SizedBox(height: 10),
            _buildTimer(),
            const Spacer(),
            _buildHealthBar(
              _logic.player1Health,
              Colors.blueAccent,
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
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.black54,
        borderRadius: BorderRadius.circular(25),
        border: Border.all(color: Colors.white12),
        boxShadow: [BoxShadow(color: Colors.black45, blurRadius: 10)],
      ),
      child: Text(
        '${_logic.timeRemaining.ceil()}s',
        style: const TextStyle(
          color: Colors.white,
          fontSize: 26,
          fontWeight: FontWeight.bold,
          fontFamily: 'monospace',
        ),
      ),
    );
  }

  Widget _buildHealthBar(int health, Color color, String label, bool isTop) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        if (!isTop)
          Text(
            label,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.bold,
              fontSize: 20,
            ),
          ),
        Container(
          width: 220,
          height: 16,
          decoration: BoxDecoration(
            color: Colors.black54,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.white10),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
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
              fontSize: 20,
            ),
          ),
      ],
    );
  }

  Widget _buildGameLayer() {
    return Stack(
      children: [
        // Obstacles with Shadow
        ..._logic.obstacles.map(
          (obs) => Positioned(
            left: obs.position.dx,
            top: obs.position.dy,
            child: _buildObstacle(obs),
          ),
        ),

        // PowerUps
        ..._logic.powerUps.map(
          (pu) => Positioned(
            left: pu.position.dx - 15,
            top: pu.position.dy - 15,
            child: _buildPowerUp(pu),
          ),
        ),

        // Shells
        ..._logic.shells.map(
          (s) => Positioned(
            left: s.position.dx - 4,
            top: s.position.dy - 4,
            child: Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.orange,
                boxShadow: [
                  BoxShadow(
                    color: Colors.orange.withOpacity(0.5),
                    blurRadius: 8,
                    spreadRadius: 2,
                  ),
                ],
              ),
            ),
          ),
        ),

        // Explosions
        ..._logic.explosions.map(
          (e) => Positioned(
            left: e.position.dx - e.radius,
            top: e.position.dy - e.radius,
            child: Opacity(
              opacity: e.opacity,
              child: Container(
                width: e.radius * 2,
                height: e.radius * 2,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      Colors.white,
                      Colors.yellow,
                      Colors.orange,
                      Colors.red,
                      Colors.transparent,
                    ],
                    stops: const [0.0, 0.2, 0.5, 0.8, 1.0],
                  ),
                ),
              ),
            ),
          ),
        ),

        // Tanks (P1)
        Positioned(
          left: _logic.player1Position.dx - 25,
          top: _logic.player1Position.dy - 25,
          child: _buildTank(Colors.blueAccent, _logic.player1),
        ),

        // Tanks (P2)
        Positioned(
          left: _logic.player2Position.dx - 25,
          top: _logic.player2Position.dy - 25,
          child: _buildTank(Colors.redAccent, _logic.player2),
        ),
      ],
    );
  }

  Widget _buildTank(Color color, Tank tank) {
    return SizedBox(
      width: 50,
      height: 50,
      child: CustomPaint(
        painter: PremiumTankPainter(
          bodyRotation: tank.rotation,
          turretRotation: tank.turretRotation,
          color: color,
          hasShield: tank.hasShield,
          recoil: tank.recoilOffset,
          flash: tank.flashOpacity,
          damageFlash: tank.damageFlash,
          treadPos: tank.treadAnimation,
        ),
      ),
    );
  }

  Widget _buildObstacle(Obstacle obs) {
    return Container(
      width: obs.width,
      height: obs.height,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [const Color(0xFF4A4A4A), const Color(0xFF2A2A2A)],
        ),
        borderRadius: BorderRadius.circular(6),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.5),
            offset: const Offset(4, 4),
            blurRadius: 4,
          ),
        ],
        border: Border.all(color: Colors.white10),
      ),
      child: obs.isDestructible
          ? Center(
              child: Text(
                "${obs.health}",
                style: const TextStyle(color: Colors.white24, fontSize: 12),
              ),
            )
          : null,
    );
  }

  Widget _buildPowerUp(PowerUp pu) {
    return Container(
      width: 30,
      height: 30,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white10,
        boxShadow: [
          BoxShadow(color: Colors.cyanAccent.withOpacity(0.3), blurRadius: 10),
        ],
        border: Border.all(color: Colors.cyanAccent, width: 2),
      ),
      child: const Icon(Icons.bolt, color: Colors.cyanAccent, size: 20),
    );
  }

  Widget _buildControls() {
    return Stack(
      children: [
        // P1
        Positioned(
          left: 20,
          bottom: 40,
          child: _buildJoystick(
            _p1MoveJoystick,
            (val) => setState(() => _p1MoveJoystick = val),
            Colors.blueAccent,
          ),
        ),
        Positioned(
          right: 20,
          bottom: 40,
          child: _buildTurretControls(
            () => _logic.firePlayer1(),
            (d) => _logic.rotatePlayer1Turret(d),
            Colors.blueAccent,
          ),
        ),

        // P2
        Positioned(
          right: 20,
          top: 40,
          child: Transform.rotate(
            angle: math.pi,
            child: _buildJoystick(
              _p2MoveJoystick,
              (val) => setState(() => _p2MoveJoystick = val),
              Colors.redAccent,
            ),
          ),
        ),
        Positioned(
          left: 20,
          top: 40,
          child: Transform.rotate(
            angle: math.pi,
            child: _buildTurretControls(
              () => _logic.firePlayer2(),
              (d) => _logic.rotatePlayer2Turret(d),
              Colors.redAccent,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildJoystick(
    Offset currentValue,
    Function(Offset) onUpdate,
    Color color,
  ) {
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
          child: Transform.translate(
            offset: currentValue * 30, // Offset the nub
            child: Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  colors: [color.withOpacity(0.4), color.withOpacity(0.2)],
                ),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(color: color.withOpacity(0.3), blurRadius: 10),
                ],
                border: Border.all(color: color.withOpacity(0.5), width: 2),
              ),
              child: Center(
                child: Container(
                  width: 25,
                  height: 25,
                  decoration: BoxDecoration(
                    color: Colors.white12,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTurretControls(
    VoidCallback onFire,
    Function(double) onRotate,
    Color color,
  ) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            _buildSmallBtn(Icons.rotate_left, () => onRotate(-0.15), color),
            const SizedBox(width: 8),
            _buildSmallBtn(Icons.rotate_right, () => onRotate(0.15), color),
          ],
        ),
        const SizedBox(height: 12),
        GestureDetector(
          onTap: onFire,
          child: Container(
            width: 85,
            height: 85,
            decoration: BoxDecoration(
              gradient: RadialGradient(
                colors: [color.withOpacity(0.3), color.withOpacity(0.1)],
              ),
              shape: BoxShape.circle,
              border: Border.all(color: color, width: 3),
              boxShadow: [
                BoxShadow(color: color.withOpacity(0.2), blurRadius: 15),
              ],
            ),
            child: const Icon(Icons.ads_click, color: Colors.white, size: 36),
          ),
        ),
      ],
    );
  }

  Widget _buildSmallBtn(IconData icon, VoidCallback onTap, Color color) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          shape: BoxShape.circle,
          border: Border.all(color: color.withOpacity(0.5)),
        ),
        child: Icon(icon, color: Colors.white, size: 24),
      ),
    );
  }
}

class BattlefieldPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final bgPaint = Paint()..color = const Color(0xFF1E1E1E);
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), bgPaint);

    final gridPaint = Paint()
      ..color = Colors.white.withOpacity(0.03)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    const spacing = 50.0;
    for (double i = 0; i < size.width; i += spacing) {
      canvas.drawLine(Offset(i, 0), Offset(i, size.height), gridPaint);
    }
    for (double i = 0; i < size.height; i += spacing) {
      canvas.drawLine(Offset(0, i), Offset(size.width, i), gridPaint);
    }

    // Aesthetic glow
    final glowPaint = Paint()
      ..shader =
          RadialGradient(
            colors: [Colors.blue.withOpacity(0.05), Colors.transparent],
          ).createShader(
            Rect.fromCenter(
              center: Offset(size.width / 2, size.height / 2),
              width: size.width,
              height: size.height,
            ),
          );
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), glowPaint);
  }

  @override
  bool shouldRepaint(BattlefieldPainter oldDelegate) => false;
}

class PremiumTankPainter extends CustomPainter {
  final double bodyRotation,
      turretRotation,
      recoil,
      flash,
      damageFlash,
      treadPos;
  final Color color;
  final bool hasShield;

  PremiumTankPainter({
    required this.bodyRotation,
    required this.turretRotation,
    required this.color,
    required this.hasShield,
    required this.recoil,
    required this.flash,
    required this.damageFlash,
    required this.treadPos,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);

    // Draw Shadow
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: center + const Offset(4, 4),
          width: 40,
          height: 35,
        ),
        const Radius.circular(4),
      ),
      Paint()..color = Colors.black45,
    );

    // Body
    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(bodyRotation);

    final mainPaint = Paint()
      ..color = Color.lerp(color, Colors.white, damageFlash)!;

    // Tracks
    final trackPaint = Paint()..color = Colors.black87;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(-22, -18, 44, 10),
        const Radius.circular(2),
      ),
      trackPaint,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(-22, 8, 44, 10),
        const Radius.circular(2),
      ),
      trackPaint,
    );

    // Tread animations
    final treadPaint = Paint()
      ..color = Colors.white10
      ..strokeWidth = 2;
    for (int i = 0; i < 5; i++) {
      double x = -20 + ((i + treadPos) * 10) % 40;
      canvas.drawLine(Offset(x, -18), Offset(x, -8), treadPaint);
      canvas.drawLine(Offset(x, 8), Offset(x, 18), treadPaint);
    }

    // Main Body
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(-20, -12, 40, 24),
        const Radius.circular(4),
      ),
      mainPaint,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(-15, -10, 30, 20),
        const Radius.circular(2),
      ),
      Paint()..color = Colors.black26,
    );

    canvas.restore();

    // Turret (Higher Z)
    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(turretRotation);

    // Barrel with Recoil (Logically pointing Right at 0 rotation)
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(2 - recoil, -4, 26, 8),
        const Radius.circular(2),
      ),
      mainPaint,
    );

    // Muzzle Flash
    if (flash > 0) {
      canvas.drawCircle(
        const Offset(32, 0),
        10 * flash,
        Paint()
          ..shader =
              RadialGradient(
                colors: [Colors.white, Colors.orange.withOpacity(0)],
              ).createShader(
                Rect.fromCircle(center: const Offset(32, 0), radius: 10),
              ),
      );
    }

    // Turret Base
    canvas.drawCircle(Offset.zero, 12, mainPaint);
    canvas.drawCircle(Offset.zero, 8, Paint()..color = Colors.black26);

    canvas.restore();

    if (hasShield) {
      canvas.drawCircle(
        center,
        35,
        Paint()
          ..color = Colors.cyanAccent.withOpacity(0.2)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2,
      );
    }
  }

  @override
  bool shouldRepaint(PremiumTankPainter oldDelegate) => true;
}
