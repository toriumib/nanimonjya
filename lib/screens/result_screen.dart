import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // Firestoreのために追加
import 'package:untitled/l10n/app_localizations.dart';
import 'player_selection_screen.dart'; // オフラインの最初の画面に戻るため
import 'online_game_screen.dart'; // オンラインの再戦に戻るため

// 多言語対応のために追加

class ResultScreen extends StatelessWidget {
  final List<int> scores;
  final int playerCount;
  final bool isOnline; // オンラインゲームの結果かどうか
  final String? roomId; // オンラインゲームの場合のルームID
  final String? myPlayerId; // オンラインゲームの場合の自分のプレイヤーID

  const ResultScreen({
    Key? key,
    required this.scores,
    required this.playerCount,
    this.isOnline = false, // デフォルトはオフライン
    this.roomId,
    this.myPlayerId,
  }) : super(key: key);

  // オンラインゲームのリセット処理
  Future<void> _resetOnlineGame(BuildContext context) async {
    if (!isOnline || roomId == null || myPlayerId == null) {
      return; // オンラインゲームでなければ何もしない
    }

    final DocumentReference roomRef = FirebaseFirestore.instance
        .collection('rooms')
        .doc(roomId!); // roomIdがnullでないことを保証

    try {
      await FirebaseFirestore.instance.runTransaction((transaction) async {
        DocumentSnapshot currentRoom = await transaction.get(roomRef);
        if (!currentRoom.exists) {
          throw Exception('ルームが見つかりません。');
        }

        Map<String, dynamic> data = currentRoom.data() as Map<String, dynamic>;

        // 既存のプレイヤーリストと画像URLを取得
        List<dynamic> players = data['players'] ?? [];
        List<dynamic> imageUrls = data['imageUrls'] ?? [];
        // ゲームモードも引き継ぐ
        String gameMode = data['gameMode'] as String? ?? 'voice';

        // スコアをリセット
        Map<String, int> initialScores = {};
        for (String playerId in players.cast<String>()) {
          initialScores[playerId] = 0;
        }

        // プレイヤーの順番をリシャッフルして設定
        List<String> shuffledPlayerOrder = List<String>.from(players)
          ..shuffle();

        // ルームの状態をwaitingに戻す
        transaction.update(roomRef, {
          'status': 'waiting',
          'deck': [],
          'fieldCards': [],
          'seenImages': [],
          'scores': initialScores, // スコアをリセット
          'currentCard': null,
          'isFirstAppearance': true,
          'canSelectPlayer': false,
          'turnCount': 0,
          'gameStarted': false, // ゲーム開始フラグもリセット
          'characterNames': {}, // キャラクター名をリセット
          'playerOrder': shuffledPlayerOrder, // プレイヤーの順番をリセット
          'currentPlayerIndex': 0, // インデックスをリセット
          'playersAttemptedCurrentCard': {}, // 回答済みプレイヤーをリセット
          'gameMode': gameMode, // ゲームモードは維持
          // imageUrlsとplayersリストは保持したまま
        });
      });

      // リセットが成功したらオンラインゲーム画面に戻る
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(
          builder: (context) => OnlineGameScreen(
            roomId: roomId!,
            myPlayerId: myPlayerId!,
            isVoiceMode: isOnline ? true : false,
          ), // isVoiceModeを適切に渡す
        ), // スタックをクリア
        (Route<dynamic> route) => false,
      );
    } catch (e) {
      debugPrint('オンラインゲームのリセットに失敗しました: $e');
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('再戦の準備に失敗しました: ${e.toString()}')));
    }
  }

  @override
  Widget build(BuildContext context) {
    // 多言語対応の文字列にアクセスするためのインスタンス
    final localizations = AppLocalizations.of(context)!; // ★追加★

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
      winnerText = localizations.noWinner; // ★修正★
    } else if (winners.length == 1) {
      winnerText = localizations.playerScore(winners[0] + 1, ''); // 勝者番号を渡す
      winnerText = localizations.winner(
        localizations.playerScore(winners[0] + 1, ''),
      ); // ★修正★
    } else {
      // 勝者のインデックスに+1して表示用文字列リスト作成
      final winnerNumbers = winners
          .map((index) => localizations.playerScore(index + 1, '')) // プレイヤーN
          .toList();
      winnerText = localizations.tie(winnerNumbers.join('と')); // ★修正★
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(localizations.gameResult), // ★修正★
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
                winnerText, // ★修正★
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 40),

              // 最終スコア表示
              Text(
                localizations.finalScore, // ★修正★
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 15),
              Card(
                // スコアを見やすくカードで囲む
                elevation: 3,
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    vertical: 15.0,
                    horizontal: 25.0,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min, // 内容に合わせたサイズ
                    children: List.generate(playerCount, (index) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 5.0),
                        child: Text(
                          localizations.playerScore(
                            index + 1,
                            scores[index],
                          ), // ★修正★
                          style: const TextStyle(fontSize: 18),
                        ),
                      );
                    }),
                  ),
                ),
              ),

              const SizedBox(height: 50),

              // 再戦ボタン / もう一度遊ぶボタン
              ElevatedButton(
                onPressed: () {
                  if (isOnline) {
                    _resetOnlineGame(context); // オンライン再戦処理
                  } else {
                    // オフラインゲームの場合はプレイヤー選択画面に戻る（以前の画面は全て削除）
                    Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const PlayerSelectionScreen(),
                      ),
                      (Route<dynamic> route) => false, // スタックをクリア
                    );
                  }
                },
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 40,
                    vertical: 15,
                  ),
                  textStyle: const TextStyle(fontSize: 18),
                ),
                child: Text(
                  isOnline
                      ? localizations.playAgainSameMembers
                      : localizations.playAgain,
                ), // ★修正★
              ),
            ],
          ),
        ),
      ),
    );
  }
}
