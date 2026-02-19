import 'dart:async';
import 'package:flutter/material.dart';
import '../models/sudoku_cell.dart';
import '../sudoku_logic.dart';
import '../../../core/services/sound_service.dart';
import '../../../core/services/haptic_service.dart';

extension DifficultyExtension on SudokuDifficulty {
  int get clues {
    switch (this) {
      case SudokuDifficulty.easy:
        return 35;
      case SudokuDifficulty.medium:
        return 45;
      case SudokuDifficulty.hard:
        return 55;
      case SudokuDifficulty.expert:
        return 62;
    }
  }
}

class SudokuProvider extends ChangeNotifier {
  List<List<SudokuCell>> board = [];
  int? selectedRow;
  int? selectedCol;
  int mistakes = 0;
  bool isNotesMode = false;
  bool isGameOver = false;
  bool won = false;
  SudokuDifficulty difficulty = SudokuDifficulty.medium;

  // Stats
  Stopwatch stopwatch = Stopwatch();
  Duration elapsedTime = Duration.zero;
  Timer? _timer;

  // Services
  SoundService? _soundService;
  HapticService? _hapticService;

  SudokuProvider() {
    _initServices();
  }

  Future<void> _initServices() async {
    _soundService = await SoundService.getInstance();
    _hapticService = await HapticService.getInstance();
  }

  void startNewGame(SudokuDifficulty diff) {
    difficulty = diff;
    final generated = SudokuLogic.generate(difficulty: diff);
    final puzzle = generated['puzzle']!;
    final solution = generated['solution']!;

    board = List.generate(9, (r) {
      return List.generate(9, (c) {
        return SudokuCell(
          row: r,
          col: c,
          value: puzzle[r][c],
          solutionValue: solution[r][c],
          isInitial: puzzle[r][c] != 0,
        );
      });
    });

    selectedRow = null;
    selectedCol = null;
    mistakes = 0;
    isGameOver = false;
    won = false;
    isNotesMode = false;

    stopwatch.reset();
    stopwatch.start();
    _startTimer();
    notifyListeners();
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      elapsedTime = stopwatch.elapsed;
      notifyListeners();
    });
  }

  void selectCell(int r, int c) {
    if (isGameOver) return;
    selectedRow = r;
    selectedCol = c;
    _hapticService?.light();
    notifyListeners();
  }

  void inputNumber(int n) {
    if (selectedRow == null || selectedCol == null || isGameOver) return;
    final cell = board[selectedRow!][selectedCol!];
    if (cell.isInitial || cell.value == n && !isNotesMode) return;

    if (isNotesMode) {
      if (cell.notes.contains(n)) {
        cell.notes.remove(n);
      } else {
        cell.notes.add(n);
      }
      _hapticService?.light();
    } else {
      if (cell.solutionValue == n) {
        cell.value = n;
        cell.notes.clear();
        cell.isError = false;
        _hapticService?.light();
        _soundService?.playPop();
        _checkWin();
      } else {
        cell.value = n;
        cell.isError = true;
        mistakes++;
        _hapticService?.heavy();
        _soundService?.playError();
        if (mistakes >= 3) {
          _endGame(false);
        }
      }
    }
    notifyListeners();
  }

  void erase() {
    if (selectedRow == null || selectedCol == null || isGameOver) return;
    final cell = board[selectedRow!][selectedCol!];
    if (cell.isInitial) return;

    cell.value = 0;
    cell.notes.clear();
    cell.isError = false;
    _hapticService?.light();
    notifyListeners();
  }

  void undo() {
    // Basic undo can be added with a history stack if needed
  }

  void toggleNotesMode() {
    isNotesMode = !isNotesMode;
    _hapticService?.selectionClick();
    notifyListeners();
  }

  void useHint() {
    if (selectedRow == null || selectedCol == null || isGameOver) return;
    final cell = board[selectedRow!][selectedCol!];
    if (cell.value == cell.solutionValue) return;

    cell.value = cell.solutionValue;
    cell.notes.clear();
    cell.isError = false;
    _hapticService?.success();
    _checkWin();
    notifyListeners();
  }

  void _checkWin() {
    bool isComplete = true;
    for (var row in board) {
      for (var cell in row) {
        if (cell.value != cell.solutionValue) {
          isComplete = false;
          break;
        }
      }
    }
    if (isComplete) {
      _endGame(true);
    }
  }

  void _endGame(bool isWon) {
    isGameOver = true;
    won = isWon;
    stopwatch.stop();
    _timer?.cancel();
    if (isWon) {
      _soundService?.playSuccess();
      _hapticService?.success();
    } else {
      _soundService?.playGameOver();
    }
    notifyListeners();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}
