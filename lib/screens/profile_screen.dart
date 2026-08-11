import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../l10n/meta_strings.dart';
import '../models/achievement.dart';
import '../models/bgm_catalog.dart';
import '../models/cosmetics.dart';
import '../models/shop_items.dart';
import '../services/bgm.dart';
import '../services/daily_reminder.dart';
import '../services/player_profile.dart';
import '../services/reward_ad_helper.dart';
import '../services/rewarded_interstitial_helper.dart';
import '../services/review_prompt.dart';
import '../services/sfx.dart';
import '../widgets/banner_ad_slot.dart';
import '../widgets/stamp_calendar.dart';
import '../services/app_analytics.dart';
import 'character_deck_screen.dart';
import 'character_shop_screen.dart';
import 'noah_story_screen.dart';
import 'player_selection_screen.dart';
import 'report_screen.dart';
import 'story_screen.dart';

const String _kDevPassphrase = 'Toriumi';
const int _kRewardedInterCoins = 90;

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});
  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen>
    with SingleTickerProviderStateMixin {
  final RewardAdHelper _rewardAd = RewardAdHelper(placement: 'profile');
  late final TabController _tabController;
  int _tabIndex = 0;

  @override
  void initState() {
    super.initState();
    AppAnalytics.screen('profile');
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) setState(() => _tabIndex = _tabController.index);
    });
    _rewardAd.load();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      PlayerProfile.instance.refreshAchievements();
    });
  }

  @override
  void dispose() {
    Bgm.instance.stopHome();
    _rewardAd.dispose();
    _tabController.dispose();
    super.dispose();
  }

  // ── shared helpers ──

  Widget _sectionCard({required String title, required Widget child, Color? color}) {
    return Card(
      elevation: 1.5,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      color: color,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            child,
          ],
        ),
      ),
    );
  }

  Widget _chipRow(String emoji, String label, String value, {Color color = const Color(0xFF3A7BD5)}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 20)),
          const SizedBox(width: 10),
          Expanded(child: Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w900))),
          Text(value, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: color)),
        ],
      ),
    );
  }

  // ═══════════════ TAB 1: 戦績 ═══════════════

  Widget _statsTab(MetaStrings m, PlayerProfile p) {
    final rank = cpuRankForRating(p.cpuRating);
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // ── プレイヤーカード ──
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF3A7BD5), Color(0xFF17408B)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [BoxShadow(color: const Color(0xFF3A7BD5).withValues(alpha: 0.35), blurRadius: 16, offset: const Offset(0, 6))],
          ),
          child: Column(
            children: [
              Container(
                width: 72, height: 72,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 3),
                  color: const Color(0xFF2B5CA5),
                ),
                child: Center(
                  child: Text(rank.emoji, style: const TextStyle(fontSize: 36)),
                ),
              ),
              const SizedBox(height: 8),
              Text(m.ja ? rank.nameJa : rank.nameEn, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Colors.white)),
              if (p.awakenings > 0)
                Text('🌌×${p.awakenings}', style: const TextStyle(fontSize: 13, color: Color(0xFFFFC02E))),
              const SizedBox(height: 4),
              Text('Rating ${p.cpuRating}', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: Color(0xFFFFC02E))),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _statColumn('${p.cpuWins}', m.ja ? '勝' : 'W'),
                  _statColumn('${p.cpuLosses}', m.ja ? '敗' : 'L'),
                  _statColumn('${p.totalGames}', m.ja ? '試合' : 'Games'),
                  _statColumn('${p.highScore}', m.ja ? '最高' : 'Best'),
                  _statColumn('${p.bestSessionStreak}', m.ja ? '連勝' : 'Streak'),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        // ── 通算成績 ──
        Row(
          children: [
            Expanded(
              child: _chipRow('🪙', m.ja ? 'コイン' : 'Coins', '${p.coins}', color: const Color(0xFFE8A400)),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _chipRow('💰', m.ja ? '生涯獲得' : 'Lifetime', '${p.lifetimeCoins}', color: const Color(0xFFB8860B)),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: _chipRow('🔥', m.ja ? '連続日数' : 'Streak', '${p.dailyStreak}', color: const Color(0xFFE8663C)),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _chipRow('📅', m.ja ? '最長連続' : 'Best streak', '${p.bestDailyStreak}', color: const Color(0xFF8A5AC2)),
            ),
          ],
        ),
        const SizedBox(height: 16),
        // ── CPU段位 ──
        _sectionCard(
          title: '🤖 ${m.ja ? "CPU段位" : "CPU Rank"}',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _rankProgress(rank, p),
              const SizedBox(height: 8),
              Row(
                children: [
                  _rankBadge('🐣', 'Easy', '${p.cpuEasyWins}W'),
                  const SizedBox(width: 8),
                  _rankBadge('🙂', 'Normal', '${p.cpuNormalWins}W'),
                  const SizedBox(width: 8),
                  _rankBadge('🔥', 'Hard', '${p.cpuHardWins}W'),
                  const SizedBox(width: 8),
                  _rankBadge('👹', 'Oni', '${p.cpuOniWins}W'),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        // ── ボタン ──
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _outlinedButton('📊 ${m.ja ? "成績レポート" : "Stats Report"}', const Color(0xFF2E9E5B), () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => const ReportScreen()));
            }),
            _outlinedButton('🃏 ${m.tabPairs}', const Color(0xFF3A7BD5), () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => const PlayerSelectionScreen()));
            }),
            _outlinedButton('📖 ${m.ja ? "ストーリー" : "Story"}', const Color(0xFF7A5AC2), () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => const StoryListScreen()));
            }),
            _outlinedButton('🚀 ${m.ja ? "プロジェクト・ノア" : "Project Noah"}', const Color(0xFF1D3A6B), () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => const NoahStoryScreen()));
            }),
          ],
        ),
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _statColumn(String value, String label) => Column(
    children: [
      Text(value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: Colors.white)),
      Text(label, style: const TextStyle(fontSize: 10, color: Color(0xCCFFFFFF))),
    ],
  );

  Widget _rankProgress(CpuRank rank, PlayerProfile p) {
    final next = rank.next;
    if (next == null) {
      return Text(p.awakenings > 0
          ? '🏆 ${p.ja ? "最高段位！覚醒 ${p.awakenings}回" : "Max rank! ${p.awakenings} awakenings"}'
          : '🏆 ${p.ja ? "最高段位！" : "Max rank!"}',
          style: const TextStyle(fontWeight: FontWeight.w900, color: Color(0xFFE8A400)));
    }
    final currentMin = rank.minRating;
    final nextMin = next.minRating;
    final progress = (p.cpuRating - currentMin) / (nextMin - currentMin);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('${rank.emoji} ${rank.name(p.ja)} → ${next.emoji} ${next.name(p.ja)}',
            style: const TextStyle(fontSize: 13)),
        const SizedBox(height: 4),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(value: progress.clamp(0.0, 1.0), minHeight: 8,
              backgroundColor: Colors.black12, color: const Color(0xFF8A5AC2)),
        ),
        Text('Rating ${p.cpuRating} / $nextMin', style: const TextStyle(fontSize: 11, color: Colors.black54)),
      ],
    );
  }

  Widget _rankBadge(String emoji, String label, String count) => Expanded(
    child: Container(
      padding: const EdgeInsets.symmetric(vertical: 6),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(children: [
        Text(emoji, style: const TextStyle(fontSize: 20)),
        Text(label, style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w900)),
        Text(count, style: const TextStyle(fontSize: 11)),
      ]),
    ),
  );

  Widget _outlinedButton(String label, Color color, VoidCallback onTap) => OutlinedButton(
    onPressed: onTap,
    style: OutlinedButton.styleFrom(
      foregroundColor: color,
      side: BorderSide(color: color.withValues(alpha: 0.5)),
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
    ),
    child: Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w900)),
  );

  // ═══════════════ TAB 2: カスタマイズ ═══════════════

  Widget _customizeTab(MetaStrings m, PlayerProfile p) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // きせかえ
        _sectionCard(
          title: '🎨 ${m.ja ? "きせかえ" : "Theme"}',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Wrap(spacing: 8, runSpacing: 8, children: [
                for (final themeId in p.unlockedThemes)
                  _choiceChip(
                    homeThemeById(themeId).name(p.ja),
                    p.selectedTheme == themeId,
                    () { p.selectTheme(themeId); Sfx.instance.pop(); },
                    homeThemeById(themeId).gradient.last,
                  ),
              ]),
            ],
          ),
        ),
        const SizedBox(height: 16),
        // 🛍 キャラクター
        _sectionCard(
          title: '🛍 ${m.tabShop}',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(m.ja
                  ? '${p.unlockedCharacters.length}体のキャラを所持中'
                  : 'Own ${p.unlockedCharacters.length} characters',
                  style: const TextStyle(fontSize: 12, color: Colors.black54)),
              const SizedBox(height: 10),
              Row(children: [
                _outlinedButton(m.shopTabLabel, const Color(0xFFE8663C), () {
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const CharacterShopScreen(embedded: true)));
                }),
                const SizedBox(width: 8),
                _outlinedButton(m.ja ? 'デッキ' : 'Deck', const Color(0xFF8A5AC2), () {
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const CharacterDeckScreen()));
                }),
              ]),
            ],
          ),
        ),
        const SizedBox(height: 16),
        // ほめボイス+お守り+名刺スキン
        _sectionCard(
          title: '🔧 ${m.ja ? "拡張アイテム" : "Extras"}',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(m.ja ? 'ほめボイス' : 'Praise Voice', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w900)),
              const SizedBox(height: 6),
              Wrap(spacing: 6, runSpacing: 6, children: [
                for (final v in kVoiceItems)
                  if (p.unlockedVoices.contains(v.id))
                    _choiceChip(v.name(p.ja), p.selectedVoice == v.id,
                        () { p.selectVoice(v.id); Sfx.instance.pop(); },
                        const Color(0xFF7A5AC2)),
              ]),
              const SizedBox(height: 14),
              Text(m.ja ? 'お守り' : 'Charm', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w900)),
              const SizedBox(height: 6),
              Wrap(spacing: 6, runSpacing: 6, children: [
                for (final c in kCharmItems)
                  if (p.unlockedCharms.contains(c.id))
                    _choiceChip(c.name(p.ja), p.selectedCharm == c.id,
                        () { p.selectCharm(c.id); Sfx.instance.pop(); },
                        const Color(0xFFE8A400)),
              ]),
            ],
          ),
        ),
        const SizedBox(height: 16),
        // 実績
        _sectionCard(
          title: '🏆 ${m.ja ? "実績" : "Achievements"} (${p.unlockedAchievements.length}/${kAchievements.length})',
          child: GridView.builder(
            shrinkWrap: true, physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 4, childAspectRatio: 0.85),
            itemCount: kAchievements.length,
            itemBuilder: (_, i) {
              final a = kAchievements[i]; final unlocked = p.unlockedAchievements.contains(a.id);
              return Opacity(
                opacity: unlocked ? 1 : 0.35,
                child: Column(
                  children: [
                    Text(a.emoji, style: const TextStyle(fontSize: 28)),
                    Text(a.name(p.ja), textAlign: TextAlign.center,
                        style: const TextStyle(fontSize: 10)),
                    if (unlocked) Text('🪙${a.rewardCoins}',
                        style: const TextStyle(fontSize: 9, color: Color(0xFF8A6A1E))),
                  ],
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _choiceChip(String label, bool selected, VoidCallback onTap, Color color) => GestureDetector(
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: selected ? color : Colors.transparent,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color, width: selected ? 2 : 1),
      ),
      child: Text(label, style: TextStyle(
          fontSize: 13, fontWeight: FontWeight.w900,
          color: selected ? Colors.white : color)),
    ),
  );

  // ═══════════════ TAB 3: 設定 ═══════════════

  Widget _settingsTab(MetaStrings m, PlayerProfile p) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // 🎁 デイリーボーナス
        _sectionCard(
          title: '📅 ${m.dailyBonus}',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(p.dailyStreak > 0 ? m.streakDays(p.dailyStreak) : m.comeBackTomorrow),
              const SizedBox(height: 10),
              _rewardPreview(m),
              const SizedBox(height: 12),
              const StampCalendar(),
              const SizedBox(height: 12),
              Row(children: [
                Expanded(child: ElevatedButton.icon(
                  onPressed: p.canClaimDaily ? _claimDaily : null,
                  icon: const Text('🎁'),
                  label: Text(p.canClaimDaily ? m.claim : m.claimed),
                  style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 14)),
                )),
              ]),
              if (RewardedInterstitialHelper.available) ...[
                const SizedBox(height: 8),
                SizedBox(width: double.infinity, child: OutlinedButton.icon(
                  onPressed: _watchRewardedInterstitial,
                  icon: const Icon(Icons.play_circle_outline),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFFE8663C),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  label: Text(m.ja
                      ? '🎬 ${m.ja ? "動画を見て" : "Watch video for"} 🪙$_kRewardedInterCoins'
                      : '🎬 Watch a video for 🪙$_kRewardedInterCoins'),
                )),
              ],
            ],
          ),
        ),
        const SizedBox(height: 16),
        // 🎵 BGM
        _sectionCard(
          title: '🎵 ${m.ja ? "BGM" : "Music"}',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(m.bgmEnabledLabel),
                subtitle: Text(m.bgmEnabledHint, style: const TextStyle(fontSize: 11.5)),
                value: p.bgmEnabled, onChanged: (v) { p.setBgmEnabled(v); Sfx.instance.pop(); },
              ),
              _homeMusicCard(m, p),
              const SizedBox(height: 10),
              _resultMusicCard(m, p),
              const SizedBox(height: 10),
              _gameMusicCard(m, p),
            ],
          ),
        ),
        const SizedBox(height: 16),
        // 🔔 通知
        _sectionCard(
          title: '🔔 ${m.ja ? "通知" : "Notifications"}',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [
                Expanded(child: Text(m.ja ? '毎日リマインド' : 'Daily reminder',
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w900))),
                Text('${p.reminderHour}:00', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900)),
              ]),
              const SizedBox(height: 2),
              Text(m.ja ? '19時にプッシュ通知でお知らせします' : 'Sends a push notification at 7 PM',
                  style: const TextStyle(fontSize: 11, color: Colors.black54)),
              const SizedBox(height: 10),
              ElevatedButton(onPressed: _setReminder, child: Text(m.ja ? '時間を変更' : 'Change time')),
            ],
          ),
        ),
        const SizedBox(height: 16),
        // 🌌 覚醒
        if (p.canAwaken)
          _sectionCard(
            title: '🌌 ${m.ja ? "覚醒（プレステージ）" : "Awaken (Prestige)"}',
            color: const Color(0xFFFFF3D6),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(m.ja
                    ? 'レーティングを1000にリセットし、永続的なコインボーナスが増えます'
                    : 'Reset rating to 1000 for a permanent coin bonus',
                    style: const TextStyle(fontSize: 13)),
                Text(m.ja
                    ? 'コイン倍率: ${(p.coinMultiplier * 100).toStringAsFixed(0)}%'
                    : 'Coin multiplier: ${(p.coinMultiplier * 100).toStringAsFixed(0)}%',
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: Color(0xFFE8A400))),
                const SizedBox(height: 8),
                ElevatedButton(
                  onPressed: () => _doAwaken(m, p),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFFC02E),
                    foregroundColor: const Color(0xFF5A4A1E),
                    minimumSize: const Size.fromHeight(48),
                  ),
                  child: Text(m.ja ? '🌌 覚醒する' : '🌌 Awaken', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w900)),
                ),
              ],
            ),
          ),
        const SizedBox(height: 16),
        // 応援
        _sectionCard(
          title: '☕ ${m.ja ? "応援" : "Support"}',
          child: Column(
            children: [
              Text(m.ja
                  ? 'ひとことでも書いてもらえると、見つけてもらいやすくなります。'
                  : 'Even one line helps others find this app!',
                  style: const TextStyle(fontSize: 12, height: 1.5)),
              const SizedBox(height: 10),
              Row(children: [
                Expanded(child: ElevatedButton.icon(
                  onPressed: _launchBmc, icon: const Text('☕'),
                  label: const Text('Buy Me a Coffee'),
                )),
                const SizedBox(width: 8),
                Expanded(child: OutlinedButton.icon(
                  onPressed: () => openStoreReview(),
                  icon: const Text('⭐'),
                  label: Text(m.ja ? 'レビュー' : 'Review'),
                )),
              ]),
            ],
          ),
        ),
        const SizedBox(height: 16),
        // 🛠 開発者
        _devModeCard(m, p),
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _rewardPreview(MetaStrings m) {
    final faces = kCharImageAssets.take(4).toList();
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 10, 8, 10),
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [Color(0xFFFFF6D8), Color(0xFFFFE3EE)]),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFFFD46B), width: 1.5),
      ),
      child: Row(children: [
        const Text('🪙', style: TextStyle(fontSize: 24)),
        const SizedBox(width: 6),
        for (final f in faces)
          Padding(padding: const EdgeInsets.only(right: 6), child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.asset(f, width: 30, height: 30, fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => const Text('🙂', style: TextStyle(fontSize: 20))),
          )),
        Expanded(child: Text(
          m.ja ? 'コインとキャラが もらえます' : 'Earn coins & characters',
          textAlign: TextAlign.right,
          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: Color(0xFF8A6A1E)),
        )),
      ]),
    );
  }

  // ═══════════ actions ═══════════

  Future<void> _launchBmc() async {
    final m = MetaStrings.of(context);
    final ok = await launchUrl(Uri.parse('https://buymeacoffee.com/toriumi'), mode: LaunchMode.externalApplication);
    if (!ok && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(m.couldNotOpenLink)));
    }
  }

  Future<void> _claimDaily() async {
    final m = MetaStrings.of(context);
    final p = PlayerProfile.instance;
    final reward = await p.claimDailyBonus();
    if (reward <= 0) return;
    Sfx.instance.coin();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(m.earnedCoins(reward))));
    }
  }

  Future<void> _watchRewardedInterstitial() async {
    if (!await RewardedInterstitialHelper.confirm(context, coins: _kRewardedInterCoins)) return;
    final shown = await RewardedInterstitialHelper.instance.show(
      placement: 'profile_daily',
      onReward: () {
        PlayerProfile.instance.grantBonusCoins(_kRewardedInterCoins);
        Sfx.instance.reward();
      },
    );
    if (!shown && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(MetaStrings.of(context).storeAdLoading)));
    }
  }

  Future<void> _setReminder() async {
    final m = MetaStrings.of(context);
    final p = PlayerProfile.instance;
    final hour = await showDialog<int>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(m.ja ? '通知時間' : 'Reminder time'),
        content: StatefulBuilder(
          builder: (_, setSt) => Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('${p.reminderHour}:00', style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w900)),
              Slider(value: p.reminderHour.toDouble(), min: 6, max: 23, divisions: 17,
                  label: '${p.reminderHour}:00',
                  onChanged: (v) { p.setReminderHour(v.round()); setSt(() {}); }),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text(m.ja ? '閉じる' : 'Close')),
          TextButton(onPressed: () { DailyReminder.instance.reschedule(); Navigator.pop(ctx, p.reminderHour); }, child: Text(m.ja ? '保存' : 'Save')),
        ],
      ),
    );
  }

  Future<void> _doAwaken(MetaStrings m, PlayerProfile p) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('🌌 ${m.ja ? "覚醒しますか？" : "Awaken?"}'),
        content: Text(m.ja
            ? 'レーティングが1000に戻りますが、コイン獲得量が永続的に増えます。何度でも繰り返せます。'
            : 'Rating resets to 1000 but you earn coins faster forever. Repeatable.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(m.ja ? 'やめる' : 'Cancel')),
          ElevatedButton(onPressed: () => Navigator.pop(ctx, true), child: Text(m.ja ? '覚醒する！' : 'Awaken!')),
        ],
      ),
    );
    if (ok == true) {
      p.awaken();
      Sfx.instance.fanfare();
      if (mounted) setState(() {});
    }
  }

  // ═══════════ BGM cards ═══════════

  Widget _homeMusicCard(MetaStrings m, PlayerProfile p) {
    final ja = p.ja;
    final options = <MapEntry<String, String>>[
      MapEntry(kHomeBgmRandom, ja ? 'おまかせ（シチリアーノ / 運命）' : 'Shuffle (Siciliano / Fate)'),
      ...kBgmCatalog.where((b) => p.unlockedBgm.contains(b.asset)).map((b) => MapEntry(b.asset, b.name(ja))),
    ];
    return _sectionCard(
      title: '🏠 ${m.homeMusic}',
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(m.homeMusicDesc, style: const TextStyle(fontSize: 13)),
        const SizedBox(height: 8),
        ...options.map((o) {
          final selected = p.selectedHomeBgm == o.key;
          return ListTile(
            contentPadding: EdgeInsets.zero,
            leading: Icon(selected ? Icons.music_note : Icons.music_note_outlined, color: selected ? const Color(0xFF4A7A2A) : Colors.grey),
            title: Text(o.value),
            trailing: selected
                ? Chip(label: Text(m.selected), backgroundColor: const Color(0xFFD7F5D7))
                : OutlinedButton(
                    onPressed: () async { await p.selectHomeBgm(o.key); Sfx.instance.pop(); await Bgm.instance.restartCurrent(); },
                    child: Text(m.select),
                  ),
          );
        }),
      ]),
    );
  }

  Widget _resultMusicCard(MetaStrings m, PlayerProfile p) {
    final ja = p.ja;
    final options = <MapEntry<String, String>>[
      MapEntry(kResultBgmRandom, ja ? 'おまかせ（勝利の行進曲から）' : 'Shuffle (victory marches)'),
      ...kBgmCatalog.where((b) => p.unlockedBgm.contains(b.asset)).map((b) => MapEntry(b.asset, b.name(ja))),
    ];
    return _sectionCard(
      title: '🎺 ${m.resultMusic}',
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(m.resultMusicDesc, style: const TextStyle(fontSize: 13)),
        const SizedBox(height: 8),
        ...options.map((o) {
          final selected = p.selectedResultBgm == o.key;
          return ListTile(
            contentPadding: EdgeInsets.zero,
            leading: Icon(selected ? Icons.music_note : Icons.music_note_outlined, color: selected ? const Color(0xFF4A7A2A) : Colors.grey),
            title: Text(o.value),
            trailing: selected
                ? Chip(label: Text(m.selected), backgroundColor: const Color(0xFFD7F5D7))
                : OutlinedButton(
                    onPressed: () async { await p.selectResultBgm(o.key); Sfx.instance.pop(); Bgm.instance.preview(o.key); },
                    child: Text(m.select),
                  ),
          );
        }),
      ]),
    );
  }

  Widget _gameMusicCard(MetaStrings m, PlayerProfile p) {
    final ja = p.ja;
    final options = kBgmCatalog.where((b) => p.unlockedBgm.contains(b.asset) || b.cost == 0).toList();
    return _sectionCard(
      title: '🎮 ${m.ja ? "試合中の曲" : "Game BGM"}',
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        ...options.map((b) {
          final selected = p.selectedBgm == b.asset;
          final owned = p.unlockedBgm.contains(b.asset);
          return ListTile(
            contentPadding: EdgeInsets.zero,
            leading: Icon(selected ? Icons.music_note : Icons.music_note_outlined, color: selected ? const Color(0xFF4A7A2A) : Colors.grey),
            title: Text(ja ? b.nameJa : b.nameEn),
            subtitle: owned ? null : Text('${b.cost} ${m.coins}', style: const TextStyle(fontSize: 11)),
            trailing: selected
                ? Chip(label: Text(m.selected), backgroundColor: const Color(0xFFD7F5D7))
                : OutlinedButton(
                    onPressed: owned
                        ? () async { await p.selectBgm(b.asset); Sfx.instance.pop(); await Bgm.instance.restartCurrent(); }
                        : () => _buyBgm(b, m, p),
                    child: Text(owned ? m.select : '${b.cost}🪙'),
                  ),
          );
        }),
        if (kBgmCatalog.any((b) => b.needsCredit))
          Padding(padding: const EdgeInsets.only(top: 8), child: Text('🎵 魔王魂', style: const TextStyle(fontSize: 10, color: Colors.black38))),
      ]),
    );
  }

  Future<void> _buyBgm(BgmItem b, MetaStrings m, PlayerProfile p) async {
    if (p.coins < b.cost) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(m.needMoreCoins(b.cost - p.coins))));
      return;
    }
    final ok = await p.unlockBgm(b.asset, b.cost);
    if (ok) {
      await p.selectBgm(b.asset);
      Sfx.instance.fanfare();
      await Bgm.instance.restartCurrent();
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(m.shopBought)));
    }
  }

  // ═══════════ dev mode ═══════════

  Widget _devModeCard(MetaStrings m, PlayerProfile p) {
    if (!p.devMode) {
      return ListTile(
        title: Text(m.ja ? '🛠 開発者モード' : '🛠 Dev Mode', style: const TextStyle(fontSize: 10, color: Colors.black26)),
        onTap: () => _promptDevPassphrase(m, p),
      );
    }
    return _sectionCard(
      title: '🛠 ${m.ja ? "開発者モード" : "Dev Mode"}',
      child: Column(children: [
        SwitchListTile(contentPadding: EdgeInsets.zero, title: const Text('Dev Mode'), value: p.devMode, onChanged: (_) => p.setDevMode(false)),
        OutlinedButton(onPressed: () { p.grantBonusCoins(999); Sfx.instance.coin(); }, child: const Text('🪙 +999')),
        OutlinedButton(onPressed: () { for (final c in kExtraCharacters) { if (!p.unlockedCharacters.contains(c.id)) p.unlockCharacter(c.id, 0); } Sfx.instance.fanfare(); }, child: const Text('🎭 全キャラ')),
        OutlinedButton(onPressed: () { for (final a in kAchievements) { if (!p.unlockedAchievements.contains(a.id)) { p.unlockedAchievements.add(a.id); p.coins += a.rewardCoins; } } p.notifyListeners(); Sfx.instance.fanfare(); }, child: const Text('🏆 全実績')),
      ]),
    );
  }

  Future<void> _promptDevPassphrase(MetaStrings m, PlayerProfile p) async {
    final ctrl = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Dev Mode'),
        content: TextField(controller: ctrl, obscureText: true, decoration: const InputDecoration(hintText: 'Passphrase')),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('OK')),
        ],
      ),
    );
    if (ok == true && ctrl.text == _kDevPassphrase) {
      p.setDevMode(true);
      Sfx.instance.fanfare();
      if (mounted) setState(() {});
    }
  }

  // ═══════════ build ═══════════

  @override
  Widget build(BuildContext context) {
    final m = MetaStrings.of(context);
    final p = PlayerProfile.instance;

    return Scaffold(
      bottomNavigationBar: const BannerAdSlot(),
      appBar: AppBar(
        title: Text(m.profileTitle),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: const Color(0xFF3A7BD5),
          labelColor: const Color(0xFF3A7BD5),
          unselectedLabelColor: Colors.grey,
          tabs: [
            Tab(text: m.ja ? '🏆 戦績' : '🏆 Stats'),
            Tab(text: m.ja ? '🎨 カスタム' : '🎨 Custom'),
            Tab(text: m.ja ? '⚙️ 設定' : '⚙️ Settings'),
          ],
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: AnimatedBuilder(
              animation: p,
              builder: (context, _) => Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF3D6),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: const Color(0xFFE6B54A)),
                  ),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    const Text('🪙', style: TextStyle(fontSize: 16)),
                    const SizedBox(width: 4),
                    Text('${p.coins}', style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF8A6A1E))),
                  ]),
                ),
              ),
            ),
          ),
        ],
      ),
      body: AnimatedBuilder(
        animation: p,
        builder: (context, _) => switch (_tabIndex) {
          0 => _statsTab(m, p),
          1 => _customizeTab(m, p),
          _ => _settingsTab(m, p),
        },
      ),
    );
  }
}
