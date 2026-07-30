import 'dart:async';
import '../../contracts/repository_contracts.dart';
import '../../contracts/provider_contracts.dart';
import '../../../shared/models/user_profile.dart';
import '../../../shared/models/virtual_wallet.dart';
import '../../../shared/models/holding.dart';
import '../../../shared/models/trade.dart';
import '../../../shared/models/portfolio.dart';
import '../../../shared/models/risk_score.dart';
import '../../../shared/models/discipline_score.dart';
import '../../../shared/models/coach_request.dart';
import '../../../shared/models/subscription_status.dart';
import '../../../shared/models/feature_flags.dart';
import '../../utils/risk_calculator.dart';
import '../../utils/discipline_calculator.dart';
import '../../events/domain_event_publisher.dart';
import '../../events/domain_events.dart';

class MockTradingRepository implements TradingRepository {
  VirtualWallet _wallet = VirtualWallet.initial();
  final List<Holding> _holdings = [];
  final List<Trade> _trades = [];
  final DomainEventPublisher? _eventPublisher;

  MockTradingRepository([this._eventPublisher]);

  VirtualWallet get wallet => _wallet;
  List<Holding> get holdings => List.unmodifiable(_holdings);

  @override
  Future<Trade> executeMarketBuy({
    required String symbol,
    required double quantity,
    required double executionPriceInr,
    double? stopLossPriceInr,
  }) async {
    final totalCost = quantity * executionPriceInr;
    if (_wallet.availableBalanceInr < totalCost) {
      throw Exception(
          'Insufficient funds. Available: ${_wallet.availableBalanceInr}, Required: $totalCost');
    }

    _wallet = _wallet.copyWith(balanceInr: _wallet.balanceInr - totalCost);

    final existingIndex = _holdings.indexWhere((h) => h.symbol == symbol);
    if (existingIndex >= 0) {
      final existing = _holdings[existingIndex];
      final newQty = existing.quantity + quantity;
      final newAvg =
          ((existing.quantity * existing.averageEntryPriceInr) + totalCost) /
              newQty;
      _holdings[existingIndex] = existing.copyWith(
        quantity: newQty,
        averageEntryPriceInr: newAvg,
        currentPriceInr: executionPriceInr,
      );
    } else {
      _holdings.add(Holding(
        id: 'h_${DateTime.now().millisecondsSinceEpoch}',
        userId: 'mock_user_1',
        symbol: symbol,
        quantity: quantity,
        averageEntryPriceInr: executionPriceInr,
        currentPriceInr: executionPriceInr,
      ));
    }

    final trade = Trade(
      id: 'tr_${DateTime.now().millisecondsSinceEpoch}',
      userId: 'mock_user_1',
      symbol: symbol,
      side: TradeSide.buy,
      type: OrderType.market,
      quantity: quantity,
      executionPriceInr: executionPriceInr,
      totalAmountInr: totalCost,
      stopLossPriceInr: stopLossPriceInr,
      timestamp: DateTime.now(),
      disciplineScoreAtTrade: stopLossPriceInr != null ? 85 : 45,
      riskScoreAtTrade: (totalCost / 100000.0 * 100.0).round().clamp(10, 90),
    );

    _trades.add(trade);
    _eventPublisher?.publish(
      TradeExecuted(
        tradeId: trade.id,
        userId: trade.userId,
        symbol: trade.symbol,
        side: 'buy',
        quantity: trade.quantity,
        executionPriceInr: trade.executionPriceInr,
        totalAmountInr: trade.totalAmountInr,
        hasStopLoss: trade.stopLossPriceInr != null,
        stopLossPriceInr: trade.stopLossPriceInr,
        occurredAt: trade.timestamp,
      ),
    );
    return trade;
  }

