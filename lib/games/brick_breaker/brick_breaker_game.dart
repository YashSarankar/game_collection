import 'dart:async';
import 'dart:math' as math;
import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flame/effects.dart';
import 'package:flame/events.dart';
import 'package:flame/game.dart';
import 'package:flame/particles.dart';
import 'package:flutter/material.dart';

import '../../core/constants/game_constants.dart';
import '../../core/services/haptic_service.dart';
import '../../core/services/sound_service.dart';
import 'brick_breaker_themes.dart';

/// The main game class for Brick Breaker - 2026 Edition (Simplified)
class BrickBreakerGame extends FlameGame
    with HasCollisionDetection, TapCallbacks, DragCallbacks {
  final VoidCallback onGameOver;
  final Function(int) onScoreUpdate;
  final Function(int) onComboUpdate;
  final Function(String, Color) onLevelUpdate;
  final VoidCallback onStartRequest;
  final HapticService? hapticService;
  final SoundService? soundService;

  BrickBreakerTheme theme;
  int level = 1;
  int score = 0;
  int combo = 0;
  double comboTimer = 0;
  static const double maxComboGap = 1.5; // seconds

  bool isGameStarted = false;
  bool isGameOver = false;
  bool _needsLevelSetup = false;

  late Paddle paddle;
  final List<Ball> balls = [];

  BrickBreakerGame({
    required this.onGameOver,
    required this.onScoreUpdate,
    required this.onComboUpdate,
    required this.onLevelUpdate,
    required this.onStartRequest,
    this.hapticService,
    this.soundService,
  }) : theme = BrickBreakerTheme.defaultTheme;

  @override
  Color backgroundColor() => theme.backgroundColor;

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    await add(ScreenHitbox());
    _setupLevel();
  }

  void _setupLevel() {
    removeAll(children);
    balls.clear();
    add(ScreenHitbox());

    isGameStarted = false;
    isGameOver = false;
    combo = 0;

    onLevelUpdate("Level $level", theme.glowColor);

    // Add Paddle
    paddle = Paddle(color: theme.paddleColor, glowColor: theme.glowColor);
    add(paddle);

    // Add Initial Ball
    final ball = Ball(color: theme.ballColor, glowColor: theme.glowColor);
    balls.add(ball);
    add(ball);

    // Add Bricks based on level
    _addBricks();

    // Background particles for ambiance
    _addBackgroundParticles();
  }

  void _addBackgroundParticles() {
    final random = math.Random();
    add(
      ParticleSystemComponent(
        particle: Particle.generate(
          count: 20,
          lifespan: 10,
          generator: (i) => MovingParticle(
            curve: Curves.easeInOut,
            from: Vector2(
              random.nextDouble() * size.x,
              random.nextDouble() * size.y,
            ),
            to: Vector2(
              random.nextDouble() * size.x,
              random.nextDouble() * size.y,
            ),
            child: CircleParticle(
              radius: random.nextDouble() * 2,
              paint: Paint()..color = theme.glowColor.withOpacity(0.1),
            ),
          ),
        ),
      ),
    );
  }

  void _addBricks() {
    const double brickHeight = 25;
    const double brickPadding = 4;
    final int columns = 8;
    final int rows = 4 + (level ~/ 2).clamp(0, 6);
    final double brickWidth = (size.x - (columns + 1) * brickPadding) / columns;

    for (int i = 0; i < rows; i++) {
      for (int j = 0; j < columns; j++) {
        // Randomly skip some bricks for designs in later levels
        if (level > 2 && math.Random().nextDouble() < 0.1) continue;

        add(
          Brick(
            position: Vector2(
              j * (brickWidth + brickPadding) + brickPadding,
              i * (brickHeight + brickPadding) + 120, // Lowered for UI
            ),
            size: Vector2(brickWidth, brickHeight),
            color: theme.brickColors[i % theme.brickColors.length],
            glowColor: theme.glowColor,
            strength: (i == 0 && level > 3) ? 2 : 1,
          ),
        );
      }
    }
  }

  void startGame() {
    if (!isGameStarted && !isGameOver) {
      isGameStarted = true;
      double baseSpeed = 400 + (level * 40); // More aggressive speed increase
      for (var ball in balls) {
        ball.velocity = Vector2(0, -baseSpeed);
      }
    }
  }

  @override
  void update(double dt) {
    super.update(dt);

    if (_needsLevelSetup) {
      _needsLevelSetup = false;
      level++;
      _setupLevel();
      hapticService?.heavy();
      return;
    }

    if (isGameStarted) {
      comboTimer -= dt;
      if (comboTimer <= 0 && combo > 0) {
        combo = 0;
        onComboUpdate(combo);
      }
    }
  }

  void onBrickHit(Brick brick) {
    // Combo logic
    combo++;
    comboTimer = maxComboGap;
    onComboUpdate(combo);

    int points = 10 * (1 + combo ~/ 5);
    score += points;
    onScoreUpdate(score);

    hapticService?.light();
    soundService?.playPop();

    // Particle Explosion
    _spawnExplosion(brick.position + brick.size / 2, brick.color);

    // Screen Shake on combo
    if (combo % 5 == 0) {
      camera.viewfinder.add(
        MoveEffect.by(
          Vector2(4, 4),
          EffectController(
            duration: 0.05,
            reverseDuration: 0.05,
            repeatCount: 3,
          ),
        ),
      );
    }

    if (brick.strength <= 1) {
      brick.removeFromParent();
      _checkWinCondition();
    } else {
      brick.strength--;
    }
  }

  void _spawnExplosion(Vector2 position, Color color) {
    add(
      ParticleSystemComponent(
        position: position,
        particle: Particle.generate(
          count: 15,
          lifespan: 0.8,
          generator: (i) {
            final random = math.Random();
            final angle = random.nextDouble() * math.pi * 2;
            final speed = 50 + random.nextDouble() * 100;
            return MovingParticle(
              from: Vector2.zero(),
              to: Vector2(math.cos(angle) * speed, math.sin(angle) * speed),
              child: AcceleratedParticle(
                acceleration: Vector2(0, 100),
                child: CircleParticle(
                  radius: 1 + random.nextDouble() * 2,
                  paint: Paint()..color = color,
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  void _checkWinCondition() {
    final remainingBricks = children
        .whereType<Brick>()
        .where((b) => !b.isRemoving)
        .length;
    if (remainingBricks <= 0) {
      _needsLevelSetup = true;
    }
  }

  void gameOver() {
    if (isGameOver) return;
    isGameOver = true;
    isGameStarted = false;
    onGameOver();
  }

  void removeBall(Ball ball) {
    balls.remove(ball);
    ball.removeFromParent();
    if (balls.isEmpty) {
      gameOver();
    }
  }

  @override
  void onTapDown(TapDownEvent event) {
    if (!isGameStarted && !isGameOver) {
      onStartRequest();
    }
  }

  @override
  void onDragUpdate(DragUpdateEvent event) {
    paddle.position.x += event.localDelta.x;
    paddle.position.x = paddle.position.x.clamp(
      paddle.size.x / 2,
      size.x - paddle.size.x / 2,
    );

    if (!isGameStarted && balls.isNotEmpty) {
      balls.first.position.x = paddle.position.x;
    }
  }
}

class Paddle extends PositionComponent
    with CollisionCallbacks, HasGameRef<BrickBreakerGame> {
  Color color;
  final Color glowColor;

  Paddle({required this.color, required this.glowColor})
    : super(
        size: Vector2(GameConstants.brickBreakerPaddleWidth, 18),
        anchor: Anchor.center,
      );

  @override
  Future<void> onLoad() async {
    // Shrink paddle with difficulty
    final double difficultyWidth =
        (GameConstants.brickBreakerPaddleWidth - (gameRef.level * 10))
            .clamp(60, 200)
            .toDouble();
    size = Vector2(difficultyWidth, 18);
    position = Vector2(gameRef.size.x / 2, gameRef.size.y - 60);
    add(RectangleHitbox());
  }

  @override
  void render(Canvas canvas) {
    // Glow effect
    final shadowPaint = Paint()
      ..color = glowColor.withOpacity(0.5)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12);
    canvas.drawRRect(
      RRect.fromRectAndRadius(size.toRect(), const Radius.circular(10)),
      shadowPaint,
    );

    final paint = Paint()
      ..shader = LinearGradient(
        colors: [color, color.withOpacity(0.8)],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ).createShader(size.toRect());

    final rect = Rect.fromLTWH(0, 0, size.x, size.y);
    final rrect = RRect.fromRectAndRadius(rect, const Radius.circular(10));
    canvas.drawRRect(rrect, paint);

    // Gloss effect
    final glossPaint = Paint()..color = Colors.white.withOpacity(0.2);
    canvas.drawRect(Rect.fromLTWH(5, 2, size.x - 10, 4), glossPaint);
  }
}

class Ball extends CircleComponent
    with CollisionCallbacks, HasGameRef<BrickBreakerGame> {
  Vector2 velocity = Vector2.zero();
  final Color glowColor;

  Ball({required Color color, required this.glowColor})
    : super(
        radius: GameConstants.brickBreakerBallRadius,
        anchor: Anchor.center,
        paint: Paint()..color = color,
      );

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    reset();
    add(CircleHitbox());
  }

  void reset() {
    position = Vector2(gameRef.size.x / 2, gameRef.size.y - 85);
    velocity = Vector2.zero();
    paint.color = gameRef.theme.ballColor;
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (!gameRef.isGameStarted) {
      position.x = gameRef.paddle.position.x;
      return;
    }

    position += velocity * dt;

    // Trail effect
    _spawnTrail();

    // Screen Bounce Logic
    if (position.x < radius) {
      position.x = radius;
      velocity.x = velocity.x.abs();
    }
    if (position.x > gameRef.size.x - radius) {
      position.x = gameRef.size.x - radius;
      velocity.x = -velocity.x.abs();
    }
    if (position.y < radius) {
      position.y = radius;
      velocity.y = velocity.y.abs();
    }
    if (position.y > gameRef.size.y) {
      gameRef.removeBall(this);
    }
  }

  void _spawnTrail() {
    gameRef.add(
      ParticleSystemComponent(
        position: position.clone(),
        particle: Particle.generate(
          count: 1,
          lifespan: 0.3,
          generator: (i) => CircleParticle(
            radius: radius * 0.8,
            paint: Paint()..color = glowColor.withOpacity(0.3),
          ),
        ),
      ),
    );
  }

  @override
  void render(Canvas canvas) {
    // Ball glow
    final glowPaint = Paint()
      ..color = glowColor.withOpacity(0.4)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);
    canvas.drawCircle(Offset(radius, radius), radius, glowPaint);

    super.render(canvas);
  }

  @override
  void onCollisionStart(
    Set<Vector2> intersectionPoints,
    PositionComponent other,
  ) {
    super.onCollisionStart(intersectionPoints, other);

    if (other is ScreenHitbox) {
      // Handled in update
    } else if (other is Paddle) {
      velocity.y = -velocity.y.abs();

      final double hitOffset =
          (position.x - other.position.x) / (other.size.x / 2);
      velocity.x += hitOffset * 300;

      // Clamp velocity
      if (velocity.x.abs() > 600) velocity.x = velocity.x.sign * 600;

      gameRef.hapticService?.light();
      gameRef.soundService?.playBounce();
    } else if (other is Brick) {
      if (other.isRemoving) return;

      if (intersectionPoints.isNotEmpty) {
        final center = other.position + (other.size / 2);
        final collisionPoint = intersectionPoints.first;
        final delta = (collisionPoint - center);

        if ((delta.x.abs() / other.size.x) > (delta.y.abs() / other.size.y)) {
          velocity.x = delta.x.sign * velocity.x.abs();
        } else {
          velocity.y = delta.y.sign * velocity.y.abs();
        }
      } else {
        velocity.y = -velocity.y;
      }
      gameRef.onBrickHit(other);
    }
  }
}

class Brick extends PositionComponent with CollisionCallbacks {
  final Color color;
  final Color glowColor;
  int strength;
  bool isHit = false;

  Brick({
    required Vector2 position,
    required Vector2 size,
    required this.color,
    required this.glowColor,
    this.strength = 1,
  }) : super(position: position, size: size, anchor: Anchor.topLeft);

  @override
  Future<void> onLoad() async {
    add(RectangleHitbox());
  }

  @override
  void render(Canvas canvas) {
    final rect = Rect.fromLTWH(0, 0, size.x, size.y);

    // Glow
    final glowPaint = Paint()
      ..color = color.withOpacity(0.3)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);
    canvas.drawRRect(
      RRect.fromRectAndRadius(rect, const Radius.circular(4)),
      glowPaint,
    );

    final paint = Paint()
      ..shader = LinearGradient(
        colors: [color, color.withOpacity(0.7)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ).createShader(rect);

    final rrect = RRect.fromRectAndRadius(rect, const Radius.circular(4));
    canvas.drawRRect(rrect, paint);

    // Strength indicator
    if (strength > 1) {
      final textPainter = TextPainter(
        text: TextSpan(
          text: '$strength',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 12,
            fontWeight: FontWeight.bold,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      textPainter.paint(
        canvas,
        Offset(
          size.x / 2 - textPainter.width / 2,
          size.y / 2 - textPainter.height / 2,
        ),
      );
    }

    // Border
    final borderPaint = Paint()
      ..color = Colors.white.withOpacity(0.2)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    canvas.drawRRect(rrect, borderPaint);
  }
}
