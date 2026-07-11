import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;
import 'app_analytics.dart';

/// 「今日のデイリーボーナスまだだよ」を毎日夕方にローカル通知する。
/// Web非対応（kIsWebガード）。サーバ不要のスケジュール通知のみ。
class DailyReminder {
  DailyReminder._();
  static final DailyReminder instance = DailyReminder._();

  static const int _notificationId = 100;
  static const int _hour = 19; // 19時 = 帰宅後・夕食後のゴールデンタイム

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

  /// ボーナス受け取り済みなら今日の分をスキップして明日19時から予約し直す。
  Future<void> onBonusClaimed() => scheduleNext(skipToday: true);

  /// 次の19時（受け取り済みなら明日19時）に毎日リマインドを予約する。
  Future<void> scheduleNext({bool skipToday = false}) async {
    if (kIsWeb || !_initialized) return;
    try {
      await _plugin.cancel(_notificationId);
      final now = tz.TZDateTime.now(tz.local);
      var next = tz.TZDateTime(tz.local, now.year, now.month, now.day, _hour);
      if (skipToday || !next.isAfter(now)) {
        next = next.add(const Duration(days: 1));
      }

      await _plugin.zonedSchedule(
        _notificationId,
        '🎁 デイリーボーナスが待ってるよ！',
        '今日のログインボーナスまだ受け取ってないよ。連続ログインが途切れちゃう前に遊びに来てね🐶',
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
