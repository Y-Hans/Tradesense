import 'package:flutter/material.dart';
import '../../../app/theme/app_theme.dart';
import '../domain/achievement.dart';
import '../domain/learning_title.dart';
import '../domain/level.dart';
import 'achievement_unlock_card.dart';

class LevelUpDialog extends StatelessWidget {
  final Level level;
  final LearningTitle title;
  final int xpEarned;
  final List<Achievement> newlyUnlockedAchievements;
  final VoidCallback onContinue;

  LevelUpDialog({
    super.key,
    required this.level,
    required this.title,
    required this.xpEarned,
    required this.newlyUnlockedAchievements,
    required this.onContinue,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20.0),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16.0),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.discipline.withValues(alpha: 0.2),
              ),
              child: const Icon(
                Icons.emoji_events_rounded,
                color: AppColors.discipline,
                size: 48.0,
              ),
            ),
            const SizedBox(height: 16.0),
            const Text(
              'LEVEL UP!',
              style: TextStyle(
                color: AppColors.discipline,
                fontSize: 14.0,
                fontWeight: FontWeight.bold,
                letterSpacing: 2.0,
              ),
            ),
            const SizedBox(height: 4.0),
            Text(
              level.title,
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurface,
                fontSize: 24.0,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4.0),
            Text(
              'Title: ${title.title}',
              style: TextStyle(
                color: Theme.of(context).textTheme.bodyMedium?.color ?? Colors.grey,
                fontSize: 14.0,
              ),
            ),
            if (xpEarned > 0) ...[
              const SizedBox(height: 12.0),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12.0,
                  vertical: 6.0,
                ),
                decoration: BoxDecoration(
                  color: AppColors.profit.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(16.0),
                ),
                child: Text(
                  '+$xpEarned XP Gained',
                  style: const TextStyle(
                    color: AppColors.profit,
                    fontWeight: FontWeight.bold,
                    fontSize: 13.0,
                  ),
                ),
              ),
            ],
            if (newlyUnlockedAchievements.isNotEmpty) ...[
              const SizedBox(height: 16.0),
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Newly Unlocked Achievements:',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurface,
                    fontSize: 13.0,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 8.0),
              Flexible(
                child: SingleChildScrollView(
                  child: Column(
                    children: newlyUnlockedAchievements
                        .map((a) => Padding(
                              padding: const EdgeInsets.only(bottom: 8.0),
                              child: AchievementUnlockCard(achievement: a),
                            ))
                        .toList(),
                  ),
                ),
              ),
            ],
            const SizedBox(height: 20.0),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  padding: const EdgeInsets.symmetric(vertical: 14.0),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12.0),
                  ),
                ),
                onPressed: onContinue,
                child: const Text(
                  'CONTINUE',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 14.0,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
