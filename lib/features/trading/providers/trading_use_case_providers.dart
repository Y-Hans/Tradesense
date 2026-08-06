import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers/app_providers.dart';
import '../../../core/providers/mocks/trading_transaction_adapter.dart';
import '../../../core/providers/mocks/mock_repositories.dart';
import '../application/execute_buy_use_case.dart';
import '../application/execute_sell_use_case.dart';
import '../application/execute_buy_contracts.dart';

import '../domain/trading_domain_service.dart';

final tradingTransactionAdapterProvider = Provider<TradingTransactionAdapter>((ref) {
  final repo = ref.watch(tradingRepositoryProvider) as MockTradingRepository;
  return TradingTransactionAdapter(repo);
});

final tradingDomainServiceProvider = Provider<TradingDomainService>((ref) {
  return TradingDomainService();
});

final executeBuyUseCaseProvider = Provider<ExecuteBuyUseCase>((ref) {
  final adapter = ref.watch(tradingTransactionAdapterProvider);
  final marketProvider = ref.watch(marketRepositoryProvider);
  final domainService = ref.watch(tradingDomainServiceProvider);
  
  return ExecuteBuyUseCase(
    walletRepository: adapter,
    holdingRepository: adapter,
    marketProvider: marketProvider,
    transactionRepository: adapter,
    tradingDomainService: domainService,
    clock: const SystemExecuteBuyClock(),
    idGenerator: _DefaultIdGenerator(),
  );
});

final executeSellUseCaseProvider = Provider<ExecuteSellUseCase>((ref) {
  final adapter = ref.watch(tradingTransactionAdapterProvider);
  final marketProvider = ref.watch(marketRepositoryProvider);
  final domainService = ref.watch(tradingDomainServiceProvider);

  return ExecuteSellUseCase(
    walletRepository: adapter,
    holdingRepository: adapter,
    marketProvider: marketProvider,
    transactionRepository: adapter,
    tradingDomainService: domainService,
    clock: const SystemExecuteBuyClock(),
    idGenerator: _DefaultIdGenerator(),
  );
});

class _DefaultIdGenerator implements ExecuteBuyIdGenerator {
  @override
  String nextTradeId() => 'tr_${DateTime.now().millisecondsSinceEpoch}';

  @override
  String nextHoldingId({required String userId, required String symbol}) => '${userId}_$symbol';
}
