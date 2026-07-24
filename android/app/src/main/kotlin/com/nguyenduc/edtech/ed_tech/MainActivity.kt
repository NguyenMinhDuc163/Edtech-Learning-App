package com.nguyenduc.edtech.ed_tech

import android.app.Activity
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugins.googlemobileads.GoogleMobileAdsPlugin

class MainActivity : FlutterActivity() {

    companion object {
        var currentActivity: Activity? = null
    }

    override fun onResume() {
        super.onResume()
        currentActivity = this
    }

    override fun onPause() {
        super.onPause()
        // Don't clear currentActivity here, keep it for ad factory
    }

    override fun onDestroy() {
        currentActivity = null
        super.onDestroy()
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        currentActivity = this

        GoogleMobileAdsPlugin.registerNativeAdFactory(
            flutterEngine,
            "eduTechNativeAdFactory",
            EduTechNativeAdFactory()
        )
    }

    override fun cleanUpFlutterEngine(flutterEngine: FlutterEngine) {
        GoogleMobileAdsPlugin.unregisterNativeAdFactory(
            flutterEngine,
            "eduTechNativeAdFactory"
        )
        super.cleanUpFlutterEngine(flutterEngine)
    }
}
