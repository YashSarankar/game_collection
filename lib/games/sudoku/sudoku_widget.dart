import 'dart:async';
import 'dart:math' show Point;
import 'package:flutter/material.dart';
import '../../core/models/game_model.dart';
import '../../core/services/haptic_service.dart';
import '../../ui/widgets/game_over_dialog.dart';
import 'sudoku_logic.dart';

class SudokuWidget extends StatefulWidget {
  final GameModel game;
  const SudokuWidget({super.key, required this.game});

  @override
  State<SudokuWidget> createState() => _SudokuWidgetState();
}

class _SudokuWidgetState extends State<SudokuWidget> {
  static const int size = 9;
  late List<List<int>> board;
  late List<List<int>> solution;
  late List<List<bool>> isInitial;
  late List<List<Set<int>>> notes;
  final Set<Point<int>> _conflicts = {};

  int? selectedRow;
  int? selectedCol;
  int mistakes = 0;
  bool isGameOver = false;
  bool isNotesMode = false;
  SudokuDifficulty difficulty = SudokuDifficulty.medium;

  final Stopwatch _stopwatch = Stopwatch();
  Timer? _timer;
  String _timeDisplay = "00:00";

  HapticService? _hapticService;
  List<BoardState> _history = [];

  // Countdown state
  int _countdown = 3;
  bool _isCountingDown = true;
  Timer? _countdownTimer;

  @override
  void initState() {
    super.initState();
    _initHaptic();
    _startNewGame();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _countdownTimer?.cancel();
    super.dispose();
  }

  Future<void> _initHaptic() async {
    _hapticService = await HapticService.getInstance();
  }

  void _startNewGame() {
    final generated = SudokuLogic.generate(difficulty: difficulty);
    board = generated['puzzle']!;
    solution = generated['solution']!;

    isInitial = List.generate(
      size,
      (r) => List.generate(size, (c) => board[r][c] != 0),
    );
    notes = List.generate(size, (r) => List.generate(size, (c) => {}));
    _conflicts.clear();

    mistakes = 0;
    isGameOver = false;
    selectedRow = null;
    selectedCol = null;
    _history = [];

    _resetTimer();
    _startCountdown();

    if (mounted) setState(() {});
  }

