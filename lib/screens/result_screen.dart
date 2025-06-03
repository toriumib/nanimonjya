import 'package:flutter/material.dart';
import 'player_selection_screen.dart'; // 最初の画面に戻るため

class ResultScreen extends StatelessWidget {
  final List<int> scores;
  final int playerCount;

  const ResultScreen({
    Key? key,
    required this.scores,
    required this.playerCount,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // 最高スコアと勝者を決定
    int maxScore = 0;
    List<int> winners = [];
    for (int i = 0; i < scores.length; i++) {
      if (scores[i] > maxScore) {
        maxScore = scores[i];
        winners = [i]; // 新しい最高得点者（インデックス）
      } else if (scores[i] == maxScore && scores[i] > 0) {
        // 0点同士は勝者としない場合
        winners.add(i); // 同点の勝者を追加
      }
    }

    // 勝者表示テキストを作成
    String winnerText;
    if (winners.isEmpty || maxScore == 0) {
      winnerText = '勝者なし';
    } else if (winners.length == 1) {
      winnerText = 'プレイヤー ${winners[0] + 1} の勝利！';
    } else {
      // 勝者のインデックスに+1して表示用文字列リスト作成
      final winnerNumbers =
          winners.map((index) => 'プレイヤー ${index + 1}').toList();
      winnerText = '${winnerNumbers.join(' と ')} の勝利！ (同点)';
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('ゲーム結果'),
        automaticallyImplyLeading: false, // 戻るボタン非表示
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              // 勝者表示
              Text(
                '🏆 $winnerText 🏆',
                style: Theme.of(context)
                    .textTheme
                    .headlineSmall
                    ?.copyWith(fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 40),

              // 最終スコア表示
              const Text(
                '-- 最終スコア --',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 15),
              Card(
                // スコアを見やすくカードで囲む
                elevation: 3,
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                      vertical: 15.0, horizontal: 25.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min, // 内容に合わせたサイズ
                    children: List.generate(playerCount, (index) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 5.0),
                        child: Text(
                          'プレイヤー ${index + 1}: ${scores[index]} 点',
                          style: const TextStyle(fontSize: 18),
                        ),
                      );
                    }),
                  ),
                ),
              ),

              const SizedBox(height: 50),

              // もう一度遊ぶボタン
              ElevatedButton(
                onPressed: () {
                  // プレイヤー選択画面に戻る（以前の画面は全て削除）
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(
                        builder: (context) => const PlayerSelectionScreen()),
                    (Route<dynamic> route) => false, // スタックをクリア
                  );
                },
                style: ElevatedButton.styleFrom(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                  textStyle: const TextStyle(fontSize: 18),
                ),
                child: const Text('もう一度遊ぶ'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
