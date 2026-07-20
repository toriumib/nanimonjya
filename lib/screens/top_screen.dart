import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart'; // ロゴ・演出アニメーション
import 'package:flutter_svg/flutter_svg.dart'; // マスコットイラスト
import 'package:google_fonts/google_fonts.dart'; // ロゴ専用フォント
import 'package:url_launcher/url_launcher.dart'; // Buy Me a Coffee のリンクを開くため
import 'package:nanimonjya/l10n/app_localizations.dart';
import 'name_call_screen.dart'; // メインモード「なまえコール」
import 'custom_roster_screen.dart'; // おぼえる（自分の写真）
import 'online_lobby_screen.dart'; // オンライン対戦の待合室
import 'profile_screen.dart'; // マイページ・戦績
import '../services/player_profile.dart';
import '../models/cosmetics.dart'; // 着せ替えテーマ・称号
import '../services/sfx.dart'; // タップ音
import '../services/reward_ad_helper.dart'; // 無料コインチェストの広告
import '../l10n/meta_strings.dart'; // マイページ導線の文言
import 'tutorial_screen.dart'; // あそびかたチュートリアル
import 'memory_tips_screen.dart'; // 名前の覚え方（記憶術の読み物）

// 多言語対応のために追加

class TopScreen extends StatefulWidget {
  const TopScreen({super.key});

  @override
  State<TopScreen> createState() => _TopScreenState();
}

