import 'package:flutter/foundation.dart';
import 'package:flutter_tts/flutter_tts.dart';

import 'storage_service.dart';

enum WordVoiceAccent {
  british,
  american,
}

/// 单词离线 TTS 服务。
///
/// 使用系统语音包发音，设备缺少对应语音时自动降级并返回友好提示。
class WordTtsService extends ChangeNotifier {
  WordTtsService._();
  static final WordTtsService instance = WordTtsService._();

  static const String _accentKey = 'default_word_voice_accent';

  final FlutterTts _tts = FlutterTts();
  WordVoiceAccent _defaultAccent = WordVoiceAccent.british;
  bool _ready = false;

  WordVoiceAccent get defaultAccent => _defaultAccent;

  Future<void> init() async {
    if (_ready) return;
    final saved = StorageService.instance.stringPref(
      _accentKey,
      defaultValue: 'british',
    );
    _defaultAccent =
        saved == 'american' ? WordVoiceAccent.american : WordVoiceAccent.british;
    try {
      await _tts.setSpeechRate(0.42);
      await _tts.setVolume(1.0);
      await _tts.setPitch(1.0);
      await _tts.awaitSpeakCompletion(false);
    } catch (e) {
      debugPrint('WordTtsService init error: $e');
    }
    _ready = true;
  }

  Future<void> setDefaultAccent(WordVoiceAccent accent) async {
    _defaultAccent = accent;
    await StorageService.instance.setStringPref(
      _accentKey,
      accent == WordVoiceAccent.american ? 'american' : 'british',
    );
    notifyListeners();
  }

  Future<String?> speak(
    String text, {
    WordVoiceAccent? accent,
    bool saveAsDefault = false,
  }) async {
    try {
      await init();
      final selected = accent ?? _defaultAccent;
      if (saveAsDefault) {
        await setDefaultAccent(selected);
      }
      await _tts.stop();
      await _tts.setLanguage(
        selected == WordVoiceAccent.american ? 'en-US' : 'en-GB',
      );
      await _tts.speak(text);
      return null;
    } catch (e) {
      debugPrint('WordTtsService speak error: $e');
      return '当前设备语音包不可用，请检查系统 TTS/语音设置。';
    }
  }

  Future<void> stop() async {
    try {
      await _tts.stop();
    } catch (e) {
      debugPrint('WordTtsService stop error: $e');
    }
  }
}
