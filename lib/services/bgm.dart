import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';

import 'player_profile.dart';

/// 🎵 BGMの再生を1か所にまとめたサービス。
///
/// これまで各画面が `AudioPlayer` を自前で持ち、
/// `setAsset(PlayerProfile.selectedBgm)` と**素のファイル名**を渡していた。
/// 実際のアセットキーは `assets/audio/<ファイル名>` なので、
/// setAsset は常に例外になり、`catch (_) {}` に飲まれて
/// **どのプラットフォームでもBGMが一切鳴っていなかった**。
///
/// ここで必ず [assetKey] を通すことで、Android・Webの両方で鳴るようにする。
/// （just_audio は Web も対応しているので `kIsWeb` で止める必要はない。
///  ただしブラウザは自動再生を制限するため、ユーザー操作より前に鳴らすと
///  失敗しうる。その場合も例外を握って静かに諦める。）
class Bgm {
  Bgm._();
  static final Bgm instance = Bgm._();

  final AudioPlayer _player = AudioPlayer();

  /// いま鳴らしているアセットキー（同じ曲の二重再生を防ぐ）。
  String? _current;

  /// SharedPreferences には素のファイル名が入っているので、アセットキーに直す。
  static String assetKey(String fileName) =>
      fileName.startsWith('assets/') ? fileName : 'assets/audio/$fileName';

  /// ゲーム中のBGM（プレイヤーが選んだ曲）をループ再生する。
  Future<void> playGame() => _play(assetKey(PlayerProfile.instance.selectedBgm));

  /// 結果画面のBGM。選ばれていた `selectedResultBgm` はどこからも再生されて
  /// いなかったため、ここで使う。
  Future<void> playResult() =>
      _play(assetKey(PlayerProfile.instance.selectedResultBgm));

  Future<void> _play(String key, {double volume = 0.35}) async {
    if (_current == key && _player.playing) return;
    try {
      await _player.stop();
      await _player.setAsset(key);
      await _player.setLoopMode(LoopMode.one);
      await _player.setVolume(volume);
      _current = key;
      await _player.play();
    } catch (e) {
      // Webの自動再生ブロックや、曲ファイルが無い場合。無音で続行する。
      _current = null;
      debugPrint('BGM play failed ($key): $e');
    }
  }

  /// 画面を離れるときに止める。プレイヤー自体は使い回すので dispose しない。
  Future<void> stop() async {
    _current = null;
    try {
      await _player.stop();
    } catch (_) {}
  }

  /// 曲を選び直したときに、鳴っている曲を即座に差し替える。
  Future<void> restartGameBgm() async {
    _current = null;
    await playGame();
  }
}
