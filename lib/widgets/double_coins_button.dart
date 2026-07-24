import 'package:flutter/material.dart';

import '../l10n/meta_strings.dart';
import '../services/player_profile.dart';
import '../services/reward_ad_helper.dart';
import '../services/sfx.dart';

/// リザルト画面用「動画を見てコイン2倍」ボタン。
///
/// ユーザーが一番テンションの高い「結果が出た直後」に置くことで、
/// リワード広告の視聴率がもっとも高くなる定番の配置。
/// [coinsEarned] が0以下のときは何も表示しない（獲得コインがない結果では出さない）。
class DoubleCoinsButton extends StatefulWidget {
  final int coinsEarned;

  const DoubleCoinsButton({super.key, required this.coinsEarned});

  @override
  State<DoubleCoinsButton> createState() => _DoubleCoinsButtonState();
}

class _DoubleCoinsButtonState extends State<DoubleCoinsButton> {
  final RewardAdHelper _ad = RewardAdHelper();
  bool _doubled = false;

  @override
  void initState() {
    super.initState();
    if (widget.coinsEarned > 0 && RewardAdHelper.available) {
      _ad.load();
    }
  }

  @override
  void dispose() {
    _ad.dispose();
    super.dispose();
  }

  Future<void> _watch() async {
    final m = MetaStrings.of(context);
    final played = await _ad.showOrQueue(onReward: () async {
      await PlayerProfile.instance.grantBonusCoins(widget.coinsEarned);
      Sfx.instance.reward();
      if (mounted) {
        setState(() => _doubled = true);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(m.earnedCoins(widget.coinsEarned))),
        );
      }
    });
    if (!played && mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(m.storeAdLoading)));
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.coinsEarned <= 0 || !RewardAdHelper.available) {
      return const SizedBox.shrink();
    }
    final m = MetaStrings.of(context);
    if (_doubled) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Text(m.doubleCoinsDone,
            textAlign: TextAlign.center,
            style: const TextStyle(
                fontSize: 13, fontWeight: FontWeight.w900,
                color: Color(0xFF2E9E52))),
      );
    }
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: SizedBox(
        width: double.infinity,
        child: AnimatedBuilder(
          animation: _ad,
          builder: (context, _) {
            return Container(
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF43C46B), Color(0xFF2E9E52)],
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF43C46B)
                        .withValues(alpha: _ad.isReady ? 0.4 : 0.15),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: ElevatedButton.icon(
                onPressed: _watch,
                icon: const Icon(Icons.play_circle_fill, size: 22),
                label: Text(m.doubleCoinsButton(widget.coinsEarned)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  shadowColor: Colors.transparent,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 13),
                  textStyle: const TextStyle(
                      fontSize: 14.5, fontWeight: FontWeight.w900),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
