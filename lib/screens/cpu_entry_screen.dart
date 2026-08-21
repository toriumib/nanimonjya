import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../l10n/meta_strings.dart';
import '../models/character_catalog.dart';
import '../models/person.dart';
import '../services/player_profile.dart';
import '../services/sfx.dart';
import '../widgets/face_view.dart';
import 'match_game_screen.dart';
import 'name_call_screen.dart';
import '../services/app_analytics.dart';

/// ⚔️ CPU対戦のまえの「参戦」演出。
///
/// 対戦相手をドンと見せてから試合に入る。ひとりで遊ぶモードは
/// 淡々と始まると盛り上がらないので、ここで一拍おいて気分を作る。
/// タップでいつでも飛ばせる（毎回見せられると邪魔になるため）。
class CpuEntryScreen extends StatefulWidget {
  final CpuLevel level;
  final int peopleCount;
  final int? copiesPerPerson;

  /// true = なまえコールのCPU戦 / false = 神経衰弱のCPU戦（既定）。
  final bool nameCall;

  const CpuEntryScreen({
    super.key,
    required this.level,
    required this.peopleCount,
    this.copiesPerPerson,
    this.nameCall = false,
  });

  @override
  State<CpuEntryScreen> createState() => _CpuEntryScreenState();
}

class _CpuEntryScreenState extends State<CpuEntryScreen> {
  late final Person _rival;
  bool _went = false;

  static const Map<CpuLevel, List<Color>> _colors = {
    CpuLevel.easy: [Color(0xFF2BB3A3), Color(0xFF0E6B60)],
    CpuLevel.normal: [Color(0xFF3A7BD5), Color(0xFF17408B)],
    CpuLevel.hard: [Color(0xFFE8663C), Color(0xFF9C2F10)],
    CpuLevel.oni: [Color(0xFF8A5AC2), Color(0xFF3D1E6B)],
    CpuLevel.god: [Color(0xFFFFD700), Color(0xFF8B0000)],
    CpuLevel.ultimate: [Color(0xFF4A0E7A), Color(0xFF1A0033)],
  };

  @override
  void initState() {
    super.initState();
    AppAnalytics.screen('cpu_entry');
    // 対戦相手の顔は、いま出演できるキャラから1人選ぶ
    // 🌍 対戦相手の顔も表示言語に合わせる（英語版は欧米系）
    final ja =
        WidgetsBinding.instance.platformDispatcher.locale.languageCode == 'ja';
    final pool = applyDeckFilter(
      playablePool(ja, PlayerProfile.instance.unlockedCharacters),
      PlayerProfile.instance.deckExcluded,
    );
    final rng = Random();
    _rival = generateRecallPeople(1, ja: ja, random: rng, charAssets: pool).first;
    Sfx.instance.fanfare();
    // 2.4秒たったら自動で試合へ
    Future.delayed(const Duration(milliseconds: 2400), _go);
  }

  void _go() {
    if (_went || !mounted) return;
    _went = true;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute<void>(
        // 🤖 どちらのCPU戦を始めるかは、難易度を選ぶ前に決めてもらう。
        //    ・神経衰弱（既定）… 従来どおり。カードをめくってペアをそろえる
        //    ・なまえコール    … 顔が再登場したら4択で答え、CPUより早ければ取れる
        //    以前は神経衰弱に固定で、なまえコールのCPU戦は実装済みなのに
        //    どこからも遊べなかった。
        builder: (_) => widget.nameCall
            ? NameCallScreen(
                humanPlayers: 1,
                quizMode: true, // ひとりで答えるので4択
                cpuLevel: widget.level,
                peopleCount: widget.peopleCount,
                copiesPerPerson: widget.copiesPerPerson,
              )
            : MatchGameScreen(cpuLevel: widget.level),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final m = MetaStrings.of(context);
    final colors = _colors[widget.level] ?? _colors[CpuLevel.normal]!;
    return Scaffold(
      backgroundColor: colors.last,
      body: GestureDetector(
        onTap: _go, // タップで飛ばせる
        behavior: HitTestBehavior.opaque,
        child: Stack(
          children: [
            // 後光のような放射状グラデーション
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    colors: [colors.first, colors.last],
                    radius: 0.95,
                  ),
                ),
              ),
            ),
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    m.cpuLevelName(widget.level),
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                      letterSpacing: 2,
                    ),
                  )
                      .animate()
                      .fadeIn(duration: 300.ms)
                      .slideY(begin: -0.5, end: 0, curve: Curves.easeOutBack),
                  const SizedBox(height: 18),
                  Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: Colors.white, width: 5),
                      boxShadow: const [
                        BoxShadow(
                            color: Color(0x66000000),
                            blurRadius: 24,
                            offset: Offset(0, 10)),
                      ],
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: FaceView(person: _rival, size: 200, radius: 20),
                  )
                      .animate()
                      .scale(
                        begin: const Offset(2.2, 2.2),
                        end: const Offset(1, 1),
                        duration: 480.ms,
                        curve: Curves.easeOutBack,
                      )
                      .fadeIn(duration: 220.ms)
                      .shake(delay: 480.ms, hz: 5, duration: 350.ms),
                  const SizedBox(height: 22),
                  Text(
                    m.cpuEntryJoin,
                    style: const TextStyle(
                      fontSize: 34,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                      letterSpacing: 4,
                      shadows: [
                        Shadow(
                            color: Color(0x99000000),
                            offset: Offset(0, 3),
                            blurRadius: 8),
                      ],
                    ),
                  )
                      .animate()
                      .fadeIn(delay: 520.ms, duration: 240.ms)
                      .scale(
                        delay: 520.ms,
                        begin: const Offset(1.8, 1.8),
                        end: const Offset(1, 1),
                        curve: Curves.easeOutBack,
                      ),
                  const SizedBox(height: 10),
                  Text(
                    m.cpuEntryTapToSkip,
                    style: const TextStyle(
                        fontSize: 12, color: Colors.white70),
                  ).animate().fadeIn(delay: 1200.ms),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
