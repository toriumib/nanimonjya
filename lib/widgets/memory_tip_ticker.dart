import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';

import '../l10n/memory_tips.dart';
import '../l10n/meta_strings.dart';
import '../screens/memory_tips_screen.dart';

/// 「名前おぼえのコツ」ワンポイント表示。
/// [rotate] がtrueなら8秒ごとに次のTipへフェード切替（待ち時間向け）。
/// タップで読み物全文（MemoryTipsScreen）を開く。
class MemoryTipTicker extends StatefulWidget {
  final bool rotate;
  const MemoryTipTicker({super.key, this.rotate = false});

  @override
  State<MemoryTipTicker> createState() => _MemoryTipTickerState();
}

class _MemoryTipTickerState extends State<MemoryTipTicker> {
  late int _index = Random().nextInt(kMemoryShortTips.length);
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    if (widget.rotate) {
      _timer = Timer.periodic(const Duration(seconds: 8), (_) {
        if (!mounted) return;
        setState(() => _index = (_index + 1) % kMemoryShortTips.length);
      });
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final m = MetaStrings.of(context);
    final tip = kMemoryShortTips[_index];
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const MemoryTipsScreen()),
        );
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFFFFF7E0),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFFFC93C), width: 1.5),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              m.memoryTipsHeader,
              style: const TextStyle(
                  fontSize: 12, fontWeight: FontWeight.w900,
                  color: Color(0xFF8A6A1E)),
            ),
            const SizedBox(height: 4),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 400),
              child: Text(
                tip.text(m.ja),
                key: ValueKey(_index),
                style: const TextStyle(fontSize: 13, height: 1.5),
              ),
            ),
            const SizedBox(height: 4),
            Align(
              alignment: Alignment.centerRight,
              child: Text(
                m.memoryTipsMore,
                style: const TextStyle(
                    fontSize: 11, color: Color(0xFF8A6A1E),
                    fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
