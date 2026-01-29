import 'dart:async';
import 'package:flutter/material.dart';
import '../../core/services/haptic_service.dart';

class GameCountdown extends StatefulWidget {
  final VoidCallback onFinished;
  final String? startText;

  const GameCountdown({
    super.key,
    required this.onFinished,
    this.startText = 'GO!',
  });

  @override
  State<GameCountdown> createState() => _GameCountdownState();
}

class _GameCountdownState extends State<GameCountdown>
    with SingleTickerProviderStateMixin {
  int _count = 3;
  bool _showGo = false;
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _opacityAnimation;
  HapticService? _hapticService;

  @override
  void initState() {
    super.initState();
    _initializeHaptics();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _scaleAnimation = Tween<double>(
      begin: 2.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutBack));

    _opacityAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.5, curve: Curves.easeIn),
      ),
    );

    _startCountdown();
  }

  Future<void> _initializeHaptics() async {
    _hapticService = await HapticService.getInstance();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _startCountdown() async {
    for (int i = 3; i > 0; i--) {
      if (!mounted) return;
      setState(() {
        _count = i;
      });
      _hapticService?.light();
      _controller.forward(from: 0.0);
      await Future.delayed(const Duration(seconds: 1));
    }

    if (!mounted) return;
    setState(() {
      _showGo = true;
    });
    _hapticService?.medium();
    _controller.forward(from: 0.0);

    // Call finish callback immediately when GO appears
    widget.onFinished();

    await Future.delayed(const Duration(milliseconds: 800));
    if (mounted) {
      // The widget will be removed by the parent based on its own logic or we can provide a way to hide it
    }
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return Opacity(
            opacity: _opacityAnimation.value,
            child: Transform.scale(
              scale: _scaleAnimation.value,
              child: Text(
                _showGo ? (widget.startText ?? 'GO!') : '$_count',
                style: const TextStyle(
                  fontSize: 100,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                  shadows: [
                    Shadow(
                      color: Colors.black26,
                      blurRadius: 20,
                      offset: Offset(0, 10),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