  @override
  Future<Trade> executeMarketSell({
    required String symbol,
    required double quantity,
    required double executionPriceInr,
  }) async {
    final existingIndex = _holdings.indexWhere((h) => h.symbol == symbol);
    if (existingIndex < 0 || _holdings[existingIndex].quantity < quantity) {
      throw Exception('Insufficient holding quantity for $symbol');
    }

    final existing = _holdings[existingIndex];
    final proceedInr = quantity * executionPriceInr;
    _wallet = _wallet.copyWith(balanceInr: _wallet.balanceInr + proceedInr);

    final remainingQty = existing.quantity - quantity;
    if (remainingQty <= 0.000001) {
      _holdings.removeAt(existingIndex);
    } else {
      _holdings[existingIndex] = existing.copyWith(quantity: remainingQty);
    }

    final trade = Trade(
      id: 'tr_${DateTime.now().millisecondsSinceEpoch}',
      userId: 'mock_user_1',
      symbol: symbol,
      side: TradeSide.sell,
      type: OrderType.market,
      quantity: quantity,
      executionPriceInr: executionPriceInr,
      totalAmountInr: proceedInr,
      timestamp: DateTime.now(),
      disciplineScoreAtTrade: 75,
      riskScoreAtTrade: 30,
    );

    _trades.add(trade);
    _eventPublisher?.publish(
      TradeExecuted(
        tradeId: trade.id,
        userId: trade.userId,
        symbol: trade.symbol,
        side: 'sell',
        quantity: trade.quantity,
        executionPriceInr: trade.executionPriceInr,
        totalAmountInr: trade.totalAmountInr,
        hasStopLoss: false,
        occurredAt: trade.timestamp,
      ),
    );
    return trade;
  }

  @override
  Future<List<Trade>> getTradeHistory() async =>
      List.unmodifiable(_trades.reversed);
}

class MockPortfolioRepository implements PortfolioRepository {
  final MockTradingRepository tradingRepository;

  MockPortfolioRepository(this.tradingRepository);

  @override
  Future<Portfolio> getPortfolio() async {
    return Portfolio(
      wallet: tradingRepository.wallet,
      holdings: tradingRepository.holdings,
      totalRealisedPnlInr: 0.0,
    );
  }

  @override
  Future<List<Holding>> getHoldings() async => tradingRepository.holdings;

  @override
  Future<List<PortfolioSnapshot>> getSnapshots() async {
    final portfolio = await getPortfolio();
    return [
      PortfolioSnapshot(
        timestamp: DateTime.now().subtract(const Duration(days: 1)),
        totalEquityInr: 100000.0,
        unrealisedPnlInr: 0.0,
        realisedPnlInr: 0.0,
        riskScore: 20,
        disciplineScore: 90,
      ),
      PortfolioSnapshot(
        timestamp: DateTime.now(),
        totalEquityInr: portfolio.totalPortfolioValueInr,
        unrealisedPnlInr: portfolio.totalUnrealisedPnlInr,
        realisedPnlInr: portfolio.totalRealisedPnlInr,
        riskScore: 35,
        disciplineScore: 78,
      ),
    ];
  }
}

class MockIntelligenceRepository implements IntelligenceRepository {
  final DomainEventPublisher? _eventPublisher;

  MockIntelligenceRepository([this._eventPublisher]);

  @override
  RiskScore calculateRiskScore({
    required Portfolio portfolio,
    required double proposedTradeSizeInr,
    required bool hasStopLoss,
    required double assetVolatility,
  }) {
    final score = RiskCalculator.compute(
      portfolio: portfolio,
      proposedTradeSizeInr: proposedTradeSizeInr,
      hasStopLoss: hasStopLoss,
      assetVolatility: assetVolatility,
    );

    _eventPublisher?.publish(
      RiskEvaluationCompleted(
        riskScore: score.score,
        riskLevel: score.level.name,
        reasonCodes: score.explanations,
        proposedTradeSizeInr: proposedTradeSizeInr,
        hasStopLoss: hasStopLoss,
      ),
    );

    return score;
  }

