import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:just_audio/just_audio.dart';

/// 効果音の再生。
///
/// ジューシーさのポイント:
/// - 起動時にプリロードし、各音を小さなプールで持つ → タップからの遅延ゼロ・連打も鳴り重なる
/// - 正解はコンボで音程が上がる（連続正解が気持ちいい）
/// - 勝利/報酬は複数音＋触覚を重ねて「ドン！」と盛り上げる
/// - 端末がミュートでも触覚フィードバックで手応えを返す
class Sfx {
  Sfx._();
  static final Sfx instance = Sfx._();

  static const int _poolSize = 3; // 同じ音の同時重ね数
  final Map<String, List<AudioPlayer>> _pool = {};
  final Map<String, int> _cursor = {};
  bool _ready = false;

  // コンボ（連続正解）状態
  int _combo = 0;
  DateTime _lastCorrect = DateTime.fromMillisecondsSinceEpoch(0);

  static const List<String> _assets = [
    'correct.wav',
    'wrong.wav',
    'coin.wav',
    'pop.wav',
    'fanfare.wav',
    'victory.wav',
  ];

  /// アプリ起動時に呼ぶ（main）。全SFXをメモリに載せてワンタップ即発音にする。
  Future<void> preload() async {
    if (_ready) return;
    _ready = true;
    for (final a in _assets) {
      final players = <AudioPlayer>[];
      for (var i = 0; i < _poolSize; i++) {
        try {
          final p = AudioPlayer();
          await p.setAsset('assets/audio/$a');
          players.add(p);
        } catch (e) {
          debugPrint('SFX preload failed ($a): $e');
        }
      }
      if (players.isNotEmpty) {
        _pool[a] = players;
        _cursor[a] = 0;
      }
    }
  }

  /// プールから次のプレイヤーを取り出して先頭から鳴らす。
  Future<void> _play(String asset, {double volume = 1.0, double speed = 1.0}) async {
    try {
      if (!_ready) await preload();
      final players = _pool[asset];
      if (players == null || players.isEmpty) {
        // フォールバック: 使い捨て再生
        final p = AudioPlayer();
        await p.setAsset('assets/audio/$asset');
        await p.setVolume(volume);
        await p.play();
        p.playerStateStream.listen((s) {
          if (s.processingState == ProcessingState.completed) p.dispose();
        });
        return;
      }
      final idx = _cursor[asset]!;
      _cursor[asset] = (idx + 1) % players.length;
      final player = players[idx];
      await player.setVolume(volume);
      try {
        await player.setSpeed(speed);
      } catch (_) {}
      await player.seek(Duration.zero);
      await player.play();
    } catch (e) {
      debugPrint('SFX play failed ($asset): $e');
    }
  }

  Future<void> pop() => _play('pop.wav', volume: 0.7);

  Future<void> coin() async {
    HapticFeedback.lightImpact();
    await _play('coin.wav', volume: 0.95);
  }

  /// 正解。連続正解でピッチが少しずつ上がっていく（コンボ演出）。
  Future<void> correct() async {
    final now = DateTime.now();
    // 3秒以内の連続正解はコンボ継続
    if (now.difference(_lastCorrect).inMilliseconds < 3000) {
      _combo = (_combo + 1).clamp(0, 6);
    } else {
      _combo = 0;
    }
    _lastCorrect = now;
    // コンボが乗るほど触覚も強めに
    if (_combo >= 4) {
      HapticFeedback.heavyImpact();
    } else if (_combo >= 2) {
      HapticFeedback.mediumImpact();
    } else {
      HapticFeedback.lightImpact();
    }
    final speed = 1.0 + _combo * 0.06; // 1.00, 1.06, 1.12 ... と上昇
    await _play('correct.wav', volume: 0.95, speed: speed);
    // 大きく連鎖したらキラッと追い足し
    if (_combo >= 5) {
      unawaited(_play('coin.wav', volume: 0.6, speed: 1.3));
    }
  }

  /// おてつき（ブッブー）。コンボはリセット。
  Future<void> wrong() async {
    _combo = 0;
    HapticFeedback.heavyImpact();
    await _play('wrong.wav', volume: 0.85);
  }

  /// 大事なボタン・アンロック成功・報酬ゲット用のファンファーレ。
  Future<void> fanfare() async {
    HapticFeedback.heavyImpact();
    await _play('fanfare.wav', volume: 0.95);
    // コインのキラキラを薄く重ねて厚みを出す
    unawaited(_play('coin.wav', volume: 0.45, speed: 1.15));
  }

  /// 勝利。ファンファーレ＋勝利音＋段階的な触覚で「ドン！」と盛り上げる。
  Future<void> victory() async {
    _combo = 0;
    HapticFeedback.heavyImpact();
    await _play('victory.wav', volume: 1.0);
    unawaited(_play('fanfare.wav', volume: 0.5));
    // 余韻の触覚
    Future.delayed(const Duration(milliseconds: 140), HapticFeedback.mediumImpact);
    Future.delayed(const Duration(milliseconds: 300), HapticFeedback.lightImpact);
  }

  /// 報酬ゲット（コイン＋ファンファーレを重ねた豪華版）。
  Future<void> reward() async {
    HapticFeedback.heavyImpact();
    await _play('coin.wav', volume: 0.95);
    unawaited(_play('fanfare.wav', volume: 0.7));
  }
}
