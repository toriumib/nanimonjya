import 'package:flutter/foundation.dart';
import 'package:flutter_tts/flutter_tts.dart';

/// 名刺の自己紹介などをテキスト読み上げ（TTS）で発声する。
/// 日本語は ja-JP、英語は en-US。端末のTTSが無い/失敗しても無音で落ちるだけにする。
class Speech {
  Speech._();
  static final Speech instance = Speech._();

  final FlutterTts _tts = FlutterTts();
  bool enabled = true;
  bool _configuredJa = false;
  bool? _lastJa;

  Future<void> _configure(bool ja) async {
    if (_lastJa == ja && _configuredJa) return;
    try {
      await _tts.setLanguage(ja ? 'ja-JP' : 'en-US');
      await _tts.setSpeechRate(0.5); // flutter_tts の rate は 0..1。0.5前後が自然
      await _tts.setPitch(1.05); // ほんの少し高めで親しみやすく
      await _tts.setVolume(1.0);
      if (!kIsWeb) {
        // Web では未対応のことがあるためガード
        await _tts.awaitSpeakCompletion(true);
      }
      _configuredJa = true;
      _lastJa = ja;
    } catch (e) {
      debugPrint('TTS configure failed: $e');
    }
  }

  /// 名刺の自己紹介を読み上げる（会社名・名前・肩書）。
  /// [bareName] は敬称なしの苗字（例: 佐藤 / Sato）。[company]/[title] は任意。
  Future<void> introduce(
    String bareName, {
    required bool ja,
    String company = '',
    String title = '',
  }) {
    final String text;
    if (ja) {
      final intro = company.isNotEmpty
          ? '$companyの$bareNameと申します。'
          : '私は$bareNameと申します。';
      text = title.isNotEmpty ? '$intro$titleをしております。' : intro;
    } else {
      final intro = company.isNotEmpty
          ? "Hello, I'm $bareName from $company."
          : "Hello, my name is $bareName.";
      text = title.isNotEmpty ? '$intro I am $title.' : intro;
    }
    return speak(text, ja: ja);
  }

  Future<void> speak(String text, {required bool ja}) async {
    if (!enabled) return;
    try {
      await _configure(ja);
      await _tts.stop();
      await _tts.speak(text);
    } catch (e) {
      debugPrint('TTS speak failed: $e');
    }
  }

  Future<void> stop() async {
    try {
      await _tts.stop();
    } catch (_) {}
  }
}
