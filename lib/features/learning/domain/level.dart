enum LevelTier {
  rookie,
  explorer,
  riskAwareTrader,
  disciplinedTrader,
}

class Level {
  final LevelTier tier;
  final String title;
  final int minXp;
  final int maxXp;

  const Level({
    required this.tier,
    required this.title,
    required this.minXp,
    required this.maxXp,
  });

  static const List<Level> tiers = [
    Level(
      tier: LevelTier.rookie,
      title: 'Rookie',
      minXp: 0,
      maxXp: 99,
    ),
    Level(
      tier: LevelTier.explorer,
      title: 'Explorer',
      minXp: 100,
      maxXp: 249,
    ),
    Level(
      tier: LevelTier.riskAwareTrader,
      title: 'Risk-Aware Trader',
      minXp: 250,
      maxXp: 429,
    ),
    Level(
      tier: LevelTier.disciplinedTrader,
      title: 'Disciplined Trader',
      minXp: 430,
      maxXp: 999999,
    ),
  ];

  /// Deterministically resolves the user's level tier based on current XP.
  static Level fromXp(int xp) {
    final sanitizedXp = xp < 0 ? 0 : xp;
    for (final level in tiers.reversed) {
      if (sanitizedXp >= level.minXp) {
        return level;
      }
    }
    return tiers.first;
  }

  /// Calculates the progress fraction (0.0 to 1.0) towards the next level tier.
  static double progressToNextLevel(int xp) {
    final sanitizedXp = xp < 0 ? 0 : xp;
    final currentLevel = fromXp(sanitizedXp);
    if (currentLevel.tier == LevelTier.disciplinedTrader) {
      return 1.0;
    }

    final range = currentLevel.maxXp - currentLevel.minXp + 1;
    final gainedInTier = sanitizedXp - currentLevel.minXp;
    return (gainedInTier / range).clamp(0.0, 1.0);
  }

  /// Returns remaining XP needed to reach the next tier (0 if at max tier).
  static int xpToNextLevel(int xp) {
    final sanitizedXp = xp < 0 ? 0 : xp;
    final currentLevel = fromXp(sanitizedXp);
    if (currentLevel.tier == LevelTier.disciplinedTrader) {
      return 0;
    }
    return (currentLevel.maxXp + 1) - sanitizedXp;
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Level &&
          runtimeType == other.runtimeType &&
          tier == other.tier &&
          minXp == other.minXp &&
          maxXp == other.maxXp;

  @override
  int get hashCode => tier.hashCode ^ minXp.hashCode ^ maxXp.hashCode;

  @override
  String toString() =>
      'Level(tier: ${tier.name}, title: $title, minXp: $minXp, maxXp: $maxXp)';
}
