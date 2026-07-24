import 'package:ed_tech/core/ads/ad_storage.dart';
import 'package:ed_tech/core/ads/admob_config.dart';

/// Manages the daily Chat AI question quota.
///
/// Rules:
/// - 5 free questions per day
/// - Rewarded Ad grants +3 questions (max 3 rewarded/day)
/// - Rewarded Interstitial from Quiz Result grants +1 question (max 2/day)
///
/// Local storage provides UX convenience. Backend must be the source of truth
/// for cost-significant AI usage.
class ChatAiQuotaManager {
  ChatAiQuotaManager._();

  static final ChatAiQuotaManager instance = ChatAiQuotaManager._();

  // ---- Quota checks ----

  /// Returns the number of remaining questions the user can ask right now.
  int get remainingQuestions {
    final free = AdMobConfig.freeChatQuestionsPerDay -
        AdStorage.dailyFreeChatUsed;
    final extra = AdStorage.dailyRewardedChatExtra;
    return (free + extra).clamp(0, 999);
  }

  /// Whether the user has any remaining quota.
  bool get canAskQuestion => remainingQuestions > 0;

  /// Whether the user has used all free questions (eligible for rewarded).
  bool get hasUsedFreeQuota =>
      AdStorage.dailyFreeChatUsed >=
      AdMobConfig.freeChatQuestionsPerDay;

  /// Whether the user can watch a Rewarded Ad for more questions.
  bool get canWatchRewardedForQuestions {
    return AdStorage.dailyRewardedCount <
        AdMobConfig.maximumRewardedAdsPerDay;
  }

  /// Whether the user can earn questions from Rewarded Interstitial.
  bool get canEarnFromRewardedInterstitial {
    return AdStorage.dailyRewardedInterstitialCount <
        AdMobConfig.maximumRewardedInterstitialPerDay;
  }

  // ---- Consumption ----

  /// Consume one free question. Returns false if no free quota remains.
  bool consumeFreeQuestion() {
    if (AdStorage.dailyFreeChatUsed >=
        AdMobConfig.freeChatQuestionsPerDay) {
      if (AdStorage.dailyRewardedChatExtra > 0) {
        AdStorage.dailyRewardedChatExtra--;
        return true;
      }
      return false;
    }
    AdStorage.dailyFreeChatUsed++;
    return true;
  }

  // ---- Rewards ----

  /// Grant extra questions from a successful Rewarded Ad watch.
  void grantRewardedQuestions() {
    AdStorage.dailyRewardedChatExtra +=
        AdMobConfig.rewardedChatQuestions;
  }

  /// Grant extra questions from a successful Rewarded Interstitial watch.
  void grantRewardedInterstitialQuestion() {
    AdStorage.dailyRewardedChatExtra +=
        AdMobConfig.rewardedInterstitialExtraChatQuestions;
  }

  // ---- Reset for testing ----

  void resetForTest() {
    AdStorage.dailyFreeChatUsed = 0;
    AdStorage.dailyRewardedChatExtra = 0;
  }
}
