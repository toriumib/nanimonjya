import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'player_profile.dart';

/// ランキング1件分。
class RankingEntry {
  final String uid;
  final String name;
  final int rating;
  final int wins;
  final int losses;

  RankingEntry({
    required this.uid,
    required this.name,
    required this.rating,
    required this.wins,
    required this.losses,
  });
}

/// ランダムマッチの競技レーティング＆全体ランキング。
/// Firestore `rankings/{uid}` に保存。1回の変動はセキュリティルールで±40に制限。
class RankingService {
  RankingService._();
  static final RankingService instance = RankingService._();

  final FirebaseFirestore _fs = FirebaseFirestore.instance;

  static const int initialRating = 1000;
  static const int winDelta = 25;
  static const int loseDelta = 15;

  CollectionReference<Map<String, dynamic>> get _col =>
      _fs.collection('rankings');

  /// ランダムマッチ終了時に自分の成績を反映（勝ち+25 / 負け-15、下限0）。
  /// 二重加算しないよう呼び出し側でガードすること。
  Future<void> recordResult({required bool won}) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    final uid = user.uid;
    final profile = PlayerProfile.instance;
    final name = profile.nickname.isNotEmpty
        ? profile.nickname
        : 'プレイヤー${uid.substring(0, 4)}';

    try {
      final ref = _col.doc(uid);
      final newRating = await _fs.runTransaction<int>((tx) async {
        final snap = await tx.get(ref);
        final cur = snap.data();
        final curRating = (cur?['rating'] as int?) ?? initialRating;
        final curWins = (cur?['wins'] as int?) ?? 0;
        final curLosses = (cur?['losses'] as int?) ?? 0;

        final delta = won ? winDelta : -loseDelta;
        int next = curRating + delta;
        if (next < 0) next = 0;

        tx.set(ref, {
          'name': name,
          'rating': next,
          'wins': curWins + (won ? 1 : 0),
          'losses': curLosses + (won ? 0 : 1),
          'updatedAt': FieldValue.serverTimestamp(),
        });
        return next;
      });
      await profile.setRankRating(newRating);
    } catch (e) {
      // 失敗しても致命的ではない（次回反映）
      // ignore: avoid_print
      print('ランキング更新失敗: $e');
    }
  }

  /// 表示名だけを更新（レーティングは維持）。
  Future<void> updateNameOnly(String name) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    final ref = _col.doc(user.uid);
    try {
      await _fs.runTransaction((tx) async {
        final snap = await tx.get(ref);
        final cur = snap.data();
        tx.set(ref, {
          'name': name,
          'rating': (cur?['rating'] as int?) ?? initialRating,
          'wins': (cur?['wins'] as int?) ?? 0,
          'losses': (cur?['losses'] as int?) ?? 0,
          'updatedAt': FieldValue.serverTimestamp(),
        });
      });
    } catch (_) {}
  }

  /// 上位ランキングを購読（レーティング降順・最大50件）。
  Stream<List<RankingEntry>> topPlayers({int limit = 50}) {
    return _col
        .orderBy('rating', descending: true)
        .limit(limit)
        .snapshots()
        .map((snap) => snap.docs.map((d) {
              final data = d.data();
              return RankingEntry(
                uid: d.id,
                name: (data['name'] as String?) ?? '???',
                rating: (data['rating'] as int?) ?? initialRating,
                wins: (data['wins'] as int?) ?? 0,
                losses: (data['losses'] as int?) ?? 0,
              );
            }).toList());
  }
}
