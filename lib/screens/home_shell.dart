import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';

import '../l10n/meta_strings.dart';
import '../services/app_analytics.dart';
import '../services/bgm.dart';
import '../services/sfx.dart';
import 'character_shop_screen.dart';
import 'custom_roster_screen.dart';
import 'memory_tips_screen.dart';
import 'profile_screen.dart';
import 'top_screen.dart';
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

  /// 初回起動の人に、まずウェルカムギフトを渡してから
  /// 「チュートリアルを見る？」を聞く。見るなら なまえがお を
  /// ゲーム形式で1回だけ体験してもらう。
  ///
  /// ⚠️ 「あそびかた」（読み物）は自動で開かない。ホームの
  ///    「あそびかた」ボタンを押したときだけ開く（押しつけは離脱の原因）。
  Future<void> _maybeShowTutorial() async {
    if (!await shouldPlayTutorial()) return;
    if (!mounted) return;

    // 🎁 まずウェルカムギフト（コイン＋キャラ即付与）。読ませない。与える。
    await Navigator.of(context).push(MaterialPageRoute<void>(
        builder: (_) => const WelcomeGiftScreen()));
    if (!mounted) return;

    // チュートリアルを「見る／見ない」で選ばせる。
    final m = MetaStrings.of(context);
    final watch = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(m.ja ? 'チュートリアル' : 'Tutorial'),
        content: Text(m.ja
            ? 'なまえがお の遊びかたを、実際に遊びながら覚えられます。'
            : 'Learn Name Call by actually playing it.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(m.ja ? '見ない' : 'Skip'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(m.ja ? '見る' : 'Watch'),
          ),
        ],
      ),
    );
    if (watch == true && mounted) {
      await Navigator.of(context).push(MaterialPageRoute<void>(
          builder: (_) => const TutorialPlayScreen()));
    }
    // 見る／見ない どちらでも「初回チュートリアルは済ませた」扱い。
    await markTutorialPlayed();
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
          const CharacterShopScreen(embedded: true), // ショップ
          const MemoryTipsScreen(embedded: true), // よみもの（記憶術・研究の読み物）
          const CustomRosterScreen(), // 🧑🎨 顔メモ
          const ProfileScreen(), // マイページ
        ],
      ),
      // 🖤 タブは線画アイコン＋小さな文字。選択中だけゴールドで示す。
      //    絵文字は端末ごとに絵柄が変わるうえ、色数が増えて散らかる。
      bottomNavigationBar: NavigationBarTheme(
        data: NavigationBarThemeData(
          backgroundColor: const Color(0xFF141A26),
          indicatorColor: const Color(0x33E9C87A),
          surfaceTintColor: Colors.transparent,
          elevation: 0,
          height: 66,
          labelTextStyle: WidgetStateProperty.resolveWith(
            (states) => TextStyle(
              fontSize: 10.5,
              letterSpacing: 0.2,
              fontWeight: states.contains(WidgetState.selected)
                  ? FontWeight.w700
                  : FontWeight.w500,
              color: states.contains(WidgetState.selected)
                  ? const Color(0xFFE9C87A)
                  : const Color(0x99FFFFFF),
            ),
          ),
          iconTheme: WidgetStateProperty.resolveWith(
            (states) => IconThemeData(
              size: 22,
              color: states.contains(WidgetState.selected)
                  ? const Color(0xFFE9C87A)
                  : const Color(0x99FFFFFF),
            ),
          ),
        ),
        child: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) {
          Sfx.instance.pop();
          // マイページで曲を試聴したあとタブを移ると、その曲が鳴り続けてしまう。
          // タブはどれも「ホーム」なので、切り替えたらホームBGMに戻す。
          // （すでにホームBGMが鳴っていれば何もしない）
          // 📊 どのタブが使われているかを記録（IDのみ・個人情報は送らない）
          AppAnalytics.featureOpen(
            const ['namecall', 'shop', 'read', 'face_memo', 'profile'][i],
            from: 'tab',
          );
          Bgm.instance.playHome();
          setState(() => _index = i);
        },
        destinations: [
          NavigationDestination(
            icon: const Icon(Icons.campaign_outlined),
            selectedIcon: const Icon(Icons.campaign),
            label: m.tabNameCall,
          ),
          NavigationDestination(
            icon: const Icon(Icons.shopping_bag_outlined),
            selectedIcon: const Icon(Icons.shopping_bag),
            label: m.tabShop,
          ),
          // ⚠️ ここは children の並び（index 3 = よみもの、4 = ものがたり）と
          //    そろえること。以前ラベルだけ逆になっていて、
          //    「ものがたり」を押すと読み物が開く状態になっていた。
          NavigationDestination(
            icon: const Icon(Icons.menu_book_outlined),
            selectedIcon: const Icon(Icons.menu_book),
            label: m.tabRead,
          ),
          NavigationDestination(
            icon: const Icon(Icons.face_outlined),
            selectedIcon: const Icon(Icons.face),
            label: m.tabFaceMemo,
          ),
          NavigationDestination(
            icon: const Icon(Icons.person_outline),
            selectedIcon: const Icon(Icons.person),
            label: m.tabMyPage,
          ),
        ],
      ),
      ),
    );
  }
}
