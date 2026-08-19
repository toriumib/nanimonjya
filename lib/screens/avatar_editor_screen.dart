import 'dart:math';

import 'package:flutter/material.dart';

import '../models/avatar.dart';
import '../services/sfx.dart';
import '../widgets/avatar_view.dart';
import '../widgets/banner_ad_slot.dart';
import '../widgets/themed_background.dart';
import '../services/app_analytics.dart';

/// 🧑‍🎨 顔メモのアバターを作る画面。
///
/// 職場で新しく会った人の顔は、写真に撮るわけにいかない。
/// そこで「メガネ・ほくろ・髪型」のような特徴を選んで顔を組み立てる。
///
/// **組み立てる作業そのものが記憶の練習になる**。
/// 顔を見て「四角メガネで、左ほおにほくろ」と言葉にすること自体が
/// 特徴の言語化で、あとで思い出す手がかりになる。
/// だから画面の下に、選んだ特徴をそのまま文にして見せている。
class AvatarEditorScreen extends StatefulWidget {
  /// 編集を始めるときの顔。新規なら null。
  final Avatar? initial;

  /// 誰の顔かが分かっていれば見出しに出す。
  final String? personName;

  const AvatarEditorScreen({super.key, this.initial, this.personName});

  @override
  State<AvatarEditorScreen> createState() => _AvatarEditorScreenState();
}

class _AvatarEditorScreenState extends State<AvatarEditorScreen> {
  @override
  void initState() {
    super.initState();
    AppAnalytics.screen('avatar_editor');
  }

  late Avatar _a = widget.initial ?? const Avatar();

  void _set(Avatar next) {
    Sfx.instance.pop();
    setState(() => _a = next);
  }

