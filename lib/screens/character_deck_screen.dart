
import 'package:flutter/material.dart';

import '../l10n/meta_strings.dart';
import '../models/character_catalog.dart';
import '../models/person.dart';
import '../services/custom_roster_service.dart';
import '../services/player_profile.dart';
import '../services/sfx.dart';
import '../widgets/banner_ad_slot.dart';
import '../widgets/face_view.dart'; // 写真・似顔絵・バンドル画像をまとめて描く
import 'character_shop_screen.dart';
import 'custom_roster_screen.dart';
import '../services/app_analytics.dart';

/// 🎴 キャラデッキ編集。
/// ゲームに出てくる顔ぶれを自分で選べる画面。
/// - 基本12人（バンドル画像）
/// - 購入した追加キャラ（unlockedCharacters）
/// - 自分で登録した顔写真（CustomRosterService）
///
/// 保存は「除外リスト」方式（PlayerProfile.deckExcluded）。
/// 買い足したり写真を登録したキャラは自動でデッキ入りする。
class CharacterDeckScreen extends StatefulWidget {
  const CharacterDeckScreen({super.key});

  @override
  State<CharacterDeckScreen> createState() => _CharacterDeckScreenState();
}

class _DeckItem {
  /// ON/OFFを覚えておくキー。
  /// ⚠️ 画像パスと同じとはかぎらない。顔メモの似顔絵は画像パスを
  ///    持たないので、`custom:<登録ID>` を使う（[FaceRef.deckKey]）。
  final String deckKey;
  final String label;

  /// どう描くか。asset／file（自分の写真）／avatar（似顔絵）。
  final FaceKind kind;

  /// 画像パス、または似顔絵のJSON。
  final String face;

  const _DeckItem({
    required this.deckKey,
    required this.label,
    required this.kind,
    required this.face,
  });

  factory _DeckItem.asset(String path, String label) => _DeckItem(
        deckKey: path,
        label: label,
        kind: FaceKind.asset,
        face: path,
      );
}

class _CharacterDeckScreenState extends State<CharacterDeckScreen> {
  @override
  void initState() {
    super.initState();
    AppAnalytics.screen('character_deck');
    // 🎴 作ったアバターがここまで届いているかを見る（2026-08 は計測ゼロ）
    AppAnalytics.deckOpen('unknown');
    // 🌐 Web でも似顔絵の顔メモは使えるので、ここで kIsWeb を見ない。
    //    （写真の登録だけがモバイル限定）
    CustomRosterService.instance.load();
  }

  List<_DeckItem> _baseItems() => [
        for (var i = 0; i < kCharImageAssets.length; i++)
          _DeckItem.asset(kCharImageAssets[i], '${i + 1}'),
      ];

  List<_DeckItem> _boughtItems(PlayerProfile profile) => [
        for (final c in kExtraCharacters)
          if (profile.unlockedCharacters.contains(c.id))
            _DeckItem.asset(c.asset, c.emoji),
      ];

  /// 🧑‍🎨 顔メモで登録した人。写真でも似顔絵でも出す。
  ///
  /// ⚠️ 以前はここで `e.imagePath` をキーにしていた。
  ///    似顔絵だけの人は imagePath が空文字なので、**登録した全員が
  ///    同じキーに潰れ**、1人OFFにすると似顔絵の人が全員消えていた。
  ///    さらに Image.file(File('')) を errorBuilder 無しで描いていて、
  ///    似顔絵の人は絵も出ていなかった。
  List<_DeckItem> _myFaceItems() => [
        for (final e in CustomRosterService.instance.entries)
          () {
            final ref = e.toFaceRef();
            return _DeckItem(
              deckKey: ref.deckKey,
              label: e.name.isEmpty ? '？' : e.name,
              kind: ref.kind,
              face: ref.face,
            );
          }(),
      ];

