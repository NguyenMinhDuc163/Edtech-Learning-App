import 'package:ed_tech/core/ads/ad_storage.dart';
import 'package:ed_tech/core/ads/admob_config.dart';

/// Central frequency manager for all full-screen ad types.
/// TEST MODE: all canShow*() always return true.
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

  // ---- TEST MODE: always allow ----

  bool canShowInterstitial() => true;

  void recordInterstitialShown() {
    lastInterstitialAt = DateTime.now();
    sessionInterstitialCount++;
    AdStorage.dailyInterstitialCount++;
  }

  bool canShowRewarded() => true;

  void recordRewardedShown() {
    AdStorage.dailyRewardedCount++;
  }

  bool canShowRewardedInterstitial() => true;

  void recordRewardedInterstitialShown() {
    lastRewardedInterstitialAt = DateTime.now();
    AdStorage.dailyRewardedInterstitialCount++;
  }

  bool canShowAppOpen() => true;

  void recordAppOpenShown() {
    lastAppOpenAt = DateTime.now();
    AdStorage.dailyAppOpenCount++;
  }

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
