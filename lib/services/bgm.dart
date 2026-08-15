import 'dart:math';

import 'package:firebase_crashlytics/firebase_crashlytics.dart';
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

  /// ⚠️ **このチェーンの中から、またチェーンに積む操作を呼んではいけない。**
  ///    内側は「外側が終わってから動く」順番待ちに入るのに、
  ///    外側は内側の完了を待つので、両者が永久に待ち合う（デッドロック）。
  ///    実際に `restartCurrent()` が `_play()`（＝チェーンに積む）を
  ///    呼んでいて、**曲を選び直すとBGMが二度と鳴らなくなっていた**。
  ///    チェーンの中では、必ず素の [_playCore] / [_stopCore] を呼ぶこと。
  Future<void> _serialize(Future<void> Function() action) {
    final next = _chain.then((_) => action()).catchError((Object e, StackTrace s) {
      debugPrint('BGM op failed: $e');
      if (!kIsWeb) {
        try { FirebaseCrashlytics.instance.recordError(e, s); } catch (_) {}
      }
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
    return _play(assetKey(homeAsset()), volume: 0.22);
  }

  /// いまホームで鳴らすべき曲。
  ///
  /// 🎲 設定が [kHomeBgmRandom] のときは [kHomeRandomPool] から引く。
  /// 毎回おなじ曲だと起動のたびに同じ体験になるので、既定はこちら。
  ///
  /// ⚠️ **同じ曲を引き直したときに鳴らし直さない。**
  ///    [_play] は同じアセットなら何もしないので、タブを行き来しても
  ///    曲が頭から鳴り直すことはない。逆に、別の曲を引くと切り替わる。
  ///    なので**曲を選ぶのは「ホームBGMが止まっているとき」だけ**にする。
  ///    そうしないとタブを押すたびに曲がガチャガチャ変わる。
  String homeAsset() {
    final chosen = PlayerProfile.instance.selectedHomeBgm;
    if (chosen != kHomeBgmRandom) return chosen;
    // すでにプールの曲が鳴っているなら、それを続ける
    final playing = _current;
    if (playing != null) {
      for (final a in kHomeRandomPool) {
        if (playing == assetKey(a)) return a;
      }
    }
    _homePick ??= kHomeRandomPool[_rng.nextInt(kHomeRandomPool.length)];
    return _homePick!;
  }

  /// この起動で引いたホームの曲。アプリを開き直すと引き直す。
  String? _homePick;
  final Random _rng = Random();

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
    return _play(assetKey(resultAsset()));
  }

  /// 🏆 勝ったときに鳴らす曲。
  ///
  /// 設定が [kResultBgmRandom] のときは [kVictoryRandomPool] から引く。
  /// **設定で1曲を選んだら、その曲だけが鳴る。**
  ///
  /// ⚠️ ホーム（[homeAsset]）とちがって、**毎回引き直してよい**。
  ///    リザルトは試合が終わるたびに1回だけ鳴る場面なので、
  ///    同じ曲が続くより、毎回変わるほうが嬉しい。
  String resultAsset() {
    final chosen = PlayerProfile.instance.selectedResultBgm;
    if (chosen != kResultBgmRandom) return chosen;
    return kVictoryRandomPool[_rng.nextInt(kVictoryRandomPool.length)];
  }

  Future<void> _play(String key, {double volume = 0.35}) =>
      _serialize(() => _playCore(key, volume: volume));

  /// 実際に鳴らす処理。**チェーンの中からだけ呼ぶこと**（[_serialize] 参照）。
  Future<void> _playCore(String key, {double volume = 0.35}) async {
    if (!PlayerProfile.instance.bgmEnabled) {
      _current = null;
      await _stopCore();
      return;
    }
    if (_current == key && _player.playing) {
      // 同じ曲でも場面によって音量がちがう（ホームは控えめ）。
      // 鳴らし直さずに音量だけ合わせる。
      if (_currentVolume != volume) {
        try {
          await _player.setVolume(volume);
          _currentVolume = volume;
        } catch (_) {}
      }
      return;
    }
    try {
      // まず明示的に止めてから次の曲を読み込む。
      // setAsset だけだと Web Audio API が前のソースを解放しきらず
      // 新しい decode に失敗する（結果: 無音）。
      await _player.stop();
      await _player.setAsset(key);
      await _player.setLoopMode(LoopMode.one);
      await _player.setVolume(volume);
      await _player.play();
      _current = key;
      _currentVolume = volume;
      _blocked = false;
    } catch (e) {
      _current = null;
      _blocked = true;
      await _stopCore();
      debugPrint('BGM ERROR: $key — $e');
    }
  }

  /// いま設定している音量（同じ曲を鳴らし直さずに合わせるために覚えておく）。
  double _currentVolume = -1;

  Future<void> _stopCore() async {
    try {
      await _player.stop();
    } catch (_) {}
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
      await _stopCore();
    });
  }

  /// 曲を選び直したときに、鳴っている曲を即座に差し替える。
  ///
  /// `_current` の消去もチェーンの中でやる。外でやると、まだ動いている
  /// 前の操作が終わりぎわに `_current` を書き戻して、同じ曲だと判定されて
  /// 差し替えが素通りすることがある。
  Future<void> restartGameBgm() {
    return _serialize(() async {
      _current = null;
      _mode = _BgmMode.game;
      await _stopCore();
      await _playCore(assetKey(PlayerProfile.instance.selectedBgm));
    });
  }

  /// 🔊 いま鳴らしている場面のBGMを、選び直した曲でかけ直す。
  ///
  /// 即座に前の曲を止めて新しい曲を鳴らす。
  /// `_current = null` + `_player.stop()` を先にやってから
  /// play系に渡すので、`_play`内の「同じ曲ならスキップ」に引っかからない。
  Future<void> restartCurrent() async {
    return _serialize(() async {
      _current = null;
      await _stopCore();
      switch (_mode) {
        case _BgmMode.game:
          await _playCore(assetKey(PlayerProfile.instance.selectedBgm));
        case _BgmMode.result:
          await _playCore(assetKey(resultAsset()));
        case _BgmMode.home:
        case _BgmMode.none:
          await _playCore(assetKey(homeAsset()), volume: 0.22);
      }
    });
  }

  /// ▶️ 試聴。持っていない曲でも鳴らせる（買う前に聴けないと選べないため）。
  ///
  /// 場面の設定（[_mode]）は変えないので、試聴をやめて画面を移れば
  /// もとの曲に戻る。
  Future<void> preview(String fileName) {
    return _serialize(() async {
      try {
        await _player.stop();
        await _player.setAsset(assetKey(fileName));
        await _player.setLoopMode(LoopMode.off);
        await _player.setVolume(0.4);
        _current = null; // 試聴後にかけ直せるよう、鳴っている曲の記録は残さない
        await _player.play();
      } catch (e) {
        debugPrint('BGM preview failed ($fileName): $e');
      }
    });
  }
}

/// BGMをいまどの用途で鳴らしているか。
enum _BgmMode { none, home, game, result }
