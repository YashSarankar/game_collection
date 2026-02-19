import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../models/tile_model.dart';
import '../models/game_event.dart';

class Match3Controller extends ChangeNotifier {
  final int rows;
  final int cols;
  final int level;
  final int targetScore;

  late List<List<TileModel>> grid;

  int score = 0;
  int moves = 30;
  bool isProcessing = false;

  final StreamController<GameEvent> _eventController =
      StreamController<GameEvent>.broadcast();
  Stream<GameEvent> get events => _eventController.stream;

  final math.Random _random = math.Random();

  Match3Controller({
    this.rows = 8,
    this.cols = 8,
    this.level = 1,
    this.targetScore = 2000,
  }) {
    moves = 25 + (level * 5).clamp(0, 20); // Scales with level
    _initGrid();
  }

  // ──────────────────────────────────────────────────────────────
  // Grid initialization
  // ──────────────────────────────────────────────────────────────
  void _initGrid() {
    // Build into a local list — we CANNOT reference `grid` (a `late` field)
    // during List.generate because it hasn't been assigned yet.
    final g = <List<TileModel>>[];
    for (int r = 0; r < rows; r++) {
      final rowList = <TileModel>[];
      for (int c = 0; c < cols; c++) {
        TileType type;
        do {
          type = _randomType();
        } while (_isInstantMatch(r, c, type, g, rowList));
        rowList.add(TileModel(r: r, c: c, type: type));
      }
      g.add(rowList);
    }
    grid = g;

    // Ensure the board always has at least one valid move.
    while (!hasPossibleMoves()) {
      _shuffleInPlace();
    }
  }

  TileType _randomType() {
    return TileType.values[_random.nextInt(
      TileType.values.length - 1,
    )]; // exclude TileType.empty
  }

  // _isInstantMatch checks whether placing `type` at (row,col) would
  // immediately form a 3-in-a-row.
  // - `g`       : already-completed rows (for vertical check).
  // - `partial` : the current row being built (for horizontal check).
  bool _isInstantMatch(
    int row,
    int col,
    TileType type,
    List<List<TileModel>> g, [
    List<TileModel> partial = const [],
  ]) {
    // Vertical: rows row-1 and row-2 are already in g
    if (row >= 2 &&
        g[row - 1][col].type == type &&
        g[row - 2][col].type == type)
      return true;
    // Horizontal: use the partial row being built, not g[row] (which doesn't exist yet)
    if (col >= 2 &&
        partial.length >= 2 &&
        partial[col - 1].type == type &&
        partial[col - 2].type == type)
      return true;
    return false;
  }

  // ──────────────────────────────────────────────────────────────
  // Move detection
  // ──────────────────────────────────────────────────────────────
  bool hasPossibleMoves() {
    for (int r = 0; r < rows; r++) {
      for (int c = 0; c < cols; c++) {
        if (c < cols - 1 && _checkSwapPotential(r, c, r, c + 1)) return true;
        if (r < rows - 1 && _checkSwapPotential(r, c, r + 1, c)) return true;
      }
    }
    return false;
  }

  /// Returns the first valid hint move as {r1, c1, r2, c2} or null.
  ({int r1, int c1, int r2, int c2})? findHintMove() {
    for (int r = 0; r < rows; r++) {
      for (int c = 0; c < cols; c++) {
        if (c < cols - 1 && _checkSwapPotential(r, c, r, c + 1)) {
          return (r1: r, c1: c, r2: r, c2: c + 1);
        }
        if (r < rows - 1 && _checkSwapPotential(r, c, r + 1, c)) {
          return (r1: r, c1: c, r2: r + 1, c2: c);
        }
      }
    }
    return null;
  }

  bool _checkSwapPotential(int r1, int c1, int r2, int c2) {
    final t1 = grid[r1][c1].type;
    final t2 = grid[r2][c2].type;
    grid[r1][c1].type = t2;
    grid[r2][c2].type = t1;
    final has = _checkMatchAt(r1, c1) || _checkMatchAt(r2, c2);
    grid[r1][c1].type = t1;
    grid[r2][c2].type = t2;
    return has;
  }

  bool _checkMatchAt(int r, int c) {
    final type = grid[r][c].type;
    if (type == TileType.empty) return false;

    int h = 1;
    for (int i = c - 1; i >= 0 && grid[r][i].type == type; i--) h++;
    for (int i = c + 1; i < cols && grid[r][i].type == type; i++) h++;
    if (h >= 3) return true;

    int v = 1;
    for (int i = r - 1; i >= 0 && grid[i][c].type == type; i--) v++;
    for (int i = r + 1; i < rows && grid[i][c].type == type; i++) v++;
    return v >= 3;
  }

