/// SPEC 3.8 — 絵が無くても動くための層。
///
/// 画像が1枚も無いうちからロジックを全部確かめられるようにする。
/// 画像を置いたら、このファイルは何も変えずに絵が出るようになる。
library;

import 'package:flutter/material.dart';

import '../engine/scene_player.dart';
import '../models/noah_field.dart';
import '../models/scene_script.dart';

/// 背景。`assets/images/bg/<id>_age<N>.png` が無ければ色とラベルで代用する。
class BackdropLayer extends StatelessWidget {
  final String id;
  final int age;
  const BackdropLayer({super.key, required this.id, this.age = 0});

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 500),
      child: Container(
        key: ValueKey('$id/$age'),
        decoration: BoxDecoration(
          gradient: RadialGradient(
            center: const Alignment(0, 1.3),
            radius: 1.1,
            colors: [
              // 老化が進むほど、赤みが強く・くすんでいく（SPEC 4.8）
              Color.lerp(const Color(0xFF2A0D0D), const Color(0xFF3A1A12),
                  (age / 10).clamp(0, 1))!,
              const Color(0xFF05070F),
            ],
          ),
        ),
        child: Align(
          alignment: Alignment.topRight,
          child: Padding(
            padding: const EdgeInsets.only(top: 60, right: 14),
            child: Text(
              id.isEmpty ? '' : 'bg: $id${age > 0 ? ' (age$age)' : ''}',
              style: const TextStyle(fontSize: 10, color: Color(0x336A7280)),
            ),
          ),
        ),
      ),
    );
  }
}

/// 立ち絵。まだ絵が無いので、キャラの色と絵文字で「誰が喋っているか」を出す。
class SpriteLayer extends StatelessWidget {
  final ScenePlayer player;
  final NoahCast? cast;
  const SpriteLayer({super.key, required this.player, this.cast});

  /// いま喋っている人を、名前から引く（sprite の指定より名前が確実）。
  NoahCharacter? _speaking() {
    final all = cast?.all;
    if (all == null || player.speaker.isEmpty) return null;
    for (final c in all) {
      // 「土倉」のような姓だけの表記でも当てられるように前方一致で見る
      if (c.name.replaceAll(' ', '').startsWith(player.speaker)) return c;
      if (player.speaker.startsWith(c.name.split(' ').first)) return c;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final c = _speaking();
    if (c == null) return const SizedBox.shrink();
    return Align(
      alignment: Alignment.bottomCenter,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 170),
        child: AnimatedOpacity(
          opacity: 1,
          duration: const Duration(milliseconds: 300),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 118,
                height: 118,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Color(c.color).withValues(alpha: 0.22),
                  border: Border.all(color: Color(c.color), width: 2.5),
                ),
                child: Center(
                  child: Text(c.emoji, style: const TextStyle(fontSize: 52)),
                ),
              ),
              const SizedBox(height: 6),
              Text(c.name,
                  style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w900,
                      color: Color(c.color))),
            ],
          ),
        ),
      ),
    );
  }
}

/// 音の代わり。音源が無いあいだは**何もしない**（例外を投げない）。
class SilentAudio {
  const SilentAudio();
  void bgm(String id, {double fade = 1.0}) {}
  void se(String id) {}
}

/// 演出のプレースホルダ。SPEC 3.1 の shake / flash をここで受ける。
String fxLabel(LineFx fx) => 'fx: ${fx.kind}';
