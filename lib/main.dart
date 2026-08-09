import 'dart:ui' show PlatformDispatcher;
import 'package:flutter/foundation.dart'; // kIsWeb のため
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'screens/home_shell.dart'; // タブシェル（ホーム）
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'firebase_options.dart';
import 'services/app_analytics.dart';
import 'services/app_toast.dart'; // 広告のお礼など全画面共通のトースト
import 'services/bgm.dart'; // ホーム/ゲーム/リザルトのBGM
import 'services/push_service.dart'; // 既存ユーザーへのお知らせプッシュ
import 'services/player_profile.dart'; // コイン/戦績のローカル状態
import 'models/cosmetics.dart'; // きせかえテーマの accent 色
import 'services/deep_link_service.dart'; // 合言葉リンクからの入室
import 'services/app_open_ad_helper.dart';
import 'services/iap_service.dart'; // 💰 課金
import 'services/interstitial_ad_helper.dart';
import 'services/custom_roster_service.dart';
import 'services/memory_stats.dart'; // 📊 成績レポートの集計（速さ・正確性・定着率）
import 'services/sfx.dart'; // 効果音（起動時プリロードで即発音）
import 'widgets/route_transitions.dart'; // 全画面共通のスライド＋フェード遷移

// 多言語対応のために追加
import 'package:flutter_localizations/flutter_localizations.dart'; // ★追加★
import 'l10n/app_localizations.dart'; // ★追加: 生成されるファイルへのパス★

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  // ⏱ 初回起動の時刻を控える（初回ゲーム開始までの秒数を測るため）
  AppAnalytics.rememberFirstOpen();
  if (!kIsWeb) {
    // Crashlytics: 未捕捉のFlutterエラー/非同期エラーを自動送信（Web非対応）
    //
    // ⚠️ **フレームワークのエラーを「致命的」として記録しない。**
    //    以前は recordFlutterFatalError にしていたが、これは
    //    「アプリが死んだ」という意味ではなく、ただの分類。
    //    実際には FlutterError.onError が呼ばれてもアプリは動き続ける。
    //
    //    2026-08、Crashlytics のクラッシュのほぼ全部が
    //    「google_fonts が圏外でフォントを取りにいって失敗した」だった。
    //    アプリは落ちていないのに、クラッシュ率が66%まで落ちて見えていた。
    //    **本物のクラッシュがこのノイズに埋もれる**ので、分類を分ける。
    //
    //    致命的として送るのは、下の PlatformDispatcher で拾う
    //    「本当に捕まえられなかった非同期エラー」だけにする。
    FlutterError.onError = FirebaseCrashlytics.instance.recordFlutterError;
    PlatformDispatcher.instance.onError = (error, stack) {
      FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
      return true;
    };
    MobileAds.instance.initialize(); // google_mobile_ads は Web 非対応
    // ⚠️ **起動時に全画面広告を先読みしない。**
    //    2026-08 のレポートで、インタースティシャルは 56ロード/7表示、
    //    リワードインタースティシャルは 14ロード/0表示だった。
    //    起動しただけで読むと、ゲームを終えずに離脱した人のぶんが
    //    まるごと空振りになる。空振りはマッチ率と単価を下げる。
    //    いまは「出す見込みが立ってから読む」に変えてある
    //    （インタースティシャル＝あと1プレイで出る時点、
    //      リワードインタースティシャル＝よみものを開いた時点）。
    // 🚪 アプリ起動広告は**いったん止めている**。
    //    枠（/9282156275）も実装（services/app_open_ad_helper.dart）も
    //    あるので、再開したくなったら次の1行を戻すだけでよい。
    //    起動のたびに全画面が出るのは効きも大きいが嫌われ方も大きいので、
    //    ほかの手を整えてから判断する。
    AppOpenAdHelper.instance.start();
    InterstitialAdHelper.instance.load(); // 起動時にインタースティシャルを先読み
    IapService.instance.init(); // 💰 課金の初期化（await不要・非同期で進行）
    PushService.instance.init(); // 📣 既存ユーザーへのお知らせプッシュ（await不要）
  }
  await PlayerProfile.instance.load(); // 戦績・コインを読み込み
  await MemoryStats.instance.load(); // 📊 成績レポートの集計を読み込み
  // 🧑‍🎨 顔メモは出演プールに混ざるので、ゲームを始める前に読んでおく。
  //    以前は顔メモ画面とキャラデッキ画面でしか読んでおらず、
  //    その2画面を開かずに対戦を始めると登録した人が出てこなかった。
  await CustomRosterService.instance.load();
  // ※ゲーム中に recordMeeting/record を呼ぶので、遊び始める前に必ず読んでおく
  //   （読む前に書くと、あとから load() が上書きして記録が消える）
  DeepLinkService.instance.init(); // 合言葉リンクからの入室を監視
  // 🔔 通知の初期化は**起動時にやらない**。
  //    初回起動でいきなりOSの許可ダイアログが出て、遊ぶ前に
  //    判断を迫られる。断られるとAndroidでは二度と出せない。
  //    予約が必要になった時点（同意後）に DailyReminder が自分で初期化する。
  Sfx.instance.preload(); // 効果音を先読み（await不要・遅延ゼロ発音のため）
  // 💳 課金の初期化。購入ストリームを張って、未処理の購入や復元も拾う（await不要）
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  /// 🌐 Web版で保存された言語コードを Locale に変換。
  /// null のときは端末の言語に従う。
  static Locale? _webLocaleOf(String? code) => switch (code) {
    'en' => const Locale('en'),
    'ja' => const Locale('ja'),
    _ => null,
  };

  // 選択中のきせかえテーマの accent 色でアプリ全体のテーマを組み立てる
  ThemeData _buildTheme(Color accent) {
    // 丸みのあるポップな書体をアプリ全体のデフォルトに（fontFamily未指定のTextへ自動継承される）
    //
    // ⚠️ ここは以前 GoogleFonts.zenMaruGothicTextTheme() で**実行時に
    //    ダウンロード**していた。届くまでの間（Webでは届いても効かないことが
    //    あり、実質ずっと）CJKのフォールバック書体で描かれ、日本語の
    //    「、」「。」が行の中央に浮いて出ていた（報告されたバグ）。
    //    句読点は中国語系の書体だと中央、日本語書体だと左下に置かれる。
    //    フォントを同梱して、最初の1フレームから日本語書体で出るようにする。
    final baseTextTheme = ThemeData(useMaterial3: true).textTheme;
    return ThemeData(
      useMaterial3: true,
      // 全プラットフォームで push/pop を「スライド＋フェード＋微拡大」のポップな遷移に統一
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: PopSlideFadeTransitionsBuilder(),
          TargetPlatform.iOS: PopSlideFadeTransitionsBuilder(),
          TargetPlatform.fuchsia: PopSlideFadeTransitionsBuilder(),
          TargetPlatform.linux: PopSlideFadeTransitionsBuilder(),
          TargetPlatform.macOS: PopSlideFadeTransitionsBuilder(),
          TargetPlatform.windows: PopSlideFadeTransitionsBuilder(),
        },
      ),
      fontFamily: 'ZenMaruGothic',
      // 同梱フォントに無い文字（絵文字など）は端末の書体に回すが、
      // その順番でも日本語書体を先に見るようにしておく。
      fontFamilyFallback: const [
        'ZenMaruGothic',
        'Noto Sans JP',
        'Hiragino Sans',
        'Yu Gothic',
      ],
      textTheme: baseTextTheme.apply(fontFamily: 'ZenMaruGothic'),
      colorScheme: ColorScheme.fromSeed(
        seedColor: accent,
        primary: accent,
        secondary: const Color(0xFF4ECDC4), // ポップシアン
        tertiary: const Color(0xFFFFD93D), // サニーイエロー
      ),
      scaffoldBackgroundColor: const Color(0xFFFFF9EC), // クリーム色の背景
      visualDensity: VisualDensity.adaptivePlatformDensity,
      appBarTheme: AppBarTheme(
        backgroundColor: accent,
        foregroundColor: Colors.white,
        centerTitle: true,
        elevation: 0,
        titleTextStyle: const TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.w900,
          color: Colors.white,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: accent,
          foregroundColor: Colors.white,
          elevation: 6,
          shadowColor: accent.withOpacity(0.4),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          textStyle: const TextStyle(
            fontWeight: FontWeight.w900,
            fontSize: 16,
          ),
        ),
      ),
      cardTheme: CardThemeData(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        elevation: 4,
      ),
      chipTheme: ChipThemeData(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: const Color(0xFF7A3B00),
        contentTextStyle: const TextStyle(
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // ★きせかえテーマを選ぶとアプリ全体のボタン・AppBar色が変わる★
    return AnimatedBuilder(
      animation: PlayerProfile.instance,
      builder: (context, _) {
        final accent =
            homeThemeById(PlayerProfile.instance.selectedTheme).accent;
        return MaterialApp(
      scaffoldMessengerKey: AppToast.messengerKey, // 広告のお礼など全画面共通のトースト
      navigatorKey: DeepLinkService.navigatorKey, // ディープリンク遷移用
      navigatorObservers: [
        FirebaseAnalyticsObserver(analytics: FirebaseAnalytics.instance),
        Bgm.routeObserver, // ホームBGMの停止・再開に使う
      ],
      title: '名前を覚えよう：なまえがお', // アプリタイトル (デフォルト値)
      theme: _buildTheme(accent),
      home: const HomeShell(),
      debugShowCheckedModeBanner: false,

      // 🌐 Web版で言語を切り替えられるようにする。
      //    webLocaleCode が null なら端末の言語に従う。
      locale: _webLocaleOf(PlayerProfile.instance.webLocaleCode),
      // ★ここから追加: 多言語対応の設定★
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('en'), // 英語
        Locale('ja'), // 日本語
      ],
      // ★追加ここまで★
        );
      },
    );
  }
}
