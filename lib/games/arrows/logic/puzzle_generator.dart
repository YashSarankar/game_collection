import 'dart:math';
import '../models/arrow_node.dart';
import '../models/level.dart';
import 'movement_engine.dart';

class PuzzleGenerator {
  static final _random = Random();

  /// Generates a valid puzzle level dynamically using reverse time placement.
  /// Shapes defined as relative coordinates from a center point
  static final Map<String, List<Point<int>>> _shapes = {
    'Bird': [
      Point(0,0), Point(1,0), Point(2,0), // Body
      Point(1,-1), Point(0,-1),           // Top/Head
      Point(1,1), Point(0,1),             // Wing/Bottom
      Point(-1,0),                        // Tail
    ],
    'Car': [
      Point(0,0), Point(1,0), Point(2,0), Point(3,0), // Body base
      Point(1,-1), Point(2,-1),                       // Cabin
      Point(0,1), Point(3,1),                         // Wheels
    ],
    'Heart': [
      Point(0,0), Point(-1,-1), Point(1,-1),
      Point(-2,-2), Point(-1,-2), Point(0,-2), Point(1,-2), Point(2,-2),
      Point(-2,-3), Point(-1,-3), Point(1,-3), Point(2,-3),
    ],
    'Tower': [
      Point(0,0), Point(1,0), Point(-1,0),
      Point(0,-1), Point(0,-2), Point(0,-3),
      Point(1,-3), Point(-1,-3),
    ],
    'Butterfly': [
      Point(0,0), Point(1,1), Point(1,-1), Point(-1,1), Point(-1,-1),
      Point(2,2), Point(2,-2), Point(-2,2), Point(-2,-2),
      Point(0,1), Point(0,-1),
    ],
    'Diamond': [
      Point(0,-2), Point(-1,-1), Point(0,-1), Point(1,-1),
      Point(-2,0), Point(-1,0), Point(0,0), Point(1,0), Point(2,0),
      Point(-1,1), Point(0,1), Point(1,1), Point(0,2),
    ]
  };

  static Level generateLevel(int levelId) {
    int numNodes = 0;
    String difficulty = 'Easy';
    int width = 12;
    int height = 12;
    int minLen = 2; // Every arrow must have a tail
    int maxLen = 3;

    // Periodic Difficulty Spikes:
    if (levelId % 10 == 0) {
      numNodes = 140 + _random.nextInt(60); 
      difficulty = 'Nightmare';
      width = 32; height = 32;
      maxLen = 18;
    } else if (levelId % 5 == 0) {
      numNodes = 80 + _random.nextInt(40);
      difficulty = 'Hard';
      width = 24; height = 24;
      maxLen = 14;
    } else {
      // Normal progression logic
      if (levelId <= 15) {
        numNodes = 20 + _random.nextInt(15);
        difficulty = 'Easy';
        maxLen = 5;
        width = 14; height = 14;
      } else if (levelId <= 40) {
        numNodes = 40 + _random.nextInt(30);
        difficulty = 'Medium';
        width = 18; height = 18;
        maxLen = 9;
      } else {
        numNodes = 70 + _random.nextInt(40);
        difficulty = 'Hard';
        width = 24; height = 24;
        maxLen = 14;
      }
    }

    List<ArrowNode> generatedNodes = [];
    int retries = 0;

    // For high complexity, rotate through multiple shapes and seeds
    int numSeeds = 1;
    if (difficulty == 'Hard') numSeeds = 4;
    if (difficulty == 'Nightmare') numSeeds = 6;

    List<Point<int>> anchorPoints = [];
    List<List<Point<int>>> shapePool = [];
    
    for (int i = 0; i < numSeeds; i++) {
        // Force anchors closer together so clusters interlock/clash
        int qx = (width ~/ 4) + _random.nextInt(width ~/ 2);
        int qy = (height ~/ 4) + _random.nextInt(height ~/ 2);
        anchorPoints.add(Point(qx, qy));

        String sName = _shapes.keys.toList()[_random.nextInt(_shapes.length)];
        var sOffsets = List<Point<int>>.from(_shapes[sName]!);
        sOffsets.shuffle();
        shapePool.add(sOffsets);
    }

    List<int> shapeIndices = List.filled(numSeeds, 0);
    int currentSeedIdx = 0;

    while (generatedNodes.length < numNodes) {
      if (retries > 500) { // More retries for dense interlocking
        generatedNodes.clear();
        retries = 0;
        shapeIndices = List.filled(numSeeds, 0);
        currentSeedIdx = 0;
        continue;
      }

      int px, py;
      
      // Rotate through seeds to build multiple structures simultaneously
      currentSeedIdx = (currentSeedIdx + 1) % numSeeds;
      Point<int> currentAnchor = anchorPoints[currentSeedIdx];
      var currentShapeOffsets = shapePool[currentSeedIdx];
      int currentShapeIdx = shapeIndices[currentSeedIdx];

      // Build around the current seed or start a new node at the seed
      if (currentShapeIdx < currentShapeOffsets.length && _random.nextDouble() < 0.8) {
        px = (currentAnchor.x + currentShapeOffsets[currentShapeIdx].x).toInt().clamp(0, width - 1);
        py = (currentAnchor.y + currentShapeOffsets[currentShapeIdx].y).toInt().clamp(0, height - 1);
        shapeIndices[currentSeedIdx]++;
      } else {
        // Cluster tightly around ANY existing node to force "bridging" between seeds
        var anchor = generatedNodes.isEmpty 
            ? currentAnchor 
            : Point(generatedNodes[_random.nextInt(generatedNodes.length)].x, 
                    generatedNodes[_random.nextInt(generatedNodes.length)].y);
        
        px = (anchor.x + _random.nextInt(3) - 1).clamp(0, width - 1);
        py = (anchor.y + _random.nextInt(3) - 1).clamp(0, height - 1);
      }

      if (generatedNodes.any((n) => n.occupies(px, py))) {
        retries++;
        continue;
      }

      List<ArrowNode> validPlacements = [];
      for (var dir in ArrowDirection.values) {
        // Longer arrows make for tougher puzzles
        for (int l = minLen; l <= maxLen; l++) {
          // Attempt multiple segment patterns for this length
          for (int attempt = 0; attempt < 3; attempt++) {
            List<Point<int>> segments = _generateSegments(px, py, dir, l);
            
            bool fitsBody = true;
            for (var seg in segments) {
              if (seg.x < 0 || seg.x >= width || seg.y < 0 || seg.y >= height) { fitsBody = false; break; }
              // Important: Check if it overlaps with other heads OR other segments
              if (generatedNodes.any((n) => n.occupies(seg.x, seg.y))) { fitsBody = false; break; }
              // Self-collision check for complex segments
              if (segments.where((s) => s.x == seg.x && s.y == seg.y).length > 1) { fitsBody = false; break; }
            }
            
            if (fitsBody) {
              var testNode = ArrowNode(id: 'test', x: px, y: py, direction: dir, segments: segments);
              if (MovementEngine.canMove(testNode, generatedNodes, width, height)) {
                validPlacements.add(testNode);
                break; // Found a valid pattern for this length/dir
              }
            }
          }
        }
      }

      if (validPlacements.isEmpty) {
        retries++;
        continue;
      }

      var chosen = validPlacements[_random.nextInt(validPlacements.length)];
      generatedNodes.add(ArrowNode(
        id: 'node_${generatedNodes.length}', 
        x: chosen.x, 
        y: chosen.y, 
        direction: chosen.direction, 
        segments: chosen.segments
      ));
      retries = 0;
    }

    // Post-generation pass: Center the entire cluster
    int minX = 1000, maxX = -1000, minY = 1000, maxY = -1000;
    for (var node in generatedNodes) {
      for (var segment in node.segments) {
        minX = min(minX, segment.x); maxX = max(maxX, segment.x);
        minY = min(minY, segment.y); maxY = max(maxY, segment.y);
      }
    }

    int clusterWidth = maxX - minX + 1;
    int clusterHeight = maxY - minY + 1;
    int offsetX = (width - clusterWidth) ~/ 2 - minX;
    int offsetY = (height - clusterHeight) ~/ 2 - minY;

    List<ArrowNode> centeredNodes = generatedNodes.map((n) {
      return ArrowNode(
        id: n.id,
        x: n.x + offsetX,
        y: n.y + offsetY,
        direction: n.direction,
        segments: n.segments.map((s) => Point<int>(s.x + offsetX, s.y + offsetY)).toList(),
      );
    }).toList();

    return Level(
      id: levelId,
      nodes: centeredNodes,
      difficulty: difficulty,
      boardWidth: width,
      boardHeight: height,
    );
  }

