import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import '../services/ad_ids.dart';
import '../services/player_profile.dart';

/// 画面下部に置く共通バナー広告。
/// Scaffold の `bottomNavigationBar` にそのまま渡せる。
/// Web / 広告未対応環境では何も描画しない（SizedBox.shrink）。
///
/// 📐 **アンカード・アダプティブバナー**を使う。
///
/// 以前は 320×50 の固定サイズ（`AdSize.banner`）だった。固定だと、
/// 幅の広い端末では左右に余白が出て**画面の一等地を使い切れず**、
/// 逆に狭い端末でははみ出しかねない。アダプティブは端末の幅に合わせた
/// 高さ・幅で配信されるので、見た目も収まりがよく、配信面としての
/// 評価も上がるとされている（AdMobが推奨している方式）。
///
/// ⚠️ 高さは**読み込む前に確保**する。あとから広告が届いて画面が
///    ずり上がると、押そうとした指が広告に当たる。誤操作であり、
///    誤タップを誘発する配置はポリシー違反にもなりうる。
class BannerAdSlot extends StatefulWidget {
  const BannerAdSlot({super.key});

  @override
  State<BannerAdSlot> createState() => _BannerAdSlotState();
}

class _BannerAdSlotState extends State<BannerAdSlot> {
  BannerAd? _bannerAd;
  bool _isLoaded = false;

  /// 確保しておく高さ。アダプティブのサイズが分かるまでは既定値を使う。
  double _slotHeight = AdSize.banner.height.toDouble();
  bool _requested = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // 画面幅が要るので initState ではなくここで。1回だけ走らせる。
    if (_requested) return;
    _requested = true;
    // 💎 広告除去を購入済みの人には出さない。
    // 課金機能自体は取り下げたが、買ってくれた人の権利は残す。
    if (kIsWeb || PlayerProfile.instance.adsRemoved) return;
    _loadAdaptiveBanner(MediaQuery.of(context).size.width.truncate());
  }

  Future<void> _loadAdaptiveBanner(int width) async {
    final size = await AdSize.getCurrentOrientationAnchoredAdaptiveBannerAdSize(
        width);
    if (size == null || !mounted) return; // 取れなければ広告を出さない
    setState(() => _slotHeight = size.height.toDouble());
    final ad = BannerAd(
      adUnitId: AdIds.banner,
      size: size,
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
    await ad.load();
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
    return SafeArea(
      top: false,
      child: SizedBox(
        height: _slotHeight,
        width: double.infinity,
        child: (_isLoaded && _bannerAd != null)
            ? Center(
                child: SizedBox(
                  width: _bannerAd!.size.width.toDouble(),
                  height: _slotHeight,
                  child: AdWidget(ad: _bannerAd!),
                ),
              )
            : const SizedBox.shrink(),
      ),
    );
  }
}
