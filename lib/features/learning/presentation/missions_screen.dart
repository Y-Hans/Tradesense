import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:design_system/design_system.dart';
import '../../../shared/widgets/trade_card.dart';
import '../application/learning_progression_notifier.dart';
import '../domain/learning_event.dart';
import '../domain/mission.dart';
import 'widgets/achievement_cards_grid.dart';
import 'widgets/level_up_celebration_dialog.dart';
import 'widgets/player_profile_summary_card.dart';
import 'widgets/recent_rewards_timeline.dart';

class MissionsScreen extends ConsumerStatefulWidget {
  const MissionsScreen({super.key});

  @override
  ConsumerState<MissionsScreen> createState() => _MissionsScreenState();
}

class _MissionsScreenState extends ConsumerState<MissionsScreen> {
  void _claimMission(Mission mission) {
    final result = ref
        .read(learningProgressionNotifierProvider.notifier)
        .claimMission(mission.id);

    if (result.isDuplicate || !result.success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Reward already claimed for this mission.'),
          backgroundColor: AppColors.successGreen,
        ),
      );
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content:
            Text('Claimed +${mission.xpReward} XP for "${mission.title}"!'),
        backgroundColor: AppColors.successGreen,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Listen for level up events to present LevelUpCelebrationDialog deterministically
    ref.listen<LearningProgressionState>(
      learningProgressionNotifierProvider,
      (previous, next) {
        if (next.showLevelUpAnimation &&
            !(previous?.showLevelUpAnimation ?? false)) {
          LevelUpCelebrationDialog.show(
            context,
            levelTitle: next.currentLevel.title,
            newLevelXp: next.totalXp,
            unlockMessage:
                'Congratulations! You have reached ${next.currentLevel.title} tier.',
            onClaim: () {
              ref
                  .read(learningProgressionNotifierProvider.notifier)
                  .dismissLevelUpAnimation();
            },
          );
        }
      },
    );

    final state = ref.watch(learningProgressionNotifierProvider);
    final missions = state.missions;
    final completedMissionIds = state.completedMissionIds;

    // Convert domain achievements into AchievementModel
    final achievementModels =
        state.achievements.map(AchievementModel.fromDomain).toList();

    // Map reward history from XpState or completed missions
    final rewardItems = state.xpState.rewardHistory.map((log) {
      final mission = state.missions.firstWhere(
        (m) => m.id == log.missionId,
        orElse: () => Mission(
          id: log.missionId,
          title: 'Learning Reward',
          description: '',
          xpReward: log.xpAwarded,
          eventType: LearningEventType.completedLesson,
        ),
      );
      return RewardItemModel(
        title: mission.title,
        subtitle: '+${log.xpAwarded} XP earned',
        date: log.timestamp,
        isClaimed: true,
      );
    }).toList();

    // Fallback: If reward history is empty, populate from completed missions
    if (rewardItems.isEmpty) {
      for (final mission in state.missions.where((m) => m.isCompleted)) {
        rewardItems.add(
          RewardItemModel(
            title: mission.title,
            subtitle: '+${mission.xpReward} XP earned',
            date: DateTime.now(),
            isClaimed: true,
          ),
        );
      }
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Gamified Learning Hub'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Glassmorphic Player Profile Summary Card
            PlayerProfileSummaryCard(
              avatarUrl: '',
              levelTitle: state.currentLevel.title,
              rank:
                  'Tier ${state.currentLevel.tier.index + 1} · ${state.currentTitle.title}',
              streakDays: state.streak.currentStreak,
              isStreakActive: state.streak.isStreakActive,
              currentXp: state.totalXp,
              maxXp: state.currentLevel.maxXp,
            ),

            const SizedBox(height: 28.0),

            const Text(
              'Educational Missions',
              style: TextStyle(
                fontSize: 18.0,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4.0),
            const Text(
              'Complete learning objectives to earn XP and level up your discipline.',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 13.0),
            ),
            const SizedBox(height: 16.0),

            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: missions.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12.0),
              itemBuilder: (context, index) {
                final mission = missions[index];
                final isCompleted = mission.isCompleted ||
                    completedMissionIds.contains(mission.id);

                return TradeCard(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10.0),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: isCompleted
                              ? AppColors.successGreen.withValues(alpha: 0.2)
                              : AppColors.primaryCyan.withValues(alpha: 0.15),
                        ),
                        child: Icon(
                          isCompleted
                              ? Icons.check_circle
                              : Icons.stars_rounded,
                          color: isCompleted
                              ? AppColors.successGreen
                              : AppColors.primaryCyan,
                          size: 24.0,
                        ),
                      ),
                      const SizedBox(width: 14.0),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              mission.title,
                              style: const TextStyle(
                                fontSize: 15.0,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4.0),
                            Text(
                              mission.description,
                              style: const TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: 12.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12.0),
                      if (isCompleted)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10.0, vertical: 6.0),
                          decoration: BoxDecoration(
                            color: AppColors.successGreen.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(20.0),
                          ),
                          child: const Text(
                            'Completed',
                            style: TextStyle(
                              color: AppColors.successGreen,
                              fontSize: 12.0,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        )
                      else
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primaryCyan,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12.0, vertical: 8.0),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8.0),
                            ),
                          ),
                          onPressed: () => _claimMission(mission),
                          child: Text(
                            '+${mission.xpReward} XP',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12.0,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                    ],
                  ),
                );
              },
            ),

            const SizedBox(height: 28.0),

            const Text(
              'Achievements & Badges',
              style: TextStyle(
                fontSize: 18.0,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4.0),
            const Text(
              'Unlock achievements by making progress in your trading education.',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 13.0),
            ),
            const SizedBox(height: 16.0),

            AchievementCardsGrid(achievements: achievementModels),

            const SizedBox(height: 28.0),

            const Text(
              'Reward History',
              style: TextStyle(
                fontSize: 18.0,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4.0),
            const Text(
              'Timeline of earned XP rewards and milestones.',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 13.0),
            ),
            const SizedBox(height: 16.0),

            RecentRewardsTimeline(rewards: rewardItems),
          ],
        ),
      ),
    );
  }
}
