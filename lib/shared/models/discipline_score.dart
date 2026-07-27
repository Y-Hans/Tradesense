import 'package:flutter/foundation.dart';

@immutable
class DisciplineScore {
  final int score; // 0-100
  final double riskMgmtScore; // 30% weight
  final double positionSizingScore; // 25% weight
  final double stopLossDisciplineScore; // 20% weight
  final double concentrationScore; // 15% weight
  final double frequencyScore; // 10% weight
  final List<String> breakdownNotes;

  const DisciplineScore({
    required this.score,
    required this.riskMgmtScore,
    required this.positionSizingScore,
    required this.stopLossDisciplineScore,
    required this.concentrationScore,
    required this.frequencyScore,
    required this.breakdownNotes,
  });

  Map<String, dynamic> toJson() => {
        'score': score,
        'risk_mgmt_score': riskMgmtScore,
        'position_sizing_score': positionSizingScore,
        'stop_loss_discipline_score': stopLossDisciplineScore,
        'concentration_score': concentrationScore,
        'frequency_score': frequencyScore,
        'breakdown_notes': breakdownNotes,
      };

  factory DisciplineScore.fromJson(Map<String, dynamic> json) =>
      DisciplineScore(
        score: (json['score'] as num).toInt(),
        riskMgmtScore: (json['risk_mgmt_score'] as num).toDouble(),
        positionSizingScore: (json['position_sizing_score'] as num).toDouble(),
        stopLossDisciplineScore:
            (json['stop_loss_discipline_score'] as num).toDouble(),
        concentrationScore: (json['concentration_score'] as num).toDouble(),
        frequencyScore: (json['frequency_score'] as num).toDouble(),
        breakdownNotes:
            (json['breakdown_notes'] as List<dynamic>).cast<String>(),
      );
}
