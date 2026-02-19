import 'package:flutter/material.dart';
import '../models/tile_model.dart';
import '../match_3_theme.dart';

/// Premium candy-style gem tile widget.
class TileWidget extends StatelessWidget {
  final TileModel tile;
  final double size;
  final VoidCallback? onTap;

  const TileWidget({
    super.key,
    required this.tile,
    required this.size,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    if (tile.type == TileType.empty) {
      return SizedBox(width: size, height: size);
    }

    final colors = Match3Theme.gemGradients[tile.type.index];
    final innerSize = size - 8.0;

    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: size,
        height: size,
        child: Padding(
          padding: const EdgeInsets.all(3),
          child: Stack(
            children: [
              // ── Shadow layer ──────────────────────────────────────
              Positioned.fill(
                top: 4,
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(innerSize * 0.28),
                    color: colors[1].withOpacity(0.55),
                  ),
                ),
              ),

              // ── Main gem body ─────────────────────────────────────
              Positioned.fill(
                bottom: 4,
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [colors[0], colors[1]],
                      stops: const [0.1, 1.0],
                    ),
                    borderRadius: BorderRadius.circular(innerSize * 0.28),
                    boxShadow: [
                      BoxShadow(
                        color: colors[0].withOpacity(0.4),
                        blurRadius: 8,
                        spreadRadius: 0,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Stack(
                    children: [
                      // ── Top gloss ────────────────────────────────
                      Positioned(
                        top: 2,
                        left: 3,
                        right: 3,
                        child: Container(
                          height: innerSize * 0.36,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.vertical(
                              top: Radius.circular(innerSize * 0.28),
                            ),
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Colors.white.withOpacity(0.55),
                                Colors.white.withOpacity(0.0),
                              ],
                            ),
                          ),
                        ),
                      ),

                      // ── Bottom rim shine ─────────────────────────
                      Positioned(
                        bottom: 3,
                        left: 6,
                        right: 6,
                        child: Container(
                          height: 3,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(4),
                            color: Colors.white.withOpacity(0.15),
                          ),
                        ),
                      ),

                      // ── Center icon / special indicator ──────────
                      Center(
                        child: tile.special != SpecialType.none
                            ? _specialIcon(innerSize)
                            : _gemIcon(innerSize),
                      ),

                      // ── Sparkle dot (top-right) ──────────────────
                      Positioned(
                        top: innerSize * 0.1,
                        right: innerSize * 0.12,
                        child: Container(
                          width: innerSize * 0.12,
                          height: innerSize * 0.12,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white.withOpacity(0.7),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _gemIcon(double s) {
    return Icon(
      _iconForType(tile.type),
      color: Colors.white.withOpacity(0.9),
      size: s * 0.44,
      shadows: const [
        Shadow(color: Colors.black38, blurRadius: 6, offset: Offset(1, 1)),
      ],
    );
  }

  Widget _specialIcon(double s) {
    IconData icon;
    Color glow;
    switch (tile.special) {
      case SpecialType.bomb:
        icon = Icons.local_fire_department_rounded;
        glow = Colors.orange;
        break;
      case SpecialType.lineHor:
        icon = Icons.swap_horiz_rounded;
        glow = Colors.cyanAccent;
        break;
      case SpecialType.lineVer:
        icon = Icons.swap_vert_rounded;
        glow = Colors.cyanAccent;
        break;
      case SpecialType.cross:
        icon = Icons.add_rounded;
        glow = Colors.limeAccent;
        break;
      case SpecialType.colorBomb:
        icon = Icons.auto_awesome_rounded;
        glow = Colors.white;
        break;
      default:
        return _gemIcon(s);
    }
    return Icon(
      icon,
      color: Colors.white,
      size: s * 0.58,
      shadows: [
        Shadow(color: glow, blurRadius: 16),
        Shadow(color: glow.withOpacity(0.5), blurRadius: 30),
      ],
    );
  }

  IconData _iconForType(TileType t) {
    switch (t) {
      case TileType.pink:
        return Icons.favorite_rounded;
      case TileType.blue:
        return Icons.water_drop_rounded;
      case TileType.green:
        return Icons.eco_rounded;
      case TileType.yellow:
        return Icons.brightness_7_rounded;
      case TileType.purple:
        return Icons.diamond_rounded;
      case TileType.orange:
        return Icons.local_fire_department_rounded;
      default:
        return Icons.circle;
    }
  }
}
