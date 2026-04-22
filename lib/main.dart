import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import 'core/services/storage_service.dart';
import 'core/services/haptic_service.dart';
import 'core/services/sound_service.dart';
import 'core/services/update_service.dart';
import 'core/services/ad_service.dart';
import 'core/services/purchase_service.dart';
import 'core/providers/settings_provider.dart';
import 'core/providers/score_provider.dart';

import 'ui/screens/splash_screen.dart';
import 'ui/screens/update_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Set preferred orientations and system UI style
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(statusBarColor: Colors.transparent),
  );

  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Initialize Services
  final storageService = await StorageService.getInstance();
  await storageService.incrementSessionCount();
  
  final hapticService = await HapticService.getInstance();
  final soundService = await SoundService.getInstance();
  final purchaseService = await PurchaseService.getInstance();
  await AdService.getInstance();
  
  // 3. Check for Mandatory Updates
  final updateInfo = await UpdateService.checkUpdate();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) =>
              SettingsProvider(storageService, hapticService, soundService),
        ),
        ChangeNotifierProvider(create: (_) => ScoreProvider(storageService)),
        ChangeNotifierProvider.value(value: purchaseService),
      ],
      child: MyApp(updateInfo: updateInfo),
    ),
  );
}

class MyApp extends StatelessWidget {
  final Map<String, dynamic>? updateInfo;
  
  const MyApp({super.key, this.updateInfo});

  @override
  Widget build(BuildContext context) {
    // If a mandatory update is required, show the Update Screen immediately
    if (updateInfo != null && updateInfo!['shouldUpdate'] == true) {
      return MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: ThemeData(useMaterial3: true),
        home: UpdateScreen(
          latestVersion: updateInfo!['latestVersion'],
          updateUrl: updateInfo!['updateUrl'],
        ),
      );
    }

    return Consumer<SettingsProvider>(
      builder: (context, settings, child) {
        // Wait for settings to load before building the app
        if (!settings.isLoaded) {
          // Simply return a placeholder until settings are loaded
          // The Splash Screen will handle the actual visual loading
          return MaterialApp(
            debugShowCheckedModeBanner: false,
            home: const Scaffold(body: SizedBox.shrink()),
          );
        }

        return MaterialApp(
          title: 'SnapPlay: Offline Mini Games',
          debugShowCheckedModeBanner: false,
          themeMode: _getThemeMode(settings.themeMode),
          theme: ThemeData(
            useMaterial3: true,
            brightness: Brightness.light,
            colorScheme: ColorScheme.fromSeed(
              seedColor: const Color(0xFFFF8C00),
              brightness: Brightness.light,
              surface: const Color(0xFFF2F2F7), // iOS Light Background
            ),
            scaffoldBackgroundColor: const Color(0xFFF2F2F7),
            appBarTheme: const AppBarTheme(
              elevation: 0,
              centerTitle: true,
              backgroundColor: Colors.transparent,
              foregroundColor: Colors.black,
            ),
            fontFamily: 'System', // Use system font (San Francisco on iOS)
          ),
          darkTheme: ThemeData(
            useMaterial3: true,
            brightness: Brightness.dark,
            colorScheme: ColorScheme.fromSeed(
              seedColor: const Color(0xFFFF8C00),
              brightness: Brightness.dark,
              surface: const Color(0xFF000000), // iOS Dark Background
            ),
            scaffoldBackgroundColor: const Color(0xFF000000),
            appBarTheme: const AppBarTheme(
              elevation: 0,
              centerTitle: true,
              backgroundColor: Colors.transparent,
              foregroundColor: Colors.white,
            ),
            fontFamily: 'System',
            dividerColor: const Color(0xFF38383A),
          ),
          home: const SplashScreen(),
        );
      },
    );
  }

  ThemeMode _getThemeMode(String mode) {
    switch (mode) {
      case 'light':
        return ThemeMode.light;
      case 'dark':
        return ThemeMode.dark;
      default:
        return ThemeMode.system;
    }
  }
}
