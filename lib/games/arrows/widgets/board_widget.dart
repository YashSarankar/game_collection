import 'dart:math';
import 'package:flutter/material.dart';
import '../models/arrow_node.dart';
import '../models/level.dart';
import '../arrows_theme.dart';
import 'node_widget.dart';

class BoardWidget extends StatelessWidget {
  final Level level;
  final ArrowNode? currentlyMovingNode;
  final String? invalidNodeId;
  final Function(String) onNodeTap;
  final bool showGrid;

  const BoardWidget({
    Key? key,
    required this.level,
    this.currentlyMovingNode,
    this.invalidNodeId,
    required this.onNodeTap,
    this.showGrid = false,
  }) : super(key: key);

  double _getLeft(ArrowNode node, double cellSize) {
    int minX = node.segments.map((s) => s.x).reduce(min);
    return minX * cellSize;
  }
  
  double _getTop(ArrowNode node, double cellSize) {
    int minY = node.segments.map((s) => s.y).reduce(min);
    return minY * cellSize;
  }
  
  double _getWidth(ArrowNode node, double cellSize) {
    int minX = node.segments.map((s) => s.x).reduce(min);
    int maxX = node.segments.map((s) => s.x).reduce(max);
    return (maxX - minX + 1) * cellSize;
  }
  
  double _getHeight(ArrowNode node, double cellSize) {
    int minY = node.segments.map((s) => s.y).reduce(min);
    int maxY = node.segments.map((s) => s.y).reduce(max);
    return (maxY - minY + 1) * cellSize;
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final double boardSize = constraints.maxWidth < constraints.maxHeight
            ? constraints.maxWidth
            : constraints.maxHeight;

        // Cell size based on standard level width + some padding
        final double cellSize = boardSize / level.boardWidth;

        return Center(
          child: SizedBox(
            width: boardSize,
            height: boardSize,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                if (showGrid)
                  ...() {
                    List<Widget> gridLines = [];
                    final Set<int> occupiedX = {};
                    final Set<int> occupiedY = {};
                    
                    for (var node in level.nodes) {
                      for (var seg in node.segments) {
                        occupiedX.add(seg.x);
                        occupiedY.add(seg.y);
                      }
                    }

                    // Horizontal lines for each active row
                    for (var y in occupiedY) {
                      gridLines.add(Positioned(
                        top: (y + 0.5) * cellSize,
                        left: 0,
                        right: 0,
                        height: 1,
                        child: Container(color: Colors.white.withOpacity(0.06)),
                      ));
                    }
                    
                    // Vertical lines for each active column
                    for (var x in occupiedX) {
                      gridLines.add(Positioned(
                        left: (x + 0.5) * cellSize,
                        top: 0,
                        bottom: 0,
                        width: 1,
                        child: Container(color: Colors.white.withOpacity(0.06)),
                      ));
                    }
                    
                    return gridLines;
                  }(),
                // Render background dots for every cell in the structure
                ...() {
                  List<Widget> dots = [];
                  for (var node in level.nodes) {
                    for (var seg in node.segments) {
                      dots.add(Positioned(
                        left: (seg.x + 0.5) * cellSize - 1.5,
                        top: (seg.y + 0.5) * cellSize - 1.5,
                        width: 3,
                        height: 3,
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.12),
                            shape: BoxShape.circle,
                          ),
                        ),
                      ));
                    }
                  }
                  return dots;
                }(),
                
                // Render stationary nodes
                ...level.nodes.where((n) => n.id != currentlyMovingNode?.id).map((node) {
                  int minX = node.segments.map((s) => s.x).reduce(min);
                  int minY = node.segments.map((s) => s.y).reduce(min);

                  return Positioned(
                    left: _getLeft(node, cellSize),
                    top: _getTop(node, cellSize),
                    width: _getWidth(node, cellSize),
                    height: _getHeight(node, cellSize),
                    child: NodeWidget(
                      node: node,
                      onTap: () => onNodeTap(node.id),
                      isMoving: false,
                      isInvalidMove: node.id == invalidNodeId,
                      // Pass relative segments for painting
                      relativeSegments: node.segments.map((s) => Point<int>(s.x - minX, s.y - minY)).toList(),
                    ),
                  );
                }),

                // Render moving node with tween
                if (currentlyMovingNode != null)
                  _MovingNodeWrapper(
                    node: currentlyMovingNode!,
                    cellSize: cellSize,
                    boardSize: boardSize,
                    startLeft: _getLeft(currentlyMovingNode!, cellSize),
                    startTop: _getTop(currentlyMovingNode!, cellSize),
                    nodeWidth: _getWidth(currentlyMovingNode!, cellSize),
                    nodeHeight: _getHeight(currentlyMovingNode!, cellSize),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _MovingNodeWrapper extends StatefulWidget {
  final ArrowNode node;
  final double cellSize;
  final double boardSize;

  const _MovingNodeWrapper({
    required this.node,
    required this.cellSize,
    required this.boardSize,
    // Note: startLeft/Top/Width/Height removed as snake movement uses board-relative coords
    double? startLeft, double? startTop, double? nodeWidth, double? nodeHeight,
  });

  @override
  __MovingNodeWrapperState createState() => __MovingNodeWrapperState();
}

class __MovingNodeWrapperState extends State<_MovingNodeWrapper> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _progress; // Distance moved in grid cells

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
       vsync: this,
       duration: const Duration(milliseconds: 600),
    );

