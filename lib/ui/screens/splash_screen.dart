import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lottie/lottie.dart';
import 'home_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 4),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.6, 1.0, curve: Curves.easeIn),
      ),
    );

    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.5, curve: Curves.easeOutBack),
      ),
    );

    // Initial forward will be overridden by onLoaded if needed
    _controller.forward();

    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _navigateToHome();
      }
    });
  }

  void _navigateToHome() {
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            const HomeScreen(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
        transitionDuration: const Duration(milliseconds: 1000),
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = MediaQuery.of(context).platformBrightness == Brightness.dark;

    // Color Palette
    const orangeAccent = Color(0xFFFF8C00); // Creative Orange
    final bgGradient = isDark
        ? const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF0F0F0F), Color(0xFF1A1A1A), Color(0xFF000000)],
          )
        : const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Colors.white, Color(0xFFFCFCFC), Color(0xFFF9F9F9)],
          );

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
      ),
      child: Scaffold(
        body: Container(
          width: double.infinity,
          height: double.infinity,
          decoration: BoxDecoration(gradient: bgGradient),
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Background Decorative Elements
              Positioned(
                top: -100,
                right: -50,
                child: _buildDecorativeCircle(
                  orangeAccent.withOpacity(0.05),
                  250,
                ),
              ),
              Positioned(
                bottom: -80,
                left: -80,
                child: _buildDecorativeCircle(
                  orangeAccent.withOpacity(0.08),
                  300,
                ),
              ),

              // Main Content
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Glow Effect behind Controller
                  AnimatedBuilder(
                    animation: _controller,
                    builder: (context, child) {
                      return Container(
                        width: 280,
                        height: 280,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: orangeAccent.withOpacity(
                                0.15 * _controller.value,
                              ),
                              blurRadius: 60,
                              spreadRadius: 20 * _controller.value,
                            ),
                          ],
                        ),
                        child: child,
                      );
                    },
                    child: ScaleTransition(
                      scale: _scaleAnimation,
                      child: Lottie.asset(
                        'assets/Controller.json',
                        controller: _controller,
                        height: 300,
                        width: 300,
                        fit: BoxFit.contain,
                        onLoaded: (composition) {
                          _controller.duration = composition.duration;
                          _controller.forward(from: 0.0);
                        },
                      ),
                    ),
                  ),

                  const SizedBox(height: 40),

                  // Title with Creative Styling
                  FadeTransition(
                    opacity: _fadeAnimation,
                    child: Column(
                      children: [
                        RichText(
                          text: TextSpan(
                            style: TextStyle(
                              fontFamily: 'System',
                              fontSize: 34,
                              fontWeight: FontWeight.w900,
                              letterSpacing: -0.5,
                              color: isDark ? Colors.white : Colors.black87,
                            ),
                            children: const [
                              TextSpan(text: 'GAME'),
                              TextSpan(
                                text: ' HUB',
                                style: TextStyle(color: orangeAccent),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          width: 40,
                          height: 4,
                          decoration: BoxDecoration(
                            color: orangeAccent,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'ULTIMATE OFFLINE COLLECTION',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 3.0,
                            color: isDark ? Colors.white54 : Colors.black45,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDecorativeCircle(Color color, double size) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(shape: BoxShape.circle, color: color),
    );
  }
}
