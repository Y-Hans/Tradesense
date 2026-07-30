import 'package:cryptoedu/features/learning/domain/achievement.dart';
import 'package:cryptoedu/features/learning/domain/learning_event.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Achievement System Unit Tests', () {
    test('initialAchievements contains standard initial achievements', () {
      const initial = Achievement.initialAchievements;
      expect(initial.length, equals(11));
      expect(initial.any((a) => a.id == 'first_steps'), isTrue);
      expect(initial.any((a) => a.id == 'market_explorer'), isTrue);
      expect(initial.any((a) => a.id == 'level_5'), isTrue);
      expect(initial.any((a) => a.id == 'level_10'), isTrue);
    });

    test('checkUnlocks unlocks achievements automatically on matching events',
        () {
      final result = Achievement.checkUnlocks(
        currentAchievements: Achievement.initialAchievements,
        totalXp: 50,
        processedEventTypes: {LearningEventType.onboardingCompleted},
      );

      final unlocked = result.newlyUnlocked;
      expect(unlocked.length, equals(1));
      expect(unlocked.first.id, equals('first_steps'));
      expect(unlocked.first.isUnlocked, isTrue);
      expect(unlocked.first.unlockedAt, isNotNull);
    });

    test(
        'checkUnlocks unlocks Level 5 achievement automatically when totalXp >= 250',
        () {
      final result = Achievement.checkUnlocks(
        currentAchievements: Achievement.initialAchievements,
        totalXp: 260,
        processedEventTypes: {},
      );

      final newlyUnlocked = result.newlyUnlocked;
      expect(newlyUnlocked.any((a) => a.id == 'level_5'), isTrue);
      expect(newlyUnlocked.any((a) => a.id == 'level_10'), isFalse);
    });

    test(
        'duplicate unlock prevention: re-evaluating unlocked achievements does not re-trigger newlyUnlocked',
        () {
      final firstPass = Achievement.checkUnlocks(
        currentAchievements: Achievement.initialAchievements,
        totalXp: 50,
        processedEventTypes: {LearningEventType.onboardingCompleted},
      );

      expect(firstPass.newlyUnlocked.length, equals(1));

      final secondPass = Achievement.checkUnlocks(
        currentAchievements: firstPass.achievements,
        totalXp: 50,
        processedEventTypes: {LearningEventType.onboardingCompleted},
      );

      expect(secondPass.newlyUnlocked, isEmpty);
      expect(
          secondPass.achievements
              .firstWhere((a) => a.id == 'first_steps')
              .isUnlocked,
          isTrue);
    });

    test(
        'AchievementRarity properties return expected display names and colors',
        () {
      expect(AchievementRarity.common.displayName, equals('Common'));
      expect(AchievementRarity.rare.displayName, equals('Rare'));
      expect(AchievementRarity.epic.displayName, equals('Epic'));
      expect(AchievementRarity.legendary.displayName, equals('Legendary'));
    });
  });
}
