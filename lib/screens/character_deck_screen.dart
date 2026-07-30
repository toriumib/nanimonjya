import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../l10n/meta_strings.dart';
import '../models/character_catalog.dart';
import '../models/person.dart';
import '../services/custom_roster_service.dart';
import '../services/player_profile.dart';
import '../services/sfx.dart';
import '../widgets/banner_ad_slot.dart';
import 'character_shop_screen.dart';
import 'custom_roster_screen.dart';

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
  final String assetPath; // 保存キー兼画像パス
  final String label;
  final bool isFile; // 自分の写真（Fileから読む）か、バンドルassetか
  const _DeckItem(this.assetPath, this.label, {this.isFile = false});
}

class _CharacterDeckScreenState extends State<CharacterDeckScreen> {
  @override
  void initState() {
    super.initState();
    if (!kIsWeb) CustomRosterService.instance.load();
  }

  List<_DeckItem> _baseItems() => [
        for (var i = 0; i < kCharImageAssets.length; i++)
          _DeckItem(kCharImageAssets[i], '${i + 1}'),
      ];

  List<_DeckItem> _boughtItems(PlayerProfile profile) => [
        for (final c in kExtraCharacters)
          if (profile.unlockedCharacters.contains(c.id))
            _DeckItem(c.asset, c.emoji),
      ];

  List<_DeckItem> _myPhotoItems() {
    if (kIsWeb) return const [];
    return [
      for (final e in CustomRosterService.instance.entries)
        _DeckItem(e.imagePath, e.name, isFile: true),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final m = MetaStrings.of(context);
    final profile = PlayerProfile.instance;

    return AnimatedBuilder(
      animation: Listenable.merge([profile, CustomRosterService.instance]),
      builder: (context, _) {
        final base = _baseItems();
        final bought = _boughtItems(profile);
        final mine = _myPhotoItems();
        final all = [...base, ...bought, ...mine];
        final activeCount =
            all.where((i) => !profile.deckExcluded.contains(i.assetPath)).length;

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
              if (!kIsWeb)
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
    final on = !profile.deckExcluded.contains(item.assetPath);
    return GestureDetector(
      onTap: () {
        Sfx.instance.pop();
        profile.setDeckIncluded(item.assetPath, !on);
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
                    child: item.isFile
                        ? Image.file(File(item.assetPath), fit: BoxFit.cover)
                        : Image.asset(item.assetPath, fit: BoxFit.cover),
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
