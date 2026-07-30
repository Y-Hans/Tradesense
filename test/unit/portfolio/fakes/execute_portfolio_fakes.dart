import 'package:cryptoedu/features/portfolio/application/execute_portfolio_contracts.dart';
import 'package:cryptoedu/features/trading/application/execute_buy_contracts.dart';
import 'package:cryptoedu/shared/models/holding.dart';
import 'package:cryptoedu/shared/models/market_ticker.dart';
import 'package:cryptoedu/shared/models/trade.dart';

import '../../trading/fakes/execute_buy_fakes.dart';

class FakeExecutePortfolioWalletRepository
    extends FakeExecuteBuyWalletRepository
    implements ExecutePortfolioWalletRepository {
  final List<String> callLog;
  int commitSnapshotCount = 0;

  FakeExecutePortfolioWalletRepository({
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

class FakeExecutePortfolioHoldingRepository
    implements ExecutePortfolioHoldingRepository {
  final List<String> callLog;
  final List<Holding> holdings = [];
  bool failLookup = false;
  int lookupCount = 0;
  int commitSnapshotCount = 0;

  FakeExecutePortfolioHoldingRepository({
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

  Future<void> commitSnapshot() async {
    commitSnapshotCount += 1;
  }
}

class FakeExecutePortfolioTradeRepository
    implements ExecutePortfolioTradeRepository {
  final List<String> callLog;
  final List<Trade> trades = [];
  bool failLookup = false;
  int lookupCount = 0;
  int commitSnapshotCount = 0;

  FakeExecutePortfolioTradeRepository({
    required this.callLog,
  });

  void put(Trade trade) {
    trades.add(trade);
  }

  @override
  Future<List<Trade>> getTradesForUser(String userId) async {
    callLog.add('trades:$userId');
    lookupCount += 1;
    if (failLookup) throw StateError('trades lookup failed');
    return trades;
  }

  Future<void> commitSnapshot() async {
    commitSnapshotCount += 1;
  }
}

class FakeExecutePortfolioMarketProvider extends FakeMarketProvider {
  final List<String> callLog;
  final List<String> requestedSymbols = [];

  FakeExecutePortfolioMarketProvider({
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

class FakeExecutePortfolioClock implements ExecutePortfolioClock {
  final DateTime fixedNow;
  int callCount = 0;

  FakeExecutePortfolioClock(this.fixedNow);

  @override
  DateTime now() {
    callCount += 1;
    return fixedNow;
  }
}
