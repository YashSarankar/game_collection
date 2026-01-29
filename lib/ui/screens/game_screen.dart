import 'package:flutter/material.dart';
import '../../core/models/game_model.dart';
import '../../games/snake/snake_game_widget.dart';
import '../../games/tic_tac_toe/tic_tac_toe_widget.dart';
import '../../games/brick_breaker/brick_breaker_widget.dart';
import '../../games/memory_match/memory_match_widget.dart';
import '../../games/balloon_pop/balloon_pop_widget.dart';
import '../../games/ping_pong/ping_pong_widget.dart';

class GameScreen extends StatelessWidget {
  final GameModel game;

  const GameScreen({super.key, required this.game});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(child: _buildGameWidget()),
    );
  }

  Widget _buildGameWidget() {
    switch (game.type) {
      case GameType.snake:
        return SnakeGameWidget(game: game);
      case GameType.ticTacToe:
        return TicTacToeWidget(game: game);
      case GameType.brickBreaker:
        return BrickBreakerWidget(game: game);
      case GameType.memoryMatch:
        return MemoryMatchWidget(game: game);
      case GameType.balloonPop:
        return BalloonPopWidget(game: game);
      case GameType.pingPong:
        return PingPongWidget(game: game);
    }
  }
}
