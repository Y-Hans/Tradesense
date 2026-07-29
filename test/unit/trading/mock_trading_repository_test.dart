import 'package:cryptoedu/core/providers/mocks/mock_market_repository.dart';
import 'package:cryptoedu/core/providers/mocks/mock_repositories.dart';
import 'package:cryptoedu/shared/models/trade.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('MockTradingRepository simulated order transitions', () {
    late MockMarketRepository marketRepo;
    late MockTradingRepository repository;

    setUp(() {
      marketRepo = MockMarketRepository();
      repository =
          MockTradingRepository(marketRepo, initialBalance: 10000000.0);
    });

    test('a virtual buy debits cash and creates a holding', () async {
      final trade = await repository.executeMarketBuy(
        symbol: 'BTC',
        quantity: 0.01,
        executionPriceInr: 5000000,
      );

      expect(trade.side, TradeSide.buy);
      expect(repository.wallet.balanceInr, 9950000); // 10,000,000 - 50,000
      expect(repository.holdings, hasLength(1));
      expect(repository.holdings.single.symbol, 'BTC');
      expect(repository.holdings.single.quantity, 0.01);
    });

    test('a virtual sell credits cash and reduces an open holding', () async {
      await repository.executeMarketBuy(
        symbol: 'ETH',
        quantity: 2,
        executionPriceInr: 10000,
      );

      final sell = await repository.executeMarketSell(
        symbol: 'ETH',
        quantity: 1,
        executionPriceInr: 12000,
      );

      expect(sell.side, TradeSide.sell);
      expect(repository.wallet.balanceInr,
          9992000); // 10,000,000 - 20,000 + 12,000 = 9,992,000
      expect(repository.holdings.single.quantity, 1);
      expect(await repository.getTradeHistory(), hasLength(2));
    });

    test('executeMarketBuy rejects quantity <= 0', () async {
      await expectLater(
        repository.executeMarketBuy(
          symbol: 'BTC',
          quantity: 0,
          executionPriceInr: 50000,
        ),
        throwsA(isA<Exception>()),
      );
    });

    test('executeMarketBuy rejects insufficient funds', () async {
      await expectLater(
        repository.executeMarketBuy(
          symbol: 'BTC',
          quantity: 300, // 300 * 50,000 = 15,000,000 > 10,000,000 balance
          executionPriceInr: 50000,
        ),
        throwsA(isA<Exception>()),
      );
    });

    test('executeMarketBuy rejects exceeding 25% max position limit', () async {
      // 10M balance. 25% is 2.5M.
      await expectLater(
        repository.executeMarketBuy(
          symbol: 'BTC',
          quantity: 1,
          executionPriceInr: 3000000.0, // Cost is 3M, > 2.5M
        ),
        throwsA(isA<Exception>()),
      );
    });

    test('executeMarketSell rejects overselling', () async {
      await repository.executeMarketBuy(
        symbol: 'BTC',
        quantity: 1,
        executionPriceInr: 2000000.0,
      );

      await expectLater(
        repository.executeMarketSell(
          symbol: 'BTC',
          quantity: 2,
          executionPriceInr: 2000000.0,
        ),
        throwsA(isA<Exception>()),
      );
    });

    test('Background ticker triggers stop-loss sell automatically', () async {
      await repository.executeMarketBuy(
        symbol: 'BTC',
        quantity: 1,
        executionPriceInr: 2000000.0,
        stopLossPriceInr: 1800000.0,
      );

      expect(repository.holdings.length, 1);
    });
  });
}
