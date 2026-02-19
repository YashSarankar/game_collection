import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'chess_logic.dart';

class ChessPieceWidget extends StatelessWidget {
  final ChessPiece piece;
  final double size;
  final bool isSelected;
  final bool isCapture;

  const ChessPieceWidget({
    super.key,
    required this.piece,
    required this.size,
    this.isSelected = false,
    this.isCapture = false,
  });

  @override
  Widget build(BuildContext context) {
    final String colorPrefix = piece.color == PlayerColor.white ? 'w' : 'b';
    final String typeName = piece.type.name.toLowerCase();
    final String assetPath = 'assets/images/chess/${colorPrefix}_$typeName.svg';

    return Container(
          width: size,
          height: size,
          padding: EdgeInsets.all(size * 0.1),
          alignment: Alignment.center,
          child: SvgPicture.asset(assetPath, width: size, height: size),
        )
        .animate(target: isCapture ? 1 : 0)
        .scale(
          begin: const Offset(1, 1),
          end: const Offset(0.2, 0.2),
          curve: Curves.easeInBack,
        )
        .fadeOut()
        .animate(target: isSelected ? 1 : 0)
        .scale(
          begin: const Offset(1, 1),
          end: const Offset(1.15, 1.15),
          duration: 200.ms,
          curve: Curves.easeOutBack,
        );
  }
}
