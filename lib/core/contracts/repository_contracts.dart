import '../../shared/models/user_profile.dart';
import '../../shared/models/trade.dart';
import '../../shared/models/holding.dart';
import '../../shared/models/portfolio.dart';
import '../../shared/models/risk_score.dart';
import '../../shared/models/discipline_score.dart';
import '../../shared/models/coach_request.dart';

import '../../features/trading/application/execute_buy_contracts.dart';
import '../../features/portfolio/application/execute_portfolio_contracts.dart';
import '../../features/trading/application/execute_trade_history_contracts.dart';

abstract class AuthRepository {
  Future<UserProfile?> getCurrentUser();
  Stream<UserProfile?> get authStateChanges;
  Future<UserProfile> signUp(
      {required String email, required String password, String? displayName});
  Future<UserProfile> signIn({required String email, required String password});
  Future<void> signOut();
  Future<void> deleteAccount();
}

abstract class TradingRepository implements
    ExecuteBuyWalletRepository,
    ExecuteBuyHoldingRepository,
    TradingTransactionRepository,
    ExecutePortfolioHoldingRepository,
    ExecutePortfolioTradeRepository,
    ExecuteTradeHistoryTradeRepository,
    ExecuteBuyIdGenerator {
  
  // Legacy methods (can be deprecated or removed later)
  Future<Trade> executeMarketBuy({
    required String symbol,
    required double quantity,
    required double executionPriceInr,
    double? stopLossPriceInr,
  });

  Future<Trade> executeMarketSell({
    required String symbol,
    required double quantity,
    required double executionPriceInr,
  });

  Future<List<Trade>> getTradeHistory();
}

abstract class PortfolioRepository {
  Future<Portfolio> getPortfolio();
  Future<List<Holding>> getHoldings();
  Future<List<PortfolioSnapshot>> getSnapshots();
}

abstract class IntelligenceRepository {
  RiskScore calculateRiskScore({
    required Portfolio portfolio,
    required double proposedTradeSizeInr,
    required bool hasStopLoss,
    required double assetVolatility,
  });

  DisciplineScore calculateDisciplineScore({
    required RiskScore currentRiskScore,
    required double positionSizePercentage,
    required bool usedStopLoss,
    required double portfolioConcentration,
    required int tradeFrequency24h,
  });

  Future<TradeAnalysis> analyzeTrade(Trade trade, Portfolio portfolio);
}
