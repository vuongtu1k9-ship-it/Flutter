enum PieceType {
  general,
  advisor,
  elephant,
  chariot,
  cannon,
  horse,
  soldier
}

enum PieceColor {
  red,
  black
}

class Piece {
  final PieceType type;
  final PieceColor color;
  int x;
  int y;

  Piece({
    required this.type,
    required this.color,
    required this.x,
    required this.y,
  });

  Piece copy() {
    return Piece(
      type: type,
      color: color,
      x: x,
      y: y,
    );
  }
}
