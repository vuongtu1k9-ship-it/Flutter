import 'dart:ui';
import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../services/socket_service.dart';
import '../models/game_models.dart';
import 'board_view.dart';
import 'offline_board_view.dart';
import 'profile_view.dart';

import '../widgets/chat_bottom_sheet.dart';

import 'home/tabs/dashboard_tab.dart';
import 'home/tabs/players_tab.dart';
import 'home/tabs/games_tab.dart';
import 'home/tabs/puzzles_tab.dart';
import 'home/tabs/tournaments_tab.dart';

class HomeView extends StatefulWidget {
  final Map<String, dynamic> userData;
  final String token;
  final ApiService apiService;
  final SocketService socketService;
  final VoidCallback onLogout;

  const HomeView({
    Key? key,
    required this.userData,
    required this.token,
    required this.apiService,
    required this.socketService,
    required this.onLogout,
  }) : super(key: key);

  @override
  _HomeViewState createState() => _HomeViewState();
}

class _HomeViewState extends State<HomeView> {
  List<User> _leaderboardPlayers = [];
  Map<String, User> _presenceMap = {};
  List<User> _bots = [];
  List<GameSummary> _activeGames = [];
  List<Puzzle> _puzzles = [];
  List<Tournament> _tournaments = [];
  List<Map<String, dynamic>> _lobbyMessages = [];
  bool _isLoading = true;
  final TextEditingController _lobbyChatController = TextEditingController();

  List<User> get _combinedPlayers {
    final Map<String, User> combined = {};
    for (var p in _leaderboardPlayers) {
      combined[p.uid] = p;
    }
    for (var p in _presenceMap.values) {
      if (p.online) {
        combined[p.uid] = p;
      }
    }
    
    return combined.values.map((p) {
       final isOnline = _presenceMap[p.uid]?.online ?? false;
       return User(
         uid: p.uid,
         name: p.name,
         picture: p.picture,
         elo: p.elo,
         online: isOnline,
       );
    }).toList();
  }

  @override
  void initState() {
    super.initState();
    _loadInitialData();
    _setupSocketListeners();
    widget.socketService.requestPresenceList();
  }

  @override
  void dispose() {
    widget.socketService.clearLobbyListeners();
    _lobbyChatController.dispose();
    super.dispose();
  }

  void _loadInitialData() async {
    setState(() => _isLoading = true);
    final players = await widget.apiService.getPlayers();
    final games = await widget.apiService.getGames();
    final puzzles = await widget.apiService.getPuzzles();
    final bots = await widget.apiService.getBots();
    final tournaments = await widget.apiService.getTournaments();
    
    if (mounted) {
      setState(() {
        _leaderboardPlayers = players;
        _activeGames = games;
        _puzzles = puzzles;
        _bots = bots;
        _tournaments = tournaments;
        _isLoading = false;
      });
    }
  }

