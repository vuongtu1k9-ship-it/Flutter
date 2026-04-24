import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:xiangqi_mobile/services/socket_service.dart';
import 'package:xiangqi_mobile/services/api_service.dart';
import 'package:xiangqi_mobile/utils/fen_utils.dart';
import 'package:xiangqi_mobile/utils/move_logic.dart';
import 'package:xiangqi_mobile/models/game_models.dart';

class PieceModel {
  final String id;
  final String code;
  int row;
  int col;

  PieceModel({required this.id, required this.code, required this.row, required this.col});
}

class BoardView extends StatefulWidget {
  final String roomId;
  final SocketService socketService;
  final ApiService apiService;
  final VoidCallback onLogout;
  final bool isPuzzle;
  final List<dynamic>? initialBoard;
  final String? initialFen;
  final String? title;
  final Map<String, dynamic>? currentUserData;
  final List<User>? onlinePlayers;
  final List<User>? bots;

  const BoardView({
    super.key,
    required this.roomId,
    required this.socketService,
    required this.apiService,
    required this.onLogout,
    this.isPuzzle = false,
    this.initialBoard,
    this.initialFen,
    this.title,
    this.currentUserData,
    this.onlinePlayers,
    this.bots,
  });

  @override
  State<BoardView> createState() => _BoardViewState();
}

class _BoardViewState extends State<BoardView> {
  Offset? _selectedCell;
  Offset? _lastMoveFrom;
  Offset? _lastMoveTo;
  String? _initialFen; // Để reset cờ thế
  List<Offset> _legalMoves = [];
  List<Offset> _captureMoves = [];
  List<List<String?>> _boardData = List.generate(10, (_) => List.filled(9, null));
  List<PieceModel> _pieces = [];
  Map<String, dynamic> _playersInfo = {'red': {'name': '...'}, 'black': {'name': '...'}};
  bool _isFlipped = false; 
  bool _isLoadingBoard = true;
  bool _isReconnecting = false;
  bool _isSpectator = false;
  int _reconnectAttempt = 0;
  String _currentSide = 'red';
  String? _mySide;
  final AudioPlayer _audioPlayer = AudioPlayer();
  final List<Map<String, dynamic>> _chatMessages = [];
  final TextEditingController _chatController = TextEditingController();
  
  // Timer State
  Map<String, dynamic>? _clock;
  int _serverClockOffset = 0;
  Timer? _timer;
  bool _isFinished = false;

  @override
  void initState() {
    super.initState();
    _initialFen = widget.initialFen;
    if (widget.isPuzzle) {
      _initPuzzle();
    } else {
      _initOnlineGame();
      _setupChatListeners();
      _setupReconnectCallbacks();
    }
    
    _timer = Timer.periodic(const Duration(milliseconds: 100), (_) {
      if (_clock != null && !_isFinished && mounted) {
        setState(() {}); // Trigger rebuild
      }
    });
  }

  void _setupReconnectCallbacks() {
    widget.socketService.onReconnecting = (attempt, max) {
      if (mounted) setState(() { _isReconnecting = true; _reconnectAttempt = attempt; });
    };
    widget.socketService.onReconnected = () {
      if (mounted) setState(() => _isReconnecting = false);
    };
    widget.socketService.onReconnectFailed = () {
      if (!mounted) return;
      setState(() => _isReconnecting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Mất kết nối. Vui lòng thử lại.')),
      );
      Navigator.pop(context);
    };
  }

  void _setupChatListeners() {
    widget.socketService.onChatMessage((data) {
      if (mounted) {
        setState(() {
          _chatMessages.add(data);
        });
      }
    });
  }

  void _enrichPlayersInfo() {
    // Ensure both sides exist
    if (!_playersInfo.containsKey('red')) _playersInfo['red'] = {'name': 'Trống'};
    if (!_playersInfo.containsKey('black')) _playersInfo['black'] = {'name': 'Trống'};

    for (var side in ['red', 'black']) {
      var info = _playersInfo[side];
      if (info == null) {
        _playersInfo[side] = {'name': 'Trống'};
        continue;
      }
      
      String name = (info is String) ? info : info['name'] ?? '';
      if (name.isEmpty) name = 'Trống';
      
      User? matchedUser;
      
      // 1. If this side is MY side, it's ME!
      if (side == _mySide && widget.currentUserData != null) {
        matchedUser = User(
          uid: widget.currentUserData!['uid'] ?? '',
          name: widget.currentUserData!['name'] ?? name,
          picture: widget.currentUserData!['avatar'] ?? widget.currentUserData!['picture'],
          elo: widget.currentUserData!['elo'] is int ? widget.currentUserData!['elo'] : int.tryParse(widget.currentUserData!['elo']?.toString() ?? '') ?? 1200,
        );
      }
      
      // 2. Otherwise try bots
      if (matchedUser == null && widget.bots != null) {
        try { matchedUser = widget.bots!.firstWhere((b) => b.name == name); } catch (_) {}
      }
      
      // 3. Try online players
      if (matchedUser == null && widget.onlinePlayers != null) {
        try { matchedUser = widget.onlinePlayers!.firstWhere((p) => p.name == name); } catch (_) {}
      }
      
      if (matchedUser != null) {
        _playersInfo[side] = {
          'name': matchedUser.name.isEmpty ? name : matchedUser.name,
          'avatar': matchedUser.picture,
          'elo': matchedUser.elo,
        };
      } else if (info is String) {
        _playersInfo[side] = {
          'name': name,
          'elo': 1200,
        };
      } else if (info is Map) {
        Map<String, dynamic> newInfo = Map<String, dynamic>.from(info);
        newInfo['name'] = name;
        if (newInfo['elo'] == null || newInfo['elo'] == '') newInfo['elo'] = 1200;
        _playersInfo[side] = newInfo;
      }
    }
  }

