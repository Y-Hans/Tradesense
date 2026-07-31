import 'package:cryptoedu/features/trading/application/execute_buy_contracts.dart';
import 'package:cryptoedu/features/trading/application/execute_stop_loss_contracts.dart';
import 'package:cryptoedu/shared/models/holding.dart';
import 'package:cryptoedu/shared/models/market_ticker.dart';
import 'package:cryptoedu/shared/models/stop_loss_order.dart';

import 'execute_buy_fakes.dart';

class FakeExecuteStopLossWalletRepository extends FakeExecuteBuyWalletRepository
    implements ExecuteStopLossWalletRepository {
  final List<String> callLog;

  FakeExecuteStopLossWalletRepository({
    required this.callLog,
  });

  @override
  Future<PersistedVirtualWallet?> getWalletForUser(String userId) async {
    callLog.add('wallet:$userId');
    return super.getWalletForUser(userId);
  }
}

class FakeExecuteStopLossHoldingRepository
    implements ExecuteStopLossHoldingRepository {
  final List<String> callLog;
  final List<Holding> holdings = [];
  bool failLookup = false;
  int lookupCount = 0;
  int persistenceCount = 0;

  FakeExecuteStopLossHoldingRepository({
    required this.callLog,
  });

  void put(Holding holding) {
    holdings.add(holding);
  }

  @override
  Future<List<Holding>> getHoldingsForUser(String userId) async {
    callLog.add('holdings:$userId');
    lookupCount += 1;
    if (failLookup) throw StateError('holdings lookup failed');
    return holdings;
  }

  Future<void> persist() async {
    persistenceCount += 1;
  }
}

class FakeExecuteStopLossOrderRepository
    implements ExecuteStopLossOrderRepository {
  final List<String> callLog;
  final List<StopLossOrder> orders = [];
  bool failLookup = false;
  int lookupCount = 0;
  int persistenceCount = 0;

  FakeExecuteStopLossOrderRepository({
    required this.callLog,
  });

  void put(StopLossOrder order) {
    orders.add(order);
  }

  @override
  Future<List<StopLossOrder>> getActiveStopLossOrdersForUser(
    String userId,
  ) async {
    callLog.add('orders:$userId');
    lookupCount += 1;
    if (failLookup) throw StateError('stop-loss lookup failed');
    return orders;
  }

  Future<void> persist() async {
    persistenceCount += 1;
  }
}

class FakeExecuteStopLossMarketProvider extends FakeMarketProvider {
  final List<String> callLog;
  final List<String> requestedSymbols = [];

  FakeExecuteStopLossMarketProvider({
    required this.callLog,
  });

  @override
  Future<MarketTicker> getTicker(String symbol) async {
    final normalized = symbol.trim().toUpperCase();
    callLog.add('ticker:$normalized');
    requestedSymbols.add(normalized);
    return super.getTicker(symbol);
  }
}

class FakeExecuteStopLossClock implements ExecuteStopLossClock {
  final DateTime fixedNow;
  int callCount = 0;

  FakeExecuteStopLossClock(this.fixedNow);

  @override
  DateTime now() {
    callCount += 1;
    return fixedNow;
  }
}
