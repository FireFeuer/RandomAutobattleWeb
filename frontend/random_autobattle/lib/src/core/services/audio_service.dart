import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';

class AudioService {
  static final AudioService _instance = AudioService._internal();
  factory AudioService() => _instance;
  AudioService._internal();

  final AudioPlayer _player = AudioPlayer();

  bool _isInitialized = false;

  // Публичные геттеры для доступа из других частей приложения
  bool get isPlaying => _player.playing;
  Stream<bool> get playingStream => _player.playingStream;
  // Если позже понадобится — можно добавить и другие:
  // Stream<PlayerState> get playerStateStream => _player.playerStateStream;
  // etc.

  Future<void> init() async {
    if (_isInitialized) return;

    try {
      // Загружаем трек из assets
      await _player.setAsset('assets/music/fruitmaster_music.mp3');

      // Зацикливаем
      await _player.setLoopMode(LoopMode.all);

      // Громкость по умолчанию
      await _player.setVolume(0.4);

      _isInitialized = true;

      debugPrint("Audio initialized (autoplay отключён)");
      // ← убрали play() отсюда
    } catch (e) {
      debugPrint("Audio init error: $e");
    }
  }

  Future<void> setVolume(double volume) async {
    if (!_isInitialized) return;
    try {
      await _player.setVolume(volume.clamp(0.0, 1.0));
    } catch (e) {
      debugPrint("Audio setVolume error: $e");
    }
  }

  void play() {
    if (!_isInitialized) return;
    _player.play();
  }

  void pause() {
    _player.pause();
  }

  void toggle() {
    if (isPlaying) {
      pause();
    } else {
      play();
    }
  }

  Future<void> dispose() async {
    await _player.dispose();
  }
}