/// lib/models/game.dart
/// Game state manager for Flutter Xiangqi app

import 'board.dart';
import 'piece.dart';

class Game {
  final Board board;
  PieceColor currentPlayer;
  bool isGameOver;
  String? winner;

  Game() : board = Board(), currentPlayer = PieceColor.red, isGameOver = false, winner = null;

  void switchPlayer() {
    currentPlayer = currentPlayer == PieceColor.red ? PieceColor.black : PieceColor.red;
  }

  bool checkGameOver() {
    final pieces = board.getPieces();
    Piece? redGeneral;
    Piece? blackGeneral;
    
    for (final p in pieces) {
      if (p.type == PieceType.general) {
        if (p.color == PieceColor.red) {
          redGeneral = p;
        } else {
          blackGeneral = p;
        }
      }
    }

    if (redGeneral == null) {
      isGameOver = true;
      winner = 'black';
      return true;
    }

    if (blackGeneral == null) {
      isGameOver = true;
      winner = 'red';
      return true;
    }

    return false;
  }

  bool canUndo() {
    return board.canUndo();
  }

  bool undo() {
    if (board.canUndo()) {
      board.undo();
      switchPlayer();
      return true;
    }
    return false;
  }

  void reset() {
    board.reset();
    currentPlayer = PieceColor.red;
    isGameOver = false;
    winner = null;
  }

  String getCurrentPlayerText() {
    return currentPlayer == PieceColor.red ? 'Red' : 'Black';
  }

  bool canMoveTo(int fromX, int fromY, int toX, int toY) {
    final piece = board.getPieceAt(fromX, fromY);
    if (piece == null || piece.color != currentPlayer) {
      return false;
    }
    return board.isValidMove(piece, toX, toY);
  }

  bool movePiece(int fromX, int fromY, int toX, int toY) {
    if (isGameOver) return false;

    final piece = board.getPieceAt(fromX, fromY);
    if (piece == null || piece.color != currentPlayer) {
      return false;
    }

    if (!board.movePiece(fromX, fromY, toX, toY)) {
      return false;
    }

    checkGameOver();

    if (!isGameOver) {
      switchPlayer();
    }

    return true;
  }

  List<Piece> getPieces() {
    return board.getPieces();
  }

  Piece? getPieceAt(int x, int y) {
    return board.getPieceAt(x, y);
  }

  String? analyzeLastMove() {
    return board.analyzeLastMove();
  }
}