import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../l10n/meta_strings.dart';
import '../models/character_catalog.dart';
import '../services/player_profile.dart';
import '../services/sfx.dart';

/// 🎁 初回起動の最初の画面。読ませない。与える。
///
/// 全員がアンインストールしていた原因:
/// 「何をするアプリか」を説明してから遊ばせようとしていた。
/// でも、ユーザーは説明を読みに来たんじゃない。
/// ドーパミンをもらいに来たんだ。
///
/// だから最初の5秒で: コインをその場で与え、キャラを1体解放し、
/// 顔を見せて名前を覚えさせる。**何も読ませずに価値を届ける。**
class WelcomeGiftScreen extends StatefulWidget {
  const WelcomeGiftScreen({super.key});

  /// 🎁 画面を出さずに、コインとキャラ1体だけをその場で付与する。
  /// 初回離脱を防ぐため「さあ、はじめよう！」の導入画面はもう出さない。
  static Future<void> grantSilently() async {
    final profile = PlayerProfile.instance;
    await profile.grantBonusCoins(100);
    final pool = kExtraCharacters
        .where((c) => !profile.unlockedCharacters.contains(c.id))
        .toList();
    if (pool.isNotEmpty) {
      final id = pool[DateTime.now().millisecond % pool.length].id;
      await profile.unlockCharacter(id, 0);
    }
  }

  @override
  State<WelcomeGiftScreen> createState() => _WelcomeGiftScreenState();
}

class _WelcomeGiftScreenState extends State<WelcomeGiftScreen> {
  int _step = 0; // 0=welcome, 1=coins, 2=character, 3=done
  GameCharacter? _giftChar;

  @override
  void initState() {
    super.initState();
    _runSequence();
  }

  Future<void> _runSequence() async {
    final profile = PlayerProfile.instance;

    // Step 1: 即コイン付与
    await Future.delayed(const Duration(milliseconds: 600));
    if (!mounted) return;
    await profile.grantBonusCoins(100);
    Sfx.instance.coin();
    HapticFeedback.mediumImpact();
    if (mounted) setState(() => _step = 1);

    // Step 2: キャラ1体解放
    await Future.delayed(const Duration(milliseconds: 900));
    if (!mounted) return;
    final pool = kExtraCharacters
        .where((c) => !profile.unlockedCharacters.contains(c.id))
        .toList();
    if (pool.isNotEmpty) {
      _giftChar = pool[DateTime.now().millisecond % pool.length];
      await profile.unlockCharacter(_giftChar!.id, 0);
    }
    Sfx.instance.fanfare();
    HapticFeedback.heavyImpact();
    if (mounted) setState(() => _step = 2);

    // Step 3: 完了
    await Future.delayed(const Duration(milliseconds: 1200));
    if (mounted) setState(() => _step = 3);
  }

  @override
  Widget build(BuildContext context) {
    final m = MetaStrings.of(context);
    return Scaffold(
      backgroundColor: const Color(0xFF0D1117),
      body: SafeArea(
        child: Center(
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 500),
            child: _step == 0
                ? _welcome(m)
                : _step == 1
                    ? _coinsGift(m)
                    : _step == 2
                        ? _charGift(m)
                        : _ready(m),
          ),
        ),
      ),
    );
  }

  Widget _welcome(MetaStrings m) {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('🚀', style: TextStyle(fontSize: 72)),
          const SizedBox(height: 16),
          Text(
            m.ja ? 'ようこそ！' : 'Welcome!',
            style: const TextStyle(
                fontSize: 28, fontWeight: FontWeight.w900, color: Colors.white),
          ),
          const SizedBox(height: 8),
          Text(
            m.ja ? 'プレゼントを準備しています…' : 'Preparing your gift…',
            style: const TextStyle(fontSize: 15, color: Color(0xFF8899BB)),
          ),
          const SizedBox(height: 24),
          const LinearProgressIndicator(
            minHeight: 4,
            color: Color(0xFF5AD1FF),
          ),
        ],
      ),
    );
  }

  Widget _coinsGift(MetaStrings m) {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('🪙', style: TextStyle(fontSize: 72)),
          const SizedBox(height: 16),
          Text(
            m.ja ? '100コイン プレゼント！' : '100 Coins for you!',
            style: const TextStyle(
                fontSize: 26, fontWeight: FontWeight.w900, color: Color(0xFFFFC02E)),
          ),
          const SizedBox(height: 8),
          Text(
            m.ja ? 'これで好きなキャラを買えます' : 'Use these to unlock characters',
            style: const TextStyle(fontSize: 14, color: Color(0xFF8899BB)),
          ),
        ],
      ),
    );
  }

  Widget _charGift(MetaStrings m) {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (_giftChar != null) ...[
            ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: Image.asset(
                _giftChar!.asset,
                width: 140, height: 140, fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  width: 140, height: 140,
                  decoration: BoxDecoration(
                    color: const Color(0xFF1D2A4A),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Center(
                    child: Text(_giftChar!.emoji, style: const TextStyle(fontSize: 56)),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],
          if (_giftChar == null)
            const Text('🎁', style: TextStyle(fontSize: 72)),
          const SizedBox(height: 16),
          Text(
            _giftChar != null
                ? (m.ja ? '仲間が増えた！' : 'New ally joined!')
                : (m.ja ? '仲間が増えた！' : 'New ally joined!'),
            style: const TextStyle(
                fontSize: 24, fontWeight: FontWeight.w900, color: Color(0xFF7DFFB0)),
          ),
          if (_giftChar != null) ...[
            const SizedBox(height: 4),
            Text(
              _giftChar!.emoji,
              style: const TextStyle(fontSize: 14, color: Color(0xFF8899BB)),
            ),
          ],
        ],
      ),
    );
  }

  Widget _ready(MetaStrings m) {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('🎉', style: TextStyle(fontSize: 72)),
          const SizedBox(height: 16),
          Text(
            m.ja ? 'さあ、はじめよう！' : 'Let\'s get started!',
            style: const TextStyle(
                fontSize: 26, fontWeight: FontWeight.w900, color: Colors.white),
          ),
          const SizedBox(height: 12),
          Text(
            m.ja ? '顔と名前を覚えるゲームだよ\n1分であそべるよ'
                : 'A face & name memory game\nYou can play in just 1 minute',
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 14, height: 1.5, color: Color(0xFF8899BB)),
          ),
          const SizedBox(height: 28),
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF5AD1FF),
              foregroundColor: const Color(0xFF0D1117),
              minimumSize: const Size.fromHeight(52),
              padding: const EdgeInsets.symmetric(horizontal: 36),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
            ),
            child: Text(
              m.ja ? 'やってみる！' : 'Play now!',
              style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w900),
            ),
          ),
        ],
      ),
    );
  }
}
