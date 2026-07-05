import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:just_audio/just_audio.dart';

/// 効果音の再生。just_audio を使い、失敗時は触覚フィードバックにフォールバック。
class Sfx {
  Sfx._();
  static final Sfx instance = Sfx._();

  Future<void> _play(String asset, {double volume = 1.0}) async {
    try {
      final player = AudioPlayer();
      await player.setVolume(volume);
      await player.setAsset('assets/audio/$asset');
      await player.play();
      // 再生完了後に解放
      player.playerStateStream.listen((state) {
        if (state.processingState == ProcessingState.completed) {
          player.dispose();
        }
      });
    } catch (e) {
      debugPrint('SFX play failed ($asset): $e');
    }
  }

  Future<void> victory() async {
    HapticFeedback.mediumImpact();
    await _play('victory.wav');
  }

  Future<void> coin() async {
    HapticFeedback.lightImpact();
    await _play('coin.wav', volume: 0.9);
  }

  Future<void> pop() async {
    await _play('pop.wav', volume: 0.7);
  }
}
