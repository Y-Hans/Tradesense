import '../domain/learning_event.dart';
import '../domain/mission.dart';
import '../domain/xp_state.dart';

class XpAwardResult {
  final int xpAwarded;
  final bool isDuplicate;
  final String reason;

  const XpAwardResult({
    required this.xpAwarded,
    required this.isDuplicate,
    required this.reason,
  });

  const XpAwardResult.zeroDuplicate(this.reason)
      : xpAwarded = 0,
        isDuplicate = true;

  const XpAwardResult.success(this.xpAwarded, this.reason)
      : isDuplicate = false;
}

/// Pure calculation engine for XP rewards.
/// Enforces educational reward logic and strict duplicate prevention.
class XpEngine {
  /// Evaluates XP award for a given mission completion attempt.
  /// Guarantees that:
  /// 1. An event or mission cannot yield duplicate XP rewards.
  /// 2. Simulated trade profit or financial metrics NEVER dictate XP rewards.
  static XpAwardResult calculateXpAward({
    required LearningEvent event,
    required Mission mission,
    required XpState currentXpState,
  }) {
    // 1. Check duplicate mission completion
    if (currentXpState.isMissionCompleted(mission.id)) {
      return XpAwardResult.zeroDuplicate(
        'Mission "${mission.id}" was already completed.',
      );
    }

    // 2. Check duplicate event processing
    if (currentXpState.isEventProcessed(event.eventId)) {
      return XpAwardResult.zeroDuplicate(
        'Event "${event.eventId}" was already processed.',
      );
    }

    // 3. Verify event matches mission requirement
    if (mission.eventType != event.type) {
      return const XpAwardResult(
        xpAwarded: 0,
        isDuplicate: false,
        reason: 'Event type does not match mission requirement.',
      );
    }

    // 4. Return educational XP reward
    return XpAwardResult.success(
      mission.xpReward,
      'Awarded +${mission.xpReward} XP for completing mission "${mission.title}".',
    );
  }
}
