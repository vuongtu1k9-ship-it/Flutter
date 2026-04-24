import 'package:flutter/material.dart';
import '../models/game_models.dart';
import '../services/api_service.dart';
import '../services/socket_service.dart';

class TournamentDetailView extends StatefulWidget {
  final Tournament tournament;
  final String token;
  final ApiService apiService;
  final SocketService socketService;
  final VoidCallback onLogout;

  const TournamentDetailView({
    super.key,
    required this.tournament,
    required this.token,
    required this.apiService,
    required this.socketService,
    required this.onLogout,
  });

  @override
  State<TournamentDetailView> createState() => _TournamentDetailViewState();
}

class _TournamentDetailViewState extends State<TournamentDetailView> {
  bool _isLoading = true;
  List<dynamic> _players = [];

  @override
  void initState() {
    super.initState();
    _loadTournamentDetails();
  }

  Future<void> _loadTournamentDetails() async {
    setState(() => _isLoading = true);
    try {
      final detail = await widget.apiService.getTournamentDetail(widget.token, widget.tournament.id);
      
      if (mounted) {
        setState(() {
          _isLoading = false;
          if (detail != null && detail['ok'] == true && detail['tournament'] != null) {
            final tournamentData = detail['tournament'];
            if (tournamentData['standings'] != null) {
               _players = tournamentData['standings'] as List<dynamic>;
            } else {
               _players = [];
            }
          } else {
            _players = [];
          }
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    bool isStarted = widget.tournament.status == 'started';

    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF1E110A), Color(0xFF0F0804)],
        ),
      ),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: CustomScrollView(
          slivers: [
            SliverAppBar(
              expandedHeight: 200,
              pinned: true,
              backgroundColor: Colors.transparent,
              elevation: 0,
              flexibleSpace: FlexibleSpaceBar(
                title: Text(
                  widget.tournament.name,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                background: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.amber.shade900.withOpacity(0.5), Colors.transparent],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                  ),
                  child: Center(
                    child: Hero(
                      tag: 'tour_${widget.tournament.id}',
                      child: Icon(
                        Icons.emoji_events_rounded,
                        size: 80,
                        color: Colors.amber.withOpacity(0.6),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildStatusCard(isStarted),
                    const SizedBox(height: 24),
                    const Text(
                      'Thông tin giải đấu',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      widget.tournament.description ?? 'Giải đấu cờ tướng chuyên nghiệp dành cho tất cả mọi người. Hãy tham gia để khẳng định bản lĩnh kỳ vương!',
                      style: const TextStyle(color: Colors.white70, height: 1.5),
                    ),
                    const SizedBox(height: 32),
                    _buildTabs(),
                  ],
                ),
              ),
            ),
            if (_isLoading)
              const SliverFillRemaining(
                child: Center(child: CircularProgressIndicator(color: Colors.amber)),
              )
            else
              _buildPlayersList(),
          ],
        ),
        bottomNavigationBar: _buildBottomBar(isStarted),
      ),
    );
  }

  Widget _buildStatusCard(bool isStarted) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white10),
      ),
      child: Row(
        children: [
          _buildInfoItem(Icons.people_rounded, '${widget.tournament.playersCount}', 'Kỳ thủ'),
          _buildDivider(),
          _buildInfoItem(Icons.timer_rounded, isStarted ? 'Đang đấu' : 'Sắp mở', 'Trạng thái'),
          _buildDivider(),
          _buildInfoItem(Icons.star_rounded, '100', 'Giải thưởng'),
        ],
      ),
    );
  }

  Widget _buildInfoItem(IconData icon, String value, String label) {
    return Expanded(
      child: Column(
        children: [
          Icon(icon, color: Colors.amber, size: 20),
          const SizedBox(height: 4),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
          Text(label, style: const TextStyle(fontSize: 10, color: Colors.white38)),
        ],
      ),
    );
  }

  Widget _buildDivider() {
    return Container(height: 30, width: 1, color: Colors.white10);
  }

  Widget _buildTabs() {
    return Row(
      children: [
        _buildTabItem('Danh sách kỳ thủ', true),
        const SizedBox(width: 16),
        _buildTabItem('Lịch thi đấu', false),
      ],
    );
  }

  Widget _buildTabItem(String label, bool active) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: active ? Colors.amber : Colors.transparent,
        borderRadius: BorderRadius.circular(20),
        border: active ? null : Border.all(color: Colors.white24),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: active ? Colors.black : Colors.white70,
          fontWeight: active ? FontWeight.bold : FontWeight.normal,
          fontSize: 13,
        ),
      ),
    );
  }

  Widget _buildPlayersList() {
    return SliverList(
      delegate: SliverChildBuilderDelegate(
        (context, index) {
          final player = _players[index];
          return Container(
            margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.03),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Text(
                  '${index + 1}',
                  style: const TextStyle(color: Colors.amber, fontWeight: FontWeight.bold),
                ),
                const SizedBox(width: 16),
                const CircleAvatar(
                  radius: 18,
                  backgroundColor: Colors.white12,
                  child: Icon(Icons.person, size: 20, color: Colors.white38),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(player['name'], style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                      Text('${player['elo']} Elo', style: const TextStyle(color: Colors.white38, fontSize: 12)),
                    ],
                  ),
                ),
                if (index < 3)
                  Icon(Icons.military_tech, color: index == 0 ? Colors.amber : Colors.grey, size: 24),
              ],
            ),
          );
        },
        childCount: _players.length,
      ),
    );
  }

  Widget _buildBottomBar(bool isStarted) {
    return SafeArea(
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: const Color(0xFF1A1A1A),
          border: Border(top: BorderSide(color: Colors.white.withOpacity(0.05))),
        ),
        child: ElevatedButton(
          onPressed: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Đang xử lý tham gia giải đấu...')),
            );
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.amber,
            foregroundColor: Colors.black,
            minimumSize: const Size(double.infinity, 54),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(27)),
            elevation: 0,
          ),
          child: Text(
            isStarted ? 'XEM TRỰC TIẾP' : 'ĐĂNG KÝ THAM GIA',
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
        ),
      ),
    );
  }
}
