import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';

/// Firebase Analytics のイベント送信を一箇所に集約するヘルパー。
/// 呼び出し側は await 不要（fire-and-forget）。失敗してもゲームは止めない。
class AppAnalytics {
  AppAnalytics._();

  static FirebaseAnalytics get _fa => FirebaseAnalytics.instance;

  static void _log(String name, [Map<String, Object>? params]) {
    // Analytics はWebでも動くが、失敗がUIに波及しないよう握りつぶす
    _fa.logEvent(name: name, parameters: params).catchError((e) {
      debugPrint('Analytics error ($name): $e');
    });
  }

  /// 画面表示（どの画面で離脱するかの分析用）
  static void screen(String screenName) {
    _fa
        .logScreenView(screenName: screenName)
        .catchError((e) => debugPrint('Analytics screen error: $e'));
    // 🩹 いまいる画面を Crashlytics にも残す。
    //
    // ⚠️ 2026-08 の時点で app_exception が 317件／11ユーザー
    //    （1人あたり28.8件）出ていたのに、**どの画面で起きたのかを
    //    특定する手がかりが無かった**。スタックだけでは Flutter の
    //    フレームワーク内部を指すことが多く、原因画面に辿りつけない。
    if (!kIsWeb) {
      FirebaseCrashlytics.instance
          .setCustomKey('screen', screenName)
          .catchError((_) {});
    }
  }

  /// ⏱ 初回起動の時刻。[markFirstGameIfNeeded] で使う。
  static const String _firstOpenKey = 'analyticsFirstOpenMillis';
  static const String _firstGameKey = 'analyticsFirstGameSent';

  /// 初回起動からゲーム開始までの秒数を、1回だけ送る。
  ///
  /// ⚠️ ここがいちばん大きい穴。2026-08 は起動162人に対して
  ///    ゲームを始めたのが75人しかいなかった。改善したかどうかを
  ///    判定できるように、**時間**で測る。
  static Future<void> markFirstGameIfNeeded() async {
    try {
      final p = await SharedPreferences.getInstance();
      if (p.getBool(_firstGameKey) ?? false) return;
      final first = p.getInt(_firstOpenKey);
      if (first == null) return; // 初回起動を記録する前の版から来た人
      await p.setBool(_firstGameKey, true);
      final sec = (DateTime.now().millisecondsSinceEpoch - first) ~/ 1000;
      firstGameStarted(sec);
    } catch (_) {}
  }

  /// 初回起動の時刻を控える（`main` から1回だけ呼ぶ）。
  static Future<void> rememberFirstOpen() async {
    try {
      final p = await SharedPreferences.getInstance();
      if (p.containsKey(_firstOpenKey)) return;
      await p.setInt(_firstOpenKey, DateTime.now().millisecondsSinceEpoch);
    } catch (_) {}
  }

  // ── ゲームプレイ ──
  static void gameStart({required String mode, int? players}) {
    _log('game_start', {
      'mode': mode, // offline / cpu / online / random_match
      if (players != null) 'players': players,
    });
    // 初回だけ「起動から何秒でここに来たか」を送る
    markFirstGameIfNeeded();
  }

  static void gameEnd({required String mode, required int topScore}) =>
      _log('game_end', {'mode': mode, 'top_score': topScore});

  // ───────── 📉 完走率のファネル ─────────
  // game_start と game_end のあいだが真っ暗で「どこで離脱したか」が
  // 分からなかったため、通過点を撃つ。GA4の「目標到達プロセスデータ探索」に
  // game_start → namecall_progress(各phase) → game_end を順に並べると、
  // 何人がどの段で消えたかが段ごとの実数で出る。

  /// ゲーム中の通過点。[phase] は到達順に固定の識別子を使う:
  /// - 'naming_done'  : 全員の命名がおわって本編に入った
  /// - 'recall_first' : 最初の想起（1枚目の出題）にたどりついた
  /// - 'recall_half'  : 出題の半分をこなした
  /// [people] は登場人数（6/9/12）。人数が多いほど落ちるのかを見分ける。
  static void namecallProgress({
    required String phase,
    required int people,
    required String mode,
  }) =>
      _log('namecall_progress', {
        'phase': phase,
        'people': people,
        'mode': mode,
      });

  /// ゲームがどう終わったか。完走と中断を分けて数える。
  /// [reason] は 'completed'（最後まで）/ 'quit'（戻るで自分から離脱）/
  /// 'backgrounded'（アプリを閉じた・別アプリへ）。
  /// [progressPct] は何%まで進んでいたか（0-100）。
  static void gameExit({
    required String mode,
    required String reason,
    required int progressPct,
    required int people,
  }) =>
      _log('game_exit', {
        'mode': mode,
        'reason': reason,
        'progress_pct': progressPct,
        'people': people,
      });

