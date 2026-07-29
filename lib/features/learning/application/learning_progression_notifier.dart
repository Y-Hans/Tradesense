import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../domain/achievement.dart';
import '../domain/learning_event.dart';
import '../domain/learning_streak.dart';
import '../domain/learning_title.dart';
import '../domain/level.dart';
import '../domain/mission.dart';
import '../domain/player_profile_summary.dart';
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
  final LearningTitle currentTitle;
  final double progressToNextLevel;
  final int xpToNextLevel;
  final List<Mission> missions;
  final List<Achievement> achievements;
  final LearningStreak streak;
  final PlayerProfileSummary playerProfileSummary;
  final bool showXpGainAnimation;
  final int recentXpGained;
  final bool showLevelUpAnimation;
  final List<Achievement> unlockedAchievements;
  final ProgressionEventResult? lastResult;

  const LearningProgressionState({
    required this.xpState,
    required this.currentLevel,
    required this.currentTitle,
    required this.progressToNextLevel,
    required this.xpToNextLevel,
    required this.missions,
    required this.achievements,
    required this.streak,
    required this.playerProfileSummary,
    this.showXpGainAnimation = false,
    this.recentXpGained = 0,
    this.showLevelUpAnimation = false,
    this.unlockedAchievements = const [],
    this.lastResult,
  });

  factory LearningProgressionState.initial() {
    const initialMissions = Mission.initialMissions;
    const initialAchievements = Achievement.initialAchievements;
    const initialXpState = XpState();
    const initialStreak = LearningStreak();
    final levelEval = LevelEngine.evaluateLevel(previousXp: 0, currentXp: 0);
    final initialTitle = LearningTitle.fromXp(0);

    final initialSummary = PlayerProfileSummary.calculate(
      totalXp: 0,
      currentLevel: levelEval.currentLevel,
      currentTitle: initialTitle,
      streak: initialStreak,
      achievements: initialAchievements,
      missions: initialMissions,
      completedMissionIds: const {},
    );

    return LearningProgressionState(
      xpState: initialXpState,
      currentLevel: levelEval.currentLevel,
      currentTitle: initialTitle,
      progressToNextLevel: levelEval.progressToNext,
      xpToNextLevel: levelEval.xpToNext,
      missions: initialMissions,
      achievements: initialAchievements,
      streak: initialStreak,
      playerProfileSummary: initialSummary,
    );
  }

  int get totalXp => xpState.totalXp;
  Set<String> get completedMissionIds => xpState.completedMissionIds;
  Set<String> get processedEventIds => xpState.processedEventIds;

  LearningProgressionState copyWith({
    XpState? xpState,
    Level? currentLevel,
    LearningTitle? currentTitle,
    double? progressToNextLevel,
    int? xpToNextLevel,
    List<Mission>? missions,
    List<Achievement>? achievements,
    LearningStreak? streak,
    PlayerProfileSummary? playerProfileSummary,
    bool? showXpGainAnimation,
    int? recentXpGained,
    bool? showLevelUpAnimation,
    List<Achievement>? unlockedAchievements,
    ProgressionEventResult? lastResult,
  }) {
    return LearningProgressionState(
      xpState: xpState ?? this.xpState,
      currentLevel: currentLevel ?? this.currentLevel,
      currentTitle: currentTitle ?? this.currentTitle,
      progressToNextLevel: progressToNextLevel ?? this.progressToNextLevel,
      xpToNextLevel: xpToNextLevel ?? this.xpToNextLevel,
      missions: missions ?? this.missions,
      achievements: achievements ?? this.achievements,
      streak: streak ?? this.streak,
      playerProfileSummary: playerProfileSummary ?? this.playerProfileSummary,
      showXpGainAnimation: showXpGainAnimation ?? this.showXpGainAnimation,
      recentXpGained: recentXpGained ?? this.recentXpGained,
      showLevelUpAnimation: showLevelUpAnimation ?? this.showLevelUpAnimation,
      unlockedAchievements: unlockedAchievements ?? this.unlockedAchievements,
      lastResult: lastResult ?? this.lastResult,
    );
  }
}

