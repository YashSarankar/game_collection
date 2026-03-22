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
  List<List<List<Color>>> history = [];
  int difficulty = 2; // Default Medium
  bool _isGameStarted = false;
  bool isGameOver = false;

  // Animation states
  int? pouringFromIndex;
  int? pouringToIndex;
  bool isPouring = false;
  Color? pouringColor;

  // Countdown state
  int _countdown = 3;
  bool _isCountingDown = false;
  Timer? _countdownTimer;

  HapticService? _hapticService;

  @override
  void initState() {
    super.initState();
    _initHaptic();
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
    setState(() {
      bottles = WaterSortLogic.generateLevel(difficulty);
      selectedIndex = null;
      history = [];
      isGameOver = false;
      isPouring = false;
      pouringFromIndex = null;
      pouringToIndex = null;
      _isGameStarted = true;
      _startCountdown();
    });
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

  void _saveState() {
    history.add(bottles.map((b) => List<Color>.from(b.stack)).toList());
  }

  void _undo() {
    if (history.isEmpty || isGameOver || _isCountingDown || isPouring) return;

    List<List<Color>> prev = history.removeLast();
    setState(() {
      for (int i = 0; i < bottles.length; i++) {
        bottles[i].stack = List.from(prev[i]);
      }
    });
    _hapticService?.light();
  }

  void _onBottleTap(int index) {
    if (isGameOver || _isCountingDown || isPouring) return;

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

  Future<void> _tryPour(int fromIdx, int toIdx) async {
    WaterSortBottle from = bottles[fromIdx];
    WaterSortBottle to = bottles[toIdx];

    if (WaterSortLogic.canPour(from, to)) {
      _saveState();
      
      Color pColor = from.topColor!;

      setState(() {
        isPouring = true;
        pouringFromIndex = fromIdx;
        pouringToIndex = toIdx;
        pouringColor = pColor;
      });

      _hapticService?.light();

      // Pour animation delay
      await Future.delayed(const Duration(milliseconds: 400));

      if (mounted) {
        setState(() {
          WaterSortLogic.pour(from, to);
          isPouring = false;
          pouringFromIndex = null;
          pouringToIndex = null;
        });

        if (WaterSortLogic.isWin(bottles)) {
          _endGame();
        }
      }
    } else {
      _hapticService?.error();
    }
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
            ? IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: _resetToMenu,
              )
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
                  child: Center(
                    child: SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 10,
                      ),
                      child: _buildBottlesGrid(),
                    ),
                  ),
                ),
                _buildControls(isDark),
                const SizedBox(height: 40),
              ],
            ),
          if (_isCountingDown) _buildCountdownOverlay(),
          if (isPouring && pouringFromIndex != null && pouringToIndex != null)
             _buildPouringAnimation(),
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
              size: 64,
              color: widget.game.primaryColor,
            ),
            const SizedBox(height: 16),
            const Text(
              'WATER SORT',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w900,
                letterSpacing: 4,
              ),
            ),
            const SizedBox(height: 40),
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
                padding: const EdgeInsets.only(bottom: 12),
                child: SizedBox(
                  width: 240,
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
                        borderRadius: BorderRadius.circular(20),
                      ),
                      elevation: 0,
                    ),
                    child: Text(
                      label,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.5,
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

  Widget _buildHeader(bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _buildStatBox(
            'LEVEL',
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
          _buildStatBox(
            'MOVES',
            '${history.length}',
            Colors.orange,
            isDark,
          ),
        ],
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
    return Wrap(
      spacing: 25,
      runSpacing: 40,
      alignment: WrapAlignment.center,
      children: List.generate(bottles.length, (index) => _buildBottle(index)),
    );
  }

  Widget _buildBottle(int index) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    bool isSelected = selectedIndex == index;
    bool isBeingPouredFrom = pouringFromIndex == index;
    WaterSortBottle bottle = bottles[index];

    return GestureDetector(
      onTap: () => _onBottleTap(index),
      child: TweenAnimationBuilder<double>(
        duration: const Duration(milliseconds: 300),
        tween: Tween(begin: 0.0, end: (isSelected || isBeingPouredFrom) ? -30.0 : 0.0),
        builder: (context, translateY, child) {
          double rotation = 0;
          if (isBeingPouredFrom) {
            rotation = 0.5; // Roughly 30 degrees
          }
          return Transform.translate(
            offset: Offset(0, translateY),
            child: Transform.rotate(
              angle: rotation,
              origin: const Offset(0, -60), // Rotate from top
              child: child,
            ),
          );
        },
        child: Stack(
          alignment: Alignment.bottomCenter,
          clipBehavior: Clip.none,
          children: [
            // Bottle Shape
            Container(
              width: 50,
              height: 140,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.05),
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(25),
                  bottomRight: Radius.circular(25),
                  topLeft: Radius.circular(10),
                  topRight: Radius.circular(10),
                ),
                border: Border.all(
                  color: isSelected
                      ? widget.game.primaryColor
                      : (isDark ? Colors.white24 : Colors.grey[300]!),
                  width: isSelected ? 3 : 2,
                ),
                boxShadow: isSelected ? [
                  BoxShadow(
                    color: widget.game.primaryColor.withOpacity(0.4),
                    blurRadius: 15,
                    spreadRadius: 2,
                  )
                ] : null,
              ),
              child: ClipRRect(
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(22),
                  bottomRight: Radius.circular(22),
                  topLeft: Radius.circular(8),
                  topRight: Radius.circular(8),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    for (int i = bottle.stack.length - 1; i >= 0; i--)
                      Expanded(
                        child: Container(
                          width: double.infinity,
                          margin: const EdgeInsets.symmetric(horizontal: 1, vertical: 0.5),
                          decoration: BoxDecoration(
                            color: bottle.stack[i],
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                bottle.stack[i].withOpacity(0.7),
                                bottle.stack[i],
                              ],
                            ),
                          ),
                        ),
                      ),
                    for (int i = 0; i < bottle.capacity - bottle.stack.length; i++)
                      Expanded(child: Container()),
                  ].reversed.toList(),
                ),
              ),
            ),
            // Glass Highlight
            Positioned(
              top: 15,
              left: 10,
              child: Container(
                width: 4,
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildControls(bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 40),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildActionButton(
            onPressed: _undo,
            icon: Icons.undo_rounded,
            label: 'UNDO',
            color: Colors.blueAccent,
            isDark: isDark,
          ),
          _buildActionButton(
            onPressed: _startNewGame,
            icon: Icons.refresh_rounded,
            label: 'RESET',
            color: widget.game.primaryColor,
            isDark: isDark,
          ),
        ],
      ),
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
              fontSize: 10,
              fontWeight: FontWeight.w900,
              color: isDark ? Colors.white70 : Colors.black87,
              letterSpacing: 1,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCountdownOverlay() {
    return Container(
      color: Colors.black.withOpacity(0.6),
      child: Center(
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 400),
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

  Widget _buildPouringAnimation() {
    // This is a simplified "stream" between bottles.
    // In a real production app, you'd calculate exact coordinates.
    // Here we'll just show a "pouring" state visually via bottle tilting.
    return const SizedBox.shrink(); // Tilting handled in _buildBottle
  }
}
