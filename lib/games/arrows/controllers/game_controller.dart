import 'package:flutter/material.dart';
import '../models/level.dart';
import '../models/arrow_node.dart';
import '../logic/puzzle_generator.dart';
import '../logic/movement_engine.dart';

// Since the SnapPlay core dependencies are not currently accessible
// or may cause compile issues if missing, we use dynamic/optional sound logic
// or fallback to print statements if they don't exist in the project yet.
// However I'll import from the generic path the previous file game_collection uses:
// If it fails, I'll provide stub implementation.
// Trying to stick to normal Flutter widgets for now.
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/services/sound_service.dart';
import '../../../core/services/haptic_service.dart';

class GameController extends ChangeNotifier {
  static const String _unlockedLevelKey = 'arrows_max_unlocked_level';
  int currentLevelNum = 1;
  int maxUnlockedLevel = 1;
  int lives = 3;
  Level? currentLevel;
  bool isGameOver = false;
  bool isLevelComplete = false;
  
  List<ArrowNode> get activeNodes => currentLevel?.nodes.where((n) => !n.isRemoved).toList() ?? [];
  bool get allRemoved => currentLevel != null && activeNodes.isEmpty;
  
  HapticService? _haptic;
  SoundService? _sound;

  ArrowNode? currentlyMovingNode;
  String? invalidNodeId;
  List<List<ArrowNode>> _undoHistory = [];

  Future<void> init(int startingLevel) async {
    try {
      _haptic = await HapticService.getInstance();
      _sound = await SoundService.getInstance();
      
      final prefs = await SharedPreferences.getInstance();
      maxUnlockedLevel = prefs.getInt(_unlockedLevelKey) ?? 1;
    } catch (e) {
      // Ignored if not found
    }
    currentLevelNum = startingLevel;
    _loadLevel(currentLevelNum);
  }

  Future<void> _unlockLevel(int levelId) async {
    if (levelId > maxUnlockedLevel) {
      maxUnlockedLevel = levelId;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_unlockedLevelKey, maxUnlockedLevel);
      notifyListeners();
    }
  }

  void loadSpecificLevel(int levelId) {
    currentLevelNum = levelId;
    _loadLevel(levelId);
  }

  void _loadLevel(int levelId) {
    isGameOver = false;
    isLevelComplete = false;
    lives = 3;
    _undoHistory.clear();
    invalidNodeId = null;
    
    currentLevel = PuzzleGenerator.generateLevel(levelId);
    for(var node in currentLevel!.nodes) {
       node.isRemoved = false;
    }
    notifyListeners();
  }

  void restartLevel() {
    if (currentLevel != null) {
      _loadLevel(currentLevelNum);
    }
  }

  void nextLevel() {
    currentLevelNum++;
    if (currentLevelNum > maxUnlockedLevel) {
       _unlockLevel(currentLevelNum);
    }
    _loadLevel(currentLevelNum);
  }
  
  void undo() {
    if (_undoHistory.isNotEmpty && !isGameOver && !isLevelComplete) {
      final lastState = _undoHistory.removeLast();
      currentLevel = Level(
        id: currentLevel!.id,
        nodes: lastState.map((n) => n.copyWith()).toList(),
        difficulty: currentLevel!.difficulty,
        boardWidth: currentLevel!.boardWidth,
        boardHeight: currentLevel!.boardHeight,
      );
      invalidNodeId = null;
      notifyListeners();
      _haptic?.light();
    }
  }

  void attemptMove(String nodeId) async {
    if (isGameOver || isLevelComplete || currentlyMovingNode != null) return;
    
    final nodeIndex = currentLevel!.nodes.indexWhere((n) => n.id == nodeId);
    if (nodeIndex == -1 || currentLevel!.nodes[nodeIndex].isRemoved) return;
    
    final node = currentLevel!.nodes[nodeIndex];
    if (MovementEngine.canMove(node, currentLevel!.nodes, currentLevel!.boardWidth, currentLevel!.boardHeight)) {
      _undoHistory.add(currentLevel!.nodes.map((n) => n.copyWith()).toList());
      
      currentlyMovingNode = node;
      invalidNodeId = null;
      notifyListeners();
      
      _sound?.playMoveSound('sounds/move_piece.mp3'); 
      _haptic?.selectionClick();
      
      await Future.delayed(const Duration(milliseconds: 300));
      
      node.isRemoved = true;
      currentlyMovingNode = null;
      
      if (allRemoved) {
        isLevelComplete = true;
        _sound?.playSound('sounds/victory.mp3');
        _haptic?.heavy();
      }
      notifyListeners();
    } else {
      lives--;
      invalidNodeId = nodeId;
      _haptic?.heavy();
      _sound?.playSound('sounds/error.mp3');
      
      if (lives <= 0) {
        isGameOver = true;
      }
      notifyListeners();
      
      await Future.delayed(const Duration(milliseconds: 600));
      invalidNodeId = null;
      if (!isGameOver) notifyListeners();
    }
  }
  
  void requestHint() {
    if(isGameOver || isLevelComplete) return;
    bool hintFound = false;
    for (var node in activeNodes) {
       if (MovementEngine.canMove(node, currentLevel!.nodes, currentLevel!.boardWidth, currentLevel!.boardHeight)) {
          _haptic?.light();
          hintFound = true;
          break;
       }
    }
    if (!hintFound) {
       // Should never happen since puzzles are generated solvable
    }
  }
}
