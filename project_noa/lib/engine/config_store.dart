/// SPEC 3.5 — コンフィグ。shared_preferences に持つ。
library;

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AdvConfig {
  /// 1文字あたりのミリ秒。小さいほど速い。0 は「即時表示」。
  final int charMs;

  /// オートで、読み終わってから次へ行くまでのミリ秒。
  final int autoWaitMs;

  final double bgmVolume;
  final double seVolume;
  final double voiceVolume;

  /// 既読だけスキップする（未読は飛ばさない）。
  final bool skipReadOnly;

  /// 画面揺れを弱める（アクセシビリティ）。
  final bool reduceShake;

  const AdvConfig({
    this.charMs = 28,
    this.autoWaitMs = 1200,
    this.bgmVolume = 0.6,
    this.seVolume = 0.8,
    this.voiceVolume = 1.0,
    this.skipReadOnly = true,
    this.reduceShake = false,
  });

  AdvConfig copyWith({
    int? charMs,
    int? autoWaitMs,
    double? bgmVolume,
    double? seVolume,
    double? voiceVolume,
    bool? skipReadOnly,
    bool? reduceShake,
  }) =>
      AdvConfig(
        charMs: charMs ?? this.charMs,
        autoWaitMs: autoWaitMs ?? this.autoWaitMs,
        bgmVolume: bgmVolume ?? this.bgmVolume,
        seVolume: seVolume ?? this.seVolume,
        voiceVolume: voiceVolume ?? this.voiceVolume,
        skipReadOnly: skipReadOnly ?? this.skipReadOnly,
        reduceShake: reduceShake ?? this.reduceShake,
      );
}

/// 設定の読み書き。変更のたびに保存する（「設定したのに戻る」を防ぐ）。
class ConfigStore extends ChangeNotifier {
  ConfigStore._();
  static final ConfigStore instance = ConfigStore._();

  AdvConfig _config = const AdvConfig();
  AdvConfig get config => _config;

  bool _loaded = false;

  Future<void> load() async {
    if (_loaded) return;
    _loaded = true;
    final p = await SharedPreferences.getInstance();
    _config = AdvConfig(
      charMs: p.getInt('cfg.charMs') ?? 28,
      autoWaitMs: p.getInt('cfg.autoWaitMs') ?? 1200,
      bgmVolume: p.getDouble('cfg.bgm') ?? 0.6,
      seVolume: p.getDouble('cfg.se') ?? 0.8,
      voiceVolume: p.getDouble('cfg.voice') ?? 1.0,
      skipReadOnly: p.getBool('cfg.skipReadOnly') ?? true,
      reduceShake: p.getBool('cfg.reduceShake') ?? false,
    );
    notifyListeners();
  }

  Future<void> update(AdvConfig next) async {
    _config = next;
    notifyListeners();
    final p = await SharedPreferences.getInstance();
    await p.setInt('cfg.charMs', next.charMs);
    await p.setInt('cfg.autoWaitMs', next.autoWaitMs);
    await p.setDouble('cfg.bgm', next.bgmVolume);
    await p.setDouble('cfg.se', next.seVolume);
    await p.setDouble('cfg.voice', next.voiceVolume);
    await p.setBool('cfg.skipReadOnly', next.skipReadOnly);
    await p.setBool('cfg.reduceShake', next.reduceShake);
  }
}