  /// 🚪 プレイ中にアプリの外へ出た（ホームボタン・別アプリ）。
  ///
  /// ⚠️ **これが無いと「飽きた」と「落ちた」が区別できない。**
  ///    2026-08 のデータは game_start 229 に対し、完了90・中断37 で、
  ///    **102件がどちらでもなかった**。中断（[gameExit]）は dispose で
  ///    撃っているので、アプリ内で画面を離れたぶんは拾えている。
  ///    残る102件は「アプリごと消えた」ぶん。
  ///
  /// ここを撃つと切り分けられる:
  /// - `game_background` あり → **自分で外に出た＝飽きた・用事ができた**
  /// - どちらも無い          → **落ちた**
  ///
  /// [card] は何枚目で出たか。ここが特定の枚数に集中していれば、
  /// 「その辺で飽きる」という設計の問題。
  static void gameBackground({
    required String mode,
    required int progressPct,
    required int card,
    required int totalCards,
  }) =>
      _log('game_background', {
        'mode': mode,
        'progress_pct': progressPct,
        'card': card,
        'total_cards': totalCards,
      });

  /// 外に出たあと、戻ってきた。[awaySeconds] は離れていた秒数。
  /// 戻ってこない人は、この差分で分かる。
  static void gameResume({required String mode, required int awaySeconds}) =>
      _log('game_resume', {'mode': mode, 'away_seconds': awaySeconds});

  /// 🎴 キャラデッキを開いた。[from] は face_memo/shop/profile。
  static void deckOpen(String from) => _log('deck_open', {'from': from});

  /// デッキの出演ON/OFFを変えた。作ったアバターが使われているかを見る。
  static void deckToggle({required int enabled, required int total}) =>
      _log('deck_toggle', {'enabled': enabled, 'total': total});

  /// 🌐 オンラインの待合室に入った。[kind] は friend/random/rank/turn。
  ///
  /// ⚠️ `online_match_end` は実装済みだが2026-08 は0件だった。
  ///    「対戦が終わらない」のか「そもそも入っていない」のかを
  ///    分けるために、入口を数える。
  static void onlineLobbyOpen(String kind) =>
      _log('online_lobby_open', {'kind': kind});

  /// 待合室から、対戦が始まらないまま出た。[waitedSeconds] は待った秒数。
  static void onlineLobbyLeave({
    required String kind,
    required int waitedSeconds,
  }) =>
      _log('online_lobby_leave',
          {'kind': kind, 'waited_seconds': waitedSeconds});

  /// 🚀 ものがたりを始めた。`story_progress` の分母になる。
  static void storyStart() => _log('story_start');

  // ── 広告（視聴率の分析用）──
  // [placement] は 'shop' / 'shop_short_of_coins' / 'home_gift' /
  // 'result_double' / 'profile'。どこから見られたのかを必ず入れる。
  // ── 広告のロードと表示 ──
  //
  // ⚠️ **ロードと表示を別々に数える。** 2026-08 の AdMob レポートで
  //    リワードが「446ロード / 14表示（3.1%）」だった。原因を突き止める
  //    手段が無かったのは、ロードしたことを記録していなかったから。
  //    出せなかったときは [adSkipped] に理由を残す。

  /// 広告のロードを開始した。[format] は banner/interstitial/rewarded/
  /// rewarded_interstitial/app_open。
  static void adLoadRequested({
    required String format,
    required String placement,
  }) =>
      _log('ad_load_requested', {'format': format, 'placement': placement});

  /// 実際に画面に出した。[adLoadRequested] との差が空振り。
  static void adShown({required String format, required String placement}) =>
      _log('ad_shown', {'format': format, 'placement': placement});

  /// 出そうとしたが出せなかった。
  ///
  /// [reason] は固定の識別子:
  /// 'not_loaded'（まだ届いていない）/ 'no_fill'（在庫なし）/
  /// 'expired'（期限切れ）/ 'cooldown'（間隔制限）/ 'error'。
  static void adSkipped({
    required String format,
    required String placement,
    required String reason,
  }) =>
      _log('ad_skipped',
          {'format': format, 'placement': placement, 'reason': reason});

  static void adRewardPrompt(String placement) =>
      _log('ad_reward_prompt', {'placement': placement});

  static void adRewardEarned(String placement) =>
      _log('ad_reward_earned', {'placement': placement});

