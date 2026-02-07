import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'dart:math';
import '../../core/models/game_model.dart';
import '../../core/providers/score_provider.dart';
import '../../core/services/haptic_service.dart';
import 'settings_screen.dart';
import 'game_screen.dart';
import 'multiplayer_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  HapticService? _hapticService;
  String _selectedFilter = 'All'; // 'All', 'Single', 'Multi'
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  String _searchQuery = '';
  bool _isSearchFocused = false;

  @override
  void initState() {
    super.initState();
    _initializeServices();
    _searchController.addListener(_onSearchChanged);
    _searchFocusNode.addListener(_onSearchFocusChanged);
  }

  void _onSearchFocusChanged() {
    if (mounted) {
      setState(() {
        _isSearchFocused = _searchFocusNode.hasFocus;
      });
    }
  }

  void _onSearchChanged() {
    if (mounted) {
      setState(() {
        _searchQuery = _searchController.text.toLowerCase();
      });
    }
  }

  Future<void> _initializeServices() async {
    _hapticService = await HapticService.getInstance();
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchFocusNode.removeListener(_onSearchFocusChanged);
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  void _navigateToGame(GameModel game) async {
    await _hapticService?.medium();
    if (!mounted) return;
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => GameScreen(game: game)),
    );
  }

  void _navigateToSettings() async {
    await _hapticService?.light();
    if (!mounted) return;
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const SettingsScreen()),
    );
  }

  void _launchRandomGame() async {
    final random = Random();
    final game = GamesList.allGames[random.nextInt(GamesList.allGames.length)];

    await _hapticService?.heavy();
    if (!mounted) return;

    showGeneralDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black.withOpacity(0.8),
      transitionDuration: const Duration(milliseconds: 600),
      pageBuilder: (context, anim1, anim2) {
        return _RandomGamePickerOverlay(game: game);
      },
    ).then((_) {
      if (mounted) {
        _navigateToGame(game);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final scoreProvider = Provider.of<ScoreProvider>(context);

    final isSearching = _searchQuery.isNotEmpty;
    final filteredGames = GamesList.allGames.where((game) {
      final matchesSearch =
          game.title.toLowerCase().contains(_searchQuery) ||
          game.subtitle.toLowerCase().contains(_searchQuery);
      if (!matchesSearch) return false;

      if (_selectedFilter == 'All') return true;
      if (_selectedFilter == 'Single') return !game.isMultiplayer;
      if (_selectedFilter == 'Multi') return game.isMultiplayer;
      return true;
    }).toList();

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
      ),
      child: Scaffold(
        backgroundColor: isDark ? const Color(0xFF121212) : Colors.white,
        body: Stack(
          children: [
            CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                SliverToBoxAdapter(
                  child: _buildCreativeHeader(context, isDark),
                ),

                if (!isSearching)
                  SliverToBoxAdapter(child: _buildHeroSection(isDark)),

                SliverPersistentHeader(
                  pinned: true,
                  delegate: _SearchFilterHeaderDelegate(
                    isDark: isDark,
                    topPadding: MediaQuery.of(context).padding.top,
                    searchController: _searchController,
                    searchFocusNode: _searchFocusNode,
                    isSearchFocused: _isSearchFocused,
                    searchQuery: _searchQuery,
                    onClearSearch: () {
                      _searchController.clear();
                      _hapticService?.light();
                    },
                    selectedFilter: _selectedFilter,
                    onFilterChanged: (filter) {
                      _hapticService?.selectionClick();
                      setState(() {
                        _selectedFilter = filter;
                      });
                    },
                  ),
                ),

                if (isSearching)
                  _buildSearchResults(filteredGames, scoreProvider, isDark)
                else ...[
                  if (_selectedFilter != 'Single')
                    SliverToBoxAdapter(child: _buildMultiplayerSection(isDark)),

                  ..._buildFilteredCategories(scoreProvider, isDark),

                  const SliverToBoxAdapter(child: SizedBox(height: 80)),
                ],
              ],
            ),

            Positioned(
              bottom: 24,
              left: 20,
              right: 20,
              child: _buildSurpriseMeButton(isDark),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryHeader(String title, String subtitle, bool isDark) {
    return SliverPadding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
      sliver: SliverToBoxAdapter(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: isDark ? Colors.white : Colors.black87,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: isDark ? Colors.grey[500] : Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchResults(
    List<GameModel> games,
    ScoreProvider scoreProvider,
    bool isDark,
  ) {
    if (games.isEmpty) {
      return SliverFillRemaining(
        hasScrollBody: false,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.search_off_rounded,
                size: 64,
                color: isDark ? Colors.grey[700] : Colors.grey[300],
              ),
              const SizedBox(height: 16),
              const Text(
                'No games found',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
      );
    }

    return SliverPadding(
      padding: const EdgeInsets.all(16),
      sliver: SliverGrid(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio: 1.0,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
        ),
        delegate: SliverChildBuilderDelegate(
          (context, index) => _buildEnhancedGameCard(
            games[index],
            scoreProvider.getHighScore(games[index].id),
            isDark,
          ),
          childCount: games.length,
        ),
      ),
    );
  }

  Widget _buildHeroSection(bool isDark) {
    final heroGames = GamesList.allGames
        .where((g) => g.id == 'snake' || g.id == 'ludo' || g.id == 'chess')
        .toList();

    return Container(
      height: 180,
      margin: const EdgeInsets.only(top: 8),
      child: PageView.builder(
        itemCount: heroGames.length,
        controller: PageController(viewportFraction: 0.9),
        itemBuilder: (context, index) {
          final game = heroGames[index];
          return _buildHeroCard(game, isDark);
        },
      ),
    );
  }

  Widget _buildHeroCard(GameModel game, bool isDark) {
    return GestureDetector(
      onTap: () => _navigateToGame(game),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [game.primaryColor, game.secondaryColor],
          ),
        ),
        child: Stack(
          children: [
            Positioned(
              right: -15,
              bottom: -15,
              child: Icon(
                game.icon,
                size: 120,
                color: Colors.white.withOpacity(0.15),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Text(
                      '🌟 GAME OF THE DAY',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                  const Spacer(),
                  Text(
                    game.title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    game.subtitle,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.9),
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildFilteredCategories(
    ScoreProvider scoreProvider,
    bool isDark,
  ) {
    final List<Widget> slivers = [];
    final categories = [
      {
        'cat': GameCategory.battleZone,
        'title': '🔥 The Battle Zone',
        'sub': 'High Energy • Multiplayer',
      },
      {
        'cat': GameCategory.brainGym,
        'title': '🧩 Brain Gym',
        'sub': 'Classic Puzzles • Sharp Mind',
      },
      {
        'cat': GameCategory.arcadeClassics,
        'title': '🕹️ Arcade Classics',
        'sub': 'Quick & Addictive Fun',
      },
      {
        'cat': GameCategory.boardRoom,
        'title': '🎲 The Board Room',
        'sub': 'Timeless Strategy',
      },
    ];

    for (var catData in categories) {
      final category = catData['cat'] as GameCategory;
      final games = GamesList.allGames.where((g) {
        if (g.category != category) return false;
        if (_selectedFilter == 'Single') return !g.isMultiplayer;
        if (_selectedFilter == 'Multi') return g.isMultiplayer;
        return true;
      }).toList();

      if (games.isNotEmpty) {
        slivers.add(
          _buildCategoryHeader(
            catData['title'] as String,
            catData['sub'] as String,
            isDark,
          ),
        );
        slivers.add(_buildStaggeredCategoryGrid(games, scoreProvider, isDark));
      }
    }
    return slivers;
  }

  Widget _buildMultiplayerSection(bool isDark) {
    final multiplayerGames = GamesList.allGames
        .where(
          (g) =>
              g.isMultiplayer &&
              (g.id == 'tap_duel' ||
                  g.id == 'air_hockey' ||
                  g.id == 'tug_of_war' ||
                  g.id == 'space_shooter_duel'),
        )
        .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
          child: InkWell(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const MultiplayerScreen(),
                ),
              );
            },
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '👫 Play with a Friend',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                  ),
                  Image.asset(
                    'assets/icons/forward_icon.png',
                    width: 12,
                    height: 12,
                    color: Colors.grey,
                  ),
                ],
              ),
            ),
          ),
        ),
        SizedBox(
          height: 160,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 14),
            itemCount: multiplayerGames.length,
            physics: const BouncingScrollPhysics(),
            itemBuilder: (context, index) {
              final game = multiplayerGames[index];
              return _buildMultiplayerCard(game, isDark);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildMultiplayerCard(GameModel game, bool isDark) {
    return GestureDetector(
      onTap: () => _navigateToGame(game),
      child: Container(
        width: 140,
        margin: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF2C2C2E) : Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
          border: Border.all(
            color: game.primaryColor.withOpacity(0.2),
            width: 1.5,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: game.primaryColor.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(game.icon, color: game.primaryColor, size: 32),
            ),
            const SizedBox(height: 12),
            Text(
              game.title,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: isDark ? Colors.white : Colors.black87,
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              '2P DUEL',
              style: TextStyle(
                fontSize: 9,
                fontWeight: FontWeight.w900,
                color: Colors.grey,
                letterSpacing: 1,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStaggeredCategoryGrid(
    List<GameModel> games,
    ScoreProvider scoreProvider,
    bool isDark,
  ) {
    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      sliver: SliverMasonryGrid.count(
        crossAxisCount: 2,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        itemBuilder: (context, index) {
          final game = games[index];
          final isLarge =
              (game.id == 'match_3' ||
              game.id == 'water_sort' ||
              game.id == 'chess' ||
              game.id == 'ludo');
          return _buildStaggeredGameCard(
            game,
            scoreProvider.getHighScore(game.id),
            isDark,
            isLarge,
          );
        },
        childCount: games.length,
      ),
    );
  }

  Widget _buildStaggeredGameCard(
    GameModel game,
    int highScore,
    bool isDark,
    bool isLarge,
  ) {
    return GestureDetector(
      onTap: () => _navigateToGame(game),
      child: Container(
        height: isLarge ? 180 : 140,
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1C1C1E) : Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(isDark ? 0.3 : 0.04),
              blurRadius: 15,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: Stack(
            children: [
              Positioned(
                top: -10,
                right: -10,
                child: Icon(
                  game.icon,
                  size: isLarge ? 80 : 60,
                  color: game.primaryColor.withOpacity(0.05),
                ),
              ),
              if (game.id == 'match_3' || game.id == 'water_sort')
                Positioned(
                  top: 12,
                  right: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.redAccent,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text(
                      'TRENDING',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 8,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: game.primaryColor.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        game.icon,
                        size: 22,
                        color: game.primaryColor,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      game.title,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: isDark ? Colors.white : Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      game.id == 'chess' || game.id == 'sudoku'
                          ? 'Timeless'
                          : game.subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 11,
                        color: isDark ? Colors.grey[500] : Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSurpriseMeButton(bool isDark) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFFF8C00).withOpacity(0.4),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: _launchRandomGame,
          borderRadius: BorderRadius.circular(20),
          child: Ink(
            padding: const EdgeInsets.symmetric(vertical: 16),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFFF8C00), Color(0xFFFF5E00)],
              ),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.auto_awesome_rounded, color: Colors.white, size: 24),
                SizedBox(width: 12),
                Text(
                  'Surprise Me!',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCreativeHeader(BuildContext context, bool isDark) {
    return Container(
      height: 150,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? [
                  const Color(0xFFFF8C00),
                  const Color(0xFFE67E00),
                  const Color(0xFFCC7000),
                ]
              : [
                  const Color(0xFFFF8C00),
                  const Color(0xFFFFA533),
                  const Color(0xFFFFB75E),
                ],
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFFF8C00).withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            top: -50,
            right: -50,
            child: Container(
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.1),
              ),
            ),
          ),
          Positioned(
            bottom: -30,
            left: -30,
            child: Container(
              width: 150,
              height: 150,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.05),
              ),
            ),
          ),
          SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: Colors.white.withOpacity(0.25),
                                width: 1,
                              ),
                            ),
                            child: const Icon(
                              Icons.games_rounded,
                              color: Colors.white,
                              size: 30,
                            ),
                          ),
                          const SizedBox(width: 14),
                          const Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'SnapPlay',
                                style: TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.w800,
                                  color: Colors.white,
                                  letterSpacing: -0.8,
                                ),
                              ),
                              Text(
                                'OFFLINE COLLECTION',
                                style: TextStyle(
                                  fontSize: 10,
                                  color: Colors.white,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: Colors.white.withOpacity(0.2),
                            width: 1,
                          ),
                        ),
                        child: IconButton(
                          onPressed: _navigateToSettings,
                          icon: const Icon(
                            Icons.settings_rounded,
                            color: Colors.white,
                            size: 22,
                          ),
                          constraints: const BoxConstraints(
                            minWidth: 40,
                            minHeight: 40,
                          ),
                          padding: EdgeInsets.zero,
                          tooltip: 'Settings',
                        ),
                      ),
                    ],
                  ),
                  const Spacer(),
                  Row(
                    children: [
                      _buildStatChip(
                        Icons.emoji_events_rounded,
                        '${GamesList.allGames.length} Games',
                        Colors.amber,
                      ),
                      const SizedBox(width: 12),
                      _buildStatChip(
                        Icons.offline_bolt_rounded,
                        'No WiFi',
                        const Color(0xFF00E676),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatChip(IconData icon, String label, Color accentColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.15), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: accentColor, size: 18),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEnhancedGameCard(GameModel game, int highScore, bool isDark) {
    return GestureDetector(
      onTap: () => _navigateToGame(game),
      child: Container(
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1C1C1E) : Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(isDark ? 0.3 : 0.06),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
          border: Border.all(
            color: isDark
                ? Colors.white.withOpacity(0.05)
                : Colors.black.withOpacity(0.02),
            width: 1,
          ),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: Stack(
            children: [
              Positioned(
                top: -30,
                right: -30,
                child: Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: game.primaryColor.withOpacity(0.08),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            game.primaryColor,
                            game.primaryColor.withOpacity(0.8),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: game.primaryColor.withOpacity(0.3),
                            blurRadius: 6,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Icon(game.icon, size: 26, color: Colors.white),
                    ),
                    const Spacer(),
                    Text(
                      game.title,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: isDark ? Colors.white : Colors.black87,
                        letterSpacing: -0.4,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    if (highScore > 0 && !game.isMultiplayer)
                      Row(
                        children: [
                          Icon(
                            Icons.emoji_events_rounded,
                            size: 14,
                            color: Colors.amber[700],
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Best: $highScore',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: isDark
                                  ? Colors.grey[400]
                                  : Colors.grey[600],
                            ),
                          ),
                        ],
                      )
                    else
                      Text(
                        game.subtitle,
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark ? Colors.grey[500] : Colors.grey[500],
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SearchFilterHeaderDelegate extends SliverPersistentHeaderDelegate {
  final bool isDark;
  final double topPadding;
  final TextEditingController searchController;
  final FocusNode searchFocusNode;
  final bool isSearchFocused;
  final String searchQuery;
  final VoidCallback onClearSearch;
  final String selectedFilter;
  final Function(String) onFilterChanged;

  _SearchFilterHeaderDelegate({
    required this.isDark,
    required this.topPadding,
    required this.searchController,
    required this.searchFocusNode,
    required this.isSearchFocused,
    required this.searchQuery,
    required this.onClearSearch,
    required this.selectedFilter,
    required this.onFilterChanged,
  });

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return Container(
      height: maxExtent,
      color: isDark ? const Color(0xFF121212) : Colors.white,
      padding: EdgeInsets.fromLTRB(20, topPadding + 8, 20, 12),
      child: Column(
        children: [
          _buildSearchBar(isDark),
          const SizedBox(height: 12),
          _buildSegmentedFilter(isDark),
        ],
      ),
    );
  }

  Widget _buildSearchBar(bool isDark) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOutCubic,
      height: 52,
      decoration: BoxDecoration(
        color: isDark
            ? (isSearchFocused
                  ? const Color(0xFF2C2C2E)
                  : const Color(0xFF1C1C1E))
            : (isSearchFocused
                  ? Colors.white
                  : const Color(0xFFF2F2F7).withOpacity(0.5)),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          if (isSearchFocused)
            BoxShadow(
              color: const Color(0xFFFF8C00).withOpacity(isDark ? 0.2 : 0.15),
              blurRadius: 15,
              offset: const Offset(0, 6),
            ),
          if (!isSearchFocused)
            BoxShadow(
              color: Colors.black.withOpacity(isDark ? 0.2 : 0.04),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
        ],
        border: Border.all(
          color: isSearchFocused
              ? const Color(0xFFFF8C00).withOpacity(0.5)
              : (isDark
                    ? Colors.white.withOpacity(0.08)
                    : Colors.black.withOpacity(0.05)),
          width: isSearchFocused ? 1.5 : 1,
        ),
      ),
      child: TextField(
        controller: searchController,
        focusNode: searchFocusNode,
        style: TextStyle(
          color: isDark ? Colors.white : Colors.black87,
          fontSize: 16,
          fontWeight: FontWeight.w500,
        ),
        decoration: InputDecoration(
          hintText: 'Search your favorite game...',
          hintStyle: TextStyle(
            color: isDark
                ? Colors.white.withOpacity(0.3)
                : Colors.black.withOpacity(0.3),
            fontSize: 15,
            fontWeight: FontWeight.w400,
          ),
          prefixIcon: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Icon(
              Icons.search_rounded,
              color: isSearchFocused
                  ? const Color(0xFFFF8C00)
                  : (isDark ? Colors.white38 : Colors.black38),
              size: 22,
            ),
          ),
          suffixIcon: searchQuery.isNotEmpty
              ? Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: IconButton(
                    icon: Icon(
                      Icons.cancel_rounded,
                      color: isDark ? Colors.white38 : Colors.black38,
                      size: 20,
                    ),
                    onPressed: onClearSearch,
                  ),
                )
              : null,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 15),
        ),
      ),
    );
  }

  Widget _buildSegmentedFilter(bool isDark) {
    const List<String> options = ['All', 'Single', 'Multi'];
    final labels = {
      'All': 'All Games',
      'Single': 'Single',
      'Multi': 'Multiplayer',
    };
    int selectedIndex = options.indexOf(selectedFilter);

    return Container(
      height: 38,
      width: double.infinity,
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: isDark
            ? const Color(0xFF1C1C1E)
            : const Color(0xFFF2F2F7).withOpacity(0.5),
        borderRadius: BorderRadius.circular(12),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final itemWidth = constraints.maxWidth / options.length;
          return Stack(
            children: [
              AnimatedPositioned(
                duration: const Duration(milliseconds: 250),
                curve: Curves.easeInOutExpo,
                left: selectedIndex * itemWidth,
                top: 0,
                bottom: 0,
                width: itemWidth,
                child: Container(
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF636366) : Colors.white,
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                ),
              ),
              Row(
                children: options.map((option) {
                  final isSelected = selectedFilter == option;
                  return Expanded(
                    child: GestureDetector(
                      onTap: () => onFilterChanged(option),
                      behavior: HitTestBehavior.opaque,
                      child: Center(
                        child: Text(
                          labels[option] ?? '',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: isSelected
                                ? FontWeight.w600
                                : FontWeight.w500,
                            color: isSelected
                                ? (isDark ? Colors.white : Colors.black87)
                                : (isDark ? Colors.white54 : Colors.black54),
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
          );
        },
      ),
    );
  }

  @override
  double get maxExtent => 130 + topPadding;
  @override
  double get minExtent => 130 + topPadding;
  @override
  bool shouldRebuild(covariant _SearchFilterHeaderDelegate oldDelegate) {
    return oldDelegate.isDark != isDark ||
        oldDelegate.isSearchFocused != isSearchFocused ||
        oldDelegate.searchQuery != searchQuery ||
        oldDelegate.selectedFilter != selectedFilter;
  }
}

class _RandomGamePickerOverlay extends StatefulWidget {
  final GameModel game;
  const _RandomGamePickerOverlay({required this.game});

  @override
  State<_RandomGamePickerOverlay> createState() =>
      _RandomGamePickerOverlayState();
}

class _RandomGamePickerOverlayState extends State<_RandomGamePickerOverlay>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _rotateAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
    _scaleAnimation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween(
          begin: 0.0,
          end: 1.2,
        ).chain(CurveTween(curve: Curves.easeOutBack)),
        weight: 40,
      ),
      TweenSequenceItem(
        tween: Tween(
          begin: 1.2,
          end: 1.0,
        ).chain(CurveTween(curve: Curves.easeInOut)),
        weight: 20,
      ),
      TweenSequenceItem(tween: ConstantTween<double>(1.0), weight: 40),
    ]).animate(_controller);
    _rotateAnimation = Tween<double>(begin: 0, end: 8).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.4, curve: Curves.easeInOut),
      ),
    );
    _controller.forward().then(
      (_) => Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted) Navigator.pop(context);
      }),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return Transform.rotate(
            angle: _rotateAnimation.value * pi * 2,
            child: Transform.scale(
              scale: _scaleAnimation.value,
              child: Container(
                width: 250,
                height: 250,
                decoration: BoxDecoration(
                  color: widget.game.primaryColor,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: widget.game.primaryColor.withOpacity(0.5),
                      blurRadius: 40,
                      spreadRadius: 10,
                    ),
                  ],
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(widget.game.icon, size: 80, color: Colors.white),
                    const SizedBox(height: 20),
                    Text(
                      'Launching...',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.8),
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        decoration: TextDecoration.none,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      widget.game.title,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.w900,
                        decoration: TextDecoration.none,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
