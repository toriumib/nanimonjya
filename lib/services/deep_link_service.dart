import 'dart:async';
import 'package:flutter/material.dart';
import 'package:app_links/app_links.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../screens/online_game_screen.dart';

/// 合言葉リンク（例: https://nanimonjya.web.app/join?room=ABC123 や
/// nanimonjya://join?room=ABC123）からアプリを起動・復帰したときに、
/// そのルームへ自動入室させるサービス。
class DeepLinkService {
  DeepLinkService._();
  static final DeepLinkService instance = DeepLinkService._();

  /// 画面遷移に使うグローバルなナビゲーターキー（main.dart で MaterialApp に渡す）。
  static final GlobalKey<NavigatorState> navigatorKey =
      GlobalKey<NavigatorState>();

  final AppLinks _appLinks = AppLinks();
  StreamSubscription<Uri>? _sub;
  bool _handling = false;

  /// アプリ起動時に呼ぶ。初回リンク＋以降のリンクを監視する。
  Future<void> init() async {
    // 起動時にリンクで開かれた場合
    try {
      final initial = await _appLinks.getInitialLink();
      if (initial != null) _handleUri(initial);
    } catch (_) {}
    // 起動後にリンクが来た場合
    _sub = _appLinks.uriLinkStream.listen(
      (uri) => _handleUri(uri),
      onError: (_) {},
    );
  }

  void dispose() {
    _sub?.cancel();
  }

  /// URI から room コードを取り出して入室する。
  Future<void> _handleUri(Uri uri) async {
    // ?room=CODE を最優先。無ければ /join/CODE 形式も拾う。
    String? room = uri.queryParameters['room'];
    if (room == null || room.isEmpty) {
      final segs = uri.pathSegments;
      final i = segs.indexOf('join');
      if (i >= 0 && i + 1 < segs.length) room = segs[i + 1];
    }
    if (room == null || room.isEmpty) return;
    await joinByCode(room.toUpperCase());
  }

  /// 合言葉コードからルームに入室する（共有リンク経由・手動どちらでも使える）。
  Future<void> joinByCode(String roomId) async {
    if (_handling) return;
    _handling = true;
    try {
      final nav = navigatorKey.currentState;
      if (nav == null) return;

      // 匿名認証
      User? user = FirebaseAuth.instance.currentUser;
      user ??= (await FirebaseAuth.instance.signInAnonymously()).user;
      if (user == null) return;
      final myPlayerId = user.uid;

      final roomRef = FirebaseFirestore.instance.collection('rooms').doc(roomId);
      final snap = await roomRef.get();
      if (!snap.exists) {
        _showSnack('その合言葉のへやが見つかりませんでした');
        return;
      }
      final data = snap.data() as Map<String, dynamic>;

      // 参加者として登録（未登録なら追加）
      final players = List<String>.from(data['players'] ?? []);
      if (!players.contains(myPlayerId)) {
        await FirebaseFirestore.instance.runTransaction((tx) async {
          final fresh = await tx.get(roomRef);
          if (!fresh.exists) return;
          final fd = fresh.data() as Map<String, dynamic>;
          final ps = List<String>.from(fd['players'] ?? []);
          if (ps.contains(myPlayerId)) return;
          if (ps.length >= 8) return; // 満員
          ps.add(myPlayerId);
          final scores = Map<String, dynamic>.from(fd['scores'] ?? {});
          scores[myPlayerId] = 0;
          tx.update(roomRef, {'players': ps, 'scores': scores});
        });
      }

      final isVoice = data['gameMode'] == 'voice';
      nav.push(
        MaterialPageRoute(
          builder: (_) => OnlineGameScreen(
            roomId: roomId,
            myPlayerId: myPlayerId,
            isVoiceMode: isVoice,
          ),
        ),
      );
    } catch (e) {
      debugPrint('ディープリンク入室に失敗: $e');
    } finally {
      _handling = false;
    }
  }

  void _showSnack(String msg) {
    final ctx = navigatorKey.currentContext;
    if (ctx != null) {
      ScaffoldMessenger.of(ctx)
          .showSnackBar(SnackBar(content: Text(msg)));
    }
  }
}

/// 合言葉から共有用のリンクを組み立てる。
String buildRoomShareLink(String roomId) =>
    'https://nanimonjya.web.app/join?room=$roomId';
