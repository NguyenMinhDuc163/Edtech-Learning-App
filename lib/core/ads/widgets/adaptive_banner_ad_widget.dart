import 'package:ed_tech/core/ads/admob_config.dart';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

/// A widget that displays an Anchored Adaptive Banner Ad.
///
/// Automatically sizes the banner to match the device width.
/// If the ad fails to load, the widget collapses to zero height
/// (no empty space is shown).
class AdaptiveBannerAdWidget extends StatefulWidget {
  const AdaptiveBannerAdWidget({super.key});

  @override
  State<AdaptiveBannerAdWidget> createState() =>
      _AdaptiveBannerAdWidgetState();
}

class _AdaptiveBannerAdWidgetState extends State<AdaptiveBannerAdWidget> {
  BannerAd? _bannerAd;
  bool _isLoaded = false;
  bool _isLoadFailed = false;
  AdSize? _adaptiveSize;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_bannerAd == null && !_isLoadFailed) {
      _loadBanner();
    }
  }

  Future<void> _loadBanner() async {
    if (!AdMobConfig.adsEnabled || !AdMobConfig.bannerEnabled) return;

    final size =
        await AdSize.getCurrentOrientationAnchoredAdaptiveBannerAdSize(
      MediaQuery.of(context).size.width.truncate(),
    );

    if (size == null || !mounted) return;
    _adaptiveSize = size;

    _bannerAd = BannerAd(
      adUnitId: AdMobConfig.bannerAdUnitId,
      size: size,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (ad) {
          if (!mounted) {
            ad.dispose();
            return;
          }
          setState(() => _isLoaded = true);
        },
        onAdFailedToLoad: (ad, error) {
          ad.dispose();
          if (!mounted) return;
          setState(() => _isLoadFailed = true);
        },
      ),
    );

    _bannerAd!.load();
  }

  @override
  void dispose() {
    _bannerAd?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_isLoaded || _adaptiveSize == null) return const SizedBox.shrink();

    return SafeArea(
      child: SizedBox(
        width: _adaptiveSize!.width.toDouble(),
        height: _adaptiveSize!.height.toDouble(),
        child: AdWidget(ad: _bannerAd!),
      ),
    );
  }
}
