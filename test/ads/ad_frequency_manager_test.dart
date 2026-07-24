import 'package:ed_tech/core/ads/ad_frequency_manager.dart';
import 'package:ed_tech/core/ads/ad_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  group('AdFrequencyManager', () {
    late AdFrequencyManager fm;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      await AdStorage.initialize();
      fm = AdFrequencyManager.instance;
      fm.resetForTest();
      // Reset daily counters
      AdStorage.dailyInterstitialCount = 0;
      AdStorage.dailyRewardedCount = 0;
      AdStorage.dailyRewardedInterstitialCount = 0;
      AdStorage.dailyAppOpenCount = 0;
      AdStorage.appLaunchCount = 0;
    });

    group('Interstitial', () {
      test('cannot show interstitial within 3 minutes of app start', () {
        // appStartedAt is set to DateTime.now() at construction time
        // so interstitial should always be blocked initially
        expect(fm.canShowInterstitial(), false);
      });

      test('cannot show interstitial when quiz is taking', () {
        fm.isQuizTaking = true;
        expect(fm.canShowInterstitial(), false);
      });

      test('cannot show interstitial when video is playing', () {
        fm.isVideoPlaying = true;
        expect(fm.canShowInterstitial(), false);
      });

      test('cannot show interstitial when payment flow is active', () {
        fm.isPaymentFlowActive = true;
        expect(fm.canShowInterstitial(), false);
      });

      test('cannot show interstitial when another fullscreen ad is showing', () {
        fm.isFullScreenAdShowing = true;
        expect(fm.canShowInterstitial(), false);
      });

      test('session interstitial count increments', () {
        expect(fm.sessionInterstitialCount, 0);
        fm.recordInterstitialShown();
        expect(fm.sessionInterstitialCount, 1);
        expect(fm.lastInterstitialAt, isNotNull);
      });

      test('daily interstitial count is recorded in storage', () {
        expect(AdStorage.dailyInterstitialCount, 0);
        fm.recordInterstitialShown();
        expect(AdStorage.dailyInterstitialCount, 1);
      });

      test('cannot exceed daily interstitial cap', () {
        AdStorage.dailyInterstitialCount = 6; // max is also 6
        expect(fm.canShowInterstitial(), false);
      });
    });

    group('Rewarded', () {
      test('can show rewarded when not blocked', () {
        // Rewarded has fewer restrictions - should pass daily cap only
        expect(fm.canShowRewarded(), true);
      });

      test('cannot show rewarded when another full-screen ad is showing', () {
        fm.isFullScreenAdShowing = true;
        expect(fm.canShowRewarded(), false);
      });

      test('daily rewarded count increments', () {
        expect(AdStorage.dailyRewardedCount, 0);
        fm.recordRewardedShown();
        expect(AdStorage.dailyRewardedCount, 1);
      });
    });

    group('Rewarded Interstitial', () {
      test('cannot show when quiz is taking', () {
        fm.isQuizTaking = true;
        expect(fm.canShowRewardedInterstitial(), false);
      });

      test('cannot show when full-screen ad is showing', () {
        fm.isFullScreenAdShowing = true;
        expect(fm.canShowRewardedInterstitial(), false);
      });

      test('daily rewarded interstitial count increments', () {
        expect(AdStorage.dailyRewardedInterstitialCount, 0);
        fm.recordRewardedInterstitialShown();
        expect(AdStorage.dailyRewardedInterstitialCount, 1);
      });
    });

    group('App Open', () {
      test('cannot show before minimum app launches', () {
        AdStorage.appLaunchCount = 0;
        expect(fm.canShowAppOpen(), false);
      });

      test('cannot show when quiz is taking', () {
        AdStorage.appLaunchCount = 5; // enough launches
        fm.isQuizTaking = true;
        expect(fm.canShowAppOpen(), false);
      });

      test('cannot show when video is playing', () {
        AdStorage.appLaunchCount = 5;
        fm.isVideoPlaying = true;
        expect(fm.canShowAppOpen(), false);
      });

      test('cannot show when payment flow is active', () {
        AdStorage.appLaunchCount = 5;
        fm.isPaymentFlowActive = true;
        expect(fm.canShowAppOpen(), false);
      });

      test('cannot show when full-screen ad is showing', () {
        AdStorage.appLaunchCount = 5;
        fm.isFullScreenAdShowing = true;
        expect(fm.canShowAppOpen(), false);
      });

      test('daily app open count increments', () {
        AdStorage.dailyAppOpenCount = 0;
        fm.recordAppOpenShown();
        expect(AdStorage.dailyAppOpenCount, 1);
      });
    });

    group('Concurrent fullscreen ad', () {
      test('only one full-screen ad can show at a time', () {
        fm.isFullScreenAdShowing = true;
        expect(fm.canShowInterstitial(), false);
        expect(fm.canShowRewarded(), false);
        expect(fm.canShowRewardedInterstitial(), false);
        expect(fm.canShowAppOpen(), false);
      });
    });
  });
}