  /// 「なぜ動画を見たのか」を残す。
  ///
  /// コインが足りずに広告へ誘導した瞬間を、**買おうとしていた商品と一緒に**
  /// 記録する。これがないと「広告がよく見られた」までは分かっても
  /// 「何が欲しくて見たのか」が永久に分からない（実際、過去に広告が
  /// 伸びたときの目的を後から特定できなかった）。
  static void adOfferedForItem({
    required String category,
    required String itemId,
    required int cost,
    required int coinsHeld,
  }) =>
      _log('ad_offered_for_item', {
        'category': category,
        'item_id': itemId,
        'cost': cost,
        'coins_held': coinsHeld,
        'short_by': cost - coinsHeld,
      });

  /// ショップの商品を見た（一覧に表示された、ではなく詳細に反応した）。
  /// 欲しがられているが買われていない商品＝値段が高すぎる商品を見つける。
  static void shopItemTapped({
    required String category,
    required String itemId,
    required int cost,
    required bool affordable,
  }) =>
      _log('shop_item_tap', {
        'category': category,
        'item_id': itemId,
        'cost': cost,
        'affordable': affordable ? 1 : 0,
      });

  // ── メタ層 ──
  static void dailyBonusClaimed(int streak) =>
      _log('daily_bonus_claimed', {'streak': streak});

  static void notificationTapped() => _log('daily_reminder_open');

  /// 🔔 練習リマインドのソフトアスクの通過状況。
  /// 「出した→受けた→OSも許可した」のどこで落ちているかが分からないと、
  /// 文言を直すべきなのか出す場所を変えるべきなのか判断できない。
  static void notifyPrompt({
    required bool shown,
    bool? accepted,
    bool? granted,
  }) =>
      _log('notify_prompt', {
        'stage': shown
            ? 'shown'
            : accepted == true
                ? (granted == true ? 'granted' : 'os_denied')
                : 'later',
      });

  // ── CPU対戦・認知トレーニング ──
  static void cpuMatchEnd({
    required String level,
    required bool won,
    required int accuracyPct,
    required int avgReactionMs,
  }) =>
      _log('cpu_match_end', {
        'level': level,
        'won': won ? 1 : 0,
        'accuracy_pct': accuracyPct,
        'avg_reaction_ms': avgReactionMs,
      });

  static void soloTrainingEnd({
    required int accuracyPct,
    required int avgReactionMs,
  }) =>
      _log('solo_training_end', {
        'accuracy_pct': accuracyPct,
        'avg_reaction_ms': avgReactionMs,
      });

  static void onlineMatchEnd({
    required bool won,
    required bool isRandomMatch,
  }) =>
      _log('online_match_end', {
        'won': won ? 1 : 0,
        'random': isRandomMatch ? 1 : 0,
      });

  static void reviewPromptShown() => _log('review_prompt_shown');

  // ───────── 📊 使われ方の可視化 ─────────
  // 「どの機能が使われ、ショップで何が売れているか」を後から数えられるようにする。
  // Firebase コンソール → Analytics → イベント で見られる。
  // ⚠️ 個人を特定できる値（入力した名前・写真・名刺の中身）は絶対に送らない。
  //    送るのはカタログ上のIDと数量だけ。

  /// タブ・モードに入った回数。どの遊び方が人気かを測る。
  /// [feature] は 'namecall' / 'pairs' / 'training' / 'read' / 'profile' /
  /// 'shop' / 'recall' / 'custom_roster' / 'spaced_review' など固定の識別子。
  /// [from] は tab / tile / deeplink。
  /// ⚠️ 以前は下タブの切替でしか撃っていなかったので、ホームのタイルから
  ///    入った人が1人も数えられていなかった。入口も必ず添えること。
  static void featureOpen(String feature, {String from = 'tab'}) =>
      _log('feature_open', {'feature': feature, 'from': from});

  // ── 機能ごとの「開いた／使った／終えた」 ──
  //
  // ⚠️ **開いた数だけでは、使われたのか眺めて閉じたのか分からない。**
  //    2026-08 のレポートでは、顔メモ・よみもの・キャラデッキに
  //    イベントが1つも無く、「使われていない」のか「測っていない」のかを
  //    区別できなかった。機能を足すときは必ず3点セットで撃つ。

  /// 🧑‍🎨 顔メモを開いた。[from] は home/tab/deck。
  static void faceMemoOpen(String from) =>
      _log('face_memo_open', {'from': from});