  @override
  DisciplineScore calculateDisciplineScore({
    required RiskScore currentRiskScore,
    required double positionSizePercentage,
    required bool usedStopLoss,
    required double portfolioConcentration,
    required int tradeFrequency24h,
  }) {
    final score = DisciplineCalculator.compute(
      currentRiskScore: currentRiskScore,
      positionSizePercentage: positionSizePercentage,
      usedStopLoss: usedStopLoss,
      portfolioConcentration: portfolioConcentration,
      tradeFrequency24h: tradeFrequency24h,
    );

    _eventPublisher?.publish(
      DisciplineEvaluationCompleted(
        disciplineScore: score.score,
        reasonCodes: score.breakdownNotes,
        positionSizePercentage: positionSizePercentage,
        usedStopLoss: usedStopLoss,
      ),
    );

    return score;
  }

  @override
  Future<TradeAnalysis> analyzeTrade(Trade trade, Portfolio portfolio) async {
    final risk = calculateRiskScore(
      portfolio: portfolio,
      proposedTradeSizeInr: trade.totalAmountInr,
      hasStopLoss: trade.stopLossPriceInr != null,
      assetVolatility: 3.5,
    );

    final discipline = calculateDisciplineScore(
      currentRiskScore: risk,
      positionSizePercentage:
          (trade.totalAmountInr / portfolio.totalPortfolioValueInr) * 100.0,
      usedStopLoss: trade.stopLossPriceInr != null,
      portfolioConcentration: 25.0,
      tradeFrequency24h: 2,
    );

    final mockCoachResponse = CoachResponse(
      whatDoneWell:
          'You maintained a reasonable position size (${((trade.totalAmountInr / portfolio.totalPortfolioValueInr) * 100).toStringAsFixed(1)}% of equity).',
      whatIncreasedRisk: trade.stopLossPriceInr == null
          ? 'Entering trade without a stop-loss order increased risk exposure.'
          : 'Asset volatility remains moderately high.',
      whatToLearn:
          'Risk management principles state that preserving capital comes before chasing simulated returns.',
      whatToConsiderNext:
          'Always define your risk-to-reward ratio before placing market orders.',
      aiProvider: 'MockCoachProvider',
      modelId: 'mock-v1',
      promptVersion: '1.0.0',
      latencyMs: 150,
    );

    return TradeAnalysis(
      tradeId: trade.id,
      disciplineScore: discipline,
      riskScore: risk,
      coachFeedback: mockCoachResponse,
      analyzedAt: DateTime.now(),
    );
  }
}

class MockAuthRepository implements AuthRepository {
  UserProfile? _currentUser = UserProfile.initial(
      id: 'usr_mock_123',
      email: 'trader@cryptoedu.app',
      displayName: 'DisciplineTrader');

  @override
  Future<UserProfile?> getCurrentUser() async => _currentUser;

  @override
  Future<UserProfile> signUp(
      {required String email,
      required String password,
      String? displayName}) async {
    _currentUser = UserProfile.initial(
        id: 'usr_${DateTime.now().millisecondsSinceEpoch}',
        email: email,
        displayName: displayName);
    return _currentUser!;
  }

  @override
  Future<UserProfile> signIn(
      {required String email, required String password}) async {
    _currentUser = UserProfile.initial(id: 'usr_mock_123', email: email);
    return _currentUser!;
  }

  @override
  Future<void> signOut() async => _currentUser = null;

  @override
  Future<void> deleteAccount() async => _currentUser = null;
}

class MockSubscriptionRepository implements SubscriptionProvider {
  bool _isPremium = false;

  @override
  Future<void> initialize() async {}

  @override
  Future<SubscriptionStatus> getStatus() async =>
      _isPremium ? SubscriptionStatus.premium() : SubscriptionStatus.free();

  @override
  Future<bool> purchasePremium() async {
    _isPremium = true;
    return true;
  }

  @override
  Future<bool> restorePurchases() async {
    _isPremium = true;
    return true;
  }
}

class MockRemoteConfigRepository implements RemoteConfigProvider {
  @override
  Future<void> fetchAndActivate() async {}

  @override
  Future<FeatureFlags> getFlags() async => const FeatureFlags();
}
