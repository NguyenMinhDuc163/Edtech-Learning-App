import 'dart:io';

abstract final class AdMobConfig {
  AdMobConfig._();

  // =========================================================
  // GLOBAL SWITCHES
  // =========================================================

  static const bool adsEnabled = true;

  static const bool bannerEnabled = true;
  static const bool nativeEnabled = true;
  static const bool interstitialEnabled = true;
  static const bool rewardedEnabled = true;
  static const bool rewardedInterstitialEnabled = true;
  static const bool appOpenEnabled = true;

  // =========================================================
  // ADMOB APP IDS - PRODUCTION
  // =========================================================

  static const String androidAppId =
      'ca-app-pub-4649011658078977~5899784818';

  static const String iosAppId =
      'ca-app-pub-4649011658078977~3080225959';

  // =========================================================
  // ANDROID PRODUCTION AD UNIT IDS
  // =========================================================

  static const String androidBannerAdUnitId =
      'ca-app-pub-4649011658078977/1486433484';

  static const String androidNativeAdUnitId =
      'ca-app-pub-4649011658078977/4819173836';

  static const String androidInterstitialAdUnitId =
      'ca-app-pub-4649011658078977/1498755786';

  static const String androidRewardedAdUnitId =
      'ca-app-pub-4649011658078977/5110697730';

  static const String androidRewardedInterstitialAdUnitId =
      'ca-app-pub-4649011658078977/9285032454';

  static const String androidAppOpenAdUnitId =
      'ca-app-pub-4649011658078977/6060103314';

  // =========================================================
  // IOS PRODUCTION AD UNIT IDS
  // =========================================================

  static const String iosBannerAdUnitId =
      'ca-app-pub-4649011658078977/6379667511';

  static const String iosNativeAdUnitId =
      'ca-app-pub-4649011658078977/2484534397';

  static const String iosInterstitialAdUnitId =
      'ca-app-pub-4649011658078977/6467297425';

  static const String iosRewardedAdUnitId =
      'ca-app-pub-4649011658078977/1171452724';

  static const String iosRewardedInterstitialAdUnitId =
      'ca-app-pub-4649011658078977/2416371779';

  static const String iosAppOpenAdUnitId =
      'ca-app-pub-4649011658078977/7904382033';

  // =========================================================
  // NATIVE FACTORY
  // =========================================================

  static const String nativeFactoryId = 'eduTechNativeAdFactory';

  // =========================================================
  // INTERSTITIAL RULES
  // =========================================================

  static const Duration minimumTimeAfterAppStart =
      Duration(minutes: 3);

  static const Duration minimumInterstitialInterval =
      Duration(minutes: 5);

  static const int maximumInterstitialPerSession = 3;

  static const int maximumInterstitialPerDay = 6;

  static const int quizCompletedInterstitialInterval = 2;

  static const int lessonCompletedInterstitialInterval = 3;

  static const Duration minimumQuizDuration =
      Duration(minutes: 2);

  // =========================================================
  // APP OPEN RULES
  // =========================================================

  static const int minimumAppLaunchesBeforeAppOpen = 3;

  static const Duration minimumBackgroundDurationForAppOpen =
      Duration(minutes: 5);

  static const Duration minimumAppOpenInterval =
      Duration(hours: 4);

  static const int maximumAppOpenPerDay = 3;

  static const Duration appOpenAdMaximumAge =
      Duration(hours: 4);

  // =========================================================
  // REWARDED CHAT RULES
  // =========================================================

  static const int freeChatQuestionsPerDay = 5;

  static const int rewardedChatQuestions = 3;

  static const int maximumRewardedAdsPerDay = 3;

  // =========================================================
  // REWARDED INTERSTITIAL RULES
  // =========================================================

  static const int rewardedInterstitialExtraChatQuestions = 1;

  static const int maximumRewardedInterstitialPerDay = 2;

  static const Duration minimumRewardedInterstitialInterval =
      Duration(minutes: 10);

  // =========================================================
  // NATIVE LIST RULES
  // =========================================================

  static const int courseListNativeInterval = 3;

  static const int courseListMaximumNativeAds = 1;

  static const int searchNativePosition = 3;

  static const int filterNativePosition = 3;

  static const int quizListNativePosition = 3;

  static const int leaderboardNativePosition = 5;

  // =========================================================
  // PLATFORM HELPERS
  // =========================================================

  static String get bannerAdUnitId {
    if (Platform.isAndroid) return androidBannerAdUnitId;
    if (Platform.isIOS) return iosBannerAdUnitId;

    throw UnsupportedError(
      'AdMob only supports Android and iOS',
    );
  }

  static String get nativeAdUnitId {
    if (Platform.isAndroid) return androidNativeAdUnitId;
    if (Platform.isIOS) return iosNativeAdUnitId;

    throw UnsupportedError(
      'AdMob only supports Android and iOS',
    );
  }

  static String get interstitialAdUnitId {
    if (Platform.isAndroid) {
      return androidInterstitialAdUnitId;
    }

    if (Platform.isIOS) {
      return iosInterstitialAdUnitId;
    }

    throw UnsupportedError(
      'AdMob only supports Android and iOS',
    );
  }

  static String get rewardedAdUnitId {
    if (Platform.isAndroid) {
      return androidRewardedAdUnitId;
    }

    if (Platform.isIOS) {
      return iosRewardedAdUnitId;
    }

    throw UnsupportedError(
      'AdMob only supports Android and iOS',
    );
  }

  static String get rewardedInterstitialAdUnitId {
    if (Platform.isAndroid) {
      return androidRewardedInterstitialAdUnitId;
    }

    if (Platform.isIOS) {
      return iosRewardedInterstitialAdUnitId;
    }

    throw UnsupportedError(
      'AdMob only supports Android and iOS',
    );
  }

  static String get appOpenAdUnitId {
    if (Platform.isAndroid) {
      return androidAppOpenAdUnitId;
    }

    if (Platform.isIOS) {
      return iosAppOpenAdUnitId;
    }

    throw UnsupportedError(
      'AdMob only supports Android and iOS',
    );
  }
}
