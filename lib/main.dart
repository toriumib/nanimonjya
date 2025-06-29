import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'screens/top_screen.dart'; // トップ画面をインポート
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

// 多言語対応のために追加
import 'package:flutter_localizations/flutter_localizations.dart'; // ★追加★
import 'l10n/app_localizations.dart'; // ★追加: 生成されるファイルへのパス★

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  MobileAds.instance.initialize();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      // title は MaterialApp のラベルであり、通常はAppLocalizationsを使わず固定値で良い場合が多いが、ここも対応可能
      title: 'ナンジャモンジャ風ゲーム', // アプリタイトル (デフォルト値)
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: const TopScreen(),
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
  }
}
