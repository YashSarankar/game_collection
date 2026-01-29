import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import '../../core/models/game_model.dart';
import '../../core/providers/coins_provider.dart';
import '../../core/providers/score_provider.dart';

import '../../core/services/ad_service.dart';
import '../../core/services/haptic_service.dart';

// import '../widgets/daily_reward_card.dart';
import 'settings_screen.dart';
import 'game_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  AdService? _adService;
  HapticService? _hapticService;
  BannerAd? _bannerAd;
  String _selectedFilter = 'All'; // 'All', 'Single', 'Multi'

  @override
  void initState() {
    super.initState();
    _initializeServices();
  }

  Future<void> _initializeServices() async {
    _adService = await AdService.getInstance();
    _hapticService = await HapticService.getInstance();

    setState(() {
      _bannerAd = _adService?.getBannerAd();
    });
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

    // Show interstitial ad after returning from game
    await _adService?.showInterstitialAd();
  }

  void _navigateToSettings() async {
    await _hapticService?.light();

    if (!mounted) return;

    await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const SettingsScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final coinsProvider = Provider.of<CoinsProvider>(context);
    final scoreProvider = Provider.of<ScoreProvider>(context);

    // Filtered games list
    final filteredGames = GamesList.allGames.where((game) {
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
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        body: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            // Scrollable Game Hub Header
            SliverToBoxAdapter(
              child: _buildCreativeHeader(context, isDark, coinsProvider),
            ),

            // Welcome Section & Filter Bar
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Choose Your Game',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : Colors.black87,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Play offline anytime, anywhere',
                      style: TextStyle(
                        fontSize: 14,
                        color: isDark ? Colors.grey[400] : Colors.grey[600],
                      ),
                    ),
                    const SizedBox(height: 16),
                    // iOS Style Segmented Control
                    _buildSegmentedFilter(isDark),
                  ],
                ),
              ),
            ),

            // Games Grid with Staggered Layout
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 40),
              sliver: SliverGrid(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  childAspectRatio: 1.0,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                ),
                delegate: SliverChildBuilderDelegate((context, index) {
                  final game = filteredGames[index];
                  final highScore = scoreProvider.getHighScore(game.id);

                  return TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0.0, end: 1.0),
                    duration: Duration(milliseconds: 300 + (index * 100)),
                    curve: Curves.easeOutBack,
                    builder: (context, value, child) {
                      return Transform.scale(
                        scale: value.clamp(0.0, 1.0),
                        child: Opacity(
                          opacity: value.clamp(0.0, 1.0),
                          child: _buildEnhancedGameCard(
                            game,
                            highScore,
                            isDark,
                          ),
                        ),
                      );
                    },
                  );
                }, childCount: filteredGames.length),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSegmentedFilter(bool isDark) {
    final List<String> options = ['All', 'Single', 'Multi'];
    final labels = {
      'All': 'All Games',
      'Single': 'Single',
      'Multi': 'Multiplayer',
    };

    int selectedIndex = options.indexOf(_selectedFilter);

    return Container(
      height: 36,
      width: double.infinity,
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1C1C1E) : const Color(0xFFF2F2F7),
        borderRadius: BorderRadius.circular(10),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final itemWidth = constraints.maxWidth / options.length;
          return Stack(
            children: [
              // Sliding Highlight
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
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.12),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                ),
              ),
              // Filter Buttons
              Row(
                children: options.map((option) {
                  final isSelected = _selectedFilter == option;
                  return Expanded(
                    child: GestureDetector(
                      onTap: () {
                        if (!isSelected) {
                          _hapticService?.selectionClick();
                          setState(() {
                            _selectedFilter = option;
                          });
                        }
                      },
                      behavior: HitTestBehavior.opaque,
                      child: Center(
                        child: Text(
                          labels[option]!,
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

  Widget _buildCreativeHeader(
    BuildContext context,
    bool isDark,
    CoinsProvider coinsProvider,
  ) {
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
          // Decorative circles
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

          // Content
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
                      // App Icon and Title
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
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Game Hub',
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
                                  color: Colors.white.withOpacity(0.7),
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),

                      // Refined Settings Button with Border
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

                  // Stats Row
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
                        Colors.greenAccent,
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
              // Subtle Inner Glow
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

              // Content
              Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // App Icon Style
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

                    // Title
                    Text(
                      game.title,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: isDark
                            ? Colors.white
                            : Colors.black.withOpacity(0.85),
                        letterSpacing: -0.4,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),

                    const SizedBox(height: 4),

                    // Subtitle or Score
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
