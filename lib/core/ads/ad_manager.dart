import 'dart:async';

import 'package:ed_tech/core/ads/ad_frequency_manager.dart';
import 'package:ed_tech/core/ads/admob_config.dart';
import 'package:ed_tech/core/ads/models/ad_show_result.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

/// Manages preloading and showing full-screen ads: Interstitial, Rewarded,
/// and Rewarded Interstitial.
///
/// Usage:
/// ```dart
/// final result = await AdManager.instance.showInterstitialIfAllowed();
/// ```
class AdManager {
  AdManager._();

  static final AdManager instance = AdManager._();

  final AdFrequencyManager _freq = AdFrequencyManager.instance;

  InterstitialAd? _interstitialAd;
  RewardedAd? _rewardedAd;
  RewardedInterstitialAd? _rewardedInterstitialAd;

  bool _isLoadingInterstitial = false;
  bool _isLoadingRewarded = false;
  bool _isLoadingRewardedInterstitial = false;

  Completer<AdShowResult>? _interstitialCompleter;
  Completer<AdShowResult>? _rewardedCompleter;
  Completer<AdShowResult>? _rewardedInterstitialCompleter;

  // ---- Preload ----

  Future<void> preloadFullScreenAds() async {
    // Fire and forget – load all types concurrently
    _loadInterstitial();
    _loadRewarded();
    _loadRewardedInterstitial();
  }

  // ---- Interstitial ----

