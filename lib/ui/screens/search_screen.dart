import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/models/game_model.dart';
import '../../core/providers/score_provider.dart';
import '../../core/services/haptic_service.dart';
import 'game_screen.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  String _searchQuery = '';
  HapticService? _hapticService;

  @override
  void initState() {
    super.initState();
    _initializeHaptics();
    // Auto-focus the search bar when the screen opens
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNode.requestFocus();
    });
  }

  Future<void> _initializeHaptics() async {
    _hapticService = await HapticService.getInstance();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _navigateToGame(GameModel game) async {
    await _hapticService?.medium();
    if (!mounted) return;
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => GameScreen(game: game)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final scoreProvider = Provider.of<ScoreProvider>(context);

    final filteredGames = GamesList.allGames.where((game) {
      final query = _searchQuery.toLowerCase();
      return game.title.toLowerCase().contains(query) ||
          game.subtitle.toLowerCase().contains(query);
    }).toList();

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF121212) : Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(isDark),
            Expanded(
              child: _searchQuery.isEmpty
                  ? _buildEmptyState(isDark, isInitial: true)
                  : filteredGames.isEmpty
                  ? _buildEmptyState(isDark, isInitial: false)
                  : _buildResultsList(filteredGames, scoreProvider, isDark),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(bool isDark) {
    return Container(
      padding: const EdgeInsets.fromLTRB(8, 8, 20, 16),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: Icon(
              Icons.arrow_back_ios_new_rounded,
              color: isDark ? Colors.white : Colors.black87,
              size: 20,
            ),
          ),
          Expanded(
            child: Container(
              height: 52,
              decoration: BoxDecoration(
                color: isDark
                    ? const Color(0xFF1C1C1E)
                    : const Color(0xFFF2F2F7),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: const Color(0xFFFF8C00).withOpacity(0.3),
                  width: 1,
                ),
              ),
              child: TextField(
                controller: _searchController,
                focusNode: _focusNode,
                onChanged: (value) => setState(() => _searchQuery = value),
                style: TextStyle(
                  color: isDark ? Colors.white : Colors.black87,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
                decoration: InputDecoration(
                  hintText: 'Search for a game...',
                  hintStyle: TextStyle(
                    color: isDark ? Colors.white38 : Colors.black38,
                    fontSize: 15,
                  ),
                  prefixIcon: const Icon(
                    Icons.search_rounded,
                    color: Color(0xFFFF8C00),
                    size: 22,
                  ),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? IconButton(
                          icon: Icon(
                            Icons.cancel_rounded,
                            color: isDark ? Colors.white38 : Colors.black38,
                            size: 20,
                          ),
                          onPressed: () {
                            _searchController.clear();
                            setState(() => _searchQuery = '');
                          },
                        )
                      : null,
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResultsList(
    List<GameModel> games,
    ScoreProvider scoreProvider,
    bool isDark,
  ) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      itemCount: games.length,
      itemBuilder: (context, index) {
        final game = games[index];
        final highScore = scoreProvider.getHighScore(game.id);

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () => _navigateToGame(game),
              borderRadius: BorderRadius.circular(20),
              child: Ink(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1C1C1E) : Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(isDark ? 0.2 : 0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [game.primaryColor, game.secondaryColor],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Icon(game.icon, color: Colors.white, size: 28),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            game.title,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              color: isDark ? Colors.white : Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            game.subtitle,
                            style: TextStyle(
                              fontSize: 13,
                              color: isDark
                                  ? Colors.grey[500]
                                  : Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (highScore > 0)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.amber.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.emoji_events_rounded,
                              color: Colors.amber,
                              size: 14,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '$highScore',
                              style: const TextStyle(
                                color: Colors.amber,
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    const SizedBox(width: 8),
                    Image.asset(
                      'assets/icons/forward_icon.png',
                      width: 12,
                      height: 12,
                      color: isDark ? Colors.white24 : Colors.black12,
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildEmptyState(bool isDark, {required bool isInitial}) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            isInitial ? Icons.search_rounded : Icons.search_off_rounded,
            size: 80,
            color: isDark ? Colors.white10 : Colors.black.withOpacity(0.05),
          ),
          const SizedBox(height: 20),
          Text(
            isInitial ? 'Find your favorite game' : 'No games found',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.grey[600] : Colors.grey[400],
            ),
          ),
          if (!isInitial) ...[
            const SizedBox(height: 8),
            Text(
              'Try searching for something else',
              style: TextStyle(
                fontSize: 14,
                color: isDark ? Colors.grey[700] : Colors.grey[500],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
