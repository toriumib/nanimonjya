import 'dart:math';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // Firestoreのために追加
import 'package:confetti/confetti.dart';
import 'package:just_audio/just_audio.dart'; // リザルトBGM用
import 'package:untitled/l10n/app_localizations.dart';
import 'package:url_launcher/url_launcher.dart';
import '../l10n/meta_strings.dart';
import '../models/cosmetics.dart'; // 称号のランクアップ判定
import '../services/player_profile.dart';
import '../services/reward_ad_helper.dart';
import '../services/ranking_service.dart'; // レート変動の表示定数
import '../services/sfx.dart';
import 'top_screen.dart'; // ホームへ確実に戻るため
import 'player_selection_screen.dart'; // オフラインの最初の画面に戻るため
import 'online_game_screen.dart'; // オンラインの再戦に戻るため
import 'profile_screen.dart'; // マイページ・戦績（トロフィー）への導線

class ResultScreen extends StatefulWidget {
  final List<int> scores;
  final int playerCount;
  final bool isOnline; // オンラインゲームの結果かどうか
  final String? roomId; // オンラインゲームの場合のルームID
  final String? myPlayerId; // オンラインゲームの場合の自分のプレイヤーID
  final int? myIndex; // scores の中で自分のスコアの位置（オンラインのみ）
  final bool isRandomMatch; // ランダムマッチだったか
  final bool opponentLeft; // 相手が離脱してこちらの勝ちになったか
  final bool vsCpu; // 🤖 CPU対戦（プレイヤー1=あなた, 2=CPU）

  const ResultScreen({
    Key? key,
    required this.scores,
    required this.playerCount,
    this.isOnline = false, // デフォルトはオフライン
    this.roomId,
    this.myPlayerId,
    this.myIndex,
    this.isRandomMatch = false,
    this.opponentLeft = false,
    this.vsCpu = false,
  }) : super(key: key);

  @override
  State<ResultScreen> createState() => _ResultScreenState();
}

class _ResultScreenState extends State<ResultScreen> {
  late final ConfettiController _confetti;
  final RewardAdHelper _rewardAd = RewardAdHelper();
  final AudioPlayer _resultBgm = AudioPlayer(); // シャイニングスターBGM

  int _earnedThisGame = 0; // 今回のゲームで獲得したコイン（2倍の対象）
  int _sessionStreak = 0;
  int _onlineWinBonus = 0; // オンライン勝利ボーナス
  bool _doubled = false; // リワード広告で2倍済みか
  final int _tipSeed = Random().nextInt(100000); // 表示するTipsを固定するための種

  // オンラインで自分が勝ったか（myIndex が渡されている時のみ判定可能）
  bool get _wonOnline {
    if (widget.opponentLeft) return true; // 相手が離脱＝こちらの勝ち
    if (!widget.isOnline || widget.myIndex == null) return false;
    final i = widget.myIndex!;
    if (i < 0 || i >= widget.scores.length) return false;
    final maxScore = widget.scores.reduce((a, b) => a > b ? a : b);
    return maxScore > 0 && widget.scores[i] == maxScore;
  }

  @override
  void initState() {
    super.initState();
    _confetti = ConfettiController(duration: const Duration(seconds: 2));
    _rewardAd.load();
    _startResultBgm(); // 🎵 シャイニングスター再生
    // フレーム描画後に報酬付与＆演出（context/localeが使える状態で行う）
    WidgetsBinding.instance.addPostFrameCallback((_) => _grantRewards());
    // ※インタースティシャル（全画面広告）は無効化中。復活させたい場合は
    //   InterstitialAdHelper.instance.onGameFinished() をここで呼ぶ。
  }

  // リザルトBGM: 選択中の曲（デフォルトは魔王魂「シャイニングスター」）をループ再生
  Future<void> _startResultBgm() async {
    try {
      await _resultBgm.setAsset(
        'assets/audio/${PlayerProfile.instance.selectedResultBgm}',
      );
      _resultBgm.setLoopMode(LoopMode.one);
      _resultBgm.setVolume(0.6);
      _resultBgm.play();
    } catch (e) {
      debugPrint('リザルトBGMの再生に失敗: $e');
    }
  }

