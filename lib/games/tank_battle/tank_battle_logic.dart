import 'package:flutter/material.dart';
import 'dart:math' as math;

enum PowerUpType { doubleDamage, rapidFire, shield, speedBoost }

// Sound callbacks
typedef SoundCallback = void Function();

class Tank {
  Offset position;
  double rotation; // Tank body rotation
  double turretRotation; // Turret rotation (independent)
  int health;
  double speed;
  bool hasShield;
  bool hasDoubleDamage;
  bool hasRapidFire;
  bool hasSpeedBoost;
  int powerUpTimer;

  // Visual effects state
  double recoilOffset = 0.0;
  double flashOpacity = 0.0;
  double damageFlash = 0.0;
  double treadAnimation = 0.0;

  Tank({
    required this.position,
    this.rotation = 0,
    this.turretRotation = 0,
    this.health = 100,
    this.speed = 3.0,
    this.hasShield = false,
    this.hasDoubleDamage = false,
    this.hasRapidFire = false,
    this.hasSpeedBoost = false,
    this.powerUpTimer = 0,
  });
}

class Shell {
  Offset position;
  Offset direction;
  bool isPlayer1;
  int damage;
  double speed;

  Shell({
    required this.position,
    required this.direction,
    required this.isPlayer1,
    this.damage = 20,
    this.speed = 6.0,
  });
}

class Obstacle {
  Offset position;
  double width;
  double height;
  bool isDestructible;
  int health;

