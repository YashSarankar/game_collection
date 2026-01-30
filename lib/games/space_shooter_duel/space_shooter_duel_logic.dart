import 'package:flutter/material.dart';
import 'dart:math' as math;

enum PowerUpType { rapidFire, shield, speedBoost, spreadShot }

class Ship {
  Offset position;
  Offset velocity;
  int health;
  double rotation;
  bool hasShield;
  bool hasRapidFire;
  bool hasSpeedBoost;
  bool hasSpreadShot;
  int powerUpTimer;

  Ship({
    required this.position,
    this.velocity = Offset.zero,
    this.health = 100,
    this.rotation = 0,
    this.hasShield = false,
    this.hasRapidFire = false,
    this.hasSpeedBoost = false,
    this.hasSpreadShot = false,
    this.powerUpTimer = 0,
  });
}

class Bullet {
  Offset position;
  Offset direction;
  bool isPlayer1;
  double speed;

  Bullet({
    required this.position,
    required this.direction,
    required this.isPlayer1,
    this.speed = 8.0,
  });
}

class PowerUp {
  Offset position;
  PowerUpType type;
  int lifetime;

  PowerUp({
    required this.position,
    required this.type,
    this.lifetime = 300, // 5 seconds at 60fps
  });
}

class ParticleEffect {
  Offset position;
  Offset velocity;
  Color color;
  double life;
  double size;

  ParticleEffect({
    required this.position,
    required this.velocity,
    required this.color,
    this.life = 1.0,
    this.size = 3.0,
  });

  void update(double dt) {
    position += velocity * dt;
    life -= 1.5 * dt;
  }
}

class SpaceShooterDuelLogic {
  late Ship player1;
  late Ship player2;
  List<Bullet> bullets = [];
  List<PowerUp> powerUps = [];
  List<ParticleEffect> particles = [];

  double timeRemaining = 90.0; // 90 seconds match
  int _lastFireFrame1 = 0;
  int _lastFireFrame2 = 0;
  int _frameCount = 0;
  final int _fireDelay = 12; // ~200ms at 60fps
  final int _rapidFireDelay = 6; // ~100ms at 60fps

  final int maxHealth = 100;
  final double shipSpeed = 250.0; // Units per second
  final double boostedSpeed = 400.0;

  final math.Random _random = math.Random();
  double _powerUpSpawnTimer = 0;
  final double _powerUpSpawnInterval = 4.0; // 4 seconds

  // Screen bounds
  Size screenSize = const Size(400, 800);

  SpaceShooterDuelLogic() {
    _initializeGame();
  }

  void _initializeGame() {
    // Player 1 starts at bottom
    player1 = Ship(
      position: const Offset(200, 600),
      rotation: -math.pi / 2, // Pointing up
    );

    // Player 2 starts at top
    player2 = Ship(
      position: const Offset(200, 200),
      rotation: math.pi / 2, // Pointing down
    );
  }

  void update(double dt) {
    _frameCount++;
    if (timeRemaining > 0) {
      timeRemaining -= dt;
    }

    // Update particles
    for (var p in particles) {
      p.update(dt);
    }
    particles.removeWhere((p) => p.life <= 0);

    // Update bullets
    _updateBullets(dt);

    // Update power-ups
    _updatePowerUps();

    // Check collisions
    _checkCollisions();

    // Spawn power-ups
    _spawnPowerUps(dt);

    // Update power-up timers
    _updateShipPowerUps();
  }

  void _updateBullets(double dt) {
    bullets.removeWhere((bullet) {
      bullet.position += bullet.direction * (bullet.speed * 60 * dt);

      // Remove if out of bounds
      return bullet.position.dx < 0 ||
          bullet.position.dx > screenSize.width ||
          bullet.position.dy < 0 ||
          bullet.position.dy > screenSize.height;
    });
  }

  void _updatePowerUps() {
    powerUps.removeWhere((powerUp) {
      powerUp.lifetime--;
      return powerUp.lifetime <= 0;
    });
  }

  void _checkCollisions() {
    // Check bullet-ship collisions
    bullets.removeWhere((bullet) {
      // Check collision with player 1
      if (!bullet.isPlayer1) {
        final distance = (bullet.position - player1.position).distance;
        if (distance < 25) {
          if (!player1.hasShield) {
            player1.health = (player1.health - 10).clamp(0, maxHealth);
          }
          _createExplosion(bullet.position, Colors.pinkAccent);
          return true;
        }
      }

      // Check collision with player 2
      if (bullet.isPlayer1) {
        final distance = (bullet.position - player2.position).distance;
        if (distance < 25) {
          if (!player2.hasShield) {
            player2.health = (player2.health - 10).clamp(0, maxHealth);
          }
          _createExplosion(bullet.position, Colors.cyanAccent);
          return true;
        }
      }

      return false;
    });

    // Check power-up collection
    powerUps.removeWhere((powerUp) {
      // Check player 1
      final dist1 = (powerUp.position - player1.position).distance;
      if (dist1 < 30) {
        _applyPowerUp(player1, powerUp.type);
        return true;
      }

      // Check player 2
      final dist2 = (powerUp.position - player2.position).distance;
      if (dist2 < 30) {
        _applyPowerUp(player2, powerUp.type);
        return true;
      }

      return false;
    });
  }

