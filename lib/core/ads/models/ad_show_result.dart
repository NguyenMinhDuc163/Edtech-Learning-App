/// Result of attempting to show a full-screen ad.
enum AdShowResult {
  /// The ad was shown and the user dismissed it (or it completed).
  shownAndDismissed,

  /// The ad was not ready to be shown (preload failed or not yet loaded).
  notReady,

  /// The ad was blocked by frequency rules (cooldown, daily cap, etc.).
  blockedByFrequency,

  /// The ad was blocked because the current screen prohibits it.
  blockedByScreen,

  /// Another full-screen ad is already showing.
  alreadyShowing,

  /// For rewarded/rewarded interstitial: the user earned the reward.
  rewardEarned,

  /// For rewarded/rewarded interstitial: the user dismissed without earning.
  dismissedWithoutReward,

  /// The ad failed to show (SDK error).
  failedToShow,
}
