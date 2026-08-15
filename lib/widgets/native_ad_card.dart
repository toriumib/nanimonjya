import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import '../services/ad_ids.dart';
import '../services/app_analytics.dart';
import '../services/player_profile.dart';

/// 🧩 一覧やリザルトに差しこむネイティブ アドバンス広告。
///
/// バナーより単価が高く、まわりのカードに馴染ませられるのが利点。
/// そのぶん「広告」だと分かる表示が要るが、そこは **Google 公式テンプレート**
/// （[NativeTemplateStyle]）が面倒を見てくれる。
///
/// ⚠️ **factoryId 方式（自前レイアウト）は採用していない。**
///    自前でやると Android 側に3点セットが要る
///    （res/layout の xml・NativeAdFactory の Kotlin・MainActivity での
///    registerNativeAdFactory）。Dart だけ直しても直らない構造になり、
///    壊れたときの原因究明が重い。見た目の自由度と引き換えに
///    公式テンプレートへ寄せてある。**Android 側の追加実装はゼロ。**
///
/// ⚠️ 高さは読み込む前から確保する。あとから広告が挿入されて一覧がずり上がると、
///    押そうとした指が広告に当たる。誤タップを誘発する配置はポリシー違反にも
///    なりうる（BannerAdSlot と同じ考え方）。
///
/// 出さない条件: Web／広告除去を買った人／本番IDが未設定のとき。
class NativeAdCard extends StatefulWidget {
  /// 分析用の場所名（'article_library' / 'result' など）。
  /// どの面が埋まってどの面が埋まらないかを分けて数えるために使う。
  final String placement;

  /// テンプレートの大きさ。
  /// 一覧の途中に挟むときは [TemplateType.small]、
  /// リザルトのように見せ場が取れるところは [TemplateType.medium]。
  final TemplateType templateType;

  const NativeAdCard({
    super.key,
    required this.placement,
    this.templateType = TemplateType.small,
  });

  @override
  State<NativeAdCard> createState() => _NativeAdCardState();
}

class _NativeAdCardState extends State<NativeAdCard> {
  NativeAd? _ad;
  bool _loaded = false;
  bool _failed = false;
  bool _requested = false;

  /// 読み込み前に確保しておく高さ（テンプレートの概算）。
  double get _slotHeight =>
      widget.templateType == TemplateType.medium ? 340 : 120;

  bool get _suppressed =>
      kIsWeb || !AdIds.nativeAvailable || PlayerProfile.instance.adsRemoved;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // 1回だけ走らせる（BannerAdSlot と同じ作り）
    if (_requested) return;
    _requested = true;
    if (_suppressed) return;
    _load();
  }

  void _load() {
    final ad = NativeAd(
      adUnitId: AdIds.nativeAdvanced,
      request: const AdRequest(),
      nativeTemplateStyle: NativeTemplateStyle(
        templateType: widget.templateType,
        cornerRadius: 16,
      ),
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
    // 出さないと決まっている／読み込み失敗が確定した ときは場所も取らない
    if (_suppressed || _failed) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: SizedBox(
        height: _slotHeight,
        width: double.infinity,
        child: (_loaded && _ad != null)
            ? ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: AdWidget(ad: _ad!),
              )
            : const SizedBox.shrink(),
      ),
    );
  }
}
