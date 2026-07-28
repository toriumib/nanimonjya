import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;
import 'app_analytics.dart';
import 'player_profile.dart';

/// 「今日のデイリーボーナスまだだよ」を毎日夕方にローカル通知する。
/// Web非対応（kIsWebガード）。サーバ不要のスケジュール通知のみ。
class DailyReminder {
  DailyReminder._();
  static final DailyReminder instance = DailyReminder._();

  static const int _notificationId = 100;
  /// 既定の時刻。実際にはユーザーが選んだ [PlayerProfile.reminderHour] を使う。
  /// 決められた時刻より「自分で決めた時刻」のほうが生活の合図と結びつきやすい。
  static const int defaultHour = 19;

  final _plugin = FlutterLocalNotificationsPlugin();
  bool _initialized = false;

  Future<void> init() async {
    if (kIsWeb || _initialized) return;
    tzdata.initializeTimeZones();
    const settings = InitializationSettings(
      android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      iOS: DarwinInitializationSettings(),
    );
    await _plugin.initialize(
      settings,
      onDidReceiveNotificationResponse: (_) =>
          AppAnalytics.notificationTapped(),
    );
    _initialized = true;
    // Android 13+ は通知のランタイム許可が必要（拒否されてもゲームは通常動作）
    await _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();
    await scheduleNext();
  }

  /// ボーナス受け取り済みなら今日の分をスキップして翌日から予約し直す。
  Future<void> onBonusClaimed() => scheduleNext(skipToday: true);

  /// 次の指定時刻（受け取り済みなら翌日）に毎日リマインドを予約する。
  Future<void> scheduleNext({bool skipToday = false}) async {
    if (kIsWeb || !_initialized) return;
    try {
      await _plugin.cancel(_notificationId);
      final now = tz.TZDateTime.now(tz.local);
      final hour = PlayerProfile.instance.reminderHour;
      var next = tz.TZDateTime(tz.local, now.year, now.month, now.day, hour);
      if (skipToday || !next.isAfter(now)) {
        next = next.add(const Duration(days: 1));
      }

      await _plugin.zonedSchedule(
        _notificationId,
        '🧠 今日の名前トレーニングの時間です',
        '3分でOK。昨日おぼえた顔と名前、まだ出てきますか？（ログインボーナスも受け取れます🪙）',
        next,
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'daily_reminder',
            'デイリーボーナスのお知らせ',
            channelDescription: '毎日のログインボーナスのリマインダー',
            importance: Importance.defaultImportance,
          ),
          iOS: DarwinNotificationDetails(),
        ),
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        matchDateTimeComponents: DateTimeComponents.time, // 毎日同時刻に繰り返し
      );
    } catch (e) {
      debugPrint('DailyReminder schedule error: $e');
    }
  }
}
