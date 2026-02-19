import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:provider/provider.dart';
import '../../core/providers/settings_provider.dart';
import '../../core/providers/score_provider.dart';

import '../../core/services/haptic_service.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  HapticService? _hapticService;

  @override
  void initState() {
    super.initState();
    _initializeServices();
  }

  Future<void> _initializeServices() async {
    _hapticService = await HapticService.getInstance();
  }

  Future<void> _launchURL(String urlString) async {
    final Uri url = Uri.parse(urlString);
    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Could not launch $urlString')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final settingsProvider = Provider.of<SettingsProvider>(context);
    final scoreProvider = Provider.of<ScoreProvider>(context);

    // Determines if we used dark mode based on Theme (system or user preference)
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // iOS Grouped Background Colors
    final backgroundColor = isDark
        ? const Color(0xFF000000)
        : const Color(0xFFF2F2F7);
    final groupColor = isDark ? const Color(0xFF1C1C1E) : Colors.white;
    final dividerColor = isDark
        ? const Color(0xFF38383A)
        : const Color(0xFFE5E5EA);

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        title: const Text('Settings'),
        backgroundColor: backgroundColor,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: 20),
        children: [
          // Section 1: Game Settings
          _buildSectionHeader('GAME PREFERENCES'),
          _buildGroup(
            backgroundColor: groupColor,
            dividerColor: dividerColor,
            isDark: isDark,
            children: [
              _buildSwitchTile(
                title: 'Sound Effects',
                icon: Icons.volume_up_rounded,
                iconColor: const Color(0xFFFF4500),
                value: settingsProvider.soundEnabled,
                onChanged: (value) async {
                  await _hapticService?.light();
                  await settingsProvider.toggleSound();
                },
                isDark: isDark,
              ),
              _buildSwitchTile(
                title: 'Haptic Feedback',
                icon: Icons.vibration_rounded,
                iconColor: Colors.orange,
                value: settingsProvider.vibrationEnabled,
                onChanged: (value) async {
                  await _hapticService?.light();
                  await settingsProvider.toggleVibration();
                },
                isDark: isDark,
              ),
            ],
          ),

          const SizedBox(height: 24),

          // Section 2: Appearance
          _buildSectionHeader('APPEARANCE'),
          _buildGroup(
            backgroundColor: groupColor,
            dividerColor: dividerColor,
            isDark: isDark,
            children: [
              _buildNavigationTile(
                title: 'Theme',
                icon: Icons.palette_rounded,
                iconColor: const Color(0xFFFF8C00),
                value:
                    settingsProvider.themeMode.substring(0, 1).toUpperCase() +
                    settingsProvider.themeMode.substring(1),
                onTap: () {
                  // Cycle or show dialog. For simplicity, let's just cycle or use a simple sheet.
                  // Since user wanted iOS style, let's use a simple dialog for now or cycle.
                  if (settingsProvider.themeMode == 'system') {
                    settingsProvider.setThemeMode('light');
                  } else if (settingsProvider.themeMode == 'light') {
                    settingsProvider.setThemeMode('dark');
                  } else {
                    settingsProvider.setThemeMode('system');
                  }
                  _hapticService?.light();
                },
                isDark: isDark,
              ),
            ],
          ),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Text(
              'Tap to cycle: System -> Light -> Dark',
              style: TextStyle(
                fontSize: 12,
                color: isDark ? Colors.grey[400] : Colors.grey[600],
              ),
            ),
          ),

          const SizedBox(height: 24),

          // Section 3: Data
          _buildSectionHeader('DATA'),
          _buildGroup(
            backgroundColor: groupColor,
            dividerColor: dividerColor,
            isDark: isDark,
            children: [
              _buildActionTile(
                title: 'Reset High Scores',
                icon: Icons.refresh_rounded,
                iconColor: Colors.red, // Danger color
                onTap: () => _showResetScoresDialog(context, scoreProvider),
                isDark: isDark,
                textColor: Colors.red,
              ),
            ],
          ),

          const SizedBox(height: 24),

          // Section 4: Legal
          _buildSectionHeader('ABOUT'),
          _buildGroup(
            backgroundColor: groupColor,
            dividerColor: dividerColor,
            isDark: isDark,
            children: [
              _buildNavigationTile(
                title: 'Privacy Policy',
                icon: Icons.privacy_tip_rounded,
                iconColor: Colors.blueAccent,
                onTap: () => _launchURL('https://sarankar.com/privacy'),
                isDark: isDark,
              ),
              _buildNavigationTile(
                title: 'Rate SnapPlay',
                icon: Icons.star_rate_rounded,
                iconColor: Colors.amber,
                onTap: () => _launchURL(
                  'https://play.google.com/store/apps/details?id=com.snapplay.offline.games',
                ),
                isDark: isDark,
              ),
              _buildNavigationTile(
                title: 'Developer',
                icon: Icons.code_rounded,
                iconColor: Colors.deepPurple,
                value: 'SarankarDevelopers',
                onTap: () => _launchURL('https://sarankar.com'),
                isDark: isDark,
              ),
              _buildNavigationTile(
                title: 'Version',
                icon: Icons.info_rounded,
                iconColor: Colors.grey,
                value: '1.0.3',
                onTap: null, // Read-only
                isDark: isDark,
              ),
            ],
          ),

          const SizedBox(height: 24),

          Center(
            child: Column(
              children: [
                Text(
                  'Designed & Developed with ❤️ by',
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark ? Colors.white24 : Colors.black26,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'SarankarDevelopers',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1,
                    color: isDark ? Colors.white38 : Colors.black38,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 100),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w500,
          color: Colors.grey,
        ),
      ),
    );
  }

  Widget _buildGroup({
    required Color backgroundColor,
    required Color dividerColor,
    required bool isDark,
    required List<Widget> children,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        children: [
          for (int i = 0; i < children.length; i++) ...[
            children[i],
            if (i != children.length - 1)
              Divider(
                height: 1,
                thickness: 0.5,
                indent: 56, // Indent to match icon width + padding
                color: dividerColor,
              ),
          ],
        ],
      ),
    );
  }

  Widget _buildSwitchTile({
    required String title,
    required IconData icon,
    required Color iconColor,
    required bool value,
    required ValueChanged<bool> onChanged,
    required bool isDark,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          _buildIcon(icon, iconColor),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              title,
              style: TextStyle(
                fontSize: 16,
                color: isDark ? Colors.white : Colors.black,
              ),
            ),
          ),
          Switch.adaptive(
            // iOS style switch
            value: value,
            onChanged: onChanged,
            activeColor: const Color(0xFF34C759), // iOS Green
          ),
        ],
      ),
    );
  }

  Widget _buildNavigationTile({
    required String title,
    required IconData icon,
    required Color iconColor,
    String? value,
    required VoidCallback? onTap,
    required bool isDark,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10), // For ripple effect
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            _buildIcon(icon, iconColor),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  fontSize: 16,
                  color: isDark ? Colors.white : Colors.black,
                ),
              ),
            ),
            if (value != null)
              Text(
                value,
                style: TextStyle(fontSize: 16, color: Colors.grey[600]),
              ),
            if (onTap != null) ...[
              const SizedBox(width: 8),
              Icon(
                Icons.arrow_forward_ios_rounded,
                size: 16,
                color: Colors.grey[400],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildActionTile({
    required String title,
    required IconData icon,
    required Color iconColor,
    required VoidCallback onTap,
    required bool isDark,
    Color? textColor,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            _buildIcon(icon, iconColor),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  fontSize: 16,
                  color: textColor ?? (isDark ? Colors.white : Colors.black),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildIcon(IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Icon(icon, color: Colors.white, size: 18),
    );
  }

  void _showResetScoresDialog(
    BuildContext context,
    ScoreProvider scoreProvider,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reset High Scores'),
        content: const Text(
          'Are you sure you want to reset all high scores? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              await scoreProvider.resetAllScores();
              if (context.mounted) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('All high scores have been reset'),
                  ),
                );
              }
            },
            child: const Text('Reset', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
