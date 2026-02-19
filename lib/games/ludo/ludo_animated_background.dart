import 'dart:ui';
import 'package:flutter/material.dart';

class AnimatedLudoBackground extends StatelessWidget {
  const AnimatedLudoBackground({super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox.expand(
      child: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset('assets/back_ludo.png', fit: BoxFit.cover),
          // Blur the image so it feels like a soft backdrop
          Container(
            // Dark tint on top of blur
            color: Colors.black.withOpacity(0.5),
          ),
        ],
      ),
    );
  }
}
