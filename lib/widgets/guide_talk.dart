import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../services/player_profile.dart';
import '../services/review_queue.dart';

/// 🗣 ホームでナナちゃん・はなちゃんが声をかける吹き出し。
///
/// **ただの飾りではなく、いまのその人に向けた一言にする。**
/// 「今日もがんばろう」だけを毎日出しても読まれなくなる。
/// 連続日数・復習どきの人数・今週おぼえた人数・時間帯といった、
/// **こちらが持っている情報**を使って、今日ここで言うべきことを選ぶ。
///
/// 優先順位は「いま**行動につながるもの**」が上。
/// 復習どきの人がいるならそれ、次にデイリー、次に近況、最後に雑談。
class GuideTalk extends StatelessWidget {
  /// 何日ぶりか等の判定に使う。ホームから渡す。
  const GuideTalk({super.key});

  @override
  Widget build(BuildContext context) {
    final ja = Localizations.localeOf(context).languageCode == 'ja';
    final line = pickGuideLine(
      profile: PlayerProfile.instance,
      dueCount: ReviewQueue.instance.dueCount(),
      hour: DateTime.now().hour,
      ja: ja,
    );
    return Container(
      margin: const EdgeInsets.fromLTRB(14, 0, 14, 10),
      padding: const EdgeInsets.fromLTRB(10, 10, 14, 10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFD8E4F0), width: 1.4),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SvgPicture.asset(line.asset, width: 44, height: 44),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(line.speaker,
                    style: const TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF2B5CA5))),
                const SizedBox(height: 2),
                Text(line.text,
                    style: const TextStyle(fontSize: 13, height: 1.5)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// 声かけ1本ぶん。
class GuideLine {
  final String speaker;
  final String asset;
  final String text;
  const GuideLine(this.speaker, this.asset, this.text);
}

const String _nanaAsset = 'assets/images/supporters/cheer_girl.svg';
const String _hanaAsset = 'assets/images/supporters/cheer_girl2.svg';

/// 状況に合う一言を選ぶ。
///
/// UIから切り離してあるのは、**言うべき順番**をテストで固定するため。
/// 「復習どきの人がいるのに雑談している」ような外し方をすると、
/// 声かけそのものが読み飛ばされるようになる。
GuideLine pickGuideLine({
  required PlayerProfile profile,
  required int dueCount,
  required int hour,
  required bool ja,
  Random? random,
}) {
  GuideLine nana(String t) => GuideLine(ja ? 'ナナちゃん' : 'Nana', _nanaAsset, t);
  GuideLine hana(String t) => GuideLine(ja ? 'はなちゃん' : 'Hana', _hanaAsset, t);

  // ① まだ一度も遊んでいない人には、まず1回終わらせてもらう
  if (profile.totalGames == 0) {
    return nana(ja
        ? 'はじめまして！まずは1ゲームだけ、いっしょにやってみよ。4人からで大丈夫だよ。'
        : "Hi! Let's just finish one game together — four faces is plenty to start.");
  }

  // ② 復習どきの人がいる。いちばん行動につながるので最優先
  if (dueCount > 0) {
    return hana(ja
        ? 'きのう覚えた$dueCount人、そろそろ忘れかけのころ。いま思い出すと、いちばん残るよ。'
        : '$dueCount people are due. Recalling them now is when it sticks best.');
  }

  // ③ デイリーボーナスがまだ
  if (profile.canClaimDaily) {
    return nana(ja
        ? '今日のごほうび、まだ受け取ってないよ。マイページで待ってるからね。'
        : "You haven't picked up today's bonus yet — it's on My Page.");
  }

  // ④ 続いている人はそこをほめる（続ける理由になる）
  if (profile.dailyStreak >= 3) {
    return hana(ja
        ? '${profile.dailyStreak}日続いてるね。毎日ちょっとずつが、いちばん効くやり方だよ。'
        : '${profile.dailyStreak} days in a row. A little every day is the method that works.');
  }

  // ⑤ 今週の成果を返す（自分の伸びが見えると続く）
  if (profile.weeklyLearned > 0) {
    final n = profile.weeklyLearned;
    return nana(ja
        ? '今週は$n人おぼえたよ。伸びぐあいはマイページの成績レポートで見られるからね。'
        : "You've learned $n people this week — see the report on My Page.");
  }

  // ⑥ 時間帯に合わせた一言
  if (hour >= 5 && hour < 11) {
    return hana(ja
        ? 'おはよう！朝は頭がすっきりしてる時間だから、3分だけやってみない？'
        : 'Morning! Your head is clearest now — how about three minutes?');
  }
  if (hour >= 21 || hour < 5) {
    return nana(ja
        ? '寝る前に一回りしておくと、寝ているあいだに残りやすいと言われているよ。'
        : 'A quick round before bed is said to help it stick while you sleep.');
  }

  // ⑦ それ以外は、覚え方のワンポイント（毎回同じにならないよう回す）
  final tips = ja
      ? const [
          '名前は、声に出して一度呼ぶだけで残りやすくなるよ。',
          '顔の「いちばん目立つところ」を、一言のタグにしてみて。',
          '思い出せなかった人こそ、明日また会いに来てね。',
          '読み返すより、思い出すほうが残る。目をつぶって言ってみよう。',
        ]
      : const [
          'Say the name out loud once — it helps.',
          'Tag the most distinctive part of the face in a few words.',
          'The ones you missed are the ones worth meeting again tomorrow.',
          'Recalling beats re-reading. Try saying it with your eyes closed.',
        ];
  final rng = random ?? Random(DateTime.now().day);
  final t = tips[rng.nextInt(tips.length)];
  // 日替わりで話し手を変える（同じ子ばかりだと飽きる）
  return DateTime.now().day.isEven ? nana(t) : hana(t);
}
