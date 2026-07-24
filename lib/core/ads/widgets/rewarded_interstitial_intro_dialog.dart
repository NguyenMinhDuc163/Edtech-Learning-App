import 'package:flutter/material.dart';

/// An intro dialog shown before a Rewarded Interstitial ad.
///
/// Requires explicit user action before the ad can be shown.
/// The "Bỏ qua" (skip) button is clearly visible and easy to tap.
class RewardedInterstitialIntroDialog extends StatelessWidget {
  const RewardedInterstitialIntroDialog({
    super.key,
    required this.title,
    required this.description,
    required this.rewardText,
    required this.onContinue,
    this.onSkip,
  });

  final String title;
  final String description;
  final String rewardText;
  final VoidCallback onContinue;
  final VoidCallback? onSkip;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(title),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(description),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primaryContainer,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.card_giftcard,
                  color: Theme.of(context).colorScheme.onPrimaryContainer,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    rewardText,
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: Theme.of(context).colorScheme.onPrimaryContainer,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () {
            onSkip?.call();
            Navigator.of(context).pop();
          },
          child: const Text('Bỏ qua'),
        ),
        FilledButton(
          onPressed: () {
            Navigator.of(context).pop();
            onContinue();
          },
          child: const Text('Xem quảng cáo'),
        ),
      ],
    );
  }

  /// Convenience method to show this dialog.
  static Future<bool?> show(
    BuildContext context, {
    required String title,
    required String description,
    required String rewardText,
    required VoidCallback onContinue,
    VoidCallback? onSkip,
  }) {
    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => RewardedInterstitialIntroDialog(
        title: title,
        description: description,
        rewardText: rewardText,
        onContinue: onContinue,
        onSkip: onSkip,
      ),
    );
  }
}
