import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import 'core/services/storage_service.dart';
import 'core/services/ad_service.dart';
import 'core/services/haptic_service.dart';
import 'core/services/sound_service.dart';
import 'core/providers/settings_provider.dart';
import 'core/providers/score_provider.dart';
import 'core/providers/coins_provider.dart';

import 'ui/screens/splash_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Mobile Ads
  await MobileAds.instance.initialize();

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
  final hapticService = await HapticService.getInstance();
  final soundService = await SoundService.getInstance();

  // Initialize AdService
  await AdService.getInstance();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) =>
              SettingsProvider(storageService, hapticService, soundService),
        ),
        ChangeNotifierProvider(create: (_) => ScoreProvider(storageService)),
        ChangeNotifierProvider(create: (_) => CoinsProvider(storageService)),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
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
          title: 'SnapPlay',
          debugShowCheckedModeBanner: false,
          themeMode: _getThemeMode(settings.themeMode),
          theme: ThemeData(
            useMaterial3: true,
            brightness: Brightness.light,
            colorScheme: ColorScheme.fromSeed(
              seedColor: const Color(0xFFFF8C00),
              brightness: Brightness.light,
              background: const Color(0xFFF2F2F7), // iOS Light Background
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
              background: const Color(0xFF000000), // iOS Dark Background
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
