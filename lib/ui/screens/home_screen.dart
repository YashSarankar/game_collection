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
import 'search_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  HapticService? _hapticService;
  String _selectedFilter = 'All'; // 'All', 'Single', 'Multi'

  @override
  void initState() {
    super.initState();
    _initializeServices();
  }

  Future<void> _initializeServices() async {
    _hapticService = await HapticService.getInstance();
  }

  @override
  void dispose() {
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
                SliverPersistentHeader(
                  pinned: true,
                  delegate: _MainHeaderDelegate(
                    isDark: isDark,
                    selectedFilter: _selectedFilter,
                    onFilterChanged: (filter) {
                      _hapticService?.selectionClick();
                      setState(() => _selectedFilter = filter);
                    },
                    onNavigateToSettings: _navigateToSettings,
                    hapticService: _hapticService,
                  ),
                ),
                SliverToBoxAdapter(child: _buildHeroSection(isDark)),
                if (_selectedFilter != 'Single')
                  SliverToBoxAdapter(child: _buildMultiplayerSection(isDark)),
                ..._buildFilteredCategories(scoreProvider, isDark),
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

  Widget _buildCategoryHeader(
    String icon,
    String title,
    String subtitle,
    bool isDark,
  ) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(icon, style: const TextStyle(fontSize: 18)),
              const SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: isDark ? Colors.white : Colors.black87,
                  letterSpacing: -0.5,
                ),
              ),
            ],
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
    );
  }

  int _getDailyIndex(int total) {
    final now = DateTime.now();
    // Use days since a fixed epoch to get a stable index for the entire day
    final daysSinceEpoch = now.difference(DateTime(2025, 1, 1)).inDays;
    return daysSinceEpoch % total;
  }

  Widget _buildHeroSection(bool isDark) {
    final allGames = GamesList.allGames;
    final dailyIndex = _getDailyIndex(allGames.length);

    // Select 3 games: One "Game of the Day" and two other featured games
    // We use offsets to ensure they are always different
    final heroGames = [
      allGames[dailyIndex],
      allGames[(dailyIndex + 5) % allGames.length],
      allGames[(dailyIndex + 12) % allGames.length],
    ];

    return Container(
      height: 160,
      margin: EdgeInsets.zero,
      child: PageView.builder(
        itemCount: heroGames.length,
        controller: PageController(viewportFraction: 0.9),
        itemBuilder: (context, index) {
          final game = heroGames[index];
          return _buildHeroCard(game, isDark, isMain: index == 0);
        },
      ),
    );
  }

  Widget _buildHeroCard(GameModel game, bool isDark, {bool isMain = true}) {
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
          border: Border.all(color: Colors.white.withOpacity(0.2), width: 1.5),
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
                    child: Text(
                      isMain ? '🌟 GAME OF THE DAY' : '✨ FEATURED FOR YOU',
                      style: const TextStyle(
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
        'icon': '🔥',
        'title': 'The Battle Zone',
        'sub': 'High Energy • Multiplayer',
      },
      {
        'cat': GameCategory.brainGym,
        'icon': '🧩',
        'title': 'Brain Gym',
        'sub': 'Classic Puzzles • Sharp Mind',
      },
      {
        'cat': GameCategory.arcadeClassics,
        'icon': '🕹️',
        'title': 'Arcade Classics',
        'sub': 'Quick & Addictive Fun',
      },
      {
        'cat': GameCategory.boardRoom,
        'icon': '🎲',
        'title': 'The Board Room',
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
          SliverToBoxAdapter(
            child: _buildCategoryHeader(
              catData['icon'] as String,
              catData['title'] as String,
              catData['sub'] as String,
              isDark,
            ),
          ),
        );
        slivers.add(
          SliverToBoxAdapter(
            child: _buildStaggeredCategoryGrid(games, scoreProvider, isDark),
          ),
        );
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
              padding: const EdgeInsets.symmetric(vertical: 0, horizontal: 0),
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
            padding: const EdgeInsets.symmetric(horizontal: 10),
            itemCount: multiplayerGames.length,
            physics: const ClampingScrollPhysics(),
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
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
      child: MasonryGridView.count(
        padding: EdgeInsets.zero,
        crossAxisCount: 2,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
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
        itemCount: games.length,
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
          border: Border.all(
            color: isDark
                ? Colors.white.withOpacity(0.08)
                : Colors.black.withOpacity(0.05),
            width: 1,
          ),
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
}

class _MainHeaderDelegate extends SliverPersistentHeaderDelegate {
  final bool isDark;
  final String selectedFilter;
  final Function(String) onFilterChanged;
  final VoidCallback onNavigateToSettings;
  final HapticService? hapticService;

  _MainHeaderDelegate({
    required this.isDark,
    required this.selectedFilter,
    required this.onFilterChanged,
    required this.onNavigateToSettings,
    this.hapticService,
  });

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    final topPadding = MediaQuery.of(context).padding.top;
    final progress = shrinkOffset / (maxExtent - minExtent);
    final currentProgress = progress.clamp(0.0, 1.0);

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? [
                  const Color(0xFFFF8C00),
                  const Color(0xFFE67E00),
                  const Color(0xFFBD6800),
                ]
              : [
                  const Color(0xFFFF8C00),
                  const Color(0xFFFFA533),
                  const Color(0xFFFFB75E),
                ],
        ),
      ),
      child: Stack(
        children: [
          // Decorative Circles (Fade out on scroll)
          Opacity(
            opacity: 1.0 - currentProgress,
            child: Stack(
              children: [
                Positioned(
                  top: -40,
                  right: -20,
                  child: Container(
                    width: 160,
                    height: 160,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withOpacity(0.08),
                    ),
                  ),
                ),
                Positioned(
                  bottom: -20,
                  left: -10,
                  child: Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withOpacity(0.05),
                    ),
                  ),
                ),
              ],
            ),
          ),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Stack(
              children: [
                // Top Row (Logo & Settings) - Fade & Scale
                Positioned(
                  top: topPadding + 8,
                  left: 0,
                  right: 0,
                  child: Opacity(
                    opacity: (1.0 - currentProgress * 2.0).clamp(0.0, 1.0),
                    child: Transform.scale(
                      scale: 1.0 - currentProgress * 0.1,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.15),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Icon(
                                  Icons.games_rounded,
                                  color: Colors.white,
                                  size: 24,
                                ),
                              ),
                              const SizedBox(width: 12),
                              const Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'SnapPlay',
                                    style: TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.w900,
                                      color: Colors.white,
                                      letterSpacing: -0.5,
                                    ),
                                  ),
                                  Text(
                                    'THE OFFLINE COLLECTION',
                                    style: TextStyle(
                                      fontSize: 9,
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
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: IconButton(
                              onPressed: onNavigateToSettings,
                              icon: const Icon(
                                Icons.settings_rounded,
                                color: Colors.white,
                                size: 20,
                              ),
                              constraints: const BoxConstraints(
                                minWidth: 26,
                                minHeight: 26,
                              ),
                              padding: EdgeInsets.zero,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                // Search & Filter Bar - Move & Morph
                Positioned(
                  bottom: 8,
                  left: 0,
                  right: 0,
                  child: Container(
                    height: 52,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(
                        0.15 + (currentProgress * 0.1),
                      ),
                      borderRadius: BorderRadius.circular(
                        16 - (currentProgress * 4),
                      ),
                      border: Border.all(
                        color: Colors.white.withOpacity(0.2),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: GestureDetector(
                            onTap: () {
                              hapticService?.light();
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const SearchScreen(),
                                ),
                              );
                            },
                            behavior: HitTestBehavior.opaque,
                            child: const Padding(
                              padding: EdgeInsets.symmetric(horizontal: 16),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.search_rounded,
                                    color: Colors.white70,
                                    size: 22,
                                  ),
                                  SizedBox(width: 12),
                                  Text(
                                    'Search games...',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 15,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        Container(
                          width: 1,
                          height: 24,
                          color: Colors.white.withOpacity(0.2),
                        ),
                        PopupMenuButton<String>(
                          initialValue: selectedFilter,
                          onSelected: onFilterChanged,
                          icon: const Icon(
                            Icons.tune_rounded,
                            color: Colors.white,
                            size: 20,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          itemBuilder: (context) => [
                            const PopupMenuItem(
                              value: 'All',
                              child: Text('All Games'),
                            ),
                            const PopupMenuItem(
                              value: 'Single',
                              child: Text('Single Player'),
                            ),
                            const PopupMenuItem(
                              value: 'Multi',
                              child: Text('Multiplayer'),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  double get maxExtent => 160;
  @override
  double get minExtent => 105;

  @override
  bool shouldRebuild(covariant _MainHeaderDelegate oldDelegate) {
    return oldDelegate.isDark != isDark ||
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
