import 'dart:ui';
import 'package:flutter/material.dart';
import '../../../../app/theme/app_theme.dart';

enum AchievementRarity {
  common,
  rare,
  epic,
  legendary,
}

class AchievementModel {
  final String title;
  final String description;
  final String iconUrl;
  final AchievementRarity rarity;
  final bool isUnlocked;

  const AchievementModel({
    required this.title,
    required this.description,
    required this.iconUrl,
    required this.rarity,
    this.isUnlocked = false,
  });
}

class AchievementCardsGrid extends StatelessWidget {
  final List<AchievementModel> achievements;

  const AchievementCardsGrid({
    super.key,
    required this.achievements,
  });

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 180,
        mainAxisSpacing: 16.0,
        crossAxisSpacing: 16.0,
        childAspectRatio: 0.85,
      ),
      itemCount: achievements.length,
      itemBuilder: (context, index) {
        return _AchievementCard(achievement: achievements[index]);
      },
    );
  }
}

class _AchievementCard extends StatelessWidget {
  final AchievementModel achievement;

  const _AchievementCard({required this.achievement});

  Color _getRarityColor(AchievementRarity rarity) {
    switch (rarity) {
      case AchievementRarity.common:
        return AppColors.electricCyan; // Cyan
      case AchievementRarity.rare:
        return Colors.blue;
      case AchievementRarity.epic:
        return Colors.purpleAccent;
      case AchievementRarity.legendary:
        return Colors.amber;
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = _getRarityColor(achievement.rarity);
    final isActive = achievement.isUnlocked;

    return ClipRRect(
      borderRadius: BorderRadius.circular(16.0),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 8.0, sigmaY: 8.0),
        child: Container(
          padding: EdgeInsets.all(12.0),
          decoration: BoxDecoration(
            color: isActive
                ? color.withValues(alpha: 0.1)
                : Theme.of(context).colorScheme.surface.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(16.0),
            border: Border.all(
              color: isActive
                  ? color.withValues(alpha: 0.6)
                  : Colors.white.withValues(alpha: 0.05),
              width: 1.5,
            ),
            boxShadow: isActive
                ? [
                    BoxShadow(
                      color: color.withValues(alpha: 0.2),
                      blurRadius: 15.0,
                      spreadRadius: -5.0,
                    )
                  ]
                : [],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(12.0),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isActive
                      ? color.withValues(alpha: 0.2)
                      : Colors.white.withValues(alpha: 0.05),
                ),
                child: achievement.iconUrl.isNotEmpty
                    ? Image.network(
                        achievement.iconUrl,
                        width: 32.0,
                        height: 32.0,
                        color: isActive ? null : Colors.grey,
                        colorBlendMode: isActive ? null : BlendMode.saturation,
                      )
                    : Icon(
                        isActive ? Icons.emoji_events : Icons.lock_outline,
                        color: isActive ? color : Colors.grey,
                        size: 32.0,
                      ),
              ),
              const SizedBox(height: 12.0),
              Text(
                achievement.title,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: isActive ? Theme.of(context).colorScheme.onSurface : Colors.grey,
                  fontSize: 13.0,
                  fontWeight: FontWeight.bold,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4.0),
              Text(
                achievement.rarity.name.toUpperCase(),
                style: TextStyle(
                  color: isActive ? color : Colors.grey.withValues(alpha: 0.5),
                  fontSize: 10.0,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.1,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
