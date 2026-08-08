import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../features/trading/application/execute_buy_use_case.dart';
import '../../features/trading/application/execute_sell_use_case.dart';
import '../../features/trading/application/execute_stop_loss_use_case.dart';
import '../../features/trading/application/execute_trade_history_use_case.dart';
import '../../features/portfolio/application/execute_portfolio_use_case.dart';
import '../../features/trading/domain/trading_domain_service.dart';
import '../../features/portfolio/domain/portfolio_engine.dart';
import '../../features/portfolio/domain/portfolio_engine_result.dart';
import '../../features/portfolio/application/execute_portfolio_result.dart';
import '../../features/trading/domain/stop_loss_engine.dart';
import '../../features/trading/domain/trade_history_engine.dart';
import '../../features/trading/application/execute_trade_history_result.dart';
import '../../features/trading/application/execute_buy_contracts.dart';
import '../../features/trading/application/execute_sell_contracts.dart';
import '../../features/portfolio/application/execute_portfolio_contracts.dart';
import '../../features/trading/application/execute_trade_history_contracts.dart';
import '../../features/trading/application/execute_stop_loss_contracts.dart';
import 'app_providers.dart';

final systemClockProvider = Provider<ExecuteBuyClock>((ref) => const SystemExecuteBuyClock());

final tradingDomainServiceProvider = Provider<TradingDomainService>((ref) {
  return const TradingDomainService();
});

final portfolioEngineProvider = Provider<PortfolioEngine>((ref) {
  return const PortfolioEngine();
});

final executeBuyUseCaseProvider = Provider<ExecuteBuyUseCase>((ref) {
  final tradingRepo = ref.watch(tradingRepositoryProvider);
  return ExecuteBuyUseCase(
    walletRepository: tradingRepo,
    holdingRepository: tradingRepo,
    marketProvider: ref.watch(marketRepositoryProvider),
    transactionRepository: tradingRepo,
    tradingDomainService: ref.watch(tradingDomainServiceProvider),
    clock: ref.watch(systemClockProvider),
    idGenerator: tradingRepo,
  );
});

final executeSellUseCaseProvider = Provider<ExecuteSellUseCase>((ref) {
  final tradingRepo = ref.watch(tradingRepositoryProvider);
  return ExecuteSellUseCase(
    walletRepository: tradingRepo,
    holdingRepository: tradingRepo,
    marketProvider: ref.watch(marketRepositoryProvider),
    transactionRepository: tradingRepo,
    tradingDomainService: ref.watch(tradingDomainServiceProvider),
    clock: ref.watch(systemClockProvider) as ExecuteSellClock,
    idGenerator: tradingRepo as ExecuteSellIdGenerator,
  );
});

final executeStopLossUseCaseProvider = Provider<ExecuteStopLossUseCase>((ref) {
  final tradingRepo = ref.watch(tradingRepositoryProvider);
  return ExecuteStopLossUseCase(
    walletRepository: tradingRepo as ExecuteStopLossWalletRepository,
    holdingRepository: tradingRepo as ExecuteStopLossHoldingRepository,
    stopLossOrderRepository: tradingRepo as ExecuteStopLossOrderRepository,
    marketProvider: ref.watch(marketRepositoryProvider),
    executeSellUseCase: ref.watch(executeSellUseCaseProvider),
    stopLossEngine: const StopLossEngine(),
    clock: ref.watch(systemClockProvider) as ExecuteStopLossClock,
  );
});

final executePortfolioUseCaseProvider = Provider<ExecutePortfolioUseCase>((ref) {
  final tradingRepo = ref.watch(tradingRepositoryProvider);
  return ExecutePortfolioUseCase(
    walletRepository: tradingRepo as ExecutePortfolioWalletRepository,
    holdingRepository: tradingRepo as ExecutePortfolioHoldingRepository,
    tradeRepository: tradingRepo as ExecutePortfolioTradeRepository,
    marketProvider: ref.watch(marketRepositoryProvider),
    portfolioEngine: ref.watch(portfolioEngineProvider),
    clock: ref.watch(systemClockProvider) as ExecutePortfolioClock,
  );
});

final executeTradeHistoryUseCaseProvider = Provider<ExecuteTradeHistoryUseCase>((ref) {
  final tradingRepo = ref.watch(tradingRepositoryProvider);
  return ExecuteTradeHistoryUseCase(
    walletRepository: tradingRepo as ExecuteTradeHistoryWalletRepository,
    tradeRepository: tradingRepo as ExecuteTradeHistoryTradeRepository,
    tradeHistoryEngine: const TradeHistoryEngine(),
    clock: ref.watch(systemClockProvider) as ExecuteTradeHistoryClock,
  );
});

final portfolioSnapshotProvider = FutureProvider((ref) async {
  final useCase = ref.watch(executePortfolioUseCaseProvider);
  final authRepo = ref.watch(authRepositoryProvider);
  final user = await authRepo.getCurrentUser();
  if (user == null) throw Exception('Not logged in');

  final result = await useCase.execute(ExecutePortfolioRequest(userId: user.id));
  if (result is ExecutePortfolioSuccess) {
    return result.snapshot;
  } else if (result is ExecutePortfolioDomainRejected) {
    throw Exception('Domain rejection: ${result.failure.message}');
  } else if (result is ExecutePortfolioApplicationFailed) {
    throw Exception('Application failure: ${result.failure.message}');
  }
  throw Exception('Unknown portfolio error');
});

final tradeHistorySnapshotProvider = FutureProvider((ref) async {
  final useCase = ref.watch(executeTradeHistoryUseCaseProvider);
  final authRepo = ref.watch(authRepositoryProvider);
  final user = await authRepo.getCurrentUser();
  if (user == null) throw Exception('Not logged in');

  final result = await useCase.execute(ExecuteTradeHistoryRequest(userId: user.id));
  if (result is ExecuteTradeHistorySuccess) {
    return result.snapshot;
  } else if (result is ExecuteTradeHistoryDomainRejected) {
    throw Exception('Domain rejection: ${result.failure.message}');
  } else if (result is ExecuteTradeHistoryApplicationFailed) {
    throw Exception('Application failure: ${result.failure.message}');
  }
  throw Exception('Unknown trade history error');
});

