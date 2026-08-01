import 'package:flutter_test/flutter_test.dart';
import 'package:nanimonjya/services/notify_prompt.dart';

/// 🔔 練習リマインドのお伺いを「いつ出すか／いつ出さないか」。
///
/// 7日維持率を上げたいので出したいが、しつこいと通知そのものを嫌われて
/// 逆効果になる。さじ加減は手では確かめにくいのでここで固定する。
void main() {
  bool ask({
    bool optIn = false,
    int totalGames = 1,
    int promptCount = 0,
    int promptedAtGames = 0,
    int reviewPromptCount = 0,
    int reviewPromptedAtGames = 0,
  }) =>
      shouldAskNotify(
        optIn: optIn,
        totalGames: totalGames,
        promptCount: promptCount,
        promptedAtGames: promptedAtGames,
        reviewPromptCount: reviewPromptCount,
        reviewPromptedAtGames: reviewPromptedAtGames,
      );

  test('1ゲーム終えたら聞く', () {
    // 「覚えられた／忘れていた」を一度体験した直後が、
    // 明日また思い出す約束をいちばん受けてもらえる場面。
    expect(ask(totalGames: 1), isTrue);
  });

  test('1ゲームも終えていないうちは聞かない', () {
    // 価値が伝わる前に頼むと断られ、Androidでは二度と聞けなくなる。
    expect(ask(totalGames: 0), isFalse);
  });

  test('すでに受け取ってくれている人には聞かない', () {
    expect(ask(optIn: true, totalGames: 10), isFalse);
  });

  test('「あとで」の直後には聞き直さない', () {
    expect(ask(totalGames: 2, promptCount: 1, promptedAtGames: 1), isFalse);
  });

  test('十分あそんでもらってから、もう一度だけ聞く', () {
    expect(ask(totalGames: 6, promptCount: 1, promptedAtGames: 1), isTrue);
  });

  test('2回断られたら、それ以上は二度と聞かない', () {
    expect(ask(totalGames: 100, promptCount: 2, promptedAtGames: 1), isFalse);
  });

  test('レビュー依頼と同じ場面では出さない（2枚続けて出さない）', () {
    expect(
        ask(
            totalGames: 7,
            promptCount: 1,
            promptedAtGames: 1,
            reviewPromptCount: 1,
            reviewPromptedAtGames: 7),
        isFalse);
  });

  test('レビュー依頼が別の場面だったなら出してよい', () {
    expect(
        ask(
            totalGames: 8,
            promptCount: 1,
            promptedAtGames: 1,
            reviewPromptCount: 1,
            reviewPromptedAtGames: 7),
        isTrue);
  });
}