class _TopScreenState extends State<TopScreen>
    with TickerProviderStateMixin {
  bool _doubleCard = false; // なまえコールの「2枚同時」オプション
  int _peopleCount = 9; // なまえコールの登場人数（6/9/12）

  /// みんなで対戦（なまえコール）の人数を選んでスタート
  void _pickLocalPlayers(BuildContext context) {
    Sfx.instance.pop();
    showModalBottomSheet<void>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              for (final n in [2, 3, 4]) ...[
                if (n > 2) const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(sheetContext);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => NameCallScreen(
                            humanPlayers: n,
                            doubleCard: _doubleCard,
                            peopleCount: _peopleCount,
                          ),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFE8663C),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: Text('$n人'),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  late AnimationController _controller;
  late Animation<double> _animation;
  late AnimationController _bounceController; // マスコットのぴょこぴょこ
  final RewardAdHelper _giftAd = RewardAdHelper(); // 無料コインチェスト用
  final Random _random = Random();
  Timer? _giftTicker; // 🎁残り時間表示の更新用

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800), // アニメーションの時間
    );
    _animation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeOut, // アニメーションのカーブ
      ),
    );
    _controller.forward(); // アニメーションを開始
    _bounceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
    _giftAd.load();
    // 🎁の残り時間表示を1分ごとに更新（止まったままにならないように）
    _giftTicker = Timer.periodic(const Duration(seconds: 60), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _bounceController.dispose();
    _giftAd.dispose();
    _giftTicker?.cancel();
    super.dispose();
  }

  // 🎁 無料コインチェスト: 動画を見てランダムなコイン(50〜200)をゲット
  Future<void> _claimGift() async {
    final m = MetaStrings.of(context);
    final profile = PlayerProfile.instance;
    if (!profile.canClaimGift) {
      final mins = profile.giftCooldownRemaining.inMinutes + 1;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(m.giftWaitMin(mins))));
      return;
    }
    // 50〜200コインのランダム報酬（10刻みでワクワク感）
    final amount = 50 + _random.nextInt(16) * 10;
    final played = await _giftAd.showOrQueue(onReward: () async {
      await profile.claimGift(amount);
      Sfx.instance.fanfare();
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(m.giftGot(amount))));
      }
    });
    if (!mounted) return;
    if (!played) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(m.adQueued)));
    }
  }

  // Buy Me a Coffee のページを外部ブラウザで開く
  Future<void> _launchBuyMeACoffee() async {
    final localizations = AppLocalizations.of(context)!;
    final uri = Uri.parse('https://buymeacoffee.com/toriumi');
    final launched = await launchUrl(
      uri,
      mode: LaunchMode.externalApplication,
    );
    if (!launched && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(localizations.couldNotOpenLink)),
      );
    }
  }

  void _openProfile() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const ProfileScreen()),
    ).then((_) {
      if (mounted) setState(() {}); // 戻ってきたらコイン表示を更新
    });
  }

  // 右上のコイン残高＋マイページボタン（デイリーボーナス可なら赤バッジ）
  Widget _topBar() {
    final profile = PlayerProfile.instance;
    return AnimatedBuilder(
      animation: profile,
      builder: (context, _) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
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
                  Text('${profile.coins}',
                      style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF8A6A1E))),
                ],
              ),
            ),
            const SizedBox(width: 4),
            Stack(
              clipBehavior: Clip.none,
              children: [
                IconButton(
                  icon: const Icon(Icons.emoji_events_outlined),
                  tooltip: 'マイページ',
                  onPressed: _openProfile,
                ),
                if (profile.canClaimDaily)
                  Positioned(
                    right: 6,
                    top: 6,
                    child: Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                    ),
                  ),
              ],
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    // 多言語対応の文字列にアクセスするためのインスタンス
    final localizations = AppLocalizations.of(context)!; // ★追加★

    // 選択中の着せ替えテーマ（コインでアンロック可能）
    final homeTheme = homeThemeById(PlayerProfile.instance.selectedTheme);

    return Scaffold(
      body: Container(
        // ★選択中テーマのグラデーション背景★
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: homeTheme.gradient,
          ),
        ),
        child: SafeArea(
        child: Stack(
          children: [
            Positioned(top: 8, right: 8, child: _topBar()),
            Center(
        child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(vertical: 24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            // ★ブランドの顔：2人のチアガールが出迎えるヒーロー（ふわり浮遊）★
            AnimatedBuilder(
              animation: _bounceController,
              builder: (context, _) {
                final t = _bounceController.value;
                final wave = t < 0.5 ? t * 2 : (1 - t) * 2; // 0→1→0
                final dyL = -9.0 * wave;
                final dyR = -9.0 * (1 - wave);
                return Stack(
                  alignment: Alignment.center,
                  clipBehavior: Clip.none,
                  children: [
                    // やわらかな後光
                    Container(
                      width: 230,
                      height: 130,
                      decoration: BoxDecoration(
                        gradient: RadialGradient(
                          colors: [
                            Colors.white.withOpacity(0.7),
                            Colors.white.withOpacity(0.0),
                          ],
                        ),
                      ),
                    ),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Transform.translate(
                          offset: Offset(0, dyL),
                          child: SvgPicture.asset(
                            'assets/images/supporters/cheer_girl2.svg',
                            width: 92,
                            height: 92,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Transform.translate(
                          offset: Offset(0, dyR),
                          child: SvgPicture.asset(
                            'assets/images/supporters/cheer_girl.svg',
                            width: 92,
                            height: 92,
                          ),
                        ),
                      ],
                    ),
                    const Positioned(
                        top: -8,
                        child: Text('✨', style: TextStyle(fontSize: 26))),
                    const Positioned(
                        top: 6, left: 30,
                        child: Text('⭐', style: TextStyle(fontSize: 18))),
                    const Positioned(
                        top: 6, right: 30,
                        child: Text('💖', style: TextStyle(fontSize: 18))),
                  ],
                );
              },
            ),
            const SizedBox(height: 6),
            // アプリタイトル（テーマ連動色・立体ロゴ風）＋キャッチコピー
            Padding(
              padding: const EdgeInsets.only(bottom: 26.0),
              child: Column(
                children: [
                  // 長いタイトルでも1行に収まるよう横幅に合わせて自動縮小
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      localizations.appTitle,
                      style: GoogleFonts.mochiyPopOne(
                        fontSize: 44,
                        color: homeTheme.titleColor,
                        letterSpacing: 1,
                        shadows: [
                          Shadow(
                            offset: const Offset(3.0, 3.0),
                            blurRadius: 0,
                            color: homeTheme.titleShadow, // ズレ影でポップに
                          ),
                          const Shadow(
                            offset: Offset(5.0, 5.0),
                            blurRadius: 8,
                            color: Color(0x33000000),
                          ),
                        ],
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 1,
                    ),
                  )
                      .animate()
                      .fadeIn(duration: 500.ms, curve: Curves.easeOut)
                      .scale(
                        begin: const Offset(0.7, 0.7),
                        end: const Offset(1.0, 1.0),
                        duration: 500.ms,
                        curve: Curves.elasticOut,
                      ),
                  const SizedBox(height: 6),
                  // キャッチコピー（何のゲームか一目でわかる＝売れる）
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 5),
                    decoration: BoxDecoration(
                      color: homeTheme.darkBackground
                          ? Colors.white.withOpacity(0.9)
                          : homeTheme.titleColor,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      MetaStrings.of(context).tagline,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w900,
                        color: homeTheme.darkBackground
                            ? const Color(0xFF2B2D64)
                            : Colors.white,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  // 現在の称号バッジ（累計コインでランクアップ）
                  AnimatedBuilder(
                    animation: PlayerProfile.instance,
                    builder: (context, _) {
                      final title = currentTitle(
                        PlayerProfile.instance.lifetimeCoins,
                      );
                      final ja = Localizations.localeOf(context)
                              .languageCode ==
                          'ja';
                      return Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.85),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: homeTheme.titleColor,
                            width: 2,
                          ),
                        ),
                        child: Text(
                          '${title.emoji} ${ja ? title.nameJa : title.nameEn}',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: homeTheme.darkBackground
                                ? const Color(0xFF2B2D64)
                                : homeTheme.titleColor,
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
            // 🎁 無料コインチェスト（動画）— 揺れて目立つ・広告視聴を促す
            if (RewardAdHelper.available)
              AnimatedBuilder(
                animation: PlayerProfile.instance,
                builder: (context, _) {
                  final ready = PlayerProfile.instance.canClaimGift;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 18),
                    child: AnimatedBuilder(
                      animation: _bounceController,
                      builder: (context, child) {
                        final wobble = ready
                            ? (_bounceController.value - 0.5) * 0.08
                            : 0.0;
                        return Transform.rotate(angle: wobble, child: child);
                      },
                      child: ElevatedButton.icon(
                        onPressed: _claimGift,
                        icon: const Text('🎁', style: TextStyle(fontSize: 22)),
                        label: Text(
                          ready
                              ? MetaStrings.of(context).freeGift
                              : MetaStrings.of(context).giftWaitMin(
                                  PlayerProfile.instance
                                          .giftCooldownRemaining.inMinutes +
                                      1),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: ready
                              ? const Color(0xFFFFC93C)
                              : Colors.grey.shade400,
                          foregroundColor: const Color(0xFF5A3E00),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 30, vertical: 14),
                          textStyle: const TextStyle(
                              fontSize: 17, fontWeight: FontWeight.w900),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(26),
                            side: const BorderSide(
                                color: Colors.white, width: 3),
                          ),
                          elevation: 8,
                          shadowColor: const Color(0xAAFFC93C),
                        ),
                      ),
                    ),
                  );
                },
              ),
            // フェードインアニメーション付きのボタン
            FadeTransition(
              opacity: _animation,
              child: Column(
                children: [
                  // ★メインモード「なまえコール」カード★
                  Builder(builder: (context) {
                    final m = MetaStrings.of(context);
                    return Container(
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.92),
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(
                            color: const Color(0xFF4ECDC4), width: 3),
                        boxShadow: const [
                          BoxShadow(
                            color: Color(0x334ECDC4),
                            blurRadius: 12,
                            offset: Offset(0, 5),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          Text(
                            m.nameCallTitle,
                            style: const TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.w900,
                                color: Color(0xFF1E8A82)),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            m.nameCallCatch,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                                fontSize: 12.5,
                                height: 1.5,
                                color: Colors.black54),
                          ),
                          const SizedBox(height: 8),
                          // 登場人数（カード枚数）の選択
                          Row(
                            children: [
                              const Text('👥', style: TextStyle(fontSize: 16)),
                              const SizedBox(width: 6),
                              for (final n in const [6, 9, 12]) ...[
                                if (n > 6) const SizedBox(width: 6),
                                Expanded(
                                  child: GestureDetector(
                                    onTap: () =>
                                        setState(() => _peopleCount = n),
                                    child: AnimatedContainer(
                                      duration:
                                          const Duration(milliseconds: 160),
                                      padding: const EdgeInsets.symmetric(
                                          vertical: 8),
                                      decoration: BoxDecoration(
                                        color: _peopleCount == n
                                            ? const Color(0xFF4ECDC4)
                                            : Colors.white,
                                        borderRadius:
                                            BorderRadius.circular(12),
                                        border: Border.all(
                                            color: const Color(0xFF4ECDC4),
                                            width: 2),
                                      ),
                                      child: Text(
                                        m.peopleCountLabel(n),
                                        textAlign: TextAlign.center,
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w900,
                                          color: _peopleCount == n
                                              ? Colors.white
                                              : const Color(0xFF1E8A82),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                          const SizedBox(height: 8),
                          // 2枚同時（りょうどり）オプション
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFFF7E0),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              children: [
                                const Text('🎴', style: TextStyle(fontSize: 16)),
                                const SizedBox(width: 4),
                                Expanded(
                                  child: Text(m.doubleCardLabel,
                                      style: const TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w900)),
                                ),
                                Switch(
                                  value: _doubleCard,
                                  onChanged: (v) =>
                                      setState(() => _doubleCard = v),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 8),
                          ElevatedButton(
                            onPressed: () {
                              Sfx.instance.fanfare();
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (_) => NameCallScreen(
                                        doubleCard: _doubleCard,
                                        peopleCount: _peopleCount)),
                              );
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF4ECDC4),
                              minimumSize: const Size.fromHeight(48),
                              textStyle: const TextStyle(
                                  fontSize: 17, fontWeight: FontWeight.w900),
                            ),
                            child: Text(m.nameCallSoloButton),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Expanded(
                                child: ElevatedButton(
                                  onPressed: () =>
                                      _pickLocalPlayers(context),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor:
                                        const Color(0xFFE8663C),
                                    minimumSize: const Size.fromHeight(44),
                                  ),
                                  child: Text(m.nameCallLocalButton,
                                      style:
                                          const TextStyle(fontSize: 13.5)),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: ElevatedButton(
                                  onPressed: () {
                                    Sfx.instance.fanfare();
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) =>
                                            const OnlineLobbyScreen(
                                                game: 'namecall'),
                                      ),
                                    );
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor:
                                        const Color(0xFFFF9F45),
                                    minimumSize: const Size.fromHeight(44),
                                  ),
                                  child: Text(m.nameCallOnlineButton,
                                      style:
                                          const TextStyle(fontSize: 13.5)),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          // 📸 自分の写真で覚える・対戦
                          OutlinedButton.icon(
                            onPressed: () {
                              Sfx.instance.pop();
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (_) => const CustomRosterScreen()),
                              );
                            },
                            icon: const Text('📸',
                                style: TextStyle(fontSize: 16)),
                            label: Text(m.customTitle),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: const Color(0xFF1E8A82),
                              side: const BorderSide(
                                  color: Color(0xFF4ECDC4), width: 2),
                              minimumSize: const Size.fromHeight(44),
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
                  const SizedBox(height: 24),
                  // ★マイページ・戦績（トロフィー）への大きな導線★
                  AnimatedBuilder(
                    animation: PlayerProfile.instance,
                    builder: (context, _) {
                      final canClaim =
                          PlayerProfile.instance.canClaimDaily;
                      return OutlinedButton.icon(
                        onPressed: () {
                          Sfx.instance.pop();
                          _openProfile();
                        },
                        icon: const Icon(Icons.emoji_events, size: 22),
                        label: Text(
                          canClaim
                              ? MetaStrings.of(context).dailyBonus
                              : MetaStrings.of(context).profileTitle,
                        ),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFFB8860B),
                          backgroundColor: Colors.white.withOpacity(0.8),
                          side: const BorderSide(
                            color: Color(0xFFFFB300),
                            width: 2.5,
                          ),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 32,
                            vertical: 14,
                          ),
                          textStyle: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w900,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(24),
                          ),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 12),
                  // ※ランキング導線は旧オンラインレーティング前提のためv2.0.0で撤去
                  //   （新ルールのランキングを実装したら復活させる）
                  // 📚 名前の覚え方（記憶術の読み物）
                  TextButton.icon(
                    onPressed: () {
                      Sfx.instance.pop();
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const MemoryTipsScreen(),
                        ),
                      );
                    },
                    icon: const Text('📚', style: TextStyle(fontSize: 18)),
                    label: Text(MetaStrings.of(context).memoryTipsTitle),
                    style: TextButton.styleFrom(
                      foregroundColor: const Color(0xFFB4326E),
                      textStyle: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  // あそびかた（チュートリアル）ボタン
                  TextButton.icon(
                    onPressed: () {
                      Sfx.instance.pop();
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const TutorialScreen(),
                        ),
                      );
                    },
                    icon: const Text('👧👦', style: TextStyle(fontSize: 18)),
                    label: Text(MetaStrings.of(context).howToPlay),
                    style: TextButton.styleFrom(
                      foregroundColor: const Color(0xFF1E7BA6),
                      textStyle: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  // Buy Me a Coffee ボタン
                  TextButton.icon(
                    onPressed: _launchBuyMeACoffee,
                    icon: const Text('☕', style: TextStyle(fontSize: 20)),
                    label: Text(localizations.buyMeACoffee),
                    style: TextButton.styleFrom(
                      foregroundColor: const Color(0xFFBB6B2A),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                      textStyle: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        ), // SingleChildScrollView を閉じる
            ),
          ],
        ),
        ),
      ),
    );
  }
}
