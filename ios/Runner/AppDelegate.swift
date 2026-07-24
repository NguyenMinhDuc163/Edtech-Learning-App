import Flutter
import UIKit
import GoogleMobileAds

@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    GeneratedPluginRegistrant.register(with: self)

    // Register Native Ad Factory
    FLTGoogleMobileAdsPlugin.registerNativeAdFactory(
      self,
      factoryId: "eduTechNativeAdFactory",
      nativeAdFactory: EduTechNativeAdFactory()
    )

    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}
