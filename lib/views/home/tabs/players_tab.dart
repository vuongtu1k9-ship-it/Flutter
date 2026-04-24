import 'package:flutter/material.dart';
import '../../../models/game_models.dart';
import '../../../services/api_service.dart';
import '../../profile_view.dart';

class PlayersTab extends StatefulWidget {
  final List<User> onlinePlayers;
  final Map<String, dynamic> currentUserData;
  final Function(User) onChallengePlayer;
  final bool isLoading;
  final ApiService apiService;

  const PlayersTab({
    super.key,
    required this.onlinePlayers,
    required this.currentUserData,
    required this.onChallengePlayer,
    required this.isLoading,
    required this.apiService,
  });

  @override
  State<PlayersTab> createState() => _PlayersTabState();
}

class _PlayersTabState extends State<PlayersTab> {
  final TextEditingController _searchController = TextEditingController();
  List<User>? _searchResults;
  bool _isSearching = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onSearch(String val) async {
    final query = val.trim();
    if (query.isEmpty) {
      setState(() {
        _searchResults = null;
        _isSearching = false;
      });
      return;
    }

    setState(() => _isSearching = true);
    final results = await widget.apiService.getPlayers(search: query, limit: 50);
    if (mounted) {
      setState(() {
        _searchResults = results;
        _isSearching = false;
      });
    }
  }

  void _goToProfile(User player) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ProfileView(
          uid: player.uid,
          apiService: widget.apiService,
          currentUserData: widget.currentUserData,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: TextField(
            controller: _searchController,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              hintText: 'Tìm kiếm kỳ thủ...',
              hintStyle: const TextStyle(color: Colors.white54),
              prefixIcon: const Icon(Icons.search, color: Colors.white54),
              suffixIcon: IconButton(
                icon: const Icon(Icons.clear, color: Colors.white54),
                onPressed: () {
                  _searchController.clear();
                  _onSearch('');
                },
              ),
              filled: true,
              fillColor: Colors.white.withOpacity(0.1),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(30),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 0),
            ),
            onSubmitted: _onSearch,
          ),
        ),
        Expanded(
          child: _buildList(),
        ),
      ],
    );
  }

  Widget _buildList() {
    if (_isSearching) return const Center(child: CircularProgressIndicator());
    
    final displayList = _searchResults ?? widget.onlinePlayers;
    
    if (widget.isLoading && _searchResults == null) {
      return const Center(child: CircularProgressIndicator());
    }
    if (displayList.isEmpty) {
      return const Center(child: Text('Không tìm thấy kỳ thủ nào', style: TextStyle(color: Colors.white54)));
    }

    // Sắp xếp: Online lên đầu, sau đó theo Elo giảm dần
    final rankedPlayers = List<User>.from(displayList);
    if (_searchResults == null) {
      rankedPlayers.sort((a, b) {
        if (a.online && !b.online) return -1;
        if (!a.online && b.online) return 1;
        return b.elo.compareTo(a.elo);
      });
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: rankedPlayers.length,
      itemBuilder: (context, index) {
        final player = rankedPlayers[index];
        final String? pic = player.picture;
        final String fullPic = (pic != null && pic.startsWith('/')) 
            ? 'https://cotuong.xyz$pic' 
            : (pic ?? '');
        
        final int rank = index + 1;
        Widget rankWidget;
        if (_searchResults != null) {
          rankWidget = const Icon(Icons.person, color: Colors.white54);
        } else if (rank == 1) {
          rankWidget = const Icon(Icons.emoji_events, color: Color(0xFFFFD700), size: 28);
        } else if (rank == 2) {
          rankWidget = const Icon(Icons.emoji_events, color: Color(0xFFC0C0C0), size: 26);
        } else if (rank == 3) {
          rankWidget = const Icon(Icons.emoji_events, color: Color(0xFFCD7F32), size: 24);
        } else {
          rankWidget = Text(
            '#$rank',
            style: TextStyle(
              color: Colors.grey.shade400,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          );
        }

        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.05),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white10),
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            leading: SizedBox(
              width: 80,
              child: Row(
                children: [
                  SizedBox(width: 30, child: Center(child: rankWidget)),
                  const SizedBox(width: 10),
                  GestureDetector(
                    onTap: () => _goToProfile(player),
                    child: CircleAvatar(
                      radius: 20,
                      backgroundImage: fullPic.isNotEmpty ? NetworkImage(fullPic) : null,
                      backgroundColor: Colors.amber.shade100,
                      child: fullPic.isEmpty ? Icon(Icons.person, color: Colors.amber.shade900) : null,
                    ),
                  ),
                ],
              ),
            ),
            title: GestureDetector(
              onTap: () => _goToProfile(player),
              child: Text(
                player.name,
                style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
              ),
            ),
            subtitle: Row(
              children: [
                const Icon(Icons.star, size: 14, color: Colors.amber),
                const SizedBox(width: 4),
                Text('${player.elo} Elo', style: const TextStyle(color: Colors.white70)),
              ],
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (player.online)
                  Container(
                    margin: const EdgeInsets.only(right: 8),
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.green.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.green.withOpacity(0.5)),
                    ),
                    child: const Text('Online', style: TextStyle(color: Colors.green, fontSize: 10, fontWeight: FontWeight.bold)),
                  ),
                if (player.uid != widget.currentUserData['uid'])
                  IconButton(
                    icon: const Icon(Icons.sports_kabaddi, color: Colors.orangeAccent),
                    onPressed: () => widget.onChallengePlayer(player),
                  ),
              ],
            ),
            onTap: () => _goToProfile(player),
          ),
        );
      },
    );
  }
}
