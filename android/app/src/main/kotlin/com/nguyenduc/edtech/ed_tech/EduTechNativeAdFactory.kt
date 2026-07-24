package com.nguyenduc.edtech.ed_tech

import android.app.Activity
import android.view.LayoutInflater
import android.view.View
import android.widget.Button
import android.widget.ImageView
import android.widget.RatingBar
import android.widget.TextView
import com.google.android.gms.ads.nativead.MediaView
import com.google.android.gms.ads.nativead.NativeAd
import com.google.android.gms.ads.nativead.NativeAdView
import io.flutter.plugins.googlemobileads.GoogleMobileAdsPlugin

class EduTechNativeAdFactory : GoogleMobileAdsPlugin.NativeAdFactory {

    override fun createNativeAd(
        nativeAd: NativeAd,
        customOptions: MutableMap<String, Any>?
    ): NativeAdView {
        val activity = MainActivity.currentActivity ?: throw IllegalStateException("Activity not available")
        val inflater = LayoutInflater.from(activity)
        val nativeAdView = inflater.inflate(R.layout.native_ad_layout, null) as NativeAdView

        // Attribution
        nativeAdView.findViewById<TextView>(R.id.native_ad_attribution).text = "Ad"

        // Headline
        val headlineView = nativeAdView.findViewById<TextView>(R.id.native_ad_headline)
        headlineView.text = nativeAd.headline
        nativeAdView.headlineView = headlineView

        // Body
        val bodyView = nativeAdView.findViewById<TextView>(R.id.native_ad_body)
        if (nativeAd.body != null) {
            bodyView.text = nativeAd.body
            bodyView.visibility = View.VISIBLE
            nativeAdView.bodyView = bodyView
        } else {
            bodyView.visibility = View.GONE
        }

        // Icon
        val iconView = nativeAdView.findViewById<ImageView>(R.id.native_ad_icon)
        if (nativeAd.icon != null) {
            iconView.setImageDrawable(nativeAd.icon!!.drawable)
            nativeAdView.iconView = iconView
        } else {
            iconView.visibility = View.GONE
        }

        // Media
        val mediaView = nativeAdView.findViewById<MediaView>(R.id.native_ad_media)
        nativeAdView.mediaView = mediaView
        mediaView.setMediaContent(nativeAd.mediaContent)

        // Advertiser
        val advertiserView = nativeAdView.findViewById<TextView>(R.id.native_ad_advertiser)
        if (nativeAd.advertiser != null) {
            advertiserView.text = nativeAd.advertiser
            advertiserView.visibility = View.VISIBLE
            nativeAdView.advertiserView = advertiserView
        } else {
            advertiserView.visibility = View.GONE
        }

        // CTA
        val ctaView = nativeAdView.findViewById<Button>(R.id.native_ad_cta)
        if (nativeAd.callToAction != null) {
            ctaView.text = nativeAd.callToAction
            nativeAdView.callToActionView = ctaView
        } else {
            ctaView.visibility = View.GONE
        }

        // Store
        val storeView = nativeAdView.findViewById<TextView>(R.id.native_ad_store)
        if (nativeAd.store != null) {
            storeView.text = nativeAd.store
            storeView.visibility = View.VISIBLE
            nativeAdView.storeView = storeView
        } else {
            storeView.visibility = View.GONE
        }

        // Price
        val priceView = nativeAdView.findViewById<TextView>(R.id.native_ad_price)
        if (nativeAd.price != null) {
            priceView.text = nativeAd.price
            priceView.visibility = View.VISIBLE
            nativeAdView.priceView = priceView
        } else {
            priceView.visibility = View.GONE
        }

        // Star Rating
        val starRatingView = nativeAdView.findViewById<RatingBar>(R.id.native_ad_stars)
        if (nativeAd.starRating != null) {
            starRatingView.rating = nativeAd.starRating!!.toFloat()
            starRatingView.visibility = View.VISIBLE
            nativeAdView.starRatingView = starRatingView
        } else {
            starRatingView.visibility = View.GONE
        }

        nativeAdView.setNativeAd(nativeAd)
        return nativeAdView
    }
}
