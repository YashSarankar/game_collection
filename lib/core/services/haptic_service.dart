import 'package:flutter/services.dart';
import 'package:vibration/vibration.dart';
import 'storage_service.dart';

/// Service for managing haptic feedback and vibration
class HapticService {
  static HapticService? _instance;
  final StorageService _storage;
  bool _isVibrationEnabled = true;

  HapticService._(this._storage);

  static Future<HapticService> getInstance() async {
    if (_instance == null) {
      final storage = await StorageService.getInstance();
      _instance = HapticService._(storage);
      await _instance!._initialize();
    }
    return _instance!;
  }

  Future<void> _initialize() async {
    _isVibrationEnabled = await _storage.getVibrationEnabled();
  }

  Future<void> setVibrationEnabled(bool enabled) async {
    _isVibrationEnabled = enabled;
    await _storage.setVibrationEnabled(enabled);
  }

  bool get isEnabled => _isVibrationEnabled;

  // Light haptic feedback (for button taps)
  Future<void> light() async {
    if (!_isVibrationEnabled) return;
    await HapticFeedback.lightImpact();
  }

  // Medium haptic feedback (for selections)
  Future<void> medium() async {
    if (!_isVibrationEnabled) return;
    await HapticFeedback.mediumImpact();
  }

  // Heavy haptic feedback (for important actions)
  Future<void> heavy() async {
    if (!_isVibrationEnabled) return;
    await HapticFeedback.heavyImpact();
  }

  // Selection click (for switches, toggles)
  Future<void> selectionClick() async {
    if (!_isVibrationEnabled) return;
    await HapticFeedback.selectionClick();
  }

  // Custom vibration pattern (for game events)
  Future<void> vibrate({int duration = 100}) async {
    if (!_isVibrationEnabled) return;

    final hasVibrator = await Vibration.hasVibrator();
    if (hasVibrator == true) {
      await Vibration.vibrate(duration: duration);
    }
  }

  // Success pattern
  Future<void> success() async {
    if (!_isVibrationEnabled) return;

    final hasVibrator = await Vibration.hasVibrator();
    if (hasVibrator == true) {
      await Vibration.vibrate(pattern: [0, 100, 50, 100]);
    }
  }

  // Error pattern
  Future<void> error() async {
    if (!_isVibrationEnabled) return;

    final hasVibrator = await Vibration.hasVibrator();
    if (hasVibrator == true) {
      await Vibration.vibrate(pattern: [0, 200, 100, 200]);
    }
  }
}