    // How far it needs to move to fully disappear: its own length + board size
    const double totalDistance = 25.0; 
    _progress = Tween<double>(begin: 0, end: totalDistance).animate(
      CurvedAnimation(parent: _controller, curve: Curves.linear)
    );

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _progress,
      builder: (context, child) {
        final double t = _progress.value;
        final List<Point<int>> originalSegments = widget.node.segments;
        final int n = originalSegments.length;
        
        // Path is original segments in reverse order: Sn -> ... -> S1 -> S0
        final List<Point<int>> path = originalSegments.reversed.toList();
        
        List<Offset> currentPositions = [];
        
        for (int i = 0; i < n; i++) {
          // At t=0, segment i is at path[n - 1 - i]
          double posInPath = (n - 1 - i) + t;
          
          Offset pos;
          if (posInPath <= n - 1) {
            // Segment is still on the original bent path
            int idx = posInPath.floor();
            double fract = posInPath - idx;
            
            Offset p1 = Offset(path[idx].x.toDouble(), path[idx].y.toDouble());
            Offset p2 = Offset(path[min(idx + 1, n - 1)].x.toDouble(), path[min(idx + 1, n - 1)].y.toDouble());
            
            pos = Offset.lerp(p1, p2, fract)!;
          } else {
            // Segment has typed the head and is moving straight out
            double overshoot = posInPath - (n - 1);
            double dx = 0, dy = 0;
            switch (widget.node.direction) {
              case ArrowDirection.up: dy = -overshoot; break;
              case ArrowDirection.down: dy = overshoot; break;
              case ArrowDirection.left: dx = -overshoot; break;
              case ArrowDirection.right: dx = overshoot; break;
            }
            pos = Offset(originalSegments[0].x + dx, originalSegments[0].y + dy);
          }
          currentPositions.add(pos);
        }

        // Actually, let's just use a CustomPaint directly to avoid Point<int> rounding issues
        return Positioned.fill(
          child: CustomPaint(
            painter: _SnakePainter(
              positions: currentPositions,
              cellSize: widget.cellSize,
              direction: widget.node.direction,
              color: widget.node.id == 'invalid' ? ArrowsTheme.blockedNode : ArrowsTheme.arrowUp,
            ),
          ),
        );
      },
    );
  }
}

class _SnakePainter extends CustomPainter {
  final List<Offset> positions;
  final double cellSize;
  final ArrowDirection direction;
  final Color color;

  _SnakePainter({
    required this.positions,
    required this.cellSize,
    required this.direction,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (positions.isEmpty) return;

    final paint = Paint()
      ..color = color
      ..strokeWidth = 2.8
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..isAntiAlias = true
      ..style = PaintingStyle.stroke;

    final path = Path();
    for (int i = 0; i < positions.length; i++) {
      double px = (positions[i].dx + 0.5) * cellSize;
      double py = (positions[i].dy + 0.5) * cellSize;
      if (i == 0) path.moveTo(px, py);
      else path.lineTo(px, py);
    }
    
    canvas.drawPath(path, paint);

    // Draw Head
    final headPaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill
      ..isAntiAlias = true;

    final headPos = positions.first;
    double hx = (headPos.dx + 0.5) * cellSize;
    double hy = (headPos.dy + 0.5) * cellSize;

    final headPath = Path();
    const double headSize = 12.0;
    const double headAngle = 0.5;

    if (direction == ArrowDirection.right) {
      headPath.moveTo(hx + 2, hy);
      headPath.lineTo(hx + 2 - headSize, hy - headSize * headAngle);
      headPath.lineTo(hx + 2 - headSize, hy + headSize * headAngle);
    } else if (direction == ArrowDirection.left) {
      headPath.moveTo(hx - 2, hy);
      headPath.lineTo(hx - 2 + headSize, hy - headSize * headAngle);
      headPath.lineTo(hx - 2 + headSize, hy + headSize * headAngle);
    } else if (direction == ArrowDirection.down) {
      headPath.moveTo(hx, hy + 2);
      headPath.lineTo(hx - headSize * headAngle, hy + 2 - headSize);
      headPath.lineTo(hx + headSize * headAngle, hy + 2 - headSize);
    } else if (direction == ArrowDirection.up) {
      headPath.moveTo(hx, hy - 2);
      headPath.lineTo(hx - headSize * headAngle, hy - 2 + headSize);
      headPath.lineTo(hx + headSize * headAngle, hy - 2 + headSize);
    }
    headPath.close();
    canvas.drawPath(headPath, headPaint);
  }

  @override
  bool shouldRepaint(covariant _SnakePainter oldDelegate) => true;
}
