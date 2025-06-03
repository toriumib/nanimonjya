import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // 数字入力制限のため
import 'game_screen.dart'; // 次の画面

class PlayerSelectionScreen extends StatefulWidget {
  const PlayerSelectionScreen({super.key});

  @override
  State<PlayerSelectionScreen> createState() => _PlayerSelectionScreenState();
}

class _PlayerSelectionScreenState extends State<PlayerSelectionScreen> {
  final TextEditingController _controller =
      TextEditingController(text: '2'); // 初期値を2に設定
  int _playerCount = 2; // デフォルトのプレイヤー人数

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _startGame() {
    final count = int.tryParse(_controller.text);
    if (count != null && count >= 2) {
      // GameScreen にプレイヤー人数を渡して遷移
      Navigator.pushReplacement(
        // この画面に戻れないように置き換え
        context,
        MaterialPageRoute(
          builder: (context) => GameScreen(playerCount: count),
        ),
      );
    } else {
      // エラーメッセージ表示
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('プレイヤーは2人以上で入力してください。')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('プレイヤー人数を選択'),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(30.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              const Text(
                'ゲームに参加する人数を入力してください (2人以上)',
                style: TextStyle(fontSize: 18),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              TextField(
                controller: _controller,
                keyboardType: TextInputType.number,
                // 数字のみ入力可能にする
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration: const InputDecoration(
                  labelText: '人数',
                  border: OutlineInputBorder(),
                  hintText: '2', // 例を表示
                ),
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 20),
                onSubmitted: (_) => _startGame(), // エンターキーで開始
              ),
              const SizedBox(height: 40),
              ElevatedButton(
                onPressed: _startGame,
                style: ElevatedButton.styleFrom(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 50, vertical: 15),
                  textStyle: const TextStyle(fontSize: 20),
                ),
                child: const Text('ゲーム開始'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
