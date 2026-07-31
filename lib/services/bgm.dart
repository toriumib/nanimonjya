import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:just_audio/just_audio.dart';

import '../models/bgm_catalog.dart';
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

  /// ホームBGMの再開に使うルート監視。
  ///
  /// ホーム（HomeShell）はタブなので、ゲーム画面から戻ってきても
  /// initState は再実行されない。そのため「別の画面が上に乗った／戻ってきた」を
  /// これで拾って、ホームBGMを止める・再開する。
  /// MaterialApp の navigatorObservers に登録すること。
  static final RouteObserver<ModalRoute<void>> routeObserver =
      RouteObserver<ModalRoute<void>>();

  final AudioPlayer _player = AudioPlayer();

  /// 直列化用のチェーン。
  ///
  /// playHome() は「タブを押すたび」「initState」「他画面から戻ったとき」の
  /// 3経路から await なしで呼ばれる。just_audio の setAsset は内部で
  /// プラットフォーム側のプレイヤーを初期化するため、同時に走ると
  /// `Platform player ... already exists` / `abort, Loading interrupted` で
  /// 落ちる（Crashlyticsのクラッシュ上位2件がこれ）。
  /// すべての操作をこのチェーンに並べて、必ず1つずつ実行する。
  Future<void> _chain = Future<void>.value();

  Future<void> _serialize(Future<void> Function() action) {
    final next = _chain.then((_) => action()).catchError((Object e) {
      debugPrint('BGM op failed: $e');
    });
    _chain = next;
    return next;
  }

  /// いま鳴らしているアセットキー（同じ曲の二重再生を防ぐ）。
  String? _current;

  /// 自動再生をブラウザに止められたか。
  ///
  /// Webは「ユーザーが1度も操作していない状態」での再生を拒否する。
  /// 起動直後の playHome() はこれに当たって無音になるため、
  /// 最初のタップで鳴らし直せるように覚えておく。
  bool _blocked = false;

  /// 何か操作があったときに呼ぶ。自動再生を止められていたら鳴らし直す。
  Future<void> retryIfBlocked() async {
    if (!_blocked) return;
    _blocked = false;
    switch (_mode) {
      case _BgmMode.home:
        await playHome();
        break;
      case _BgmMode.game:
        await playGame();
        break;
      case _BgmMode.result:
        await playResult();
        break;
      case _BgmMode.none:
        break;
    }
  }

  /// いま誰のためにに鳴らしているか。
  ///
  /// `pushReplacement`（ゲーム画面→リザルト画面）では、
  /// **新しい画面の initState が先に走り、古い画面の dispose が後から走る**。
  /// そのため古い画面が無条件に stop() すると、リザルト画面が鳴らし始めた曲を
  /// 直後に止めてしまう。用途を持たせて「自分が鳴らした曲だけ止める」ようにする。
  _BgmMode _mode = _BgmMode.none;

  /// SharedPreferences には素のファイル名が入っているので、アセットキーに直す。
  static String assetKey(String fileName) =>
      fileName.startsWith('assets/') ? fileName : 'assets/audio/$fileName';

  /// 🏠 ホーム（タブシェル）で流すBGM。
  ///
  /// ゲーム画面へ移ると [playGame] に上書きされ、戻ってくると
  /// [routeObserver] 経由でまたこれが呼ばれる。
  /// ホームは操作していない時間も長いので、音量は控えめにする。
  Future<void> playHome() {
    _mode = _BgmMode.home;
    // 🏠 ホームの曲はマイページで選べる（3場面それぞれ設定できる）
    return _play(assetKey(PlayerProfile.instance.selectedHomeBgm),
        volume: 0.22);
  }

  /// ホームBGMだけを止める（ゲーム画面が先に鳴らし始めていたら何もしない）。
  Future<void> stopHome() async {
    if (_mode != _BgmMode.home) return;
    await stop();
  }

  /// ゲーム中のBGM（プレイヤーが選んだ曲）をループ再生する。
  Future<void> playGame() {
    _mode = _BgmMode.game;
    return _play(assetKey(PlayerProfile.instance.selectedBgm));
  }

  /// 結果画面のBGM。選ばれていた `selectedResultBgm` はどこからも再生されて
  /// いなかったため、ここで使う。
  Future<void> playResult() {
    _mode = _BgmMode.result;
    return _play(assetKey(PlayerProfile.instance.selectedResultBgm));
  }

  Future<void> _play(String key, {double volume = 0.35}) {
    return _serialize(() async {
      // 🔇 マイページでBGMを切っている人には何も鳴らさない。
      // （効果音は別設定なので、ここでは止めない）
      if (!PlayerProfile.instance.bgmEnabled) {
        _current = null;
        try {
          await _player.stop();
        } catch (_) {}
        return;
      }
      if (_current == key && _player.playing) return;
      try {
        await _player.stop();
        await _player.setAsset(key);
        await _player.setLoopMode(LoopMode.one);
        await _player.setVolume(volume);
        _current = key;
        await _player.play();
      } catch (e) {
        // Webの自動再生ブロックや、曲ファイルが無い場合。無音で続行し、
        // 最初のタップで鳴らし直せるよう印をつける。
        _current = null;
        _blocked = true;
        debugPrint('BGM play failed ($key): $e');
      }
    });
  }

  /// ゲーム画面を離れるときに止める。
  ///
  /// リザルト画面がすでに鳴らし始めていたら**止めない**（上記の順序問題への対策）。
  Future<void> stopGame() async {
    if (_mode != _BgmMode.game) return;
    await stop();
  }

  /// 無条件に止める。プレイヤー自体は使い回すので dispose しない。
  Future<void> stop() {
    return _serialize(() async {
      _current = null;
      _mode = _BgmMode.none;
      try {
        await _player.stop();
      } catch (_) {}
    });
  }

  /// 曲を選び直したときに、鳴っている曲を即座に差し替える。
  Future<void> restartGameBgm() async {
    _current = null;
    await playGame();
  }
}

/// BGMをいまどの用途で鳴らしているか。
enum _BgmMode { none, home, game, result }
