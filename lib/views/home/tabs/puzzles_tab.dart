import 'package:flutter/material.dart';
import '../../../models/game_models.dart';
import '../../../widgets/mini_board.dart';
import '../../../services/api_service.dart';

class PuzzlesTab extends StatefulWidget {
  final Function(Puzzle) onStartPuzzle;
  final ApiService apiService;

  const PuzzlesTab({
    super.key,
    required this.onStartPuzzle,
    required this.apiService,
  });

  @override
  State<PuzzlesTab> createState() => _PuzzlesTabState();
}

class _PuzzlesTabState extends State<PuzzlesTab> {
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();
  List<Puzzle> _puzzles = [];
  int _currentPage = 1;
  bool _isLoading = true;
  bool _isFetchingMore = false;
  bool _hasMore = true;

  @override
  void initState() {
    super.initState();
    _fetchPuzzles();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200) {
      _loadMore();
    }
  }

  Future<void> _fetchPuzzles({bool refresh = false}) async {
    if (refresh) {
      setState(() {
        _currentPage = 1;
        _hasMore = true;
        _isLoading = true;
      });
    }

    final query = _searchController.text.trim();
    final results = await widget.apiService.getPuzzles(page: _currentPage, limit: 12, query: query);

    if (mounted) {
      setState(() {
        if (refresh) {
          _puzzles = results;
        } else {
          _puzzles.addAll(results);
        }
        _hasMore = results.length == 12; // Assuming limit is 12
        _isLoading = false;
        _isFetchingMore = false;
      });
    }
  }

  Future<void> _loadMore() async {
    if (_isFetchingMore || !_hasMore) return;
    setState(() => _isFetchingMore = true);
    _currentPage++;
    await _fetchPuzzles();
  }

  void _onSearchSubmit(String val) {
    _fetchPuzzles(refresh: true);
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
              hintText: 'Tìm cờ thế...',
              hintStyle: const TextStyle(color: Colors.white54),
              prefixIcon: const Icon(Icons.search, color: Colors.white54),
              suffixIcon: IconButton(
                icon: const Icon(Icons.clear, color: Colors.white54),
                onPressed: () {
                  _searchController.clear();
                  _fetchPuzzles(refresh: true);
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
            onSubmitted: _onSearchSubmit,
          ),
        ),
        Expanded(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _puzzles.isEmpty
                  ? const Center(child: Text('Không tìm thấy cờ thế nào', style: TextStyle(color: Colors.white54)))
                  : GridView.builder(
                      controller: _scrollController,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        crossAxisSpacing: 16,
                        mainAxisSpacing: 16,
                        childAspectRatio: 0.85,
                      ),
                      itemCount: _puzzles.length + (_hasMore ? 1 : 0),
                      itemBuilder: (context, index) {
                        if (index == _puzzles.length) {
                          return const Center(child: Padding(
                            padding: EdgeInsets.all(8.0),
                            child: CircularProgressIndicator(),
                          ));
                        }
                        
                        final puzzle = _puzzles[index];
                        Color levelColor;
                        String levelName;
                        if (puzzle.level <= 2) {
                          levelColor = Colors.green.shade400;
                          levelName = 'Dễ';
                        } else if (puzzle.level <= 4) {
                          levelColor = Colors.orange.shade400;
                          levelName = 'Trung bình';
                        } else {
                          levelColor = Colors.red.shade400;
                          levelName = 'Khó';
                        }

                        return InkWell(
                          onTap: () => widget.onStartPuzzle(puzzle),
                          borderRadius: BorderRadius.circular(20),
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.05),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: Colors.white10),
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: levelColor.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: IgnorePointer(
                                    child: MiniBoard(
                                      fen: puzzle.fen ?? "rnbakabnr/9/1c5c1/p1p1p1p1p/9/9/P1P1P1P1P/1C5C1/9/RNBAKABNR w - - 0 1",
                                      width: 90,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 12),
                                Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 8),
                                  child: Text(
                                    puzzle.name,
                                    style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
                                    textAlign: TextAlign.center,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: levelColor.withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    levelName,
                                    style: TextStyle(color: levelColor, fontSize: 10, fontWeight: FontWeight.bold),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
        ),
      ],
    );
  }
}
