import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:nanimonjya/services/interstitial_ad_helper.dart';

/// 📊 全画面広告の「出す間隔」の決まりごとを守るテスト。
///
/// 2026-08のAdMobでは表示7回／リクエスト56だった。完了した試合は90前後
/// あったので、2プレイに1回なら本来45回前後は出ていたはず。原因は
///   ① 期限切れ（約1時間）の広告が居座り、出そうとして毎回失敗していた
///   ② 「表示する」と決めた時点でカウンタを0に戻していたので、
///      表示に失敗した回のプレイまで消費されていた
/// の2つ。ここでは②の「出せなかったらプレイ数を消費しない」を固定する。
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('広告が用意できていないときは、プレイ数を使い切らずに持ち越す', () async {
    // テスト環境では広告を読み込めない＝常に「準備できていない」状態になる。
    final helper = InterstitialAdHelper.instance;
    for (var i = 0; i < 5; i++) {
      await helper.onGameFinished();
    }
    final p = await SharedPreferences.getInstance();
    final plays = p.getInt('playsSinceInterstitial') ?? 0;

    // 出せなかったぶんは持ち越すので、しきい値より下には戻らない。
    // （0に戻ると、次に出せるまでまた2プレイ必要になる＝取りこぼし）
    expect(plays, greaterThanOrEqualTo(InterstitialAdHelper.playsPerAd),
        reason: '出せていないのにカウンタが0に戻っている');
  });

  test('しきい値と間隔の設定は、出しすぎない範囲に収まっている', () {
    // 出しすぎて遊ぶのをやめられたら、その先の広告収入ごと失う。
    expect(InterstitialAdHelper.playsPerAd, greaterThanOrEqualTo(2));
    expect(InterstitialAdHelper.minIntervalSeconds, greaterThanOrEqualTo(60));
  });
}
