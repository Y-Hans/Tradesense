import 'package:flutter_test/flutter_test.dart';
import 'package:cryptoedu/features/learning/application/level_engine.dart';
import 'package:cryptoedu/features/learning/application/mission_engine.dart';
import 'package:cryptoedu/features/learning/application/xp_engine.dart';
import 'package:cryptoedu/features/learning/domain/learning_event.dart';
import 'package:cryptoedu/features/learning/domain/level.dart';
import 'package:cryptoedu/features/learning/domain/mission.dart';
import 'package:cryptoedu/features/learning/domain/xp_state.dart';

void main() {
  test('XP awards are fixed by the mission, not trade profit metadata', () {
    final event = LearningEvent.firstTradeCompleted(
      eventId: 'trade-event',
      metadata: {'profitInr': 999999.0},
    );
    const mission = Mission(
      id: 'm4_first_trade',
      title: 'First Virtual Trade',
      description: 'Execute a first trade',
      xpReward: 50,
      eventType: LearningEventType.firstTradeCompleted,
    );

    final award = XpEngine.calculateXpAward(
      event: event,
      mission: mission,
      currentXpState: const XpState(),
    );

    expect(award.xpAwarded, 50);
  });

  test('mission processing is idempotent for the same event', () {
    final event = LearningEvent.loginCompleted(eventId: 'login-event');
    final first = MissionEngine.processEvent(
      event: event,
      missions: Mission.initialMissions,
      xpState: const XpState(),
    );
    final second = MissionEngine.processEvent(
      event: event,
      missions: first.updatedMissions,
      xpState: first.updatedXpState,
    );

    expect(first.totalXpGained, greaterThan(0));
    expect(second.isIdempotentSkip, isTrue);
    expect(second.totalXpGained, 0);
  });

  test('level thresholds remain deterministic at the boundary', () {
    expect(LevelEngine.evaluateLevel(previousXp: 99, currentXp: 100).didLevelUp,
        isTrue);
    expect(Level.fromXp(100).tier, LevelTier.explorer);
  });
}
