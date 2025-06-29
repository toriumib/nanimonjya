import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // 数字入力制限のため
import 'game_screen.dart'; // 次の画面

// 多言語対応のために追加
import 'package:untitled/l10n/app_localizations.dart'; // ★パス修正済み★

class PlayerSelectionScreen extends StatefulWidget {
  const PlayerSelectionScreen({super.key});

  @override
  State<PlayerSelectionScreen> createState() => _PlayerSelectionScreenState();
}

class _PlayerSelectionScreenState extends State<PlayerSelectionScreen> {
  // プレイヤー人数を保持する変数。初期値は2人
  int _playerCount = 2;

  // ゲーム開始処理
  void _startGame() {
    // GameScreen にプレイヤー人数を渡して遷移
    Navigator.pushReplacement(
      // この画面に戻れないように置き換え
      context,
      MaterialPageRoute(
        builder: (context) => GameScreen(playerCount: _playerCount),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // 多言語対応の文字列にアクセスするためのインスタンス
    final localizations = AppLocalizations.of(context)!; // ★追加★

    return Scaffold(
      appBar: AppBar(title: Text(localizations.playerCountSelection)), // ★修正★
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(30.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Text(
                localizations.selectPlayerCountPrompt, // ★修正★
                style: const TextStyle(fontSize: 18),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              // プレイヤー人数選択ボタン
              Wrap(
                spacing: 10.0, // ボタン間の横方向スペース
                runSpacing: 10.0, // ボタン間の縦方向スペース
                alignment: WrapAlignment.center,
                children: List.generate(5, (index) {
                  // 2人から6人までなので、6 - 2 + 1 = 5個のボタンを生成
                  int count = index + 2; // プレイヤー人数は2から始まる
                  return ElevatedButton(
                    onPressed: () {
                      setState(() {
                        _playerCount = count; // 選択された人数を更新
                      });
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _playerCount == count
                          ? Colors
                                .blueAccent // 選択中のボタンの色
                          : Colors.grey, // それ以外のボタンの色
                      padding: const EdgeInsets.symmetric(
                        horizontal: 25,
                        vertical: 15,
                      ),
                      textStyle: const TextStyle(fontSize: 20),
                    ),
                    child: Text(localizations.players(count)), // ★修正★
                  );
                }),
              ),
              const SizedBox(height: 40),
              ElevatedButton(
                onPressed: _startGame,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 50,
                    vertical: 15,
                  ),
                  textStyle: const TextStyle(fontSize: 20),
                ),
                child: Text(localizations.gameStart), // ★修正★
              ),
            ],
          ),
        ),
      ),
    );
  }
}