  Future<void> _grantRewards() async {
    final profile = PlayerProfile.instance;
    final maxScore = widget.scores.isEmpty
        ? 0
        : widget.scores.reduce((a, b) => a > b ? a : b);

    final titleBefore = currentTitle(profile.lifetimeCoins);
    final reward = await profile.recordGamePlayed(maxScore);
    // オンライン対戦の戦績記録（勝利ボーナス付き）。トロフィー判定は
    // 直後の refreshAchievements がまとめて行う。
    int onlineBonus = 0;
    if (widget.isOnline) {
      onlineBonus = await profile.recordOnlineGame(
        won: _wonOnline,
        isRandomMatch: widget.isRandomMatch,
      );
    }
    final newAchievements = await profile.refreshAchievements();
    final titleAfter = currentTitle(profile.lifetimeCoins);

    if (!mounted) return;
    setState(() {
      _earnedThisGame = reward.total + onlineBonus;
      _onlineWinBonus = onlineBonus;
      _sessionStreak = reward.sessionStreak;
    });
    // 勝者がいれば盛大に演出（BGMが流れているので紙吹雪のみ）
    if (maxScore > 0) {
      _confetti.play();
    }

    // 実績解除・称号ランクアップを順番にトースト表示（喜びの積み重ね演出）
    final m = MetaStrings.of(context);
    final messenger = ScaffoldMessenger.of(context);
    int delayMs = 800;
    for (final id in newAchievements) {
      Future.delayed(Duration(milliseconds: delayMs), () {
        if (!mounted) return;
        Sfx.instance.coin();
        messenger.showSnackBar(
          SnackBar(
            content: Text(m.achievementUnlocked(m.achTitle(id))),
            duration: const Duration(seconds: 2),
          ),
        );
      });
      delayMs += 2200;
    }
    if (titleAfter.requiredLifetimeCoins > titleBefore.requiredLifetimeCoins) {
      Future.delayed(Duration(milliseconds: delayMs), () {
        if (!mounted) return;
        Sfx.instance.victory();
        _confetti.play(); // 称号アップはもう一度紙吹雪！
        messenger.showSnackBar(
          SnackBar(
            content: Text(
              m.titleRankUp(
                m.ja ? titleAfter.nameJa : titleAfter.nameEn,
              ),
            ),
            duration: const Duration(seconds: 3),
          ),
        );
      });
    }
  }

  @override
  void dispose() {
    _confetti.dispose();
    _rewardAd.dispose();
    _resultBgm.dispose();
    super.dispose();
  }

