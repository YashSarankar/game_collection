import 'dart:ui';
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
    with TickerProviderStateMixin {
  late AnimationController _controller;
  late AnimationController _driftController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 2500),
      vsync: this,
    );

    _driftController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    )..repeat(reverse: true);

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.4, 0.9, curve: Curves.easeIn),
      ),
    );

    _scaleAnimation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween(
          begin: 0.8,
          end: 1.05,
        ).chain(CurveTween(curve: Curves.easeOutCubic)),
        weight: 40,
      ),
      TweenSequenceItem(
        tween: Tween(
          begin: 1.05,
          end: 1.0,
        ).chain(CurveTween(curve: Curves.easeInOut)),
        weight: 60,
      ),
    ]).animate(_controller);

    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        // Add a slight delay after Lottie completion to let the
        // SarankarDevelopers branding and final logo state be seen.
        Future.delayed(const Duration(milliseconds: 800), () {
          if (mounted) _navigateToHome();
        });
      }
    });

    // Fallback: Ensure we transition even if Lottie fails for some reason
    Future.delayed(const Duration(seconds: 4), () {
      if (mounted && _controller.status != AnimationStatus.completed) {
        _navigateToHome();
      }
    });

    // Start fetching or initializing if needed
    _controller.forward();
  }

  void _navigateToHome() {
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            const HomeScreen(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
        transitionDuration: const Duration(milliseconds: 600),
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    _driftController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = MediaQuery.of(context).platformBrightness == Brightness.dark;
    const orangeAccent = Color(0xFFFF8C00);

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
        systemNavigationBarColor: Colors.transparent,
        systemNavigationBarIconBrightness: isDark
            ? Brightness.light
            : Brightness.dark,
      ),
      child: Scaffold(
        backgroundColor: isDark ? Colors.black : Colors.white,
        body: Stack(
          children: [
            // Premium Atmospheric Background (Ported from Wallpaper project)
            Positioned.fill(
              child: AnimatedBuilder(
                animation: _driftController,
                builder: (context, child) {
                  return Stack(
                    children: [
                      _AtmosphericLight(
                        color: orangeAccent.withOpacity(isDark ? 0.15 : 0.1),
                        beginAlignment: Alignment.topLeft,
                        endAlignment: Alignment.centerLeft,
                        controller: _driftController,
                        size: 600,
                      ),
                      _AtmosphericLight(
                        color: const Color(
                          0xFF4F46E5,
                        ).withOpacity(isDark ? 0.12 : 0.08),
                        beginAlignment: Alignment.bottomRight,
                        endAlignment: Alignment.centerRight,
                        controller: _driftController,
                        size: 500,
                      ),
                      _AtmosphericLight(
                        color: orangeAccent.withOpacity(isDark ? 0.1 : 0.05),
                        beginAlignment: Alignment.topRight,
                        endAlignment: Alignment.bottomLeft,
                        controller: _driftController,
                        size: 400,
                      ),
                    ],
                  );
                },
              ),
            ),

            // Main Content
            Center(
              child: AnimatedBuilder(
                animation: _controller,
                builder: (context, child) {
                  return Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Spacer(flex: 3),

                      // The Center Piece (Logo/Controller)
                      Transform.scale(
                        scale: _scaleAnimation.value,
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            // Soft Glow
                            Container(
                              width: 180,
                              height: 180,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: orangeAccent.withOpacity(
                                      0.2 * _controller.value,
                                    ),
                                    blurRadius: 80,
                                    spreadRadius: 20,
                                  ),
                                ],
                              ),
                            ),

                            // Lottie Animation
                            Lottie.asset(
                              'assets/Controller.json',
                              controller: _controller,
                              width: 300,
                              height: 300,
                              onLoaded: (composition) {
                                _controller.duration = composition.duration;
                                _controller.forward(from: 0.0);
                              },
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 32),

                      // Title with Creative Styling
                      FadeTransition(
                        opacity: _fadeAnimation,
                        child: Column(
                          children: [
                            RichText(
                              text: TextSpan(
                                style: TextStyle(
                                  fontSize: 42,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: -1,
                                  color: isDark ? Colors.white : Colors.black87,
                                ),
                                children: const [
                                  TextSpan(text: 'Snap'),
                                  TextSpan(
                                    text: 'Play',
                                    style: TextStyle(color: orangeAccent),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'ULTIMATE OFFLINE COLLECTION',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                letterSpacing: 4,
                                color: isDark ? Colors.white38 : Colors.black38,
                              ),
                            ),
                          ],
                        ),
                      ),

                      const Spacer(flex: 4),

                      // Developer Branding (Premium touch from Wallpaper project)
                      FadeTransition(
                        opacity: _fadeAnimation,
                        child: Padding(
                          padding: const EdgeInsets.only(bottom: 40),
                          child: Column(
                            children: [
                              Text(
                                'FROM',
                                style: TextStyle(
                                  color: isDark
                                      ? Colors.white24
                                      : Colors.black26,
                                  fontSize: 10,
                                  letterSpacing: 4,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                'SarankarDevelopers',
                                style: TextStyle(
                                  color: isDark
                                      ? Colors.white60
                                      : Colors.black54,
                                  fontSize: 14,
                                  letterSpacing: 1.5,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AtmosphericLight extends StatelessWidget {
  final Color color;
  final Alignment beginAlignment;
  final Alignment endAlignment;
  final AnimationController controller;
  final double size;

  const _AtmosphericLight({
    required this.color,
    required this.beginAlignment,
    required this.endAlignment,
    required this.controller,
    required this.size,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, child) {
        final alignment = Alignment.lerp(
          beginAlignment,
          endAlignment,
          controller.value,
        )!;
        return Align(
          alignment: alignment,
          child: Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(colors: [color, color.withOpacity(0.0)]),
            ),
          ),
        );
      },
    );
  }
}
