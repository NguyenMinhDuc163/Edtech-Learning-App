import 'package:ed_tech/core/ads/widgets/native_ad_widget.dart';
import 'package:flutter/material.dart';

/// Helper that inserts [NativeAdWidget] into a list of items at the given
/// positions, after the original item at that index.
///
/// Example:
/// ```dart
/// // nativeAdAt: {5: 1, 11: 2} means insert after idx 5 and after idx 11
/// final items = [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13];
/// final withAds = AdListHelper.insertNativeAds(
///   items: items,
///   itemBuilder: (item, context) => ListTile(title: Text('$item')),
///   nativeAdHeight: 100.0,
///   nativeAdPositions: const {5, 11},
/// );
/// ```
///
/// Builds [int] as value for position map to allow unique keys.
class AdListHelper {
  AdListHelper._();

  /// Total item count (real items + ad widgets).
  static int totalCount({
    required int itemCount,
    required Set<int> nativeAdPositions,
    required int maxNativeAds,
  }) {
    int adsInserted = 0;
    for (int pos in nativeAdPositions) {
      if (adsInserted >= maxNativeAds) break;
      if (pos < itemCount) adsInserted++;
    }
    return itemCount + adsInserted;
  }

  /// Returns true if the widget at [index] should be a native ad.
  static bool isNativeAdAtIndex({
    required int index,
    required int itemCount,
    required Set<int> nativeAdPositions,
    required int maxNativeAds,
  }) {
    int adsBefore = 0;
    int adCount = 0;
    for (int i = 0; i <= index; i++) {
      // Check if we should insert an ad after position (i - adsBefore - 1)
      final itemIdx = i - adsBefore - 1;
      if (itemIdx >= 0 && nativeAdPositions.contains(itemIdx) && adCount < maxNativeAds) {
        if (i == itemIdx + adsBefore + 1) {
          // This slot is not the ad slot — it's the item itself
          continue;
        }
        adsBefore++;
        adCount++;
        if (index == i) return true;
        // After inserting an ad, the remaining indices shift
      }
    }
    return false;
  }

  /// Build list widgets with native ads interspersed.
  static List<Widget> buildListWithAds({
    required int itemCount,
    required Widget Function(int itemIndex, BuildContext context) itemBuilder,
    required BuildContext context,
    required double? nativeAdHeight,
    required Set<int> nativeAdPositions,
    required int maxNativeAds,
    bool Function()? isPurchased,
  }) {
    // Don't show ads to purchased users
    if (isPurchased != null && isPurchased()) {
      return List.generate(
        itemCount,
        (i) => itemBuilder(i, context),
      );
    }

    if (itemCount < nativeAdPositions.first + 1) {
      return List.generate(
        itemCount,
        (i) => itemBuilder(i, context),
      );
    }

    final widgets = <Widget>[];
    int adCount = 0;

    for (int i = 0; i < itemCount; i++) {
      widgets.add(itemBuilder(i, context));

      if (adCount < maxNativeAds && nativeAdPositions.contains(i)) {
        widgets.add(
          NativeAdWidget(
            key: ValueKey('native_ad_$i'),
            height: nativeAdHeight,
          ),
        );
        adCount++;
      }
    }

    return widgets;
  }
}
