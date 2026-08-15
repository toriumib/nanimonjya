/// PROJECT NOA — 東戸塚・四十九光年の約束
///
/// 仕様は SPEC.md（エンジン）、物語は STORY.md が正。
/// 実装フェーズは SPEC 9章の順に進める。
library;

import 'package:flutter/material.dart';

import 'engine/config_store.dart';
import 'ui/title_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // 文字速度はいちばん最初の1行から効いてほしいので、先に読む。
  await ConfigStore.instance.load();
  runApp(const NoaApp());
}

class NoaApp extends StatelessWidget {
  const NoaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'PROJECT NOA',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF05080F),
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFFD4A24C),
          brightness: Brightness.dark,
        ),
      ),
      home: const TitleScreen(),
    );
  }
}
