import 'package:flutter/material.dart';

class AirHockeyLogic {
  Size tableSize = Size.zero;

  Offset puckPosition = Offset.zero;
  Offset puckVelocity = Offset.zero;
  double puckRadius = 15;

  Offset paddle1Position = Offset.zero;
  Offset paddle2Position = Offset.zero;
  Offset paddle1Velocity = Offset.zero;
  Offset paddle2Velocity = Offset.zero;
  double paddleRadius = 30;

  int player1Score = 0;
  int player2Score = 0;

  double goalWidth = 120;

  bool isGameOver = false;

  void initialize(Size size) {
    tableSize = size;
    resetPuck();
    paddle1Position = Offset(size.width / 2, size.height - 100);
    paddle2Position = Offset(size.width / 2, 100);
  }

  void resetPuck() {
    puckPosition = Offset(tableSize.width / 2, tableSize.height / 2);
    puckVelocity = Offset.zero;
  }

  void update(double dt) {
    if (isGameOver) return;

    // Update Puck Position
    puckPosition += puckVelocity;

    // Friction
    puckVelocity *= 0.99;

    // Wall Collisions
    if (puckPosition.dx - puckRadius < 0) {
      puckPosition = Offset(puckRadius, puckPosition.dy);
      puckVelocity = Offset(-puckVelocity.dx, puckVelocity.dy);
    } else if (puckPosition.dx + puckRadius > tableSize.width) {
      puckPosition = Offset(tableSize.width - puckRadius, puckPosition.dy);
      puckVelocity = Offset(-puckVelocity.dx, puckVelocity.dy);
    }

    // Goal Checking
    if (puckPosition.dy < 0) {
      if (puckPosition.dx > (tableSize.width - goalWidth) / 2 &&
          puckPosition.dx < (tableSize.width + goalWidth) / 2) {
        player1Score++;
        resetPuck();
        puckVelocity = const Offset(0, 2); // Start moving towards player 1
      } else {
        puckPosition = Offset(puckPosition.dx, puckRadius);
        puckVelocity = Offset(puckVelocity.dx, -puckVelocity.dy);
      }
    } else if (puckPosition.dy > tableSize.height) {
      if (puckPosition.dx > (tableSize.width - goalWidth) / 2 &&
          puckPosition.dx < (tableSize.width + goalWidth) / 2) {
        player2Score++;
        resetPuck();
        puckVelocity = const Offset(0, -2); // Start moving towards player 2
      } else {
        puckPosition = Offset(puckPosition.dx, tableSize.height - puckRadius);
        puckVelocity = Offset(puckVelocity.dx, -puckVelocity.dy);
      }
    }

    // Puck speed limit
    double currentSpeed = puckVelocity.distance;
    if (currentSpeed > 15) {
      puckVelocity = (puckVelocity / currentSpeed) * 15;
    }

    // Collision with Paddles
    _checkPaddleCollision(paddle1Position, paddle1Velocity);
    _checkPaddleCollision(paddle2Position, paddle2Velocity);

    // Decelerate paddle velocity tracking
    paddle1Velocity *= 0.5;
    paddle2Velocity *= 0.5;
  }

  void _checkPaddleCollision(Offset paddlePos, Offset paddleVel) {
    final dist = (puckPosition - paddlePos).distance;
    final minDist = puckRadius + paddleRadius;

    if (dist < minDist) {
      final normal = (puckPosition - paddlePos) / dist;

      // Standard reflection + paddle velocity transfer
      double relativeVelocity =
          (puckVelocity - paddleVel).dx * normal.dx +
          (puckVelocity - paddleVel).dy * normal.dy;

      if (relativeVelocity < 0) {
        puckVelocity = (puckVelocity - normal * (2 * relativeVelocity)) * 0.9;
        puckVelocity += paddleVel * 0.5; // Transfer some paddle momentum
      }

      // Ensure a minimum speed after hit
      if (puckVelocity.distance < 3) {
        puckVelocity = normal * 3;
      }

      puckPosition = paddlePos + normal * minDist;
    }
  }

  void movePaddle1(Offset newPos) {
    final oldPos = paddle1Position;
    double dx = newPos.dx.clamp(paddleRadius, tableSize.width - paddleRadius);
    double dy = newPos.dy.clamp(
      tableSize.height / 2 + paddleRadius,
      tableSize.height - paddleRadius,
    );
    paddle1Position = Offset(dx, dy);
    paddle1Velocity = paddle1Position - oldPos;
  }

  void movePaddle2(Offset newPos) {
    final oldPos = paddle2Position;
    double dx = newPos.dx.clamp(paddleRadius, tableSize.width - paddleRadius);
    double dy = newPos.dy.clamp(
      paddleRadius,
      tableSize.height / 2 - paddleRadius,
    );
    paddle2Position = Offset(dx, dy);
    paddle2Velocity = paddle2Position - oldPos;
  }
}
