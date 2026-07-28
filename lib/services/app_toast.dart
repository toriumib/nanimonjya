import 'package:flutter/material.dart';

/// 画面をまたいで使える、軽いトースト表示。
///
/// リワード広告のお礼のように「どの画面から再生されたか分からない」通知を、
/// 呼び出し側に BuildContext を配らずに出すために使う。
class AppToast {
  AppToast._();

  /// MaterialApp に渡すキー。これ経由で SnackBar を出す。
  static final GlobalKey<ScaffoldMessengerState> messengerKey =
      GlobalKey<ScaffoldMessengerState>();

  /// 広告を最後まで見てくれた人への短いお礼。
  ///
  /// 報酬（コインや解放）の通知は各画面が別に出すので、ここは
  /// 「ありがとうございます」だけの控えめな1行にとどめる。
  static void thanksForAd(bool ja) {
    show(ja ? '🙏 ありがとうございます' : '🙏 Thank you!',
        duration: const Duration(milliseconds: 1600));
  }

  static void show(String message,
      {Duration duration = const Duration(seconds: 2)}) {
    final messenger = messengerKey.currentState;
    if (messenger == null) return; // まだアプリが構築されていない
    messenger.showSnackBar(
      SnackBar(
        content: Text(message, textAlign: TextAlign.center),
        duration: duration,
        behavior: SnackBarBehavior.floating,
        width: 220,
        backgroundColor: const Color(0xF22B5CA5),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
        ),
      ),
    );
  }
}
