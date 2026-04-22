import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:http/http.dart' as http;

class UpdateService {
  static const String _updateConfigUrl =
      'https://gist.githubusercontent.com/YashSarankar/113b1cea294a0e0c0d0674cd26189329/raw/gistfile1.txt';

  static Future<Map<String, dynamic>?> checkUpdate() async {
    try {
      // 1. Get current app version info
      final PackageInfo packageInfo = await PackageInfo.fromPlatform();
      final int currentBuildNumber = int.parse(packageInfo.buildNumber);

      // 2. Fetch latest version info from remote URL
      // NOTE: User needs to replace _updateConfigUrl with a real URL (GitHub Gist, etc.)
      final response = await http
          .get(Uri.parse(_updateConfigUrl))
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);

        final int minBuildNumber = data['min_build_number'] ?? 0;
        final String latestVersionName = data['latest_version'] ?? '1.0.0';
        final String updateUrl =
            data['update_url'] ??
            'https://play.google.com/store/apps/details?id=com.snapplay.offline.games';
        final bool forceUpdate = data['force_update'] ?? false;

        // 3. Compare versions: If current build is lower than min required, force update.
        if (currentBuildNumber < minBuildNumber) {
          return {
            'shouldUpdate': true,
            'forceUpdate': true, // Always force update if version is below minimum
            'latestVersion': latestVersionName,
            'updateUrl': updateUrl,
          };
        }
      }
    } catch (e) {
      debugPrint('Error checking for updates: $e');
    }
    return null;
  }
}
