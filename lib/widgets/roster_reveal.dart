import 'package:flutter/material.dart';

import '../l10n/meta_strings.dart';
import '../models/person.dart';
import 'face_view.dart';

/// 📇 結果画面の「誰が誰だったか」。
///
/// 正解率や獲得枚数だけを返されても、**どの顔を取り違えたのか**が分からず
/// 次に活かしようがなかった。最後に顔と名前をもう一度そろえて見せる。
/// これ自体が、間隔をあけた復習の1回にもなる。
///
/// 名前が空の [Person]（なまえがお用の生成器は name が空）を渡しても
/// 意味がないので、名前が入っているものだけを渡すこと。
/// [people] が空なら何も描かない。
class RosterRevealCard extends StatelessWidget {
  final List<Person> people;

  /// 人物ごとの補足（「出会った場所」など）。null なら出さない。
  final String Function(Person)? subtitle;

  const RosterRevealCard({super.key, required this.people, this.subtitle});

  @override
  Widget build(BuildContext context) {
    if (people.isEmpty) return const SizedBox.shrink();
    final m = MetaStrings.of(context);
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(m.reportRosterTitle,
                style:
                    const TextStyle(fontSize: 15, fontWeight: FontWeight.w900)),
            const SizedBox(height: 2),
            Text(m.reportRosterHint,
                style: const TextStyle(fontSize: 11.5, color: Colors.black54)),
            const SizedBox(height: 10),
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 3,
              childAspectRatio: subtitle == null ? 0.78 : 0.66,
              mainAxisSpacing: 10,
              crossAxisSpacing: 10,
              children: [
                for (final p in people)
                  Column(
                    children: [
                      Expanded(child: FaceView(person: p, size: 200, radius: 12)),
                      const SizedBox(height: 4),
                      Text(
                        p.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            fontSize: 13, fontWeight: FontWeight.w900),
                      ),
                      if (subtitle != null)
                        Text(
                          subtitle!(p),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                              fontSize: 10.5, color: Colors.black54),
                        ),
                    ],
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
