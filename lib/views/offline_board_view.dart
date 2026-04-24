import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:xiangqi_mobile/utils/fen_utils.dart';
import 'package:xiangqi_mobile/utils/move_logic.dart';
import 'package:xiangqi_mobile/utils/lightweight_ai.dart';
import 'package:xiangqi_mobile/models/game_models.dart';

class PieceModel {
  final String id;
  final String code;
  int row;
  int col;

  PieceModel({required this.id, required this.code, required this.row, required this.col});
}

class OfflineBoardView extends StatefulWidget {
  final bool playVsBot;

  const OfflineBoardView({
    super.key,
    this.playVsBot = false,
  });

  @override
  State<OfflineBoardView> createState() => _OfflineBoardViewState();
}

class _OfflineBoardViewState extends State<OfflineBoardView> {
  Offset? _selectedCell;
  Offset? _lastMoveFrom;
  Offset? _lastMoveTo;
  List<Offset> _legalMoves = [];
  List<Offset> _captureMoves = [];
  List<List<String?>> _boardData = List.generate(10, (_) => List.filled(9, null));
  List<PieceModel> _pieces = [];
  Map<String, dynamic> _playersInfo = {'red': {'name': 'Người chơi 1', 'elo': 1200}, 'black': {'name': 'Người chơi 2', 'elo': 1200}};
  bool _isFlipped = false; 
  String _currentSide = 'red';
  String _mySide = 'red'; // Luôn nhìn từ góc Đỏ
  final AudioPlayer _audioPlayer = AudioPlayer();
  bool _isFinished = false;
  bool _isAiThinking = false;
  String _selectedEngine = 'lightweight';

  @override
  void initState() {
    super.initState();
    _loadSettingsAndInit();
  }

