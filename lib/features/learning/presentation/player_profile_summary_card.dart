import 'package:flutter/material.dart';
import '../../../app/theme/app_theme.dart';
import '../../../core/widgets/trade_card.dart';
import '../../../core/widgets/visual_gauge.dart';
import '../domain/player_profile_summary.dart';

class PlayerProfileSummaryCard extends StatelessWidget {
  final PlayerProfileSummary summary;

  const PlayerProfileSummaryCard({
    super.key,
    required this.summary,
  });

  @override
  Widget build(BuildContext context) {
    return TradeCard(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: Level & Title vs Visual Gauge
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'PLAYER PROFILE',
                      style: TextStyle(
                        color: Theme.of(context).textTheme.bodyMedium?.color ?? Colors.grey,
                        fontSize: 11.0,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.2,
                      ),
                    ),
                    const SizedBox(height: 4.0),
                    Text(
                      summary.currentLevel.title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 22.0,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 2.0),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8.0,
                        vertical: 3.0,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.discipline.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(6.0),
                      ),
                      child: Text(
                        summary.currentTitle.title,
                        style: const TextStyle(
                          color: AppColors.discipline,
                          fontSize: 12.0,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              VisualGauge(
                progress:
                    (summary.completionPercentage / 100.0).clamp(0.0, 1.0),
                activeColor: AppColors.discipline,
                label: '${summary.totalXp} XP',
              ),
            ],
          ),

          SizedBox(height: 16.0),
          Divider(color: Theme.of(context).dividerColor, height: 1.0),
          const SizedBox(height: 16.0),

          // Grid of 4 Key Player Profile Metrics
          Row(
            children: [
              Expanded(
                child: _buildMetricTile(
                  context: context,
                  icon: Icons.local_fire_department_rounded,
                  iconColor: Colors.orangeAccent,
                  label: 'Streak',
                  value: '${summary.currentStreak} Days',
                ),
              ),
              Expanded(
                child: _buildMetricTile(
                  context: context,
                  icon: Icons.emoji_events_rounded,
                  iconColor: AppColors.discipline,
                  label: 'Achievements',
                  value: summary.achievementsUnlocked,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12.0),
          Row(
            children: [
              Expanded(
                child: _buildMetricTile(
                  context: context,
                  icon: Icons.task_alt_rounded,
                  iconColor: AppColors.profit,
                  label: 'Missions',
                  value: summary.missionsCompleted,
                ),
              ),
              Expanded(
                child: _buildMetricTile(
                  context: context,
                  icon: Icons.pie_chart_outline_rounded,
                  iconColor: AppColors.primary,
                  label: 'Completion',
                  value: '${summary.completionPercentage.toStringAsFixed(0)}%',
                ),
              ),
            ],
          ),

          const SizedBox(height: 16.0),

          // Bottom Bar: XP remaining to next level
          Container(
            padding:
                EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              borderRadius: BorderRadius.circular(8.0),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Next Level Requirement:',
                  style: TextStyle(
                    color: Theme.of(context).textTheme.bodyMedium?.color ?? Colors.grey,
                    fontSize: 12.0,
                  ),
                ),
                Text(
                  summary.xpRemainingToNextLevel == 0
                      ? 'Max Level Reached'
                      : '${summary.xpRemainingToNextLevel} XP needed',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12.0,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricTile({
    required BuildContext context,
    required IconData icon,
    required Color iconColor,
    required String label,
    required String value,
  }) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8.0),
          decoration: BoxDecoration(
            color: iconColor.withValues(alpha: 0.15),
            shape: BoxShape.circle,
          ),
          child: Icon(
            icon,
            color: iconColor,
            size: 18.0,
          ),
        ),
        SizedBox(width: 10.0),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(
                color: Theme.of(context).textTheme.bodyMedium?.color ?? Colors.grey,
                fontSize: 11.0,
              ),
            ),
            Text(
              value,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14.0,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