  static List<Point<int>> _generateSegments(int px, int py, ArrowDirection dir, int length) {
    List<Point<int>> segments = [Point(px, py)];
    if (length == 1) return segments;

    int dx = 0, dy = 0;
    // Tail offset for the FIRST segment must be strictly opposite to movement
    // to ensure the head is on the tip of a matching line.
    int firstTailDx = 0;
    int firstTailDy = 0;

    switch (dir) {
      case ArrowDirection.up: 
        dy = 1; 
        firstTailDy = 1;
        break;
      case ArrowDirection.down: 
        dy = -1; 
        firstTailDy = -1;
        break;
      case ArrowDirection.left: 
        dx = 1; 
        firstTailDx = 1;
        break;
      case ArrowDirection.right: 
        dx = -1; 
        firstTailDx = -1;
        break;
    }

    // Always add the first tail segment in the correct axis
    segments.add(Point(px + firstTailDx, py + firstTailDy));
    if (length == 2) return segments;

    // From the third segment onwards, we can start snaking
    double bentChance = length > 4 ? 0.8 : 0.5;
    bool isBent = _random.nextDouble() < bentChance;

    if (!isBent) {
      for (int i = 2; i < length; i++) {
        segments.add(Point(px + i * dx, py + i * dy));
      }
    } else {
      Point<int> current = segments.last;
      Point<int> prev = segments.first;

      for (int i = 2; i < length; i++) {
        List<Point<int>> potents = [
          Point(current.x + 1, current.y),
          Point(current.x - 1, current.y),
          Point(current.x, current.y + 1),
          Point(current.x, current.y - 1),
        ];
        
        // 1. Don't backtrack
        potents.removeWhere((p) => p == prev);
        
        // 2. Head must be leading edge - no part of tail can be "ahead" of head (px, py)
        if (dir == ArrowDirection.up) potents.removeWhere((p) => p.y < py);
        if (dir == ArrowDirection.down) potents.removeWhere((p) => p.y > py);
        if (dir == ArrowDirection.left) potents.removeWhere((p) => p.x < px);
        if (dir == ArrowDirection.right) potents.removeWhere((p) => p.x > px);

        if (potents.isEmpty) break;
        
        int cdx = current.x - prev.x;
        int cdy = current.y - prev.y;
        Point<int> forward = Point(current.x + cdx, current.y + cdy);
        
        Point<int> next;
        if (_random.nextDouble() < 0.7 && potents.contains(forward)) {
          next = forward;
        } else {
           next = potents[_random.nextInt(potents.length)];
        }
        
        prev = current;
        current = next;
        segments.add(current);
      }
    }
    return segments;
  }
}
