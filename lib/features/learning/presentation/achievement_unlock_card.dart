import 'package:flutter/material.dart';
import '../../../app/theme/app_theme.dart';
import '../domain/achievement.dart';

class AchievementUnlockCard extends StatelessWidget {
  final Achievement achievement;

  const AchievementUnlockCard({
    super.key,
    required this.achievement,
  });

  @override
  Widget build(BuildContext context) {
    final isUnlocked = achievement.isUnlocked;
    final rarityColor = achievement.rarity.color;

    return Container(
      padding: EdgeInsets.all(12.0),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12.0),
        border: Border.all(
          color: isUnlocked
              ? rarityColor.withValues(alpha: 0.6)
              : Theme.of(context).dividerColor,
          width: isUnlocked ? 1.5 : 1.0,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(10.0),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isUnlocked
                  ? rarityColor.withValues(alpha: 0.2)
                  : Theme.of(context).cardColor,
            ),
            child: Icon(
              achievement.icon,
              color: isUnlocked ? rarityColor : Theme.of(context).textTheme.bodyMedium?.color ?? Colors.grey,
              size: 22.0,
            ),
          ),
          SizedBox(width: 12.0),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Text(
                      achievement.title,
                      style: TextStyle(
                        color:
                            isUnlocked ? Colors.white : Theme.of(context).textTheme.bodyMedium?.color ?? Colors.grey,
                        fontSize: 14.0,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(width: 8.0),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6.0,
                        vertical: 2.0,
                      ),
                      decoration: BoxDecoration(
                        color: rarityColor.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(6.0),
                      ),
                      child: Text(
                        achievement.rarity.displayName,
                        style: TextStyle(
                          color: rarityColor,
                          fontSize: 10.0,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4.0),
                Text(
                  achievement.description,
                  style: TextStyle(
                    color: Theme.of(context).textTheme.bodyMedium?.color ?? Colors.grey,
                    fontSize: 12.0,
                  ),
                ),
              ],
            ),
          ),
          if (isUnlocked)
            const Icon(
              Icons.check_circle_rounded,
              color: AppColors.profit,
              size: 18.0,
            ),
        ],
      ),
    );
  }
}
