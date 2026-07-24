import 'package:ed_tech/core/ads/admob_config.dart';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

/// A widget that displays a Native Ad using a platform-specific factory.
///
/// Shows a placeholder while loading so the ad slot is always visible
/// for verification purposes.
class NativeAdWidget extends StatefulWidget {
  const NativeAdWidget({
    super.key,
    this.height,
    this.onLoaded,
    this.onFailed,
    this.showPlaceholder = true,
  });

  final double? height;
  final VoidCallback? onLoaded;
  final VoidCallback? onFailed;

  /// When true, shows a visible placeholder while the ad loads or if it fails.
  /// Set to false for production (collapse on failure).
  final bool showPlaceholder;

  @override
  State<NativeAdWidget> createState() => _NativeAdWidgetState();
}

class _NativeAdWidgetState extends State<NativeAdWidget>
    with AutomaticKeepAliveClientMixin {
  NativeAd? _nativeAd;
  bool _isLoaded = false;
  bool _isLoadFailed = false;
  bool _isLoading = true;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _loadNativeAd();
  }

  Future<void> _loadNativeAd() async {
    if (!AdMobConfig.adsEnabled || !AdMobConfig.nativeEnabled) {
      setState(() {
        _isLoading = false;
        _isLoadFailed = true;
      });
      return;
    }

    _nativeAd?.dispose();
    _nativeAd = null;

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
          setState(() {
            _isLoaded = true;
            _isLoading = false;
          });
          widget.onLoaded?.call();
        },
        onAdFailedToLoad: (ad, error) {
          ad.dispose();
          if (!mounted) return;
          setState(() {
            _isLoadFailed = true;
            _isLoading = false;
          });
          widget.onFailed?.call();
        },
      ),
    );

    _nativeAd!.load();
  }

  @override
  void dispose() {
    _nativeAd?.dispose();
    _nativeAd = null;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    // If loaded successfully, show real ad
    if (_isLoaded && _nativeAd != null) {
      return Container(
        width: MediaQuery.of(context).size.width,
        height: widget.height,
        constraints: const BoxConstraints(
          maxHeight: 400,
          minHeight: 80,
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: AdWidget(ad: _nativeAd!),
        ),
      );
    }

    // Show placeholder while loading or on failure
    if (widget.showPlaceholder) {
      return Container(
        width: MediaQuery.of(context).size.width,
        height: widget.height ?? 100,
        margin: const EdgeInsets.symmetric(vertical: 4),
        decoration: BoxDecoration(
          color: const Color(0xFFF5F5F5),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: const Color(0xFFE0E0E0),
            width: 1,
          ),
        ),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                _isLoading ? Icons.hourglass_empty : Icons.ad_units,
                size: 28,
                color: _isLoading
                    ? const Color(0xFF9E9E9E)
                    : const Color(0xFFFF9800),
              ),
              const SizedBox(height: 6),
              Text(
                _isLoading ? 'Đang tải quảng cáo...' : 'Vị trí quảng cáo',
                style: TextStyle(
                  fontSize: 13,
                  color: _isLoading
                      ? const Color(0xFF9E9E9E)
                      : const Color(0xFFFF9800),
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                _isLoading ? 'Native Ad' : '(Native Ad - chưa load được)',
                style: const TextStyle(
                  fontSize: 10,
                  color: Color(0xFFBDBDBD),
                ),
              ),
            ],
          ),
        ),
      );
    }

    // Collapse on failure (production mode)
    return const SizedBox.shrink();
  }
}
