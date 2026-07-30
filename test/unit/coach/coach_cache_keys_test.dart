import 'package:cryptoedu/features/coach/data/keys/coach_cache_keys.dart';
import 'package:cryptoedu/shared/models/coach_request.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('CoachCacheKeys Unit Tests', () {
    test('identical requests produce identical cache key', () {
      const request1 = CoachRequest(
        userId: 'user_123',
        tradeId: 'trade_abc',
        tradeContext: {
          'symbol': 'BTC',
          'side': 'buy',
          'quantity': 0.5,
          'execution_price_inr': 5000000.0,
          'total_trade_value_inr': 2500000.0,
          'has_stop_loss': true,
        },
        portfolioContext: {
          'total_equity_inr': 10000000.0,
          'virtual_cash_balance_inr': 7500000.0,
        },
        marketContext: {
          'risk_reason_codes': ['NORMAL_VOLATILITY'],
          'discipline_reason_codes': ['USED_STOP_LOSS'],
        },
        riskScore: 25,
        disciplineScore: 90,
      );

      const request2 = CoachRequest(
        userId: 'user_999', // Different userId
        tradeId: 'trade_xyz', // Different tradeId
        tradeContext: {
          'symbol': 'BTC',
          'side': 'buy',
          'quantity': 0.5,
          'execution_price_inr': 5000000.0,
          'total_trade_value_inr': 2500000.0,
          'has_stop_loss': true,
        },
        portfolioContext: {
          'total_equity_inr': 10000000.0,
          'virtual_cash_balance_inr': 7500000.0,
        },
        marketContext: {
          'risk_reason_codes': ['NORMAL_VOLATILITY'],
          'discipline_reason_codes': ['USED_STOP_LOSS'],
        },
        riskScore: 25,
        disciplineScore: 90,
      );

      final key1 = CoachCacheKeys.forRequest(request1);
      final key2 = CoachCacheKeys.forRequest(request2);

      expect(key1, equals(key2));
    });

    test('different trade facts produce different cache keys', () {
      const request1 = CoachRequest(
        userId: 'user_1',
        tradeId: 't1',
        tradeContext: {
          'symbol': 'BTC',
          'side': 'buy',
          'quantity': 0.5,
        },
        portfolioContext: {},
        marketContext: {},
        riskScore: 20,
        disciplineScore: 80,
      );

      const request2 = CoachRequest(
        userId: 'user_1',
        tradeId: 't1',
        tradeContext: {
          'symbol': 'ETH', // Different symbol
          'side': 'buy',
          'quantity': 0.5,
        },
        portfolioContext: {},
        marketContext: {},
        riskScore: 20,
        disciplineScore: 80,
      );

      final key1 = CoachCacheKeys.forRequest(request1);
      final key2 = CoachCacheKeys.forRequest(request2);

      expect(key1, isNot(equals(key2)));
    });

    test('cache keys exclude metadata/IDs and remain deterministic', () {
      const req = CoachRequest(
        userId: 'transient_user_id',
        tradeId: 'transient_trade_id',
        tradeContext: {'symbol': 'SOL', 'side': 'sell'},
        portfolioContext: {},
        marketContext: {},
        riskScore: 40,
        disciplineScore: 70,
      );

      final key = CoachCacheKeys.forRequest(req);
      expect(key, contains('SOL'));
      expect(key, contains('sell'));
      expect(key, isNot(contains('transient_user_id')));
      expect(key, isNot(contains('transient_trade_id')));
    });
  });
}
