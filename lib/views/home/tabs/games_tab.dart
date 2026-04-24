import 'package:flutter/material.dart';
import '../../../models/game_models.dart';
import '../../../widgets/mini_board.dart';
import '../../../services/api_service.dart';

class GamesTab extends StatefulWidget {
  final Function(String) onJoinGame;
  final ApiService apiService;

  const GamesTab({
    super.key,
    required this.onJoinGame,
    required this.apiService,
  });

  @override
  State<GamesTab> createState() => _GamesTabState();
}

class _GamesTabState extends State<GamesTab> {
  final ScrollController _scrollController = ScrollController();
  List<GameSummary> _games = [];
  bool _isLoading = true;
  bool _isFetchingMore = false;
  bool _hasMore = true;

  @override
  void initState() {
    super.initState();
    _fetchGames();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200) {
      _loadMore();
    }
  }

  Future<void> _fetchGames({bool refresh = false}) async {
    if (refresh) {
      setState(() {
        _hasMore = true;
        _isLoading = true;
      });
    }

    int? cursor;
    if (!refresh && _games.isNotEmpty) {
      cursor = _games.last.createdAt;
    }

    final results = await widget.apiService.getGames(limit: 10, cursor: cursor);

    if (mounted) {
      setState(() {
        if (refresh) {
          _games = results;
        } else {
          _games.addAll(results);
        }
        _hasMore = results.length == 10;
        _isLoading = false;
        _isFetchingMore = false;
      });
    }
  }

  Future<void> _loadMore() async {
    if (_isFetchingMore || !_hasMore) return;
    setState(() => _isFetchingMore = true);
    await _fetchGames();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const Center(child: CircularProgressIndicator());
    if (_games.isEmpty) return const Center(child: Text('Không có bàn cờ nào đang chơi', style: TextStyle(color: Colors.white54)));

    return RefreshIndicator(
      onRefresh: () => _fetchGames(refresh: true),
      child: ListView.builder(
        controller: _scrollController,
        itemCount: _games.length + (_hasMore ? 1 : 0),
        itemBuilder: (context, index) {
          if (index == _games.length) {
            return const Center(child: Padding(
              padding: EdgeInsets.all(8.0),
              child: CircularProgressIndicator(),
            ));
          }

          final game = _games[index];
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
                          width: 80,
                        ),
                      ),
                    )
                  else
                    const SizedBox(
                      width: 80,
                      height: 88,
                      child: Center(child: Icon(Icons.table_chart, color: Colors.brown, size: 40)),
                    ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(game.redName ?? "Trống", style: const TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold)),
                        const Text('vs', style: TextStyle(color: Colors.white54, fontSize: 12)),
                        Text(game.blackName ?? "Trống", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 8),
                        Text('Khán giả: ${game.spectators}', style: const TextStyle(color: Colors.amber, fontSize: 12)),
                      ],
                    ),
                  ),
                  ElevatedButton(
                    onPressed: () => widget.onJoinGame(game.roomId),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.amber,
                      foregroundColor: Colors.black,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                    ),
                    child: const Text('Vào Xem', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
