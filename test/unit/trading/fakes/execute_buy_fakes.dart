import 'package:cryptoedu/core/contracts/market_provider.dart';
import 'package:cryptoedu/core/utils/financial_math.dart';
import 'package:cryptoedu/features/trading/application/execute_buy_contracts.dart';
import 'package:cryptoedu/shared/models/crypto_asset.dart';
import 'package:cryptoedu/shared/models/holding.dart';
import 'package:cryptoedu/shared/models/market_ticker.dart';
import 'package:cryptoedu/shared/models/trade.dart';
import 'package:cryptoedu/shared/models/virtual_wallet.dart';

class FakeExecuteBuyWalletRepository implements ExecuteBuyWalletRepository {
  final Map<String, PersistedVirtualWallet> wallets = {};
  PersistedVirtualWallet? forcedWallet;
  bool failLookup = false;
  int lookupCount = 0;

  void put({
    required String userId,
    required VirtualWallet wallet,
    String? version = 'v1',
    DateTime? updatedAt,
  }) {
    wallets[userId] = PersistedVirtualWallet(
      userId: userId,
      wallet: wallet,
      version: version,
      updatedAt: updatedAt,
    );
  }

  @override
  Future<PersistedVirtualWallet?> getWalletForUser(String userId) async {
    lookupCount += 1;
    if (failLookup) throw StateError('wallet lookup failed');
    return forcedWallet ?? wallets[userId];
  }
}

class FakeExecuteBuyHoldingRepository implements ExecuteBuyHoldingRepository {
  final Map<String, Holding> holdings = {};
  Holding? forcedHolding;
  bool failLookup = false;
  int lookupCount = 0;

  void put(Holding holding) {
    holdings[_key(holding.userId, holding.symbol)] = holding;
  }

  @override
  Future<Holding?> getHoldingForUserAsset({
    required String userId,
    required String symbol,
  }) async {
    lookupCount += 1;
    if (failLookup) throw StateError('holding lookup failed');
    return forcedHolding ?? holdings[_key(userId, symbol)];
  }

  String _key(String userId, String symbol) =>
      '$userId:${symbol.trim().toUpperCase()}';
}

class FakeMarketProvider implements MarketProvider {
  final Map<String, MarketTicker> tickers = {};
  bool failUnavailable = false;
  bool failRepository = false;
  int tickerLookupCount = 0;

  void putTicker(MarketTicker ticker) {
    tickers[ticker.symbol.trim().toUpperCase()] = ticker;
  }

  @override
  Future<MarketTicker> getTicker(String symbol) async {
    tickerLookupCount += 1;
    final normalized = symbol.trim().toUpperCase();
    if (failUnavailable) {
      throw MarketTickerUnavailableException(symbol: normalized);
    }
    if (failRepository) throw StateError('market repository failed');
    final ticker = tickers[normalized];
    if (ticker == null) {
      throw MarketTickerUnavailableException(symbol: normalized);
    }
    return ticker;
  }

  @override
  Future<List<CryptoAsset>> getSupportedAssets() async => const [];

  @override
  Future<Map<String, MarketTicker>> getAllTickers() async =>
      Map.unmodifiable(tickers);

  @override
  Future<List<MarketCandle>> getCandles(
    String symbol, {
    String interval = '1h',
    int limit = 100,
  }) async =>
      const [];

  @override
  Stream<MarketTicker> streamTicker(String symbol) async* {
    yield await getTicker(symbol);
  }
}

class FakeExecuteBuyClock implements ExecuteBuyClock {
  final DateTime fixedNow;
  int callCount = 0;

  FakeExecuteBuyClock(this.fixedNow);

  @override
  DateTime now() {
    callCount += 1;
    return fixedNow;
  }
}

class FakeExecuteBuyIdGenerator implements ExecuteBuyIdGenerator {
  final List<String> tradeIds;
  final List<String> holdingIds;
  int tradeIdCount = 0;
  int holdingIdCount = 0;

  FakeExecuteBuyIdGenerator({
    this.tradeIds = const ['trade_1'],
    this.holdingIds = const ['holding_1'],
  });

  @override
  String nextTradeId() => tradeIds[tradeIdCount++];

  @override
  String nextHoldingId({
    required String userId,
    required String symbol,
  }) =>
      holdingIds[holdingIdCount++];
}

enum FakeCommitMode {
  success,
  persistenceFailure,
  concurrencyConflict,
}

class FakeTradingTransactionRepository implements TradingTransactionRepository {
  final FakeExecuteBuyWalletRepository walletRepository;
  final FakeExecuteBuyHoldingRepository holdingRepository;
  final List<Trade> trades = [];
  FakeCommitMode mode = FakeCommitMode.success;
  void Function()? beforeValidation;
  int commitAttempts = 0;
  int successfulCommits = 0;

  FakeTradingTransactionRepository({
    required this.walletRepository,
    required this.holdingRepository,
  });

  @override
  Future<BuyTransactionCommitResult> commitBuy({
    required String userId,
    required VirtualWallet updatedWallet,
    required Holding updatedHolding,
    required Trade trade,
    required double expectedPreviousWalletBalanceInr,
    String? expectedWalletVersion,
    required DateTime executedAt,
  }) async {
    commitAttempts += 1;
    beforeValidation?.call();

    if (mode == FakeCommitMode.persistenceFailure) {
      return const BuyTransactionCommitFailure(
        BuyTransactionFailure(
          code: BuyTransactionFailureCode.persistenceFailure,
          message: 'Atomic BUY persistence failed.',
        ),
      );
    }
    if (mode == FakeCommitMode.concurrencyConflict) {
      return const BuyTransactionCommitFailure(
        BuyTransactionFailure(
          code: BuyTransactionFailureCode.concurrencyConflict,
          message: 'Wallet changed before BUY commit.',
        ),
      );
    }

    final currentWallet = walletRepository.wallets[userId];
    final expectedPaise =
        FinancialMath.inrToPaise(expectedPreviousWalletBalanceInr);
    final currentPaise = currentWallet == null
        ? null
        : FinancialMath.inrToPaise(currentWallet.wallet.balanceInr);
    final versionMatches = currentWallet?.version == expectedWalletVersion;
    if (currentWallet == null ||
        currentPaise != expectedPaise ||
        !versionMatches) {
      return const BuyTransactionCommitFailure(
        BuyTransactionFailure(
          code: BuyTransactionFailureCode.concurrencyConflict,
          message: 'Wallet changed before BUY commit.',
        ),
      );
    }

    walletRepository.wallets[userId] = PersistedVirtualWallet(
      userId: userId,
      wallet: updatedWallet,
      version: _nextVersion(currentWallet.version),
      updatedAt: executedAt,
    );
    holdingRepository.put(updatedHolding);
    trades.add(trade);
    successfulCommits += 1;

    return BuyTransactionCommitSuccess(
      confirmationId: 'commit_$successfulCommits',
      committedAt: executedAt,
    );
  }

  String _nextVersion(String? version) {
    final value = version ?? 'v0';
    final parsed = int.tryParse(value.replaceFirst('v', '')) ?? 0;
    return 'v${parsed + 1}';
  }
}
