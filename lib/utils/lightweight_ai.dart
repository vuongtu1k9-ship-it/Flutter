import 'dart:math';
import 'package:flutter/foundation.dart';
import 'move_logic.dart';

class LightweightAI {
  static const int _maxDepth = 4; // Increased depth for stronger AI

  // Static evaluation weights for pieces
  static const Map<String, int> _pieceValues = {
    'k': 10000,
    'a': 200,
    'b': 200,
    'n': 400,
    'r': 900,
    'c': 450,
    'p': 100, // Can be more if crossed river, handled in evaluate
  };

  static Future<Map<String, dynamic>?> getBestMove(List<List<String?>> board, String side) async {
    // Run min-max in a separate Isolate to prevent UI thread from freezing
    return await compute(_computeBestMove, {'board': board, 'side': side});
  }

  // Must be static top-level for compute
  static Map<String, dynamic>? _computeBestMove(Map<String, dynamic> args) {
    List<List<String?>> board = args['board'];
    String side = args['side'];

    List<_Move> legalMoves = _generateAllLegalMoves(board, side);
    if (legalMoves.isEmpty) return null;

    int bestScore = -999999;
    _Move? bestMove;

    // Randomize slightly if multiple moves have same score
    legalMoves.shuffle(Random());

    for (var move in legalMoves) {
      _makeMove(board, move);
      int score = -_negaMax(board, _maxDepth - 1, -999999, 999999, side == 'red' ? 'black' : 'red');
      _unmakeMove(board, move);

      if (score > bestScore) {
        bestScore = score;
        bestMove = move;
      }
    }

    if (bestMove == null && legalMoves.isNotEmpty) {
      bestMove = legalMoves.first; // Fallback
    }

    if (bestMove != null) {
      return {
        'from': {'row': bestMove.fromRow, 'col': bestMove.fromCol},
        'to': {'row': bestMove.toRow, 'col': bestMove.toCol},
      };
    }
    return null;
  }

  static int _negaMax(List<List<String?>> board, int depth, int alpha, int beta, String currentSide) {
    if (depth == 0) {
      return _evaluateBoard(board, currentSide);
    }

    List<_Move> moves = _generateAllLegalMoves(board, currentSide);
    if (moves.isEmpty) return -99999; // Lost

    int maxScore = -999999;
    String nextSide = currentSide == 'red' ? 'black' : 'red';

    for (var move in moves) {
      _makeMove(board, move);
      int score = -_negaMax(board, depth - 1, -beta, -alpha, nextSide);
      _unmakeMove(board, move);

      if (score > maxScore) maxScore = score;
      if (maxScore > alpha) alpha = maxScore;
      if (alpha >= beta) break; // Prune
    }

    return maxScore;
  }

  static int _evaluateBoard(List<List<String?>> board, String perspectiveSide) {
    int score = 0;
    for (int r = 0; r < 10; r++) {
      for (int c = 0; c < 9; c++) {
        String? piece = board[r][c];
        if (piece == null) continue;
        
        bool isRed = piece == piece.toUpperCase();
        String pieceSide = isRed ? 'red' : 'black';
        String type = piece.toLowerCase();
        
        int val = _pieceValues[type] ?? 0;
        
        // Bonus for pawns crossing river
        if (type == 'p') {
          if (isRed && r <= 4) val += 100;
          if (!isRed && r >= 5) val += 100;
        }

        if (pieceSide == perspectiveSide) {
          score += val;
        } else {
          score -= val;
        }
      }
    }
    return score;
  }

  static List<_Move> _generateAllLegalMoves(List<List<String?>> board, String side) {
    List<_Move> moves = [];
    for (int r = 0; r < 10; r++) {
      for (int c = 0; c < 9; c++) {
        String? piece = board[r][c];
        if (piece == null) continue;
        bool isRed = piece == piece.toUpperCase();
        if ((side == 'red' && isRed) || (side == 'black' && !isRed)) {
          for (int tr = 0; tr < 10; tr++) {
            for (int tc = 0; tc < 9; tc++) {
              if (MoveLogic.isLegalMove(piece, r, c, tr, tc, board)) {
                moves.add(_Move(r, c, tr, tc, board[tr][tc]));
              }
            }
          }
        }
      }
    }
    return moves;
  }

  static void _makeMove(List<List<String?>> board, _Move move) {
    board[move.toRow][move.toCol] = board[move.fromRow][move.fromCol];
    board[move.fromRow][move.fromCol] = null;
  }

  static void _unmakeMove(List<List<String?>> board, _Move move) {
    board[move.fromRow][move.fromCol] = board[move.toRow][move.toCol];
    board[move.toRow][move.toCol] = move.capturedPiece;
  }
}

class _Move {
  final int fromRow;
  final int fromCol;
  final int toRow;
  final int toCol;
  final String? capturedPiece;

  _Move(this.fromRow, this.fromCol, this.toRow, this.toCol, this.capturedPiece);
}
