// ⚠️ ディレクトリは com/kengo/marubatusokketu/ のままだが、package は com.nanimonjya。
//    MainActivity.kt が同じ形になっている（Kotlin はディレクトリ一致を要求しない）。
//    ディレクトリを動かすと applicationId まわりで事故りやすいので触らない。
package com.nanimonjya

import android.view.LayoutInflater
import android.widget.Button
import android.widget.ImageView
import android.widget.TextView
import com.google.android.gms.ads.nativead.NativeAd
import com.google.android.gms.ads.nativead.NativeAdView
import io.flutter.plugins.googlemobileads.GoogleMobileAdsPlugin

/**
 * 🧩 ネイティブ アドバンス広告を native_ad_small.xml に流しこむファクトリ。
 *
 * Flutter 側は `NativeAd(factoryId = "small", ...)` で呼ぶ。
 * この登録が無いと広告は**必ず読み込みに失敗する**（Dart だけでは完結しない）。
 *
 * 差しこむ項目が空のときは、その View を GONE にする。
 * 空文字のまま出すと、無地の帯が残って「壊れている」ように見える。
 */
class NativeAdFactorySmall(private val inflater: LayoutInflater) :
    GoogleMobileAdsPlugin.NativeAdFactory {

    override fun createNativeAd(
        nativeAd: NativeAd,
        customOptions: MutableMap<String, Any>?
    ): NativeAdView {
        val adView =
            inflater.inflate(R.layout.native_ad_small, null) as NativeAdView

        val headline = adView.findViewById<TextView>(R.id.ad_headline)
        headline.text = nativeAd.headline
        adView.headlineView = headline

        val body = adView.findViewById<TextView>(R.id.ad_body)
        if (nativeAd.body.isNullOrEmpty()) {
            body.visibility = android.view.View.GONE
        } else {
            body.visibility = android.view.View.VISIBLE
            body.text = nativeAd.body
        }
        adView.bodyView = body

        val icon = adView.findViewById<ImageView>(R.id.ad_icon)
        val iconDrawable = nativeAd.icon?.drawable
        if (iconDrawable == null) {
            icon.visibility = android.view.View.GONE
        } else {
            icon.visibility = android.view.View.VISIBLE
            icon.setImageDrawable(iconDrawable)
        }
        adView.iconView = icon

        val cta = adView.findViewById<Button>(R.id.ad_call_to_action)
        if (nativeAd.callToAction.isNullOrEmpty()) {
            cta.visibility = android.view.View.GONE
        } else {
            cta.visibility = android.view.View.VISIBLE
            cta.text = nativeAd.callToAction
        }
        adView.callToActionView = cta

        // ここを呼んで初めてクリックとインプレッションが計測される
        adView.setNativeAd(nativeAd)
        return adView
    }
}
