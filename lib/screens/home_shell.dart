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

/// アプリのルート: 下部タブでモードを切り替えるシェル。
/// 1. なまえコール（メイン） 2. ビジネス特訓 3. ショップ 4. よみもの 5. マイページ
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
    _maybeShowTutorial();
  }

  /// 初回起動の人にはあそびかたを見せる（スキップ可・一度きり）。
  ///
  /// 読むだけで終わらせず、**そのまま1回やってもらう**。
  /// 説明を読んだだけでは手が動かないまま閉じられるので、
  /// 名前をつける→呼ぶ→取れる→コインをもらう、までを一続きにする。
  Future<void> _maybeShowTutorial() async {
    if (await shouldShowTutorial()) {
      if (!mounted) return;
      await Navigator.of(context).push(MaterialPageRoute<void>(
          builder: (_) => const TutorialScreen()));
    }
    // 🎮 読み物のあと（または読み物をスキップした人にも）おためしを1回
    if (!await shouldPlayTutorial()) return;
    if (!mounted) return;
    await Navigator.of(context).push(MaterialPageRoute<void>(
        builder: (_) => const TutorialPlayScreen()));
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
          const TopScreen(), // なまえコール（メイン）
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
          AppAnalytics.featureOpen(const [
            'namecall', 'training', 'shop', 'read', 'story', 'profile'
          ][i]);
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
          // ⚠️ 並びは上の IndexedStack と1対1で対応させること。
          //    index 3 = よみもの（MemoryTips）／index 4 = ものがたり（NoahStory）。
          //    ここが入れ替わっていて「ものがたり」を押すと読み物が開いていた。
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
