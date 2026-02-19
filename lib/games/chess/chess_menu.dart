import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'chess_controller.dart';

class ChessMenu extends StatelessWidget {
  final Function(GameMode, AIDifficulty, {int? timeSeconds}) onStart;
  final Color primaryColor;

  const ChessMenu({
    super.key,
    required this.onStart,
    required this.primaryColor,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF0F2027), Color(0xFF203A43), Color(0xFF2C5364)],
          ),
        ),
        child: Stack(
          children: [
            // Subtle animated background elements
            ...List.generate(5, (index) => _buildFloatingShape(index)),

            SafeArea(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.grid_4x4_rounded,
                        color: Colors.white,
                        size: 80,
                      ).animate().scale(
                        duration: 800.ms,
                        curve: Curves.elasticOut,
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        "CHESS",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 4,
                        ),
                      ).animate().fadeIn(delay: 400.ms),
                      const SizedBox(height: 60),
                      _buildModeCard(
                        context,
                        "AI MODE",
                        "Challenge the Engine",
                        Icons.computer_rounded,
                        () => _showAIDifficultySelector(context),
                      ),
                      const SizedBox(height: 20),
                      _buildModeCard(
                        context,
                        "PVP MODE",
                        "Play with Friends",
                        Icons.person_add_alt_1_rounded,
                        () => _showTimeSelector(context),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildModeCard(
    BuildContext context,
    String title,
    String subtitle,
    IconData icon,
    VoidCallback onTap,
  ) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Material(
          color: Colors.white.withOpacity(0.05),
          child: InkWell(
            onTap: onTap,
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: Colors.white10),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: primaryColor.withOpacity(0.2),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(icon, color: primaryColor, size: 28),
                  ),
                  const SizedBox(width: 20),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                          ),
                        ),
                        Text(
                          subtitle,
                          style: const TextStyle(
                            color: Colors.white54,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.chevron_right, color: Colors.white24),
                ],
              ),
            ),
          ),
        ),
      ),
    ).animate().fadeIn(delay: 600.ms).slideX(begin: 0.1);
  }

  void _showTimeSelector(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Color(0xFF1A1A1A),
          borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
        ),
        padding: const EdgeInsets.all(32),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                "SELECT TIME",
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                  letterSpacing: 2,
                ),
              ),
              const SizedBox(height: 24),
              _buildTimeButton(context, "5 MIN", 300),
              const SizedBox(height: 12),
              _buildTimeButton(context, "10 MIN", 600),
              const SizedBox(height: 12),
              _buildTimeButton(context, "30 MIN", 1800),
              const SizedBox(height: 12),
              _buildTimeButton(context, "PRACTICE (NO TIMER)", null),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTimeButton(BuildContext context, String label, int? seconds) {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: OutlinedButton(
        onPressed: () {
          Navigator.pop(context);
          if (seconds == null) {
            onStart(GameMode.practice, AIDifficulty.medium, timeSeconds: 0);
          } else {
            onStart(GameMode.pvp, AIDifficulty.medium, timeSeconds: seconds);
          }
        },
        style: OutlinedButton.styleFrom(
          side: BorderSide(color: Colors.blueAccent.withOpacity(0.3)),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        child: Text(
          label,
          style: const TextStyle(
            color: Colors.blueAccent,
            fontWeight: FontWeight.bold,
            letterSpacing: 2,
          ),
        ),
      ),
    );
  }

  void _showAIDifficultySelector(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Color(0xFF1A1A1A),
          borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
        ),
        padding: const EdgeInsets.all(32),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                "SELECT DIFFICULTY",
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                  letterSpacing: 2,
                ),
              ),
              const SizedBox(height: 32),
              ...AIDifficulty.values.map(
                (d) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _buildDifficultyButton(context, d),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDifficultyButton(BuildContext context, AIDifficulty d) {
    Color color = Colors.white24;
    switch (d) {
      case AIDifficulty.easy:
        color = Colors.greenAccent;
        break;
      case AIDifficulty.medium:
        color = Colors.orangeAccent;
        break;
      case AIDifficulty.hard:
        color = Colors.redAccent;
        break;
      case AIDifficulty.pro:
        color = Colors.deepPurpleAccent;
        break;
    }

    return SizedBox(
      width: double.infinity,
      height: 50,
      child: OutlinedButton(
        onPressed: () {
          Navigator.pop(context);
          onStart(GameMode.vsAI, d);
        },
        style: OutlinedButton.styleFrom(
          side: BorderSide(color: color.withOpacity(0.3)),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        child: Text(
          d.name.toUpperCase(),
          style: TextStyle(
            color: color,
            fontWeight: FontWeight.bold,
            letterSpacing: 2,
          ),
        ),
      ),
    );
  }

  Widget _buildFloatingShape(int index) {
    return Positioned(
      left: (index * 70).toDouble(),
      top: (index * 150).toDouble(),
      child:
          Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      primaryColor.withOpacity(0.05),
                      Colors.transparent,
                    ],
                  ),
                ),
              )
              .animate(onPlay: (c) => c.repeat())
              .moveY(
                begin: -20,
                end: 20,
                duration: (2 + index).seconds,
                curve: Curves.easeInOutSine,
              ),
    );
  }
}
