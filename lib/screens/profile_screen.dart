import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:url_launcher/url_launcher.dart';
import '../l10n/meta_strings.dart';
import '../models/achievement.dart';
import '../models/cosmetics.dart';
import '../services/player_profile.dart';
import 'character_shop_screen.dart';
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
  // --- クラシック ---
  BgmItem('op9-2-Nocturne.mp3', 'ノクターン Op.9-2', 'Nocturne Op.9-2', 0),
  BgmItem('bgm_ode_to_joy.wav', '歓喜の歌', 'Ode to Joy', 150),
  BgmItem('for_siciliano.mp3', 'シチリアーノ', 'Siciliano', 300),
  BgmItem('bgm_fur_elise.wav', 'エリーゼのために', 'Für Elise', 400),
  BgmItem('op.10-4.mp3', '練習曲 Op.10-4', 'Étude Op.10-4', 500),
  BgmItem('bgm_eine_kleine.wav', 'アイネ・クライネ', 'Eine kleine Nachtmusik', 700),
  BgmItem('c00Chopin_Fantaisie-Impromptu.mp3', '幻想即興曲', 'Fantaisie-Impromptu', 800),
  // --- 魔王魂（著作権フリー・クレジット表記済み） ---
  BgmItem('05_halzion.mp3', 'ハルジオン', 'Halzion', 250),
  BgmItem('08_burning_heart.mp3', 'バーニングハート', 'Burning Heart', 350),
  BgmItem('19_12345.mp3', '12345', '12345', 450),
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
    // ★未準備なら予約→読み込み完了と同時に自動再生★
    final playedNow = await _rewardAd.showOrQueue(onReward: () {
      PlayerProfile.instance.grantBonusCoins(60);
      Sfx.instance.reward(); // 報酬ゲットは盛大に（コイン＋ファンファーレ）
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(m.earnedCoins(50))));
      }
    });
    if (!mounted) return;
    if (!playedNow) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(m.adQueued)));
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
            _missionsCard(m, profile),
            const SizedBox(height: 16),
            _statsCard(m, profile),
            const SizedBox(height: 16),
            _awakenCard(m, profile),
            const SizedBox(height: 16),
            _titleCard(m, profile),
            const SizedBox(height: 16),
            _themeCard(m, profile),
            const SizedBox(height: 16),
            _dogCard(m, profile),
            const SizedBox(height: 16),
            _cheerCard(m, profile),
            const SizedBox(height: 16),
            _costumeCard(m, profile),
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
            const SizedBox(height: 10),
            // ★大きくド派手な「動画で+50コイン」ボタン（状態表示付き）★
            AnimatedBuilder(
              animation: _rewardAd,
              builder: (context, _) {
                final ready = _rewardAd.isReady;
                return SizedBox(
                  width: double.infinity,
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF43C46B), Color(0xFF2E9E52)],
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
                      onPressed: _watchAdForCoins,
                      icon: ready
                          ? const Icon(Icons.play_circle_fill, size: 28)
                          : const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.5,
                                color: Colors.white,
                              ),
                            ),
                      label: Text(ready ? m.watchAdBonus : m.adPreparing),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        shadowColor: Colors.transparent,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        textStyle: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ],
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () {
                Sfx.instance.pop();
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => const CharacterShopScreen()),
                );
              },
              icon: const Icon(Icons.storefront_rounded),
              label: Text(m.storeTitle),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF3A7BD5),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                textStyle: const TextStyle(
                    fontSize: 15, fontWeight: FontWeight.w900),
              ),
            ),
          ),
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
          row(m.cpuRatingLabel, '${p.cpuRating}'),
          row(m.bestDaily, '${p.bestDailyStreak}'),
          row(m.bestSession, '${p.bestSessionStreak}'),
          row(m.lifetimeCoins, '${p.lifetimeCoins}'),
        ],
      ),
    );
  }

  Widget _awakenCard(MetaStrings m, PlayerProfile p) {
    final pct = (p.awakenings * 5).toString();
    return _sectionCard(
      title: m.awakenTitle,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(m.awakenDesc,
              style: const TextStyle(fontSize: 12.5, height: 1.5)),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(m.awakenCount(p.awakenings),
                  style: const TextStyle(
                      fontSize: 15, fontWeight: FontWeight.w900)),
              Text(m.awakenMultiplier(pct),
                  style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF7B5CFF))),
            ],
          ),
          const SizedBox(height: 12),
          if (p.canAwaken)
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => _confirmAwaken(m, p),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF7B5CFF),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  textStyle: const TextStyle(
                      fontSize: 15, fontWeight: FontWeight.w900),
                ),
                child: Text(m.awakenButton),
              ),
            )
          else
            Text(m.awakenLocked,
                style: const TextStyle(fontSize: 12, color: Colors.black45)),
        ],
      ),
    );
  }

  Future<void> _confirmAwaken(MetaStrings m, PlayerProfile p) async {
    Sfx.instance.pop();
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(m.awakenConfirmTitle),
        content: Text(m.awakenConfirmBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(m.cancel),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF7B5CFF)),
            child: Text(m.awakenButton),
          ),
        ],
      ),
    );
    if (ok == true) {
      final done = await p.awaken();
      if (done) {
        Sfx.instance.victory();
        if (mounted) {
          ScaffoldMessenger.of(context)
              .showSnackBar(SnackBar(content: Text(m.awakenDone)));
        }
      }
    }
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
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(m.dressupDesc,
                  style: const TextStyle(fontSize: 13)),
            ),
          ),
          ...kHomeThemes.map((t) {
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
                  Sfx.instance.fanfare(); // アンロック成功は盛大に
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
          }),
        ],
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
          // 🐶 なつき度（あそぶほど上がって声援が変化）
          Row(
            children: [
              Text(
                '${dogBond(p.dogAffection).emoji} ${m.bondLabel}: '
                '${ja ? dogBond(p.dogAffection).nameJa : dogBond(p.dogAffection).nameEn}',
                style: const TextStyle(
                    fontWeight: FontWeight.bold, fontSize: 14),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: LinearProgressIndicator(
                    value: dogBondProgress(p.dogAffection),
                    minHeight: 8,
                    backgroundColor: Colors.grey.shade200,
                    valueColor: const AlwaysStoppedAnimation<Color>(
                        Color(0xFFFF8FB4)),
                  ),
                ),
              ),
            ],
          ),
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
                    width: 64,
                    height: 64,
                    padding: const EdgeInsets.all(4),
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
                      child: unlocked
                          ? SvgPicture.asset(d.asset, width: 50, height: 50)
                          : const Text('🔒',
                              style: TextStyle(fontSize: 26)),
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
  // チア応援団（最初から全員参加・ショーケース表示）
  // 📋 デイリーミッション（毎日リセット・達成でコイン）
  Widget _missionsCard(MetaStrings m, PlayerProfile p) {
    Widget mission({
      required String id,
      required String title,
      required int progress,
      required int goal,
      required int reward,
    }) {
      final done = progress >= goal;
      final claimed = p.missionClaimed.contains(id);
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 14)),
                  const SizedBox(height: 4),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: LinearProgressIndicator(
                      value: (progress / goal).clamp(0.0, 1.0),
                      minHeight: 8,
                      backgroundColor: Colors.grey.shade200,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        done
                            ? const Color(0xFF43C46B)
                            : const Color(0xFFFF4FA3),
                      ),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${progress.clamp(0, goal)} / $goal',
                    style: const TextStyle(
                        fontSize: 11, color: Colors.black54),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            claimed
                ? const Icon(Icons.check_circle, color: Color(0xFF4A7A2A))
                : ElevatedButton(
                    onPressed: done
                        ? () async {
                            final ok = await p.claimMission(id, reward);
                            if (!mounted) return;
                            if (ok) {
                              Sfx.instance.fanfare();
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                    content:
                                        Text(m.missionClaimedMsg(reward))),
                              );
                            }
                          }
                        : null,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8),
                      textStyle: const TextStyle(
                          fontSize: 12, fontWeight: FontWeight.w900),
                    ),
                    child: Text(done ? '$reward🪙' : '$reward🪙'),
                  ),
          ],
        ),
      );
    }

    return _sectionCard(
      title: '📋 ${m.dailyMissions}',
      child: Column(
        children: [
          mission(
            id: 'play3',
            title: '🎮 ${m.missionPlay3}',
            progress: p.missionPlays,
            goal: 3,
            reward: 30,
          ),
          mission(
            id: 'coin60',
            title: '🪙 ${m.missionCoin60}',
            progress: p.missionCoinsEarned,
            goal: 60,
            reward: 40,
          ),
          // ※オンライン対戦ミッションはv2.0.0のルール刷新で撤去
        ],
      ),
    );
  }

  // 🎽 応援団の衣装ショップ（コインで解放＆着せ替え）
  Widget _costumeCard(MetaStrings m, PlayerProfile p) {
    final ja = m.ja;
    return _sectionCard(
      title: '🎽 ${m.cheerCostume}',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(m.cheerCostumeDesc, style: const TextStyle(fontSize: 13)),
          const SizedBox(height: 6),
          ...kCheerCostumes.map((c) {
            final owned = p.unlockedCostumes.contains(c.id);
            final selected = p.selectedCostume == c.id;
            Widget trailing;
            if (selected) {
              trailing = Chip(
                label: Text(m.selected),
                backgroundColor: const Color(0xFFD7F5D7),
              );
            } else if (owned) {
              trailing = OutlinedButton(
                onPressed: () {
                  p.selectCostume(c.id);
                  Sfx.instance.pop();
                },
                child: Text(m.select),
              );
            } else {
              trailing = ElevatedButton(
                onPressed: () async {
                  final ok = await p.unlockCostume(c.id, c.cost);
                  if (!mounted) return;
                  if (ok) {
                    Sfx.instance.fanfare();
                    p.selectCostume(c.id); // 買ったら即着せ替え
                    ScaffoldMessenger.of(context)
                        .showSnackBar(SnackBar(content: Text(m.unlocked)));
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(m.notEnoughCoins)));
                  }
                },
                child: Text('${c.cost}🪙'),
              );
            }
            return ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: c.zoneGradient),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: selected
                        ? const Color(0xFF4A7A2A)
                        : Colors.grey.shade300,
                    width: 2,
                  ),
                ),
                child: Center(
                  child: Text(c.accessory.isEmpty ? '🎓' : c.accessory,
                      style: const TextStyle(fontSize: 20)),
                ),
              ),
              title: Text(ja ? c.nameJa : c.nameEn,
                  style: const TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Text(
                (ja ? c.cheersJa.first : c.cheersEn.first),
                style: const TextStyle(fontSize: 12, color: Colors.black54),
              ),
              trailing: trailing,
            );
          }),
        ],
      ),
    );
  }

  Widget _cheerCard(MetaStrings m, PlayerProfile p) {
    return _sectionCard(
      title: '📣 ${m.cheerSquad}',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(m.cheerSquadDesc, style: const TextStyle(fontSize: 13)),
          const SizedBox(height: 12),
          // 全メンバーを並べて紹介
          Center(
            child: Wrap(
              spacing: 14,
              runSpacing: 8,
              alignment: WrapAlignment.center,
              children: kAllCheerMembers
                  .map((a) => Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFF3F8),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                              color: const Color(0xFFFFC9E0), width: 1.5),
                        ),
                        child:
                            SvgPicture.asset(a, width: 48, height: 48),
                      ))
                  .toList(),
            ),
          ),
          const SizedBox(height: 8),
          Center(
            child: Text(
              m.cheerAllJoined,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: Color(0xFFB4326E),
              ),
            ),
          ),
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
                  Sfx.instance.fanfare(); // アンロック成功は盛大に
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
