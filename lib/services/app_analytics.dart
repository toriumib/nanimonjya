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

  // ── 広告（視聴率の分析用）──
  static void adRewardPrompt(String placement) =>
      _log('ad_reward_prompt', {'placement': placement});

  static void adRewardEarned(String placement) =>
      _log('ad_reward_earned', {'placement': placement});

  // ── メタ層 ──
  static void dailyBonusClaimed(int streak) =>
      _log('daily_bonus_claimed', {'streak': streak});

  static void notificationTapped() => _log('daily_reminder_open');

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
}
