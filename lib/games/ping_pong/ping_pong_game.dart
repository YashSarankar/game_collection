import 'dart:async';
import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/services/haptic_service.dart';

class PingPongGame extends FlameGame
    with HasCollisionDetection, KeyboardEvents, HasGameRef {
  final VoidCallback onGameOver;
  final Function(int, int) onScoreUpdate; // top, bottom
  final HapticService? hapticService;
  final Color ballColor;
  Color gameBackgroundColor;

  PingPongGame({
    required this.onGameOver,
    required this.onScoreUpdate,
    this.hapticService,
    this.ballColor = Colors.white,
    this.gameBackgroundColor = const Color(0xFF000000),
  });

  late Paddle topPaddle;
  late Paddle bottomPaddle;
  late Ball ball;

  int topScore = 0;
  int bottomScore = 0;
  bool isGameStarted = false;
  bool isGameOver = false;
  bool isPaused = false;

  // Track serving side (true = top, false = bottom)
  bool topServes = true;

  // Active keys tracking for perfect simultaneous movement
  final Set<LogicalKeyboardKey> activeKeys = {};

  @override
  Color backgroundColor() => gameBackgroundColor;

  void updateColors(Color bgColor, Color ballColor) {
    gameBackgroundColor = bgColor;
    ball.paint.color = ballColor;
  }

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    _initGame();
  }

  void _initGame() {
    removeAll(children);
    add(ScreenHitbox());

    // Top Paddle (Player 2)
    topPaddle = Paddle(isBottom: false, color: Colors.redAccent);
    add(topPaddle);

    // Bottom Paddle (Player 1)
    bottomPaddle = Paddle(isBottom: true, color: Colors.blueAccent);
    add(bottomPaddle);

    // Ball
    ball = Ball(color: ballColor);
    add(ball);

    _resetBallPosition();
  }

  void _resetBallPosition() {
    ball.position = Vector2(size.x / 2, size.y / 2);
    ball.velocity = Vector2.zero();
    isGameStarted = false;
  }

  Future<void> releaseBall() async {
    if (isGameOver || isPaused) return;

    isPaused = true;
    _resetBallPosition();

    await Future.delayed(const Duration(seconds: 1));

    if (isGameOver) return;

    isGameStarted = true;
    isPaused = false;

    double vy = topServes ? -450 : 450;
    double vx = (DateTime.now().millisecond % 400 - 200).toDouble();
    ball.velocity = Vector2(vx, vy);
  }

  void onScore(bool topScored) {
    if (isGameOver) return;

    if (topScored) {
      topScore++;
      topServes = false;
      hapticService?.success();
    } else {
      bottomScore++;
      topServes = true;
      hapticService?.error();
    }

    onScoreUpdate(topScore, bottomScore);

    if (topScore >= 7 || bottomScore >= 7) {
      isGameOver = true;
      ball.velocity = Vector2.zero();
      onGameOver();
    } else {
      releaseBall();
    }
  }

  void restartGame() {
    topScore = 0;
    bottomScore = 0;
    isGameOver = false;
    isGameStarted = false;
    isPaused = false;
    topServes = true;
    onScoreUpdate(topScore, bottomScore);
    _initGame();
  }

  @override
  KeyEventResult onKeyEvent(
    KeyEvent event,
    Set<LogicalKeyboardKey> keysPressed,
  ) {
    if (event is KeyDownEvent) {
      activeKeys.add(event.logicalKey);
      if (event.logicalKey == LogicalKeyboardKey.keyR && isGameOver) {
        restartGame();
      }
    } else if (event is KeyUpEvent) {
      activeKeys.remove(event.logicalKey);
    }

    // List of keys we handle so Flutter doesn't use them for scrolling
    final handledKeys = {
      LogicalKeyboardKey.keyW,
      LogicalKeyboardKey.keyS,
      LogicalKeyboardKey.keyA,
      LogicalKeyboardKey.keyD,
      LogicalKeyboardKey.arrowUp,
      LogicalKeyboardKey.arrowDown,
      LogicalKeyboardKey.arrowLeft,
      LogicalKeyboardKey.arrowRight,
      LogicalKeyboardKey.keyR,
    };

    if (handledKeys.contains(event.logicalKey)) {
      return KeyEventResult.handled;
    }

    return KeyEventResult.ignored;
  }
}