class LearningProgressionNotifier
    extends StateNotifier<LearningProgressionState> {
  LearningProgressionNotifier() : super(LearningProgressionState.initial());

  /// Processes an incoming [LearningEvent] through mission, XP, achievement, and streak logic.
  /// Guarantees idempotent execution, duplicate prevention, and non-financial reward policies.
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

    // Update daily streak on activity
    final updatedStreak = state.streak.registerActivity(
      activityDate: event.timestamp,
    );

    // Collect processed event types to evaluate achievement unlocks
    final processedTypes = state.missions
        .where((m) =>
            m.isCompleted ||
            processResult.updatedXpState.completedMissionIds.contains(m.id))
        .map((m) => m.eventType)
        .toSet();
    processedTypes.add(event.type);

    // Check achievement unlocks
    final achievementEval = Achievement.checkUnlocks(
      currentAchievements: state.achievements,
      totalXp: newXp,
      processedEventTypes: processedTypes,
      timestamp: event.timestamp,
    );

    final updatedTitle = LearningTitle.fromXp(newXp);
    final xpGained = processResult.totalXpGained;

    final updatedSummary = PlayerProfileSummary.calculate(
      totalXp: newXp,
      currentLevel: levelEval.currentLevel,
      currentTitle: updatedTitle,
      streak: updatedStreak,
      achievements: achievementEval.achievements,
      missions: processResult.updatedMissions,
      completedMissionIds: processResult.updatedXpState.completedMissionIds,
    );

    final result = ProgressionEventResult(
      success: xpGained > 0,
      xpGained: xpGained,
      newlyCompletedMissions: processResult.newlyCompletedMissions,
      didLevelUp: levelEval.didLevelUp,
      newLevel: levelEval.currentLevel,
      isDuplicate: isDuplicate,
      message: xpGained > 0
          ? 'Gained +$xpGained XP!'
          : (isDuplicate
              ? 'Reward already claimed.'
              : 'Event processed with 0 new rewards.'),
    );

    state = LearningProgressionState(
      xpState: processResult.updatedXpState,
      currentLevel: levelEval.currentLevel,
      currentTitle: updatedTitle,
      progressToNextLevel: levelEval.progressToNext,
      xpToNextLevel: levelEval.xpToNext,
      missions: processResult.updatedMissions,
      achievements: achievementEval.achievements,
      streak: updatedStreak,
      playerProfileSummary: updatedSummary,
      showXpGainAnimation: xpGained > 0,
      recentXpGained: xpGained,
      showLevelUpAnimation: levelEval.didLevelUp,
      unlockedAchievements: achievementEval.newlyUnlocked,
      lastResult: result,
    );

    return result;
  }

  /// Dismisses the XP gain animation trigger state.
  void dismissXpGainAnimation() {
    state = state.copyWith(
      showXpGainAnimation: false,
      recentXpGained: 0,
    );
  }

  /// Dismisses the Level-Up celebration animation trigger state.
  void dismissLevelUpAnimation() {
    state = state.copyWith(
      showLevelUpAnimation: false,
      unlockedAchievements: const [],
    );
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
    LearningStreak? streak,
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

    final restoredStreak = streak ?? const LearningStreak();
    final restoredTitle = LearningTitle.fromXp(totalXp);

    final processedTypes = restoredMissions
        .where((m) => m.isCompleted)
        .map((m) => m.eventType)
        .toSet();

    final achievementEval = Achievement.checkUnlocks(
      currentAchievements: Achievement.initialAchievements,
      totalXp: totalXp,
      processedEventTypes: processedTypes,
    );

    final restoredSummary = PlayerProfileSummary.calculate(
      totalXp: totalXp,
      currentLevel: levelEval.currentLevel,
      currentTitle: restoredTitle,
      streak: restoredStreak,
      achievements: achievementEval.achievements,
      missions: restoredMissions,
      completedMissionIds: completedMissionIds,
    );

    state = LearningProgressionState(
      xpState: restoredXpState,
      currentLevel: levelEval.currentLevel,
      currentTitle: restoredTitle,
      progressToNextLevel: levelEval.progressToNext,
      xpToNextLevel: levelEval.xpToNext,
      missions: restoredMissions,
      achievements: achievementEval.achievements,
      streak: restoredStreak,
      playerProfileSummary: restoredSummary,
      showXpGainAnimation: false,
      recentXpGained: 0,
      showLevelUpAnimation: false,
      unlockedAchievements: const [],
    );
  }
}

/// Global Riverpod Provider for Learning Progression StateNotifier.
final learningProgressionNotifierProvider = StateNotifierProvider<
    LearningProgressionNotifier, LearningProgressionState>((ref) {
  return LearningProgressionNotifier();
});
