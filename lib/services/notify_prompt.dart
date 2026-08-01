import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../l10n/meta_strings.dart';
import 'app_analytics.dart';
import 'daily_reminder.dart';
import 'player_profile.dart';
import 'sfx.dart';

/// 🔔 練習リマインドの「ソフトアスク」。
///
/// **なぜアプリ内で先に聞くのか**
///
/// 7日維持率が伸びない一番の理由は、思い出すきっかけが無いまま忘れられること。
/// 通知はこちらから出せる唯一の合図なので、OSの許可を取れるかどうかが
/// そのまま維持率の上限になる。
///
/// ところがAndroidの通知許可は**一度断られると二度と出せない**。
/// 以前は起動直後、まだ何の価値も伝わっていない状態でいきなりOSの
/// ダイアログを出していたので、断られた人にはその後どうやっても
/// 声をかけられなくなっていた。
///
/// そこで、
/// 1. 1ゲーム終えて「覚えられた／覚えられなかった」を体験した直後に
/// 2. アプリ内のダイアログで「なぜ必要か」を説明してから意思を聞き
/// 3. 「受け取る」と言ってくれた人にだけOSの許可を求める
/// という順番にする。断られてもOSの許可は消費されないので、
/// 次の機会にもう一度声をかけられる。
///
/// 断り方も大事なので、「あとで」を選んだ人にはしつこくしない
/// （[_maxAttempts] 回まで、[_gapGames] ゲーム空けて）。

/// お伺いを出す最低プレイ回数。1ゲーム終えてから。
const int _minGames = 1;

/// 次に聞くまでに必要な追加プレイ数。
const int _gapGames = 5;

/// 聞く上限回数。これ以上は二度と出さない。
const int _maxAttempts = 2;

/// 条件を満たしていれば、練習リマインドのお伺いを出す。
///
/// 良いタイミング（ゲームを最後まで終えた直後）から呼ぶこと。
/// 表示したら true。
/// お伺いを出してよい状態か。
///
/// 「しつこくしない」は手で確かめにくく、間違えると一番嫌われるところなので、
/// UIから切り離してテストできる形にしてある（test/notify_prompt_test.dart）。
bool shouldAskNotify({
  required bool optIn,
  required int totalGames,
  required int promptCount,
  required int promptedAtGames,
  required int reviewPromptCount,
  required int reviewPromptedAtGames,
}) {
  if (optIn) return false; // すでに受け取ってくれている
  if (totalGames < _minGames) return false;
  if (promptCount >= _maxAttempts) return false;
  // 一度「あとで」と言われたら、しばらく遊んでもらってからでないと聞かない
  if (promptCount > 0 && totalGames - promptedAtGames < _gapGames) return false;
  // レビュー依頼と同じ場面で2枚続けて出すと、どちらも雑に閉じられる
  if (reviewPromptCount > 0 && reviewPromptedAtGames == totalGames) {
    return false;
  }
  return true;
}

Future<bool> maybeAskNotify(BuildContext context) async {
  if (kIsWeb) return false; // Webはローカル通知に非対応
  final p = PlayerProfile.instance;
  if (!shouldAskNotify(
    optIn: p.notifyOptIn,
    totalGames: p.totalGames,
    promptCount: p.notifyPromptCount,
    promptedAtGames: p.notifyPromptedAtGames,
    reviewPromptCount: p.reviewPromptCount,
    reviewPromptedAtGames: p.reviewPromptedAtGames,
  )) {
    return false;
  }
  if (!context.mounted) return false;

  await p.markNotifyPrompted();
  final m = MetaStrings.of(context);
  AppAnalytics.notifyPrompt(shown: true);

  final accepted = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Text(
        m.notifyAskTitle,
        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(m.notifyAskWhy,
              style: const TextStyle(fontSize: 14, height: 1.6)),
          const SizedBox(height: 8),
          Text(m.notifyAskWhen(PlayerProfile.instance.reminderHour),
              style: const TextStyle(fontSize: 14, height: 1.6)),
          const SizedBox(height: 8),
          Text(m.notifyAskEscape,
              style: const TextStyle(fontSize: 12, color: Colors.black54)),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(dialogContext, false),
          child: Text(m.notifyAskLater),
        ),
        ElevatedButton(
          onPressed: () => Navigator.pop(dialogContext, true),
          child: Text(m.notifyAskAccept),
        ),
      ],
    ),
  );

  if (accepted != true) {
    AppAnalytics.notifyPrompt(shown: false, accepted: false);
    return true;
  }

  Sfx.instance.pop();
  // ここで初めてOSの許可を求める。断られたらONにはしない
  //（許可が無いのに「お知らせします」と表示だけ残るのを避ける）。
  final granted = await DailyReminder.instance.requestPermission();
  await p.setNotifyOptIn(granted);
  AppAnalytics.notifyPrompt(shown: false, accepted: true, granted: granted);
  if (context.mounted) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(granted
            ? m.reminderSaved(m.hourLabel(p.reminderHour))
            : m.notifyDeniedHint),
      ),
    );
  }
  return true;
}
