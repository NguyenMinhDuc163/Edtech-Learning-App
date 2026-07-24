import 'package:ed_tech/core/ads/ad_storage.dart';
import 'package:ed_tech/core/ads/admob_config.dart';

/// Central frequency manager for all full-screen ad types.
///
/// Enforces cooldowns, daily caps, session limits, and screen-level blocks.
class AdFrequencyManager {
  AdFrequencyManager._();

  static final AdFrequencyManager instance = AdFrequencyManager._();

  final DateTime appStartedAt = DateTime.now();

  DateTime? lastInterstitialAt;
  DateTime? lastRewardedInterstitialAt;
  DateTime? lastAppOpenAt;
  DateTime? backgroundStartedAt;

  int sessionInterstitialCount = 0;

  bool isFullScreenAdShowing = false;
  bool isQuizTaking = false;
  bool isVideoPlaying = false;
  bool isPaymentFlowActive = false;

  // ---- Interstitial ----

  bool canShowInterstitial() {
    if (!AdMobConfig.adsEnabled || !AdMobConfig.interstitialEnabled) {
      return false;
    }

    if (isFullScreenAdShowing) return false;
    if (isQuizTaking || isVideoPlaying || isPaymentFlowActive) return false;

    final elapsed = DateTime.now().difference(appStartedAt);
    if (elapsed < AdMobConfig.minimumTimeAfterAppStart) return false;

    if (lastInterstitialAt != null) {
      final sinceLast = DateTime.now().difference(lastInterstitialAt!);
      if (sinceLast < AdMobConfig.minimumInterstitialInterval) return false;
    }

    if (sessionInterstitialCount >= AdMobConfig.maximumInterstitialPerSession) {
      return false;
    }

    if (AdStorage.dailyInterstitialCount >= AdMobConfig.maximumInterstitialPerDay) {
      return false;
    }

    return true;
  }

  void recordInterstitialShown() {
    lastInterstitialAt = DateTime.now();
    sessionInterstitialCount++;
    AdStorage.dailyInterstitialCount++;
  }

  // ---- Rewarded ----

  bool canShowRewarded() {
    if (!AdMobConfig.adsEnabled || !AdMobConfig.rewardedEnabled) return false;
    if (isFullScreenAdShowing) return false;
    if (AdStorage.dailyRewardedCount >= AdMobConfig.maximumRewardedAdsPerDay) {
      return false;
    }
    return true;
  }

  void recordRewardedShown() {
    AdStorage.dailyRewardedCount++;
  }

  // ---- Rewarded Interstitial ----

  bool canShowRewardedInterstitial() {
    if (!AdMobConfig.adsEnabled || !AdMobConfig.rewardedInterstitialEnabled) {
      return false;
    }
    if (isFullScreenAdShowing) return false;
    if (isQuizTaking || isVideoPlaying || isPaymentFlowActive) return false;

    if (lastRewardedInterstitialAt != null) {
      if (DateTime.now().difference(lastRewardedInterstitialAt!) <
          AdMobConfig.minimumRewardedInterstitialInterval) return false;
    }
    if (AdStorage.dailyRewardedInterstitialCount >=
        AdMobConfig.maximumRewardedInterstitialPerDay) return false;

    return true;
  }

  void recordRewardedInterstitialShown() {
    lastRewardedInterstitialAt = DateTime.now();
    AdStorage.dailyRewardedInterstitialCount++;
  }

  // ---- App Open ----

  bool canShowAppOpen() {
    if (!AdMobConfig.adsEnabled || !AdMobConfig.appOpenEnabled) return false;
    if (isFullScreenAdShowing) return false;
    if (isQuizTaking || isVideoPlaying || isPaymentFlowActive) return false;

    if (AdStorage.appLaunchCount < AdMobConfig.minimumAppLaunchesBeforeAppOpen) {
      return false;
    }

    if (backgroundStartedAt != null) {
      if (DateTime.now().difference(backgroundStartedAt!) <
          AdMobConfig.minimumBackgroundDurationForAppOpen) return false;
    }

    if (lastAppOpenAt != null) {
      if (DateTime.now().difference(lastAppOpenAt!) <
          AdMobConfig.minimumAppOpenInterval) return false;
    }

    if (AdStorage.dailyAppOpenCount >= AdMobConfig.maximumAppOpenPerDay) {
      return false;
    }

    return true;
  }

  void recordAppOpenShown() {
    lastAppOpenAt = DateTime.now();
    AdStorage.dailyAppOpenCount++;
  }

  // ---- Background tracking ----

  void onPaused() {
    backgroundStartedAt = DateTime.now();
  }

  void onResumed() {}

  void resetForTest() {
    lastInterstitialAt = null;
    lastRewardedInterstitialAt = null;
    lastAppOpenAt = null;
    backgroundStartedAt = null;
    sessionInterstitialCount = 0;
    isFullScreenAdShowing = false;
    isQuizTaking = false;
    isVideoPlaying = false;
    isPaymentFlowActive = false;
  }
}
