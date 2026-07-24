import 'dart:async';

import 'package:ed_tech/core/ads/ad_frequency_manager.dart';
import 'package:ed_tech/core/ads/admob_config.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

/// Manages the App Open Ad lifecycle.
///
/// Listens to app lifecycle changes and shows an App Open Ad when the app
/// returns to the foreground, subject to frequency rules.
class AppOpenAdManager {
  AppOpenAdManager._();

  static final AppOpenAdManager instance = AppOpenAdManager._();

  final AdFrequencyManager _freq = AdFrequencyManager.instance;

  AppOpenAd? _appOpenAd;
  DateTime? _loadedAt;
  bool _isLoading = false;

  Completer<void>? _showCompleter;

  /// Preload an App Open Ad. Call after SDK initialization.
  Future<void> preload() async {
    if (_isLoading || _appOpenAd != null) return;
    await _loadAd();
  }

  Future<void> _loadAd() async {
    if (_isLoading) return;
    _isLoading = true;

    await AppOpenAd.load(
      adUnitId: AdMobConfig.appOpenAdUnitId,
      request: const AdRequest(),
      adLoadCallback: AppOpenAdLoadCallback(
        onAdLoaded: (ad) {
          _appOpenAd = ad;
          _loadedAt = DateTime.now();
          _isLoading = false;

          ad.fullScreenContentCallback = FullScreenContentCallback(
            onAdDismissedFullScreenContent: (ad) {
              ad.dispose();
              _appOpenAd = null;
              _loadedAt = null;
              _showCompleter?.complete();
              _showCompleter = null;
              _loadAd(); // preload next
            },
            onAdFailedToShowFullScreenContent: (ad, error) {
              ad.dispose();
              _appOpenAd = null;
              _loadedAt = null;
              _showCompleter?.complete();
              _showCompleter = null;
              _loadAd();
            },
          );
        },
        onAdFailedToLoad: (error) {
          _isLoading = false;
          _appOpenAd = null;
          _loadedAt = null;
        },
      ),
    );
  }

  /// Call when app transitions from paused → resumed.
  Future<void> onResumed() async {
    _freq.onResumed();

    if (!_freq.canShowAppOpen()) return;

    // Check ad age
    if (_loadedAt != null) {
      final age = DateTime.now().difference(_loadedAt!);
      if (age > AdMobConfig.appOpenAdMaximumAge) {
        _appOpenAd?.dispose();
        _appOpenAd = null;
        _loadedAt = null;
        _loadAd();
        return;
      }
    }

    if (_appOpenAd == null) {
      // Not ready – try to load for next time
      _loadAd();
      return;
    }

    _freq.isFullScreenAdShowing = true;
    _showCompleter = Completer<void>();

    try {
      await _appOpenAd!.show();
    } catch (e) {
      _appOpenAd?.dispose();
      _appOpenAd = null;
      _loadedAt = null;
      _freq.isFullScreenAdShowing = false;
      _showCompleter = null;
      _loadAd();
      return;
    }

    _freq.recordAppOpenShown();

    await _showCompleter!.future;
    _freq.isFullScreenAdShowing = false;
  }

  /// Call when app transitions from resumed → paused.
  void onPaused() {
    _freq.onPaused();
  }

  /// Dispose the current ad and stop loading.
  void dispose() {
    _appOpenAd?.dispose();
    _appOpenAd = null;
    _loadedAt = null;
    _isLoading = false;
  }
}
