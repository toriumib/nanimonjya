import 'package:in_app_review/in_app_review.dart';

import 'player_profile.dart';

/// 良いタイミング（勝利・好成績・特訓クリア）で、一度だけストアレビュー依頼を出す。
/// [minGames] 未満のプレイ回数では出さない（初回の連打を避ける）。
Future<void> maybeAskReview({int minGames = 3}) async {
  final p = PlayerProfile.instance;
  if (p.reviewPrompted) return;
  if (p.totalGames < minGames) return;
  try {
    final review = InAppReview.instance;
    if (await review.isAvailable()) {
      await p.markReviewPrompted();
      await review.requestReview();
    }
  } catch (_) {
    // レビューAPIが使えない環境では何もしない
  }
}
