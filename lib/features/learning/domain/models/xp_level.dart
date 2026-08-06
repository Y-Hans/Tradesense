export '../level.dart';
import '../level.dart';

/// Legacy alias class pointing to [Level] for compatibility with older UI components.
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

  static List<XpLevel> get tiers => Level.tiers
      .map((l) => XpLevel(
            tier: l.tier,
            title: l.title,
            minXp: l.minXp,
            maxXp: l.maxXp,
          ))
      .toList();

  static XpLevel fromXp(int xp) {
    final level = Level.fromXp(xp);
    return XpLevel(
      tier: level.tier,
      title: level.title,
      minXp: level.minXp,
      maxXp: level.maxXp,
    );
  }

  static double getProgressToNextLevel(int currentXp) {
    return Level.progressToNextLevel(currentXp);
  }
}
