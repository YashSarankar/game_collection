import 'package:flutter/material.dart';
import '../../core/models/game_model.dart';
import '../../games/snake/snake_game_widget.dart';
import '../../games/tic_tac_toe/tic_tac_toe_widget.dart';
import '../../games/brick_breaker/brick_breaker_widget.dart';
import '../../games/memory_match/memory_match_widget.dart';
import '../../games/balloon_pop/balloon_pop_widget.dart';
import '../../games/ping_pong/ping_pong_widget.dart';
import '../../games/ludo/ludo_widget.dart';
import '../../games/carrom/carrom_widget.dart';
import '../../games/game_2048/game_2048_widget.dart';
import '../../games/number_puzzle/number_puzzle_widget.dart';
import '../../games/sudoku/sudoku_widget.dart';
import '../../games/water_sort/water_sort_widget.dart';
import '../../games/chess/chess_widget.dart';
import '../../games/snakes_and_ladders/snakes_and_ladders_widget.dart';
import '../../games/air_hockey/air_hockey_widget.dart';
import '../../games/tap_duel/tap_duel_widget.dart';
import '../../games/dots_and_boxes/dots_and_boxes_widget.dart';
import '../../games/space_shooter_duel/space_shooter_duel_widget.dart';
import '../../games/tank_battle/tank_battle_widget.dart';
import '../../games/asteroids/asteroids_widget.dart';
import '../../games/nine_mens_morris/nine_mens_morris_widget.dart';
import '../../games/word_battle/word_battle_widget.dart';
import '../../games/reaction_time_battle/reaction_time_battle_widget.dart';
import '../../games/tug_of_war/tug_of_war_widget.dart';
import '../../games/knife_hit/knife_hit_widget.dart';
import '../../games/match_3/match_3_widget.dart';

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
      case GameType.ludo:
        return LudoWidget(game: game);
      case GameType.carrom:
        return CarromWidget(game: game);
      case GameType.game2048:
        return Game2048Widget(game: game);
      case GameType.numberPuzzle:
        return NumberPuzzleWidget(game: game);
      case GameType.sudoku:
        return SudokuWidget(game: game);
      case GameType.waterSort:
        return WaterSortWidget(game: game);
      case GameType.chess:
        return ChessWidget(game: game);
      case GameType.snakesAndLadders:
        return SnakesAndLaddersWidget(game: game);
      case GameType.airHockey:
        return AirHockeyWidget(game: game);
      case GameType.tapDuel:
        return TapDuelWidget(game: game);
      case GameType.dotsAndBoxes:
        return DotsAndBoxesWidget(game: game);
      case GameType.spaceShooterDuel:
        return const SpaceShooterDuelWidget();
      case GameType.tankBattle:
        return const TankBattleWidget();
      case GameType.asteroids:
        return AsteroidsWidget(game: game);
      case GameType.nineMensMorris:
        return NineMensMorrisWidget(game: game);
      case GameType.wordBattle:
        return WordBattleWidget(game: game);
      case GameType.reactionTimeBattle:
        return ReactionTimeBattleWidget(game: game);
      case GameType.tugOfWar:
        return TugOfWarWidget(game: game);
      case GameType.knifeHit:
        return KnifeHitWidget(game: game);
      case GameType.match3:
        return Match3Widget(game: game);
    }
  }
}
