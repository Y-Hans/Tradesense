# SHARED CONTRACTS & INTERFACES

**Status**: Verified & Synchronized  
**Lead Owner**: Yajat (Shared Contracts / Core Architecture)  

---

## 1. Repository Contracts (`lib/core/contracts/repository_contracts.dart`)

```dart
abstract class AuthRepository {
  Future<UserProfile?> getCurrentUser();
  Future<UserProfile> signUp({required String email, required String password, String? displayName});
  Future<UserProfile> signIn({required String email, required String password});
  Future<void> signOut();
  Future<void> deleteAccount();
}

abstract class TradingRepository {
  Future<Trade> executeMarketBuy({required String symbol, required double quantity, required double executionPriceInr, double? stopLossPriceInr});
  Future<Trade> executeMarketSell({required String symbol, required double quantity, required double executionPriceInr});
  Future<List<Trade>> getTradeHistory();
}

abstract class PortfolioRepository {
  Future<Portfolio> getPortfolio();
  Future<List<Holding>> getHoldings();
  Future<List<PortfolioSnapshot>> getSnapshots();
}

abstract class IntelligenceRepository {
  RiskScore calculateRiskScore({required Portfolio portfolio, required double proposedTradeSizeInr, required bool hasStopLoss, required double assetVolatility});
  DisciplineScore calculateDisciplineScore({required RiskScore currentRiskScore, required double positionSizePercentage, required bool usedStopLoss, required double portfolioConcentration, required int tradeFrequency24h});
  Future<TradeAnalysis> analyzeTrade(Trade trade, Portfolio portfolio);
}
```

---

## 2. Dev 4 Inter-Domain Contracts

- **Wallet Contract (`WalletContract`)**: Allows Dev 4's account initializer to seed the starting balance (**₹100,000 VIRTUAL**) without modifying or coupling to Dev 2's internal trading engine arithmetic.
- **Contract Stability**: All core contracts remain fully valid and unbroken.
