import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart'; // Buy Me a Coffee のリンクを開くため
import 'package:untitled/l10n/app_localizations.dart';
import 'player_selection_screen.dart'; // オフラインモード
import 'online_game_lobby_screen.dart'; // オンラインモード
import 'profile_screen.dart'; // マイページ・戦績
import '../services/player_profile.dart';
import '../models/cosmetics.dart'; // 着せ替えテーマ・称号

// 多言語対応のために追加

class TopScreen extends StatefulWidget {
  const TopScreen({super.key});

  @override
  State<TopScreen> createState() => _TopScreenState();
}

class _TopScreenState extends State<TopScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

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
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
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
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            // アプリタイトル（ポップにバウンド登場・テーマ連動色）
            Padding(
              padding: const EdgeInsets.only(bottom: 32.0),
              child: Column(
                children: [
                  const Text('🎉', style: TextStyle(fontSize: 40)),
                  const SizedBox(height: 4),
                  Text(
                    localizations.appTitle,
                    style: TextStyle(
                      fontSize: 46,
                      fontWeight: FontWeight.w900,
                      color: homeTheme.titleColor,
                      letterSpacing: 2,
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
                  ),
                  const SizedBox(height: 10),
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
            // フェードインアニメーション付きのボタン
            FadeTransition(
              opacity: _animation,
              child: Column(
                children: [
                  ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const OnlineGameLobbyScreen(),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF4ECDC4), // ポップシアン
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 50,
                        vertical: 20,
                      ),
                      textStyle: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                        side: const BorderSide(color: Colors.white, width: 3),
                      ),
                      elevation: 8,
                      shadowColor: const Color(0xAA4ECDC4),
                    ),
                    child: Text('🌐 ${localizations.playOnline}'),
                  ),
                  const SizedBox(height: 30),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const PlayerSelectionScreen(),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFF9F45), // ポップオレンジ
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 50,
                        vertical: 20,
                      ),
                      textStyle: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                        side: const BorderSide(color: Colors.white, width: 3),
                      ),
                      elevation: 8,
                      shadowColor: const Color(0xAAFF9F45),
                    ),
                    child: Text('🎮 ${localizations.playOffline}'),
                  ),
                  const SizedBox(height: 40),
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
            ),
          ],
        ),
        ),
      ),
    );
  }
}