  /// 追加方法を選んだ。[kind] は avatar/photo/camera。
  ///
  /// [faceMemoAdded] との差が、登録フォームの離脱率になる。
  /// 18項目もあるので、ここは必ず measurable にしておく。
  static void faceMemoAddStart(String kind) =>
      _log('face_memo_add_start', {'kind': kind});

  /// 登録が完了した。[fieldsFilled] は18項目のうち埋めた数。
  static void faceMemoAdded({required String kind, required int fieldsFilled}) =>
      _log('face_memo_added', {'kind': kind, 'fields_filled': fieldsFilled});

  /// 似顔絵エディタで「この顔で決定」を押した。
  /// [changed] はいじった項目数（0なら既定のまま出た＝作り込まれていない）。
  static void avatarEditorDone(int changed) =>
      _log('avatar_editor_done', {'changed': changed});

  /// 📚 読み物を開いた／ページを送った／読み切った。
  ///
  /// [readPage] があると**何ページ目で閉じられるか**が分かる。
  /// 全25話あるので、開いた数だけでは改善のしようがない。
  static void readOpen(String articleId) =>
      _log('read_open', {'article_id': articleId});

  static void readPage({required String articleId, required int page}) =>
      _log('read_page', {'article_id': articleId, 'page': page});

  static void readFinish(String articleId) =>
      _log('read_finish', {'article_id': articleId});

  /// 💼 名刺覚え。開始と終了で1組。
  static void recallStart({required int count, required int fields}) =>
      _log('recall_start', {'count': count, 'fields': fields});

  /// ⏱ 初回起動からゲームを始めるまでの秒数。
  ///
  /// 2026-08 の時点で、起動した162人のうち87人が**1回もゲームを
  /// 始めずに消えた**。ここがいちばん大きい穴なので、直接測る。
  static void firstGameStarted(int secondsSinceFirstOpen) =>
      _log('first_game_started', {'seconds': secondsSinceFirstOpen});

  /// 🎯 ホームでどの遊び方のボタンが押されたか。
  ///
  /// [featureOpen] が数えるのは「下タブを切り替えた回数」なので、
  /// なまえがおタブの中にある みんなで／ひとりで／オンライン／ランク が
  /// まったく区別できなかった。**どのモードが人気か**を知るには
  /// 押された瞬間をボタン単位で撃つ必要がある。
  ///
  /// [mode] は固定の識別子:
  /// 'local'（みんなで1台）/ 'cpu' / 'online_friend' / 'rank' /
  /// 'face_memo' / 'tutorial' / 'support' / 'profile' / 'rules'。
  ///
  /// GA4 では mode 別に数えると、そのままモード人気の順位表になる。
  /// 起動しただけの回数と区別するため、game_start とは別イベントにする
  /// （押したが設定シートで止めた人も、ここには残る）。
  static void modePick(String mode) => _log('mode_pick', {'mode': mode});

  /// 🚀 ものがたりモードの進み具合。
  ///
  /// 読み物と違って章が長いので、「開いた数」だけでは
  /// 最後まで遊ばれているのか途中で閉じられているのか分からない。
  /// [phase] は _Phase の名前をそのまま入れる。
  static void storyProgress(String phase) =>
      _log('story_progress', {'phase': phase});

  /// 🚀 ものがたりモードの結末。どの結末に届いたかの分布を見る。
  /// [ending] は 'happy' / 'harem' / 'bitter' / 'lonely'。
  static void storyEnding({
    required String ending,
    required int correct,
    required int total,
  }) =>
      _log('story_ending', {
        'ending': ending,
        'correct': correct,
        'total': total,
      });

  /// ショップの購入。何がどれだけ売れているかを商品単位で数える。
  /// [category] は 'character' / 'voice' / 'charm' / 'skin' / 'theme' / 'bgm'。
  /// [method] は 'coins'（コイン購入）/ 'ad'（動画で解放）/ 'iap'（課金）。
  static void shopPurchase({
    required String category,
    required String itemId,
    required int cost,
    required String method,
  }) =>
      _log('shop_purchase', {
        'category': category,
        'item_id': itemId,
        'cost': cost,
        'method': method,
      });

  /// 買おうとしたがコインが足りなかった。値付けが高すぎる商品を見つけられる。
  static void shopBlockedByCoins({
    required String category,
    required String itemId,
    required int shortBy,
  }) =>
      _log('shop_short_of_coins', {
        'category': category,
        'item_id': itemId,
        'short_by': shortBy,
      });

  /// 日をまたいだ復習をやり切った。定着の指標。
  static void spacedReviewDone({required int total, required int correct}) =>
      _log('spaced_review_done', {'total': total, 'correct': correct});
}
