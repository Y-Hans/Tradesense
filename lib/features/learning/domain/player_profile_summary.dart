import 'achievement.dart';
import 'learning_streak.dart';
import 'learning_title.dart';
import 'level.dart';
import 'mission.dart';

class PlayerProfileSummary {
  final int totalXp;
  final Level currentLevel;
  final LearningTitle currentTitle;
  final int currentStreak;
  final String achievementsUnlocked;
  final String missionsCompleted;
  final double completionPercentage;
  final int xpRemainingToNextLevel;

  const PlayerProfileSummary({
    required this.totalXp,
    required this.currentLevel,
    required this.currentTitle,
    required this.currentStreak,
    required this.achievementsUnlocked,
    required this.missionsCompleted,
    required this.completionPercentage,
    required this.xpRemainingToNextLevel,
  });

  /// Factory helper that calculates a [PlayerProfileSummary] from domain objects.
  factory PlayerProfileSummary.calculate({
    required int totalXp,
    required Level currentLevel,
    required LearningTitle currentTitle,
    required LearningStreak streak,
    required List<Achievement> achievements,
    required List<Mission> missions,
    required Set<String> completedMissionIds,
  }) {
    final unlockedAchievementsCount =
        achievements.where((a) => a.isUnlocked).length;
    final totalAchievementsCount = achievements.length;

    final completedMissionsCount = missions
        .where((m) => m.isCompleted || completedMissionIds.contains(m.id))
        .length;
    final totalMissionsCount = missions.length;

    final completionFraction = totalMissionsCount > 0
        ? (completedMissionsCount / totalMissionsCount) * 100.0
        : 0.0;

    final xpRemaining = Level.xpToNextLevel(totalXp);

    return PlayerProfileSummary(
      totalXp: totalXp,
      currentLevel: currentLevel,
      currentTitle: currentTitle,
      currentStreak: streak.getEffectiveStreak(),
      achievementsUnlocked:
          '$unlockedAchievementsCount / $totalAchievementsCount',
      missionsCompleted: '$completedMissionsCount / $totalMissionsCount',
      completionPercentage: completionFraction.clamp(0.0, 100.0),
      xpRemainingToNextLevel: xpRemaining,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PlayerProfileSummary &&
          runtimeType == other.runtimeType &&
          totalXp == other.totalXp &&
          currentLevel == other.currentLevel &&
          currentTitle == other.currentTitle &&
          currentStreak == other.currentStreak &&
          achievementsUnlocked == other.achievementsUnlocked &&
          missionsCompleted == other.missionsCompleted &&
          completionPercentage == other.completionPercentage &&
          xpRemainingToNextLevel == other.xpRemainingToNextLevel;

  @override
  int get hashCode =>
      totalXp.hashCode ^
      currentLevel.hashCode ^
      currentTitle.hashCode ^
      currentStreak.hashCode ^
      achievementsUnlocked.hashCode ^
      missionsCompleted.hashCode ^
      completionPercentage.hashCode ^
      xpRemainingToNextLevel.hashCode;

  @override
  String toString() =>
      'PlayerProfileSummary(totalXp: $totalXp, level: ${currentLevel.title}, title: ${currentTitle.title}, streak: $currentStreak, completion: ${completionPercentage.toStringAsFixed(1)}%)';
}
