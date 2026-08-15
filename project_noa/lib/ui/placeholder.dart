/// SPEC 3.8 — 絵が無くても動くための層。
///
/// 画像ファイルは1枚も使わない。背景も立ち絵も**コードで描く**（ui/art/）。
/// 素材が届くのを待たずに全部の場面を確かめられるのが狙いで、
/// あとから画像に差し替えるときも、触るのはこのファイルだけで済む。
library;

import 'package:flutter/material.dart';

import '../engine/scene_player.dart';
import '../models/noah_field.dart';
import '../models/scene_script.dart';
import 'art/backdrop.dart';
import 'art/portrait.dart';

/// 背景。
class BackdropLayer extends StatelessWidget {
  final String id;
  final int age;
  const BackdropLayer({super.key, required this.id, this.age = 0});

  @override
  Widget build(BuildContext context) => NoahBackdrop(id: id, age: age);
}

/// 立ち絵。いま喋っている人を出す。
class SpriteLayer extends StatelessWidget {
  final ScenePlayer player;
  final NoahCast? cast;
  const SpriteLayer({super.key, required this.player, this.cast});

  /// いま喋っている人を引く。
  ///
  /// シナリオの `"sprite": "hibino/smile"` があればそれを信じる。
  /// 無いときは名前から探す（「土倉」のような姓だけの表記に備える）。
  ({String id, Expression exp})? _speaking() {
    final all = cast?.all;
    if (all == null) return null;

    // 台本が立ち絵を指定しているか
    final line = (player.index >= 0 && player.index < player.scene.lines.length)
        ? player.scene.lines[player.index]
        : null;
    if (line is LineSay && line.sprite.isNotEmpty) {
      final parts = line.sprite.split('/');
      return (id: parts.first, exp: expressionFromKey(parts.length > 1 ? parts[1] : ''));
    }

    if (player.speaker.isEmpty) return null;
    for (final c in all) {
      final family = c.name.split(' ').first;
      if (player.speaker.startsWith(family) ||
          c.name.replaceAll(' ', '').startsWith(player.speaker)) {
        return (id: c.id, exp: Expression.normal);
      }
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final who = _speaking();
    if (who == null) return const SizedBox.shrink();

    return LayoutBuilder(
      builder: (context, box) {
        // 立ち絵は画面の高さに合わせる。文字窓に潜り込ませて、
        // 「奥に人がいて、手前に窓がある」ように見せる。
        final h = box.maxHeight * 0.62;
        return Align(
          alignment: Alignment.bottomCenter,
          child: Padding(
            padding: EdgeInsets.only(bottom: box.maxHeight * 0.20),
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 220),
              child: NoahPortrait(
                key: ValueKey('${who.id}/${who.exp}/${player.aging}'),
                charId: who.id,
                expression: who.exp,
                height: h,
                aging: player.aging,
              ),
            ),
          ),
        );
      },
    );
  }
}

/// 音の代わり。音源が無いあいだは**何もしない**（例外を投げない）。
class SilentAudio {
  const SilentAudio();
  void bgm(String id, {double fade = 1.0}) {}
  void se(String id) {}
}
