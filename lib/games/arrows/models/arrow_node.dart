import 'dart:math';

enum ArrowDirection { up, down, left, right }

class ArrowNode {
  final String id;
  final int x; // Head X
  final int y; // Head Y
  final ArrowDirection direction;
  final List<Point<int>> segments; 
  bool isRemoved;

  ArrowNode({
    required this.id,
    required this.x,
    required this.y,
    required this.direction,
    required this.segments,
    this.isRemoved = false,
  });

  int get length => segments.length;

  ArrowNode copyWith({bool? isRemoved}) {
    return ArrowNode(
      id: id,
      x: x,
      y: y,
      direction: direction,
      segments: List.from(segments),
      isRemoved: isRemoved ?? this.isRemoved,
    );
  }

  bool occupies(int px, int py) {
    for (var segment in segments) {
      if (segment.x == px && segment.y == py) return true;
    }
    return false;
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'x': x,
        'y': y,
        'direction': direction.index,
        'segments': segments.map((s) => {'x': s.x, 'y': s.y}).toList(),
      };

  factory ArrowNode.fromJson(Map<String, dynamic> json) {
    return ArrowNode(
      id: json['id'],
      x: json['x'],
      y: json['y'],
      direction: ArrowDirection.values[json['direction']],
      segments: (json['segments'] as List)
          .map((s) => Point<int>(s['x'], s['y']))
          .toList(),
    );
  }
}
