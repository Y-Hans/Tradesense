import 'package:flutter/material.dart';
import '../../../app/theme/app_theme.dart';
import '../domain/models/mission.dart';
import '../domain/models/xp_level.dart';
import '../../../core/widgets/trade_card.dart';
import '../../../core/widgets/visual_gauge.dart';

class MissionsScreen extends StatefulWidget {
  const MissionsScreen({super.key});

  @override
  State<MissionsScreen> createState() => _MissionsScreenState();
}

class _MissionsScreenState extends State<MissionsScreen> {
  int _userXp = 0;
  final Set<String> _completedMissionIds = {};

  void _claimMission(Mission mission) {
    if (_completedMissionIds.contains(mission.id)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Reward already claimed for this mission.'),
          backgroundColor: AppColors.alert,
        ),
      );
      return;
    }

    setState(() {
      _completedMissionIds.add(mission.id);
      _userXp += mission.xpReward;
    });

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
    final currentLevel = XpLevel.fromXp(_userXp);
    final progressToNext = XpLevel.getProgressToNextLevel(_userXp);
    const missions = Mission.coreMissions;

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
                  colors: [AppColors.electricCyan, AppColors.cyberGold],
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
                          const Text(
                            'CURRENT LEVEL',
                            style: TextStyle(
                              color: AppColors.textSecondary,
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
                          const SizedBox(height: 16.0),
                          Text(
                            currentLevel.tier == LevelTier.disciplinedTrader
                                ? 'Maximum level reached!'
                                : 'Next Level Tier at ${currentLevel.maxXp + 1} XP',
                            style: const TextStyle(
                                color: Colors.white70, fontSize: 12.0),
                          ),
                        ],
                      ),
                      VisualGauge(
                        progress: progressToNext,
                        activeColor: AppColors.alert,
                        label: '$_userXp XP',
                      ),
                    ],
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
                final isCompleted = _completedMissionIds.contains(mission.id);

                return TradeCard(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10.0),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: isCompleted
                              ? AppColors.profit.withValues(alpha: 0.2)
                              : AppColors.electricCyan.withValues(alpha: 0.15),
                        ),
                        child: Icon(
                          isCompleted
                              ? Icons.check_circle
                              : Icons.stars_rounded,
                          color: isCompleted
                              ? AppColors.profit
                              : AppColors.electricCyan,
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
                            backgroundColor: AppColors.electricCyan,
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
