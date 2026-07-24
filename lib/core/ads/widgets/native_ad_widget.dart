import 'package:ed_tech/core/ads/admob_config.dart';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

/// A widget that displays a Native Ad using a platform-specific factory.
///
/// The native ad is rendered by the platform factory registered with
/// [AdMobConfig.nativeFactoryId]. Each widget instance loads its own
/// NativeAd and disposes it when the widget is removed from the tree.
class NativeAdWidget extends StatefulWidget {
  const NativeAdWidget({
    super.key,
    this.height,
    this.onLoaded,
    this.onFailed,
  });

  /// Optional fixed height for the native ad container.
  /// If not provided, defaults to a reasonable aspect ratio.
  final double? height;

  /// Called when the ad successfully loads.
  final VoidCallback? onLoaded;

  /// Called when the ad fails to load.
  final VoidCallback? onFailed;

  @override
  State<NativeAdWidget> createState() => _NativeAdWidgetState();
}

class _NativeAdWidgetState extends State<NativeAdWidget> {
  NativeAd? _nativeAd;
  bool _isLoaded = false;
  bool _isLoadFailed = false;

  @override
  void initState() {
    super.initState();
    _loadNativeAd();
  }

  void _loadNativeAd() {
    if (!AdMobConfig.adsEnabled || !AdMobConfig.nativeEnabled) return;

    _nativeAd = NativeAd(
      adUnitId: AdMobConfig.nativeAdUnitId,
      factoryId: AdMobConfig.nativeFactoryId,
      request: const AdRequest(),
      listener: NativeAdListener(
        onAdLoaded: (ad) {
          if (!mounted) {
            ad.dispose();
            return;
          }
          setState(() => _isLoaded = true);
          widget.onLoaded?.call();
        },
        onAdFailedToLoad: (ad, error) {
          ad.dispose();
          if (!mounted) return;
          setState(() => _isLoadFailed = true);
          widget.onFailed?.call();
        },
      ),
    );

    _nativeAd!.load();
  }

  @override
  void dispose() {
    _nativeAd?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoadFailed || !_isLoaded || _nativeAd == null) {
      // Collapse to zero size on failure – no blank space
      return const SizedBox.shrink();
    }

    final screenWidth = MediaQuery.of(context).size.width;

    return Container(
      width: screenWidth,
      height: widget.height,
      constraints: const BoxConstraints(
        maxHeight: 400,
        minHeight: 80,
      ),
      child: AdWidget(ad: _nativeAd!),
    );
  }
}