  void _setupSocketListeners() {
    widget.socketService.onPresenceList((data) {
      if (data != null && data['ok'] == true && data['presence'] is List) {
        if (mounted) {
          setState(() {
            _presenceMap.clear();
            for (var pData in data['presence']) {
              final user = User.fromJson(pData);
              _presenceMap[user.uid] = user;
            }
          });
        }
      }
    });

    widget.socketService.onPresenceUpdate((data) {
      if (mounted && data != null) {
        setState(() {
          final user = User.fromJson(data);
          _presenceMap[user.uid] = user;
        });
      }
    });
    
    widget.socketService.onLobbyUpdate((data) {
      _loadInitialData();
    });

    widget.socketService.onChallengeAccepted((data) {
      if (data['roomId'] != null) {
        _joinGame(data['roomId']);
      }
    });

    widget.socketService.onChallengeReceived((data) {
      _showChallengeDialog(data);
    });

    widget.socketService.onChallengeError((data) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(data['message'] ?? 'Đã xảy ra lỗi khi mời thi đấu')),
      );
    });

    widget.socketService.onChallengeStatus((data) {
      if (!mounted) return;
      if (data['status'] == 'declined') {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${data['targetName'] ?? 'Đối thủ'} đã từ chối lời mời.')),
        );
      } else if (data['status'] == 'pending' && data['isSender'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(data['message'] ?? 'Đang chờ đối thủ phản hồi...')),
        );
      }
    });

    widget.socketService.onChallengeCanceled((data) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Lời mời thi đấu đã bị hủy.')),
      );
      // Close challenge dialog if it's open (hard to do without a specific reference, but user can tap out)
    });

    widget.socketService.onLobbyMessage((data) {
      if (mounted) {
        setState(() {
          _lobbyMessages.add(data);
        });
      }
    });
  }

  void _showChallengeDialog(Map<String, dynamic> data) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Lời mời thi đấu'),
        content: Text('${data['senderName']} muốn thách đấu bạn!'),
        actions: [
          TextButton(
            onPressed: () {
              widget.socketService.replyToChallenge(data['id'], 'decline');
              Navigator.pop(context);
            },
            child: const Text('Từ chối'),
          ),
          ElevatedButton(
            onPressed: () {
              widget.socketService.replyToChallenge(data['id'], 'accept');
              Navigator.pop(context);
            },
            child: const Text('Chấp nhận'),
          ),
        ],
      ),
    );
  }

  void _showBotSelectionDialog() {
    // Luôn luôn ưu tiên chơi Offline với AI khi khách chọn "Đấu với máy"
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const OfflineBoardView(playVsBot: true),
      ),
    );
  }

  void _startAiGame(User bot) {
    // Hàm này giữ lại để tương thích nếu sau này có mode Online AI
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const OfflineBoardView(playVsBot: true),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 5,
      child: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF1E110A), Color(0xFF0F0804)],
          ),
        ),
        child: Scaffold(
          backgroundColor: Colors.transparent,
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            title: const Text('Cờ Tướng Live', style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1.5)),
            actions: [
              IconButton(
                icon: const Icon(Icons.person),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ProfileView(
                        uid: widget.userData['uid'],
                        apiService: widget.apiService,
                        currentUserData: widget.userData,
                      ),
                    ),
                  );
                },
              ),
              IconButton(
                icon: const Icon(Icons.chat_bubble_outline),
                onPressed: _showLobbyChat,
                tooltip: 'Chat thế giới',
              ),
              IconButton(
                icon: const Icon(Icons.logout),
                onPressed: widget.onLogout,
              ),
            ],
          ),
          body: Column(
            children: [
              _buildUserProfile(),
              Expanded(
                child: Builder(
                  builder: (context) {
                    return TabBarView(
                      children: [
                        DashboardTab(
                          onlinePlayers: _combinedPlayers,
                          activeGames: _activeGames,
                          puzzles: _puzzles,
                          onStartPuzzle: _startPuzzle,
                          onJoinGame: _joinGame,
                          onGoToGames: () => DefaultTabController.of(context).animateTo(2),
                          onGoToPuzzles: () => DefaultTabController.of(context).animateTo(3),
                          onChallengePlayer: _showChallengeConfirmDialog,
                          onShowBotSelection: _showBotSelectionDialog,
                        ),
                        PlayersTab(
                          onlinePlayers: _combinedPlayers,
                          currentUserData: widget.userData,
                          onChallengePlayer: _showChallengeConfirmDialog,
                          isLoading: _isLoading,
                          apiService: widget.apiService,
                        ),
                        GamesTab(
                          onJoinGame: _joinGame,
                          apiService: widget.apiService,
                        ),
                        PuzzlesTab(
                          onStartPuzzle: _startPuzzle,
                          apiService: widget.apiService,
                        ),
                        TournamentsTab(
                          tournaments: _tournaments,
                          isLoading: _isLoading,
                          socketService: widget.socketService,
                          apiService: widget.apiService,
                          onLogout: widget.onLogout,
                          currentUserData: widget.userData,
                          onlinePlayers: _combinedPlayers,
                        ),
                      ],
                    );
                  }
                ),
              ),
            ],
          ),
          bottomNavigationBar: ClipRRect(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
              child: Container(
                color: Colors.black.withOpacity(0.5),
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                    child: TabBar(
                      indicator: BoxDecoration(
                        color: Colors.amber.shade900,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                           BoxShadow(color: Colors.amber.shade900.withOpacity(0.5), blurRadius: 8, offset: const Offset(0, 2))
                        ]
                      ),
                      indicatorSize: TabBarIndicatorSize.tab,
                      labelColor: Colors.white,
                      unselectedLabelColor: Colors.white54,
                      tabs: const [
                        Tab(icon: Icon(Icons.home_rounded, size: 24)),
                        Tab(icon: Icon(Icons.leaderboard_rounded, size: 24)),
                        Tab(icon: Icon(Icons.style_rounded, size: 24)),
                        Tab(icon: Icon(Icons.extension_rounded, size: 24)),
                        Tab(icon: Icon(Icons.emoji_events_rounded, size: 24)),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
          floatingActionButton: FloatingActionButton.extended(
            onPressed: _createNewRoom,
            backgroundColor: Colors.amber.shade700,
            label: const Text('Tạo bàn', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black)),
            icon: const Icon(Icons.add, color: Colors.black),
          ),
        ),
      ),
    );
  }

  void _createNewRoom() {
    widget.socketService.createRoom({}, (data) {
      if (data['ok'] == true && data['roomId'] != null) {
        _joinGame(data['roomId']);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Không thể tạo bàn: ${data['error'] ?? 'Lỗi'}')),
        );
      }
    });
  }

  void _startPuzzle(Puzzle puzzle) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => BoardView(
          roomId: 'puzzle-${puzzle.uid}',
          socketService: widget.socketService,
          apiService: widget.apiService,
          onLogout: widget.onLogout,
          isPuzzle: true,
          initialBoard: puzzle.board,
          initialFen: puzzle.fen,
          title: puzzle.name,
          currentUserData: widget.userData,
          onlinePlayers: _combinedPlayers,
          bots: _bots,
        ),
      ),
    );
  }

  Widget _buildUserProfile() {
    final String? pictureUrl = widget.userData['picture'];
    final String fullPictureUrl = (pictureUrl != null && pictureUrl.startsWith('/')) 
        ? 'https://cotuong.xyz$pictureUrl' 
        : (pictureUrl ?? '');

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.amber.withOpacity(0.2), width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(2),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: Colors.amber.shade700, width: 2),
            ),
            child: CircleAvatar(
              radius: 28,
              backgroundImage: fullPictureUrl.isNotEmpty
                  ? NetworkImage(fullPictureUrl) 
                  : null,
              backgroundColor: Colors.grey.shade900,
              child: fullPictureUrl.isEmpty
                  ? const Icon(Icons.person, size: 28, color: Colors.white54) 
                  : null,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.userData['name'] ?? 'Kỳ thủ',
                  style: const TextStyle(
                    fontSize: 18, 
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.star_rounded, color: Colors.amber, size: 16),
                    const SizedBox(width: 4),
                    Text(
                      '${widget.userData['elo'] ?? 1200} Elo',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.amber.shade100,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          ElevatedButton(
            onPressed: _showBotSelectionDialog,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.amber.shade900.withOpacity(0.2),
              foregroundColor: Colors.amber.shade400,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(color: Colors.amber.withOpacity(0.3)),
              ),
              elevation: 0,
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.smart_toy_rounded, size: 16),
                SizedBox(width: 6),
                Text('Đấu Máy', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
              ],
            ),
          ),
        ],
      ),
    );
  }


  void _showChallengeConfirmDialog(User player) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Thách đấu'),
        content: Text('Bạn muốn mời ${player.name} thi đấu?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () {
              widget.socketService.sendChallenge(player.uid, player.name);
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Đã gửi lời mời tới ${player.name}')),
              );
            },
            child: const Text('Mời thi đấu'),
          ),
        ],
      ),
    );
  }


  void _joinGame(String roomId) {
    final String targetRoomId = roomId.toLowerCase();
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => BoardView(
          roomId: targetRoomId,
          socketService: widget.socketService,
          apiService: widget.apiService,
          onLogout: widget.onLogout,
          currentUserData: widget.userData,
          onlinePlayers: _combinedPlayers,
          bots: _bots,
        ),
      ),
    );
  }

  void _showLobbyChat() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => ChatBottomSheet(
        title: 'Chat Thế Giới',
        messages: _lobbyMessages,
        currentUserId: widget.userData['uid'],
        onSendMessage: (text) {
          widget.socketService.sendLobbyMessage(text);
        },
      ),
    );
  }
}
