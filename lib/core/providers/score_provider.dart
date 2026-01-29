import 'package:flutter/foundation.dart';
import '../services/storage_service.dart';
import '../models/game_model.dart';

/// Provider for managing game scores
class ScoreProvider extends ChangeNotifier {
  final StorageService _storage;

  Map<String, int> _highScores = {};

  ScoreProvider(this._storage) {
    _loadScores();
  }

  Map<String, int> get highScores => _highScores;

  int getHighScore(String gameId) {
    return _highScores[gameId] ?? 0;
  }

  Future<void> _loadScores() async {
    _highScores = await _storage.getAllHighScores();
    notifyListeners();
  }

  Future<bool> saveScore(String gameId, int score) async {
    final isNewHighScore = await _storage.saveHighScore(gameId, score);
    if (isNewHighScore) {
      _highScores[gameId] = score;
      notifyListeners();
    }
    return isNewHighScore;
  }

  Future<void> resetHighScore(String gameId) async {
    _highScores[gameId] = 0;
    await _storage.saveHighScore(gameId, 0);
    notifyListeners();
  }

  Future<void> resetAllScores() async {
    _highScores.clear();
    // Clear all scores by saving 0 for each game
    for (final game in GamesList.allGames) {
      await _storage.saveHighScore(game.id, 0);
    }
    notifyListeners();
  }
}
