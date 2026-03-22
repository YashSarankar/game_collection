import 'package:flutter/material.dart';
import '../controllers/game_controller.dart';
import '../widgets/board_widget.dart';
import '../widgets/life_bar.dart';
import '../arrows_theme.dart';

import 'level_complete_screen.dart';
import 'game_over_screen.dart';
import 'collection_screen.dart';

class GameScreen extends StatefulWidget {
  final GameController controller;
  final VoidCallback onBack;

  const GameScreen({
    Key? key,
    required this.controller,
    required this.onBack,
  }) : super(key: key);

  @override
  _GameScreenState createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  bool _showGrid = false;

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onGameStateChanged);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onGameStateChanged);
    super.dispose();
  }

  void _onGameStateChanged() {
    if (mounted) setState(() {});
    
    // Check win/loss conditions
    if (widget.controller.isLevelComplete) {
      _showLevelCompleteOverlay();
    } else if (widget.controller.isGameOver) {
      _showGameOverOverlay();
    }
  }

  void _showLevelCompleteOverlay() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => LevelCompleteScreen(
        currentLevelNum: widget.controller.currentLevelNum,
        onNextLevel: () {
          Navigator.pop(context);
          widget.controller.nextLevel();
        },
        onCollection: () {
          Navigator.pop(context);
          _showCollection();
        },
        onMenu: () {
          Navigator.pop(context);
          widget.onBack();
        },
      ),
    );
  }

  void _showCollection() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CollectionScreen(
          controller: widget.controller,
          onSelect: () {
             Navigator.pop(context);
             setState(() {});
          },
        ),
      ),
    );
  }

  void _showGameOverOverlay() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => GameOverScreen(
        onMenu: () {
          Navigator.pop(context);
          widget.onBack();
        },
        onRetry: () {
          Navigator.pop(context);
          widget.controller.restartLevel();
        },
        onCollection: () {
          Navigator.pop(context);
          _showCollection();
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (widget.controller.currentLevel == null) {
      return const Scaffold(
        backgroundColor: ArrowsTheme.background,
        body: Center(child: CircularProgressIndicator(color: ArrowsTheme.primaryButton)),
      );
    }

    final level = widget.controller.currentLevel!;
    
    return Scaffold(
      backgroundColor: ArrowsTheme.background,
      floatingActionButton: FloatingActionButton(
        onPressed: () => setState(() => _showGrid = !_showGrid),
        backgroundColor: ArrowsTheme.primaryButton,
        child: const Icon(Icons.grid_on_rounded, color: Colors.white),
      ),
      body: SafeArea(
        child: Column(
          children: [
            // TOP BAR
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 20.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    icon: const Icon(Icons.grid_view_rounded, color: ArrowsTheme.textPrimary),
                    onPressed: _showCollection,
                  ),
                  Column(
                    children: [
                      Text(
                        'LEVEL ${level.id}',
                        style: const TextStyle(
                          color: ArrowsTheme.textPrimary,
                          fontSize: 24,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 2,
                        ),
                      ),
                      const SizedBox(height: 4),
                      LifeBar(lives: widget.controller.lives),
                    ],
                  ),
                  IconButton(
                    icon: const Icon(Icons.refresh_rounded, color: ArrowsTheme.textPrimary),
                    onPressed: () => widget.controller.restartLevel(),
                  ),
                ],
              ),
            ),
            
            Expanded(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20.0),
                  child: AspectRatio(
                    aspectRatio: 1,
                    child: BoardWidget(
                      level: level,
                      currentlyMovingNode: widget.controller.currentlyMovingNode,
                      invalidNodeId: widget.controller.invalidNodeId,
                      onNodeTap: (id) => widget.controller.attemptMove(id),
                      showGrid: _showGrid,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