  @override
  Widget build(BuildContext context) {
    final m = MetaStrings.of(context);
    final profile = PlayerProfile.instance;

    return AnimatedBuilder(
      animation: Listenable.merge([profile, CustomRosterService.instance]),
      builder: (context, _) {
        final base = _baseItems();
        final bought = _boughtItems(profile);
        final mine = _myFaceItems();
        final all = [...base, ...bought, ...mine];
        final activeCount =
            all.where((i) => !profile.deckExcluded.contains(i.deckKey)).length;

        return Scaffold(
          appBar: AppBar(
            title: Text(m.deckTitle),
            actions: [
              TextButton(
                onPressed: profile.deckExcluded.isEmpty
                    ? null
                    : () {
                        Sfx.instance.pop();
                        profile.resetDeck();
                      },
                child: Text(m.deckSelectAll),
              ),
            ],
          ),
          bottomNavigationBar: const BannerAdSlot(),
          body: ListView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
            children: [
              _headerCard(m, activeCount),
              const SizedBox(height: 16),
              _section(m.deckSectionBase, base, profile),
              const SizedBox(height: 20),
              _section(
                m.deckSectionBought,
                bought,
                profile,
                emptyHint: m.deckEmptyBought,
                emptyAction: _shopButton(m),
              ),
              const SizedBox(height: 20),
              // 🧑‍🎨 顔メモは Web でも似顔絵なら使えるので、ここを kIsWeb で隠さない。
              _section(
                  m.deckSectionMine,
                  mine,
                  profile,
                  emptyHint: m.deckEmptyMine,
                  emptyAction: _rosterButton(m),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _headerCard(MetaStrings m, int activeCount) {
    // 出演人数が少なすぎるとゲームが成立しないので、そのときだけ警告を出す。
    final tooFew = activeCount < 4;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF3A7BD5), Color(0xFF00C2A8)],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(m.deckHeadline,
              style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w900,
                  color: Colors.white)),
          const SizedBox(height: 6),
          Text(m.deckDesc,
              style: const TextStyle(
                  fontSize: 12.5, height: 1.4, color: Colors.white)),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: tooFew ? const Color(0xFFD64545) : Colors.white,
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              tooFew ? m.deckTooFew : m.deckActiveCount(activeCount),
              style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w900,
                  color: tooFew ? Colors.white : const Color(0xFF2B5CA5)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _shopButton(MetaStrings m) => ElevatedButton(
        onPressed: () => Navigator.of(context).push(MaterialPageRoute<void>(
            builder: (_) => const CharacterShopScreen())),
        child: Text(m.deckGoShop),
      );

  Widget _rosterButton(MetaStrings m) => ElevatedButton(
        onPressed: () => Navigator.of(context).push(MaterialPageRoute<void>(
            builder: (_) => const CustomRosterScreen())),
        child: Text(m.deckGoRoster),
      );

  Widget _section(
    String title,
    List<_DeckItem> items,
    PlayerProfile profile, {
    String? emptyHint,
    Widget? emptyAction,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title,
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w900)),
        const SizedBox(height: 10),
        if (items.isEmpty && emptyHint != null) ...[
          Text(emptyHint,
              style: const TextStyle(fontSize: 12.5, color: Colors.black54)),
          const SizedBox(height: 8),
          if (emptyAction != null) emptyAction,
        ] else
          GridView.count(
            crossAxisCount: 4,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
            childAspectRatio: 0.78,
            children: [
              for (final item in items) _tile(item, profile),
            ],
          ),
      ],
    );
  }

  Widget _tile(_DeckItem item, PlayerProfile profile) {
    final on = !profile.deckExcluded.contains(item.deckKey);
    return GestureDetector(
      onTap: () {
        Sfx.instance.pop();
        profile.setDeckIncluded(item.deckKey, !on);
      },
      child: Column(
        children: [
          Expanded(
            child: Stack(
              fit: StackFit.expand,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: ColorFiltered(
                    colorFilter: on
                        ? const ColorFilter.mode(
                            Colors.transparent, BlendMode.multiply)
                        : const ColorFilter.matrix(<double>[
                            0.2126, 0.7152, 0.0722, 0, 0, //
                            0.2126, 0.7152, 0.0722, 0, 0, //
                            0.2126, 0.7152, 0.0722, 0, 0, //
                            0, 0, 0, 1, 0,
                          ]),
                    // 写真・似顔絵・バンドル画像をまとめて FaceView に任せる。
                    // 自前で Image.file を書いていたころは、似顔絵の人が
                    // 空パスで読み込まれて絵が出なかった。
                    child: FaceView(
                      person: Person(
                        face: item.face,
                        kind: item.kind,
                        name: item.label,
                        hobby: '',
                      ),
                      size: 200,
                      radius: 12,
                    ),
                  ),
                ),
                if (!on)
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.35),
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                Positioned(
                  right: 4,
                  top: 4,
                  child: Container(
                    padding: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      color: on ? const Color(0xFF00C2A8) : Colors.white70,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(on ? Icons.check : Icons.close,
                        size: 15,
                        color: on ? Colors.white : Colors.black54),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 4),
          Text(
            item.label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: on ? Colors.black87 : Colors.black38),
          ),
        ],
      ),
    );
  }
}
