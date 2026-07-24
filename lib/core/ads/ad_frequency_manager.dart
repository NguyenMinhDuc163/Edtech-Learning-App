import 'package:ed_tech/core/ads/ad_storage.dart';
import 'package:ed_tech/core/ads/admob_config.dart';

/// Central frequency manager for all full-screen ad types.
///
/// Enforces cooldowns, daily caps, session limits, and screen-level blocks.
/// In-memory state is backed by [AdStorage] for persistence across launches.
class AdFrequencyManager {
  AdFrequencyManager._();

  static final AdFrequencyManager instance = AdFrequencyManager._();

  // ---- In-memory state ----

  final DateTime appStartedAt = DateTime.now();

  DateTime? lastInterstitialAt;
  DateTime? lastRewardedInterstitialAt;
  DateTime? lastAppOpenAt;
  DateTime? backgroundStartedAt;

  int sessionInterstitialCount = 0;
  // daily counts are read/written directly via AdStorage

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

    // Minimum time after app start
    final elapsed = DateTime.now().difference(appStartedAt);
    if (elapsed < AdMobConfig.minimumTimeAfterAppStart) return false;

    // Cooldown between interstitials
    if (lastInterstitialAt != null) {
      final sinceLast =
          DateTime.now().difference(lastInterstitialAt!);
      if (sinceLast < AdMobConfig.minimumInterstitialInterval) return false;
    }

    // Session cap
    if (sessionInterstitialCount >=
        AdMobConfig.maximumInterstitialPerSession) {
      return false;
    }

    // Daily cap
    if (AdStorage.dailyInterstitialCount >=
        AdMobConfig.maximumInterstitialPerDay) {
      return false;
    }

    return true;
  }

  void recordInterstitialShown() {
    lastInterstitialAt = DateTime.now();
    sessionInterstitialCount++;
    AdStorage.dailyInterstitialCount++;
  }

  // ---- Rewarded (user-initiated, fewer limits) ----

  bool canShowRewarded() {
    if (!AdMobConfig.adsEnabled || !AdMobConfig.rewardedEnabled) {
      return false;
    }

    if (isFullScreenAdShowing) return false;

    // Daily cap
    if (AdStorage.dailyRewardedCount >=
        AdMobConfig.maximumRewardedAdsPerDay) {
      return false;
    }

    return true;
  }

  void recordRewardedShown() {
    AdStorage.dailyRewardedCount++;
  }

  // ---- Rewarded Interstitial ----

  bool canShowRewardedInterstitial() {
    if (!AdMobConfig.adsEnabled ||
        !AdMobConfig.rewardedInterstitialEnabled) {
      return false;
    }

    if (isFullScreenAdShowing) return false;
    if (isQuizTaking || isVideoPlaying || isPaymentFlowActive) return false;

    // Cooldown
    if (lastRewardedInterstitialAt != null) {
      final sinceLast =
          DateTime.now().difference(lastRewardedInterstitialAt!);
      if (sinceLast <
          AdMobConfig.minimumRewardedInterstitialInterval) {
        return false;
      }
    }

    // Daily cap
    if (AdStorage.dailyRewardedInterstitialCount >=
        AdMobConfig.maximumRewardedInterstitialPerDay) {
      return false;
    }

    return true;
  }

  void recordRewardedInterstitialShown() {
    lastRewardedInterstitialAt = DateTime.now();
    AdStorage.dailyRewardedInterstitialCount++;
  }

  // ---- App Open ----

  bool canShowAppOpen() {
    if (!AdMobConfig.adsEnabled || !AdMobConfig.appOpenEnabled) {
      return false;
    }

    if (isFullScreenAdShowing) return false;
    if (isQuizTaking || isVideoPlaying || isPaymentFlowActive) return false;

    // Minimum app launches
    if (AdStorage.appLaunchCount <
        AdMobConfig.minimumAppLaunchesBeforeAppOpen) {
      return false;
    }

    // Background duration
    if (backgroundStartedAt != null) {
      final bgDuration =
          DateTime.now().difference(backgroundStartedAt!);
      if (bgDuration <
          AdMobConfig.minimumBackgroundDurationForAppOpen) {
        return false;
      }
    }

    // Cooldown between app opens
    if (lastAppOpenAt != null) {
      final sinceLast =
          DateTime.now().difference(lastAppOpenAt!);
      if (sinceLast < AdMobConfig.minimumAppOpenInterval) return false;
    }

    // Daily cap
    if (AdStorage.dailyAppOpenCount >=
        AdMobConfig.maximumAppOpenPerDay) {
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

  void onResumed() {
    // backgroundStartedAt is read in canShowAppOpen()
  }

  // ---- Reset for testing ----

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