  void _createExplosion(Offset pos, Color color) {
    for (int i = 0; i < 10; i++) {
      final angle = _random.nextDouble() * 2 * math.pi;
      final speed = 50 + _random.nextDouble() * 100;
      particles.add(
        ParticleEffect(
          position: pos,
          velocity: Offset(math.cos(angle), math.sin(angle)) * speed,
          color: color,
          life: 0.5 + _random.nextDouble() * 0.5,
        ),
      );
    }
  }

  void _applyPowerUp(Ship ship, PowerUpType type) {
    switch (type) {
      case PowerUpType.rapidFire:
        ship.hasRapidFire = true;
        ship.powerUpTimer = 300; // 5 seconds
        break;
      case PowerUpType.shield:
        ship.hasShield = true;
        ship.powerUpTimer = 300;
        break;
      case PowerUpType.speedBoost:
        ship.hasSpeedBoost = true;
        ship.powerUpTimer = 300;
        break;
      case PowerUpType.spreadShot:
        ship.hasSpreadShot = true;
        ship.powerUpTimer = 300;
        break;
    }
  }

  void _updateShipPowerUps() {
    // Player 1
    if (player1.powerUpTimer > 0) {
      player1.powerUpTimer--;
      if (player1.powerUpTimer == 0) {
        player1.hasRapidFire = false;
        player1.hasShield = false;
        player1.hasSpeedBoost = false;
        player1.hasSpreadShot = false;
      }
    }

    // Player 2
    if (player2.powerUpTimer > 0) {
      player2.powerUpTimer--;
      if (player2.powerUpTimer == 0) {
        player2.hasRapidFire = false;
        player2.hasShield = false;
        player2.hasSpeedBoost = false;
        player2.hasSpreadShot = false;
      }
    }
  }

  void _spawnPowerUps(double dt) {
    _powerUpSpawnTimer += dt;
    if (_powerUpSpawnTimer >= _powerUpSpawnInterval) {
      _powerUpSpawnTimer = 0;

      // Random position in the middle area
      final x = 50 + _random.nextDouble() * (screenSize.width - 100);
      final y =
          screenSize.height * 0.3 +
          _random.nextDouble() * (screenSize.height * 0.4);

      // Random power-up type
      final types = PowerUpType.values;
      final type = types[_random.nextInt(types.length)];

      powerUps.add(PowerUp(position: Offset(x, y), type: type));
    }
  }

  void handleJoystickMovePlayer1(Offset joystickValue, double dt) {
    if (joystickValue.distance < 0.1) return;

    final speed = (player1.hasSpeedBoost ? boostedSpeed : shipSpeed) * dt;
    final direction = joystickValue / joystickValue.distance;
    final newPos = player1.position + direction * speed;

    player1.position = Offset(
      newPos.dx.clamp(20, screenSize.width - 20),
      newPos.dy.clamp(screenSize.height / 2, screenSize.height - 20),
    );

    // Update rotation towards movement
    player1.rotation = math.atan2(direction.dy, direction.dx);
  }

  void handleJoystickMovePlayer2(Offset joystickValue, double dt) {
    if (joystickValue.distance < 0.1) return;

    final speed = (player2.hasSpeedBoost ? boostedSpeed : shipSpeed) * dt;
    final direction = joystickValue / joystickValue.distance;
    final newPos = player2.position + direction * speed;

    player2.position = Offset(
      newPos.dx.clamp(20, screenSize.width - 20),
      newPos.dy.clamp(20, screenSize.height / 2),
    );

    // Update rotation towards movement
    player2.rotation = math.atan2(direction.dy, direction.dx);
  }

  void firePlayer1() {
    final delay = player1.hasRapidFire ? _rapidFireDelay : _fireDelay;

    if (_frameCount - _lastFireFrame1 >= delay) {
      _lastFireFrame1 = _frameCount;

      if (player1.hasSpreadShot) {
        // Fire 3 bullets in a spread pattern
        for (int i = -1; i <= 1; i++) {
          final angle = player1.rotation + (i * 0.3);
          final direction = Offset(math.cos(angle), math.sin(angle));

          bullets.add(
            Bullet(
              position: player1.position + direction * 25,
              direction: direction,
              isPlayer1: true,
            ),
          );
        }
      } else {
        // Fire single bullet
        final direction = Offset(
          math.cos(player1.rotation),
          math.sin(player1.rotation),
        );

        bullets.add(
          Bullet(
            position: player1.position + direction * 25,
            direction: direction,
            isPlayer1: true,
          ),
        );
      }
    }
  }

  void firePlayer2() {
    final delay = player2.hasRapidFire ? _rapidFireDelay : _fireDelay;

    if (_frameCount - _lastFireFrame2 >= delay) {
      _lastFireFrame2 = _frameCount;

      if (player2.hasSpreadShot) {
        // Fire 3 bullets in a spread pattern
        for (int i = -1; i <= 1; i++) {
          final angle = player2.rotation + (i * 0.3);
          final direction = Offset(math.cos(angle), math.sin(angle));

          bullets.add(
            Bullet(
              position: player2.position + direction * 25,
              direction: direction,
              isPlayer1: false,
            ),
          );
        }
      } else {
        // Fire single bullet
        final direction = Offset(
          math.cos(player2.rotation),
          math.sin(player2.rotation),
        );

        bullets.add(
          Bullet(
            position: player2.position + direction * 25,
            direction: direction,
            isPlayer1: false,
          ),
        );
      }
    }
  }

  int get player1Health => player1.health;
  int get player2Health => player2.health;
  Offset get player1Position => player1.position;
  Offset get player2Position => player2.position;
  double get player1Rotation => player1.rotation;
  double get player2Rotation => player2.rotation;
}
