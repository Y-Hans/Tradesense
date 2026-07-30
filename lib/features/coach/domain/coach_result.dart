import 'package:flutter/foundation.dart';
import '../../../shared/models/coach_request.dart';
import '../../../shared/models/discipline_score.dart';
import '../../../shared/models/risk_score.dart';
import '../../../shared/models/trade.dart';

/// Structured domain model representing the complete output of the AI Coach pipeline.
@immutable
class CoachResult {
  final Trade trade;
  final DisciplineScore disciplineScore;
  final RiskScore riskScore;
  final CoachResponse coachFeedback;

  const CoachResult({
    required this.trade,
    required this.disciplineScore,
    required this.riskScore,
    required this.coachFeedback,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CoachResult &&
          runtimeType == other.runtimeType &&
          trade.id == other.trade.id &&
          disciplineScore.score == other.disciplineScore.score &&
          riskScore.score == other.riskScore.score;

  @override
  int get hashCode =>
      trade.id.hashCode ^
      disciplineScore.score.hashCode ^
      riskScore.score.hashCode;
}