class Paddle extends PositionComponent
    with CollisionCallbacks, DragCallbacks, HasGameRef<PingPongGame> {
  final bool isBottom;
  final Color color;
  final double speed = 900; // Increased for better "playability"

  Paddle({required this.isBottom, required this.color})
    : super(size: Vector2(100, 18), anchor: Anchor.center);

  @override
  Future<void> onLoad() async {
    double yPos = isBottom ? gameRef.size.y - 60 : 60;
    position = Vector2(gameRef.size.x / 2, yPos);
    add(RectangleHitbox());
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (gameRef.isGameOver) return;

    final keys = gameRef.activeKeys;

    if (isBottom) {
      // Player 1: W/S or A/D
      if (keys.contains(LogicalKeyboardKey.keyW) ||
          keys.contains(LogicalKeyboardKey.keyA)) {
        position.x -= speed * dt;
      }
      if (keys.contains(LogicalKeyboardKey.keyS) ||
          keys.contains(LogicalKeyboardKey.keyD)) {
        position.x += speed * dt;
      }
    } else {
      // Player 2: Up/Down or Left/Right
      if (keys.contains(LogicalKeyboardKey.arrowUp) ||
          keys.contains(LogicalKeyboardKey.arrowLeft)) {
        position.x -= speed * dt;
      }
      if (keys.contains(LogicalKeyboardKey.arrowDown) ||
          keys.contains(LogicalKeyboardKey.arrowRight)) {
        position.x += speed * dt;
      }
    }

    // Clamp position
    position.x = position.x.clamp(size.x / 2, gameRef.size.x - size.x / 2);
  }

  @override
  void onDragUpdate(DragUpdateEvent event) {
    if (gameRef.isGameOver) return;
    position.x += event.localDelta.x;
    position.x = position.x.clamp(size.x / 2, gameRef.size.x - size.x / 2);
  }

  @override
  void render(Canvas canvas) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final borderPaint = Paint()
      ..color = Colors.white.withOpacity(0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    final rect = Rect.fromLTWH(0, 0, size.x, size.y);
    final rrect = RRect.fromRectAndRadius(rect, const Radius.circular(9));

    canvas.drawRRect(rrect, paint);
    canvas.drawRRect(rrect, borderPaint);
  }
}

class Ball extends CircleComponent
    with CollisionCallbacks, HasGameRef<PingPongGame> {
  Vector2 velocity = Vector2.zero();

  Ball({required Color color})
    : super(radius: 10, anchor: Anchor.center, paint: Paint()..color = color);

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    add(CircleHitbox());
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (!gameRef.isGameStarted || gameRef.isGameOver || gameRef.isPaused)
      return;

    position += velocity * dt;

    if (position.x < radius) {
      position.x = radius;
      velocity.x = velocity.x.abs();
    } else if (position.x > gameRef.size.x - radius) {
      position.x = gameRef.size.x - radius;
      velocity.x = -velocity.x.abs();
    }

    if (position.y < 0) {
      gameRef.onScore(false);
    } else if (position.y > gameRef.size.y) {
      gameRef.onScore(true);
    }
  }

  @override
  void onCollisionStart(
    Set<Vector2> intersectionPoints,
    PositionComponent other,
  ) {
    if (gameRef.isGameOver) return;
    super.onCollisionStart(intersectionPoints, other);

    if (other is Paddle) {
      if (other.isBottom) {
        velocity.y = -velocity.y.abs();
      } else {
        velocity.y = velocity.y.abs();
      }

      final double hitOffset =
          (position.x - other.position.x) / (other.size.x / 2);
      velocity.x += hitOffset * 350;
      velocity *= 1.1;

      if (velocity.length > 1100) {
        velocity = velocity.normalized() * 1100;
      }
      gameRef.hapticService?.light();
    }
  }
}
