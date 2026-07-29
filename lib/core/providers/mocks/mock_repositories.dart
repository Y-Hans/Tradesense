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
import '../../../features/auth/domain/auth_exception.dart';

class MockTradingRepository implements TradingRepository {
  VirtualWallet _wallet = VirtualWallet.initial();
  final List<Holding> _holdings = [];
  final List<Trade> _trades = [];

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
  @override
  RiskScore calculateRiskScore({
    required Portfolio portfolio,
    required double proposedTradeSizeInr,
    required bool hasStopLoss,
    required double assetVolatility,
  }) {
    return RiskCalculator.compute(
      portfolio: portfolio,
      proposedTradeSizeInr: proposedTradeSizeInr,
      hasStopLoss: hasStopLoss,
      assetVolatility: assetVolatility,
    );
  }

  @override
  DisciplineScore calculateDisciplineScore({
    required RiskScore currentRiskScore,
    required double positionSizePercentage,
    required bool usedStopLoss,
    required double portfolioConcentration,
    required int tradeFrequency24h,
  }) {
    return DisciplineCalculator.compute(
      currentRiskScore: currentRiskScore,
      positionSizePercentage: positionSizePercentage,
      usedStopLoss: usedStopLoss,
      portfolioConcentration: portfolioConcentration,
      tradeFrequency24h: tradeFrequency24h,
    );
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
  final Map<String, String> _userCredentials = {
    'trader@cryptoedu.app': 'password123',
  };

  final Map<String, UserProfile> _userProfiles = {
    'trader@cryptoedu.app': UserProfile.initial(
      id: 'usr_mock_123',
      email: 'trader@cryptoedu.app',
      displayName: 'DisciplineTrader',
    ),
  };

  UserProfile? _currentUser;

  MockAuthRepository() {
    _currentUser = _userProfiles['trader@cryptoedu.app'];
  }

  /// Helper for testing to set or clear active user session directly
  void setCurrentUser(UserProfile? user) {
    _currentUser = user;
    if (user != null) {
      _userProfiles[user.email.toLowerCase()] = user;
    }
  }

  @override
  Future<UserProfile?> getCurrentUser() async => _currentUser;

  @override
  Future<UserProfile> signUp(
      {required String email,
      required String password,
      String? displayName}) async {
    final lowerEmail = email.trim().toLowerCase();
    if (_userCredentials.containsKey(lowerEmail)) {
      throw AuthException.userAlreadyExists();
    }
    _userCredentials[lowerEmail] = password;
    final profile = UserProfile.initial(
        id: 'usr_${DateTime.now().millisecondsSinceEpoch}',
        email: lowerEmail,
        displayName: displayName);
    _userProfiles[lowerEmail] = profile;
    _currentUser = profile;
    return _currentUser!;
  }

  @override
  Future<UserProfile> signIn(
      {required String email, required String password}) async {
    final lowerEmail = email.trim().toLowerCase();
    if (!_userCredentials.containsKey(lowerEmail) ||
        _userCredentials[lowerEmail] != password) {
      throw AuthException.invalidCredentials();
    }
    final profile = _userProfiles[lowerEmail] ??
        UserProfile.initial(
          id: 'usr_${DateTime.now().millisecondsSinceEpoch}',
          email: lowerEmail,
          displayName: lowerEmail.split('@').first,
        );
    _userProfiles[lowerEmail] = profile;
    _currentUser = profile;
    return _currentUser!;
  }

  @override
  Future<void> signOut() async {
    _currentUser = null;
  }

  @override
  Future<void> deleteAccount() async {
    if (_currentUser != null) {
      _userProfiles.remove(_currentUser!.email.toLowerCase());
      _userCredentials.remove(_currentUser!.email.toLowerCase());
    }
    _currentUser = null;
  }
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
