import 'package:flutter/foundation.dart';
import 'virtual_wallet.dart';
import 'holding.dart';

@immutable
class Portfolio {
  final VirtualWallet wallet;
  final List<Holding> holdings;
  final double totalRealisedPnlInr;

  const Portfolio({
    required this.wallet,
    required this.holdings,
    required this.totalRealisedPnlInr,
  });

  double get holdingsValueInr =>
      holdings.fold(0.0, (sum, h) => sum + h.currentValueInr);

  double get totalPortfolioValueInr => wallet.balanceInr + holdingsValueInr;

  double get totalUnrealisedPnlInr =>
      holdings.fold(0.0, (sum, h) => sum + h.unrealisedPnlInr);

  double get overallPnlPercent {
    final netGainInr = (totalPortfolioValueInr + totalRealisedPnlInr) -
        wallet.initialBalanceInr;
    return wallet.initialBalanceInr == 0
        ? 0.0
        : (netGainInr / wallet.initialBalanceInr) * 100.0;
  }

  Map<String, dynamic> toJson() => {
        'wallet': wallet.toJson(),
        'holdings': holdings.map((h) => h.toJson()).toList(),
        'total_realised_pnl_inr': totalRealisedPnlInr,
      };

  factory Portfolio.fromJson(Map<String, dynamic> json) => Portfolio(
        wallet: VirtualWallet.fromJson(json['wallet'] as Map<String, dynamic>),
        holdings: (json['holdings'] as List<dynamic>)
            .map((h) => Holding.fromJson(h as Map<String, dynamic>))
            .toList(),
        totalRealisedPnlInr: (json['total_realised_pnl_inr'] as num).toDouble(),
      );
}

@immutable
class PortfolioSnapshot {
  final DateTime timestamp;
  final double totalEquityInr;
  final double unrealisedPnlInr;
  final double realisedPnlInr;
  final int riskScore;
  final int disciplineScore;

  const PortfolioSnapshot({
    required this.timestamp,
    required this.totalEquityInr,
    required this.unrealisedPnlInr,
    required this.realisedPnlInr,
    required this.riskScore,
    required this.disciplineScore,
  });

  Map<String, dynamic> toJson() => {
        'timestamp': timestamp.toIso8601String(),
        'total_equity_inr': totalEquityInr,
        'unrealised_pnl_inr': unrealisedPnlInr,
        'realised_pnl_inr': realisedPnlInr,
        'risk_score': riskScore,
        'discipline_score': disciplineScore,
      };

  factory PortfolioSnapshot.fromJson(Map<String, dynamic> json) =>
      PortfolioSnapshot(
        timestamp: DateTime.parse(json['timestamp'] as String),
        totalEquityInr: (json['total_equity_inr'] as num).toDouble(),
        unrealisedPnlInr: (json['unrealised_pnl_inr'] as num).toDouble(),
        realisedPnlInr: (json['realised_pnl_inr'] as num).toDouble(),
        riskScore: (json['risk_score'] as num).toInt(),
        disciplineScore: (json['discipline_score'] as num).toInt(),
      );
}
