import 'package:flutter/material.dart';

import '../models/cosmetics.dart';
import '../services/player_profile.dart';

/// 着せ替えテーマ（[HomeTheme]）を、ホーム以外の画面にも敷くための背景。
///
/// これまで各画面が背景グラデーションを直書きしていたため、テーマを買っても
/// ホーム画面しか変わらなかった。この widget を通すことで、買ったテーマが
/// アプリ全体に効くようになる。
///
/// 使う色は [HomeTheme.subtle]（必ず明るい2色）なので、暗いテーマを選んでも
/// 各画面の黒文字が読めなくなることはない。
class ThemedBackground extends StatelessWidget {
  final Widget child;

  const ThemedBackground({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: PlayerProfile.instance,
      builder: (context, _) {
        final t = homeThemeById(PlayerProfile.instance.selectedTheme);
        return DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: t.subtle,
            ),
          ),
          child: child,
        );
      },
    );
  }
}
