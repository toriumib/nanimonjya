import 'package:flutter/material.dart';

import '../l10n/meta_strings.dart';
import '../services/sfx.dart';
import '../services/speech.dart';
import '../widgets/banner_ad_slot.dart';

/// 📖 ルールブック。
///
/// 「あそびかた」チュートリアルは初回に一度きりなので、あとから
/// ルールを確かめる場所がなかった。ここに全モードのルールをまとめ、
/// ホームからもゲーム中からも開けるようにする。
///
/// [focus] を渡すと、そのモードを開いた状態で表示する。
class RulebookScreen extends StatelessWidget {
  final RuleTopic? focus;
  const RulebookScreen({super.key, this.focus});

  @override
  Widget build(BuildContext context) {
    final m = MetaStrings.of(context);
    const topics = RuleTopic.values;
    return Scaffold(
      appBar: AppBar(
        title: Text(m.rulebookTitle),
        actions: [
          IconButton(
            tooltip: m.rulebookRead,
            icon: const Icon(Icons.volume_up),
            onPressed: () {
              final t = focus ?? RuleTopic.nameCall;
              Speech.instance
                  .speak('${m.ruleTitle(t)}。${m.ruleBody(t)}', ja: m.ja);
            },
          ),
        ],
      ),
      bottomNavigationBar: const BannerAdSlot(),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        children: [
          Text(m.rulebookLead,
              style: const TextStyle(fontSize: 12.5, color: Colors.black54)),
          const SizedBox(height: 12),
          for (final t in topics)
            Card(
              margin: const EdgeInsets.only(bottom: 10),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
              child: ExpansionTile(
                initiallyExpanded: t == (focus ?? RuleTopic.nameCall),
                shape: const Border(),
                leading: Text(m.ruleEmoji(t),
                    style: const TextStyle(fontSize: 26)),
                title: Text(m.ruleTitle(t),
                    style: const TextStyle(
                        fontSize: 15.5, fontWeight: FontWeight.w900)),
                childrenPadding:
                    const EdgeInsets.fromLTRB(16, 0, 16, 14),
                children: [
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(m.ruleBody(t),
                        style: const TextStyle(fontSize: 13.5, height: 1.7)),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

/// ルールブックで扱うモード。
///
/// 🌐 オンラインは「フレンド」「ランク」「ターン制」で勝ち方も進み方も違う。
/// 1つの「オンライン対戦」にまとめると、どれの説明なのか分からなくなるので
/// 別々の項目にしてある。
enum RuleTopic {
  nameCall,
  cpu,
  onlineFriend,
  rank,
  turnPairs,
  lineMatch,
  cardMemory,
  pairs,
}

/// 📖 どこからでも押せるルールボタン。
/// ゲーム中のAppBarにも置けるよう小さめにしてある。
///
/// ⚠️ 以前は本のアイコンだけの丸ボタンだった。何のボタンか分からず、
/// ゲーム中にルールを見直したい人が気づけなかったので「ルール」の文字を添える。
class RulebookButton extends StatelessWidget {
  final RuleTopic? focus;
  /// AppBar に置くときは白抜きにする
  final bool onDark;
  const RulebookButton({super.key, this.focus, this.onDark = false});

  @override
  Widget build(BuildContext context) {
    final m = MetaStrings.of(context);
    return Tooltip(
      message: m.rulebookTitle,
      child: Material(
        color: onDark ? Colors.white24 : const Color(0xFF3A7BD5),
        shape: const StadiumBorder(),
        child: InkWell(
          customBorder: const StadiumBorder(),
          onTap: () {
            Sfx.instance.pop();
            Navigator.of(context).push(MaterialPageRoute<void>(
                builder: (_) => RulebookScreen(focus: focus)));
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.menu_book_rounded,
                    color: Colors.white, size: 20),
                const SizedBox(width: 5),
                Text(
                  m.rulebookShort,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
