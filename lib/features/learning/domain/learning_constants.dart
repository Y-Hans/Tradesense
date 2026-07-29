class LearningConstants {
  const LearningConstants._();

  // XP Reward Values
  static const int xpOnboardingCompleted = 50;
  static const int xpLoginCompleted = 30;
  static const int xpViewedMarket = 30;
  static const int xpFirstTradeCompleted = 50;
  static const int xpCompletedLesson = 40;
  static const int xpNewsDetectiveCompleted = 100;

  // Level Thresholds
  static const int xpLevelRookieMin = 0;
  static const int xpLevelRookieMax = 99;
  static const int xpLevelExplorerMin = 100;
  static const int xpLevelExplorerMax = 249;
  static const int xpLevelRiskAwareMin = 250;
  static const int xpLevelRiskAwareMax = 429;
  static const int xpLevelDisciplinedMin = 430;

  // Learning Title Thresholds
  static const int xpTitleCryptoRookie = 0;
  static const int xpTitleMarketExplorer = 100;
  static const int xpTitleRiskAwareTrader = 250;
  static const int xpTitleDisciplinedTrader = 430;
  static const int xpTitleCryptoMentor = 750;

  // Achievement XP Requirements
  static const int xpAchievementLevel5 = 250;
  static const int xpAchievementLevel10 = 1000;

  // Motivational Messages
  static const List<String> motivationalMessages = [
    'Consistency is key to mastering market discipline!',
    'Great work expanding your financial knowledge today!',
    'Every lesson completed sharpens your risk awareness!',
    'Stay disciplined — small daily gains build mastery!',
    'Keep learning and growing your trading mindset!',
  ];

  static String getMotivationalMessage(int streakDays) {
    if (streakDays > 5) {
      return 'Outstanding! $streakDays-day learning streak active!';
    } else if (streakDays > 1) {
      return 'Keep the momentum going! $streakDays days in a row!';
    }
    return motivationalMessages.first;
  }
}
