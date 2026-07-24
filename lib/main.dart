import 'dart:ui' show PlatformDispatcher;
import 'package:flutter/foundation.dart'; // kIsWeb のため
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart'; // アプリ全体のフォント刷新
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'screens/home_shell.dart'; // タブシェル（ホーム）
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'firebase_options.dart';
import 'services/player_profile.dart'; // コイン/戦績のローカル状態
import 'models/cosmetics.dart'; // きせかえテーマの accent 色
import 'services/deep_link_service.dart'; // 合言葉リンクからの入室
import 'services/daily_reminder.dart'; // デイリーボーナスのリマインド通知
import 'services/sfx.dart'; // 効果音（起動時プリロードで即発音）
import 'services/interstitial_ad_helper.dart'; // 3プレイに1回のリザルト全画面広告
import 'widgets/route_transitions.dart'; // 全画面共通のスライド＋フェード遷移

// 多言語対応のために追加
import 'package:flutter_localizations/flutter_localizations.dart'; // ★追加★
import 'l10n/app_localizations.dart'; // ★追加: 生成されるファイルへのパス★

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  if (!kIsWeb) {
    // Crashlytics: 未捕捉のFlutterエラー/非同期エラーを自動送信（Web非対応）
    FlutterError.onError = FirebaseCrashlytics.instance.recordFlutterFatalError;
    PlatformDispatcher.instance.onError = (error, stack) {
      FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
      return true;
    };
    MobileAds.instance.initialize(); // google_mobile_ads は Web 非対応
    InterstitialAdHelper.instance.load(); // 3プレイに1回、リザルト表示時に先読み済みを表示
  }
  await PlayerProfile.instance.load(); // 戦績・コインを読み込み
  DeepLinkService.instance.init(); // 合言葉リンクからの入室を監視
  DailyReminder.instance.init(); // 🎁デイリーボーナスのリマインド通知（await不要）
  Sfx.instance.preload(); // 効果音を先読み（await不要・遅延ゼロ発音のため）
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // 選択中のきせかえテーマの accent 色でアプリ全体のテーマを組み立てる
  ThemeData _buildTheme(Color accent) {
    // 丸みのあるポップな書体をアプリ全体のデフォルトに（fontFamily未指定のTextへ自動継承される）
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
      textTheme: GoogleFonts.zenMaruGothicTextTheme(baseTextTheme),
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
      navigatorKey: DeepLinkService.navigatorKey, // ディープリンク遷移用
      navigatorObservers: [
        FirebaseAnalyticsObserver(analytics: FirebaseAnalytics.instance),
      ],
      title: '名前を覚えよう：なまえコール', // アプリタイトル (デフォルト値)
      theme: _buildTheme(accent),
      home: const HomeShell(),
      debugShowCheckedModeBanner: false,

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
