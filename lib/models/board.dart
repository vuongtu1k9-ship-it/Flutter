/// lib/models/board.dart
/// Board model for Flutter Xiangqi app

import 'piece.dart';

class Board {
  List<List<Piece?>> board;
  List<List<Piece?>>? _history;

  Board() : board = List.generate(10, (_) => List.generate(9, (_) => null));

  void initDefault() {
    for (int y = 0; y < 10; y++) {
      for (int x = 0; x < 9; x++) {
        board[y][x] = null;
      }
    }

    board[9][0] = Piece(type: PieceType.chariot, color: PieceColor.red, x: 0, y: 9);
    board[9][1] = Piece(type: PieceType.horse, color: PieceColor.red, x: 1, y: 9);
    board[9][2] = Piece(type: PieceType.elephant, color: PieceColor.red, x: 2, y: 9);
    board[9][3] = Piece(type: PieceType.advisor, color: PieceColor.red, x: 3, y: 9);
    board[9][4] = Piece(type: PieceType.general, color: PieceColor.red, x: 4, y: 9);
    board[9][5] = Piece(type: PieceType.advisor, color: PieceColor.red, x: 5, y: 9);
    board[9][6] = Piece(type: PieceType.elephant, color: PieceColor.red, x: 6, y: 9);
    board[9][7] = Piece(type: PieceType.horse, color: PieceColor.red, x: 7, y: 9);
    board[9][8] = Piece(type: PieceType.chariot, color: PieceColor.red, x: 8, y: 9);

    board[7][1] = Piece(type: PieceType.cannon, color: PieceColor.red, x: 1, y: 7);
    board[7][7] = Piece(type: PieceType.cannon, color: PieceColor.red, x: 7, y: 7);

    board[6][0] = Piece(type: PieceType.soldier, color: PieceColor.red, x: 0, y: 6);
    board[6][2] = Piece(type: PieceType.soldier, color: PieceColor.red, x: 2, y: 6);
    board[6][4] = Piece(type: PieceType.soldier, color: PieceColor.red, x: 4, y: 6);
    board[6][6] = Piece(type: PieceType.soldier, color: PieceColor.red, x: 6, y: 6);
    board[6][8] = Piece(type: PieceType.soldier, color: PieceColor.red, x: 8, y: 6);

    board[0][0] = Piece(type: PieceType.chariot, color: PieceColor.black, x: 0, y: 0);
    board[0][1] = Piece(type: PieceType.horse, color: PieceColor.black, x: 1, y: 0);
    board[0][2] = Piece(type: PieceType.elephant, color: PieceColor.black, x: 2, y: 0);
    board[0][3] = Piece(type: PieceType.advisor, color: PieceColor.black, x: 3, y: 0);
    board[0][4] = Piece(type: PieceType.general, color: PieceColor.black, x: 4, y: 0);
    board[0][5] = Piece(type: PieceType.advisor, color: PieceColor.black, x: 5, y: 0);
    board[0][6] = Piece(type: PieceType.elephant, color: PieceColor.black, x: 6, y: 0);
    board[0][7] = Piece(type: PieceType.horse, color: PieceColor.black, x: 7, y: 0);
    board[0][8] = Piece(type: PieceType.chariot, color: PieceColor.black, x: 8, y: 0);

    board[3][1] = Piece(type: PieceType.cannon, color: PieceColor.black, x: 1, y: 3);
    board[3][7] = Piece(type: PieceType.cannon, color: PieceColor.black, x: 7, y: 3);

    board[3][0] = Piece(type: PieceType.soldier, color: PieceColor.black, x: 0, y: 3);
    board[3][2] = Piece(type: PieceType.soldier, color: PieceColor.black, x: 2, y: 3);
    board[3][4] = Piece(type: PieceType.soldier, color: PieceColor.black, x: 4, y: 3);
    board[3][6] = Piece(type: PieceType.soldier, color: PieceColor.black, x: 6, y: 3);
    board[3][8] = Piece(type: PieceType.soldier, color: PieceColor.black, x: 8, y: 3);
  }

  Piece? getPiece(int x, int y) {
    if (x < 0 || x > 8 || y < 0 || y > 9) return null;
    return board[y][x];
  }

  bool movePiece(int fromX, int fromY, int toX, int toY) {
    final piece = getPiece(fromX, fromY);
    if (piece == null) return false;
    
    final target = getPiece(toX, toY);
    if (target != null && target.color == piece.color) return false;
    
    _history ??= [];
    _history!.add(_copyBoard(board));
    
    board[fromY][fromX] = null;
    piece.x = toX;
    piece.y = toY;
    board[toY][toX] = piece;
    return true;
  }

  List<List<Piece?>> _copyBoard(List<List<Piece?>> src) {
    return src.map((row) => row.map((p) => p?.copy()).toList()).toList();
  }

  bool canUndo() {
    return _history != null && _history!.isNotEmpty;
  }

  void undo() {
    if (canUndo()) {
      board = _history!.removeLast();
    }
  }

