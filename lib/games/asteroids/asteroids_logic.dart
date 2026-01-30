import 'dart:math' as math;
import 'package:flutter/material.dart';

enum AsteroidSize { small, medium, large }

class Asteroid {
  Offset position;
  Offset velocity;
  AsteroidSize size;
  double rotation;
  double rotationSpeed;
  late double radius;
  late List<Offset> points;

  Asteroid({
    required this.position,
    required this.velocity,
    required this.size,
    required this.rotation,
    required this.rotationSpeed,
  }) {
    final random = math.Random();
    switch (size) {
      case AsteroidSize.small:
        radius = 12;
        break;
      case AsteroidSize.medium:
        radius = 25;
        break;
      case AsteroidSize.large:
        radius = 45;
        break;
    }

    // Generate random jagged shape
    int numPoints = 8 + random.nextInt(5);
    points = [];
    for (int i = 0; i < numPoints; i++) {
      double angle = (i / numPoints) * 2 * math.pi;
      double r = radius * (0.8 + random.nextDouble() * 0.4);
      points.add(Offset(math.cos(angle) * r, math.sin(angle) * r));
    }
  }
}

class Bullet {
  Offset position;
  Offset velocity;
  double timeToLive;

  Bullet({
    required this.position,
    required this.velocity,
    this.timeToLive = 2.0,
  });
}

class Spaceship {
  Offset position;
  Offset velocity;
  double rotation;
  double radius = 15;
  bool isThrusting = false;

  Spaceship({
    required this.position,
    this.velocity = Offset.zero,
    this.rotation = -math.pi / 2, // Always point up for vertical scroller
  });
}

class Particle {
  Offset position;
  Offset velocity;
  double life;
  Color color;

  Particle({
    required this.position,
    required this.velocity,
    required this.life,
    required this.color,
  });
}

class AsteroidsLogic extends ChangeNotifier {
  Spaceship? ship;
  List<Asteroid> asteroids = [];
  List<Bullet> bullets = [];
  List<Particle> particles = [];

  int score = 0;
  int lives = 3;
  int level = 1;
  bool isGameOver = false;
  bool isPaused = false;

  Size screenSize = Size.zero;
  final math.Random _random = math.Random();

  // Settings
  final double thrustAcceleration = 400.0;
  final double rotationSpeed = 5.0;
  final double maxShipSpeed = 500.0;
  final double bulletSpeed = 600.0;
  final double fireRate = 0.2;
  double _lastFireTime = 0;
  double _invulnerabilityTimer = 0;
  double screenShake = 0;
  double bgOffset = 0;

  double thrustPower = 0; // For visual feedback

  AsteroidsLogic();

  void init(Size size) {
    screenSize = size;
    _resetGame();
  }

  void _resetGame() {
    ship = Spaceship(
      position: Offset(screenSize.width / 2, screenSize.height * 0.8),
    );
    asteroids.clear();
    bullets.clear();
    particles.clear();
    score = 0;
    lives = 3;
    level = 1;
    bgOffset = 0;
    _lastFireTime = 0;
    isGameOver = false;
    _invulnerabilityTimer = 3.0; // 3 seconds of safety at start
    _spawnAsteroids();
    notifyListeners();
  }

  void _spawnAsteroids() {
    int count = 5 + (level * 2); // Start with more asteroids
    for (int i = 0; i < count; i++) {
      _spawnLargeAsteroid();
    }
  }

  void _spawnLargeAsteroid() {
    // Spawn from top
    Offset pos = Offset(
      _random.nextDouble() * screenSize.width,
      -50 - _random.nextDouble() * 100,
    );

    double angle =
        (math.pi / 2) + (_random.nextDouble() - 0.5) * 0.5; // Mostly downwards
    double speed = 150.0 + _random.nextDouble() * 100.0 + (level * 20);

    asteroids.add(
      Asteroid(
        position: pos,
        velocity: Offset(math.cos(angle) * speed, math.sin(angle) * speed),
        size: AsteroidSize.large,
        rotation: _random.nextDouble() * 2 * math.pi,
        rotationSpeed: (_random.nextDouble() - 0.5) * 2,
      ),
    );
  }

