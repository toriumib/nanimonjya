import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import '../services/ad_ids.dart';
import '../services/player_profile.dart';

/// 画面下部に置く共通バナー広告。
/// Scaffold の `bottomNavigationBar` にそのまま渡せる（高さ0で自動的に隙間を空ける）。
/// Web / 広告未対応環境では何も描画しない（SizedBox.shrink）。
class BannerAdSlot extends StatefulWidget {
  const BannerAdSlot({super.key});

  @override
  State<BannerAdSlot> createState() => _BannerAdSlotState();
}

class _BannerAdSlotState extends State<BannerAdSlot> {
  BannerAd? _bannerAd;
  bool _isLoaded = false;

  @override
  void initState() {
    super.initState();
    // 💎 広告除去を購入済みの人には出さない。
    // 課金機能自体は取り下げたが、買ってくれた人の権利は残す。
    if (!kIsWeb && !PlayerProfile.instance.adsRemoved) _loadBanner();
  }

  void _loadBanner() {
    final ad = BannerAd(
      adUnitId: AdIds.banner,
      size: AdSize.banner,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (ad) {
          if (!mounted) {
            ad.dispose();
            return;
          }
          setState(() => _isLoaded = true);
        },
        onAdFailedToLoad: (ad, error) {
          ad.dispose();
          if (mounted) setState(() => _isLoaded = false);
        },
      ),
    );
    _bannerAd = ad;
    ad.load();
  }

  @override
  void dispose() {
    _bannerAd?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // 広告を出さない環境では場所も取らない
    if (kIsWeb || PlayerProfile.instance.adsRemoved) {
      return const SizedBox.shrink();
    }

    // ⚠️ 読み込めるまで高さ0にすると、広告が届いた瞬間に画面全体が
    // ガクッと上へずれる。ボタンを押そうとした指が広告に当たってしまい、
    // 誤タップ（AdMobのポリシー違反にもなりうる）と操作ミスの原因になる。
    // そこで最初から同じ高さを確保し、中身だけ差し替える。
    final h = AdSize.banner.height.toDouble();
    return SafeArea(
      top: false,
      child: SizedBox(
        height: h,
        width: double.infinity,
        child: (_isLoaded && _bannerAd != null)
            ? Center(
                child: SizedBox(
                  width: _bannerAd!.size.width.toDouble(),
                  height: h,
                  child: AdWidget(ad: _bannerAd!),
                ),
              )
            : const SizedBox.shrink(),
      ),
    );
  }
}
