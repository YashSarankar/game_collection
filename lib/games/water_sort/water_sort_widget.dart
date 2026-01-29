import 'dart:async';
import 'package:flutter/material.dart';
import '../../core/models/game_model.dart';
import '../../core/services/haptic_service.dart';
import '../../ui/widgets/game_over_dialog.dart';
import 'water_sort_logic.dart';

class WaterSortWidget extends StatefulWidget {
  final GameModel game;
  const WaterSortWidget({super.key, required this.game});

  @override
  State<WaterSortWidget> createState() => _WaterSortWidgetState();
}

class _WaterSortWidgetState extends State<WaterSortWidget>
    with TickerProviderStateMixin {
  late List<WaterSortBottle> bottles;
  int? selectedIndex;
  List<WaterSortMove> history = [];
  int difficulty = 2; // Default Medium
  bool _isGameStarted = false;
  bool isGameOver = false;

  // Countdown state
  int _countdown = 3;
  bool _isCountingDown = true;
  Timer? _countdownTimer;

  HapticService? _hapticService;

  @override
  void initState() {
    super.initState();
    _initHaptic();
    // Don't call _startNewGame immediately, wait for user selection
    _isCountingDown = false;
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    super.dispose();
  }

  Future<void> _initHaptic() async {
    _hapticService = await HapticService.getInstance();
  }

  void _startNewGame() {
    bottles = WaterSortLogic.generateLevel(difficulty);
    selectedIndex = null;
    history = [];
    isGameOver = false;
    _isGameStarted = true;
    _startCountdown();
    if (mounted) setState(() {});
  }

  void _resetToMenu() {
    setState(() {
      _isGameStarted = false;
      isGameOver = false;
      _isCountingDown = false;
    });
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
          }
        });
      }
    });
  }

  void _onBottleTap(int index) {
    if (isGameOver || _isCountingDown) return;

    _hapticService?.selectionClick();

    setState(() {
      if (selectedIndex == null) {
        if (!bottles[index].isEmpty) {
          selectedIndex = index;
        }
      } else {
        if (selectedIndex == index) {
          selectedIndex = null;
        } else {
          _tryPour(selectedIndex!, index);
          selectedIndex = null;
        }
      }
    });
  }

  void _tryPour(int fromIdx, int toIdx) {
    WaterSortBottle from = bottles[fromIdx];
    WaterSortBottle to = bottles[toIdx];

    if (WaterSortLogic.canPour(from, to)) {
      int amount = WaterSortLogic.calculatePourAmount(from, to);
      List<Color> colorsPoured = [];

      setState(() {
        for (int i = 0; i < amount; i++) {
          colorsPoured.add(from.layers.removeLast());
        }
        for (int i = colorsPoured.length - 1; i >= 0; i--) {
          to.layers.add(colorsPoured[i]);
        }
        history.add(
          WaterSortMove(
            fromIndex: fromIdx,
            toIndex: toIdx,
            colorsPoured: colorsPoured,
          ),
        );
      });

      _hapticService?.light();

      if (WaterSortLogic.isWin(bottles)) {
        _endGame();
      }
    } else {
      _hapticService?.error();
      // Visual feedback for invalid move could be added here (e.g., shake animation)
    }
  }

  void _undo() {
    if (history.isEmpty || isGameOver || _isCountingDown) return;

    WaterSortMove lastMove = history.removeLast();
    setState(() {
      for (int i = 0; i < lastMove.colorsPoured.length; i++) {
        bottles[lastMove.toIndex].layers.removeLast();
      }
      for (int i = lastMove.colorsPoured.length - 1; i >= 0; i--) {
        bottles[lastMove.fromIndex].layers.add(lastMove.colorsPoured[i]);
      }
    });
    _hapticService?.light();
  }

  void _endGame() {
    isGameOver = true;
    _hapticService?.success();

    int finalScore = 500 + (difficulty * 100);

    Future.delayed(const Duration(milliseconds: 600), () {
      if (!mounted) return;
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => GameOverDialog(
          gameId: widget.game.id,
          score: finalScore,
          customMessage: "All colors sorted!",
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          widget.game.title,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: isDark ? Colors.white : Colors.black,
        leading: (_isGameStarted && !isGameOver)
            ? const SizedBox.shrink()
            : IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () => Navigator.pop(context),
              ),
        actions: _isGameStarted
            ? [
                IconButton(
                  icon: const Icon(Icons.refresh),
                  onPressed: _startNewGame,
                ),
                IconButton(
                  icon: const Icon(Icons.menu),
                  onPressed: _resetToMenu,
                ),
              ]
            : null,
      ),
      body: Stack(
        children: [
          if (!_isGameStarted)
            _buildLevelSelection(isDark)
          else
            Column(
              children: [
                _buildHeader(isDark),
                Expanded(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 10,
                    ),
                    child: _buildBottlesGrid(),
                  ),
                ),
                const SizedBox(height: 10),
                _buildControls(isDark),
                const SizedBox(height: 20),
                _buildSpecialTools(isDark),
                const SizedBox(height: 40),
              ],
            ),
          if (_isCountingDown) _buildCountdownOverlay(),
        ],
      ),
    );
  }

  Widget _buildLevelSelection(bool isDark) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.opacity_rounded,
              size: 60,
              color: widget.game.primaryColor,
            ),
            const SizedBox(height: 16),
            const Text(
              'SELECT DIFFICULTY',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w900,
                letterSpacing: 2,
              ),
            ),
            const SizedBox(height: 20),
            ...[1, 2, 3, 4, 5].map((d) {
              final label = [
                'EASY',
                'MEDIUM',
                'HARD',
                'EXPERT',
                'BRUTAL',
              ][d - 1];
              final isDiff = difficulty == d;
              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: SizedBox(
                  width: double.infinity,
                  height: 54,
                  child: ElevatedButton(
                    onPressed: () {
                      _hapticService?.light();
                      setState(() {
                        difficulty = d;
                        _startNewGame();
                      });
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isDiff
                          ? widget.game.primaryColor
                          : (isDark ? Colors.white10 : Colors.grey[200]),
                      foregroundColor: isDiff
                          ? Colors.white
                          : (isDark ? Colors.white70 : Colors.black87),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                        side: BorderSide(
                          color: isDiff ? Colors.white24 : Colors.transparent,
                        ),
                      ),
                      elevation: 0,
                    ),
                    child: Text(
                      label,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1,
                      ),
                    ),
                  ),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildSpecialTools(bool isDark) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        ElevatedButton.icon(
          onPressed: _addHiddenBottle,
          icon: const Icon(Icons.add_circle_outline, color: Colors.white),
          label: const Text(
            'EXTRA BOTTLE',
            style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.orange[800],
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
          ),
        ),
      ],
    );
  }

  void _addHiddenBottle() {
    if (isGameOver || _isCountingDown) return;

    // Simulate rewarded ad check or cost
    setState(() {
      bottles.add(WaterSortBottle(layers: []));
      _hapticService?.heavy();
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Extra Bottle Added!'),
        duration: Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Widget _buildHeader(bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _buildStatBox(
            'DIFFICULTY',
            [
              'Easy',
              'Medium',
              'Hard',
              'Expert',
              'Brutal',
            ][difficulty - 1].toUpperCase(),
            widget.game.primaryColor,
            isDark,
          ),
          _buildDifficultySelector(isDark),
        ],
      ),
    );
  }

  Widget _buildDifficultySelector(bool isDark) {
    return Container(
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
        child: DropdownButton<int>(
          value: difficulty,
          icon: Icon(
            Icons.keyboard_arrow_down,
            size: 18,
            color: isDark ? Colors.white70 : widget.game.primaryColor,
          ),
          dropdownColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          style: TextStyle(
            color: isDark ? Colors.white : widget.game.primaryColor,
            fontWeight: FontWeight.bold,
            fontSize: 12,
          ),
          items: [1, 2, 3, 4, 5].map((d) {
            return DropdownMenuItem(
              value: d,
              child: Text(['EASY', 'MED', 'HARD', 'EXPERT', 'BRUTAL'][d - 1]),
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
    );
  }

  Widget _buildStatBox(String label, String value, Color color, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
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
        Text(
          value,
          style: TextStyle(
            color: color,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildBottlesGrid() {
    int crossAxisCount = bottles.length > 8 ? 4 : 3;
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        childAspectRatio: 0.5,
        crossAxisSpacing: 20,
        mainAxisSpacing: 30,
      ),
      itemCount: bottles.length,
      itemBuilder: (context, index) {
        return _buildBottle(index);
      },
    );
  }

  Widget _buildBottle(int index) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    bool isSelected = selectedIndex == index;
    WaterSortBottle bottle = bottles[index];

    return GestureDetector(
      onTap: () => _onBottleTap(index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        transform: Matrix4.translationValues(0, isSelected ? -20 : 0, 0),
        child: Stack(
          alignment: Alignment.bottomCenter,
          children: [
            // Bottle Shape
            Container(
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.1),
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(20),
                  bottomRight: Radius.circular(20),
                  topLeft: Radius.circular(8),
                  topRight: Radius.circular(8),
                ),
                border: Border.all(
                  color: isSelected
                      ? widget.game.primaryColor
                      : (bottle.isEmpty
                            ? (isDark ? Colors.white38 : Colors.grey[400]!)
                            : (isDark ? Colors.white24 : Colors.grey[300]!)),
                  width: bottle.isEmpty ? 2.5 : 2,
                ),
              ),
              child: ClipRRect(
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(17),
                  bottomRight: Radius.circular(17),
                  topLeft: Radius.circular(5),
                  topRight: Radius.circular(5),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    for (
                      int i = 0;
                      i < bottle.capacity - bottle.layers.length;
                      i++
                    )
                      Expanded(child: Container()),
                    for (int i = bottle.layers.length - 1; i >= 0; i--)
                      Expanded(
                        child: Container(
                          width: double.infinity,
                          margin: const EdgeInsets.all(1),
                          decoration: BoxDecoration(
                            color:
                                (bottle.isMystery &&
                                    i < bottle.layers.length - 1)
                                ? Colors.grey[800]
                                : bottle.layers[i],
                            borderRadius: BorderRadius.circular(4),
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors:
                                  (bottle.isMystery &&
                                      i < bottle.layers.length - 1)
                                  ? [Colors.grey[700]!, Colors.grey[800]!]
                                  : [
                                      bottle.layers[i].withOpacity(0.8),
                                      bottle.layers[i],
                                    ],
                            ),
                          ),
                          child:
                              (bottle.isMystery && i < bottle.layers.length - 1)
                              ? const Center(
                                  child: Text(
                                    '?',
                                    style: TextStyle(
                                      color: Colors.white24,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                                )
                              : null,
                        ),
                      ),
                  ],
                ),
              ),
            ),
            // Glass reflection
            Positioned(
              top: 10,
              left: 8,
              width: 4,
              height: 40,
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            if (bottle.isEmpty)
              Positioned(
                top: 20,
                child: Text(
                  'EMPTY',
                  style: TextStyle(
                    fontSize: 8,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white10 : Colors.grey[200],
                    letterSpacing: 1,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildControls(bool isDark) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _buildActionButton(
          onPressed: _undo,
          icon: Icons.undo_rounded,
          label: 'Undo',
          color: Colors.grey,
          isDark: isDark,
        ),
        const SizedBox(width: 40),
        _buildActionButton(
          onPressed: _startNewGame,
          icon: Icons.refresh_rounded,
          label: 'Reset',
          color: widget.game.primaryColor,
          isDark: isDark,
        ),
      ],
    );
  }

  Widget _buildActionButton({
    required VoidCallback onPressed,
    required IconData icon,
    required String label,
    required Color color,
    required bool isDark,
  }) {
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(16),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              shape: BoxShape.circle,
              border: Border.all(color: color.withOpacity(0.3)),
            ),
            child: Icon(icon, color: color, size: 28),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white70 : Colors.black87,
            ),
          ),
        ],
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
}
