import 'package:flutter/material.dart';

import '../l10n/meta_strings.dart';
import '../services/app_analytics.dart';
import '../services/bgm.dart';
import '../services/sfx.dart';
import 'character_shop_screen.dart';
import 'memory_tips_screen.dart';
import 'profile_screen.dart';
import 'top_screen.dart';
import 'training_hub_screen.dart';
import 'tutorial_screen.dart';

/// アプリのルート: 下部タブでモードを切り替えるシェル。
/// 1. なまえコール（メイン） 2. ショップ 3. ビジネス特訓 4. よみもの 5. マイページ
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

  /// 初回起動の人にはあそびかたを自動で見せる（スキップ可・一度きり）。
  Future<void> _maybeShowTutorial() async {
    if (!await shouldShowTutorial()) return;
    if (!mounted) return;
    await Navigator.of(context).push(MaterialPageRoute<void>(
        builder: (_) => const TutorialScreen()));
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
    return Scaffold(
      body: IndexedStack(
        index: _index,
        children: const [
          TopScreen(), // なまえコール（メイン）
          CharacterShopScreen(embedded: true), // ショップ
          TrainingHubScreen(), // ビジネス特訓
          MemoryTipsScreen(embedded: true), // よみもの（記憶術・研究の読み物）
          ProfileScreen(), // マイページ
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
            'namecall', 'shop', 'training', 'read', 'profile'
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
            icon: const Text('🛍', style: TextStyle(fontSize: 22)),
            label: m.tabShop,
          ),
          NavigationDestination(
            icon: const Text('🏋️', style: TextStyle(fontSize: 22)),
            label: m.tabTraining,
          ),
          NavigationDestination(
            icon: const Text('📚', style: TextStyle(fontSize: 22)),
            label: m.tabRead,
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
