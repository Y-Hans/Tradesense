import 'package:flutter/foundation.dart';

enum RiskLevel {
  low, // 0-30
  moderate, // 31-60
  high, // 61-80
  extreme // 81-100
}

@immutable
class RiskScore {
  final int score; // 0-100
  final RiskLevel level;
  final double concentrationScore; // 40% weight component
  final double sizingScore; // 30% weight component
  final double volatilityScore; // 20% weight component
  final double stopLossScore; // 10% weight component
  final List<String> explanations;

  const RiskScore({
    required this.score,
    required this.level,
    required this.concentrationScore,
    required this.sizingScore,
    required this.volatilityScore,
    required this.stopLossScore,
    required this.explanations,
  });

  static RiskLevel calculateLevel(int score) {
    if (score <= 30) return RiskLevel.low;
    if (score <= 60) return RiskLevel.moderate;
    if (score <= 80) return RiskLevel.high;
    return RiskLevel.extreme;
  }

  Map<String, dynamic> toJson() => {
        'score': score,
        'level': level.name,
        'concentration_score': concentrationScore,
        'sizing_score': sizingScore,
        'volatility_score': volatilityScore,
        'stop_loss_score': stopLossScore,
        'explanations': explanations,
      };

  factory RiskScore.fromJson(Map<String, dynamic> json) => RiskScore(
        score: (json['score'] as num).toInt(),
        level: RiskLevel.values.byName(json['level'] as String),
        concentrationScore: (json['concentration_score'] as num).toDouble(),
        sizingScore: (json['sizing_score'] as num).toDouble(),
        volatilityScore: (json['volatility_score'] as num).toDouble(),
        stopLossScore: (json['stop_loss_score'] as num).toDouble(),
        explanations: (json['explanations'] as List<dynamic>).cast<String>(),
      );
}
