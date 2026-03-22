import '../models/arrow_node.dart';

class MovementEngine {
  /// Checks if the given [startNode] can move out of the board without hitting any of the [remainingNodes].
  static bool canMove(ArrowNode startNode, List<ArrowNode> remainingNodes, int width, int height) {
    int dx = 0;
    int dy = 0;
    switch (startNode.direction) {
      case ArrowDirection.up:
        dy = -1;
        break;
      case ArrowDirection.down:
        dy = 1;
        break;
      case ArrowDirection.left:
        dx = -1;
        break;
      case ArrowDirection.right:
        dx = 1;
        break;
    }

    // In snake/follow-the-leader movement, segments follow the path of the head.
    // Therefore, only the path in front of the head needs to be clear.
    int cx = startNode.x + dx;
    int cy = startNode.y + dy;

    while (cx >= 0 && cx < width && cy >= 0 && cy < height) {
      for (var node in remainingNodes) {
        if (!node.isRemoved && node.id != startNode.id && node.occupies(cx, cy)) {
          return false;
        }
      }
      cx += dx;
      cy += dy;
    }

    return true; // The path in front of the head is clear
  }
}
