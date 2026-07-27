import 'package:flutter/foundation.dart';

@immutable
class FeatureFlags {
  final bool aiCoachEnabled;
  final bool newsDetectiveEnabled;
  final bool missionsEnabled;
  final bool premiumFeaturesEnabled;
  final bool marketTradingEnabled;
  final bool maintenanceMode;

  const FeatureFlags({
    this.aiCoachEnabled = true,
    this.newsDetectiveEnabled = true,
    this.missionsEnabled = true,
    this.premiumFeaturesEnabled = true,
    this.marketTradingEnabled = true,
    this.maintenanceMode = false,
  });

  Map<String, dynamic> toJson() => {
        'ai_coach_enabled': aiCoachEnabled,
        'news_detective_enabled': newsDetectiveEnabled,
        'missions_enabled': missionsEnabled,
        'premium_features_enabled': premiumFeaturesEnabled,
        'market_trading_enabled': marketTradingEnabled,
        'maintenance_mode': maintenanceMode,
      };

  factory FeatureFlags.fromJson(Map<String, dynamic> json) => FeatureFlags(
        aiCoachEnabled: json['ai_coach_enabled'] as bool? ?? true,
        newsDetectiveEnabled: json['news_detective_enabled'] as bool? ?? true,
        missionsEnabled: json['missions_enabled'] as bool? ?? true,
        premiumFeaturesEnabled:
            json['premium_features_enabled'] as bool? ?? true,
        marketTradingEnabled: json['market_trading_enabled'] as bool? ?? true,
        maintenanceMode: json['maintenance_mode'] as bool? ?? false,
      );
}
