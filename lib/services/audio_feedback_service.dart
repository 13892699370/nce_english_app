import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';

import 'storage_service.dart';

/// 本地短促反馈音效服务。
///
/// 只负责播放按钮反馈音，不参与单词复习算法，也不影响 TTS 发音。
class AudioFeedbackService extends ChangeNotifier {
  AudioFeedbackService._();
  static final AudioFeedbackService instance = AudioFeedbackService._();

  static const String _enabledKey = 'sound_effects_enabled';

  final AudioPlayer _player = AudioPlayer();
  bool _enabled = true;
  bool _ready = false;

  bool get enabled => _enabled;

  Future<void> init() async {
    if (_ready) return;
    _enabled = StorageService.instance.boolPref(_enabledKey, defaultValue: true);
    try {
      await _player.setPlayerMode(PlayerMode.lowLatency);
      await _player.setReleaseMode(ReleaseMode.stop);
    } catch (e) {
      debugPrint('AudioFeedbackService init error: $e');
    }
    _ready = true;
  }

  Future<void> setEnabled(bool value) async {
    _enabled = value;
    await StorageService.instance.setBoolPref(_enabledKey, value);
    notifyListeners();
  }

  Future<void> playKnown() => _play('sounds/known.wav');

  Future<void> playUnknown() => _play('sounds/unknown.wav');

  Future<void> _play(String assetPath) async {
    if (!_enabled) return;
    try {
      await init();
      await _player.stop();
      await _player.play(AssetSource(assetPath), volume: 0.65);
    } catch (e) {
      debugPrint('AudioFeedbackService play error: $e');
    }
  }

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }
}
