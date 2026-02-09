import 'package:audioplayers/audioplayers.dart';
import 'storage_service.dart';

/// Service for managing sound effects
class SoundService {
  static SoundService? _instance;
  final StorageService _storage;
  final AudioPlayer _dicePlayer = AudioPlayer();
  final AudioPlayer _movePlayer = AudioPlayer();
  final AudioPlayer _shootPlayer = AudioPlayer(); // Dedicated for rapid-fire shooting sounds
  bool _isSoundEnabled = true;

  SoundService._(this._storage);

  static Future<SoundService> getInstance() async {
    if (_instance == null) {
      final storage = await StorageService.getInstance();
      _instance = SoundService._(storage);
      await _instance!._initialize();
    }
    return _instance!;
  }

  Future<void> _initialize() async {
    _isSoundEnabled = await _storage.getSoundEnabled();
    await _dicePlayer.setReleaseMode(ReleaseMode.stop);
    await _movePlayer.setReleaseMode(ReleaseMode.stop);
    await _shootPlayer.setReleaseMode(ReleaseMode.stop);
  }

  Future<void> setSoundEnabled(bool enabled) async {
    _isSoundEnabled = enabled;
    await _storage.setSoundEnabled(enabled);
  }

  bool get isEnabled => _isSoundEnabled;

  // Play sound effect (general - uses dice player)
  Future<void> playSound(String soundPath) async {
    if (!_isSoundEnabled) return;

    try {
      await _dicePlayer.stop();
      await _dicePlayer.play(AssetSource(soundPath));
    } catch (e) {
      // Silently fail if sound file doesn't exist
    }
  }

  // Play movement sound (non-blocking, uses separate player)
  void playMoveSound(String soundPath) {
    if (!_isSoundEnabled) return;

    try {
      _movePlayer.stop();
      _movePlayer.play(AssetSource(soundPath));
    } catch (e) {
      // Silently fail if sound file doesn't exist
    }
  }

  // Play shooting sound (for rapid-fire weapons, restarts from beginning each time)
  void playShootSound(String soundPath) {
    if (!_isSoundEnabled) return;

    try {
      _shootPlayer.stop();
      _shootPlayer.play(AssetSource(soundPath));
    } catch (e) {
      // Silently fail if sound file doesn't exist
    }
  }

  // Common sound effects
  Future<void> playButtonClick() async {
    // await playSound('sounds/button_click.mp3');
    // For now, we'll skip actual sound files to keep the app lightweight
  }

  Future<void> playGameStart() async {
    // await playSound('sounds/game_start.mp3');
  }

  Future<void> playGameOver() async {
    // await playSound('sounds/game_over.mp3');
  }

  Future<void> playSuccess() async {
    // await playSound('sounds/success.mp3');
  }

  Future<void> playError() async {
    // await playSound('sounds/error.mp3');
  }

  Future<void> playPoint() async {
    // await playSound('sounds/point.mp3');
  }

  Future<void> playPop() async {
    // await playSound('sounds/pop.mp3');
  }

  Future<void> playBounce() async {
    // await playSound('sounds/bounce.mp3');
  }

  void dispose() {
    _dicePlayer.dispose();
    _movePlayer.dispose();
    _shootPlayer.dispose();
  }
}
