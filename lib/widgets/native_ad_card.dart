import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import '../services/ad_ids.dart';
import '../services/player_profile.dart';

/// リザルト画面などの本文（スクロール一覧）に差し込むネイティブ広告。
/// 下部バナーより eCPM が高く、結果カードの1つとして自然に溶け込む。
///
/// Web / 広告未対応環境では何も描画しない（SizedBox.shrink）。
///
/// ⚠️ 読み込む前に高さを確保して、広告が届いた瞬間に下のボタンが
///    ずり上がって誤タップを誘発しないようにする（BannerAdSlot と同じ方針）。
class NativeAdCard extends StatefulWidget {
  const NativeAdCard({super.key});

  @override
  State<NativeAdCard> createState() => _NativeAdCardState();
}

class _NativeAdCardState extends State<NativeAdCard> {
  NativeAd? _ad;
  bool _isLoaded = false;
  bool _requested = false;

  /// ミディアムテンプレートの概算高さ。読み込み前の場所取りに使う。
  static const double _slotHeight = 340;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_requested) return;
    _requested = true;
    if (kIsWeb || PlayerProfile.instance.adsRemovedOrPremium || !AdIds.nativeAvailable) {
      return;
    }
    _loadNativeAd();
  }

  Future<void> _loadNativeAd() async {
    final ad = NativeAd(
      adUnitId: AdIds.nativeAdvanced,
      request: const AdRequest(),
      listener: NativeAdListener(
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
      nativeTemplateStyle: NativeTemplateStyle(
        templateType: TemplateType.medium,
      ),
    );
    _ad = ad;
    await ad.load();
  }

  @override
  void dispose() {
    _ad?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // 💎 広告除去を買った瞬間に消えるよう、購入状態を聞いておく（バナーと同じ）
    return ListenableBuilder(
      listenable: PlayerProfile.instance,
      builder: (context, _) => _build(context),
    );
  }

  Widget _build(BuildContext context) {
    if (kIsWeb || PlayerProfile.instance.adsRemovedOrPremium || !AdIds.nativeAvailable) {
      if (_ad != null) {
        _ad?.dispose();
        _ad = null;
        _isLoaded = false;
      }
      return const SizedBox.shrink();
    }
    if (_isLoaded && _ad != null) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: AdWidget(ad: _ad!),
      );
    }
    // 読み込み中は場所を確保して、後からのレイアウトずれを防ぐ。
    return const SizedBox(height: _slotHeight, width: double.infinity);
  }
}
