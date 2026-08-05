import 'dart:ui';
import 'package:flutter/material.dart';
import '../../../../app/theme/app_theme.dart';

class RewardItemModel {
  final String title;
  final String subtitle;
  final DateTime date;
  final bool isClaimed;

  const RewardItemModel({
    required this.title,
    required this.subtitle,
    required this.date,
    this.isClaimed = true,
  });
}

class RecentRewardsTimeline extends StatelessWidget {
  final List<RewardItemModel> rewards;

  const RecentRewardsTimeline({
    super.key,
    required this.rewards,
  });

  @override
  Widget build(BuildContext context) {
    if (rewards.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(16.0),
        child: Text(
          'No recent rewards.',
          style: TextStyle(color: AppColors.textSecondary),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: List.generate(rewards.length, (index) {
        final isLast = index == rewards.length - 1;
        return _TimelineTile(
          reward: rewards[index],
          isLast: isLast,
        );
      }),
    );
  }
}

class _TimelineTile extends StatelessWidget {
  final RewardItemModel reward;
  final bool isLast;

  const _TimelineTile({
    required this.reward,
    required this.isLast,
  });

  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Timeline indicator (Line and dot)
          SizedBox(
            width: 40.0,
            child: Column(
              children: [
                Container(
                  width: 16.0,
                  height: 16.0,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: reward.isClaimed
                        ? AppColors.electricCyan
                        : Colors.white.withValues(alpha: 0.1),
                    border: Border.all(
                      color: reward.isClaimed
                          ? AppColors.electricCyan
                          : Colors.grey,
                      width: 2.0,
                    ),
                    boxShadow: reward.isClaimed
                        ? [
                            BoxShadow(
                              color: AppColors.electricCyan.withValues(alpha: 0.5),
                              blurRadius: 8.0,
                            ),
                          ]
                        : null,
                  ),
                ),
                if (!isLast)
                  Expanded(
                    child: Container(
                      width: 2.0,
                      color: Colors.white.withValues(alpha: 0.1),
                    ),
                  ),
              ],
            ),
          ),
          // Content
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 24.0, right: 16.0),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12.0),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 8.0, sigmaY: 8.0),
                  child: Container(
                    padding: const EdgeInsets.all(16.0),
                    decoration: BoxDecoration(
                      color: AppColors.oledSurface.withValues(alpha: 0.4),
                      borderRadius: BorderRadius.circular(12.0),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.05),
                        width: 1.0,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              reward.title,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 16.0,
                              ),
                            ),
                            if (reward.isClaimed)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8.0,
                                  vertical: 4.0,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.electricCyan.withValues(alpha: 0.2),
                                  borderRadius: BorderRadius.circular(8.0),
                                ),
                                child: const Text(
                                  'CLAIMED',
                                  style: TextStyle(
                                    color: AppColors.electricCyan,
                                    fontSize: 10.0,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 6.0),
                        Text(
                          reward.subtitle,
                          style: const TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 13.0,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
