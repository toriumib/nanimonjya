import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import '../services/ad_ids.dart';
import '../services/app_analytics.dart';
import '../services/player_profile.dart';

/// 🧩 一覧の中に差しこむネイティブ アドバンス広告。
///
/// バナーより単価が高く、まわりのカードに馴染ませられるのが利点。
/// そのぶん**広告だと分かる表示**（「広告」バッジ）が必須で、
/// それは Android 側のレイアウト native_ad_small.xml に入れてある。
///
/// ⚠️ Dart だけでは動かない。次の3つがそろって初めて表示される:
///   1. android/app/src/main/res/layout/native_ad_small.xml
///   2. NativeAdFactorySmall.kt
///   3. MainActivity.configureFlutterEngine での registerNativeAdFactory('small')
///
/// ⚠️ 高さは読み込む前から確保しておく（BannerAdSlot と同じ考え方）。
///    あとから広告が届いて一覧がずり上がると、押そうとした指が広告に当たる。
///    誤タップを誘発する配置はポリシー違反にもなりうる。
///
/// 出さない条件: Web／広告除去を買った人／本番IDが未設定のとき。
class NativeAdCard extends StatefulWidget {
  /// 分析用の場所名（'article_library' など）。
  final String placement;

  /// 確保しておく高さ。レイアウトの実寸に合わせてある。
  final double height;

  const NativeAdCard({
    super.key,
    required this.placement,
    this.height = 116,
  });

  @override
  State<NativeAdCard> createState() => _NativeAdCardState();
}

class _NativeAdCardState extends State<NativeAdCard> {
  NativeAd? _ad;
  bool _loaded = false;
  bool _failed = false;

  bool get _suppressed =>
      kIsWeb || !AdIds.nativeAvailable || PlayerProfile.instance.adsRemoved;

  @override
  void initState() {
    super.initState();
    if (_suppressed) return;
    _load();
  }

  void _load() {
    final ad = NativeAd(
      adUnitId: AdIds.nativeAdvanced,
      factoryId: 'small', // MainActivity で登録している ID
      request: const AdRequest(),
      listener: NativeAdListener(
        onAdLoaded: (ad) {
          AppAnalytics.nativeAdResult(
              placement: widget.placement, filled: true);
          // 破棄済みなら受け取らずに捨てる（AdWidget に渡すと落ちる）
          if (!mounted) {
            ad.dispose();
            return;
          }
          setState(() => _loaded = true);
        },
        onAdFailedToLoad: (ad, error) {
          AppAnalytics.nativeAdResult(
              placement: widget.placement, filled: false);
          ad.dispose();
          _ad = null;
          // 読み込めなかったと**確定**したときだけ場所ごと畳む。
          // ここで再試行を積むと、一覧を開くたびに無駄な通信が増える。
          if (mounted) setState(() => _failed = true);
        },
      ),
    );
    _ad = ad;
    ad.load();
  }

  @override
  void dispose() {
    _ad?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // 出さないと決まっている／読み込みに失敗が確定した ときは場所も取らない
    if (_suppressed || _failed) return const SizedBox.shrink();
    // 読み込み中も高さは確保しておく。あとから広告が挿入されて
    // 一覧がずり上がると、押そうとした指が広告に当たる（誤タップ）。
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: SizedBox(
        height: widget.height,
        child: (_loaded && _ad != null)
            ? AdWidget(ad: _ad!)
            : const SizedBox.shrink(),
      ),
    );
  }
}
