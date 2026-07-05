import 'dart:math';
import 'package:flutter/material.dart';
import '../models/cosmetics.dart';
import '../services/player_profile.dart';

/// バトル画面を応援するわんちゃんたち。
/// 累計コインが増えるほど仲間が増える（cosmetics.dart の kDogCompanions 参照）。
/// それぞれが位相をずらしてぴょこぴょこ跳ねる。
class DogSquad extends StatefulWidget {
  const DogSquad({super.key});

  @override
  State<DogSquad> createState() => _DogSquadState();
}

class _DogSquadState extends State<DogSquad>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: PlayerProfile.instance,
      builder: (context, _) {
        final dogs = unlockedDogs(PlayerProfile.instance.lifetimeCoins);
        if (dogs.isEmpty) return const SizedBox.shrink();
        return SizedBox(
          height: 44,
          child: AnimatedBuilder(
            animation: _controller,
            builder: (context, _) {
              return Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  for (int i = 0; i < dogs.length; i++)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 6),
                      child: Transform.translate(
                        // 位相をずらして順番にジャンプ
                        offset: Offset(
                          0,
                          -6 *
                              max(
                                0,
                                sin(
                                  (_controller.value * 2 * pi) + i * 0.9,
                                ),
                              ),
                        ),
                        child: Text(
                          dogs[i].emoji,
                          style: const TextStyle(fontSize: 28),
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
        );
      },
    );
  }
}
