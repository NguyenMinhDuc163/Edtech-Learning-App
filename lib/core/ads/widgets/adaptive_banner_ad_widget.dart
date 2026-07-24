import 'package:ed_tech/core/ads/admob_config.dart';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

/// A widget that displays an Anchored Adaptive Banner Ad.
///
/// Shows a placeholder while loading so the ad slot is always visible.
class AdaptiveBannerAdWidget extends StatefulWidget {
  const AdaptiveBannerAdWidget({
    super.key,
    this.showPlaceholder = true,
  });

  /// When true, shows a visible placeholder while the ad loads or fails.
  final bool showPlaceholder;

  @override
  State<AdaptiveBannerAdWidget> createState() =>
      _AdaptiveBannerAdWidgetState();
}

class _AdaptiveBannerAdWidgetState extends State<AdaptiveBannerAdWidget> {
  BannerAd? _bannerAd;
  bool _isLoaded = false;
  bool _isLoading = true;
  AdSize? _adaptiveSize;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_bannerAd == null && !_isLoaded) {
      _loadBanner();
    }
  }

  Future<void> _loadBanner() async {
    if (!AdMobConfig.adsEnabled || !AdMobConfig.bannerEnabled) {
      setState(() => _isLoading = false);
      return;
    }

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
          setState(() {
            _isLoaded = true;
            _isLoading = false;
          });
        },
        onAdFailedToLoad: (ad, error) {
          ad.dispose();
          if (!mounted) return;
          setState(() => _isLoading = false);
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
    if (_isLoaded && _adaptiveSize != null) {
      return SafeArea(
        child: SizedBox(
          width: _adaptiveSize!.width.toDouble(),
          height: _adaptiveSize!.height.toDouble(),
          child: AdWidget(ad: _bannerAd!),
        ),
      );
    }

    if (widget.showPlaceholder) {
      return Container(
        width: MediaQuery.of(context).size.width,
        height: 60,
        margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
        decoration: BoxDecoration(
          color: const Color(0xFFF5F5F5),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: const Color(0xFFE0E0E0)),
        ),
        child: const Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.ad_units, size: 22, color: Color(0xFFFF9800)),
              SizedBox(height: 4),
              Text(
                'Vị trí Banner',
                style: TextStyle(
                  fontSize: 12,
                  color: Color(0xFFFF9800),
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                '(chưa load được)',
                style: TextStyle(fontSize: 10, color: Color(0xFFBDBDBD)),
              ),
            ],
          ),
        ),
      );
    }

    return const SizedBox.shrink();
  }
}
