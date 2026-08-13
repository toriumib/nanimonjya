import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';

import '../l10n/meta_strings.dart';
import '../services/app_analytics.dart';
import '../services/bgm.dart';
import '../services/sfx.dart';
import 'character_shop_screen.dart';
import 'memory_tips_screen.dart';
import 'noah_story_screen.dart';
import 'profile_screen.dart';
import 'top_screen.dart';
import 'training_hub_screen.dart';
import 'tutorial_screen.dart';
import 'tutorial_play_screen.dart';
import 'welcome_gift_screen.dart';

/// アプリのルート: 下部タブでモードを切り替えるシェル。
/// 1. なまえがお（メイン） 2. ビジネス特訓 3. ショップ 4. よみもの 5. マイページ
/// ※ ペアさがしはタブから外したが、一人特訓の土台として画面は生きている。
///   マイページから引き続き遊べる。
class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> with RouteAware {
  int _index = 0;

  @override
  void initState() {
    super.initState();
    // 🎵 ホームのBGM（魔王魂「ハルジオン」）。
    // ブラウザは操作前の自動再生を止めるので、Webでは最初のタップ以降に鳴る。
    Bgm.instance.playHome();
    if (kIsWeb) {
      // Webはランディングから即ホーム。チュートリアルはスキップ。
      markTutorialPlayed();
      markTutorialDone();
    }
    _maybeShowTutorial();
  }

  /// 初回起動の人を、**まず1ゲームに入れる**。
  ///
  /// ⚠️ 以前は「あそびかた（全11ページ）を読ませてから、おためし」の順だった。
  ///    2026-08 の計測で、**起動した162人のうちゲームを始めたのは75人**。
  ///    半分が、遊ぶ前に消えていた。
  ///    説明を先に置くと、読み終わる前に閉じられて、ゲームに辿りつかない。
  ///
  /// なので順番を逆にした。**遊ぶ → 面白かった人だけが読む。**
  /// 説明は押しつけず、遊び終わったあとに一度だけ声をかける。
  /// 断られたらそれ以上は勧めない（`markTutorialSkipped` が2回で諦める）。
  Future<void> _maybeShowTutorial() async {
    final needPlay = await shouldPlayTutorial();
    final needRead = await shouldShowTutorial();

    // 🎁 まずウェルカムギフト（コイン＋キャラ即付与）。読ませない。与える。
    if (needPlay) {
      if (!mounted) return;
      await Navigator.of(context).push(MaterialPageRoute<void>(
          builder: (_) => const WelcomeGiftScreen()));
      if (!mounted) return;
      // チュートリアルゲーム（1分で終わる簡易版）
      await Navigator.of(context).push(MaterialPageRoute<void>(
          builder: (_) => const TutorialPlayScreen()));
      if (!mounted) return;
      if (needRead) await _offerGuide();
      return;
    }

    if (needRead) {
      if (!mounted) return;
      await Navigator.of(context).push(MaterialPageRoute<void>(
          builder: (_) => const TutorialScreen()));
    }
  }

  /// 遊んだあとに「あそびかたを読む？」と一度だけ聞く。
  Future<void> _offerGuide() async {
    final m = MetaStrings.of(context);
    final read = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFFFFF8E6),
        title: Text(m.offerGuideTitle),
        content: Text(
          m.offerGuideBody,
          style: const TextStyle(height: 1.6),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(m.offerGuideLater),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(m.offerGuideRead),
          ),
        ],
      ),
    );
    if (read == true) {
      if (!mounted) return;
      await Navigator.of(context).push(MaterialPageRoute<void>(
          builder: (_) => const TutorialScreen()));
    } else {
      // 断られた。しつこく出さない。
      await markTutorialSkipped();
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final route = ModalRoute.of(context);
    if (route is ModalRoute<void>) {
      Bgm.routeObserver.subscribe(this, route);
    }
  }

  // ゲーム画面などが上に乗ったら、ホームBGMを止めて場所を譲る。
  // （ゲーム側が先に自分の曲を鳴らしていれば stopHome は何もしない）
  @override
  void didPushNext() => Bgm.instance.stopHome();

  // 上の画面から戻ってきたらホームBGMを再開する。
  // ホームはタブなので initState は再実行されず、ここで拾うしかない。
  @override
  void didPopNext() => Bgm.instance.playHome();

  @override
  void dispose() {
    Bgm.routeObserver.unsubscribe(this);
    Bgm.instance.stopHome();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final m = MetaStrings.of(context);
    // 🔊 Webは最初のユーザー操作より前の再生を拒否する。
    //    どこかを触った時点で鳴らし直す（Androidでは何も起きない）。
    return Listener(
      onPointerDown: (_) => Bgm.instance.retryIfBlocked(),
      child: _buildShell(m),
    );
  }

  Widget _buildShell(MetaStrings m) {
    return Scaffold(
      body: IndexedStack(
        index: _index,
        children: [
          const TopScreen(), // なまえがお（メイン）
          // active を渡す: IndexedStack は全タブを最初に組み立てるので、
          // 「開かれたかどうか」を渡さないと初回説明が起動時に出てしまう
          TrainingHubScreen(active: _index == 1), // ビジネス特訓
          const CharacterShopScreen(embedded: true), // ショップ
          const MemoryTipsScreen(embedded: true), // よみもの（記憶術・研究の読み物）
          const NoahStoryScreen(embedded: true), // 📖 ものがたり
          const ProfileScreen(), // マイページ
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) {
          Sfx.instance.pop();
          // マイページで曲を試聴したあとタブを移ると、その曲が鳴り続けてしまう。
          // タブはどれも「ホーム」なので、切り替えたらホームBGMに戻す。
          // （すでにホームBGMが鳴っていれば何もしない）
          // 📊 どのタブが使われているかを記録（IDのみ・個人情報は送らない）
          AppAnalytics.featureOpen(
            const ['namecall', 'training', 'shop', 'read', 'story', 'profile']
                [i],
            from: 'tab',
          );
          Bgm.instance.playHome();
          setState(() => _index = i);
        },
        destinations: [
          NavigationDestination(
            icon: const Text('📣', style: TextStyle(fontSize: 22)),
            label: m.tabNameCall,
          ),
          NavigationDestination(
            icon: const Text('🏋️', style: TextStyle(fontSize: 22)),
            label: m.tabTraining,
          ),
          NavigationDestination(
            icon: const Text('🛍', style: TextStyle(fontSize: 22)),
            label: m.tabShop,
          ),
          // ⚠️ ここは children の並び（index 3 = よみもの、4 = ものがたり）と
          //    そろえること。以前ラベルだけ逆になっていて、
          //    「ものがたり」を押すと読み物が開く状態になっていた。
          NavigationDestination(
            icon: const Text('📚', style: TextStyle(fontSize: 22)),
            label: m.tabRead,
          ),
          NavigationDestination(
            icon: const Text('🚀', style: TextStyle(fontSize: 22)),
            label: m.tabStory,
          ),
          NavigationDestination(
            icon: const Text('🏆', style: TextStyle(fontSize: 22)),
            label: m.tabMyPage,
          ),
        ],
      ),
    );
  }
}
