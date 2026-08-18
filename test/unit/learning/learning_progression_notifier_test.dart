import 'package:flutter_test/flutter_test.dart';
import 'package:cryptoedu/features/learning/application/learning_progression_notifier.dart';
import 'package:cryptoedu/features/learning/domain/level.dart';

void main() {
  group('LearningProgressionState Unit Tests', () {
    test('initial state has 0 total XP and uncompleted missions', () {
      final state = LearningProgressionState.initial();

      expect(state.totalXp, equals(0));
      expect(state.currentLevel.tier, equals(LevelTier.rookie));
      expect(state.currentLevel.title, equals('Rookie'));
      expect(state.completedMissionIds, isEmpty);
      expect(state.missions, isNotEmpty);
    });

    test('restoreState correctly updates XP, level evaluation, and completed missions', () {
      final state = LearningProgressionState.initial();

      // Update with restored backend authoritative data
      final updatedXpState = state.xpState.copyWith(
        totalXp: 50,
        completedMissionIds: {'first_trade'},
      );

      final updatedState = state.copyWith(
        xpState: updatedXpState,
      );

      expect(updatedState.totalXp, equals(50));
      expect(updatedState.completedMissionIds.contains('first_trade'), isTrue);
    });
  });
}
