import 'dart:async';
import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flame/game.dart';
import 'package:flame/input.dart';
import 'package:flutter/material.dart';

import '../../core/constants/game_constants.dart';
import '../../core/services/haptic_service.dart';

/// The main game class for Brick Breaker
class BrickBreakerGame extends FlameGame
        // ignore: deprecated_member_use
        with
        HasCollisionDetection,
        TapDetector,
        PanDetector {
  final VoidCallback onGameOver;
  final Function(int) onScoreUpdate;
  final HapticService? hapticService;
  Color ballColor;
  Color paddleColor;
  Color gameBackgroundColor;

  BrickBreakerGame({
    required this.onGameOver,
    required this.onScoreUpdate,
    this.hapticService,
    this.ballColor = Colors.white,
    this.paddleColor = const Color(0xFFFF8C00),
    this.gameBackgroundColor = const Color(0xFF000000),
  });

  late Paddle paddle;
  late Ball ball;

  int score = 0;
  double ballSpeedMultiplier = 1.0;
  bool isGameStarted = false;
  bool isGameOver = false;

  @override
  Color backgroundColor() => gameBackgroundColor;

  @override
  Future<void> onLoad() async {
    await super.onLoad();

    // Add boundaries (walls)
    await add(ScreenHitbox());

    _resetGame();
  }

  void _resetGame() {
    removeAll(children);
    add(ScreenHitbox());

    score = 0;
    ballSpeedMultiplier = 1.0;
    isGameStarted = false;
    isGameOver = false;
    onScoreUpdate(0);

    // Add Paddle
    paddle = Paddle(color: paddleColor);
    add(paddle);

    // Add Ball
    ball = Ball(color: ballColor);
    add(ball);

    // Add Bricks
    _addBricks();
  }

  void _addBricks() {
    const double brickHeight = 30;
    const double brickPadding = 5;
    final double brickWidth =
        size.x / GameConstants.brickBreakerColumns - brickPadding;

    for (int i = 0; i < GameConstants.brickBreakerRows; i++) {
      for (int j = 0; j < GameConstants.brickBreakerColumns; j++) {
        add(
          Brick(
            position: Vector2(
              j * (brickWidth + brickPadding) + brickPadding / 2,
              i * (brickHeight + brickPadding) + 100, // Offset from top
            ),
            size: Vector2(brickWidth, brickHeight),
            color: GameColors.brickColors[i % GameColors.brickColors.length],
          ),
        );
      }
    }
  }

  void startGame() {
    if (!isGameStarted && !isGameOver) {
      isGameStarted = true;
      double baseSpeed = 350 * ballSpeedMultiplier;
      // Cap max speed
      if (baseSpeed > 800) baseSpeed = 800;
      ball.velocity = Vector2(0, -baseSpeed); // Shoot up
    }
  }

  void updateColors({
    required Color ballColor,
    required Color paddleColor,
    required Color gameBackgroundColor,
  }) {
    this.ballColor = ballColor;
    this.paddleColor = paddleColor;
    this.gameBackgroundColor = gameBackgroundColor;

    // Update existing components
    paddle.color = paddleColor;
    ball.paint.color = ballColor;
  }

  void gameOver() {
    isGameOver = true;
    isGameStarted = false;
    onGameOver();
  }

  void onBrickHit(Brick brick) {
    if (brick.isHit) return;
    brick.isHit = true;
    score += 10;
    onScoreUpdate(score);
    hapticService?.light();
    brick.removeFromParent();

    // Check win condition (no bricks left)
    // We check for length <= 1 because the current brick is still in children but marked for removal
    final remainingBricks = children
        .whereType<Brick>()
        .where((b) => !b.isHit)
        .length;

    if (remainingBricks == 0) {
      _nextLevel();
    }
  }

  void _nextLevel() {
    // Respawn bricks
    _addBricks();

    // Reset ball to paddle for the next level
    isGameStarted = false;
    ball.reset();

    // Increase speed for the next level difficulty
    ballSpeedMultiplier *= 1.15;

    hapticService?.medium();
  }

  @override
  void onTapDown(TapDownInfo info) {
    if (!isGameStarted) {
      startGame();
    }
  }

  @override
  void onPanUpdate(DragUpdateInfo info) {
    paddle.position.x += info.delta.global.x;
    // Clamp paddle within screen
    paddle.position.x = paddle.position.x.clamp(
      paddle.size.x / 2,
      size.x - paddle.size.x / 2,
    );

    if (!isGameStarted) {
      ball.position.x = paddle.position.x;
    }
  }
}

