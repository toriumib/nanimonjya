import 'package:flutter/material.dart';
import 'package:untitled/l10n/app_localizations.dart';
import 'player_selection_screen.dart'; // オフラインモード
import 'online_game_lobby_screen.dart'; // オンラインモード

// 多言語対応のために追加

class TopScreen extends StatefulWidget {
  const TopScreen({super.key});

  @override
  State<TopScreen> createState() => _TopScreenState();
}

class _TopScreenState extends State<TopScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800), // アニメーションの時間
    );
    _animation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeOut, // アニメーションのカーブ
      ),
    );
    _controller.forward(); // アニメーションを開始
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // 多言語対応の文字列にアクセスするためのインスタンス
    final localizations = AppLocalizations.of(context)!; // ★追加★

    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            // アプリタイトル
            Padding(
              padding: const EdgeInsets.only(bottom: 50.0),
              child: Text(
                localizations.appTitle, // ★修正★
                style: TextStyle(
                  fontSize: 48,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).primaryColor,
                  shadows: [
                    Shadow(
                      offset: const Offset(2.0, 2.0),
                      blurRadius: 4.0,
                      color: Colors.black.withOpacity(0.3),
                    ),
                  ],
                ),
                textAlign: TextAlign.center,
              ),
            ),
            // フェードインアニメーション付きのボタン
            FadeTransition(
              opacity: _animation,
              child: Column(
                children: [
                  ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const OnlineGameLobbyScreen(),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 50,
                        vertical: 20,
                      ),
                      textStyle: const TextStyle(fontSize: 22),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                      elevation: 8,
                    ),
                    child: Text(localizations.playOnline), // ★修正★
                  ),
                  const SizedBox(height: 30),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const PlayerSelectionScreen(),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 50,
                        vertical: 20,
                      ),
                      textStyle: const TextStyle(fontSize: 22),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                      elevation: 8,
                    ),
                    child: Text(localizations.playOffline), // ★修正★
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
