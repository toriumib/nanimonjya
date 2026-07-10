import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 📖 みんなの珍名アルバム。
/// オンライン対戦でつけられた名前を匿名で収集し、
/// 「今週の爆笑ネーム大賞」（❤️投票制）として表示する。
class FunnyName {
  final String id;
  final String name;
  final int likes;
  FunnyName({required this.id, required this.name, required this.likes});
}

class NameAlbumService {
  NameAlbumService._();
  static final NameAlbumService instance = NameAlbumService._();
  final FirebaseFirestore _fs = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _col =>
      _fs.collection('funnyNames');

  /// 今週のキー（例: 2026-W28相当。月曜はじまりの単純計算）
  static String weekKey([DateTime? now]) {
    final d = now ?? DateTime.now();
    final firstDay = DateTime(d.year, 1, 1);
    final week = ((d.difference(firstDay).inDays + firstDay.weekday) / 7).ceil();
    return '${d.year}-W$week';
  }

  /// 名前を匿名投稿（命名時に自動で呼ばれる・失敗しても無視）
  Future<void> submit(String name) async {
    final n = name.trim();
    if (n.isEmpty || n.length > 8) return;
    if (FirebaseAuth.instance.currentUser == null) return;
    try {
      await _col.add({
        'name': n,
        'week': weekKey(),
        'likes': 0,
        'createdAt': FieldValue.serverTimestamp(),
      });
    } catch (_) {}
  }

  /// 今週の投稿を取得（likes降順に整列して返す）。
  /// 複合インデックス不要にするため week 一致だけで取得しクライアントで整列。
  Stream<List<FunnyName>> weeklyTop({int limit = 30}) {
    return _col
        .where('week', isEqualTo: weekKey())
        .limit(200)
        .snapshots()
        .map((snap) {
      final list = snap.docs
          .map((d) => FunnyName(
                id: d.id,
                name: (d.data()['name'] as String?) ?? '?',
                likes: (d.data()['likes'] as int?) ?? 0,
              ))
          .toList()
        ..sort((a, b) => b.likes.compareTo(a.likes));
      return list.take(limit).toList();
    });
  }

  /// ❤️を送る（1端末につき各名前1回・ローカルで管理）
  Future<bool> like(String id) async {
    final prefs = await SharedPreferences.getInstance();
    final liked = (prefs.getStringList('likedNames') ?? []).toSet();
    if (liked.contains(id)) return false;
    try {
      await _col.doc(id).update({'likes': FieldValue.increment(1)});
      liked.add(id);
      await prefs.setStringList('likedNames', liked.toList());
      return true;
    } catch (_) {
      return false;
    }
  }
}
