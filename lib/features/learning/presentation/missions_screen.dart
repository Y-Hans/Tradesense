import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../app/theme/app_theme.dart';
import '../application/learning_progression_notifier.dart';
import '../domain/level.dart';
import '../domain/mission.dart';

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
          backgroundColor: AppColors.discipline,
        ),
      );
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content:
            Text('Claimed +${mission.xpReward} XP for "${mission.title}"!'),
        backgroundColor: AppColors.profit,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final progressionState = ref.watch(learningProgressionNotifierProvider);
    final userXp = progressionState.totalXp;
    final currentLevel = progressionState.currentLevel;
    final progressToNext = progressionState.progressToNextLevel;
    final missions = progressionState.missions;
    final completedMissionIds = progressionState.completedMissionIds;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Missions & Rewards'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Level & XP Header Card
            Container(
              padding: const EdgeInsets.all(20.0),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppColors.primary, AppColors.accent],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16.0),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'CURRENT LEVEL',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 11.0,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.2,
                            ),
                          ),
                          const SizedBox(height: 4.0),
                          Text(
                            currentLevel.title,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 22.0,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12.0, vertical: 6.0),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(20.0),
                        ),
                        child: Text(
                          '$userXp XP',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16.0),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8.0),
                    child: LinearProgressIndicator(
                      value: progressToNext,
                      minHeight: 8.0,
                      backgroundColor: Colors.white.withValues(alpha: 0.2),
                      valueColor: const AlwaysStoppedAnimation<Color>(
                          AppColors.discipline),
                    ),
                  ),
                  const SizedBox(height: 8.0),
                  Text(
                    currentLevel.tier == LevelTier.disciplinedTrader
                        ? 'Maximum level reached!'
                        : 'Next Level Tier at ${currentLevel.maxXp + 1} XP',
                    style:
                        const TextStyle(color: Colors.white70, fontSize: 12.0),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24.0),

            const Text(
              'Educational Missions',
              style: TextStyle(
                fontSize: 18.0,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4.0),
            Text(
              'Complete learning objectives to earn XP and level up your discipline.',
              style: TextStyle(color: Theme.of(context).textTheme.bodyMedium?.color ?? Colors.grey, fontSize: 13.0),
            ),
            const SizedBox(height: 16.0),

            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: missions.length,
              separatorBuilder: (_, __) => SizedBox(height: 12.0),
              itemBuilder: (context, index) {
                final mission = missions[index];
                final isCompleted = mission.isCompleted ||
                    completedMissionIds.contains(mission.id);

                return Container(
                  padding: EdgeInsets.all(16.0),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surface,
                    borderRadius: BorderRadius.circular(12.0),
                    border: Border.all(
                      color: isCompleted
                          ? AppColors.profit.withValues(alpha: 0.5)
                          : Theme.of(context).cardColor,
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10.0),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: isCompleted
                              ? AppColors.profit.withValues(alpha: 0.2)
                              : AppColors.primary.withValues(alpha: 0.15),
                        ),
                        child: Icon(
                          isCompleted
                              ? Icons.check_circle
                              : Icons.stars_rounded,
                          color: isCompleted
                              ? AppColors.profit
                              : AppColors.primary,
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
                              style: TextStyle(
                                color: Theme.of(context).textTheme.bodyMedium?.color ?? Colors.grey,
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
                            color: AppColors.profit.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(20.0),
                          ),
                          child: const Text(
                            'Completed',
                            style: TextStyle(
                              color: AppColors.profit,
                              fontSize: 12.0,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        )
                      else
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
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
          ],
        ),
      ),
    );
  }
}
