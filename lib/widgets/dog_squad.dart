import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import '../models/cosmetics.dart';
import '../services/player_profile.dart';

/// バトル画面を応援する「応援ゾーン」。
/// ・わんちゃん：累計コインで仲間が増える（kDogCompanions）
/// ・チア応援団：コインでアップグレード（kCheerStages / cheerLevel）
/// メンバーは位相をずらしてぴょこぴょこ跳ね、数秒ごとに誰かが吹き出しで声援を送る。
class DogSquad extends StatefulWidget {
  const DogSquad({super.key});

  @override
  State<DogSquad> createState() => _DogSquadState();
}

class _DogSquadState extends State<DogSquad>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  Timer? _bubbleTimer;
  final Random _random = Random();
  int _bubbleMemberIndex = -1; // 今しゃべっているメンバー（-1でなし）
  String _bubbleText = '';

  static const List<String> _dogCheersJa = ['ワン！', 'ワンワン♪', 'クゥ〜ン'];
  static const List<String> _cheerCheersJa = [
    'がんばれ〜！',
    'ナイス！',
    'その調子！',
    'いけいけ〜！',
    'フレー！フレー！',
  ];
  static const List<String> _dogCheersEn = ['Woof!', 'Arf arf♪', 'Awoo~'];
  static const List<String> _cheerCheersEn = [
    'Go go!',
    'Nice!',
    'Keep it up!',
    'You got this!',
    'Hooray!',
  ];

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat();
    // 4秒ごとにランダムなメンバーが声援（2秒表示して消える）
    _bubbleTimer = Timer.periodic(const Duration(seconds: 4), (_) {
      if (!mounted) return;
      final profile = PlayerProfile.instance;
      final dogs = unlockedDogs(profile.lifetimeCoins);
      final cheers = cheerMembers(profile.cheerLevel);
      final total = dogs.length + cheers.length;
      if (total == 0) return;
      final ja = Localizations.localeOf(context).languageCode == 'ja';
      final idx = _random.nextInt(total);
      final isDog = idx < dogs.length;
      final pool = isDog
          ? (ja ? _dogCheersJa : _dogCheersEn)
          : (ja ? _cheerCheersJa : _cheerCheersEn);
      setState(() {
        _bubbleMemberIndex = idx;
        _bubbleText = pool[_random.nextInt(pool.length)];
      });
      Future.delayed(const Duration(seconds: 2), () {
        if (mounted) setState(() => _bubbleMemberIndex = -1);
      });
    });
  }

  @override
  void dispose() {
    _bubbleTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: PlayerProfile.instance,
      builder: (context, _) {
        final profile = PlayerProfile.instance;
        final dogs = unlockedDogs(profile.lifetimeCoins);
        final cheers = cheerMembers(profile.cheerLevel);
        // 表示メンバー: わんちゃん → チア の順に並べる
        final members = <String>[
          ...dogs.map((d) => d.emoji),
          ...cheers,
        ];
        if (members.isEmpty) return const SizedBox.shrink();

        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          padding: const EdgeInsets.symmetric(vertical: 6),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFFFFF6D8), Color(0xFFFFE3F0), Color(0xFFD8F6F0)],
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white, width: 2),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.08),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: SizedBox(
            height: 62,
            child: AnimatedBuilder(
              animation: _controller,
              builder: (context, _) {
                return Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    for (int i = 0; i < members.length; i++)
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 5),
                        child: _member(members[i], i),
                      ),
                  ],
                );
              },
            ),
          ),
        );
      },
    );
  }

  // 1メンバー分（跳ねる絵文字＋しゃべっていれば吹き出し）
  Widget _member(String emoji, int index) {
    final double bounce =
        -7.0 * max(0.0, sin((_controller.value * 2 * pi) + index * 0.9));
    final speaking = index == _bubbleMemberIndex;
    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      mainAxisSize: MainAxisSize.min,
      children: [
        // 吹き出し（しゃべっている時だけ・ポンと拡大登場）
        if (speaking)
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0.5, end: 1.0),
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOutBack,
            builder: (context, scale, child) =>
                Transform.scale(scale: scale, child: child),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFFF4FA3), width: 1.5),
              ),
              child: Text(
                _bubbleText,
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFFB4326E),
                ),
              ),
            ),
          )
        else
          const SizedBox(height: 22),
        Transform.translate(
          offset: Offset(0, bounce),
          child: Text(
            emoji,
            style: TextStyle(
              fontSize: speaking ? 32.0 : 28.0, // しゃべる子は少し大きく
              shadows: const [
                Shadow(
                  offset: Offset(1.5, 2.5),
                  blurRadius: 3,
                  color: Color(0x33000000),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
