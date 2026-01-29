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

  @override
  void initState() {
    super.initState();
    _initHaptic();
    _startNewGame();
  }

  @override
  void dispose() {
    _timer?.cancel();
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
    _startTimer();

    if (mounted) setState(() {});
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
    if (isGameOver) return;
    _hapticService?.selectionClick();
    setState(() {
      selectedRow = r;
      selectedCol = c;
    });
  }

  void _onNumberButtonTap(int n) {
    if (selectedRow == null || selectedCol == null || isGameOver) return;
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
    if (selectedRow == null || selectedCol == null || isGameOver) return;
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
    if (_history.isEmpty || isGameOver) return;

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
    final color = widget.game.primaryColor;
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(
          widget.game.title,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        foregroundColor: color,
        elevation: 0,
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _startNewGame),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            _buildInfoBar(color),
            const Spacer(),
            _buildSudokuGrid(color),
            const Spacer(),
            _buildTools(color),
            const SizedBox(height: 10),
            _buildNumberPad(color),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoBar(Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Mistakes: $mistakes / 3',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: mistakes > 0 ? Colors.redAccent : Colors.grey[600],
                ),
              ),
              DropdownButton<SudokuDifficulty>(
                value: difficulty,
                underline: Container(),
                iconEnabledColor: color,
                style: TextStyle(color: color, fontWeight: FontWeight.bold),
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
            ],
          ),
          Text(
            _timeDisplay,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              fontFamily: 'monospace',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSudokuGrid(Color color) {
    double gridSize = MediaQuery.of(context).size.width - 24;
    return Container(
      width: gridSize,
      height: gridSize,
      margin: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.black, width: 2),
        color: Colors.black,
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
            _buildCell(index ~/ 9, index % 9, color),
      ),
    );
  }

  Widget _buildCell(int r, int c, Color color) {
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

    BorderSide bold = const BorderSide(color: Colors.black, width: 1.5);
    BorderSide slim = BorderSide(color: Colors.grey[300]!, width: 0.5);

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
                    ),
                  ),
                )
              : _buildNotes(r, c),
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
  ) {
    if (isSelected) return color.withOpacity(0.4);
    if (error || conflict) return Colors.red.withOpacity(0.15);
    if (same) return color.withOpacity(0.25);
    if (row || col || box) return color.withOpacity(0.08);
    return Colors.white;
  }

  Color _getTextColor(bool initial, bool error, bool conflict, Color color) {
    if (error || conflict) return Colors.red;
    if (initial) return Colors.black;
    return color;
  }

  Widget _buildNotes(int r, int c) {
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
            style: TextStyle(fontSize: 10, color: Colors.grey[600]),
          ),
        );
      },
    );
  }

  Widget _buildTools(Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildToolButton(Icons.undo, "Undo", _undo, color),
          _buildToolButton(Icons.delete_outline, "Erase", _eraseCell, color),
          _buildToolButton(
            isNotesMode ? Icons.edit : Icons.edit_outlined,
            "Notes",
            () => setState(() => isNotesMode = !isNotesMode),
            color,
            isActive: isNotesMode,
          ),
          _buildToolButton(Icons.lightbulb_outline, "Hint", _useHint, color),
        ],
      ),
    );
  }

  Widget _buildToolButton(
    IconData icon,
    String label,
    VoidCallback onTap,
    Color color, {
    bool isActive = false,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          children: [
            Icon(icon, size: 28, color: isActive ? color : Colors.grey[700]),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: isActive ? color : Colors.grey[700],
                fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _useHint() {
    if (selectedRow == null || selectedCol == null || isGameOver) return;
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

  Widget _buildNumberPad(Color color) {
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
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Center(
                  child: Text(
                    '$n',
                    style: TextStyle(
                      fontSize: 24,
                      color: color,
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
