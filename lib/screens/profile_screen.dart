import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../l10n/meta_strings.dart';
import '../models/achievement.dart';
import '../models/cosmetics.dart';
import '../services/player_profile.dart';
import '../services/reward_ad_helper.dart';
import '../services/sfx.dart';

/// アンロック可能なBGMカタログ（既存のショパン音源を活用）。
class BgmItem {
  final String asset;
  final String nameJa;
  final String nameEn;
  final int cost;
  const BgmItem(this.asset, this.nameJa, this.nameEn, this.cost);
}

const List<BgmItem> kBgmCatalog = [
  BgmItem('op9-2-Nocturne.mp3', 'ノクターン Op.9-2', 'Nocturne Op.9-2', 0),
  BgmItem('bgm_ode_to_joy.wav', '歓喜の歌', 'Ode to Joy', 150),
  BgmItem('for_siciliano.mp3', 'シチリアーノ', 'Siciliano', 300),
  BgmItem('bgm_fur_elise.wav', 'エリーゼのために', 'Für Elise', 400),
  BgmItem('op.10-4.mp3', '練習曲 Op.10-4', 'Étude Op.10-4', 500),
  BgmItem('bgm_eine_kleine.wav', 'アイネ・クライネ', 'Eine kleine Nachtmusik', 700),
  BgmItem('c00Chopin_Fantaisie-Impromptu.mp3', '幻想即興曲', 'Fantaisie-Impromptu', 800),
];

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final RewardAdHelper _rewardAd = RewardAdHelper();

  @override
  void initState() {
    super.initState();
    _rewardAd.load();
    // 画面を開いた時点で条件を満たす実績を解放
    WidgetsBinding.instance.addPostFrameCallback((_) {
      PlayerProfile.instance.refreshAchievements();
    });
  }

  @override
  void dispose() {
    _rewardAd.dispose();
    super.dispose();
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

  Future<void> _claimDaily() async {
    final m = MetaStrings.of(context);
    final profile = PlayerProfile.instance;
    final reward = await profile.claimDailyBonus();
    if (reward <= 0) return;
    Sfx.instance.coin();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(m.earnedCoins(reward))),
    );
  }

  Future<void> _watchAdForCoins() async {
    final m = MetaStrings.of(context);
    final shown = await _rewardAd.show(onReward: () {
      PlayerProfile.instance.grantBonusCoins(50);
      Sfx.instance.coin();
    });
    if (!mounted) return;
    if (!shown) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(m.adNotReady)));
    } else {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(m.earnedCoins(50))));
    }
  }

  @override
  Widget build(BuildContext context) {
    final m = MetaStrings.of(context);
    final profile = PlayerProfile.instance;

    return Scaffold(
      appBar: AppBar(
        title: Text(m.profileTitle),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: AnimatedBuilder(
              animation: profile,
              builder: (context, _) => Center(child: _coinChip(profile.coins)),
            ),
          ),
        ],
      ),
      body: AnimatedBuilder(
        animation: profile,
        builder: (context, _) => ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _dailyBonusCard(m, profile),
            const SizedBox(height: 16),
            _statsCard(m, profile),
            const SizedBox(height: 16),
            _titleCard(m, profile),
            const SizedBox(height: 16),
            _themeCard(m, profile),
            const SizedBox(height: 16),
            _dogCard(m, profile),
            const SizedBox(height: 16),
            _cheerCard(m, profile),
            const SizedBox(height: 16),
            _achievementsCard(m, profile),
            const SizedBox(height: 16),
            _bgmCard(m, profile),
            const SizedBox(height: 16),
            _resultMusicCard(m, profile),
            const SizedBox(height: 16),
            _supportCard(m),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _coinChip(int coins) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF3D6),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE6B54A)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('🪙', style: TextStyle(fontSize: 16)),
          const SizedBox(width: 4),
          Text('$coins',
              style: const TextStyle(
                  fontWeight: FontWeight.bold, color: Color(0xFF8A6A1E))),
        ],
      ),
    );
  }

  Widget _sectionCard({required String title, required Widget child}) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title,
                style: const TextStyle(
                    fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            child,
          ],
        ),
      ),
    );
  }

  Widget _dailyBonusCard(MetaStrings m, PlayerProfile p) {
    return _sectionCard(
      title: '📅 ${m.dailyBonus}',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(p.dailyStreak > 0 ? m.streakDays(p.dailyStreak) : m.comeBackTomorrow),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: p.canClaimDaily ? _claimDaily : null,
                  icon: const Text('🎁'),
                  label: Text(p.canClaimDaily ? m.claim : m.claimed),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
              ),
            ],
          ),
          if (RewardAdHelper.available) ...[
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: _watchAdForCoins,
              icon: const Icon(Icons.play_circle_outline),
              label: Text(m.watchAdBonus),
            ),
          ],
        ],
      ),
    );
  }

  Widget _statsCard(MetaStrings m, PlayerProfile p) {
    Widget row(String label, String value) => Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(label, style: const TextStyle(fontSize: 15)),
              Text(value,
                  style: const TextStyle(
                      fontSize: 15, fontWeight: FontWeight.bold)),
            ],
          ),
        );
    return _sectionCard(
      title: '📊 ${m.records}',
      child: Column(
        children: [
          row(m.gamesPlayed, '${p.totalGames}'),
          row(m.highScore, '${p.highScore}'),
          row(m.onlineGamesLabel, '${p.onlineGames}'),
          row(m.onlineWinsLabel, '${p.onlineWins}'),
          row(m.bestDaily, '${p.bestDailyStreak}'),
          row(m.bestSession, '${p.bestSessionStreak}'),
          row(m.lifetimeCoins, '${p.lifetimeCoins}'),
        ],
      ),
    );
  }

  Widget _achievementsCard(MetaStrings m, PlayerProfile p) {
    return _sectionCard(
      title: '🏆 ${m.achievements} (${p.unlockedAchievements.length}/${kAchievements.length})',
      child: Column(
        children: kAchievements.map((a) {
          final unlocked = p.unlockedAchievements.contains(a.id);
          return Opacity(
            opacity: unlocked ? 1.0 : 0.4,
            child: ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Text(unlocked ? a.emoji : '🔒',
                  style: const TextStyle(fontSize: 26)),
              title: Text(m.achTitle(a.id),
                  style: const TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Text(m.achDesc(a.id)),
              trailing: Text('+${a.rewardCoins}🪙',
                  style: TextStyle(
                      color: unlocked ? const Color(0xFF8A6A1E) : Colors.grey)),
            ),
          );
        }).toList(),
      ),
    );
  }

  // 称号一覧（累計コインで自動ランクアップ）
  Widget _titleCard(MetaStrings m, PlayerProfile p) {
    final ja = m.ja;
    final current = currentTitle(p.lifetimeCoins);
    return _sectionCard(
      title: '👑 ${m.titles}',
      child: Column(
        children: kPlayerTitles.map((t) {
          final unlocked = p.lifetimeCoins >= t.requiredLifetimeCoins;
          final isCurrent = t.requiredLifetimeCoins ==
              current.requiredLifetimeCoins;
          return Opacity(
            opacity: unlocked ? 1.0 : 0.4,
            child: ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Text(
                unlocked ? t.emoji : '🔒',
                style: const TextStyle(fontSize: 26),
              ),
              title: Text(
                ja ? t.nameJa : t.nameEn,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: isCurrent ? const Color(0xFFB8860B) : null,
                ),
              ),
              subtitle: Text(
                unlocked
                    ? (isCurrent ? m.currentTitleLabel : m.unlocked)
                    : m.coinsToUnlock(
                        t.requiredLifetimeCoins - p.lifetimeCoins,
                      ),
              ),
              trailing: isCurrent
                  ? const Icon(Icons.star, color: Color(0xFFFFB300))
                  : Text(
                      '🪙${t.requiredLifetimeCoins}',
                      style: const TextStyle(color: Colors.grey),
                    ),
            ),
          );
        }).toList(),
      ),
    );
  }

  // ホーム画面のきせかえ（コインで解放）
  Widget _themeCard(MetaStrings m, PlayerProfile p) {
    final ja = m.ja;
    return _sectionCard(
      title: '🎨 ${m.dressup}',
      child: Column(
        children: kHomeThemes.map((t) {
          final owned = p.unlockedThemes.contains(t.id);
          final selected = p.selectedTheme == t.id;
          Widget trailing;
          if (selected) {
            trailing = Chip(
              label: Text(m.selected),
              backgroundColor: const Color(0xFFD7F5D7),
            );
          } else if (owned) {
            trailing = OutlinedButton(
              onPressed: () {
                p.selectTheme(t.id);
                Sfx.instance.pop();
              },
              child: Text(m.select),
            );
          } else {
            trailing = ElevatedButton(
              onPressed: () async {
                final ok = await p.unlockTheme(t.id, t.cost);
                if (!mounted) return;
                if (ok) {
                  Sfx.instance.coin();
                  ScaffoldMessenger.of(context)
                      .showSnackBar(SnackBar(content: Text(m.unlocked)));
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(m.notEnoughCoins)));
                }
              },
              child: Text('${t.cost}🪙'),
            );
          }
          return ListTile(
            contentPadding: EdgeInsets.zero,
            // テーマのグラデーションをプレビュー表示
            leading: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: t.gradient,
                ),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: selected
                      ? const Color(0xFF4A7A2A)
                      : Colors.grey.shade300,
                  width: 2,
                ),
              ),
              child: Center(
                child: Text(t.emoji, style: const TextStyle(fontSize: 20)),
              ),
            ),
            title: Text(
              ja ? t.nameJa : t.nameEn,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Text(
              t.cost == 0 ? m.free : (owned ? m.unlocked : '${t.cost} ${m.coins}'),
            ),
            trailing: trailing,
          );
        }).toList(),
      ),
    );
  }

  // 応援わんちゃん図鑑（累計コインで自動解放）
  Widget _dogCard(MetaStrings m, PlayerProfile p) {
    final ja = m.ja;
    return _sectionCard(
      title: '🐾 ${m.dogSquad}',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(m.dogSquadDesc, style: const TextStyle(fontSize: 13)),
          const SizedBox(height: 10),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: kDogCompanions.map((d) {
              final unlocked =
                  p.lifetimeCoins >= d.requiredLifetimeCoins;
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: unlocked
                          ? const Color(0xFFFFF3D6)
                          : Colors.grey.shade200,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: unlocked
                            ? const Color(0xFFE6B54A)
                            : Colors.grey.shade400,
                        width: 2,
                      ),
                    ),
                    child: Center(
                      child: Text(
                        unlocked ? d.emoji : '🔒',
                        style: const TextStyle(fontSize: 26),
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    unlocked
                        ? (ja ? d.nameJa : d.nameEn)
                        : '🪙${d.requiredLifetimeCoins}',
                    style: const TextStyle(fontSize: 12),
                  ),
                ],
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  // チア応援団（コインでレベルアップ）
  Widget _cheerCard(MetaStrings m, PlayerProfile p) {
    final ja = m.ja;
    final isMax = p.cheerLevel >= kCheerStages.length;
    final nextStage = isMax ? null : kCheerStages[p.cheerLevel];
    return _sectionCard(
      title: '📣 ${m.cheerSquad}',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(m.cheerSquadDesc, style: const TextStyle(fontSize: 13)),
          const SizedBox(height: 10),
          // 現在のメンバー表示
          Row(
            children: [
              Text(
                m.cheerLevelLabel(p.cheerLevel),
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(width: 12),
              Text(
                p.cheerLevel > 0
                    ? cheerMembers(p.cheerLevel).join(' ')
                    : '—',
                style: const TextStyle(fontSize: 24),
              ),
            ],
          ),
          const SizedBox(height: 10),
          // レベル一覧
          ...kCheerStages.map((s) {
            final owned = p.cheerLevel >= s.level;
            final isNext = nextStage?.level == s.level;
            return Opacity(
              opacity: owned || isNext ? 1.0 : 0.4,
              child: ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Text(
                  owned ? s.members.last : '🔒',
                  style: const TextStyle(fontSize: 26),
                ),
                title: Text(
                  'Lv.${s.level} ${ja ? s.nameJa : s.nameEn}',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Text(s.members.join(' ')),
                trailing: owned
                    ? const Icon(Icons.check_circle,
                        color: Color(0xFF4A7A2A))
                    : isNext
                        ? ElevatedButton(
                            onPressed: () async {
                              final ok =
                                  await p.upgradeCheer(s.upgradeCost);
                              if (!mounted) return;
                              if (ok) {
                                Sfx.instance.coin();
                                ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text(m.unlocked)));
                              } else {
                                ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                        content: Text(m.notEnoughCoins)));
                              }
                            },
                            child: Text('${s.upgradeCost}🪙'),
                          )
                        : Text('${s.upgradeCost}🪙',
                            style: const TextStyle(color: Colors.grey)),
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _bgmCard(MetaStrings m, PlayerProfile p) {
    final ja = m.ja;
    return _sectionCard(
      title: '🎵 ${m.selectBgm}',
      child: Column(
        children: kBgmCatalog.map((b) {
          final owned = p.unlockedBgm.contains(b.asset);
          final selected = p.selectedBgm == b.asset;
          Widget trailing;
          if (selected) {
            trailing = Chip(
              label: Text(m.selected),
              backgroundColor: const Color(0xFFD7F5D7),
            );
          } else if (owned) {
            trailing = OutlinedButton(
              onPressed: () {
                p.selectBgm(b.asset);
                Sfx.instance.pop();
              },
              child: Text(m.select),
            );
          } else {
            trailing = ElevatedButton(
              onPressed: () async {
                final ok = await p.unlockBgm(b.asset, b.cost);
                if (!mounted) return;
                if (ok) {
                  Sfx.instance.coin();
                  ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(m.unlocked)));
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(m.notEnoughCoins)));
                }
              },
              child: Text('${b.cost}🪙'),
            );
          }
          return ListTile(
            contentPadding: EdgeInsets.zero,
            leading: Icon(selected ? Icons.music_note : Icons.music_note_outlined,
                color: selected ? const Color(0xFF4A7A2A) : Colors.grey),
            title: Text(ja ? b.nameJa : b.nameEn),
            subtitle: Text(b.cost == 0 ? m.free : (owned ? m.unlocked : '${b.cost} ${m.coins}')),
            trailing: trailing,
          );
        }).toList(),
      ),
    );
  }

  // リザルト画面の曲を選ぶ（シャイニングスター＋アンロック済みクラシック曲）
  Widget _resultMusicCard(MetaStrings m, PlayerProfile p) {
    final ja = m.ja;
    // 選択肢: シャイニングスター（常時）＋BGMショップでアンロック済みの曲
    final options = <MapEntry<String, String>>[
      MapEntry('shining_star.mp3', ja ? 'シャイニングスター' : 'Shining Star'),
      ...kBgmCatalog
          .where((b) => p.unlockedBgm.contains(b.asset))
          .map((b) => MapEntry(b.asset, ja ? b.nameJa : b.nameEn)),
    ];
    return _sectionCard(
      title: '🎺 ${m.resultMusic}',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(m.resultMusicDesc, style: const TextStyle(fontSize: 13)),
          const SizedBox(height: 8),
          ...options.map((o) {
            final selected = p.selectedResultBgm == o.key;
            return ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Icon(
                selected ? Icons.music_note : Icons.music_note_outlined,
                color: selected ? const Color(0xFF4A7A2A) : Colors.grey,
              ),
              title: Text(o.value),
              trailing: selected
                  ? Chip(
                      label: Text(m.selected),
                      backgroundColor: const Color(0xFFD7F5D7),
                    )
                  : OutlinedButton(
                      onPressed: () {
                        p.selectResultBgm(o.key);
                        Sfx.instance.pop();
                      },
                      child: Text(m.select),
                    ),
            );
          }),
        ],
      ),
    );
  }

  Widget _supportCard(MetaStrings m) {
    return Card(
      elevation: 2,
      color: const Color(0xFFFFF8EC),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('☕ ${m.supportDev}',
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text(m.supportBody, style: const TextStyle(fontSize: 14)),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _launchBmc,
                icon: const Text('☕', style: TextStyle(fontSize: 18)),
                label: Text(m.supportDev),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFFDD00),
                  foregroundColor: Colors.black87,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
