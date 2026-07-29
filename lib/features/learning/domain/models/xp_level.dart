enum LevelTier { rookie, explorer, riskAwareTrader, disciplinedTrader }

class XpLevel {
  final LevelTier tier;
  final String title;
  final int minXp;
  final int maxXp;

  const XpLevel({
    required this.tier,
    required this.title,
    required this.minXp,
    required this.maxXp,
  });

  static const List<XpLevel> tiers = [
    XpLevel(
      tier: LevelTier.rookie,
      title: 'Rookie',
      minXp: 0,
      maxXp: 99,
    ),
    XpLevel(
      tier: LevelTier.explorer,
      title: 'Explorer',
      minXp: 100,
      maxXp: 249,
    ),
    XpLevel(
      tier: LevelTier.riskAwareTrader,
      title: 'Risk-Aware Trader',
      minXp: 250,
      maxXp: 429,
    ),
    XpLevel(
      tier: LevelTier.disciplinedTrader,
      title: 'Disciplined Trader',
      minXp: 430,
      maxXp: 999999,
    ),
  ];

  static XpLevel fromXp(int xp) {
    for (final level in tiers.reversed) {
      if (xp >= level.minXp) {
        return level;
      }
    }
    return tiers.first;
  }

  static double getProgressToNextLevel(int currentXp) {
    final currentLevel = fromXp(currentXp);
    if (currentLevel.tier == LevelTier.disciplinedTrader) return 1.0;

    final range = currentLevel.maxXp - currentLevel.minXp + 1;
    final gainedInTier = currentXp - currentLevel.minXp;
    return (gainedInTier / range).clamp(0.0, 1.0);
  }
}