class Paddle extends PositionComponent
    with CollisionCallbacks, HasGameRef<BrickBreakerGame> {
  Color color;

  Paddle({required this.color})
    : super(
        size: Vector2(GameConstants.brickBreakerPaddleWidth, 20),
        anchor: Anchor.center,
      );

  @override
  Future<void> onLoad() async {
    position = Vector2(gameRef.size.x / 2, gameRef.size.y - 50);
    add(RectangleHitbox());
  }

  @override
  void render(Canvas canvas) {
    final paint = Paint()..color = color;
    final rect = Rect.fromLTWH(0, 0, size.x, size.y);
    final rrect = RRect.fromRectAndRadius(rect, const Radius.circular(10));
    canvas.drawRRect(rrect, paint);
  }
}

class Ball extends CircleComponent
    with CollisionCallbacks, HasGameRef<BrickBreakerGame> {
  Vector2 velocity = Vector2.zero();

  Ball({required Color color})
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
    position = Vector2(
      gameRef.size.x / 2,
      gameRef.size.y - 80,
    ); // Just above paddle
    velocity = Vector2.zero();
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (!gameRef.isGameStarted) {
      position.x = gameRef.paddle.position.x;
      return;
    }

    position += velocity * dt;

    // Screen Bounce Logic
    // Left
    if (position.x < radius) {
      position.x = radius;
      velocity.x = velocity.x.abs();
    }
    // Right
    if (position.x > gameRef.size.x - radius) {
      position.x = gameRef.size.x - radius;
      velocity.x = -velocity.x.abs();
    }
    // Top
    if (position.y < radius) {
      position.y = radius;
      velocity.y = velocity.y.abs();
    }
    // Bottom (Game Over)
    if (position.y > gameRef.size.y) {
      gameRef.gameOver();
    }
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
      velocity.y = -velocity.y.abs(); // Always bounce up

      // Prevent horizontal locking
      if (velocity.y.abs() < 200) {
        velocity.y = -200;
      }

      // Add english/spin based on where it hit the paddle
      final double hitOffset =
          (position.x - other.position.x) / (other.size.x / 2);
      velocity.x += hitOffset * 300; // Adjust horizontal angle

      // Clamp velocity.x to prevent extreme angles
      if (velocity.x.abs() > 500) {
        velocity.x = velocity.x.sign * 500;
      }

      gameRef.hapticService?.light();
    } else if (other is Brick) {
      if (other.isHit) return;

      // Robust Collision Detection using intersection points
      if (intersectionPoints.isNotEmpty) {
        final center = other.position + (other.size / 2);
        final collisionPoint = intersectionPoints.first;
        final delta = (collisionPoint - center);

        // Determine if hit top/bottom or left/right
        if ((delta.x.abs() / other.size.x) > (delta.y.abs() / other.size.y)) {
          // Hit from side
          velocity.x = delta.x.sign * velocity.x.abs();
        } else {
          // Hit from top/bottom
          velocity.y = delta.y.sign * velocity.y.abs();
        }
      } else {
        // Fallback to simple bounce
        velocity.y = -velocity.y;
      }

      gameRef.onBrickHit(other);
    }
  }
}

class Brick extends PositionComponent with CollisionCallbacks {
  final Color color;
  bool isHit = false;

  Brick({required Vector2 position, required Vector2 size, required this.color})
    : super(position: position, size: size, anchor: Anchor.topLeft);

  @override
  Future<void> onLoad() async {
    add(RectangleHitbox());
  }

  @override
  void render(Canvas canvas) {
    if (isHit) return;
    final paint = Paint()..color = color;
    final rect = Rect.fromLTWH(0, 0, size.x, size.y);
    final rrect = RRect.fromRectAndRadius(rect, const Radius.circular(4));

    // Add a simple border for better visibility
    final borderPaint = Paint()
      ..color = Colors.white.withOpacity(0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    canvas.drawRRect(rrect, paint);
    canvas.drawRRect(rrect, borderPaint);
  }
}
