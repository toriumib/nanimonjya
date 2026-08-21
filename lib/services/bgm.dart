import 'dart:async';
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
  ///
  /// Webは最初のユーザー操作より前の再生を拒否する。[_playCore] が再生を
  /// 拒否されたときもソースはロード済み（[_current] は残る）なので、ここでは
  /// **重い `setAudioSource` を挟まずに `play()` だけを呼ぶ**。するとチェーン
  /// が空なら action はマイクロタスクで走り、ポインター操作のジェスチャー
  /// コンテキストが維持されたまま `audioElement.play()` に届くため、
  /// ブラウザの自動再生が許可される。
  Future<void> retryIfBlocked() async {
    if (!_blocked) return;
    if (_current != null) {
      // ロード済み。ユーザー操作の中で再生だけを再試行する。
      // Webでは play() を await しない（ループ再生中は曲の終了まで返らない）。
      await _serialize(() async {
        try {
          // ⚠️ 自動再生に拒否された直後は `_player.playing` が true のまま残る
          //    （just_audio が再生開始を楽観的に立て、platform の play() が
          //    失敗しても戻さない）。play() は `if (playing) return;` で
          //    即リターンしてしまうので、まず pause() で playing を false に
          //    戻してから play() する。pause() はソースを破棄しない。
          if (_player.playing) {
            await _player.pause();
          }
          unawaited(_player.play().catchError((Object e) {
            _blocked = true;
          }));
          _blocked = false;
        } catch (_) {
          _blocked = true;
        }
      });
      return;
    }
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
    _ensureListening();
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
    _ensureListening();
    _mode = _BgmMode.game;
    return _play(assetKey(PlayerProfile.instance.selectedBgm));
  }

  /// 結果画面のBGM。選ばれていた `selectedResultBgm` はどこからも再生されて
  /// いなかったため、ここで使う。
  Future<void> playResult() {
    _ensureListening();
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

  /// ユーザー設定の音量倍率（0.0〜1.0）。プロフィールのスライダーから変更する。
  static double volumeScale = 1.0;

  // ── プロフィール設定の自動反映 ──
  // 画面が明示的に playHome 等を呼ぶのを待たずに、
  // PlayerProfile の変化（OFF/ON・音量・曲の変更）を検知して即反映する。
  bool _listening = false;
  bool _lastBgmEnabled = true;
  double _lastBgmVolume = 1.0;
  String _lastHomeBgm = kHomeBgmRandom;
  String _lastResultBgm = kResultBgmRandom;

  void _ensureListening() {
    if (_listening) return;
    _listening = true;
    _lastBgmEnabled = PlayerProfile.instance.bgmEnabled;
    _lastBgmVolume = PlayerProfile.instance.bgmVolume;
    _lastHomeBgm = PlayerProfile.instance.selectedHomeBgm;
    _lastResultBgm = PlayerProfile.instance.selectedResultBgm;
    PlayerProfile.instance.addListener(_onProfileChanged);
  }

  void _onProfileChanged() {
    final p = PlayerProfile.instance;
    // 🔇 BGM をオフにされたら、鳴っていたら即止める。
    if (!p.bgmEnabled) {
      _lastBgmEnabled = false;
      if (_mode != _BgmMode.none) stop();
      return;
    }
    if (!_lastBgmEnabled) {
      _lastBgmEnabled = true;
      // オフ→オンに戻されたら、場面に応じた曲を鳴らす。
      restartCurrent();
      return;
    }
    // 🔊 音量が変わったら、鳴っている曲に即反映。
    if (p.bgmVolume != _lastBgmVolume) {
      _lastBgmVolume = p.bgmVolume;
      if (_current != null) {
        _serialize(() => _player.setVolume(_currentVolume * volumeScale));
      }
      return;
    }
    // 🎵 ホーム曲が変わったら、ホーム場面なら再再生する。
    if (_mode == _BgmMode.home && p.selectedHomeBgm != _lastHomeBgm) {
      _lastHomeBgm = p.selectedHomeBgm;
      restartCurrent();
      return;
    }
    // 🏆 結果画面の曲が変わったら、結果場面なら再再生する。
    if (_mode == _BgmMode.result && p.selectedResultBgm != _lastResultBgm) {
      _lastResultBgm = p.selectedResultBgm;
      restartCurrent();
    }
  }

  Future<void> _play(String key, {double volume = 0.35}) =>
      _serialize(() => _playCore(key, volume: volume * volumeScale));

  /// 実際に鳴らす処理。**チェーンの中からだけ呼ぶこと**（[_serialize] 参照）。
  Future<void> _playCore(String key, {double volume = 0.35}) async {
    _cancelPreviewWatch(); // 場面の曲に切り替わるので、試聴の見張りは用済み
    if (!PlayerProfile.instance.bgmEnabled) {
      _current = null;
      await _stopCore();
      return;
    }
    if (_current == key && _player.playing && !_blocked) {
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
      // まず明示的に止めてから、`setAudioSource` で古いソースを解放しつつ新しい曲を読む。
      // ⚠️ 旧 `setAsset` だけだと Web Audio API が前のソースを解放しきらず、
      //    新しい decode に失敗して無音・曲が変わらなかった（Web で再現確認済み）。
      await _player.stop();
      await _player.setAudioSource(AudioSource.asset(key));
      await _player.setLoopMode(LoopMode.one);
      await _player.setVolume(volume);
      _current = key;
      _currentVolume = volume;
      // ⚠️ Webでは `play()` の Future は「曲が終わるか止められるまで」返らない。
      //    チェーンの中で await すると、ループ再生中は以降の操作（stop/曲の変更）
      //    が永遠に実行されず、BGMが死ぬ。なので await せず開始だけを投げる。
      //    自動再生に止められた場合（NotAllowedError）はこの Future がエラーで
      //    完了するので、その時点で `_blocked` を立てる。ソースはロード済みのまま
      //    残すので、次のユーザー操作（[retryIfBlocked]）が `play()` だけを
      //    ジェスチャー内で呼び直して鳴らせる。
      unawaited(_player.play().catchError((Object e) {
        _blocked = true;
      }));
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
      _cancelPreviewWatch();
      _current = null;
      _mode = _BgmMode.none;
      await _stopCore();
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
  /// 場面の設定（[_mode]）は変えないので、試聴が終わればその場面の曲に戻る。
  Future<void> preview(String fileName) {
    return _serialize(() async {
      _cancelPreviewWatch();
      // 🔇 「音楽を鳴らす」をオフにしている人には、試聴でも鳴らさない。
      //    ショップの▶はこの設定を見ていなかったので、消したはずの音が出ていた。
      if (!PlayerProfile.instance.bgmEnabled) return;
      try {
        await _player.stop();
        await _player.setAudioSource(AudioSource.asset(assetKey(fileName)));
        await _player.setLoopMode(LoopMode.off);
        await _player.setVolume(0.4 * volumeScale);
        _current = null; // 試聴後にかけ直せるよう、鳴っている曲の記録は残さない
        _currentVolume = 0.4;
        // ⚠️ `play()` の Future は**曲が終わるまで返らない**。
        //    ここで await すると試聴のあいだチェーンが詰まり、
        //    別の曲の試聴もタブ移動のBGM切り替えも、曲が終わるまで効かなくなる。
        unawaited(_player.play());
        // 試聴が終わったら場面の曲に戻す。黙ったままにすると
        //「試聴したらBGMが止まった」になる。
        _previewWatch = _player.processingStateStream.listen((s) {
          if (s == ProcessingState.completed) {
            _cancelPreviewWatch();
            restartCurrent();
          }
        });
      } catch (e) {
        debugPrint('BGM preview failed ($fileName): $e');
      }
    });
  }

  /// 試聴の終わりを見張っている購読。次の再生・停止が来たら捨てる。
  StreamSubscription<ProcessingState>? _previewWatch;

  void _cancelPreviewWatch() {
    _previewWatch?.cancel();
    _previewWatch = null;
  }
}

/// BGMをいまどの用途で鳴らしているか。
enum _BgmMode { none, home, game, result }