  Future<void> _loadInterstitial() async {
    if (_isLoadingInterstitial || _interstitialAd != null) return;
    _isLoadingInterstitial = true;

    await InterstitialAd.load(
      adUnitId: AdMobConfig.interstitialAdUnitId,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          _interstitialAd = ad;
          _isLoadingInterstitial = false;

          ad.fullScreenContentCallback = FullScreenContentCallback(
            onAdDismissedFullScreenContent: (ad) {
              ad.dispose();
              _interstitialAd = null;
              _interstitialCompleter?.complete(AdShowResult.shownAndDismissed);
              _interstitialCompleter = null;
              _loadInterstitial(); // preload next
            },
            onAdFailedToShowFullScreenContent: (ad, error) {
              ad.dispose();
              _interstitialAd = null;
              _interstitialCompleter?.complete(AdShowResult.failedToShow);
              _interstitialCompleter = null;
              _loadInterstitial();
            },
          );
        },
        onAdFailedToLoad: (error) {
          _isLoadingInterstitial = false;
          _interstitialAd = null;
        },
      ),
    );
  }

  Future<AdShowResult> showInterstitialIfAllowed() async {
    if (!_freq.canShowInterstitial()) {
      if (_freq.isFullScreenAdShowing) return AdShowResult.alreadyShowing;
      if (_freq.isQuizTaking ||
          _freq.isVideoPlaying ||
          _freq.isPaymentFlowActive) {
        return AdShowResult.blockedByScreen;
      }
      return AdShowResult.blockedByFrequency;
    }

    if (_interstitialAd == null) {
      // Try a quick load
      await _loadInterstitial();
      if (_interstitialAd == null) return AdShowResult.notReady;
    }

    _freq.isFullScreenAdShowing = true;
    _interstitialCompleter = Completer<AdShowResult>();

    try {
      await _interstitialAd!.show();
    } catch (e) {
      _interstitialAd?.dispose();
      _interstitialAd = null;
      _freq.isFullScreenAdShowing = false;
      _interstitialCompleter = null;
      _loadInterstitial();
      return AdShowResult.failedToShow;
    }

    _freq.recordInterstitialShown();

    final result = await _interstitialCompleter!.future;
    _freq.isFullScreenAdShowing = false;
    return result;
  }

  // ---- Rewarded ----

  Future<void> _loadRewarded() async {
    if (_isLoadingRewarded || _rewardedAd != null) return;
    _isLoadingRewarded = true;

    await RewardedAd.load(
      adUnitId: AdMobConfig.rewardedAdUnitId,
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (ad) {
          _rewardedAd = ad;
          _isLoadingRewarded = false;

          ad.fullScreenContentCallback = FullScreenContentCallback(
            onAdDismissedFullScreenContent: (ad) {
              ad.dispose();
              _rewardedAd = null;
              _rewardedCompleter?.complete(AdShowResult.dismissedWithoutReward);
              _rewardedCompleter = null;
              _loadRewarded();
            },
            onAdFailedToShowFullScreenContent: (ad, error) {
              ad.dispose();
              _rewardedAd = null;
              _rewardedCompleter?.complete(AdShowResult.failedToShow);
              _rewardedCompleter = null;
              _loadRewarded();
            },
          );
        },
        onAdFailedToLoad: (error) {
          _isLoadingRewarded = false;
          _rewardedAd = null;
        },
      ),
    );
  }

  Future<AdShowResult> showRewarded({
    required Future<void> Function(RewardItem reward) onRewardEarned,
  }) async {
    if (!_freq.canShowRewarded()) {
      if (_freq.isFullScreenAdShowing) return AdShowResult.alreadyShowing;
      return AdShowResult.blockedByFrequency;
    }

    if (_rewardedAd == null) {
      await _loadRewarded();
      if (_rewardedAd == null) return AdShowResult.notReady;
    }

    _freq.isFullScreenAdShowing = true;
    _rewardedCompleter = Completer<AdShowResult>();
    bool rewardEarned = false;

    try {
      await _rewardedAd!.show(
        onUserEarnedReward: (ad, reward) async {
          rewardEarned = true;
          await onRewardEarned(reward);
        },
      );
    } catch (e) {
      _rewardedAd?.dispose();
      _rewardedAd = null;
      _freq.isFullScreenAdShowing = false;
      _rewardedCompleter = null;
      _loadRewarded();
      return AdShowResult.failedToShow;
    }

    _freq.recordRewardedShown();

    if (!_rewardedCompleter!.isCompleted) {
      _rewardedCompleter!.complete(
        rewardEarned ? AdShowResult.rewardEarned : AdShowResult.dismissedWithoutReward,
      );
    }

    final result = await _rewardedCompleter!.future;
    _freq.isFullScreenAdShowing = false;
    return result;
  }

  // ---- Rewarded Interstitial ----

  Future<void> _loadRewardedInterstitial() async {
    if (_isLoadingRewardedInterstitial || _rewardedInterstitialAd != null) {
      return;
    }
    _isLoadingRewardedInterstitial = true;

    await RewardedInterstitialAd.load(
      adUnitId: AdMobConfig.rewardedInterstitialAdUnitId,
      request: const AdRequest(),
      rewardedInterstitialAdLoadCallback: RewardedInterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          _rewardedInterstitialAd = ad;
          _isLoadingRewardedInterstitial = false;

          ad.fullScreenContentCallback = FullScreenContentCallback(
            onAdDismissedFullScreenContent: (ad) {
              ad.dispose();
              _rewardedInterstitialAd = null;
              _rewardedInterstitialCompleter
                  ?.complete(AdShowResult.dismissedWithoutReward);
              _rewardedInterstitialCompleter = null;
              _loadRewardedInterstitial();
            },
            onAdFailedToShowFullScreenContent: (ad, error) {
              ad.dispose();
              _rewardedInterstitialAd = null;
              _rewardedInterstitialCompleter?.complete(AdShowResult.failedToShow);
              _rewardedInterstitialCompleter = null;
              _loadRewardedInterstitial();
            },
          );
        },
        onAdFailedToLoad: (error) {
          _isLoadingRewardedInterstitial = false;
          _rewardedInterstitialAd = null;
        },
      ),
    );
  }

  Future<AdShowResult> showRewardedInterstitial({
    required Future<void> Function(RewardItem reward) onRewardEarned,
  }) async {
    if (!_freq.canShowRewardedInterstitial()) {
      if (_freq.isFullScreenAdShowing) return AdShowResult.alreadyShowing;
      return AdShowResult.blockedByFrequency;
    }

    if (_rewardedInterstitialAd == null) {
      await _loadRewardedInterstitial();
      if (_rewardedInterstitialAd == null) return AdShowResult.notReady;
    }

    _freq.isFullScreenAdShowing = true;
    _rewardedInterstitialCompleter = Completer<AdShowResult>();
    bool rewardEarned = false;

    try {
      await _rewardedInterstitialAd!.show(
        onUserEarnedReward: (ad, reward) async {
          rewardEarned = true;
          await onRewardEarned(reward);
        },
      );
    } catch (e) {
      _rewardedInterstitialAd?.dispose();
      _rewardedInterstitialAd = null;
      _freq.isFullScreenAdShowing = false;
      _rewardedInterstitialCompleter = null;
      _loadRewardedInterstitial();
      return AdShowResult.failedToShow;
    }

    _freq.recordRewardedInterstitialShown();

    if (!_rewardedInterstitialCompleter!.isCompleted) {
      _rewardedInterstitialCompleter!.complete(
        rewardEarned ? AdShowResult.rewardEarned : AdShowResult.dismissedWithoutReward,
      );
    }

    final result = await _rewardedInterstitialCompleter!.future;
    _freq.isFullScreenAdShowing = false;
    return result;
  }
}