  Obstacle({
    required this.position,
    this.width = 40,
    this.height = 40,
    this.isDestructible = true,
    this.health = 50,
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

class ExplosionEffect {
  Offset position;
  double radius;
  double maxRadius;
  double opacity;
  bool isFinished = false;

  ExplosionEffect({
    required this.position,
    this.radius = 0,
    this.maxRadius = 40,
    this.opacity = 1.0,
  });

  void update(double dt) {
    radius += 100 * dt;
    opacity -= 2 * dt;
    if (opacity <= 0) {
      isFinished = true;
    }
  }
}

class TankBattleLogic {
  late Tank player1;
  late Tank player2;
  List<Shell> shells = [];
  List<Obstacle> obstacles = [];
  List<PowerUp> powerUps = [];
  List<ExplosionEffect> explosions = [];

  // Screen shake state
  double screenShake = 0.0;

  // Sound callback - only for shooting (movement and rotation removed due to performance issues)
  SoundCallback? onTankShoot;

  double timeRemaining = 120.0; // 2 minutes match
  int _lastFireFrame1 = 0;
  int _lastFireFrame2 = 0;
  int _frameCount = 0;
  final int _fireDelay = 30; // ~500ms at 60fps
  final int _rapidFireDelay = 15; // ~250ms at 60fps

  final int maxHealth = 100;
  final double tankSpeed = 150.0; // Units per second
  final double boostedSpeed = 250.0;
  final double tankSize = 35.0;
  final double rotationSpeed = 3.0; // Radians per second

  final math.Random _random = math.Random();
  double _powerUpSpawnTimer = 0;
  final double _powerUpSpawnInterval = 5.0; // 5 seconds

  // Screen bounds
  Size screenSize = const Size(400, 800);

  TankBattleLogic() {
    _initializeGame();
  }

  void _initializeGame() {
    // Player 1 starts at bottom-left
    player1 = Tank(
      position: const Offset(80, 700),
      rotation: -math.pi / 2, // Facing up
      turretRotation: -math.pi / 2,
    );

    // Player 2 starts at top-right
    player2 = Tank(
      position: const Offset(320, 100),
      rotation: math.pi / 2, // Facing down
      turretRotation: math.pi / 2,
    );

    _generateObstacles();
  }

  void _generateObstacles() {
    obstacles.clear();
    // Create some obstacles in the middle area
    final centerX = screenSize.width / 2;
    final centerY = screenSize.height / 2;

    // Center obstacles
    obstacles.add(
      Obstacle(
        position: Offset(centerX - 60, centerY - 60),
        width: 50,
        height: 50,
      ),
    );

    obstacles.add(
      Obstacle(
        position: Offset(centerX + 10, centerY - 60),
        width: 50,
        height: 50,
      ),
    );

    obstacles.add(
      Obstacle(
        position: Offset(centerX - 60, centerY + 10),
        width: 50,
        height: 50,
      ),
    );

    obstacles.add(
      Obstacle(
        position: Offset(centerX + 10, centerY + 10),
        width: 50,
        height: 50,
      ),
    );

    // Side obstacles
    obstacles.add(
      Obstacle(position: Offset(50, centerY - 25), width: 40, height: 80),
    );

    obstacles.add(
      Obstacle(
        position: Offset(screenSize.width - 90, centerY - 25),
        width: 40,
        height: 80,
      ),
    );
  }

  void update(double dt) {
    _frameCount++;
    if (timeRemaining > 0) {
      timeRemaining = (timeRemaining - dt).clamp(0.0, 120.0);
    }

    // Update shells
    _updateShells(dt);

    // Update power-ups
    _updatePowerUps(dt);

    // Update explosions
    for (var explosion in explosions) {
      explosion.update(dt);
    }
    explosions.removeWhere((e) => e.isFinished);

    // Check collisions
    _checkCollisions();

    // Spawn power-ups
    _spawnPowerUps(dt);

    // Update power-up timers
    _updateTankPowerUps(dt);

    // Update visual states
    _updateVisualStates(dt);
  }

  void _updateVisualStates(double dt) {
    if (screenShake > 0) {
      screenShake = (screenShake - dt * 20).clamp(0.0, 10.0);
    }

    _updateTankVisuals(player1, dt);
    _updateTankVisuals(player2, dt);
  }

  void _updateTankVisuals(Tank tank, double dt) {
    if (tank.recoilOffset > 0) {
      tank.recoilOffset = (tank.recoilOffset - dt * 40).clamp(0.0, 10.0);
    }
    if (tank.flashOpacity > 0) {
      tank.flashOpacity = (tank.flashOpacity - dt * 5).clamp(0.0, 1.0);
    }
    if (tank.damageFlash > 0) {
      tank.damageFlash = (tank.damageFlash - dt * 5).clamp(0.0, 1.0);
    }
  }

  void _updateShells(double dt) {
    shells.removeWhere((shell) {
      shell.position += shell.direction * (shell.speed * 60 * dt);

      // Remove if out of bounds
      if (shell.position.dx < 0 ||
          shell.position.dx > screenSize.width ||
          shell.position.dy < 0 ||
          shell.position.dy > screenSize.height) {
        return true;
      }

      // Check collision with obstacles
      for (var obstacle in obstacles) {
        if (_checkShellObstacleCollision(shell, obstacle)) {
          if (obstacle.isDestructible) {
            obstacle.health -= shell.damage;
          }
          explosions.add(
            ExplosionEffect(position: shell.position, maxRadius: 20),
          );
          return true; // Remove shell
        }
      }

      return false;
    });

    // Remove destroyed obstacles
    obstacles.removeWhere((obstacle) => obstacle.health <= 0);
  }

  bool _checkShellObstacleCollision(Shell shell, Obstacle obstacle) {
    return shell.position.dx >= obstacle.position.dx &&
        shell.position.dx <= obstacle.position.dx + obstacle.width &&
        shell.position.dy >= obstacle.position.dy &&
        shell.position.dy <= obstacle.position.dy + obstacle.height;
  }

  void _updatePowerUps(double dt) {
    powerUps.removeWhere((powerUp) {
      powerUp.lifetime--; // This could also be time based
      return powerUp.lifetime <= 0;
    });
  }

  void _checkCollisions() {
    // Check shell-tank collisions
    shells.removeWhere((shell) {
      // Check collision with player 1
      if (!shell.isPlayer1) {
        final distance = (shell.position - player1.position).distance;
        if (distance < tankSize / 2 + 5) {
          if (!player1.hasShield) {
            player1.health = (player1.health - shell.damage).clamp(
              0,
              maxHealth,
            );
            player1.damageFlash = 1.0;
            screenShake = 5.0;
          }
          explosions.add(
            ExplosionEffect(position: shell.position, maxRadius: 30),
          );
          return true;
        }
      }

      // Check collision with player 2
      if (shell.isPlayer1) {
        final distance = (shell.position - player2.position).distance;
        if (distance < tankSize / 2 + 5) {
          if (!player2.hasShield) {
            player2.health = (player2.health - shell.damage).clamp(
              0,
              maxHealth,
            );
            player2.damageFlash = 1.0;
            screenShake = 5.0;
          }
          explosions.add(
            ExplosionEffect(position: shell.position, maxRadius: 30),
          );
          return true;
        }
      }

      return false;
    });

    // Check power-up collection
    powerUps.removeWhere((powerUp) {
      // Check player 1
      final dist1 = (powerUp.position - player1.position).distance;
      if (dist1 < tankSize / 2 + 15) {
        _applyPowerUp(player1, powerUp.type);
        return true;
      }

      // Check player 2
      final dist2 = (powerUp.position - player2.position).distance;
      if (dist2 < tankSize / 2 + 15) {
        _applyPowerUp(player2, powerUp.type);
        return true;
      }

      return false;
    });
  }

  void _applyPowerUp(Tank tank, PowerUpType type) {
    switch (type) {
      case PowerUpType.doubleDamage:
        tank.hasDoubleDamage = true;
        tank.powerUpTimer = 300; // ~5 seconds
        break;
      case PowerUpType.rapidFire:
        tank.hasRapidFire = true;
        tank.powerUpTimer = 300;
        break;
      case PowerUpType.shield:
        tank.hasShield = true;
        tank.powerUpTimer = 300;
        break;
      case PowerUpType.speedBoost:
        tank.hasSpeedBoost = true;
        tank.powerUpTimer = 300;
        break;
    }
  }

  void _updateTankPowerUps(double dt) {
    // Player 1
    if (player1.powerUpTimer > 0) {
      player1.powerUpTimer--;
      if (player1.powerUpTimer == 0) {
        player1.hasDoubleDamage = false;
        player1.hasRapidFire = false;
        player1.hasShield = false;
        player1.hasSpeedBoost = false;
      }
    }

    // Player 2
    if (player2.powerUpTimer > 0) {
      player2.powerUpTimer--;
      if (player2.powerUpTimer == 0) {
        player2.hasDoubleDamage = false;
        player2.hasRapidFire = false;
        player2.hasShield = false;
        player2.hasSpeedBoost = false;
      }
    }
  }

  void _spawnPowerUps(double dt) {
    _powerUpSpawnTimer += dt;
    if (_powerUpSpawnTimer >= _powerUpSpawnInterval) {
      _powerUpSpawnTimer = 0;

      // Random position avoiding edges
      final x = 60 + _random.nextDouble() * (screenSize.width - 120);
      final y = 60 + _random.nextDouble() * (screenSize.height - 120);
      final position = Offset(x, y);

      // Check if position is clear of obstacles
      bool isClear = true;
      for (var obstacle in obstacles) {
        if ((position - obstacle.position).distance < 60) {
          isClear = false;
          break;
        }
      }

      if (isClear) {
        // Random power-up type
        final types = PowerUpType.values;
        final type = types[_random.nextInt(types.length)];

        powerUps.add(PowerUp(position: position, type: type));
      }
    }
  }

  void movePlayer1Forward(double dt) {
    final speed = (player1.hasSpeedBoost ? boostedSpeed : tankSpeed) * dt;
    final newPos =
        player1.position +
        Offset(
          math.cos(player1.rotation) * speed,
          math.sin(player1.rotation) * speed,
        );

    if (_isPositionValid(newPos, player1)) {
      player1.position = newPos;
    }
  }

  void movePlayer1Backward(double dt) {
    final speed = (player1.hasSpeedBoost ? boostedSpeed : tankSpeed) * dt;
    final newPos =
        player1.position -
        Offset(
          math.cos(player1.rotation) * speed,
          math.sin(player1.rotation) * speed,
        );

    if (_isPositionValid(newPos, player1)) {
      player1.position = newPos;
    }
  }

  void handlePlayer1Movement(Offset joystickValue, double dt) {
    if (joystickValue.distance < 0.1) return;

    // Movement
    final speed = (player1.hasSpeedBoost ? boostedSpeed : tankSpeed) * dt;
    final direction = joystickValue / joystickValue.distance;
    final newPos = player1.position + direction * speed;

    if (_isPositionValid(newPos, player1)) {
      player1.position = newPos;
      // Gently rotate tank body towards movement direction
      final targetRotation = math.atan2(direction.dy, direction.dx);
      _smoothRotate(player1, targetRotation, dt);
      player1.treadAnimation = (player1.treadAnimation + dt * 10) % 1.0;
      // Movement sound removed - was causing performance issues
    }
  }

  void handlePlayer2Movement(Offset joystickValue, double dt) {
    if (joystickValue.distance < 0.1) return;

    // Movement
    final speed = (player2.hasSpeedBoost ? boostedSpeed : tankSpeed) * dt;
    final direction = joystickValue / joystickValue.distance;
    final newPos = player2.position + direction * speed;

    if (_isPositionValid(newPos, player2)) {
      player2.position = newPos;
      // Gently rotate tank body towards movement direction
      final targetRotation = math.atan2(direction.dy, direction.dx);
      _smoothRotate(player2, targetRotation, dt);
      player2.treadAnimation = (player2.treadAnimation + dt * 10) % 1.0;
      // Movement sound removed - was causing performance issues
    }
  }

  void _smoothRotate(Tank tank, double targetRotation, double dt) {
    double diff = targetRotation - tank.rotation;
    while (diff > math.pi) diff -= 2 * math.pi;
    while (diff < -math.pi) diff += 2 * math.pi;

    final rotationStep = rotationSpeed * dt;
    if (diff.abs() < rotationStep) {
      tank.rotation = targetRotation;
    } else {
      tank.rotation += diff.sign * rotationStep;
    }
  }

  void rotatePlayer1Turret(double delta) {
    player1.turretRotation += delta;
    // Turret rotation sound removed - was causing performance issues
  }

  void rotatePlayer2Turret(double delta) {
    player2.turretRotation += delta;
    // Turret rotation sound removed - was causing performance issues
  }

  bool _isPositionValid(Offset position, Tank tank) {
    // Check screen bounds
    if (position.dx < tankSize / 2 ||
        position.dx > screenSize.width - tankSize / 2 ||
        position.dy < tankSize / 2 ||
        position.dy > screenSize.height - tankSize / 2) {
      return false;
    }

    // Check obstacle collisions
    for (var obstacle in obstacles) {
      final rect = Rect.fromLTWH(
        obstacle.position.dx,
        obstacle.position.dy,
        obstacle.width,
        obstacle.height,
      );
      if (rect.inflate(tankSize / 2).contains(position)) {
        return false;
      }
    }

    // Check other tank
    final otherTank = tank == player1 ? player2 : player1;
    if ((position - otherTank.position).distance < tankSize) {
      return false;
    }

    return true;
  }

  void firePlayer1() {
    final delay = player1.hasRapidFire ? _rapidFireDelay : _fireDelay;

    if (_frameCount - _lastFireFrame1 >= delay) {
      _lastFireFrame1 = _frameCount;

      final direction = Offset(
        math.cos(player1.turretRotation),
        math.sin(player1.turretRotation),
      );

      final damage = player1.hasDoubleDamage ? 40 : 20;

      shells.add(
        Shell(
          position: player1.position + direction * 28,
          direction: direction,
          isPlayer1: true,
          damage: damage,
        ),
      );

      player1.recoilOffset = 8.0;
      player1.flashOpacity = 1.0;
      screenShake = 3.0;
      onTankShoot?.call(); // Play shooting sound
    }
  }

  void firePlayer2() {
    final delay = player2.hasRapidFire ? _rapidFireDelay : _fireDelay;

    if (_frameCount - _lastFireFrame2 >= delay) {
      _lastFireFrame2 = _frameCount;

      final direction = Offset(
        math.cos(player2.turretRotation),
        math.sin(player2.turretRotation),
      );

      final damage = player2.hasDoubleDamage ? 40 : 20;

      shells.add(
        Shell(
          position: player2.position + direction * 28,
          direction: direction,
          isPlayer1: false,
          damage: damage,
        ),
      );

      player2.recoilOffset = 8.0;
      player2.flashOpacity = 1.0;
      screenShake = 3.0;
      onTankShoot?.call(); // Play shooting sound
    }
  }

  int get player1Health => player1.health;
  int get player2Health => player2.health;
  Offset get player1Position => player1.position;
  Offset get player2Position => player2.position;
  double get player1Rotation => player1.rotation;
  double get player2Rotation => player2.rotation;
  double get player1TurretRotation => player1.turretRotation;
  double get player2TurretRotation => player2.turretRotation;
}