  void update(
    double dt, {
    Offset moveVector = Offset.zero,
    double currentTime = 0,
  }) {
    if (isGameOver || isPaused || screenSize == Size.zero) return;

    if (ship != null) {
      // Direct movement based on moveVector (Joystick/Touch)
      if (moveVector != Offset.zero) {
        ship!.isThrusting = true;
        thrustPower = (thrustPower + dt * 5).clamp(0.0, 1.0);

        // Apply velocity directly
        ship!.velocity = moveVector * maxShipSpeed;

        // Add particles for thrust
        if (_random.nextDouble() > 0.4) {
          _addThrustParticles();
        }
      } else {
        ship!.isThrusting = false;
        thrustPower = (thrustPower - dt * 2).clamp(0.0, 1.0);
        // Decelerate naturally
        ship!.velocity *= 0.9;
      }

      // Update position with velocity
      ship!.position += ship!.velocity * dt;

      // Horizontal wrap, vertical clamping
      // Clamp position to screen bounds (No wrapping for the ship)
      double x = ship!.position.dx.clamp(
        ship!.radius,
        screenSize.width - ship!.radius,
      );
      double y = ship!.position.dy.clamp(
        screenSize.height * 0.1,
        screenSize.height * 0.95,
      );
      ship!.position = Offset(x, y);

      if (_invulnerabilityTimer > 0) {
        _invulnerabilityTimer -= dt;
      }

      // ALWAYS SHOOT
      shoot(currentTime);
    }

    // Update Bullets
    for (int i = bullets.length - 1; i >= 0; i--) {
      bullets[i].position += bullets[i].velocity * dt;
      // Removed wrapping: bullets should not wrap from top to bottom
      bullets[i].timeToLive -= dt;
      if (bullets[i].timeToLive <= 0) {
        bullets.removeAt(i);
      }
    }

    // Update Asteroids
    for (int i = asteroids.length - 1; i >= 0; i--) {
      var asteroid = asteroids[i];
      asteroid.position += asteroid.velocity * dt;
      asteroid.rotation += asteroid.rotationSpeed * dt;

      // Horizontal wrap
      if (asteroid.position.dx < -100)
        asteroid.position = Offset(
          screenSize.width + 100,
          asteroid.position.dy,
        );
      if (asteroid.position.dx > screenSize.width + 100)
        asteroid.position = Offset(-100, asteroid.position.dy);

      // Remove if off bottom OR top (prevents leaking out of play area)
      if (asteroid.position.dy > screenSize.height + 150) {
        asteroids.removeAt(i);
        _spawnLargeAsteroid();
      } else if (asteroid.position.dy < -300) {
        asteroids.removeAt(i);
        _spawnLargeAsteroid();
      }
    }

    // Scroll Background
    bgOffset = (bgOffset + dt * 200) % screenSize.height;

    // Update Particles
    for (int i = particles.length - 1; i >= 0; i--) {
      particles[i].position += particles[i].velocity * dt;
      particles[i].life -= dt;
      if (particles[i].life <= 0) {
        particles.removeAt(i);
      }
    }

    // Update screen shake
    if (screenShake > 0) {
      screenShake -= dt * 30;
      if (screenShake < 0) screenShake = 0;
    }

    _checkCollisions();

    // Check level complete
    if (asteroids.isEmpty && !isGameOver) {
      level++;
      _spawnAsteroids();
      // Optional: reset ship position or give brief safety
      _invulnerabilityTimer = 2.0;
    }

    notifyListeners();
  }

  void shoot(double currentTime) {
    if (isGameOver || ship == null) return;
    if (currentTime - _lastFireTime < fireRate) return;

    _lastFireTime = currentTime;
    bullets.add(
      Bullet(
        position:
            ship!.position +
            Offset(
              math.cos(ship!.rotation) * 20,
              math.sin(ship!.rotation) * 20,
            ),
        velocity:
            Offset(
              math.cos(ship!.rotation) * bulletSpeed,
              math.sin(ship!.rotation) * bulletSpeed,
            ) +
            ship!.velocity * 0.5,
      ),
    );
  }

