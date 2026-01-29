import 'package:flutter/foundation.dart';
import '../services/storage_service.dart';
import '../services/haptic_service.dart';
import '../services/sound_service.dart';

/// Provider for managing app settings
class SettingsProvider extends ChangeNotifier {
  final StorageService _storage;
  final HapticService _haptic;
  final SoundService _sound;

  bool _soundEnabled = true;
  bool _vibrationEnabled = true;
  String _themeMode = 'system'; // 'light', 'dark', 'system'
  bool _isLoaded = false;

  SettingsProvider(this._storage, this._haptic, this._sound) {
    _loadSettings();
  }

  bool get soundEnabled => _soundEnabled;
  bool get vibrationEnabled => _vibrationEnabled;
  String get themeMode => _themeMode;
  bool get isLoaded => _isLoaded;

  Future<void> _loadSettings() async {
    _soundEnabled = await _storage.getSoundEnabled();
    _vibrationEnabled = await _storage.getVibrationEnabled();
    _themeMode = await _storage.getThemeMode();
    _isLoaded = true;
    notifyListeners();
  }

  Future<void> toggleSound() async {
    _soundEnabled = !_soundEnabled;
    await _storage.setSoundEnabled(_soundEnabled);
    await _sound.setSoundEnabled(_soundEnabled);
    notifyListeners();
  }

  Future<void> toggleVibration() async {
    _vibrationEnabled = !_vibrationEnabled;
    await _storage.setVibrationEnabled(_vibrationEnabled);
    await _haptic.setVibrationEnabled(_vibrationEnabled);
    notifyListeners();
  }

  Future<void> setThemeMode(String mode) async {
    _themeMode = mode;
    await _storage.setThemeMode(mode);
    notifyListeners();
  }
}
