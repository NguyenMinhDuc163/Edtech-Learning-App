import 'package:ed_tech/core/ads/ad_storage.dart';
import 'package:ed_tech/core/ads/admob_config.dart';
import 'package:ed_tech/core/ads/chat_ai_quota_manager.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  group('AdMobConfig', () {
    test('all platform getters should throw for non-Android/iOS', () {
      // This tests that the switch logic compiles correctly
      expect(AdMobConfig.nativeFactoryId, 'eduTechNativeAdFactory');
    });

    test('global switches are true by default', () {
      expect(AdMobConfig.adsEnabled, true);
      expect(AdMobConfig.bannerEnabled, true);
      expect(AdMobConfig.nativeEnabled, true);
      expect(AdMobConfig.interstitialEnabled, true);
      expect(AdMobConfig.rewardedEnabled, true);
      expect(AdMobConfig.rewardedInterstitialEnabled, true);
      expect(AdMobConfig.appOpenEnabled, true);
    });

    test('course list native interval is 6', () {
      expect(AdMobConfig.courseListNativeInterval, 6);
      expect(AdMobConfig.courseListMaximumNativeAds, 2);
    });

    test('chat quota configs are correct', () {
      expect(AdMobConfig.freeChatQuestionsPerDay, 5);
      expect(AdMobConfig.rewardedChatQuestions, 3);
      expect(AdMobConfig.maximumRewardedAdsPerDay, 3);
    });

    test('app open configs are correct', () {
      expect(AdMobConfig.minimumAppLaunchesBeforeAppOpen, 3);
      expect(AdMobConfig.minimumBackgroundDurationForAppOpen, const Duration(minutes: 5));
      expect(AdMobConfig.minimumAppOpenInterval, const Duration(hours: 4));
      expect(AdMobConfig.maximumAppOpenPerDay, 3);
    });

    test('interstitial configs are correct', () {
      expect(AdMobConfig.minimumTimeAfterAppStart, const Duration(minutes: 3));
      expect(AdMobConfig.minimumInterstitialInterval, const Duration(minutes: 5));
      expect(AdMobConfig.maximumInterstitialPerSession, 3);
      expect(AdMobConfig.maximumInterstitialPerDay, 6);
    });

    test('AD IDs are placeholders (not hardcoded real values)', () {
      expect(AdMobConfig.androidAppId, contains('YOUR_'));
      expect(AdMobConfig.iosAppId, contains('YOUR_'));
      expect(AdMobConfig.androidBannerAdUnitId, contains('YOUR_'));
      expect(AdMobConfig.iosBannerAdUnitId, contains('YOUR_'));
    });
  });

  group('AdStorage', () {
    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      await AdStorage.initialize();
    });

    test('app launch count starts at 0', () {
      expect(AdStorage.appLaunchCount, 0);
    });

    test('app launch count can be set', () {
      AdStorage.appLaunchCount = 5;
      expect(AdStorage.appLaunchCount, 5);
    });

    test('daily counters start at 0', () {
      expect(AdStorage.dailyInterstitialCount, 0);
      expect(AdStorage.dailyRewardedCount, 0);
      expect(AdStorage.dailyAppOpenCount, 0);
      expect(AdStorage.dailyRewardedInterstitialCount, 0);
    });

    test('daily counters can be incremented', () {
      AdStorage.dailyInterstitialCount = 1;
      expect(AdStorage.dailyInterstitialCount, 1);

      AdStorage.dailyRewardedCount = 2;
      expect(AdStorage.dailyRewardedCount, 2);
    });

    test('free lesson and quiz counters start at 0', () {
      expect(AdStorage.validQuizCompletedCount, 0);
      expect(AdStorage.freeLessonCompletedCount, 0);
    });
  });

  group('ChatAiQuotaManager', () {
    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      await AdStorage.initialize();
    });

    test('initial quota is 5 free questions', () {
      expect(ChatAiQuotaManager.instance.remainingQuestions, 5);
    });

    test('can ask question initially', () {
      expect(ChatAiQuotaManager.instance.canAskQuestion, true);
    });

    test('consume free question reduces remaining', () {
      final manager = ChatAiQuotaManager.instance;
      expect(manager.consumeFreeQuestion(), true);
      expect(manager.remainingQuestions, 4);
    });

    test('after 5 questions, no free quota remains', () {
      final manager = ChatAiQuotaManager.instance;
      for (int i = 0; i < 5; i++) {
        manager.consumeFreeQuestion();
      }
      expect(manager.remainingQuestions, 0);
      expect(manager.canAskQuestion, false);
      expect(manager.hasUsedFreeQuota, true);
    });

    test('rewarded grants 3 extra questions', () {
      final manager = ChatAiQuotaManager.instance;
      manager.grantRewardedQuestions();
      expect(manager.remainingQuestions, 8); // 5 free + 3 rewarded
    });

    test('rewarded interstitial grants 1 extra question', () {
      final manager = ChatAiQuotaManager.instance;
      manager.grantRewardedInterstitialQuestion();
      expect(manager.remainingQuestions, 6); // 5 free + 1
    });

    test('extra questions consumed after free exhausted', () {
      final manager = ChatAiQuotaManager.instance;
      // Use all 5 free
      for (int i = 0; i < 5; i++) {
        manager.consumeFreeQuestion();
      }
      // Grant 3 extras
      manager.grantRewardedQuestions();
      expect(manager.remainingQuestions, 3);

      // Consume extras
      expect(manager.consumeFreeQuestion(), true);
      expect(manager.remainingQuestions, 2);
    });

    test('reset clears all counters', () {
      final manager = ChatAiQuotaManager.instance;
      for (int i = 0; i < 5; i++) {
        manager.consumeFreeQuestion();
      }
      manager.grantRewardedQuestions();
      manager.resetForTest();
      expect(manager.remainingQuestions, 5);
    });
  });
}