  void _resetPuzzle() {
    setState(() {
      if (widget.initialBoard != null) {
        _boardData = FenUtils.fromBoardObject(widget.initialBoard!);
      } else if (_initialFen != null) {
        _boardData = FenUtils.parseFen(_initialFen!);
      }
      _currentSide = 'red';
      _lastMoveFrom = null;
      _lastMoveTo = null;
      _selectedCell = null;
      _legalMoves = [];
      _captureMoves = [];
      _syncPiecesFromBoard();
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Đã làm lại từ đầu')),
    );
  }

  void _showHint() async {
    if (_currentSide != 'red') return;
    
    setState(() => _isLoadingBoard = true);
    
    List<List<Map<String, dynamic>?>> serverBoard = List.generate(10, (r) => List.generate(9, (c) {
      String? code = _boardData[r][c];
      if (code == null) return null;
      bool isRed = code == code.toUpperCase();
      return {
        'side': isRed ? 'red' : 'black',
        'type': _charToType(code.toLowerCase()),
      };
    }));

    widget.socketService.requestEngineBestMove({
      'board': serverBoard,
      'side': 'red',
      'movetimeMs': 1500,
    }, (data) {
      setState(() => _isLoadingBoard = false);
      if (data != null && data['ok'] == true) {
        var from = data['from'];
        var to = data['to'];
        if (from != null && to != null) {
          setState(() {
            _selectedCell = Offset(from['col'].toDouble(), from['row'].toDouble());
            _calculateLegalMoves(from['row'], from['col'], _boardData[from['row']][from['col']]!);
          });
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Gợi ý: Hãy di chuyển quân cờ đang được chọn')),
          );
        }
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    // FIX BUG-007: Clear socket listeners to prevent memory leak
    widget.socketService.clearGameListeners();
    widget.socketService.off('room:players');
    widget.socketService.off('chat:message');
    widget.socketService.off('bot:taunt');

    _audioPlayer.dispose();
    _chatController.dispose();
    super.dispose();
  }

  void _syncPiecesFromBoard() {
    List<PieceModel> newPieces = [];
    for (int r = 0; r < 10; r++) {
      for (int c = 0; c < 9; c++) {
        String? code = _boardData[r][c];
        if (code != null) {
          // Create a stable ID based on initial discovery or just use coordinates for now
          // but for animation we need to try and preserve IDs between moves.
          // For initial load, we just generate IDs.
          newPieces.add(PieceModel(
            id: 'piece-${r}-${c}-${code}-${DateTime.now().microsecondsSinceEpoch}',
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

  void _initPuzzle() {
    setState(() {
      if (widget.initialBoard != null) {
        _boardData = FenUtils.fromBoardObject(widget.initialBoard!);
      } else if (widget.initialFen != null) {
        _boardData = FenUtils.parseFen(widget.initialFen!);
      }
      String myName = widget.currentUserData?['name'] ?? 'Bạn';
      String? myAvatar = widget.currentUserData?['avatar'] ?? widget.currentUserData?['picture'];
      
      _playersInfo = {
        'red': {'name': myName, 'avatar': myAvatar},
        'black': {'name': 'Máy (Pikafish)', 'avatar': '/img/bot/pikafish.png', 'elo': 2500}
      };
      
      _enrichPlayersInfo();
      _isLoadingBoard = false;
      _currentSide = 'red';
      _mySide = 'red';
      _syncPiecesFromBoard();
    });
    _playSound('start');
  }

  void _updateGameState(dynamic data) {
    if (data == null) return;
    
    if (data['serverTime'] != null) {
      _serverClockOffset = DateTime.now().millisecondsSinceEpoch - (data['serverTime'] as int);
    }
    
    if (data['clock'] != null) {
      _clock = data['clock'];
    } else if (data['state'] != null && data['state']['clock'] != null) {
      _clock = data['state']['clock'];
    } else if (data['game'] != null && data['game']['state'] != null && data['game']['state']['clock'] != null) {
      _clock = data['game']['state']['clock'];
    }
    
    if (data['finished'] != null) {
      _isFinished = data['finished'];
    } else if (data['state'] != null && data['state']['finished'] != null) {
      _isFinished = data['state']['finished'];
    } else if (data['game'] != null && data['game']['state'] != null && data['game']['state']['finished'] != null) {
      _isFinished = data['game']['state']['finished'];
    }
  }

  void _initOnlineGame() {
    final String targetRoomId = widget.roomId.toLowerCase();
    
    void handleRoomData(dynamic data, {bool isSpectator = false}) {
      setState(() => _isLoadingBoard = false);
      if (data['ok'] == true) {
        setState(() {
          _updateGameState(data);
          _isSpectator = isSpectator;
          if (data['board'] != null) {
            _boardData = FenUtils.fromBoardObject(data['board']);
            _syncPiecesFromBoard();
          } else if (data['state'] != null) {
            if (data['state']['board'] != null) {
              _boardData = FenUtils.fromBoardObject(data['state']['board']);
              _syncPiecesFromBoard();
            } else if (data['state']['position'] != null) {
              _boardData = FenUtils.parseFen(data['state']['position']);
              _syncPiecesFromBoard();
            }
          } else if (data['game'] != null && data['game']['state'] != null) {
            if (data['game']['state']['board'] != null) {
              _boardData = FenUtils.fromBoardObject(data['game']['state']['board']);
              _syncPiecesFromBoard();
            } else if (data['game']['state']['position'] != null) {
              _boardData = FenUtils.parseFen(data['game']['state']['position']);
              _syncPiecesFromBoard();
            }
          }
          if (data['playerNames'] != null) {
            _playersInfo = Map<String, dynamic>.from(data['playerNames']);
          }
          if (data['side'] != null) {
            _mySide = data['side'];
            if (_mySide == 'black') {
              _isFlipped = true;
            }
          } else if (isSpectator) {
            _mySide = 'red'; // Mặc định góc nhìn
          }
          if (data['currentPlayer'] != null) {
            _currentSide = data['currentPlayer'];
          }
          
          // Now that _mySide is known, we can safely enrich
          _enrichPlayersInfo();
        });
        if (!isSpectator) {
          _playSound('start');
        }
      }
    }

    widget.socketService.joinRoom(targetRoomId, (data) {
      if (data['ok'] == true) {
        handleRoomData(data);
      } else {
        if (data['error'] == 'ROOM_FULL' || data['error'] == 'ALREADY_IN_GAME' || data['error'] == 'ROOM_LOCKED' || data['error'] == 'GUEST_RESTRICTION') {
          // Thử xem với tư cách khán giả
          widget.socketService.watchRoom(targetRoomId, (watchData) {
            if (watchData['ok'] == true) {
              handleRoomData(watchData, isSpectator: true);
            } else {
              setState(() => _isLoadingBoard = false);
            }
          });
        } else {
          setState(() => _isLoadingBoard = false);
        }
      }
    });

    widget.socketService.onRoomPlayers((data) {
      if (data['roomId']?.toString().toLowerCase() == targetRoomId && data['playerNames'] != null) {
        setState(() {
          _playersInfo = Map<String, dynamic>.from(data['playerNames']);
        });
      }
    });

    widget.socketService.onGameMoved((data) {
      if (data['roomId']?.toString().toLowerCase() == targetRoomId) {
        setState(() {
          _updateGameState(data);
          if (data['state'] != null) {
            if (data['state']['board'] != null) {
              _boardData = FenUtils.fromBoardObject(data['state']['board']);
              _syncPiecesFromBoard();
            } else if (data['state']['position'] != null) {
              _boardData = FenUtils.parseFen(data['state']['position']);
              _syncPiecesFromBoard();
            }
            if (data['state']['currentPlayer'] != null) {
              _currentSide = data['state']['currentPlayer'];
            }
          } else if (data['move'] != null) {
            _applyMove(data['move']['from'], data['move']['to']);
            if (data['currentPlayer'] != null) {
              _currentSide = data['currentPlayer'];
            }
          }
          _selectedCell = null;
          _legalMoves = [];
          _captureMoves = [];
          _checkGameState();
        });
      }
    });
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
        // Find the piece in _pieces to animate it
        try {
          PieceModel movingPieceObj = _pieces.firstWhere((p) => p.row == fromRow && p.col == fromCol);
          // Remove any piece at destination (captured)
          _pieces.removeWhere((p) => p != movingPieceObj && p.row == toRow && p.col == toCol);
          // Update position of moving piece
          movingPieceObj.row = toRow;
          movingPieceObj.col = toCol;
        } catch (e) {
          // Piece not found in _pieces list, fallback to re-sync
          _syncPiecesFromBoard();
        }

        if (_boardData[fromRow][fromCol] != null) {
          _boardData[toRow][toCol] = _boardData[fromRow][fromCol];
          _boardData[fromRow][fromCol] = null;
          _lastMoveFrom = Offset(fromCol.toDouble(), fromRow.toDouble());
          _lastMoveTo = Offset(toCol.toDouble(), toRow.toDouble());
        }
      });
      
      _playSound(isCapture ? 'capture' : 'move');
    }
  }

  void _onTapDown(TapDownDetails details, Size size) {
    if (_isLoadingBoard) return;
    if (_isSpectator) return;
    
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
        
        if (_mySide != null && pieceSide != _mySide) return;
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
            isLegal = true;
            break;
          }
        }
        if (!isLegal) {
          for (var move in _captureMoves) {
            if (move.dx.toInt() == col && move.dy.toInt() == row) {
              isLegal = true;
              break;
            }
          }
        }

        if (!isLegal) {
          String? piece = _boardData[row][col];
          if (piece != null) {
            bool pieceIsRed = piece == piece.toUpperCase();
            String pieceSide = pieceIsRed ? 'red' : 'black';
            if (pieceSide == _currentSide && (_mySide == null || pieceSide == _mySide)) {
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

        bool isCapture = _boardData[row][col] != null;

        // Animate piece movement
        try {
          PieceModel movingPieceObj = _pieces.firstWhere((p) => p.row == fromRow && p.col == fromCol);
          _pieces.removeWhere((p) => p != movingPieceObj && p.row == row && p.col == col);
          movingPieceObj.row = row;
          movingPieceObj.col = col;
        } catch (e) {
          _syncPiecesFromBoard();
        }

        String? movingPiece = _boardData[fromRow][fromCol];
        _boardData[row][col] = movingPiece;
        _boardData[fromRow][fromCol] = null;
        _lastMoveFrom = Offset(fromCol.toDouble(), fromRow.toDouble());
        _lastMoveTo = Offset(col.toDouble(), row.toDouble());
        _selectedCell = null;
        _legalMoves = [];
        _captureMoves = [];
        
        _currentSide = (_currentSide == 'red' ? 'black' : 'red');
        _playSound(isCapture ? 'capture' : 'move');
        _checkGameState();

        if (widget.isPuzzle) {
          _handlePuzzleMove();
        } else {
          _handleOnlineMove(fromRow, fromCol, row, col);
        }
      }
    });
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
      String winner = _currentSide == 'red' ? 'Đen' : 'Đỏ';
      String reason = isCheck ? 'Chiếu bí (Checkmate)' : 'Hết nước đi (Stalemate)';
      _playSound(winner == (_mySide ?? 'red') ? 'win' : 'loss');
      
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
              const SizedBox(height: 20),
            ],
          ),
          actions: [
            Center(
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFF59E0B),
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                ),
                onPressed: () {
                  Navigator.pop(context);
                  Navigator.pop(context);
                },
                child: const Text('QUAY VỀ TRANG CHỦ', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ),
            const SizedBox(height: 10),
          ],
        ),
      );
    }
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

  Future<void> _handlePuzzleMove() async {
    setState(() => _isLoadingBoard = true);
    
    List<List<Map<String, dynamic>?>> serverBoard = List.generate(10, (r) => List.generate(9, (c) {
      String? code = _boardData[r][c];
      if (code == null) return null;
      bool isRed = code == code.toUpperCase();
      return {
        'side': isRed ? 'red' : 'black',
        'type': _charToType(code.toLowerCase()),
      };
    }));

    widget.socketService.requestEngineBestMove({
      'board': serverBoard,
      'side': 'black',
      'movetimeMs': 1000,
    }, (data) {
      setState(() => _isLoadingBoard = false);
      if (data != null && data['ok'] == true) {
        var from = data['from'];
        var to = data['to'];
        if (from != null && to != null) {
          _applyMove(from, to);
          setState(() {
            _currentSide = 'red';
          });
          _checkGameState();
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Máy không thể phản hồi')),
        );
      }
    });
  }

  void _handleOnlineMove(int fromRow, int fromCol, int toRow, int toCol) {
    widget.socketService.sendMove(
      widget.roomId.toLowerCase(), 
      {'row': fromRow, 'col': fromCol},
      {'row': toRow, 'col': toCol},
      (data) {
        if (data['ok'] != true) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Lỗi nước đi: ${data['error'] ?? 'Lỗi'}')),
          );
        } else {
          if (data['currentPlayer'] != null) {
            setState(() => _currentSide = data['currentPlayer']);
          }
        }
      }
    );
  }



  String _charToType(String char) {
    switch (char) {
      case 'k': return 'general';
      case 'a': return 'advisor';
      case 'b': return 'elephant';
      case 'n': return 'horse';
      case 'r': return 'chariot';
      case 'c': return 'cannon';
      case 'p': return 'soldier';
      default: return 'soldier';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF2C1810),
      appBar: AppBar(
        title: Text(
          widget.title ?? 'Trận Đấu',
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
          if (!widget.isPuzzle)
            IconButton(
              icon: const Icon(Icons.chat_bubble_outline),
              onPressed: _showChatSheet,
              tooltip: 'Trò chuyện',
            ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: widget.onLogout,
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // ─── Reconnection Banner ────────────────────────────────────────
            if (_isReconnecting)
              Container(
                width: double.infinity,
                color: Colors.amber.shade800,
                padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const SizedBox(
                      width: 14, height: 14,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black54),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '⚠️ Mất kết nối — Đang thử lại ($_reconnectAttempt/5)...',
                      style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 12),
                    ),
                  ],
                ),
              ),
            // Top Player (Opponent by default, or Black if not flipped)
            _buildPlayerProfile(_isFlipped ? 'red' : 'black'),
            
            // The Board
            Expanded(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12.0),
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      double boardWidth = constraints.maxWidth;
                      double cellW = boardWidth / 9;
                      double cellH = cellW * 1.1; 
                      double totalHeight = cellH * 10;

                      // Prevent vertical overflow on small screens or web browsers
                      if (totalHeight > constraints.maxHeight) {
                        totalHeight = constraints.maxHeight;
                        cellH = totalHeight / 10;
                        cellW = cellH / 1.1;
                        boardWidth = cellW * 9;
                      }

                      Size boardSize = Size(boardWidth, totalHeight);

                      return SizedBox(
                        width: boardSize.width,
                        height: boardSize.height,
                        child: Stack(
                          clipBehavior: Clip.none,
                          children: [
                            GestureDetector(
                              onTapDown: (details) => _onTapDown(details, boardSize),
                              child: Container(
                                width: boardSize.width,
                                height: boardSize.height,
                                decoration: BoxDecoration(
                                  color: const Color(0xFFD4B996),
                                  borderRadius: BorderRadius.circular(4),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.5),
                                      blurRadius: 10,
                                      spreadRadius: 2,
                                    )
                                  ],
                                ),
                                child: CustomPaint(
                                  painter: XiangqiPainter(
                                    selectedCell: _selectedCell,
                                    lastMoveFrom: _lastMoveFrom,
                                    lastMoveTo: _lastMoveTo,
                                    legalMoves: _legalMoves,
                                    captureMoves: _captureMoves,
                                    isFlipped: _isFlipped,
                                  ),
                                ),
                              ),
                            ),
                            ..._buildPieces(_pieces, cellW, cellH),
                            if (_isLoadingBoard)
                              IgnorePointer(
                                child: Center(
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const CircularProgressIndicator(color: Colors.white, strokeWidth: 4),
                                      const SizedBox(height: 16),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                        decoration: BoxDecoration(
                                          color: Colors.black.withOpacity(0.7),
                                          borderRadius: BorderRadius.circular(20),
                                          border: Border.all(color: Colors.white24),
                                        ),
                                        child: const Text(
                                          'Đang chờ...',
                                          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                          ],
                        ),
                      );
                    }
                  ),
                ),
              ),
            ),
            
            if (widget.isPuzzle) _buildPuzzleTools(),
            
            // Bottom Player (Self by default, or Red if not flipped)
            _buildPlayerProfile(_isFlipped ? 'black' : 'red'),
            
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildPuzzleTools() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white10),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildToolButton(
            icon: Icons.lightbulb_outline_rounded,
            label: 'Gợi ý',
            color: Colors.amber,
            onTap: _showHint,
          ),
          _buildToolButton(
            icon: Icons.refresh_rounded,
            label: 'Làm lại',
            color: Colors.blue,
            onTap: _resetPuzzle,
          ),
          _buildToolButton(
            icon: Icons.close_rounded,
            label: 'Thoát',
            color: Colors.red,
            onTap: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }

  Widget _buildToolButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(color: color.withOpacity(0.8), fontSize: 12, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  void _showChatSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) {
          return Container(
            height: MediaQuery.of(context).size.height * 0.6,
            decoration: const BoxDecoration(
              color: Color(0xFF1F120A),
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: Column(
              children: [
                Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(2)),
                ),
                const Text('Trò chuyện', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
                const Divider(color: Colors.white10),
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _chatMessages.length,
                    itemBuilder: (context, index) {
                      final msg = _chatMessages[index];
                      bool isMe = msg['uid'] == null; // Simplified logic for demo
                      return Align(
                        alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                          decoration: BoxDecoration(
                            color: isMe ? Colors.amber.shade900 : Colors.white.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (!isMe) Text(msg['name'] ?? 'Khách', style: const TextStyle(color: Colors.amber, fontSize: 10, fontWeight: FontWeight.bold)),
                              Text(msg['message'] ?? '', style: const TextStyle(color: Colors.white)),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
                Padding(
                  padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom + 16, left: 16, right: 16),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _chatController,
                          style: const TextStyle(color: Colors.white),
                          decoration: InputDecoration(
                            hintText: 'Nhập tin nhắn...',
                            hintStyle: const TextStyle(color: Colors.white38),
                            filled: true,
                            fillColor: Colors.white.withOpacity(0.05),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(24), borderSide: BorderSide.none),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        icon: const Icon(Icons.send_rounded, color: Colors.amber),
                        onPressed: () {
                          if (_chatController.text.trim().isNotEmpty) {
                            widget.socketService.sendChatMessage(widget.roomId, _chatController.text);
                            _chatController.clear();
                            Navigator.pop(context); // Close for simplicity in demo
                            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Đã gửi tin nhắn')));
                          }
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  List<Widget> _buildPieces(List<PieceModel> pieces, double cellW, double cellH) {
    return pieces.map((piece) {
      int displayRow = _isFlipped ? 9 - piece.row : piece.row;
      int displayCol = _isFlipped ? 8 - piece.col : piece.col;
      
      return AnimatedPositioned(
        key: ValueKey(piece.id),
        duration: const Duration(milliseconds: 450),
        curve: Curves.easeOutCubic,
        left: displayCol * cellW,
        top: displayRow * cellH,
        width: cellW,
        height: cellH,
        child: IgnorePointer(
          child: Center(
            child: Container(
              width: cellW * 0.90,
              height: cellH * 0.90,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    Colors.white,
                    const Color(0xFFF3EFEA),
                    const Color(0xFFD6CDBB),
                  ],
                  stops: const [0.3, 0.7, 1.0],
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.5),
                    blurRadius: 6,
                    offset: const Offset(0, 4),
                  ),
                  BoxShadow(
                    color: Colors.white.withOpacity(0.8),
                    blurRadius: 2,
                    offset: const Offset(-1, -1),
                  ),
                ],
                border: Border.all(
                  color: const Color(0xFF8B7355),
                  width: 1.5,
                ),
              ),
              padding: const EdgeInsets.all(3.0),
              child: Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withOpacity(0.5),
                ),
                child: ClipOval(
                  child: SvgPicture.asset(
                    FenUtils.getPieceAsset(piece.code),
                    fit: BoxFit.contain,
                  ),
                ),
              ),
            ),
          ),
        ),
      );
    }).toList();
  }

  String _formatMs(int ms) {
    int totalSeconds = (ms / 1000).ceil();
    int minutes = totalSeconds ~/ 60;
    int seconds = totalSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  Widget _buildPlayerProfile(String side) {
    final info = _playersInfo[side];
    final bool isMyTurn = _currentSide == side;
    final bool isMySide = _mySide == side;
    
    String name = "Trống";
    String elo = "";
    String? avatar;
    
    if (info is String) {
      name = info;
    } else if (info is Map) {
      name = info['name'] ?? "Kỳ thủ";
      elo = info['elo']?.toString() ?? "1200";
      avatar = info['avatar'] ?? info['picture'];
    }

    final String fullAvatarUrl = (avatar != null && avatar.startsWith('/')) 
        ? 'https://cotuong.xyz$avatar' 
        : (avatar ?? '');

    // --- CLOCK CALCULATION ---
    int? clockMs;
    double? perMoveRemaining;
    int perMoveLimit = 120000;

    if (_clock != null) {
      bool hasClock = _clock!['remainingMs'] != null;
      if (hasClock) {
        int base = (_clock!['remainingMs'][side] as num?)?.toInt() ?? 0;
        bool isActive = _clock!['turnSide'] == side && !_isFinished && _clock!['turnStartedAt'] != null;
        
        int nowOffset = DateTime.now().millisecondsSinceEpoch - _serverClockOffset;
        
        if (isActive) {
          int turnStartedAt = (_clock!['turnStartedAt'] as num).toInt();
          int elapsed = (nowOffset - turnStartedAt).clamp(0, double.maxFinite.toInt());
          clockMs = (base - elapsed).clamp(0, double.maxFinite.toInt());
          
          int turnDeadline = (_clock!['perMoveDeadlineAt'] as num?)?.toInt() ?? 0;
          perMoveLimit = (_clock!['perMoveMs'] as num?)?.toInt() ?? 120000;
          if (turnDeadline > 0) {
            perMoveRemaining = (turnDeadline - nowOffset).clamp(0, double.maxFinite.toInt()).toDouble();
          } else {
            perMoveRemaining = perMoveLimit.toDouble();
          }
        } else {
          clockMs = base;
          perMoveRemaining = null;
        }
      }
    }

    return AnimatedContainer(
      duration: const Duration(milliseconds: 400),
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isMyTurn ? Colors.white.withOpacity(0.1) : Colors.white.withOpacity(0.02),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isMyTurn ? const Color(0xFFF59E0B).withOpacity(0.8) : Colors.white10,
          width: isMyTurn ? 1.5 : 1,
        ),
        boxShadow: isMyTurn ? [
          BoxShadow(
            color: const Color(0xFFF59E0B).withOpacity(0.15),
            blurRadius: 12,
            spreadRadius: 2,
          )
        ] : [],
      ),
      child: Row(
        children: [
          // Avatar
          Stack(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: side == 'red' ? Colors.redAccent.withOpacity(0.8) : Colors.black87, 
                    width: 2,
                  ),
                  image: fullAvatarUrl.isNotEmpty 
                      ? DecorationImage(image: NetworkImage(fullAvatarUrl), fit: BoxFit.cover)
                      : null,
                  color: Colors.black26,
                ),
                child: fullAvatarUrl.isEmpty 
                    ? const Icon(Icons.person, color: Colors.white54, size: 28) 
                    : null,
              ),
              if (isMyTurn)
                Positioned(
                  right: -2,
                  bottom: -2,
                  child: Container(
                    padding: const EdgeInsets.all(2),
                    decoration: const BoxDecoration(
                      color: Color(0xFF1A1A1A),
                      shape: BoxShape.circle,
                    ),
                    child: Container(
                      width: 14,
                      height: 14,
                      decoration: const BoxDecoration(
                        color: Color(0xFFF59E0B),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.timer, size: 10, color: Colors.black),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(width: 16),
          // Name and Elo and Per-Move Bar
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Text(
                      name,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: isMyTurn ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                    if (isMySide)
                      Container(
                        margin: const EdgeInsets.only(left: 6),
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.blueAccent.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text(
                          'Bạn',
                          style: TextStyle(color: Colors.blueAccent, fontSize: 10, fontWeight: FontWeight.bold),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  'Elo: $elo',
                  style: TextStyle(color: Colors.white70, fontSize: 12),
                ),
                if (perMoveRemaining != null && perMoveLimit > 0) ...[
                  const SizedBox(height: 6),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('BƯỚC ĐI:', style: TextStyle(color: Colors.white60, fontSize: 10, fontWeight: FontWeight.bold)),
                      Text(
                        _formatMs(perMoveRemaining.toInt()),
                        style: TextStyle(
                          color: perMoveRemaining < 15000 ? Colors.red : Colors.amber,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'monospace',
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Container(
                    height: 4,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.black26,
                      borderRadius: BorderRadius.circular(2),
                    ),
                    child: FractionallySizedBox(
                      alignment: Alignment.centerLeft,
                      widthFactor: (perMoveRemaining / perMoveLimit).clamp(0.0, 1.0),
                      child: Container(
                        decoration: BoxDecoration(
                          color: perMoveRemaining < 15000 ? Colors.red : Colors.amber,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
          
          const SizedBox(width: 8),

          // Total Timer Clock or Side Indicator
          if (clockMs != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: isMyTurn ? Colors.black45 : Colors.black26,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: isMyTurn && clockMs < 30000 ? Colors.red.withOpacity(0.8) : Colors.white10,
                  width: isMyTurn && clockMs < 30000 ? 2 : 1,
                ),
              ),
              child: Text(
                _formatMs(clockMs),
                style: TextStyle(
                  color: isMyTurn 
                      ? (clockMs < 30000 ? Colors.redAccent : Colors.white)
                      : Colors.white54,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'monospace',
                ),
              ),
            )
          else
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: side == 'red' ? Colors.red.withOpacity(0.2) : Colors.black.withOpacity(0.4),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: side == 'red' ? Colors.red : Colors.grey, width: 1),
              ),
              child: Text(
                side == 'red' ? 'ĐỎ' : 'ĐEN',
                style: TextStyle(
                  color: side == 'red' ? Colors.redAccent : Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class XiangqiPainter extends CustomPainter {
  final Offset? selectedCell;
  final Offset? lastMoveFrom;
  final Offset? lastMoveTo;
  final List<Offset> legalMoves;
  final List<Offset> captureMoves;
  final bool isFlipped;
  
  XiangqiPainter({
    this.selectedCell, 
    this.lastMoveFrom,
    this.lastMoveTo,
    required this.legalMoves,
    required this.captureMoves,
    this.isFlipped = false
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.black.withOpacity(0.4)
      ..strokeWidth = 1.2;
      
    final thickerPaint = Paint()
      ..color = Colors.black.withOpacity(0.6)
      ..strokeWidth = 2.5;

    double cellW = size.width / 9;
    double cellH = size.height / 10;

    // Draw coordinate background (subtle)
    final coordStyle = TextStyle(color: Colors.black.withOpacity(0.3), fontSize: 10, fontWeight: FontWeight.bold);

    // Draw main board frame
    canvas.drawRect(
      Rect.fromLTWH(cellW / 2, cellH / 2, 8 * cellW, 9 * cellH),
      thickerPaint..style = PaintingStyle.stroke,
    );

    // Vertical lines
    for (int i = 0; i < 9; i++) {
      double x = i * cellW + (cellW / 2);
      canvas.drawLine(Offset(x, cellH / 2), Offset(x, 4.5 * cellH), paint);
      canvas.drawLine(Offset(x, 5.5 * cellH), Offset(x, 9.5 * cellH), paint);
      
      // Draw Column Coordinates (1-9)
      String colText = isFlipped ? (9 - i).toString() : (i + 1).toString();
      _drawText(canvas, colText, Offset(x, 0.2 * cellH), coordStyle);
      _drawText(canvas, colText, Offset(x, 9.8 * cellH), coordStyle);
    }
    
    // Horizontal lines
    for (int i = 0; i < 10; i++) {
      double y = i * cellH + (cellH / 2);
      canvas.drawLine(Offset(cellW / 2, y), Offset(8.5 * cellW, y), paint);

      // Draw Row Coordinates (0-9)
      String rowText = isFlipped ? i.toString() : (9 - i).toString();
      _drawText(canvas, rowText, Offset(0.2 * cellW, y), coordStyle);
      _drawText(canvas, rowText, Offset(8.8 * cellW, y), coordStyle);
    }

    // Palace (X lines)
    canvas.drawLine(Offset(3.5 * cellW, cellH / 2), Offset(5.5 * cellW, 2.5 * cellH), paint);
    canvas.drawLine(Offset(5.5 * cellW, cellH / 2), Offset(3.5 * cellW, 2.5 * cellH), paint);
    canvas.drawLine(Offset(3.5 * cellW, 7.5 * cellH), Offset(5.5 * cellW, 9.5 * cellH), paint);
    canvas.drawLine(Offset(5.5 * cellW, 7.5 * cellH), Offset(3.5 * cellW, 9.5 * cellH), paint);

    // Cross markers (Cannons and Soldiers)
    final markerPaint = Paint()
      ..color = Colors.black.withOpacity(0.3)
      ..strokeWidth = 1.0;
    
    void drawCross(int row, int col) {
      double x = col * cellW + (cellW / 2);
      double y = row * cellH + (cellH / 2);
      double gap = cellW * 0.12;
      double len = cellW * 0.18;
      
      // Top Left
      if (col > 0) {
        canvas.drawLine(Offset(x - gap, y - gap), Offset(x - gap - len, y - gap), markerPaint);
        canvas.drawLine(Offset(x - gap, y - gap), Offset(x - gap, y - gap - len), markerPaint);
      }
      // Top Right
      if (col < 8) {
        canvas.drawLine(Offset(x + gap, y - gap), Offset(x + gap + len, y - gap), markerPaint);
        canvas.drawLine(Offset(x + gap, y - gap), Offset(x + gap, y - gap - len), markerPaint);
      }
      // Bottom Left
      if (col > 0) {
        canvas.drawLine(Offset(x - gap, y + gap), Offset(x - gap - len, y + gap), markerPaint);
        canvas.drawLine(Offset(x - gap, y + gap), Offset(x - gap, y + gap + len), markerPaint);
      }
      // Bottom Right
      if (col < 8) {
        canvas.drawLine(Offset(x + gap, y + gap), Offset(x + gap + len, y + gap), markerPaint);
        canvas.drawLine(Offset(x + gap, y + gap), Offset(x + gap, y + gap + len), markerPaint);
      }
    }

    drawCross(2, 1); drawCross(2, 7);
    drawCross(7, 1); drawCross(7, 7);
    for (int i = 0; i <= 8; i += 2) {
      drawCross(3, i);
      drawCross(6, i);
    }

    // River Text
    String riverText = "cotuong.xyz";
    final tp = TextPainter(
      text: TextSpan(
        text: riverText, 
        style: TextStyle(
          color: Colors.black.withOpacity(0.15), 
          fontSize: 24, 
          fontWeight: FontWeight.bold,
          letterSpacing: 8.0,
          fontStyle: FontStyle.italic,
        )
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, Offset(size.width/2 - tp.width/2, 4.5 * cellH + (cellH - tp.height)/2));

    // Highlights (Last Move, Selected, Legal Moves, Captures)
    _paintHighlights(canvas, cellW, cellH);
  }

  void _drawText(Canvas canvas, String text, Offset center, TextStyle style) {
    final tp = TextPainter(
      text: TextSpan(text: text, style: style),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, Offset(center.dx - tp.width / 2, center.dy - tp.height / 2));
  }

  void _paintHighlights(Canvas canvas, double cellW, double cellH) {
    // Last Move
    if (lastMoveFrom != null && lastMoveTo != null) {
      final lastMoveFromPaint = Paint()..color = const Color(0xFF4338CA).withOpacity(0.15);
      final lastMoveToPaint = Paint()
        ..color = const Color(0xFF4338CA).withOpacity(0.25)
        ..style = PaintingStyle.fill;
      final lastMoveToBorderPaint = Paint()
        ..color = const Color(0xFF4338CA).withOpacity(0.7)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3.0;

      int fCol = isFlipped ? 8 - lastMoveFrom!.dx.toInt() : lastMoveFrom!.dx.toInt();
      int fRow = isFlipped ? 9 - lastMoveFrom!.dy.toInt() : lastMoveFrom!.dy.toInt();
      canvas.drawCircle(Offset(fCol * cellW + cellW/2, fRow * cellH + cellH/2), cellW * 0.4, lastMoveFromPaint);
      
      int tCol = isFlipped ? 8 - lastMoveTo!.dx.toInt() : lastMoveTo!.dx.toInt();
      int tRow = isFlipped ? 9 - lastMoveTo!.dy.toInt() : lastMoveTo!.dy.toInt();
      canvas.drawCircle(Offset(tCol * cellW + cellW/2, tRow * cellH + cellH/2), cellW * 0.48, lastMoveToPaint);
      canvas.drawCircle(Offset(tCol * cellW + cellW/2, tRow * cellH + cellH/2), cellW * 0.48, lastMoveToBorderPaint);
    }

    // Selected Cell
    if (selectedCell != null) {
      int displayCol = isFlipped ? 8 - selectedCell!.dx.toInt() : selectedCell!.dx.toInt();
      int displayRow = isFlipped ? 9 - selectedCell!.dy.toInt() : selectedCell!.dy.toInt();
      
      final selPaint = Paint()
        ..color = const Color(0xFF0EA5E9)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3.0;
        
      canvas.drawCircle(Offset(displayCol * cellW + cellW / 2, displayRow * cellH + cellH / 2), cellW * 0.48, selPaint);
    }

    // Legal Moves
    final dotPaint = Paint()..color = const Color(0xFF0EA5E9).withOpacity(0.4);
    for (var move in legalMoves) {
      int displayCol = isFlipped ? 8 - move.dx.toInt() : move.dx.toInt();
      int displayRow = isFlipped ? 9 - move.dy.toInt() : move.dy.toInt();
      canvas.drawCircle(Offset(displayCol * cellW + cellW / 2, displayRow * cellH + cellH / 2), cellW * 0.12, dotPaint);
    }

    // Capture Moves
    final capturePaint = Paint()
      ..color = const Color(0xFFDC2626).withOpacity(0.2)
      ..style = PaintingStyle.fill;
    final captureBorderPaint = Paint()
      ..color = const Color(0xFFDC2626).withOpacity(0.6)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5;

    for (var move in captureMoves) {
      int displayCol = isFlipped ? 8 - move.dx.toInt() : move.dx.toInt();
      int displayRow = isFlipped ? 9 - move.dy.toInt() : move.dy.toInt();
      canvas.drawCircle(Offset(displayCol * cellW + cellW / 2, displayRow * cellH + cellH / 2), cellW * 0.4, capturePaint);
      canvas.drawCircle(Offset(displayCol * cellW + cellW / 2, displayRow * cellH + cellH / 2), cellW * 0.4, captureBorderPaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
