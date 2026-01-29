import 'dart:math';

enum SudokuDifficulty { easy, medium, hard, expert }

class SudokuLogic {
  static const int size = 9;
  static const int boxSize = 3;

  /// Generates a new Sudoku board and its solution
  /// Returns a Map with 'puzzle' and 'solution'
  static Map<String, List<List<int>>> generate({
    SudokuDifficulty difficulty = SudokuDifficulty.medium,
  }) {
    List<List<int>> board = List.generate(size, (_) => List.filled(size, 0));

    // Fill the board
    _solve(board);

    // Copy the solution
    List<List<int>> solution = List.generate(size, (r) => List.from(board[r]));

    // Remove numbers based on difficulty
    int cellsToRemove;
    switch (difficulty) {
      case SudokuDifficulty.easy:
        cellsToRemove = 35;
        break;
      case SudokuDifficulty.medium:
        cellsToRemove = 45;
        break;
      case SudokuDifficulty.hard:
        cellsToRemove = 55;
        break;
      case SudokuDifficulty.expert:
        cellsToRemove = 62;
        break;
    }

    _removeCells(board, cellsToRemove);

    return {'puzzle': board, 'solution': solution};
  }

  static bool _solve(List<List<int>> board) {
    for (int row = 0; row < size; row++) {
      for (int col = 0; col < size; col++) {
        if (board[row][col] == 0) {
          List<int> numbers = [1, 2, 3, 4, 5, 6, 7, 8, 9]..shuffle();
          for (int num in numbers) {
            if (isValid(board, row, col, num)) {
              board[row][col] = num;
              if (_solve(board)) return true;
              board[row][col] = 0;
            }
          }
          return false;
        }
      }
    }
    return true;
  }

  static bool isValid(List<List<int>> board, int row, int col, int num) {
    // Check row
    for (int x = 0; x < size; x++) {
      if (board[row][x] == num) return false;
    }

    // Check column
    for (int x = 0; x < size; x++) {
      if (board[x][col] == num) return false;
    }

    // Check box
    int startRow = row - row % boxSize;
    int startCol = col - col % boxSize;
    for (int i = 0; i < boxSize; i++) {
      for (int j = 0; j < boxSize; j++) {
        if (board[i + startRow][j + startCol] == num) return false;
      }
    }

    return true;
  }

  static void _removeCells(List<List<int>> board, int remainingToRemove) {
    List<Point<int>> positions = [];
    for (int r = 0; r < size; r++) {
      for (int c = 0; c < size; c++) {
        positions.add(Point(r, c));
      }
    }
    positions.shuffle();

    int removed = 0;
    for (var pos in positions) {
      if (removed >= remainingToRemove) break;

      int r = pos.x;
      int c = pos.y;
      int temp = board[r][c];
      board[r][c] = 0;

      if (_countSolutions(board) != 1) {
        board[r][c] = temp;
      } else {
        removed++;
      }
    }
  }

  static int _countSolutions(List<List<int>> board, {int limit = 2}) {
    int count = 0;

    void solve(List<List<int>> b) {
      if (count >= limit) return;

      int row = -1;
      int col = -1;
      bool found = false;

      for (int i = 0; i < size; i++) {
        for (int j = 0; j < size; j++) {
          if (b[i][j] == 0) {
            row = i;
            col = j;
            found = true;
            break;
          }
        }
        if (found) break;
      }

      if (!found) {
        count++;
        return;
      }

      for (int num = 1; num <= 9; num++) {
        if (isValid(b, row, col, num)) {
          b[row][col] = num;
          solve(b);
          b[row][col] = 0;
          if (count >= limit) return;
        }
      }
    }

    List<List<int>> copy = List.generate(size, (r) => List.from(board[r]));
    solve(copy);
    return count;
  }

  /// Checks if the board is valid according to Sudoku rules
  static bool isBoardValid(List<List<int>> board) {
    for (int r = 0; r < size; r++) {
      for (int c = 0; c < size; c++) {
        int val = board[r][c];
        if (val != 0) {
          board[r][c] = 0;
          if (!isValid(board, r, c, val)) {
            board[r][c] = val;
            return false;
          }
          board[r][c] = val;
        }
      }
    }
    return true;
  }

  /// Find conflicts for a specific cell
  static Set<Point<int>> getConflicts(
    List<List<int>> board,
    int row,
    int col,
    int num,
  ) {
    Set<Point<int>> conflicts = {};
    if (num == 0) return conflicts;

    // Row
    for (int x = 0; x < size; x++) {
      if (x != col && board[row][x] == num) {
        conflicts.add(Point(row, x));
      }
    }

    // Column
    for (int x = 0; x < size; x++) {
      if (x != row && board[x][col] == num) {
        conflicts.add(Point(x, col));
      }
    }

    // Box
    int startRow = row - row % boxSize;
    int startCol = col - col % boxSize;
    for (int i = 0; i < boxSize; i++) {
      for (int j = 0; j < boxSize; j++) {
        int r = i + startRow;
        int c = j + startCol;
        if ((r != row || c != col) && board[r][c] == num) {
          conflicts.add(Point(r, c));
        }
      }
    }

    return conflicts;
  }
}
