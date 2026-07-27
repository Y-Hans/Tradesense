import 'package:flutter/foundation.dart';

@immutable
class SubscriptionStatus {
  final bool isPremium;
  final List<String> activeEntitlements;
  final DateTime? expirationDate;
  final String? activeOffering;

  const SubscriptionStatus({
    required this.isPremium,
    required this.activeEntitlements,
    this.expirationDate,
    this.activeOffering,
  });

  factory SubscriptionStatus.free() => const SubscriptionStatus(
        isPremium: false,
        activeEntitlements: [],
      );

  factory SubscriptionStatus.premium({DateTime? expires}) => SubscriptionStatus(
        isPremium: true,
        activeEntitlements: const ['premium'],
        expirationDate: expires,
        activeOffering: 'default_monthly',
      );

  Map<String, dynamic> toJson() => {
        'is_premium': isPremium,
        'active_entitlements': activeEntitlements,
        'expiration_date': expirationDate?.toIso8601String(),
        'active_offering': activeOffering,
      };

  factory SubscriptionStatus.fromJson(Map<String, dynamic> json) =>
      SubscriptionStatus(
        isPremium: json['is_premium'] as bool? ?? false,
        activeEntitlements:
            (json['active_entitlements'] as List<dynamic>?)?.cast<String>() ??
                [],
        expirationDate: json['expiration_date'] != null
            ? DateTime.parse(json['expiration_date'] as String)
            : null,
        activeOffering: json['active_offering'] as String?,
      );
}

@immutable
class Mission {
  final String id;
  final String title;
  final String description;
  final int rewardXp;
  final bool isCompleted;

  const Mission({
    required this.id,
    required this.title,
    required this.description,
    required this.rewardXp,
    this.isCompleted = false,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'description': description,
        'reward_xp': rewardXp,
        'is_completed': isCompleted,
      };

  factory Mission.fromJson(Map<String, dynamic> json) => Mission(
        id: json['id'] as String,
        title: json['title'] as String,
        description: json['description'] as String,
        rewardXp: (json['reward_xp'] as num).toInt(),
        isCompleted: json['is_completed'] as bool? ?? false,
      );
}
