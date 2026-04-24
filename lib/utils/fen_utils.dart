class FenUtils {
  static List<List<String?>> parseFen(String fen) {
    List<List<String?>> board = List.generate(10, (_) => List.filled(9, null));
    String boardPart = fen.split(' ')[0];
    List<String> rows = boardPart.split('/');

    for (int r = 0; r < rows.length; r++) {
      int c = 0;
      for (int i = 0; i < rows[r].length; i++) {
        String char = rows[r][i];
        if (int.tryParse(char) != null) {
          c += int.parse(char);
        } else {
          board[r][c] = char;
          c++;
        }
      }
    }
    return board;
  }

  static List<List<String?>> fromBoardObject(dynamic boardObj) {
    if (boardObj == null) return List.generate(10, (_) => List.filled(9, null));

    if (boardObj is String) {
      return parseFen(boardObj);
    }

    if (boardObj is List && boardObj.isNotEmpty && boardObj[0] is String) {
      return _parseLegacyBoard(boardObj.cast<String>());
    }

    List<List<String?>> board = List.generate(10, (_) => List.filled(9, null));
    for (int r = 0; r < 10; r++) {
      if (r >= (boardObj as List).length) break;
      for (int c = 0; c < 9; c++) {
        if (c >= boardObj[r].length) break;
        var piece = boardObj[r][c];
        if (piece != null) {
          String type = piece['type'];
          String side = piece['side'];
          String code = _typeToChar(type);
          // Standard FEN: Uppercase for Red, Lowercase for Black
          board[r][c] = side == 'red' ? code.toUpperCase() : code.toLowerCase();
        }
      }
    }
    return board;
  }

  static List<List<String?>> _parseLegacyBoard(List<String> pos) {
    List<List<String?>> board = List.generate(10, (_) => List.filled(9, null));
    for (var item in pos) {
      var parts = item.split(':');
      if (parts.length != 2) continue;
      String key = parts[0].toLowerCase();
      String coord = parts[1];
      
      String side = key.startsWith('r') ? 'red' : 'black';
      String typeKey = key.substring(1); 
      
      if (coord.length != 2) continue;
      int r = int.parse(coord[0]);
      int c = int.parse(coord[1]);
      
      if (r >= 0 && r < 10 && c >= 0 && c < 9) {
        String code = _legacyTypeToChar(typeKey);
        board[r][c] = side == 'red' ? code.toUpperCase() : code.toLowerCase();
      }
    }
    return board;
  }

  static String _legacyTypeToChar(String key) {
    switch (key) {
      case 'k': case 'general': return 'k';
      case 'a': case 'advisor': return 'a';
      case 'b': case 'e': case 'elephant': return 'b';
      case 'n': case 'h': case 'horse': return 'n';
      case 'r': case 'c': case 'chariot': return 'r';
      case 'c': case 'p': case 'cannon': return 'c';
      case 'p': case 's': case 'soldier': return 'p';
      default: return 'p';
    }
  }

  static String _typeToChar(String type) {
    switch (type) {
      case 'general': return 'k';
      case 'advisor': return 'a';
      case 'elephant': return 'b';
      case 'horse': return 'n';
      case 'chariot': return 'r';
      case 'cannon': return 'c';
      case 'soldier': return 'p';
      default: return 'p';
    }
  }

  static String getPieceAsset(String pieceCode) {
    // Standard FEN: Uppercase is Red
    bool isRed = pieceCode == pieceCode.toUpperCase();
    String type = pieceCode.toLowerCase();
    String side = isRed ? "red" : "black";
    
    Map<String, String> names = {
      'r': 'chariot',
      'n': 'horse',
      'b': 'elephant',
      'a': 'advisor',
      'k': 'general',
      'c': 'cannon',
      'p': 'soldier'
    };
    
    String? typeName = names[type];
    if (typeName == null) return "assets/pieces/red-soldier.svg"; // Fallback
    
    return "assets/pieces/$side-$typeName.svg";
  }
}
