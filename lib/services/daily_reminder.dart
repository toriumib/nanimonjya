import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;
import 'app_analytics.dart';
import 'review_queue.dart';
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
    // ⚠️ ここで OSの許可を求めてはいけない。
    //    以前は起動直後に何の説明もなく許可ダイアログを出していたが、
    //    Androidは一度断られると二度と出せない。断られた時点でその人には
    //    永久に合図を送れなくなり、7日維持率を上げる手立てが1つ消える。
    //    許可を求めるのは、アプリ内で「受け取る」と言ってもらってから
    //    （[requestPermission] を呼ぶのは services/notify_prompt.dart）。
    if (PlayerProfile.instance.notifyOptIn) await scheduleNext();
  }

  /// OSの通知許可を求める。**アプリ内で同意をもらってからだけ**呼ぶこと。
  /// 許可されたら true。
  Future<bool> requestPermission() async {
    if (kIsWeb) return false;
    if (!_initialized) await init();
    try {
      final android = _plugin.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();
      if (android != null) {
        return await android.requestNotificationsPermission() ?? false;
      }
      final ios = _plugin.resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin>();
      if (ios != null) {
        return await ios.requestPermissions(alert: true, badge: true, sound: true) ??
            false;
      }
      return false;
    } catch (e) {
      debugPrint('requestPermission error: $e');
      return false;
    }
  }

  /// 予約をすべて取り消す（通知をOFFにしたとき）。
  Future<void> cancelAll() async {
    if (kIsWeb || !_initialized) return;
    try {
      await _plugin.cancel(_notificationId);
    } catch (_) {}
  }

  /// ボーナス受け取り済みなら今日の分をスキップして翌日から予約し直す。
  Future<void> onBonusClaimed() => scheduleNext(skipToday: true);

  /// 次の指定時刻（受け取り済みなら翌日）に毎日リマインドを予約する。
  Future<void> scheduleNext({bool skipToday = false}) async {
    if (kIsWeb || !_initialized) return;
    // 同意していない人には予約しない
    if (!PlayerProfile.instance.notifyOptIn) return;
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
        _title(),
        _body(),
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

  /// 通知の見出し。
  ///
  /// 「アプリを開いてください」ではなく「あの人たち、まだ思い出せますか？」の
  /// 形にする。忘れかけている具体的な相手がいると分かるほうが戻る理由になる。
  String _title() {
    final due = ReviewQueue.instance.dueCount();
    if (due > 0) return '🧠 きのう覚えた$due人、まだ思い出せますか？';
    return '🧠 今日の名前トレーニングの時間です';
  }

  String _body() {
    final due = ReviewQueue.instance.dueCount();
    if (due > 0) {
      return '時間をおいてから思い出すと定着すると言われています。3分でひと回りできます。';
    }
    return '3分でOK。昨日おぼえた顔と名前、まだ出てきますか？（ログインボーナスも受け取れます🪙）';
  }
}