  void _checkCollisions() {
    if (ship == null) return;

    // Bullet vs Asteroid
    for (int i = bullets.length - 1; i >= 0; i--) {
      for (int j = asteroids.length - 1; j >= 0; j--) {
        double dist = (bullets[i].position - asteroids[j].position).distance;
        if (dist < asteroids[j].radius + 5) {
          _destroyAsteroid(j);
          bullets.removeAt(i);
          break;
        }
      }
    }

    // Ship vs Asteroid
    if (_invulnerabilityTimer <= 0) {
      for (var asteroid in asteroids) {
        double dist = (ship!.position - asteroid.position).distance;
        if (dist < ship!.radius + asteroid.radius) {
          _handleShipCrash();
          break;
        }
      }
    }
  }

  void _destroyAsteroid(int index) {
    Asteroid asteroid = asteroids[index];
    asteroids.removeAt(index);

    // Add explosion particles
    _addExplosionParticles(asteroid.position, asteroid.radius, Colors.white);

    // Add screen shake based on size
    screenShake = asteroid.size == AsteroidSize.large
        ? 15.0
        : (asteroid.size == AsteroidSize.medium ? 8.0 : 4.0);

    switch (asteroid.size) {
      case AsteroidSize.large:
        score += 20;
        _splitAsteroid(asteroid, AsteroidSize.medium);
        break;
      case AsteroidSize.medium:
        score += 50;
        _splitAsteroid(asteroid, AsteroidSize.small);
        break;
      case AsteroidSize.small:
        score += 100;
        break;
    }
  }

  void _splitAsteroid(Asteroid parent, AsteroidSize newSize) {
    for (int i = 0; i < 2; i++) {
      // Ensure split asteroids also move generally downwards
      double angle = (math.pi * 0.5) + (_random.nextDouble() - 0.5) * 1.5;
      double parentSpeed = parent.velocity.distance;
      double speed = (parentSpeed + 50.0) * (1.1 + _random.nextDouble() * 0.3);
      asteroids.add(
        Asteroid(
          position: parent.position,
          velocity: Offset(math.cos(angle) * speed, math.sin(angle) * speed),
          size: newSize,
          rotation: _random.nextDouble() * 2 * math.pi,
          rotationSpeed: (_random.nextDouble() - 0.5) * 4,
        ),
      );
    }
  }

  void _handleShipCrash() {
    _addExplosionParticles(ship!.position, 30, Colors.orange);
    screenShake = 25.0;
    lives--;
    if (lives <= 0) {
      isGameOver = true;
    } else {
      ship!.position = Offset(screenSize.width / 2, screenSize.height * 0.8);
      ship!.velocity = Offset.zero;
      _invulnerabilityTimer = 3.0;
    }
  }

  void _addExplosionParticles(Offset pos, double radius, Color color) {
    int count = (radius * 1).toInt();
    for (int i = 0; i < count; i++) {
      double angle = _random.nextDouble() * 2 * math.pi;
      double speed = 50.0 + _random.nextDouble() * 150.0;
      particles.add(
        Particle(
          position: pos,
          velocity: Offset(math.cos(angle) * speed, math.sin(angle) * speed),
          life: 0.5 + _random.nextDouble() * 0.5,
          color: color,
        ),
      );
    }
  }

  void _addThrustParticles() {
    if (ship == null) return;
    double angle =
        ship!.rotation + math.pi + (_random.nextDouble() - 0.5) * 0.5;
    double speed = 100.0 + _random.nextDouble() * 100.0;
    particles.add(
      Particle(
        position:
            ship!.position -
            Offset(
              math.cos(ship!.rotation) * 15,
              math.sin(ship!.rotation) * 15,
            ),
        velocity:
            Offset(math.cos(angle) * speed, math.sin(angle) * speed) +
            ship!.velocity,
        life: 0.2 + _random.nextDouble() * 0.3,
        color: Colors.orange.withOpacity(0.6),
      ),
    );
  }

  bool get isInvulnerable => _invulnerabilityTimer > 0;

  void togglePause() {
    isPaused = !isPaused;
    notifyListeners();
  }

  void restart() {
    _resetGame();
  }
}
