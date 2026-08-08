import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/foundation.dart';

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
  }

  // ── ゲームプレイ ──
  static void gameStart({required String mode, int? players}) =>
      _log('game_start', {
        'mode': mode, // offline / cpu / online / random_match
        if (players != null) 'players': players,
      });

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

  // ── 広告（視聴率の分析用）──
  // [placement] は 'shop' / 'shop_short_of_coins' / 'home_gift' /
  // 'result_double' / 'profile'。どこから見られたのかを必ず入れる。
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
        'affordable': affordable,
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
        'won': won,
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
        'won': won,
        'random': isRandomMatch,
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
  static void featureOpen(String feature) =>
      _log('feature_open', {'feature': feature});

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
