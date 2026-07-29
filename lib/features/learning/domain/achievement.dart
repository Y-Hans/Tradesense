import 'package:flutter/material.dart';
import 'learning_constants.dart';
import 'learning_event.dart';

enum AchievementRarity {
  common,
  rare,
  epic,
  legendary,
}

extension AchievementRarityX on AchievementRarity {
  String get displayName {
    switch (this) {
      case AchievementRarity.common:
        return 'Common';
      case AchievementRarity.rare:
        return 'Rare';
      case AchievementRarity.epic:
        return 'Epic';
      case AchievementRarity.legendary:
        return 'Legendary';
    }
  }

  Color get color {
    switch (this) {
      case AchievementRarity.common:
        return const Color(0xFF64B5F6); // Soft blue
      case AchievementRarity.rare:
        return const Color(0xFFBA68C8); // Soft purple
      case AchievementRarity.epic:
        return const Color(0xFFFFB74D); // Gold/Amber
      case AchievementRarity.legendary:
        return const Color(0xFF4DB6AC); // Teal/Emerald
    }
  }
}

class Achievement {
  final String id;
  final String title;
  final String description;
  final IconData icon;
  final AchievementRarity rarity;
  final int xpRequirement;
  final String unlockCondition;
  final DateTime? unlockedAt;
  final bool isUnlocked;

  const Achievement({
    required this.id,
    required this.title,
    required this.description,
    required this.icon,
    required this.rarity,
    this.xpRequirement = 0,
    required this.unlockCondition,
    this.unlockedAt,
    this.isUnlocked = false,
  });

  Achievement copyWith({
    DateTime? unlockedAt,
    bool? isUnlocked,
  }) {
    return Achievement(
      id: id,
      title: title,
      description: description,
      icon: icon,
      rarity: rarity,
      xpRequirement: xpRequirement,
      unlockCondition: unlockCondition,
      unlockedAt: unlockedAt ?? this.unlockedAt,
      isUnlocked: isUnlocked ?? this.isUnlocked,
    );
  }

  static const List<Achievement> initialAchievements = [
    Achievement(
      id: 'first_steps',
      title: 'First Steps',
      description: 'Completed onboarding walkthrough',
      icon: Icons.directions_walk_rounded,
      rarity: AchievementRarity.common,
      unlockCondition: 'onboardingCompleted',
    ),
    Achievement(
      id: 'market_explorer',
      title: 'Market Explorer',
      description: 'Viewed live market screen',
      icon: Icons.travel_explore_rounded,
      rarity: AchievementRarity.common,
      unlockCondition: 'viewedMarket',
    ),
    Achievement(
      id: 'curious_learner',
      title: 'Curious Learner',
      description: 'Read educational lesson',
      icon: Icons.menu_book_rounded,
      rarity: AchievementRarity.common,
      unlockCondition: 'completedLesson',
    ),
    Achievement(
      id: 'first_trade',
      title: 'First Trade',
      description: 'Executed first simulated trade',
      icon: Icons.candlestick_chart_rounded,
      rarity: AchievementRarity.rare,
      unlockCondition: 'firstTradeCompleted',
    ),
    Achievement(
      id: 'risk_aware',
      title: 'Risk Aware',
      description: 'Completed risk assessment module',
      icon: Icons.shield_rounded,
      rarity: AchievementRarity.rare,
      unlockCondition: 'completedLesson',
    ),
    Achievement(
      id: 'news_detective',
      title: 'News Detective',
      description: 'Completed News Detective analysis',
      icon: Icons.psychology_rounded,
      rarity: AchievementRarity.epic,
      unlockCondition: 'newsDetectiveCompleted',
    ),
    Achievement(
      id: 'level_5',
      title: 'Level 5 Achiever',
      description: 'Reached 250+ total XP',
      icon: Icons.military_tech_rounded,
      rarity: AchievementRarity.epic,
      xpRequirement: LearningConstants.xpAchievementLevel5,
      unlockCondition: 'totalXp >= 250',
    ),
    Achievement(
      id: 'level_10',
      title: 'Level 10 Master',
      description: 'Reached 1000+ total XP',
      icon: Icons.workspace_premium_rounded,
      rarity: AchievementRarity.legendary,
      xpRequirement: LearningConstants.xpAchievementLevel10,
      unlockCondition: 'totalXp >= 1000',
    ),
  ];

  /// Pure function checking unlock rules and returning updated achievements list along with newly unlocked achievements.
  static ({
    List<Achievement> achievements,
    List<Achievement> newlyUnlocked,
  }) checkUnlocks({
    required List<Achievement> currentAchievements,
    required int totalXp,
    required Set<LearningEventType> processedEventTypes,
    DateTime? timestamp,
  }) {
    final now = timestamp ?? DateTime.now();
    final updatedList = <Achievement>[];
    final newlyUnlockedList = <Achievement>[];

    for (final achievement in currentAchievements) {
      if (achievement.isUnlocked) {
        updatedList.add(achievement);
        continue;
      }

      bool shouldUnlock = false;

      // Event condition checks
      if (achievement.id == 'first_steps' &&
          processedEventTypes.contains(LearningEventType.onboardingCompleted)) {
        shouldUnlock = true;
      } else if (achievement.id == 'market_explorer' &&
          processedEventTypes.contains(LearningEventType.viewedMarket)) {
        shouldUnlock = true;
      } else if (achievement.id == 'curious_learner' &&
          processedEventTypes.contains(LearningEventType.completedLesson)) {
        shouldUnlock = true;
      } else if (achievement.id == 'first_trade' &&
          processedEventTypes.contains(LearningEventType.firstTradeCompleted)) {
        shouldUnlock = true;
      } else if (achievement.id == 'risk_aware' &&
          processedEventTypes.contains(LearningEventType.completedLesson)) {
        shouldUnlock = true;
      } else if (achievement.id == 'news_detective' &&
          processedEventTypes
              .contains(LearningEventType.newsDetectiveCompleted)) {
        shouldUnlock = true;
      }

      // XP / Level condition checks
      if (achievement.xpRequirement > 0 &&
          totalXp >= achievement.xpRequirement) {
        shouldUnlock = true;
      }

      if (shouldUnlock) {
        final unlocked = achievement.copyWith(
          isUnlocked: true,
          unlockedAt: now,
        );
        updatedList.add(unlocked);
        newlyUnlockedList.add(unlocked);
      } else {
        updatedList.add(achievement);
      }
    }

    return (
      achievements: updatedList,
      newlyUnlocked: newlyUnlockedList,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Achievement &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          isUnlocked == other.isUnlocked;

  @override
  int get hashCode => id.hashCode ^ isUnlocked.hashCode;

  @override
  String toString() =>
      'Achievement(id: $id, title: $title, isUnlocked: $isUnlocked, rarity: ${rarity.name})';
}
