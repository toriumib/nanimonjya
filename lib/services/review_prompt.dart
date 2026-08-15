import 'package:in_app_review/in_app_review.dart';

import 'app_analytics.dart';
import 'player_profile.dart';

/// これ未満のプレイ回数では絶対に頼まない（呼び出し側が0を渡しても守る）。
const int _absoluteFloor = 3;

/// 次に頼むまでに必要な追加プレイ数。
const int _gapGames = 15;

/// 依頼の上限回数。
const int _maxAttempts = 3;

/// 良いタイミング（勝利・好成績・特訓クリア）でストアレビュー依頼を出す。
///
/// 設計の理由:
/// - **1回きりにしない**。`requestReview()` はGoogle側の頻度制限でダイアログが
///   出ないことがあり、その場合もアプリからは成功したように見える。
///   1回で打ち止めにすると「実際には一度も表示されないまま終わる」ことがある。
///   間隔をあけて最大[_maxAttempts]回まで試す。
/// - **最低プレイ回数を必ず守る**。呼び出し側が `minGames: 0` を渡しても、
///   価値を感じてもらう前に頼むのは逆効果（低評価を呼ぶ）なので
///   [_absoluteFloor] を下回らせない。
Future<void> maybeAskReview({int minGames = 3}) async {
  final p = PlayerProfile.instance;
  final games = p.totalGames;

  // 呼び出し側の指定と絶対下限の、きびしいほうを採用する
  final threshold = minGames > _absoluteFloor ? minGames : _absoluteFloor;
  if (games < threshold) return;

  if (p.reviewPromptCount >= _maxAttempts) return;
  // 前回頼んでから十分あそんでもらってから、もう一度だけ声をかける
  if (p.reviewPromptCount > 0 && games - p.reviewPromptedAtGames < _gapGames) {
    return;
  }

  try {
    final review = InAppReview.instance;
    if (await review.isAvailable()) {
      await p.markReviewPrompted();
      // 📊 出そうとした回数を残す。
      //    requestReview() は Google 側の割り当てで**何も出ないことがあり**、
      //    しかもアプリからは成功と区別がつかない。せめて
      //    「何回声をかけたか」だけでも見えるようにしておかないと、
      //    レビューが増えない原因が導線なのか割り当てなのか判断できない。
      AppAnalytics.reviewPromptShown();
      await review.requestReview();
    }
  } catch (_) {
    // レビューAPIが使えない環境では何もしない
  }
}

/// ⭐ 自分から「評価する」を押したときに、ストアのページを開く。
///
/// [maybeAskReview] との違いは2つ。
/// - **必ずストアのページを開く**。アプリ内ダイアログ（`requestReview`）は
///   Google の割り当てにかかると黙って何も出ないので、
///   自分から押した人にまで「押したのに何も起きない」を見せない。
/// - **自動の依頼回数を消費しない**。手動で開いたからといって、
///   あとから来る良いタイミングでの依頼を減らす理由はない。
Future<void> openStoreReview() async {
  try {
    AppAnalytics.reviewPromptShown();
    await InAppReview.instance.openStoreListing();
  } catch (_) {
    // ストアが無い環境（Web・エミュレータ等）では何もしない
  }
}
