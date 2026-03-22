import 'dart:math';
import 'package:flutter/material.dart';
import '../models/arrow_node.dart';
import '../arrows_theme.dart';

import 'arrow_widget.dart';

class NodeWidget extends StatefulWidget {
  final ArrowNode node;
  final VoidCallback onTap;
  final bool isMoving;
  final bool isInvalidMove;
  final List<Point<int>> relativeSegments;

  const NodeWidget({
    Key? key,
    required this.node,
    required this.onTap,
    required this.relativeSegments,
    this.isMoving = false,
    this.isInvalidMove = false,
  }) : super(key: key);

  @override
  _NodeWidgetState createState() => _NodeWidgetState();
}

class _NodeWidgetState extends State<NodeWidget> with SingleTickerProviderStateMixin {
  late AnimationController _shakeController;

  @override
  void initState() {
    super.initState();
    _shakeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
  }

  @override
  void didUpdateWidget(covariant NodeWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isInvalidMove && !oldWidget.isInvalidMove) {
      _shakeController.forward(from: 0.0);
    }
  }

  @override
  void dispose() {
    _shakeController.dispose();
    super.dispose();
  }

  Color get nodeColor {
    switch (widget.node.direction) {
      case ArrowDirection.up:
        return ArrowsTheme.arrowUp;
      case ArrowDirection.down:
        return ArrowsTheme.arrowDown;
      case ArrowDirection.left:
        return ArrowsTheme.arrowLeft;
      case ArrowDirection.right:
        return ArrowsTheme.arrowRight;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.node.isRemoved && !widget.isMoving) {
      return const SizedBox.shrink();
    }

    return AnimatedBuilder(
      animation: _shakeController,
      builder: (context, child) {
        double shakeOffset = 0.0;
        if (_shakeController.isAnimating) {
          double val = _shakeController.value;
          shakeOffset = (val < 0.25) ? 10 * val * 4 :
                        (val < 0.5) ? 10 * (0.5 - val) * 4 :
                        (val < 0.75) ? -10 * (val - 0.5) * 4 :
                        -10 * (1 - val) * 4;
        }

        return Transform.translate(
          offset: Offset(shakeOffset, 0),
          child: child,
        );
      },
      child: GestureDetector(
        onTap: widget.isMoving ? null : widget.onTap,
        child: Container(
          decoration: BoxDecoration(
            color: Colors.transparent, // Nodes have no background in the new aesthetic
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: Colors.transparent,
              width: 0,
            ),
          ),
          child: Center(
            child: ArrowWidget(
               direction: widget.node.direction,
               isInvalid: widget.isInvalidMove,
               relativeSegments: widget.relativeSegments,
            ),
          ),
        ),
      ),
    );
  }
}

