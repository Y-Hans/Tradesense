import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../domain/learning_event.dart';
import '../domain/level.dart';
import '../domain/mission.dart';
import '../domain/xp_state.dart';
import 'level_engine.dart';
import 'mission_engine.dart';

class ProgressionEventResult {
  final bool success;
  final int xpGained;
  final List<Mission> newlyCompletedMissions;
  final bool didLevelUp;
  final Level newLevel;
  final bool isDuplicate;
  final String message;

  const ProgressionEventResult({
    required this.success,
    required this.xpGained,
    required this.newlyCompletedMissions,
    required this.didLevelUp,
    required this.newLevel,
    required this.isDuplicate,
    required this.message,
  });
}

class LearningProgressionState {
  final XpState xpState;
  final Level currentLevel;
  final double progressToNextLevel;
  final int xpToNextLevel;
  final List<Mission> missions;
  final ProgressionEventResult? lastResult;

  const LearningProgressionState({
    required this.xpState,
    required this.currentLevel,
    required this.progressToNextLevel,
    required this.xpToNextLevel,
    required this.missions,
    this.lastResult,
  });

  factory LearningProgressionState.initial() {
    const initialMissions = Mission.initialMissions;
    const initialXpState = XpState();
    final levelEval = LevelEngine.evaluateLevel(previousXp: 0, currentXp: 0);

    return LearningProgressionState(
      xpState: initialXpState,
      currentLevel: levelEval.currentLevel,
      progressToNextLevel: levelEval.progressToNext,
      xpToNextLevel: levelEval.xpToNext,
      missions: initialMissions,
    );
  }

  int get totalXp => xpState.totalXp;
  Set<String> get completedMissionIds => xpState.completedMissionIds;
  Set<String> get processedEventIds => xpState.processedEventIds;

  LearningProgressionState copyWith({
    XpState? xpState,
    Level? currentLevel,
    double? progressToNextLevel,
    int? xpToNextLevel,
    List<Mission>? missions,
    ProgressionEventResult? lastResult,
  }) {
    return LearningProgressionState(
      xpState: xpState ?? this.xpState,
      currentLevel: currentLevel ?? this.currentLevel,
      progressToNextLevel: progressToNextLevel ?? this.progressToNextLevel,
      xpToNextLevel: xpToNextLevel ?? this.xpToNextLevel,
      missions: missions ?? this.missions,
      lastResult: lastResult ?? this.lastResult,
    );
  }
}

class LearningProgressionNotifier
    extends StateNotifier<LearningProgressionState> {
  LearningProgressionNotifier() : super(LearningProgressionState.initial());

  /// Processes an incoming [LearningEvent] through the mission and XP engines.
  /// Guarantees idempotent execution and duplicate prevention.
  ProgressionEventResult processEvent(LearningEvent event) {
    final previousXp = state.totalXp;
    final processResult = MissionEngine.processEvent(
      event: event,
      missions: state.missions,
      xpState: state.xpState,
    );

    final isDuplicate =
        processResult.isIdempotentSkip || processResult.isDuplicateAttempt;

    if (processResult.isIdempotentSkip) {
      final result = ProgressionEventResult(
        success: false,
        xpGained: 0,
        newlyCompletedMissions: const [],
        didLevelUp: false,
        newLevel: state.currentLevel,
        isDuplicate: true,
        message: 'Event "${event.eventId}" was already processed.',
      );
      state = state.copyWith(lastResult: result);
      return result;
    }

    final newXp = processResult.updatedXpState.totalXp;
    final levelEval = LevelEngine.evaluateLevel(
      previousXp: previousXp,
      currentXp: newXp,
    );

    final result = ProgressionEventResult(
      success: processResult.totalXpGained > 0,
      xpGained: processResult.totalXpGained,
      newlyCompletedMissions: processResult.newlyCompletedMissions,
      didLevelUp: levelEval.didLevelUp,
      newLevel: levelEval.currentLevel,
      isDuplicate: isDuplicate,
      message: processResult.totalXpGained > 0
          ? 'Gained +${processResult.totalXpGained} XP!'
          : (isDuplicate
              ? 'Reward already claimed.'
              : 'Event processed with 0 new rewards.'),
    );

    state = LearningProgressionState(
      xpState: processResult.updatedXpState,
      currentLevel: levelEval.currentLevel,
      progressToNextLevel: levelEval.progressToNext,
      xpToNextLevel: levelEval.xpToNext,
      missions: processResult.updatedMissions,
      lastResult: result,
    );

    return result;
  }

  /// Claims a specific mission by ID manually.
  ProgressionEventResult claimMission(String missionId) {
    final mission = state.missions.firstWhere(
      (m) => m.id == missionId,
      orElse: () => throw ArgumentError('Mission "$missionId" not found.'),
    );

    final event = LearningEvent(
      type: mission.eventType,
      eventId: 'claim_${missionId}_${DateTime.now().microsecondsSinceEpoch}',
    );

    return processEvent(event);
  }

  /// Resets state back to initial (useful on logout or user switch).
  void reset() {
    state = LearningProgressionState.initial();
  }

  /// Restores learning progression state from persistent storage or snapshot.
  void restoreState({
    required int totalXp,
    required Set<String> completedMissionIds,
    required Set<String> processedEventIds,
  }) {
    final restoredXpState = XpState(
      totalXp: totalXp,
      completedMissionIds: completedMissionIds,
      processedEventIds: processedEventIds,
    );

    final restoredMissions = Mission.initialMissions.map((m) {
      if (completedMissionIds.contains(m.id)) {
        return m.copyWith(isCompleted: true);
      }
      return m;
    }).toList();

    final levelEval = LevelEngine.evaluateLevel(
      previousXp: totalXp,
      currentXp: totalXp,
    );

    state = LearningProgressionState(
      xpState: restoredXpState,
      currentLevel: levelEval.currentLevel,
      progressToNextLevel: levelEval.progressToNext,
      xpToNextLevel: levelEval.xpToNext,
      missions: restoredMissions,
    );
  }
}

/// Global Riverpod Provider for Learning Progression StateNotifier.
final learningProgressionNotifierProvider = StateNotifierProvider<
    LearningProgressionNotifier, LearningProgressionState>((ref) {
  return LearningProgressionNotifier();
});