  Future<void> _watchAdToDouble() async {
    final m = MetaStrings.of(context);
    // ★未準備なら予約→読み込み完了と同時に自動再生（押したのに流れない問題の根絶）★
    final playedNow = await _rewardAd.showOrQueue(onReward: () {
      PlayerProfile.instance.grantBonusCoins(_earnedThisGame);
      Sfx.instance.fanfare(); // コイン2倍ゲットは盛大に
      if (mounted) {
        setState(() => _doubled = true);
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(m.doubledCoins)));
      }
    });
    if (!mounted) return;
    if (!playedNow) {
      // 予約済み: 読み込みが終わり次第自動で再生される
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(m.adQueued)));
    }
  }

  Future<void> _launchBmc() async {
    final m = MetaStrings.of(context);
    final ok = await launchUrl(
      Uri.parse('https://buymeacoffee.com/toriumi'),
      mode: LaunchMode.externalApplication,
    );
    if (!ok && mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(m.couldNotOpenLink)));
    }
  }

  // 戦績をXでシェアする（Web Intentなのでアプリ未インストールでもブラウザで開く）
  Future<void> _shareOnX() async {
    final m = MetaStrings.of(context);
    // 現在の称号をシェア文に埋め込む
    final title = currentTitle(PlayerProfile.instance.lifetimeCoins);
    MetaStrings.titleForShare =
        '${title.emoji}${m.ja ? title.nameJa : title.nameEn}';
    final maxScore = widget.scores.isEmpty
        ? 0
        : widget.scores.reduce((a, b) => a > b ? a : b);
    final text = _wonOnline
        ? m.shareWin(widget.playerCount, widget.scores[widget.myIndex!])
        : m.sharePlayed(widget.playerCount, maxScore);
    final uri = Uri.https('twitter.com', '/intent/tweet', {
      'text': '$text ${m.shareHashtag}',
      'url': 'https://nanimonjya.web.app',
    });
    final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!ok && mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(m.couldNotOpenLink)));
    }
  }

  // オンラインゲームのリセット処理
  Future<void> _resetOnlineGame(BuildContext context) async {
    if (!widget.isOnline || widget.roomId == null || widget.myPlayerId == null) {
      return; // オンラインゲームでなければ何もしない
    }

    final DocumentReference roomRef =
        FirebaseFirestore.instance.collection('rooms').doc(widget.roomId!);

    // 部屋の実際のゲームモードを再戦後の画面に引き継ぐ
    // （以前は常に通話モード扱いになり、テキストモード部屋の再戦が壊れていた）
    bool isVoiceRoom = true;
    try {
      await FirebaseFirestore.instance.runTransaction((transaction) async {
        DocumentSnapshot currentRoom = await transaction.get(roomRef);
        if (!currentRoom.exists) {
          throw Exception('ルームが見つかりません。');
        }

        Map<String, dynamic> data = currentRoom.data() as Map<String, dynamic>;

        List<dynamic> players = data['players'] ?? [];
        String gameMode = data['gameMode'] as String? ?? 'voice';
        isVoiceRoom = gameMode == 'voice';

        Map<String, int> initialScores = {};
        for (String playerId in players.cast<String>()) {
          initialScores[playerId] = 0;
        }

        List<String> shuffledPlayerOrder = List<String>.from(players)..shuffle();

        transaction.update(roomRef, {
          'status': 'waiting',
          'deck': [],
          'fieldCards': [],
          'seenImages': [],
          'scores': initialScores,
          'currentCard': null,
          'isFirstAppearance': true,
          'canSelectPlayer': false,
          'turnCount': 0,
          'gameStarted': false,
          'characterNames': {},
          'playerOrder': shuffledPlayerOrder,
          'currentPlayerIndex': 0,
          'playersAttemptedCurrentCard': {},
          'gameMode': gameMode,
          'leftPlayers': [], // 離脱記録をリセット
          'abandonedBy': null, // 離脱者をリセット
          'characterChoices': {}, // 事前生成した選択肢もリセット
          'displayDelayCompleteTimestamp': null,
          'lastNamedCharacterData': null,
        });
      });

      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(
          builder: (context) => OnlineGameScreen(
            roomId: widget.roomId!,
            myPlayerId: widget.myPlayerId!,
            isVoiceMode: isVoiceRoom,
          ),
        ),
        (Route<dynamic> route) => false,
      );
    } catch (e) {
      debugPrint('オンラインゲームのリセットに失敗しました: $e');
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('再戦の準備に失敗しました: ${e.toString()}')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;
    final m = MetaStrings.of(context);
    final scores = widget.scores;
    final playerCount = widget.playerCount;

    // 最高スコアと勝者を決定
    int maxScore = 0;
    List<int> winners = [];
    for (int i = 0; i < scores.length; i++) {
      if (scores[i] > maxScore) {
        maxScore = scores[i];
        winners = [i];
      } else if (scores[i] == maxScore && scores[i] > 0) {
        winners.add(i);
      }
    }

    // 🤖 CPU対戦時はプレイヤー2を「CPU」、プレイヤー1を「あなた」と表示
    String playerLabel(int index) {
      if (!widget.vsCpu) return localizations.player(index + 1);
      return index == 1 ? m.cpuLabel : m.you;
    }

    String winnerText;
    if (winners.isEmpty || maxScore == 0) {
      winnerText = localizations.noWinner;
    } else if (winners.length == 1) {
      // ★修正: 以前は playerScore（"プレイヤーN: X点"の形式）に空文字を渡していたため
      //   「プレイヤー1: 点 の勝利！」と表示されるバグがあった。player を使う★
      winnerText = localizations.winner(playerLabel(winners[0]));
    } else {
      final winnerNumbers = winners.map(playerLabel).toList();
      winnerText = localizations.tie(winnerNumbers.join('と'));
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(localizations.gameResult),
        automaticallyImplyLeading: false,
        // ★右上に必ず見えるホームボタン★
        actions: [
          IconButton(
            icon: const Icon(Icons.home_rounded),
            tooltip: m.backToHome,
            onPressed: () {
              Sfx.instance.pop();
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (_) => const TopScreen()),
                (route) => false,
              );
            },
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: Stack(
        children: [
          Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  // 相手が離脱して勝った場合のバナー
                  if (widget.opponentLeft) ...[
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 10),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE3F7E8),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                            color: const Color(0xFF6BBF7E), width: 1.5),
                      ),
                      child: Text(
                        m.opponentLeftWin,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                          color: Color(0xFF2E8B4E),
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],
                  Text(
                    winnerText,
                    style: Theme.of(context)
                        .textTheme
                        .headlineSmall
                        ?.copyWith(fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 10),
                  // 🎭 成績に応じた一言コメント（ポンと拡大登場）
                  TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0.7, end: 1.0),
                    duration: const Duration(milliseconds: 400),
                    curve: Curves.elasticOut,
                    builder: (context, s, child) =>
                        Transform.scale(scale: s, child: child),
                    child: Text(
                      m.resultQuip(maxScore > 0, _tipSeed),
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFFFF4FA3),
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(height: 20),

                  // 獲得コイン演出
                  _rewardBanner(m),
                  // 🏅 ランダムマッチのレート変動バナー
                  if (widget.isRandomMatch) ...[
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 10),
                      decoration: BoxDecoration(
                        color: _wonOnline
                            ? const Color(0xFFE3F7E8)
                            : const Color(0xFFFDE7E7),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: _wonOnline
                              ? const Color(0xFF6BbF7E)
                              : const Color(0xFFE79A9A),
                          width: 1.5,
                        ),
                      ),
                      child: Text(
                        m.ratingChange(
                          _wonOnline,
                          _wonOnline
                              ? RankingService.winDelta
                              : RankingService.loseDelta,
                        ),
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                          color: _wonOnline
                              ? const Color(0xFF2E8B4E)
                              : const Color(0xFFC0392B),
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: 24),

                  Text(
                    localizations.finalScore,
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 15),
                  Card(
                    elevation: 3,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          vertical: 15.0, horizontal: 25.0),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: List.generate(playerCount, (index) {
                          final isWinner = winners.contains(index);
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 5.0),
                            child: Text(
                              widget.vsCpu
                                  ? '${isWinner ? '👑 ' : ''}${playerLabel(index)}: ${scores[index]}'
                                  : '${isWinner ? '👑 ' : ''}${localizations.playerScore(index + 1, scores[index])}',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight:
                                    isWinner ? FontWeight.bold : FontWeight.normal,
                              ),
                            ),
                          );
                        }),
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // ★再戦＋ホーム（スクロール不要で常に見える一等地に配置）★
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () {
                            if (widget.isOnline) {
                              _resetOnlineGame(context);
                            } else {
                              Navigator.pushAndRemoveUntil(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      const PlayerSelectionScreen(),
                                ),
                                (route) => false,
                              );
                            }
                          },
                          icon: const Icon(Icons.refresh),
                          label: Text(
                            widget.isOnline
                                ? localizations.playAgainSameMembers
                                : localizations.playAgain,
                            overflow: TextOverflow.ellipsis,
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF4ECDC4),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            textStyle: const TextStyle(
                                fontSize: 15, fontWeight: FontWeight.w900),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () {
                            Sfx.instance.pop();
                            // ★確実にホームへ: スタックを全消しして新しいTopScreenへ★
                            Navigator.of(context).pushAndRemoveUntil(
                              MaterialPageRoute(
                                  builder: (_) => const TopScreen()),
                              (route) => false,
                            );
                          },
                          icon: const Icon(Icons.home_rounded),
                          label: Text(m.backToHome,
                              overflow: TextOverflow.ellipsis),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFFF9F45),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            textStyle: const TextStyle(
                                fontSize: 15, fontWeight: FontWeight.w900),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // ★できることTips（ランダムに1つ表示）★
                  _tipsCard(m),
                  const SizedBox(height: 12),

                  // ★マイページ・戦績（トロフィー）への大きな導線★
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const ProfileScreen(),
                          ),
                        );
                      },
                      icon: const Icon(Icons.emoji_events),
                      label: Text(m.openTrophy),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFFFB300),
                        foregroundColor: const Color(0xFF5A3E00),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        textStyle: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // ★リワード広告：コイン2倍（大きくド派手に・状態表示付き）★
                  if (RewardAdHelper.available && !_doubled && _earnedThisGame > 0)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: AnimatedBuilder(
                        animation: _rewardAd,
                        builder: (context, _) {
                          final ready = _rewardAd.isReady;
                          return SizedBox(
                            width: double.infinity,
                            child: Container(
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [
                                    Color(0xFF43C46B),
                                    Color(0xFF2E9E52),
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(20),
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(0xFF43C46B)
                                        .withOpacity(ready ? 0.5 : 0.2),
                                    blurRadius: 10,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: ElevatedButton.icon(
                                onPressed: _watchAdToDouble,
                                icon: ready
                                    ? const Icon(Icons.play_circle_fill,
                                        size: 30)
                                    : const SizedBox(
                                        width: 22,
                                        height: 22,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2.5,
                                          color: Colors.white,
                                        ),
                                      ),
                                label: Text(
                                  ready ? m.watchAdDouble : m.adPreparing,
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.transparent,
                                  shadowColor: Colors.transparent,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 24, vertical: 18),
                                  textStyle: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),

                  const SizedBox(height: 12),
                  // Xシェアボタン（戦績＋リンク付きで投稿画面を開く）
                  ElevatedButton.icon(
                    onPressed: _shareOnX,
                    icon: const Text(
                      '𝕏',
                      style: TextStyle(
                          fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    label: Text(m.shareOnX),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.black,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 32, vertical: 12),
                    ),
                  ),

                  const SizedBox(height: 16),
                  // 応援（BMC）
                  TextButton.icon(
                    onPressed: _launchBmc,
                    icon: const Text('☕', style: TextStyle(fontSize: 18)),
                    label: Text(m.supportDev),
                    style: TextButton.styleFrom(
                      foregroundColor: const Color(0xFFBB6B2A),
                    ),
                  ),
                  const SizedBox(height: 8),
                  // 楽曲クレジット（魔王魂の利用規約によりクレジット表記）
                  const Text(
                    'BGM: 魔王魂（シャイニングスター ほか）',
                    style: TextStyle(fontSize: 11, color: Colors.grey),
                  ),
                ],
              ),
            ),
          ),

          // 紙吹雪（画面上部中央から下向きに噴射）
          Align(
            alignment: Alignment.topCenter,
            child: ConfettiWidget(
              confettiController: _confetti,
              blastDirection: pi / 2, // 下向き
              emissionFrequency: 0.05,
              numberOfParticles: 20,
              maxBlastForce: 20,
              minBlastForce: 8,
              gravity: 0.25,
              shouldLoop: false,
              colors: const [
                Colors.amber,
                Colors.pinkAccent,
                Colors.lightBlueAccent,
                Colors.greenAccent,
                Colors.purpleAccent,
              ],
            ),
          ),
        ],
      ),
    );
  }

  // できることTips（コインの使い道・遊びの広がりを提示して継続を促す）
  Widget _tipsCard(MetaStrings m) {
    final tips = m.tips();
    final tip = tips[_tipSeed % tips.length];
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFEAF7FF),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF7FD1F0), width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            m.tipsTitle,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1E7BA6),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            tip,
            style: const TextStyle(fontSize: 15, height: 1.4),
          ),
        ],
      ),
    );
  }

  Widget _rewardBanner(MetaStrings m) {
    if (_earnedThisGame <= 0) {
      return const SizedBox.shrink();
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF3D6),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE6B54A), width: 1.5),
      ),
      child: Column(
        children: [
          // コインがカラカラとカウントアップする演出
          TweenAnimationBuilder<int>(
            tween: IntTween(
              begin: 0,
              end: _doubled ? _earnedThisGame * 2 : _earnedThisGame,
            ),
            duration: const Duration(milliseconds: 900),
            curve: Curves.easeOutCubic,
            builder: (context, value, _) => Text(
              '🪙 ${m.earnedCoins(value)}',
              style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF8A6A1E)),
            ),
          ),
          if (_sessionStreak >= 2) ...[
            const SizedBox(height: 4),
            Text(
              '🔥 ${m.sessionBonusN((_sessionStreak - 1) * 5)}',
              style: const TextStyle(
                  fontSize: 14, color: Color(0xFFB35A1E)),
            ),
          ],
          if (_onlineWinBonus > 0) ...[
            const SizedBox(height: 4),
            Text(
              '🏆 ${m.onlineWinBonusN(_onlineWinBonus)}',
              style: const TextStyle(
                  fontSize: 14, color: Color(0xFFB35A1E)),
            ),
          ],
        ],
      ),
    );
  }
}
