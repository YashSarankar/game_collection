enum TileType { pink, blue, green, yellow, purple, orange, empty }

enum SpecialType {
  none,
  bomb, // Explodes 3x3
  lineHor, // Clears horizontal line
  lineVer, // Clears vertical line
  cross, // Clears horizontal & vertical
  colorBomb, // Clears all of same type
}

class TileModel {
  int r;
  int c;
  TileType type;
  SpecialType special;

  // Animation related fields
  double? xOffset;
  double? yOffset;
  bool isMatching;
  bool isNew;

  TileModel({
    required this.r,
    required this.c,
    required this.type,
    this.special = SpecialType.none,
    this.xOffset = 0,
    this.yOffset = 0,
    this.isMatching = false,
    this.isNew = false,
  });

  TileModel copy() {
    return TileModel(
      r: r,
      c: c,
      type: type,
      special: special,
      xOffset: xOffset,
      yOffset: yOffset,
      isMatching: isMatching,
      isNew: isNew,
    );
  }
}
