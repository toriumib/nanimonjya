import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import 'app_analytics.dart';

/// 📣 既存ユーザーへのお知らせプッシュ（Firebase Cloud Messaging）。
///
/// これまでの通知は端末内で予約する「練習リマインド」だけで、
/// **すでにインストールしている人へこちらから知らせる手段が無かった**。
/// アップデートのお知らせやイベント告知を Firebase コンソールから
/// 送れるようにする。
///
/// 使い方（サーバー不要）:
///   Firebase コンソール → Messaging → 新しいキャンペーン → 通知
///   → ターゲットに「トピック」を選び [topicAll] を指定して送信
///
/// トピックを使うのは、端末トークンを自前で集めて保存しなくて済むから。
/// 「全員に送る」だけならこれで足りる。
///
/// ⚠️ 送りすぎは通知オフ・アンインストールに直結する。
/// 頻度は多くても月1〜2回、内容のある告知だけにすること。
class PushService {
  PushService._();
  static final PushService instance = PushService._();

  /// 全員に届けるためのトピック名。Firebase コンソールで指定する。
  static const String topicAll = 'all_users';

  /// アプリ表示中に受け取った通知を出すためのローカル通知チャンネル。
  /// （FCMは「アプリが前面にあるとき」は自動では通知を出さない）
  static const AndroidNotificationChannel _channel = AndroidNotificationChannel(
    'push_news',
    'お知らせ',
    description: 'アップデートやイベントのお知らせ',
    importance: Importance.defaultImportance,
  );

  final _local = FlutterLocalNotificationsPlugin();
  bool _ready = false;

  /// OSの通知許可を求める。**アプリ内で同意をもらってからだけ**呼ぶこと。
  ///
  /// Android の POST_NOTIFICATIONS はアプリ全体で1つなので、
  /// ここと [DailyReminder.requestPermission] のどちらかが通れば両方届く。
  /// iOS は APNs の登録が別に要るので、こちらも呼んでおく。
  Future<void> askPermission() async {
    if (kIsWeb) return;
    try {
      await FirebaseMessaging.instance.requestPermission();
    } catch (e) {
      debugPrint('PushService.askPermission error: $e');
    }
  }

  Future<void> init() async {
    // Web は別途VAPIDキーの設定が要るうえ、通知許可の体験も異なるので対象外
    if (kIsWeb || _ready) return;
    _ready = true;
    try {
      final messaging = FirebaseMessaging.instance;

      // ⚠️ **ここで許可を求めてはいけない。**
      //    起動直後に何の説明もなくOSのダイアログが出て、まだ何も
      //    遊んでいない人に判断を迫ることになる。Androidは一度断られると
      //    二度と出せない。実際、初回起動の最初の画面で出ていた。
      //    許可は、アプリ内で「受け取る」と言ってもらってから
      //    [askPermission] で求める（services/notify_prompt.dart）。

      // 前面表示中の通知を自分で出すためのチャンネルを作る
      await _local
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(_channel);

      // 全員向けトピックを購読（これでコンソールから一斉送信できる）
      await messaging.subscribeToTopic(topicAll);

      // アプリを開いている最中に届いた通知は自分で表示する
      FirebaseMessaging.onMessage.listen(_showForeground);

      // 通知をタップして開かれたときの計測
      FirebaseMessaging.onMessageOpenedApp.listen((_) {
        AppAnalytics.notificationTapped();
      });
      final initial = await messaging.getInitialMessage();
      if (initial != null) AppAnalytics.notificationTapped();
    } catch (e) {
      // 通知が使えなくてもゲーム本体には影響させない
      debugPrint('PushService init failed: $e');
    }
  }

  Future<void> _showForeground(RemoteMessage message) async {
    final n = message.notification;
    if (n == null) return;
    try {
      await _local.show(
        n.hashCode,
        n.title,
        n.body,
        NotificationDetails(
          android: AndroidNotificationDetails(
            _channel.id,
            _channel.name,
            channelDescription: _channel.description,
            importance: Importance.defaultImportance,
          ),
          iOS: const DarwinNotificationDetails(),
        ),
      );
    } catch (e) {
      debugPrint('foreground push show failed: $e');
    }
  }

  /// お知らせを受け取らないようにする（設定でオフにしたい場合用）。
  Future<void> unsubscribe() async {
    if (kIsWeb) return;
    try {
      await FirebaseMessaging.instance.unsubscribeFromTopic(topicAll);
    } catch (e) {
      debugPrint('unsubscribe failed: $e');
    }
  }

  Future<void> resubscribe() async {
    if (kIsWeb) return;
    try {
      await FirebaseMessaging.instance.subscribeToTopic(topicAll);
    } catch (e) {
      debugPrint('resubscribe failed: $e');
    }
  }
}
