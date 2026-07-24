import 'package:shared_preferences/shared_preferences.dart';

/// Persists ad frequency state across app sessions using SharedPreferences.
///
/// All daily counters are keyed by date so they naturally reset.
class AdStorage {
  AdStorage._();

  static SharedPreferences? _prefs;

  static Future<void> initialize() async {
    _prefs = await SharedPreferences.getInstance();
  }

  static SharedPreferences get _p {
    assert(_prefs != null, 'AdStorage.initialize() must be called first');
    return _prefs!;
  }

  static String get _todayKey {
    final now = DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
  }

  // ---- App Launches ----

  static int get appLaunchCount => _p.getInt('ad_app_launch_count') ?? 0;

  static set appLaunchCount(int value) =>
      _p.setInt('ad_app_launch_count', value);

  // ---- Daily Counters (reset by date key) ----

  static int get dailyInterstitialCount =>
      _p.getInt('ad_daily_interstitial_$_todayKey') ?? 0;

  static set dailyInterstitialCount(int value) =>
      _p.setInt('ad_daily_interstitial_$_todayKey', value);

  static int get dailyRewardedCount =>
      _p.getInt('ad_daily_rewarded_$_todayKey') ?? 0;

  static set dailyRewardedCount(int value) =>
      _p.setInt('ad_daily_rewarded_$_todayKey', value);

  static int get dailyRewardedInterstitialCount =>
      _p.getInt('ad_daily_rw_interstitial_$_todayKey') ?? 0;

  static set dailyRewardedInterstitialCount(int value) =>
      _p.setInt('ad_daily_rw_interstitial_$_todayKey', value);

  static int get dailyAppOpenCount =>
      _p.getInt('ad_daily_app_open_$_todayKey') ?? 0;

  static set dailyAppOpenCount(int value) =>
      _p.setInt('ad_daily_app_open_$_todayKey', value);

  // ---- Chat quota (separate from ad frequency) ----

  static int get dailyFreeChatUsed =>
      _p.getInt('ad_chat_free_used_$_todayKey') ?? 0;

  static set dailyFreeChatUsed(int value) =>
      _p.setInt('ad_chat_free_used_$_todayKey', value);

  static int get dailyRewardedChatExtra =>
      _p.getInt('ad_chat_rewarded_extra_$_todayKey') ?? 0;

  static set dailyRewardedChatExtra(int value) =>
      _p.setInt('ad_chat_rewarded_extra_$_todayKey', value);

  // ---- Quiz / Lesson counters ----

  static int get validQuizCompletedCount =>
      _p.getInt('ad_valid_quiz_count') ?? 0;

  static set validQuizCompletedCount(int value) =>
      _p.setInt('ad_valid_quiz_count', value);

  static int get freeLessonCompletedCount =>
      _p.getInt('ad_free_lesson_count') ?? 0;

  static set freeLessonCompletedCount(int value) =>
      _p.setInt('ad_free_lesson_count', value);
}
