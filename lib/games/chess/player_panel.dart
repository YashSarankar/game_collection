import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'chess_logic.dart';

class PlayerPanel extends StatelessWidget {
  final String name;
  final int time;
  final bool isTurn;
  final PlayerColor color;
  final List<PieceType> captures;

  const PlayerPanel({
    super.key,
    required this.name,
    required this.time,
    required this.isTurn,
    required this.color,
    this.captures = const [],
  });

  @override
  Widget build(BuildContext context) {
    String formattedTime =
        "${time ~/ 60}:${(time % 60).toString().padLeft(2, '0')}";

    return ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: (isTurn
                    ? Colors.white.withOpacity(0.15)
                    : Colors.white.withOpacity(0.05)),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isTurn
                      ? Colors.blueAccent.withOpacity(0.5)
                      : Colors.white10,
                  width: 2,
                ),
              ),
              child: Row(
                children: [
                  _buildAvatar(),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              name,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            _buildTimer(formattedTime),
                          ],
                        ),
                        const SizedBox(height: 4),
                        _buildCaptures(),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        )
        .animate(target: isTurn ? 1 : 0)
        .custom(
          duration: 1.seconds,
          builder: (context, value, child) => Container(
            decoration: BoxDecoration(
              boxShadow: [
                if (isTurn)
                  BoxShadow(
                    color: Colors.blueAccent.withOpacity(0.2 * value),
                    blurRadius: 15 * value,
                    spreadRadius: 2 * value,
                  ),
              ],
            ),
            child: child,
          ),
        );
  }

  Widget _buildAvatar() {
    return Stack(
      children: [
        CircleAvatar(
          radius: 24,
          backgroundColor: color == PlayerColor.white
              ? Colors.white24
              : Colors.black45,
          child: Icon(
            Icons.person,
            color: color == PlayerColor.white ? Colors.white : Colors.white70,
          ),
        ),
        Positioned(
          right: 0,
          bottom: 0,
          child: Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              color: Colors.green,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.black, width: 2),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTimer(String time) {
    return Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: isTurn ? Colors.redAccent.withOpacity(0.2) : Colors.black26,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            time,
            style: TextStyle(
              color: isTurn ? Colors.redAccent : Colors.white,
              fontWeight: FontWeight.bold,
              fontFamily: 'monospace',
              fontSize: 18,
            ),
          ),
        )
        .animate(target: (isTurn && this.time < 30) ? 1 : 0)
        .shimmer(color: Colors.red.withOpacity(0.5));
  }

  Widget _buildCaptures() {
    if (captures.isEmpty) return const SizedBox(height: 20);

    // Sort captures by piece value for cleaner display
    final sortedCaptures = List<PieceType>.from(captures)
      ..sort((a, b) => _pieceValue(b).compareTo(_pieceValue(a)));

    // If this is white's panel, show black pieces captured
    final opponentPrefix = color == PlayerColor.white ? 'b' : 'w';

    return SizedBox(
      height: 20,
      child: Wrap(
        children: sortedCaptures
            .map(
              (type) => Padding(
                padding: const EdgeInsets.only(right: 2),
                child: SvgPicture.asset(
                  'assets/images/chess/${opponentPrefix}_${type.name.toLowerCase()}.svg',
                  width: 18,
                  height: 18,
                ),
              ),
            )
            .toList(),
      ),
    );
  }

  int _pieceValue(PieceType type) {
    switch (type) {
      case PieceType.pawn:
        return 1;
      case PieceType.knight:
        return 3;
      case PieceType.bishop:
        return 3;
      case PieceType.rook:
        return 5;
      case PieceType.queen:
        return 9;
      case PieceType.king:
        return 0;
    }
  }

  String _getPieceIcon(PieceType type) {
    // If this is white's panel, show black pieces captured
    final pieceColor = color == PlayerColor.white
        ? PlayerColor.black
        : PlayerColor.white;

    if (pieceColor == PlayerColor.white) {
      switch (type) {
        case PieceType.pawn:
          return '♙';
        case PieceType.rook:
          return '♖';
        case PieceType.knight:
          return '♘';
        case PieceType.bishop:
          return '♗';
        case PieceType.queen:
          return '♕';
        case PieceType.king:
          return '♔';
      }
    } else {
      switch (type) {
        case PieceType.pawn:
          return '♟';
        case PieceType.rook:
          return '♜';
        case PieceType.knight:
          return '♞';
        case PieceType.bishop:
          return '♝';
        case PieceType.queen:
          return '♛';
        case PieceType.king:
          return '♚';
      }
    }
  }
}
