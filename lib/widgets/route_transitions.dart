import 'package:flutter/material.dart';

/// アプリ全体の画面遷移をポップに演出するためのユーティリティ。
///
/// - [PopSlideFadeTransitionsBuilder] を ThemeData.pageTransitionsTheme に登録すると、
///   既存の Navigator.push（MaterialPageRoute）が全部まとめて「スライド＋フェード＋わずかに拡大」の
///   気持ちいい遷移になる（呼び出し側の変更ゼロ）。
/// - 個別に使いたいときは [slideFadeRoute] / [fadeRoute] を使う。

/// 右からスライドインしつつフェード＆微拡大。戻るときは軽く縮小フェード。
class PopSlideFadeTransitionsBuilder extends PageTransitionsBuilder {
  const PopSlideFadeTransitionsBuilder();

  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    // 入場: 弾むようなカーブでスライドイン＋フェードイン
    final curved = CurvedAnimation(
      parent: animation,
      curve: Curves.easeOutCubic,
      reverseCurve: Curves.easeInCubic,
    );
    // 退場（下の画面）: 少し奥に引っ込んでフェードして奥行きを出す
    final secondaryCurved = CurvedAnimation(
      parent: secondaryAnimation,
      curve: Curves.easeOutCubic,
      reverseCurve: Curves.easeInCubic,
    );

    final slide = Tween<Offset>(
      begin: const Offset(0.14, 0.02),
      end: Offset.zero,
    ).animate(curved);
    final scale = Tween<double>(begin: 0.96, end: 1.0).animate(curved);

    final outSlide = Tween<Offset>(
      begin: Offset.zero,
      end: const Offset(-0.06, 0.0),
    ).animate(secondaryCurved);
    final outScale = Tween<double>(begin: 1.0, end: 0.97).animate(secondaryCurved);

    return SlideTransition(
      position: outSlide,
      child: ScaleTransition(
        scale: outScale,
        child: FadeTransition(
          opacity: Tween<double>(begin: 1.0, end: 0.85).animate(secondaryCurved),
          child: SlideTransition(
            position: slide,
            child: ScaleTransition(
              scale: scale,
              child: FadeTransition(opacity: curved, child: child),
            ),
          ),
        ),
      ),
    );
  }
}

/// 個別用: スライド＋フェードのルート。
Route<T> slideFadeRoute<T>(Widget page, {Duration? duration}) {
  return PageRouteBuilder<T>(
    transitionDuration: duration ?? const Duration(milliseconds: 320),
    reverseTransitionDuration: duration ?? const Duration(milliseconds: 260),
    pageBuilder: (_, __, ___) => page,
    transitionsBuilder: (context, animation, secondaryAnimation, child) =>
        const PopSlideFadeTransitionsBuilder()
            .buildTransitions(
      // PageRouteBuilder は PageRoute なのでキャストして流用
      ModalRoute.of(context) as PageRoute<T>,
      context,
      animation,
      secondaryAnimation,
      child,
    ),
  );
}

/// 個別用: 純粋なクロスフェード（ダイアログ的な画面や結果画面向き）。
Route<T> fadeRoute<T>(Widget page, {Duration? duration}) {
  return PageRouteBuilder<T>(
    transitionDuration: duration ?? const Duration(milliseconds: 280),
    reverseTransitionDuration: duration ?? const Duration(milliseconds: 220),
    pageBuilder: (_, __, ___) => page,
    transitionsBuilder: (_, animation, __, child) => FadeTransition(
      opacity: CurvedAnimation(parent: animation, curve: Curves.easeOutCubic),
      child: child,
    ),
  );
}