  Future<void> _loadSettingsAndInit() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _selectedEngine = prefs.getString('offlineEngine') ?? 'lightweight';
    });
    _initOfflineGame();
  }

  void _initOfflineGame() {
    setState(() {
      _boardData = FenUtils.parseFen('rnbakabnr/9/1c5c1/p1p1p1p1p/9/9/P1P1P1P1P/1C5C1/9/RNBAKABNR');
      _currentSide = 'red';
      _isFinished = false;
      _lastMoveFrom = null;
      _lastMoveTo = null;
      _selectedCell = null;
      _legalMoves = [];
      _captureMoves = [];
      
      _playersInfo = {
        'red': {'name': 'Người chơi (Đỏ)', 'elo': 1200},
        'black': {'name': widget.playVsBot ? 'Máy (${_selectedEngine == "lightweight" ? "Nhẹ" : "Pikafish"})' : 'Người chơi (Đen)', 'elo': widget.playVsBot ? 2500 : 1200}
      };
      
      _syncPiecesFromBoard();
    });
    _playSound('start');
  }

  void _syncPiecesFromBoard() {
    List<PieceModel> newPieces = [];
    for (int r = 0; r < 10; r++) {
      for (int c = 0; c < 9; c++) {
        String? code = _boardData[r][c];
        if (code != null) {
          newPieces.add(PieceModel(
            id: 'piece-$r-$c-$code-${DateTime.now().microsecondsSinceEpoch}',
            code: code,
            row: r,
            col: c,
          ));
        }
      }
    }
    setState(() {
      _pieces = newPieces;
    });
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }

  void _playSound(String type) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      bool vibrateEnabled = prefs.getBool('vibrateEnabled') ?? true;
      if (vibrateEnabled && (type == 'move' || type == 'capture' || type == 'check')) {
        if (type == 'capture' || type == 'check') {
          HapticFeedback.mediumImpact();
        } else {
          HapticFeedback.lightImpact();
        }
      }

      bool soundEnabled = prefs.getBool('soundEnabled') ?? true;
      if (!soundEnabled) return;

      if (_audioPlayer.state == PlayerState.playing) {
        await _audioPlayer.stop();
      }
      await _audioPlayer.play(AssetSource('sounds/$type.mp3'));
    } catch (e) {
      debugPrint('Error playing sound: $e');
    }
  }

  void _applyMove(Map<String, dynamic> from, Map<String, dynamic> to) {
    int fromRow = from['row'];
    int fromCol = from['col'];
    int toRow = to['row'];
    int toCol = to['col'];
    
    if (fromRow >= 0 && fromRow < 10 && fromCol >= 0 && fromCol < 9 &&
        toRow >= 0 && toRow < 10 && toCol >= 0 && toCol < 9) {
      
      bool isCapture = _boardData[toRow][toCol] != null;
      
      setState(() {
        try {
          PieceModel movingPieceObj = _pieces.firstWhere((p) => p.row == fromRow && p.col == fromCol);
          _pieces.removeWhere((p) => p != movingPieceObj && p.row == toRow && p.col == toCol);
          movingPieceObj.row = toRow;
          movingPieceObj.col = toCol;
        } catch (e) {
          _syncPiecesFromBoard();
        }

        if (_boardData[fromRow][fromCol] != null) {
          _boardData[toRow][toCol] = _boardData[fromRow][fromCol];
          _boardData[fromRow][fromCol] = null;
          _lastMoveFrom = Offset(fromCol.toDouble(), fromRow.toDouble());
          _lastMoveTo = Offset(toCol.toDouble(), toRow.toDouble());
        }
        
        _currentSide = (_currentSide == 'red' ? 'black' : 'red');
      });
      
      _playSound(isCapture ? 'capture' : 'move');
      _checkGameState();

      // Nếu tới lượt Máy
      if (!_isFinished && widget.playVsBot && _currentSide == 'black') {
        _handleAiMove();
      }
    }
  }

  Future<void> _handleAiMove() async {
    setState(() => _isAiThinking = true);
    
    Map<String, dynamic>? bestMove;
    if (_selectedEngine == 'pikafish') {
      // Placeholder: Tương lai gọi Pikafish FFI
      // Tạm thời fallback về lightweight + giả lập delay tải Engine
      await Future.delayed(const Duration(seconds: 2));
      bestMove = await LightweightAI.getBestMove(_boardData, 'black');
    } else {
      bestMove = await LightweightAI.getBestMove(_boardData, 'black');
    }

    if (mounted) {
      setState(() => _isAiThinking = false);
      if (bestMove != null) {
        _applyMove(bestMove['from'], bestMove['to']);
      } else {
        // AI không tìm được nước đi (hết cờ)
        _checkGameState();
      }
    }
  }

  void _checkGameState() {
    bool isCheck = MoveLogic.isInCheck(_currentSide, _boardData);
    bool hasMoves = MoveLogic.hasAnyLegalMove(_currentSide, _boardData);

    if (isCheck && hasMoves) {
      _playSound('check');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.warning_amber_rounded, color: Colors.white),
              const SizedBox(width: 12),
              Text(
                'CHIẾU TƯỚNG! (${_currentSide == 'red' ? 'Bên Đỏ' : 'Bên Đen'})',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ],
          ),
          duration: const Duration(milliseconds: 1500),
          backgroundColor: Colors.red.shade800,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          margin: const EdgeInsets.all(16),
        ),
      );
    }

    if (!hasMoves) {
      setState(() => _isFinished = true);
      String winner = _currentSide == 'red' ? 'Đen' : 'Đỏ';
      String reason = isCheck ? 'Chiếu bí (Checkmate)' : 'Hết nước đi (Stalemate)';
      _playSound('win');
      
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          backgroundColor: const Color(0xFF2C1810),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20), 
            side: const BorderSide(color: Color(0xFFF59E0B), width: 1),
          ),
          title: Center(
            child: Text(
              'KẾT THÚC TRẬN ĐẤU',
              style: TextStyle(color: const Color(0xFFF59E0B), fontWeight: FontWeight.bold, letterSpacing: 1.5),
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 10),
              Text(
                '$winner THẮNG!',
                style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                reason,
                style: const TextStyle(color: Colors.white70, fontSize: 14),
              ),
            ],
          ),
          actions: [
            Center(
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFF59E0B),
                  foregroundColor: Colors.black,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                ),
                onPressed: () {
                  Navigator.pop(context); // Close dialog
                  _initOfflineGame(); // Reset
                },
                child: const Text('CHƠI LẠI VÁN MỚI', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      );
    }
  }

  void _onTapDown(TapDownDetails details, Size size) {
    if (_isFinished) return;
    if (widget.playVsBot && _currentSide == 'black') return; // AI đang đi

    double cellW = size.width / 9;
    double cellH = size.height / 10;
    int screenCol = (details.localPosition.dx / cellW).floor();
    int screenRow = (details.localPosition.dy / cellH).floor();
    int col = _isFlipped ? 8 - screenCol : screenCol;
    int row = _isFlipped ? 9 - screenRow : screenRow;

    setState(() {
      if (_selectedCell == null) {
        String? piece = _boardData[row][col];
        if (piece == null) return;
        
        bool pieceIsRed = piece == piece.toUpperCase();
        String pieceSide = pieceIsRed ? 'red' : 'black';
        
        if (_currentSide != pieceSide) return;
        
        _selectedCell = Offset(col.toDouble(), row.toDouble());
        _calculateLegalMoves(row, col, piece);
      } else {
        final int fromRow = _selectedCell!.dy.toInt();
        final int fromCol = _selectedCell!.dx.toInt();
        
        if (fromRow == row && fromCol == col) {
          _selectedCell = null;
          _legalMoves = [];
          _captureMoves = [];
          return;
        }

        bool isLegal = false;
        for (var move in _legalMoves) {
          if (move.dx.toInt() == col && move.dy.toInt() == row) {
            isLegal = true; break;
          }
        }
        if (!isLegal) {
          for (var move in _captureMoves) {
            if (move.dx.toInt() == col && move.dy.toInt() == row) {
              isLegal = true; break;
            }
          }
        }

        if (!isLegal) {
          String? piece = _boardData[row][col];
          if (piece != null) {
            bool pieceIsRed = piece == piece.toUpperCase();
            String pieceSide = pieceIsRed ? 'red' : 'black';
            if (pieceSide == _currentSide) {
              _selectedCell = Offset(col.toDouble(), row.toDouble());
              _calculateLegalMoves(row, col, piece);
              return;
            }
          }
          _selectedCell = null;
          _legalMoves = [];
          _captureMoves = [];
          return;
        }

        _applyMove({'row': fromRow, 'col': fromCol}, {'row': row, 'col': col});
        _selectedCell = null;
        _legalMoves = [];
        _captureMoves = [];
      }
    });
  }

  void _calculateLegalMoves(int row, int col, String piece) {
    List<Offset> moves = [];
    List<Offset> captures = [];
    for (int r = 0; r < 10; r++) {
      for (int c = 0; c < 9; c++) {
        if (MoveLogic.isLegalMove(piece, row, col, r, c, _boardData)) {
          if (_boardData[r][c] != null) {
            captures.add(Offset(c.toDouble(), r.toDouble()));
          } else {
            moves.add(Offset(c.toDouble(), r.toDouble()));
          }
        }
      }
    }
    setState(() {
      _legalMoves = moves;
      _captureMoves = captures;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF2C1810),
      appBar: AppBar(
        title: Text(
          widget.playVsBot ? 'Chơi Với Máy (Offline)' : 'Chơi 2 Người (Offline)',
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, letterSpacing: 1.2),
        ),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.sync),
            onPressed: () => setState(() => _isFlipped = !_isFlipped),
            tooltip: 'Xoay bàn cờ',
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Top Player (Black)
            _buildPlayerPanel('black'),
            
            // Chess Board
            Expanded(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: AspectRatio(
                    aspectRatio: 9 / 10,
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        return GestureDetector(
                          onTapDown: (details) => _onTapDown(details, constraints.biggest),
                          child: Stack(
                            children: [
                              _buildBoardBackground(),
                              _buildGridLines(constraints.biggest),
                              ..._buildHighlights(constraints.biggest),
                              ..._pieces.map((p) => _buildPiece(p, constraints.biggest)),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ),
            ),

            // Controls & Bottom Player (Red)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  ElevatedButton.icon(
                    onPressed: _initOfflineGame,
                    icon: const Icon(Icons.refresh, size: 18),
                    label: const Text('Chơi Lại'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white10,
                      foregroundColor: Colors.white,
                    ),
                  ),
                  if (_isAiThinking)
                    const Row(
                      children: [
                        SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.amber, strokeWidth: 2)),
                        SizedBox(width: 8),
                        Text('Máy đang nghĩ...', style: TextStyle(color: Colors.amber)),
                      ],
                    )
                ],
              ),
            ),
            _buildPlayerPanel('red'),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildPlayerPanel(String side) {
    Map<String, dynamic> info = _playersInfo[side] ?? {};
    bool isCurrentTurn = _currentSide == side;
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: isCurrentTurn ? Colors.white.withOpacity(0.1) : Colors.transparent,
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: side == 'red' ? Colors.red.shade900 : Colors.grey.shade800,
            radius: 20,
            child: Icon(side == 'red' ? Icons.person : (widget.playVsBot && side == 'black' ? Icons.computer : Icons.person), color: Colors.white),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  info['name'] ?? 'Player',
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  'Elo: ${info['elo'] ?? 1200}',
                  style: const TextStyle(color: Colors.amber, fontSize: 12),
                ),
              ],
            ),
          ),
          if (isCurrentTurn)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.amber.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.amber, width: 1),
              ),
              child: const Text('LƯỢT ĐI', style: TextStyle(color: Colors.amber, fontSize: 12, fontWeight: FontWeight.bold)),
            )
        ],
      ),
    );
  }

  Widget _buildBoardBackground() {
    return Positioned.fill(
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFFD4A373),
          borderRadius: BorderRadius.circular(4),
          border: Border.all(color: const Color(0xFF8B4513), width: 3),
        ),
      ),
    );
  }

  Widget _buildGridLines(Size size) {
    return Positioned.fill(
      child: CustomPaint(
        painter: ChessBoardPainter(),
        size: size,
      ),
    );
  }

  List<Widget> _buildHighlights(Size size) {
    List<Widget> highlights = [];
    double cellW = size.width / 9;
    double cellH = size.height / 10;

    if (_lastMoveFrom != null) {
      int screenCol = _isFlipped ? 8 - _lastMoveFrom!.dx.toInt() : _lastMoveFrom!.dx.toInt();
      int screenRow = _isFlipped ? 9 - _lastMoveFrom!.dy.toInt() : _lastMoveFrom!.dy.toInt();
      highlights.add(Positioned(
        left: screenCol * cellW, top: screenRow * cellH, width: cellW, height: cellH,
        child: Container(color: Colors.blue.withOpacity(0.3)),
      ));
    }
    if (_lastMoveTo != null) {
      int screenCol = _isFlipped ? 8 - _lastMoveTo!.dx.toInt() : _lastMoveTo!.dx.toInt();
      int screenRow = _isFlipped ? 9 - _lastMoveTo!.dy.toInt() : _lastMoveTo!.dy.toInt();
      highlights.add(Positioned(
        left: screenCol * cellW, top: screenRow * cellH, width: cellW, height: cellH,
        child: Container(color: Colors.blue.withOpacity(0.4)),
      ));
    }
    if (_selectedCell != null) {
      int screenCol = _isFlipped ? 8 - _selectedCell!.dx.toInt() : _selectedCell!.dx.toInt();
      int screenRow = _isFlipped ? 9 - _selectedCell!.dy.toInt() : _selectedCell!.dy.toInt();
      highlights.add(Positioned(
        left: screenCol * cellW, top: screenRow * cellH, width: cellW, height: cellH,
        child: Container(
          decoration: BoxDecoration(color: Colors.green.withOpacity(0.4), border: Border.all(color: Colors.green, width: 2)),
        ),
      ));
    }

    for (var move in _legalMoves) {
      int screenCol = _isFlipped ? 8 - move.dx.toInt() : move.dx.toInt();
      int screenRow = _isFlipped ? 9 - move.dy.toInt() : move.dy.toInt();
      highlights.add(Positioned(
        left: screenCol * cellW, top: screenRow * cellH, width: cellW, height: cellH,
        child: Center(child: Container(width: cellW * 0.3, height: cellH * 0.3, decoration: const BoxDecoration(color: Colors.green, shape: BoxShape.circle))),
      ));
    }

    for (var move in _captureMoves) {
      int screenCol = _isFlipped ? 8 - move.dx.toInt() : move.dx.toInt();
      int screenRow = _isFlipped ? 9 - move.dy.toInt() : move.dy.toInt();
      highlights.add(Positioned(
        left: screenCol * cellW, top: screenRow * cellH, width: cellW, height: cellH,
        child: Center(
          child: Container(
            width: cellW * 0.8, height: cellH * 0.8,
            decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: Colors.red, width: 3)),
          ),
        ),
      ));
    }
    return highlights;
  }

  Widget _buildPiece(PieceModel p, Size size) {
    double cellW = size.width / 9;
    double cellH = size.height / 10;
    
    int screenCol = _isFlipped ? 8 - p.col : p.col;
    int screenRow = _isFlipped ? 9 - p.row : p.row;
    
    String assetPath = FenUtils.getPieceAsset(p.code);

    return AnimatedPositioned(
      key: ValueKey(p.id),
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      left: screenCol * cellW,
      top: screenRow * cellH,
      width: cellW,
      height: cellH,
      child: Center(
        child: Container(
          width: cellW * 0.9,
          height: cellH * 0.9,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white.withOpacity(0.5),
          ),
          child: ClipOval(
            child: SvgPicture.asset(assetPath, fit: BoxFit.contain),
          ),
        ),
      ),
    );
  }
}

class ChessBoardPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF8B4513)
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    double cellW = size.width / 9;
    double cellH = size.height / 10;

    for (int i = 0; i < 10; i++) canvas.drawLine(Offset(cellW / 2, i * cellH + cellH / 2), Offset(size.width - cellW / 2, i * cellH + cellH / 2), paint);
    for (int i = 0; i < 9; i++) {
      canvas.drawLine(Offset(i * cellW + cellW / 2, cellH / 2), Offset(i * cellW + cellW / 2, 4 * cellH + cellH / 2), paint);
      canvas.drawLine(Offset(i * cellW + cellW / 2, 5 * cellH + cellH / 2), Offset(i * cellW + cellW / 2, size.height - cellH / 2), paint);
    }
    canvas.drawLine(Offset(0 * cellW + cellW / 2, cellH / 2), Offset(0 * cellW + cellW / 2, size.height - cellH / 2), paint);
    canvas.drawLine(Offset(8 * cellW + cellW / 2, cellH / 2), Offset(8 * cellW + cellW / 2, size.height - cellH / 2), paint);
    canvas.drawLine(Offset(3 * cellW + cellW / 2, 0 * cellH + cellH / 2), Offset(5 * cellW + cellW / 2, 2 * cellH + cellH / 2), paint);
    canvas.drawLine(Offset(5 * cellW + cellW / 2, 0 * cellH + cellH / 2), Offset(3 * cellW + cellW / 2, 2 * cellH + cellH / 2), paint);
    canvas.drawLine(Offset(3 * cellW + cellW / 2, 7 * cellH + cellH / 2), Offset(5 * cellW + cellW / 2, 9 * cellH + cellH / 2), paint);
    canvas.drawLine(Offset(5 * cellW + cellW / 2, 7 * cellH + cellH / 2), Offset(3 * cellW + cellW / 2, 9 * cellH + cellH / 2), paint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}
