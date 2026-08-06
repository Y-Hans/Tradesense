import '../domain/learning_event.dart';
import '../domain/mission.dart';
import '../domain/xp_state.dart';
import 'xp_engine.dart';

class MissionProcessResult {
  final List<Mission> updatedMissions;
  final XpState updatedXpState;
  final List<Mission> newlyCompletedMissions;
  final int totalXpGained;
  final bool isIdempotentSkip;
  final bool isDuplicateAttempt;

  const MissionProcessResult({
    required this.updatedMissions,
    required this.updatedXpState,
    required this.newlyCompletedMissions,
    required this.totalXpGained,
    required this.isIdempotentSkip,
    required this.isDuplicateAttempt,
  });
}

/// Pure engine for processing learning events against active educational missions.
class MissionEngine {
  /// Processes an incoming [LearningEvent] against the list of [missions].
  /// Guarantees idempotent event processing and duplicate reward prevention.
  static MissionProcessResult processEvent({
    required LearningEvent event,
    required List<Mission> missions,
    required XpState xpState,
  }) {
    // If event has already been processed, skip idempotently
    if (xpState.isEventProcessed(event.eventId)) {
      return MissionProcessResult(
        updatedMissions: missions,
        updatedXpState: xpState,
        newlyCompletedMissions: const [],
        totalXpGained: 0,
        isIdempotentSkip: true,
        isDuplicateAttempt: true,
      );
    }

    final updatedMissions = <Mission>[];
    final newlyCompleted = <Mission>[];
    var gainedXp = 0;
    var isDuplicateAttempt = false;
    var currentXpState = xpState;
    final newProcessedEvents = Set<String>.from(xpState.processedEventIds)
      ..add(event.eventId);
    final newCompletedMissions = Set<String>.from(xpState.completedMissionIds);
    final newRewardHistory = List<XpRewardLog>.from(xpState.rewardHistory);

    for (final mission in missions) {
      if (mission.eventType == event.type) {
        if (mission.isCompleted || xpState.isMissionCompleted(mission.id)) {
          isDuplicateAttempt = true;
          updatedMissions.add(mission);
          continue;
        }

        // Calculate XP reward idempotently
        final awardResult = XpEngine.calculateXpAward(
          event: event,
          mission: mission,
          currentXpState: currentXpState,
        );

        if (awardResult.xpAwarded > 0 && !awardResult.isDuplicate) {
          final completedMission = mission.copyWith(
            isCompleted: true,
            completedAt: event.timestamp,
          );
          updatedMissions.add(completedMission);
          newlyCompleted.add(completedMission);
          gainedXp += awardResult.xpAwarded;

          newCompletedMissions.add(mission.id);
          newRewardHistory.add(
            XpRewardLog(
              eventId: event.eventId,
              missionId: mission.id,
              xpAwarded: awardResult.xpAwarded,
              timestamp: event.timestamp,
            ),
          );

          currentXpState = currentXpState.copyWith(
            totalXp: currentXpState.totalXp + awardResult.xpAwarded,
            completedMissionIds: newCompletedMissions,
            rewardHistory: newRewardHistory,
          );
        } else {
          if (awardResult.isDuplicate) {
            isDuplicateAttempt = true;
          }
          updatedMissions.add(mission);
        }
      } else {
        updatedMissions.add(mission);
      }
    }

    final finalXpState = currentXpState.copyWith(
      totalXp: xpState.totalXp + gainedXp,
      processedEventIds: newProcessedEvents,
      completedMissionIds: newCompletedMissions,
      rewardHistory: newRewardHistory,
    );

    return MissionProcessResult(
      updatedMissions: updatedMissions,
      updatedXpState: finalXpState,
      newlyCompletedMissions: newlyCompleted,
      totalXpGained: gainedXp,
      isIdempotentSkip: false,
      isDuplicateAttempt: isDuplicateAttempt,
    );
  }

  /// Manually claims a specific mission reward if eligible.
  static MissionProcessResult claimMission({
    required String missionId,
    required List<Mission> missions,
    required XpState xpState,
  }) {
    final targetMission = missions.firstWhere(
      (m) => m.id == missionId,
      orElse: () => throw ArgumentError('Mission "$missionId" not found.'),
    );

    final event = LearningEvent(
      type: targetMission.eventType,
      eventId:
          'manual_claim_${missionId}_${DateTime.now().microsecondsSinceEpoch}',
    );

    return processEvent(
      event: event,
      missions: missions,
      xpState: xpState,
    );
  }
}
