import 'package:flutter/material.dart';
import '../../../models/game_models.dart';
import '../../../widgets/mini_board.dart';

class DashboardTab extends StatelessWidget {
  final List<User> onlinePlayers;
  final List<GameSummary> activeGames;
  final List<Puzzle> puzzles;
  final Function(Puzzle) onStartPuzzle;
  final Function(String) onJoinGame;
  final VoidCallback onGoToGames;
  final VoidCallback onGoToPuzzles;
  final Function(User) onChallengePlayer;
  final VoidCallback onShowBotSelection;

  const DashboardTab({
    super.key,
    required this.onlinePlayers,
    required this.activeGames,
    required this.puzzles,
    required this.onStartPuzzle,
    required this.onJoinGame,
    required this.onGoToGames,
    required this.onGoToPuzzles,
    required this.onChallengePlayer,
    required this.onShowBotSelection,
  });

  @override
  Widget build(BuildContext context) {
    final onlineOnly = onlinePlayers.where((p) => p.online).toList();
    final topGames = activeGames.take(3).toList();
    final topPuzzles = puzzles.take(4).toList();

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeroActions(context),
          if (onlineOnly.isNotEmpty) _buildOnlineStatusSection(onlineOnly),
          
          _buildSectionHeader('Trận đấu mới nhất', Icons.videogame_asset_rounded, onGoToGames),
          if (topGames.isEmpty) 
            const Padding(padding: EdgeInsets.all(16), child: Text('Đang chờ trận đấu mới...', style: TextStyle(color: Colors.white70)))
          else
            ...topGames.map((game) => _buildGameItem(game)),

          _buildSectionHeader('Cờ thế tiêu biểu', Icons.extension_rounded, onGoToPuzzles),
          SizedBox(
            height: 180,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: topPuzzles.length,
              itemBuilder: (context, index) {
                final puzzle = topPuzzles[index];
                return _buildPuzzleMiniCard(puzzle);
              },
            ),
          ),
          
          const SizedBox(height: 30),
        ],
      ),
    );
  }

  Widget _buildHeroActions(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        children: [
          Expanded(
            child: _buildHeroCard(
              title: 'Đấu với Máy',
              subtitle: 'Luyện tập AI',
              icon: Icons.smart_toy_rounded,
              color1: const Color(0xFFE65100),
              color2: const Color(0xFFFF8F00),
              onTap: onShowBotSelection,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: _buildHeroCard(
              title: 'Giải Cờ Thế',
              subtitle: 'Thử thách trí tuệ',
              icon: Icons.extension_rounded,
              color1: const Color(0xFF006064),
              color2: const Color(0xFF00BCD4),
              onTap: onGoToPuzzles,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeroCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color1,
    required Color color2,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        height: 100,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [color1, color2],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(color: color1.withOpacity(0.4), blurRadius: 10, offset: const Offset(0, 4)),
          ],
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: Colors.white, size: 28),
            const Spacer(),
            Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
            Text(subtitle, style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 11)),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon, VoidCallback onTap) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Icon(icon, color: Colors.amber, size: 20),
              const SizedBox(width: 8),
              Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
            ],
          ),
          TextButton(
            onPressed: onTap,
            child: const Text('Xem tất cả', style: TextStyle(color: Colors.amber, fontSize: 12)),
          ),
        ],
      ),
    );
  }

  Widget _buildPuzzleMiniCard(Puzzle puzzle) {
    return Container(
      width: 140,
      margin: const EdgeInsets.only(right: 12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white10),
      ),
      child: InkWell(
        onTap: () => onStartPuzzle(puzzle),
        borderRadius: BorderRadius.circular(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            IgnorePointer(
              child: MiniBoard(
                fen: puzzle.fen ?? "rnbakabnr/9/1c5c1/p1p1p1p1p/9/9/P1P1P1P1P/1C5C1/9/RNBAKABNR w - - 0 1",
                width: 80,
              ),
            ),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Text(
                puzzle.name,
                style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGameItem(GameSummary game) {
    return Card(
      color: Colors.white.withOpacity(0.05),
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            if (game.thumbBoard != null)
              Container(
                decoration: BoxDecoration(
                  color: Colors.white10,
                  borderRadius: BorderRadius.circular(8),
                ),
                padding: const EdgeInsets.all(4),
                child: IgnorePointer(
                  child: MiniBoard(
                    board: game.thumbBoard,
                    width: 60,
                  ),
                ),
              )
            else
              const SizedBox(
                width: 60,
                height: 66,
                child: Center(child: Icon(Icons.table_chart, color: Colors.brown, size: 30)),
              ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(game.redName ?? "Trống", style: const TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold, fontSize: 13)),
                  const Text('vs', style: TextStyle(color: Colors.white54, fontSize: 11)),
                  Text(game.blackName ?? "Trống", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                ],
              ),
            ),
            ElevatedButton(
              onPressed: () => onJoinGame(game.roomId),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.amber.withOpacity(0.2),
                foregroundColor: Colors.amber,
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              ),
              child: const Text('Xem', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOnlineStatusSection(List<User> onlinePlayers) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(color: Colors.greenAccent, shape: BoxShape.circle),
              ),
              const SizedBox(width: 8),
              Text('${onlinePlayers.length} kỳ thủ đang online', style: const TextStyle(color: Colors.white70, fontSize: 14)),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 60,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: onlinePlayers.length,
              itemBuilder: (context, index) {
                final player = onlinePlayers[index];
                final String? pic = player.picture;
                final String fullPic = (pic != null && pic.startsWith('/')) 
                    ? 'https://cotuong.xyz$pic' 
                    : (pic ?? '');
                return Container(
                  margin: const EdgeInsets.only(right: 12),
                  child: Tooltip(
                    message: '${player.name} (${player.elo})\nNhấn để thách đấu',
                    child: InkWell(
                      onTap: () => onChallengePlayer(player),
                      borderRadius: BorderRadius.circular(26),
                      child: Stack(
                        children: [
                          CircleAvatar(
                            radius: 26,
                            backgroundColor: Colors.amber.shade200,
                            child: CircleAvatar(
                              radius: 24,
                              backgroundImage: fullPic.isNotEmpty ? NetworkImage(fullPic) : null,
                              backgroundColor: Colors.grey.shade800,
                              child: fullPic.isEmpty ? const Icon(Icons.person, color: Colors.white54) : null,
                            ),
                          ),
                          Positioned(
                            right: 0,
                            bottom: 0,
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: const BoxDecoration(
                                color: Colors.orangeAccent,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.sports_kabaddi, size: 12, color: Colors.white),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