  // ──────────────────────────────────────────────────────────────
  // Swap
  // ──────────────────────────────────────────────────────────────
  Future<bool> swapTiles(int r1, int c1, int r2, int c2) async {
    if (isProcessing) return false;
    if ((r1 - r2).abs() + (c1 - c2).abs() != 1) return false;

    isProcessing = true;
    notifyListeners();

    // Perform swap
    final t1 = grid[r1][c1].type;
    final s1 = grid[r1][c1].special;
    final t2 = grid[r2][c2].type;
    final s2 = grid[r2][c2].special;
    grid[r1][c1].type = t2;
    grid[r1][c1].special = s2;
    grid[r2][c2].type = t1;
    grid[r2][c2].special = s1;
    notifyListeners();

    if (_hasAnyMatch()) {
      moves--;
      await processMatches();
      isProcessing = false;
      notifyListeners();

      // Check end conditions
      if (score >= targetScore) {
        _eventController.add(GameEvent(type: GameEventType.levelComplete));
      } else if (moves <= 0) {
        _eventController.add(GameEvent(type: GameEventType.gameOver));
      }
      return true;
    } else {
      // Invalid – snap back with delay
      await Future.delayed(const Duration(milliseconds: 280));
      grid[r1][c1].type = t1;
      grid[r1][c1].special = s1;
      grid[r2][c2].type = t2;
      grid[r2][c2].special = s2;
      isProcessing = false;
      notifyListeners();
      return false;
    }
  }

  // ──────────────────────────────────────────────────────────────
  // Match detection & processing
  // ──────────────────────────────────────────────────────────────
  bool _hasAnyMatch() {
    for (int r = 0; r < rows; r++) {
      for (int c = 0; c < cols; c++) {
        if (_checkMatchAt(r, c)) return true;
      }
    }
    return false;
  }

  Future<void> processMatches() async {
    int comboCount = 0;

    while (_hasAnyMatch()) {
      comboCount++;
      final toClear = List.generate(rows, (_) => List.filled(cols, false));

      // Mark all matching groups
      for (int r = 0; r < rows; r++) {
        for (int c = 0; c < cols; c++) {
          if (grid[r][c].type == TileType.empty) continue;
          final type = grid[r][c].type;

          // Horizontal run starting at (r,c)
          int hEnd = c;
          while (hEnd < cols && grid[r][hEnd].type == type) hEnd++;
          final hLen = hEnd - c;
          if (hLen >= 3) {
            for (int i = c; i < hEnd; i++) toClear[r][i] = true;
            if (hLen == 4)
              _createSpecial(r, c + hLen ~/ 2, type, SpecialType.lineHor);
            if (hLen >= 5)
              _createSpecial(r, c + hLen ~/ 2, type, SpecialType.colorBomb);
          }

          // Vertical run starting at (r,c)
          int vEnd = r;
          while (vEnd < rows && grid[vEnd][c].type == type) vEnd++;
          final vLen = vEnd - r;
          if (vLen >= 3) {
            for (int i = r; i < vEnd; i++) toClear[i][c] = true;
            if (vLen == 4)
              _createSpecial(r + vLen ~/ 2, c, type, SpecialType.lineVer);
            if (vLen >= 5)
              _createSpecial(r + vLen ~/ 2, c, type, SpecialType.colorBomb);
          }

          // L/T shape → bomb
          if (hLen >= 3 && vLen >= 3)
            _createSpecial(r, c, type, SpecialType.bomb);
        }
      }

      // Activate specials inside the clear zone
      for (int r = 0; r < rows; r++) {
        for (int c = 0; c < cols; c++) {
          if (toClear[r][c] && grid[r][c].special != SpecialType.none) {
            _activateSpecial(
              r,
              c,
              grid[r][c].special,
              grid[r][c].type,
              toClear,
            );
          }
        }
      }

      // Clear tiles
      int cleared = 0;
      for (int r = 0; r < rows; r++) {
        for (int c = 0; c < cols; c++) {
          if (toClear[r][c]) {
            // Emit particle event
            _eventController.add(
              GameEvent(
                type: GameEventType.match,
                position: Offset(c.toDouble(), r.toDouble()),
                data: grid[r][c].type,
              ),
            );
            grid[r][c].type = TileType.empty;
            grid[r][c].special = SpecialType.none;
            cleared++;
          }
        }
      }

      // Scoring
      final comboBonus = comboCount > 1 ? comboCount * 0.5 : 1.0;
      score += (cleared * 10 * comboBonus).round();

      // Juice events
      if (cleared >= 4 || comboCount > 1) {
        _eventController.add(GameEvent(type: GameEventType.shake));
        final msg = cleared >= 9
            ? 'INCREDIBLE!'
            : cleared >= 6
            ? 'AWESOME!'
            : comboCount > 1
            ? 'COMBO x$comboCount!'
            : 'GREAT!';
        _eventController.add(
          GameEvent(type: GameEventType.combo, message: msg),
        );
      }

      notifyListeners();
      await Future.delayed(const Duration(milliseconds: 350));

      await _applyGravity();
      await Future.delayed(const Duration(milliseconds: 280));
    }

    if (!hasPossibleMoves()) {
      _eventController.add(
        GameEvent(type: GameEventType.combo, message: 'SHUFFLING...'),
      );
      await Future.delayed(const Duration(milliseconds: 600));
      _shuffleInPlace();
      notifyListeners();
    }
  }

