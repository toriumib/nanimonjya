package com.nanimonjya

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugins.googlemobileads.GoogleMobileAdsPlugin

class MainActivity: FlutterActivity() {

    /**
     * 🧩 ネイティブ広告のファクトリを登録する。
     *
     * Flutter 側の `NativeAd(factoryId: 'small')` はこの ID を引く。
     * 登録し忘れると読み込みが必ず失敗するので、Dart 側だけ直しても直らない。
     */
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        GoogleMobileAdsPlugin.registerNativeAdFactory(
            flutterEngine, "small", NativeAdFactorySmall(layoutInflater)
        )
    }

    override fun cleanUpFlutterEngine(flutterEngine: FlutterEngine) {
        GoogleMobileAdsPlugin.unregisterNativeAdFactory(flutterEngine, "small")
        super.cleanUpFlutterEngine(flutterEngine)
    }
}
