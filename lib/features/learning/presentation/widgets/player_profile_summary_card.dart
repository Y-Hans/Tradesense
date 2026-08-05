import 'dart:ui';
import 'package:flutter/material.dart';
import '../../../../app/theme/app_theme.dart';
import 'animated_xp_progress_bar.dart';
import 'daily_streak_card.dart';

class PlayerProfileSummaryCard extends StatelessWidget {
  final String avatarUrl;
  final String levelTitle;
  final String rank;
  final int streakDays;
  final bool isStreakActive;
  final int currentXp;
  final int maxXp;

  const PlayerProfileSummaryCard({
    super.key,
    required this.avatarUrl,
    required this.levelTitle,
    required this.rank,
    required this.streakDays,
    required this.isStreakActive,
    required this.currentXp,
    required this.maxXp,
  });

  @override
  Widget build(BuildContext context) {
    final progress = maxXp > 0 ? (currentXp / maxXp).clamp(0.0, 1.0) : 0.0;

    return ClipRRect(
      borderRadius: BorderRadius.circular(20.0),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12.0, sigmaY: 12.0),
        child: Container(
          padding: const EdgeInsets.all(24.0),
          decoration: BoxDecoration(
            color: AppColors.oledSurface.withValues(alpha: 0.3),
            borderRadius: BorderRadius.circular(20.0),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.1),
              width: 1.0,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 72.0,
                    height: 72.0,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: AppColors.electricCyan, width: 2.0),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.electricCyan.withValues(alpha: 0.3),
                          blurRadius: 10.0,
                          spreadRadius: 2.0,
                        ),
                      ],
                    ),
                    child: CircleAvatar(
                      backgroundColor: Colors.transparent,
                      backgroundImage: avatarUrl.isNotEmpty
                          ? NetworkImage(avatarUrl)
                          : null,
                      child: avatarUrl.isEmpty
                          ? const Icon(Icons.person,
                              size: 40.0, color: AppColors.electricCyan)
                          : null,
                    ),
                  ),
                  const SizedBox(width: 24.0),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          levelTitle,
                          style: const TextStyle(
                            fontSize: 22.0,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 4.0),
                        Text(
                          rank,
                          style: const TextStyle(
                            fontSize: 14.0,
                            color: AppColors.textSecondary,
                            letterSpacing: 1.1,
                          ),
                        ),
                      ],
                    ),
                  ),
                  DailyStreakCard(
                    streakDays: streakDays,
                    isActive: isStreakActive,
                  ),
                ],
              ),
              const SizedBox(height: 24.0),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'XP Progress',
                    style: TextStyle(
                      fontSize: 12.0,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textSecondary,
                      letterSpacing: 1.2,
                    ),
                  ),
                  Text(
                    '$currentXp / $maxXp XP',
                    style: const TextStyle(
                      fontSize: 12.0,
                      fontWeight: FontWeight.bold,
                      color: AppColors.electricCyan,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12.0),
              AnimatedXpProgressBar(
                progress: progress,
                height: 12.0,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