  // ──────────────────────────────────────────────────────────────
  // Special tile logic
  // ──────────────────────────────────────────────────────────────
  void _createSpecial(int r, int c, TileType type, SpecialType special) {
    grid[r][c].type = type;
    grid[r][c].special = special;
  }

  void _activateSpecial(
    int r,
    int c,
    SpecialType special,
    TileType type,
    List<List<bool>> toClear,
  ) {
    switch (special) {
      case SpecialType.bomb:
        for (int i = r - 1; i <= r + 1; i++) {
          for (int j = c - 1; j <= c + 1; j++) {
            if (i >= 0 && i < rows && j >= 0 && j < cols) toClear[i][j] = true;
          }
        }
        break;
      case SpecialType.cross:
        for (int i = 0; i < cols; i++) toClear[r][i] = true;
        for (int i = 0; i < rows; i++) toClear[i][c] = true;
        break;
      case SpecialType.lineHor:
        for (int i = 0; i < cols; i++) toClear[r][i] = true;
        break;
      case SpecialType.lineVer:
        for (int i = 0; i < rows; i++) toClear[i][c] = true;
        break;
      case SpecialType.colorBomb:
        for (int i = 0; i < rows; i++) {
          for (int j = 0; j < cols; j++) {
            if (grid[i][j].type == type) toClear[i][j] = true;
          }
        }
        break;
      default:
        break;
    }
  }

  // ──────────────────────────────────────────────────────────────
  // Gravity (tiles fall down to fill gaps)
  // ──────────────────────────────────────────────────────────────
  Future<void> _applyGravity() async {
    for (int c = 0; c < cols; c++) {
      int slot = rows - 1;
      for (int r = rows - 1; r >= 0; r--) {
        if (grid[r][c].type != TileType.empty) {
          if (slot != r) {
            grid[slot][c].type = grid[r][c].type;
            grid[slot][c].special = grid[r][c].special;
            grid[slot][c].isNew = false;
            grid[r][c].type = TileType.empty;
            grid[r][c].special = SpecialType.none;
          }
          slot--;
        }
      }
      // Fill new tiles from the top
      for (int r = slot; r >= 0; r--) {
        grid[r][c].type = _randomType();
        grid[r][c].special = SpecialType.none;
        grid[r][c].isNew = true;
      }
    }
    notifyListeners();
  }

  // ──────────────────────────────────────────────────────────────
  // Shuffle
  // ──────────────────────────────────────────────────────────────
  void _shuffleInPlace() {
    // Fisher-Yates on the flat list
    final flat = <TileType>[];
    for (int r = 0; r < rows; r++) {
      for (int c = 0; c < cols; c++) {
        flat.add(
          grid[r][c].type == TileType.empty ? _randomType() : grid[r][c].type,
        );
      }
    }
    for (int i = flat.length - 1; i > 0; i--) {
      final j = _random.nextInt(i + 1);
      final tmp = flat[i];
      flat[i] = flat[j];
      flat[j] = tmp;
    }
    int idx = 0;
    for (int r = 0; r < rows; r++) {
      for (int c = 0; c < cols; c++) {
        grid[r][c].type = flat[idx++];
        grid[r][c].special = SpecialType.none;
      }
    }
    // Ensure no starting matches after shuffle
    // Quick fix: re-init if still has instant matches
    for (int r = 0; r < rows; r++) {
      for (int c = 0; c < cols; c++) {
        while (_isInstantMatch(r, c, grid[r][c].type, grid)) {
          grid[r][c].type = _randomType();
        }
      }
    }
  }

  /// Public shuffle for the Shuffle booster button
  void debugShuffle() {
    if (isProcessing) return;
    _shuffleInPlace();
    notifyListeners();
  }

  @override
  void dispose() {
    _eventController.close();
    super.dispose();
  }
}
