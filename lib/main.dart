import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'screens/player_selection_screen.dart'; // 作成する画面
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

Future<void> main() async {
  //わからない　スキップ
  // Flutterアプリの初期化を保証
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    demoProjectId: "demo-project-id",
  );
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
      home: const PlayerSelectionScreen(),
      debugShowCheckedModeBanner: false, // デバッグバナーを非表示
    );
  }
}