  void _startCountdown() {
    _isCountingDown = true;
    _countdown = 3;
    _countdownTimer?.cancel();
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          if (_countdown > 1) {
            _countdown--;
            _hapticService?.light();
          } else {
            _isCountingDown = false;
            _hapticService?.heavy();
            timer.cancel();
            _startTimer();
          }
        });
      }
    });
  }

  void _startTimer() {
    _timer?.cancel();
    _stopwatch.reset();
    _stopwatch.start();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted && !isGameOver) {
        setState(() {
          _timeDisplay = _formatTime(_stopwatch.elapsed);
        });
      }
    });
  }

  void _resetTimer() {
    _stopwatch.stop();
    _stopwatch.reset();
    _timeDisplay = "00:00";
  }

  String _formatTime(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, "0");
    String twoDigitMinutes = twoDigits(duration.inMinutes.remainder(60));
    String twoDigitSeconds = twoDigits(duration.inSeconds.remainder(60));
    return "$twoDigitMinutes:$twoDigitSeconds";
  }

  void _onCellTap(int r, int c) {
    if (isGameOver || _isCountingDown) return;
    _hapticService?.selectionClick();
    setState(() {
      selectedRow = r;
      selectedCol = c;
    });
  }

  void _onNumberButtonTap(int n) {
    if (selectedRow == null ||
        selectedCol == null ||
        isGameOver ||
        _isCountingDown)
      return;
    int r = selectedRow!;
    int c = selectedCol!;
    if (board[r][c] == n && !isNotesMode) return;
    if (isInitial[r][c]) return;

    _saveToHistory();

    if (isNotesMode) {
      setState(() {
        if (notes[r][c].contains(n)) {
          notes[r][c].remove(n);
        } else {
          notes[r][c].add(n);
        }
      });
      _hapticService?.light();
    } else {
      setState(() {
        board[r][c] = n;
        notes[r][c].clear();
        _updateConflicts();
        if (solution[r][c] == n) {
          _checkWin();
          _hapticService?.light();
        } else {
          mistakes++;
          if (mistakes >= 3) {
            _endGame(false);
          }
          _hapticService?.heavy();
        }
      });
    }
  }

  void _updateConflicts() {
    _conflicts.clear();
    for (int r = 0; r < size; r++) {
      for (int c = 0; c < size; c++) {
        if (board[r][c] != 0) {
          _conflicts.addAll(SudokuLogic.getConflicts(board, r, c, board[r][c]));
        }
      }
    }
  }

  void _eraseCell() {
    if (selectedRow == null ||
        selectedCol == null ||
        isGameOver ||
        _isCountingDown)
      return;
    int r = selectedRow!;
    int c = selectedCol!;
    if (isInitial[r][c]) return;

    _saveToHistory();
    setState(() {
      board[r][c] = 0;
      notes[r][c].clear();
      _updateConflicts();
    });
    _hapticService?.light();
  }

  void _undo() {
    if (_history.isEmpty || isGameOver || _isCountingDown) return;

    BoardState lastState = _history.removeLast();
    setState(() {
      board = lastState.board;
      notes = lastState.notes;
      _updateConflicts();
    });
    _hapticService?.light();
  }

  void _saveToHistory() {
    _history.add(
      BoardState(
        board: List.generate(size, (r) => List.from(board[r])),
        notes: List.generate(
          size,
          (r) => List.generate(size, (c) => Set.from(notes[r][c])),
        ),
      ),
    );
    if (_history.length > 20) _history.removeAt(0);
  }

  void _checkWin() {
    bool complete = true;
    for (int r = 0; r < size; r++) {
      for (int c = 0; c < size; c++) {
        if (board[r][c] != solution[r][c]) {
          complete = false;
          break;
        }
      }
    }
    if (complete) _endGame(true);
  }

  void _endGame(bool won) {
    isGameOver = true;
    _stopwatch.stop();
    if (won) _hapticService?.success();

    int finalScore = won
        ? (1000 - mistakes * 100 - (_stopwatch.elapsed.inSeconds ~/ 2))
        : 0;
    if (finalScore < 0) finalScore = 10;

    Future.delayed(const Duration(milliseconds: 500), () {
      if (!mounted) return;
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => GameOverDialog(
          gameId: widget.game.id,
          score: finalScore,
          customMessage: won
              ? "Sudoku Solved!\nDifficulty: ${_difficultyLabel(difficulty)}\nTime: $_timeDisplay"
              : "Game Over\n3 Mistakes reached",
          onRestart: () {
            Navigator.pop(context);
            _startNewGame();
          },
          onHome: () {
            Navigator.pop(context);
            Navigator.pop(context);
          },
        ),
      );
    });
  }

  String _difficultyLabel(SudokuDifficulty d) {
    return d.name[0].toUpperCase() + d.name.substring(1);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = widget.game.primaryColor;
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          widget.game.title,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: theme.scaffoldBackgroundColor,
        foregroundColor: isDark ? Colors.white : color,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _startNewGame,
            color: isDark ? Colors.white : color,
          ),
        ],
      ),
      body: SafeArea(
        child: Stack(
          children: [
            Column(
              children: [
                _buildInfoBar(color, theme),
                const Spacer(),
                _buildSudokuGrid(color, theme),
                const Spacer(),
                _buildTools(color, theme),
                const SizedBox(height: 10),
                _buildNumberPad(color, theme),
                const SizedBox(height: 20),
              ],
            ),
            if (_isCountingDown) _buildCountdownOverlay(),
          ],
        ),
      ),
    );
  }

  Widget _buildCountdownOverlay() {
    return Container(
      color: Colors.black.withOpacity(0.7),
      child: Center(
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 500),
          transitionBuilder: (Widget child, Animation<double> animation) {
            return ScaleTransition(scale: animation, child: child);
          },
          child: Text(
            '$_countdown',
            key: ValueKey<int>(_countdown),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 120,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInfoBar(Color color, ThemeData theme) {
    final isDark = theme.brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _buildStatBox(
            'MISTAKES',
            '$mistakes / 3',
            mistakes > 0
                ? Colors.redAccent
                : (isDark ? Colors.white : Colors.black),
            isDark,
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            height: 36,
            decoration: BoxDecoration(
              color: isDark ? Colors.white.withOpacity(0.05) : Colors.grey[100],
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: isDark ? Colors.white10 : Colors.grey[300]!,
                width: 1,
              ),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<SudokuDifficulty>(
                value: difficulty,
                icon: Icon(
                  Icons.keyboard_arrow_down,
                  size: 18,
                  color: isDark ? Colors.white70 : color,
                ),
                iconEnabledColor: isDark ? Colors.white : color,
                dropdownColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                borderRadius: BorderRadius.circular(12),
                style: TextStyle(
                  color: isDark ? Colors.white : color,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
                items: SudokuDifficulty.values.map((d) {
                  return DropdownMenuItem(
                    value: d,
                    child: Text(_difficultyLabel(d).toUpperCase()),
                  );
                }).toList(),
                onChanged: (val) {
                  if (val != null) {
                    setState(() {
                      difficulty = val;
                      _startNewGame();
                    });
                  }
                },
              ),
            ),
          ),
          _buildStatBox(
            'TIME',
            _timeDisplay,
            isDark ? Colors.white : Colors.black,
            isDark,
          ),
        ],
      ),
    );
  }

  Widget _buildStatBox(
    String label,
    String value,
    Color textColor,
    bool isDark,
  ) {
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(
            color: isDark ? Colors.white54 : Colors.grey[600],
            fontSize: 10,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.2,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(
            color: textColor,
            fontSize: 20,
            fontWeight: FontWeight.bold,
            fontFamily: 'monospace',
          ),
        ),
      ],
    );
  }

  Widget _buildSudokuGrid(Color color, ThemeData theme) {
    double gridSize = MediaQuery.of(context).size.width - 24;
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      width: gridSize,
      height: gridSize,
      margin: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        border: Border.all(
          color: isDark ? theme.dividerColor : Colors.black,
          width: 2,
        ),
        color: isDark ? theme.dividerColor : Colors.black,
      ),
      child: GridView.builder(
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: size,
          crossAxisSpacing: 0,
          mainAxisSpacing: 0,
        ),
        itemCount: 81,
        itemBuilder: (context, index) =>
            _buildCell(index ~/ 9, index % 9, color, theme),
      ),
    );
  }

  Widget _buildCell(int r, int c, Color color, ThemeData theme) {
    final isDark = theme.brightness == Brightness.dark;
    bool isSelected = selectedRow == r && selectedCol == c;
    bool inSelectedRow = selectedRow == r;
    bool inSelectedCol = selectedCol == c;
    bool inSelectedBox =
        (selectedRow != null && selectedCol != null) &&
        (r ~/ 3 == selectedRow! ~/ 3 && c ~/ 3 == selectedCol! ~/ 3);

    int value = board[r][c];
    int selectedValue = (selectedRow != null && selectedCol != null)
        ? board[selectedRow!][selectedCol!]
        : 0;

    bool isSameValue = value != 0 && value == selectedValue;
    bool isInitialCell = isInitial[r][c];
    bool isError = value != 0 && value != solution[r][c];
    bool inConflict = _conflicts.contains(Point(r, c));

    BorderSide bold = BorderSide(
      color: isDark ? theme.dividerColor : Colors.black,
      width: 1.5,
    );
    BorderSide slim = BorderSide(
      color: isDark ? Colors.white10 : Colors.grey[300]!,
      width: 0.5,
    );

    return GestureDetector(
      onTap: () => _onCellTap(r, c),
      child: Container(
        decoration: BoxDecoration(
          color: _getBoxColor(
            isSelected,
            inSelectedRow,
            inSelectedCol,
            inSelectedBox,
            isSameValue,
            isError,
            inConflict,
            color,
            theme,
          ),
          border: Border(
            right: (c == 2 || c == 5) ? bold : slim,
            bottom: (r == 2 || r == 5) ? bold : slim,
          ),
        ),
        child: Center(
          child: value != 0
              ? Text(
                  '$value',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: isInitialCell
                        ? FontWeight.bold
                        : FontWeight.normal,
                    color: _getTextColor(
                      isInitialCell,
                      isError,
                      inConflict,
                      color,
                      isDark,
                    ),
                  ),
                )
              : _buildNotes(r, c, isDark),
        ),
      ),
    );
  }

  Color _getBoxColor(
    bool isSelected,
    bool row,
    bool col,
    bool box,
    bool same,
    bool error,
    bool conflict,
    Color color,
    ThemeData theme,
  ) {
    final isDark = theme.brightness == Brightness.dark;
    if (isSelected) return color.withOpacity(0.4);
    if (error || conflict) return Colors.red.withOpacity(0.2);
    if (same) return color.withOpacity(0.3);
    if (row || col || box) return color.withOpacity(0.12);
    return isDark ? Colors.black : Colors.white;
  }

  Color _getTextColor(
    bool initial,
    bool error,
    bool conflict,
    Color color,
    bool isDark,
  ) {
    if (error || conflict) return Colors.redAccent;
    if (initial) return isDark ? Colors.white : Colors.black;
    return isDark ? color.withOpacity(0.9) : color;
  }

  Widget _buildNotes(int r, int c, bool isDark) {
    Set<int> cellNotes = notes[r][c];
    if (cellNotes.isEmpty) return const SizedBox.shrink();

    return GridView.builder(
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
      ),
      itemCount: 9,
      itemBuilder: (context, index) {
        int n = index + 1;
        return Center(
          child: Text(
            cellNotes.contains(n) ? '$n' : '',
            style: TextStyle(
              fontSize: 10,
              color: isDark ? Colors.white54 : Colors.grey[600],
            ),
          ),
        );
      },
    );
  }

  Widget _buildTools(Color color, ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildToolButton(Icons.undo, "Undo", _undo, color, theme),
          _buildToolButton(
            Icons.delete_outline,
            "Erase",
            _eraseCell,
            color,
            theme,
          ),
          _buildToolButton(
            isNotesMode ? Icons.edit : Icons.edit_outlined,
            "Notes",
            () => setState(() => isNotesMode = !isNotesMode),
            color,
            theme,
            isActive: isNotesMode,
          ),
          _buildToolButton(
            Icons.lightbulb_outline,
            "Hint",
            _useHint,
            color,
            theme,
          ),
        ],
      ),
    );
  }

  Widget _buildToolButton(
    IconData icon,
    String label,
    VoidCallback onTap,
    Color color,
    ThemeData theme, {
    bool isActive = false,
  }) {
    final isDark = theme.brightness == Brightness.dark;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          children: [
            Icon(
              icon,
              size: 28,
              color: isActive
                  ? (isDark ? Colors.white : color)
                  : (isDark ? Colors.white70 : Colors.grey[700]),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: isActive
                    ? (isDark ? Colors.white : color)
                    : (isDark ? Colors.white70 : Colors.grey[700]),
                fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _useHint() {
    if (selectedRow == null ||
        selectedCol == null ||
        isGameOver ||
        _isCountingDown)
      return;
    int r = selectedRow!;
    int c = selectedCol!;
    if (board[r][c] == solution[r][c]) return;

    _saveToHistory();
    setState(() {
      board[r][c] = solution[r][c];
      notes[r][c].clear();
      _updateConflicts();
      _checkWin();
    });
    _hapticService?.light();
  }

  Widget _buildNumberPad(Color color, ThemeData theme) {
    final isDark = theme.brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: List.generate(9, (index) {
          int n = index + 1;
          return Expanded(
            child: GestureDetector(
              onTap: () => _onNumberButtonTap(n),
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 4),
                height: 50,
                decoration: BoxDecoration(
                  color: isDark
                      ? Colors.white.withOpacity(0.1)
                      : Colors.grey[100],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Center(
                  child: Text(
                    '$n',
                    style: TextStyle(
                      fontSize: 24,
                      color: isDark ? Colors.white : color,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}

class BoardState {
  final List<List<int>> board;
  final List<List<Set<int>>> notes;
  BoardState({required this.board, required this.notes});
}
