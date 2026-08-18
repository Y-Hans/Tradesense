import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../domain/achievement.dart';
import '../domain/learning_event.dart';
import '../domain/learning_streak.dart';
import '../domain/learning_title.dart';
import '../domain/level.dart';
import '../domain/mission.dart';
import '../domain/player_profile_summary.dart';
import '../domain/xp_state.dart';
import '../../../core/providers/supabase_provider.dart';
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
  final Ref ref;
  
  LearningProgressionNotifier(this.ref) : super(LearningProgressionState.initial()) {
    refresh();
  }

  Future<void> refresh() async {
    try {
      // In a real app, we'd import the repository properly. 
      // Using Supabase directly here for simplicity since it's a mirror.
      final supabase = ref.read(supabaseClientProvider);
      final user = supabase.auth.currentUser;
      if (user == null) return;

      final profileResp = await supabase
          .from('profiles')
          .select('total_xp')
          .eq('id', user.id)
          .maybeSingle();
      
      final totalXp = profileResp != null ? (profileResp['total_xp'] as int? ?? 0) : 0;

      final missionsResp = await supabase
          .from('mission_progress')
          .select('mission_id')
          .eq('user_id', user.id);
          
      final completedMissionIds = (missionsResp as List<dynamic>)
          .map((e) => e['mission_id'] as String)
          .toSet();

      restoreState(
        totalXp: totalXp,
        completedMissionIds: completedMissionIds,
        processedEventIds: {}, // no longer used for mutation
      );
    } catch (e) {
      // Keep existing state on error
    }
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
      streakDays: restoredStreak.currentStreak,
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
  return LearningProgressionNotifier(ref);
});
