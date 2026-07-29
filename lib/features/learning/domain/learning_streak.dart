import 'dart:math';

class LearningStreak {
  final int currentStreak;
  final int longestStreak;
  final DateTime? lastActivityDate;

  const LearningStreak({
    this.currentStreak = 0,
    this.longestStreak = 0,
    this.lastActivityDate,
  });

  /// Registers activity and evaluates streak changes deterministically.
  LearningStreak registerActivity({DateTime? activityDate}) {
    final now = activityDate ?? DateTime.now();

    if (lastActivityDate == null) {
      return LearningStreak(
        currentStreak: 1,
        longestStreak: 1,
        lastActivityDate: now,
      );
    }

    final prevDate = DateTime(
      lastActivityDate!.year,
      lastActivityDate!.month,
      lastActivityDate!.day,
    );
    final currDate = DateTime(now.year, now.month, now.day);
    final differenceInDays = currDate.difference(prevDate).inDays;

    if (differenceInDays == 0) {
      // Same day activity: duplicate activity does not increase streak
      return this;
    } else if (differenceInDays == 1) {
      // Consecutive day activity: increases streak
      final newStreak = currentStreak + 1;
      return LearningStreak(
        currentStreak: newStreak,
        longestStreak: max(longestStreak, newStreak),
        lastActivityDate: now,
      );
    } else {
      // Missed one or more days: resets streak to 1 (starting today)
      return LearningStreak(
        currentStreak: 1,
        longestStreak: max(longestStreak, 1),
        lastActivityDate: now,
      );
    }
  }

  /// Calculates effective active streak at a given [checkDate].
  /// If more than 1 calendar day has passed since last activity, current streak is reset to 0.
  int getEffectiveStreak({DateTime? checkDate}) {
    if (lastActivityDate == null) return 0;
    final now = checkDate ?? DateTime.now();

    final prevDate = DateTime(
      lastActivityDate!.year,
      lastActivityDate!.month,
      lastActivityDate!.day,
    );
    final currDate = DateTime(now.year, now.month, now.day);
    final differenceInDays = currDate.difference(prevDate).inDays;

    if (differenceInDays > 1) {
      return 0;
    }
    return currentStreak;
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LearningStreak &&
          runtimeType == other.runtimeType &&
          currentStreak == other.currentStreak &&
          longestStreak == other.longestStreak &&
          lastActivityDate == other.lastActivityDate;

  @override
  int get hashCode =>
      currentStreak.hashCode ^
      longestStreak.hashCode ^
      lastActivityDate.hashCode;

  @override
  String toString() =>
      'LearningStreak(current: $currentStreak, longest: $longestStreak, last: $lastActivityDate)';
}
