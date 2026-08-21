import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

/// 📮 ゲーム内のご意見・不具合報告を Firestore の `feedback` コレクションへ送る。
///
/// 受け手は Firebase コンソールで `feedback` コレクションを開くだけで読める。
/// 送信者の匿名 uid・端末種別・どの画面から送ったかも一緒に残すので、
/// 「どこで起きたか」の切り分けがしやすい。
class FeedbackService {
  FeedbackService._();

  /// [text] を feedback コレクションへ保存する。成功で true。
  static Future<bool> submit(String text) async {
    final body = text.trim();
    if (body.isEmpty) return false;
    try {
      // ルールが request.auth != null を要求するため、未ログインなら匿名で入る。
      var user = FirebaseAuth.instance.currentUser;
      user ??= (await FirebaseAuth.instance.signInAnonymously()).user;

      await FirebaseFirestore.instance.collection('feedback').add({
        'text': body,
        'platform': kIsWeb ? 'web' : defaultTargetPlatform.name,
        'screen': 'home',
        'at': FieldValue.serverTimestamp(),
      });
      return true;
    } catch (e) {
      debugPrint('FeedbackService.submit error: $e');
      return false;
    }
  }
}
