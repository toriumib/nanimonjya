/// SPEC 3.6 — タイトル。はじめから／つづきから／コンフィグ。
library;

import 'package:flutter/material.dart';

import '../engine/save_manager.dart';
import '../models/save_data.dart';
import 'adv_screen.dart';
import 'encyclopedia_screen.dart';
import 'settings_screen.dart';

class TitleScreen extends StatefulWidget {
  const TitleScreen({super.key});

  @override
  State<TitleScreen> createState() => _TitleScreenState();
}

class _TitleScreenState extends State<TitleScreen> {
  SaveData? _auto;
  SystemData _system = const SystemData();
  bool _ready = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final auto = await SaveManager.instance.read(SaveManager.autoSlot);
    final sys = await SaveManager.instance.readSystem();
    if (!mounted) return;
    setState(() {
      _auto = auto;
      _system = sys;
      _ready = true;
    });
  }

  Future<void> _play({SaveData? resume}) async {
    await Navigator.of(context).push(MaterialPageRoute<void>(
        builder: (_) => AdvScreen(resume: resume)));
    // 遊んで戻ってきたら、つづきの有無が変わっているかもしれない
    if (mounted) _load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF05080F),
      body: Container(
        decoration: const BoxDecoration(
          gradient: RadialGradient(
            center: Alignment(0, 1.2),
            radius: 1.2,
            colors: [Color(0xFF2A0D0D), Color(0xFF05070F)],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(28),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('PROJECT NOA',
                      style: TextStyle(
                          fontSize: 34,
                          letterSpacing: 6,
                          fontWeight: FontWeight.w300,
                          color: Color(0xFFD4A24C))),
                  const SizedBox(height: 8),
                  const Text('東戸塚 ・ 四十九光年 の 約束',
                      style: TextStyle(
                          fontSize: 12.5,
                          letterSpacing: 2,
                          color: Color(0xFF6A7280))),
                  const SizedBox(height: 6),
                  const Text('覚えているから、会える。',
                      style: TextStyle(
                          fontSize: 13,
                          color: Color(0xFF9FB4D8),
                          fontWeight: FontWeight.w700)),
                  const SizedBox(height: 40),

                  if (!_ready)
                    const CircularProgressIndicator()
                  else ...[
                    _button('はじめから', () => _play()),
                    const SizedBox(height: 12),
                    _button(
                      'つづきから',
                      _auto == null ? null : () => _play(resume: _auto),
                      hint: _auto == null ? 'まだ記録がありません' : _auto!.sceneId,
                    ),
                    const SizedBox(height: 12),
                    _button(
                      '船内百科',
                      () => Navigator.of(context).push(MaterialPageRoute<void>(
                          builder: (_) =>
                              EncyclopediaScreen(system: _system))),
                      hint: _system.unlocks.mysteries
                          ? '謎、全解禁'
                          : '用語と、まだ解けていない謎',
                    ),
                    const SizedBox(height: 12),
                    _button(
                      'コンフィグ',
                      () => Navigator.of(context).push(MaterialPageRoute<void>(
                          builder: (_) => const SettingsScreen())),
                    ),
                    const SizedBox(height: 28),
                    // 周回でどこまで開いたか。何も無いうちは出さない。
                    if (_system.cleared > 0 || _system.maxMemoryRate > 0)
                      Text(
                        'クリア ${_system.cleared} 周　'
                        '最高記憶率 ${memoryRateLabel(_system.maxMemoryRate)}',
                        style: const TextStyle(
                            fontSize: 11.5, color: Color(0xFF6A7280)),
                      ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _button(String label, VoidCallback? onTap, {String? hint}) {
    return SizedBox(
      width: 260,
      child: Column(
        children: [
          OutlinedButton(
            onPressed: onTap,
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFFE8ECF1),
              disabledForegroundColor: const Color(0xFF3A4453),
              side: BorderSide(
                  color: onTap == null
                      ? const Color(0xFF1D2A4A)
                      : const Color(0xFFD4A24C),
                  width: 1.4),
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: const StadiumBorder(),
            ),
            child: Text(label,
                style: const TextStyle(
                    fontSize: 15, fontWeight: FontWeight.w900, letterSpacing: 2)),
          ),
          if (hint != null)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(hint,
                  style: const TextStyle(
                      fontSize: 10.5, color: Color(0xFF6A7280))),
            ),
        ],
      ),
    );
  }
}
