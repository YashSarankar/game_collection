# Offline Games - No WiFi Games Collection

A production-ready offline games collection app built with Flutter and Flame.

## Features
- **6 Mini Games**: Snake, Tic Tac Toe, Brick Breaker (Flame), Memory Match, Balloon Pop, Ping Pong (Flame).
- **Offline First**: All games work without internet.
- **Monetization**: Integrated AdMob (Banner, Interstitial, Rewarded) with intelligent frequency capping.
- **Daily Rewards**: Coin system with 24h cooldown.
- **Settings**: Sound, Vibration, and Theme toggles.

## Getting Started

1. **Install Dependencies**
   ```bash
   flutter pub get
   ```

2. **Run the App**
   ```bash
   flutter run
   ```

3. **Build APk**
   ```bash
   flutter build apk --release
   ```

## AdMob Configuration

To enable real ads, update the Ad Unit IDs in `lib/core/services/ad_service.dart`:

```dart
// Replace these with your actual AdMob IDs
String get _bannerAdUnitId => Platform.isAndroid ? 'YOUR_ANDROID_BANNER_ID' : 'YOUR_IOS_BANNER_ID';
String get _interstitialAdUnitId => Platform.isAndroid ? 'YOUR_ANDROID_INTERSTITIAL_ID' : 'YOUR_IOS_INTERSTITIAL_ID';
String get _rewardedAdUnitId => Platform.isAndroid ? 'YOUR_ANDROID_REWARDED_ID' : 'YOUR_IOS_REWARDED_ID';
```

Also verify `android/app/src/main/AndroidManifest.xml` (or `ios/Runner/Info.plist`) has the correct App ID configuration as per AdMob documentation.

## Project Structure

- `lib/core`: Constants, Models, Providers, Services.
- `lib/games`: Modular game implementations.
- `lib/ui`: Screens and shared widgets.
- `lib/main.dart`: Entry point.

## Tech Stack
- Flutter 3.x
- Flame Engine 1.18.0
- Provider for State Management
- Shared Preferences for Local Storage
