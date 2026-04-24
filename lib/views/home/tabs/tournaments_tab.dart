import 'package:flutter/material.dart';
import '../../../models/game_models.dart';
import '../../tournament_detail_view.dart';
import '../../../services/socket_service.dart';
import '../../../services/api_service.dart';

class TournamentsTab extends StatelessWidget {
  final List<Tournament> tournaments;
  final bool isLoading;
  final SocketService socketService;
  final ApiService apiService;
  final VoidCallback onLogout;
  final Map<String, dynamic> currentUserData;
  final List<User> onlinePlayers;

  const TournamentsTab({
    Key? key,
    required this.tournaments,
    required this.isLoading,
    required this.socketService,
    required this.apiService,
    required this.onLogout,
    required this.currentUserData,
    required this.onlinePlayers,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (isLoading) return const Center(child: CircularProgressIndicator());
    if (tournaments.isEmpty) return const Center(child: Text('Không có giải đấu nào'));

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: tournaments.length,
      itemBuilder: (context, index) {
        final tournament = tournaments[index];
        bool isStarted = tournament.status == 'started';

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: isStarted 
                ? [Colors.amber.shade900.withOpacity(0.8), Colors.black87] 
                : [Colors.grey.shade800, Colors.black87],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: isStarted ? Colors.amber.shade700 : Colors.white10),
            boxShadow: isStarted ? [
              BoxShadow(color: Colors.amber.withOpacity(0.2), blurRadius: 8, offset: const Offset(0, 4))
            ] : null,
          ),
          child: InkWell(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => TournamentDetailView(
                    tournament: tournament,
                    token: currentUserData['token'] ?? '',
                    socketService: socketService,
                    apiService: apiService,
                    onLogout: onLogout,
                  ),
                ),
              );
            },
            borderRadius: BorderRadius.circular(20),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          tournament.name,
                          style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                      ),
                      if (isStarted)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(color: Colors.red, borderRadius: BorderRadius.circular(8)),
                          child: const Row(
                            children: [
                              Icon(Icons.fiber_manual_record, color: Colors.white, size: 10),
                              SizedBox(width: 4),
                              Text('LIVE', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                            ],
                          ),
                        )
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(tournament.description ?? 'Chưa có thông tin giải đấu', style: const TextStyle(color: Colors.white70, fontSize: 13), maxLines: 2, overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Icon(Icons.people, size: 16, color: Colors.amber.shade200),
                      const SizedBox(width: 4),
                      Text('${tournament.playersCount} kỳ thủ', style: const TextStyle(color: Colors.white70)),
                      const SizedBox(width: 16),
                      Icon(Icons.timer, size: 16, color: Colors.amber.shade200),
                      const SizedBox(width: 4),
                      Text(isStarted ? 'Đang đấu' : 'Sắp diễn ra', style: const TextStyle(color: Colors.white70)),
                    ],
                  )
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
