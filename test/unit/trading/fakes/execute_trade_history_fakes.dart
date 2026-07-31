import 'package:cryptoedu/features/trading/application/execute_buy_contracts.dart';
import 'package:cryptoedu/features/trading/application/execute_trade_history_contracts.dart';
import 'package:cryptoedu/shared/models/trade.dart';

import 'execute_buy_fakes.dart';

class FakeExecuteTradeHistoryWalletRepository
    extends FakeExecuteBuyWalletRepository
    implements ExecuteTradeHistoryWalletRepository {
  final List<String> callLog;
  int commitSnapshotCount = 0;

  FakeExecuteTradeHistoryWalletRepository({
    required this.callLog,
  });

  @override
  Future<PersistedVirtualWallet?> getWalletForUser(String userId) async {
    callLog.add('wallet:$userId');
    return super.getWalletForUser(userId);
  }

  Future<void> commitSnapshot() async {
    commitSnapshotCount += 1;
  }
}

class FakeExecuteTradeHistoryTradeRepository
    implements ExecuteTradeHistoryTradeRepository {
  final List<String> callLog;
  final List<Trade> trades = [];
  bool failLookup = false;
  int lookupCount = 0;
  int commitSnapshotCount = 0;

  FakeExecuteTradeHistoryTradeRepository({
    required this.callLog,
  });

  void put(Trade trade) {
    trades.add(trade);
  }

  @override
  Future<List<Trade>> getTradesForUser(String userId) async {
    callLog.add('trades:$userId');
    lookupCount += 1;
    if (failLookup) throw StateError('trade history lookup failed');
    return trades;
  }

  Future<void> commitSnapshot() async {
    commitSnapshotCount += 1;
  }
}

class FakeExecuteTradeHistoryClock implements ExecuteTradeHistoryClock {
  final DateTime fixedNow;
  int callCount = 0;

  FakeExecuteTradeHistoryClock(this.fixedNow);

  @override
  DateTime now() {
    callCount += 1;
    return fixedNow;
  }
}
