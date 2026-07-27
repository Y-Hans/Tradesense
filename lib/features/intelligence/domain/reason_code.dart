library;

/// Machine-readable deterministic reason codes for Portfolio Risk evaluation.
enum RiskReasonCode {
  /// Single asset share > 50% of total portfolio equity.
  highConcentration('CONCENTRATION_HIGH'),

  /// Single asset share <= 50% of total portfolio equity.
  balancedConcentration('CONCENTRATION_BALANCED'),

  /// Proposed trade allocation > 25% of total portfolio equity.
  largePositionSize('POSITION_SIZE_LARGE'),

  /// Proposed trade allocation <= 25% of total portfolio equity.
  controlledPositionSize('POSITION_SIZE_CONTROLLED'),

  /// 24h market volatility swing > 5.0%.
  elevatedVolatility('VOLATILITY_ELEVATED'),

  /// 24h market volatility swing <= 5.0%.
  normalVolatility('VOLATILITY_NORMAL'),

  /// Trade lacks stop-loss protection.
  noStopLoss('NO_STOP_LOSS'),

  /// Trade includes protective stop-loss.
  stopLossPresent('STOP_LOSS_PRESENT');

  final String code;
  const RiskReasonCode(this.code);

  static RiskReasonCode fromCode(String code) {
    return RiskReasonCode.values.firstWhere(
      (e) => e.code == code,
      orElse: () => throw ArgumentError('Unknown RiskReasonCode: $code'),
    );
  }
}

/// Machine-readable deterministic reason codes for Trading Discipline evaluation.
enum DisciplineReasonCode {
  /// Unmanaged high portfolio risk score (> 60).
  poorRiskManagement('RISK_MANAGEMENT_POOR'),

  /// Controlled portfolio risk score (<= 60).
  goodRiskManagement('RISK_MANAGEMENT_GOOD'),

  /// Position size percentage > 10% of equity (penalized).
  excessivePositionSize('POSITION_SIZE_EXCESSIVE'),

  /// Position size percentage <= 10% of equity (full score).
  disciplinedPositionSize('POSITION_SIZE_DISCIPLINED'),

  /// Trade executed without stop-loss protection.
  missingStopLoss('NO_STOP_LOSS'),

  /// Used protective stop-loss.
  usedStopLoss('STOP_LOSS_USED'),

  /// Portfolio concentration > 50%.
  highConcentration('CONCENTRATION_HIGH'),

  /// Portfolio concentration <= 50%.
  controlledConcentration('CONCENTRATION_CONTROLLED'),

  /// High 24h trading frequency (> 5 trades) penalizing discipline score.
  highTradingFrequency('TRADING_FREQUENCY_HIGH'),

  /// Controlled 24h trading frequency (<= 5 trades).
  controlledTradingFrequency('TRADING_FREQUENCY_CONTROLLED');

  final String code;
  const DisciplineReasonCode(this.code);

  static DisciplineReasonCode fromCode(String code) {
    return DisciplineReasonCode.values.firstWhere(
      (e) => e.code == code,
      orElse: () => throw ArgumentError('Unknown DisciplineReasonCode: $code'),
    );
  }
}
