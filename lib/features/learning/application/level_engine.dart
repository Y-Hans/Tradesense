import '../domain/level.dart';

class LevelEvaluation {
  final Level currentLevel;
  final double progressToNext;
  final int xpToNext;
  final bool didLevelUp;

  const LevelEvaluation({
    required this.currentLevel,
    required this.progressToNext,
    required this.xpToNext,
    required this.didLevelUp,
  });
}

/// Pure calculation engine for Level evaluation based on cumulative XP.
class LevelEngine {
  /// Evaluates level metrics deterministically from total XP.
  static LevelEvaluation evaluateLevel({
    required int previousXp,
    required int currentXp,
  }) {
    final prevLevel = Level.fromXp(previousXp);
    final currLevel = Level.fromXp(currentXp);
    final progress = Level.progressToNextLevel(currentXp);
    final remainingXp = Level.xpToNextLevel(currentXp);
    final leveledUp = currLevel.tier.index > prevLevel.tier.index;

    return LevelEvaluation(
      currentLevel: currLevel,
      progressToNext: progress,
      xpToNext: remainingXp,
      didLevelUp: leveledUp,
    );
  }

  /// Calculates level tier for a given XP count.
  static Level getLevelForXp(int xp) => Level.fromXp(xp);

  /// Calculates progress fraction towards next tier.
  static double getProgress(int xp) => Level.progressToNextLevel(xp);
}
