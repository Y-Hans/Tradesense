import 'package:cryptoedu/features/learning/domain/learning_streak.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Daily Learning Streak Unit Tests', () {
    test('initial streak is 0', () {
      const streak = LearningStreak();
      expect(streak.currentStreak, equals(0));
      expect(streak.longestStreak, equals(0));
      expect(streak.lastActivityDate, isNull);
    });

    test('first activity initializes streak to 1', () {
      final day1 = DateTime(2026, 7, 20, 10, 0);
      final streak =
          const LearningStreak().registerActivity(activityDate: day1);

      expect(streak.currentStreak, equals(1));
      expect(streak.longestStreak, equals(1));
      expect(streak.lastActivityDate, equals(day1));
    });

    test('consecutive day activity increases streak', () {
      final day1 = DateTime(2026, 7, 20, 10, 0);
      final day2 = DateTime(2026, 7, 21, 14, 30);
      final day3 = DateTime(2026, 7, 22, 9, 15);

      final s1 = const LearningStreak().registerActivity(activityDate: day1);
      final s2 = s1.registerActivity(activityDate: day2);
      final s3 = s2.registerActivity(activityDate: day3);

      expect(s3.currentStreak, equals(3));
      expect(s3.longestStreak, equals(3));
    });

    test('duplicate activity on same calendar day does not increase streak',
        () {
      final day1Time1 = DateTime(2026, 7, 20, 10, 0);
      final day1Time2 = DateTime(2026, 7, 20, 18, 45);

      final s1 =
          const LearningStreak().registerActivity(activityDate: day1Time1);
      final s2 = s1.registerActivity(activityDate: day1Time2);

      expect(s2.currentStreak, equals(1));
      expect(s2.longestStreak, equals(1));
    });

    test(
        'missed calendar day resets current streak to 1 and preserves longest streak',
        () {
      final day1 = DateTime(2026, 7, 20, 10, 0);
      final day2 = DateTime(2026, 7, 21, 10, 0);
      final day3 = DateTime(2026, 7, 22, 10, 0);
      // Skip July 23!
      final day5 = DateTime(2026, 7, 24, 10, 0);

      final s3 = const LearningStreak()
          .registerActivity(activityDate: day1)
          .registerActivity(activityDate: day2)
          .registerActivity(activityDate: day3);

      expect(s3.currentStreak, equals(3));
      expect(s3.longestStreak, equals(3));

      final s5 = s3.registerActivity(activityDate: day5);
      expect(s5.currentStreak, equals(1));
      expect(s5.longestStreak, equals(3));
    });

    test('getEffectiveStreak returns 0 if more than 1 day missed', () {
      final day1 = DateTime(2026, 7, 20, 10, 0);
      final s1 = const LearningStreak().registerActivity(activityDate: day1);

      final checkTwoDaysLater = DateTime(2026, 7, 22, 10, 0);
      expect(s1.getEffectiveStreak(checkDate: checkTwoDaysLater), equals(0));
    });
  });
}
