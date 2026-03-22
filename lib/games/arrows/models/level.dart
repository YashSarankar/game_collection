import 'arrow_node.dart';

class Level {
  final int id;
  final List<ArrowNode> nodes;
  final String difficulty;
  final int boardWidth;
  final int boardHeight;

  Level({
    required this.id,
    required this.nodes,
    required this.difficulty,
    this.boardWidth = 8,
    this.boardHeight = 8,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'nodes': nodes.map((n) => n.toJson()).toList(),
        'difficulty': difficulty,
      };

  factory Level.fromJson(Map<String, dynamic> json) {
    return Level(
      id: json['id'],
      nodes: (json['nodes'] as List).map((n) => ArrowNode.fromJson(n)).toList(),
      difficulty: json['difficulty'],
      boardWidth: 8,
      boardHeight: 8,
    );
  }
}
