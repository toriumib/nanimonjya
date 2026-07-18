import 'package:flutter/material.dart';

/// ディープリンクサービス（v2.0.0で無効化）。
///
/// 旧オンライン対戦の「合言葉リンク入室」に使っていたが、
/// ルール刷新（顔と名前の神経衰弱）に伴いオンライン対戦を撤去したため、
/// 現在は navigatorKey の提供のみ行う空実装。
/// オンライン対戦を新ルールで再実装する際にここへ戻す。
class DeepLinkService {
  DeepLinkService._();
  static final DeepLinkService instance = DeepLinkService._();

  /// 画面遷移に使うグローバルなナビゲーターキー（main.dart で MaterialApp に渡す）。
  static final GlobalKey<NavigatorState> navigatorKey =
      GlobalKey<NavigatorState>();

  /// 何もしない（旧: リンク監視を開始していた）。
  Future<void> init() async {}

  void dispose() {}
}
