import 'package:ed_tech/core/ads/chat_ai_quota_manager.dart';
import 'package:ed_tech/core/ads/ad_manager.dart';
import 'package:ed_tech/core/ads/models/ad_show_result.dart';
import 'package:flutter/material.dart';

/// Coordinates Rewarded Interstitial reward flow for Quiz Result screen.
///
/// If the quiz result offers an extra AI question via Rewarded Interstitial,
/// this manager handles the dialog → ad → reward pipeline.
class RewardedInterstitialRewardManager {
  RewardedInterstitialRewardManager._();

  static final RewardedInterstitialRewardManager instance =
      RewardedInterstitialRewardManager._();

  /// Show the intro dialog and (if user accepts) the Rewarded Interstitial ad.
  ///
  /// Returns `true` if the user earned the reward, `false` otherwise.
  Future<bool> showRewardedInterstitialForQuizResult(
    BuildContext context, {
    required String rewardText,
  }) async {
    final accepted = await _showIntroDialog(context, rewardText);
    if (accepted != true) return false;

    final result = await AdManager.instance.showRewardedInterstitial(
      onRewardEarned: (reward) async {
        // Grant +1 AI question
        ChatAiQuotaManager.instance.grantRewardedInterstitialQuestion();
      },
    );

    return result == AdShowResult.rewardEarned;
  }

  Future<bool?> _showIntroDialog(
    BuildContext context,
    String rewardText,
  ) {
    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          title: const Text('Xem quảng cáo để nhận phần thưởng'),
          content: Text(rewardText),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Bỏ qua'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Xem quảng cáo'),
            ),
          ],
        );
      },
    );
  }
}