  bool isValidMove(Piece piece, int toX, int toY) {
    if (toX < 0 || toX > 8 || toY < 0 || toY > 9) return false;
    
    final target = getPiece(toX, toY);
    if (target != null && target.color == piece.color) return false;

    switch (piece.type) {
      case PieceType.general:
        return _isValidGeneralMove(piece, toX, toY);
      case PieceType.advisor:
        return _isValidAdvisorMove(piece, toX, toY);
      case PieceType.elephant:
        return _isValidElephantMove(piece, toX, toY);
      case PieceType.chariot:
        return _isValidChariotMove(piece, toX, toY);
      case PieceType.cannon:
        return _isValidCannonMove(piece, toX, toY);
      case PieceType.horse:
        return _isValidHorseMove(piece, toX, toY);
      case PieceType.soldier:
        return _isValidSoldierMove(piece, toX, toY);
    }
  }

  bool _isValidGeneralMove(Piece piece, int toX, int toY) {
    final dx = (toX - piece.x).abs();
    final dy = (toY - piece.y).abs();
    if (dx + dy != 1) return false;
    return inPalace(toX, toY, piece.color);
  }

  bool _isValidAdvisorMove(Piece piece, int toX, int toY) {
    final dx = (toX - piece.x).abs();
    final dy = (toY - piece.y).abs();
    if (dx != 1 || dy != 1) return false;
    return inPalace(toX, toY, piece.color);
  }

  bool _isValidElephantMove(Piece piece, int toX, int toY) {
    final dx = (toX - piece.x).abs();
    final dy = (toY - piece.y).abs();
    if (dx != 2 || dy != 2) return false;
    if (piece.color == PieceColor.red && toY > 4) return false;
    if (piece.color == PieceColor.black && toY < 5) return false;
    final midX = (piece.x + toX) ~/ 2;
    final midY = (piece.y + toY) ~/ 2;
    return getPiece(midX, midY) == null;
  }

  bool _isValidChariotMove(Piece piece, int toX, int toY) {
    if (piece.x != toX && piece.y != toY) return false;
    if (piece.x == toX) {
      final minY = piece.y < toY ? piece.y : toY;
      final maxY = piece.y < toY ? toY : piece.y;
      for (int y = minY + 1; y < maxY; y++) {
        if (getPiece(piece.x, y) != null) return false;
      }
    } else {
      final minX = piece.x < toX ? piece.x : toX;
      final maxX = piece.x < toX ? toX : piece.x;
      for (int x = minX + 1; x < maxX; x++) {
        if (getPiece(x, piece.y) != null) return false;
      }
    }
    return true;
  }

  bool _isValidCannonMove(Piece piece, int toX, int toY) {
    if (piece.x != toX && piece.y != toY) return false;
    int count = 0;
    if (piece.x == toX) {
      final minY = piece.y < toY ? piece.y : toY;
      final maxY = piece.y < toY ? toY : piece.y;
      for (int y = minY + 1; y < maxY; y++) {
        if (getPiece(piece.x, y) != null) count++;
      }
    } else {
      final minX = piece.x < toX ? piece.x : toX;
      final maxX = piece.x < toX ? toX : piece.x;
      for (int x = minX + 1; x < maxX; x++) {
        if (getPiece(x, piece.y) != null) count++;
      }
    }
    final target = getPiece(toX, toY);
    if (target == null) return count == 0;
    return count == 1;
  }

  bool _isValidHorseMove(Piece piece, int toX, int toY) {
    final dx = (toX - piece.x).abs();
    final dy = (toY - piece.y).abs();
    if (!((dx == 1 && dy == 2) || (dx == 2 && dy == 1))) return false;
    if (dx == 2) {
      final midX = (piece.x + toX) ~/ 2;
      return getPiece(midX, piece.y) == null;
    } else {
      final midY = (piece.y + toY) ~/ 2;
      return getPiece(piece.x, midY) == null;
    }
  }

  bool _isValidSoldierMove(Piece piece, int toX, int toY) {
    final dy = toY - piece.y;
    if (piece.color == PieceColor.red) {
      if (piece.y < 5) {
        return dy == 1 && toX == piece.x;
      } else {
        return (dy == 1 && toX == piece.x) || (dy == 0 && (toX - piece.x).abs() == 1);
      }
    } else {
      if (piece.y > 4) {
        return dy == -1 && toX == piece.x;
      } else {
        return (dy == -1 && toX == piece.x) || (dy == 0 && (toX - piece.x).abs() == 1);
      }
    }
  }

  bool inPalace(int x, int y, PieceColor color) {
    if (x < 3 || x > 5) return false;
    if (color == PieceColor.red) {
      return y >= 7 && y <= 9;
    } else {
      return y >= 0 && y <= 2;
    }
  }

  List<Piece> getPieces() {
    final pieces = <Piece>[];
    for (int y = 0; y < 10; y++) {
      for (int x = 0; x < 9; x++) {
        final piece = board[y][x];
        if (piece != null) pieces.add(piece);
      }
    }
    return pieces;
  }

  String? analyzeLastMove() {
    return null;
  }
}