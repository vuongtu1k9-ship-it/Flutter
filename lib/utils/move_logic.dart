class MoveLogic {
  static bool isValidMove(
    String pieceCode,
    int fromRow,
    int fromCol,
    int toRow,
    int toCol,
    List<List<String?>> board,
  ) {
    if (toRow < 0 || toRow > 9 || toCol < 0 || toCol > 8) return false;
    if (fromRow == toRow && fromCol == toCol) return false;

    String? target = board[toRow][toCol];
    bool pieceIsRed = pieceCode == pieceCode.toUpperCase();
    String side = pieceIsRed ? 'red' : 'black';

    if (target != null) {
      bool targetIsRed = target == target.toUpperCase();
      if (targetIsRed == pieceIsRed) return false;
    }

    int rowDiff = fromRow - toRow;
    int colDiff = fromCol - toCol;
    int absRow = rowDiff.abs();
    int absCol = colDiff.abs();
    String type = pieceCode.toLowerCase();

    switch (type) {
      case 'k': // general
        bool oneStep = absCol + absRow == 1;
        if (!oneStep) return false;
        return _isInPalace(toRow, toCol, side);

      case 'a': // advisor
        return absCol == 1 && absRow == 1 && _isInPalace(toRow, toCol, side);

      case 'b': // elephant
        return absRow == 2 &&
            absCol == 2 &&
            !_isCrossRiver(toRow, side) &&
            !_isBlockedElephant(fromRow, fromCol, toRow, toCol, board);

      case 'n': // horse
        return _isHorseMove(fromRow, fromCol, toRow, toCol, board);

      case 'r': // chariot
        return (fromRow == toRow || fromCol == toCol) &&
            !_isPathBlocked(fromRow, fromCol, toRow, toCol, board);

      case 'c': // cannon
        if (!(fromRow == toRow || fromCol == toCol)) return false;
        int between = _countPiecesBetween(fromRow, fromCol, toRow, toCol, board);
        if (target == null) {
          return between == 0;
        }
        return between == 1;

      case 'p': // soldier
        if (side == 'red') {
          bool forward = toRow == fromRow - 1 && toCol == fromCol;
          bool crossed = fromRow <= 4;
          bool sideways = crossed && toRow == fromRow && absCol == 1;
          return forward || sideways;
        } else {
          bool forward = toRow == fromRow + 1 && toCol == fromCol;
          bool crossed = fromRow >= 5;
          bool sideways = crossed && toRow == fromRow && absCol == 1;
          return forward || sideways;
        }

      default:
        return false;
    }
  }

  static bool isLegalMove(
    String pieceCode,
    int fromRow,
    int fromCol,
    int toRow,
    int toCol,
    List<List<String?>> board,
  ) {
    if (!isValidMove(pieceCode, fromRow, fromCol, toRow, toCol, board)) return false;

    // Simulate move to check if general is in check
    List<List<String?>> nextBoard = List.generate(10, (r) => List.from(board[r]));
    nextBoard[toRow][toCol] = pieceCode;
    nextBoard[fromRow][fromCol] = null;

    bool pieceIsRed = pieceCode == pieceCode.toUpperCase();
    String side = pieceIsRed ? 'red' : 'black';
    return !isInCheck(side, nextBoard);
  }

  static bool isInCheck(String side, List<List<String?>> board) {
    int? kRow, kCol;
    String generalChar = side == 'red' ? 'K' : 'k';

    for (int r = 0; r < 10; r++) {
      for (int c = 0; c < 9; c++) {
        if (board[r][c] == generalChar) {
          kRow = r;
          kCol = c;
          break;
        }
      }
    }

    if (kRow == null || kCol == null) return false;

    String attackerSide = side == 'red' ? 'black' : 'red';
    
    // Facing generals
    int? otherKRow, otherKCol;
    String otherGeneralChar = side == 'red' ? 'k' : 'K';
    for (int r = 0; r < 10; r++) {
      for (int c = 0; c < 9; c++) {
        if (board[r][c] == otherGeneralChar) {
          otherKRow = r;
          otherKCol = c;
          break;
        }
      }
    }
    if (otherKRow != null && otherKCol == kCol) {
      if (_countPiecesBetween(kRow, kCol, otherKRow, otherKCol!, board) == 0) return true;
    }

    for (int r = 0; r < 10; r++) {
      for (int c = 0; c < 9; c++) {
        String? p = board[r][c];
        if (p == null) continue;
        bool pIsRed = p == p.toUpperCase();
        String pSide = pIsRed ? 'red' : 'black';
        if (pSide != attackerSide) continue;

        if (isValidMove(p, r, c, kRow, kCol, board)) return true;
      }
    }
    return false;
  }

  static bool hasAnyLegalMove(String side, List<List<String?>> board) {
    for (int r = 0; r < 10; r++) {
      for (int c = 0; c < 9; c++) {
        String? p = board[r][c];
        if (p == null) continue;
        bool pIsRed = p == p.toUpperCase();
        String pSide = pIsRed ? 'red' : 'black';
        if (pSide != side) continue;

        for (int tr = 0; tr < 10; tr++) {
          for (int tc = 0; tc < 9; tc++) {
            if (isLegalMove(p, r, c, tr, tc, board)) return true;
          }
        }
      }
    }
    return false;
  }

  static bool _isHorseMove(int fromR, int fromC, int toR, int toC, List<List<String?>> board) {
    int dr = toR - fromR;
    int dc = toC - fromC;
    int adr = dr.abs();
    int adc = dc.abs();
    if (!((adr == 2 && adc == 1) || (adr == 1 && adc == 2))) return false;

    if (adr == 2) {
      int legRow = fromR + dr.sign;
      return board[legRow][fromC] == null;
    }
    int legCol = fromC + dc.sign;
    return board[fromR][legCol] == null;
  }

  static bool _isInPalace(int r, int c, String side) {
    if (c < 3 || c > 5) return false;
    if (side == 'red') return r >= 7;
    return r <= 2;
  }

  static bool _isCrossRiver(int r, String side) {
    if (side == 'red') return r < 5;
    return r > 4;
  }

  static bool _isBlockedElephant(int fromR, int fromC, int toR, int toC, List<List<String?>> board) {
    int midR = (fromR + toR) ~/ 2;
    int midC = (fromC + toC) ~/ 2;
    return board[midR][midC] != null;
  }

  static bool _isPathBlocked(int fromR, int fromC, int toR, int toC, List<List<String?>> board) {
    return _countPiecesBetween(fromR, fromC, toR, toC, board) > 0;
  }

  static int _countPiecesBetween(int fromR, int fromC, int toR, int toC, List<List<String?>> board) {
    int count = 0;
    if (fromR == toR) {
      int minC = fromC < toC ? fromC : toC;
      int maxC = fromC > toC ? fromC : toC;
      for (int c = minC + 1; c < maxC; c++) {
        if (board[fromR][c] != null) count++;
      }
      return count;
    }
    if (fromC == toC) {
      int minR = fromR < toR ? fromR : toR;
      int maxR = fromR > toR ? fromR : toR;
      for (int r = minR + 1; r < maxR; r++) {
        if (board[r][fromC] != null) count++;
      }
      return count;
    }
    return 99;
  }
}