  @override
  Widget build(BuildContext context) {
    final features = _a.featuresJa();
    return ThemedBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        bottomNavigationBar: const BannerAdSlot(placement: 'avatar_editor'),
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          title: Text(widget.personName == null
              ? '🧑‍🎨 顔をつくる'
              : '🧑‍🎨 ${widget.personName} の顔'),
          actions: [
            IconButton(
              tooltip: 'ランダム',
              icon: const Icon(Icons.casino_outlined),
              onPressed: () => _set(Avatar.random(Random())),
            ),
          ],
        ),
        body: SafeArea(
          child: Column(
            children: [
              // 顔は常に見えていてほしいので、上に固定してリストだけ動かす
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
                child: Row(
                  children: [
                    AvatarView(avatar: _a, size: 108, radius: 18),
                    const SizedBox(width: 10),
                    // 🧍 全身。身長・年齢を動かした結果がここに出る。
                    ClipRRect(
                      borderRadius: BorderRadius.circular(18),
                      child: AvatarBodyView(avatar: _a, height: 108),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text('この人の特徴',
                              style: TextStyle(
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w900,
                                  color: Color(0xFF2B5CA5))),
                          const SizedBox(height: 4),
                          if (features.isEmpty)
                            const Text(
                              'メガネ・ほくろ・ひげ・髪型をつけると、\n'
                              '思い出す手がかりになります。',
                              style: TextStyle(fontSize: 11.5, height: 1.5),
                            )
                          else
                            Wrap(
                              spacing: 6,
                              runSpacing: 4,
                              children: [
                                for (final f in features)
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 8, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFFFF2C6),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Text(f,
                                        style: const TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w900)),
                                  ),
                              ],
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              // 🗂 3つのグループに分ける。
              //    以前は14項目が1本の長いスクロールに並んでいて、
              //    どこまで見たか分からず最後まで届かなかった。
              //    「特徴 → 顔だち → その人のこと」の順で、
              //    覚える手がかりになるものから決められるようにする。
              Expanded(
                child: DefaultTabController(
                  length: 3,
                  child: Column(
                    children: [
                      const TabBar(
                        labelColor: Color(0xFF2B5CA5),
                        unselectedLabelColor: Colors.black45,
                        indicatorColor: Color(0xFF3A7BD5),
                        labelStyle: TextStyle(
                            fontSize: 12.5, fontWeight: FontWeight.w900),
                        tabs: [
                          Tab(text: '👓 特徴'),
                          Tab(text: '🙂 顔だち'),
                          Tab(text: '📋 その人のこと'),
                        ],
                      ),
                      Expanded(
                        child: TabBarView(
                          children: [
                            // ① 覚える手がかりになるもの。
                            //    肌や輪郭より、メガネ・ほくろのほうが
                            //    言葉にしやすく、思い出す取っかかりになる。
                            _tabList([
                              _picker('👓 メガネ', kGlassesJa, _a.glasses,
                                  (i) => _set(_a.copyWith(glasses: i))),
                              _picker('⚫ ほくろ', kMoleJa, _a.mole,
                                  (i) => _set(_a.copyWith(mole: i))),
                              _picker('💇 髪型', kHairJa, _a.hair,
                                  (i) => _set(_a.copyWith(hair: i))),
                              _picker('🧔 ひげ', kBeardJa, _a.beard,
                                  (i) => _set(_a.copyWith(beard: i))),
                              _swatches('🎨 髪の色', _a.hairColor,
                                  kHairColorJa.length,
                                  (i) => _set(_a.copyWith(hairColor: i)),
                                  labels: kHairColorJa),
                            ]),
                            // ② 顔のつくり
                            _tabList([
                              _picker('🙂 輪郭', kFaceShapeJa, _a.faceShape,
                                  (i) => _set(_a.copyWith(faceShape: i))),
                              _picker('👀 目', kEyesJa, _a.eyes,
                                  (i) => _set(_a.copyWith(eyes: i))),
                              _picker('✏️ まゆ', kEyebrowsJa, _a.eyebrows,
                                  (i) => _set(_a.copyWith(eyebrows: i))),
                              _picker('👃 鼻', kNoseJa, _a.nose,
                                  (i) => _set(_a.copyWith(nose: i))),
                              _picker('👄 口', kMouthJa, _a.mouth,
                                  (i) => _set(_a.copyWith(mouth: i))),
                              _swatches('🖐 肌の色', _a.skin, Avatar.skinCount,
                                  (i) => _set(_a.copyWith(skin: i))),
                            ]),
                            // ③ 絵にも出るが、思い出す手がかりでもあるもの
                            _tabList([
                              _picker('🚻 性別', kGenderJa, _a.gender,
                                  (i) => _set(i == 2
                                      // 女性はかわいい顔（ぱっちり目＋にっこり口）を提案
                                      ? _a.copyWith(gender: i, eyes: 5, mouth: 1)
                                      : _a.copyWith(gender: i))),
                              _slider(
                                  '🎂 年齢のめやす',
                                  '${_a.age}歳',
                                  _a.age.toDouble(),
                                  Avatar.minAge,
                                  Avatar.maxAge,
                                  (v) => setState(
                                      () => _a = _a.copyWith(age: v))),
                              _slider(
                                  '📏 身長のめやす',
                                  '${_a.height}cm',
                                  _a.height.toDouble(),
                                  Avatar.minHeight,
                                  Avatar.maxHeight,
                                  (v) => setState(
                                      () => _a = _a.copyWith(height: v))),
                            ]),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              // 決定ボタンはタブの外に固定する。
              // タブの中に置くと、タブごとに出たり消えたりしてしまう。
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 8, 12, 10),
                child: ElevatedButton(
                  onPressed: () {
                    // いじった項目数を残す。0なら既定の顔のまま出ている＝
                    // エディタが使われていないのと同じなので、そこを見る。
                    AppAnalytics.avatarEditorDone(_a.diffCount(const Avatar()));
                    Navigator.pop(context, _a);
                  },
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size.fromHeight(50),
                    backgroundColor: const Color(0xFF3A7BD5),
                    foregroundColor: Colors.white,
                    textStyle: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.w900),
                  ),
                  child: const Text('この顔で決定'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── パーツ ──

  /// タブ1枚ぶんの中身。
  Widget _tabList(List<Widget> children) => ListView(
        padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
        children: children,
      );

  Widget _card({required Widget child}) => Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.94),
          borderRadius: BorderRadius.circular(14),
        ),
        child: child,
      );

  Widget _label(String text) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Text(text,
            style: const TextStyle(
                fontSize: 13, fontWeight: FontWeight.w900)),
      );

  /// 選択肢を横スクロールのチップで並べる。
  Widget _picker(String title, List<String> labels, int value,
      ValueChanged<int> onPick) {
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _label(title),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              for (var i = 0; i < labels.length; i++)
                ChoiceChip(
                  label: Text(labels[i],
                      style: const TextStyle(
                          fontSize: 12.5, fontWeight: FontWeight.w700)),
                  selected: value == i,
                  showCheckmark: false,
                  selectedColor: const Color(0xFF3A7BD5),
                  labelStyle: TextStyle(
                      color: value == i ? Colors.white : Colors.black87),
                  onSelected: (_) => onPick(i),
                ),
            ],
          ),
        ],
      ),
    );
  }

  /// 色は名前だけだと分からないので、丸で見せる。
  Widget _swatches(String title, int value, int count, ValueChanged<int> onPick,
      {List<String>? labels}) {
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _label(title),
          // ⚠️ Row だと、色数を増やしたときや狭い画面ではみ出す。
          //    Wrap にして折り返させる。
          Wrap(
            spacing: 10,
            runSpacing: 8,
            children: [
              for (var i = 0; i < count; i++)
                Padding(
                  padding: EdgeInsets.zero,
                  child: GestureDetector(
                    onTap: () => onPick(i),
                    child: Column(
                      children: [
                        Container(
                          width: 30,
                          height: 30,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: title.contains('髪')
                                ? _hairSwatch(i)
                                : _skinSwatch(i),
                            border: Border.all(
                              color: value == i
                                  ? const Color(0xFF3A7BD5)
                                  : Colors.black12,
                              width: value == i ? 3 : 1.5,
                            ),
                          ),
                        ),
                        if (labels != null)
                          Text(labels[i],
                              style: const TextStyle(fontSize: 9.5)),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _slider(String title, String valueLabel, double value, int min,
      int max, ValueChanged<int> onChanged) {
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: _label(title)),
              Text(valueLabel,
                  style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFF2B5CA5))),
            ],
          ),
          Slider(
            value: value,
            min: min.toDouble(),
            max: max.toDouble(),
            divisions: max - min,
            onChanged: (v) => onChanged(v.round()),
          ),
        ],
      ),
    );
  }
}

// エディタの色見本。AvatarView と同じ並び順にそろえる。
Color _skinSwatch(int i) => const [
      Color(0xFFFFE0C4),
      Color(0xFFF6D0AC),
      Color(0xFFE8BC94),
      Color(0xFFC99B72),
      Color(0xFF9A6B4A),
    ][i % 5];

Color _hairSwatch(int i) => const [
      Color(0xFF2B2118),
      Color(0xFF4A3324),
      Color(0xFF7A5230),
      Color(0xFFD9A94C),
      Color(0xFF8C4A2F),
      Color(0xFF9E9E9E),
    ][i % 6];
