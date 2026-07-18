import 'package:flutter/material.dart';

import '../l10n/meta_strings.dart';
import '../services/sfx.dart';
import 'player_selection_screen.dart';
import 'profile_screen.dart';
import 'top_screen.dart';
import 'training_hub_screen.dart';

/// アプリのルート: 下部タブでモードを切り替えるシェル。
/// 1. なまえコール（メイン） 2. ペアさがし（神経衰弱） 3. とっくん 4. マイページ
class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    final m = MetaStrings.of(context);
    return Scaffold(
      body: IndexedStack(
        index: _index,
        children: const [
          TopScreen(), // なまえコール（メイン）
          PlayerSelectionScreen(), // ペアさがし（神経衰弱）
          TrainingHubScreen(), // とっくん
          ProfileScreen(), // マイページ
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) {
          Sfx.instance.pop();
          setState(() => _index = i);
        },
        destinations: [
          NavigationDestination(
            icon: const Text('📣', style: TextStyle(fontSize: 22)),
            label: m.tabNameCall,
          ),
          NavigationDestination(
            icon: const Text('🃏', style: TextStyle(fontSize: 22)),
            label: m.tabPairs,
          ),
          NavigationDestination(
            icon: const Text('🏋️', style: TextStyle(fontSize: 22)),
            label: m.tabTraining,
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
