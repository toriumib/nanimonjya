import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'screens/top_screen.dart'; // トップ画面をインポート
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
// import 'package:flutter_localizations/flutter_localizations.dart'; // ★追加★
// import 'package:untitled/app_localizations.dart'; // ★追加: 生成されるファイルへのパス★

Future<void> main() async {
  //わからない　スキップ
  // Flutterアプリの初期化を保証
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  // Google Mobile Ads SDK を初期化
  MobileAds.instance.initialize();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ナンジャモンジャ風ゲーム', // アプリタイトル変更
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      // 最初にプレイヤー人数選択画面を表示
      home: const TopScreen(), // 最初の画面をTopScreenに変更
      debugShowCheckedModeBanner: false, // デバッグバナーを非表示
      //       // ★ここから追加: 多言語対応の設定★
      // localizationsDelegates: const [
      //   AppLocalizations.delegate,
      //   GlobalMaterialLocalizations.delegate,
      //   GlobalWidgetsLocalizations.delegate,
      //   GlobalCupertinoLocalizations.delegate,
      // ],
      // supportedLocales: const [
      //   Locale('en'), // 英語
      //   Locale('ja'), // 日本語
      // ],
      // // ★追加ここまで★
    );
  }
}
