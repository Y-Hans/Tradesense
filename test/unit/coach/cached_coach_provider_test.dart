import 'package:cryptoedu/core/cache/data/repositories/default_cache_repository.dart';
import 'package:cryptoedu/core/cache/data/storage/in_memory_cache_storage.dart';
import 'package:cryptoedu/core/cache/domain/contracts/cache_repository.dart';
import 'package:cryptoedu/core/cache/domain/models/cache_policy.dart';
import 'package:cryptoedu/core/contracts/provider_contracts.dart';
import 'package:cryptoedu/features/coach/data/config/coach_cache_policy.dart';
import 'package:cryptoedu/features/coach/data/repositories/cached_coach_provider.dart';
import 'package:cryptoedu/features/coach/data/serializers/coach_serializers.dart';
import 'package:cryptoedu/shared/models/coach_request.dart';
import 'package:flutter_test/flutter_test.dart';

class FakeAIProvider implements AIProvider {
  int generateCallCount = 0;
  bool shouldThrow = false;
  CoachResponse responseToReturn = const CoachResponse(
    whatDoneWell: 'Executed order with defined boundaries.',
    whatIncreasedRisk: 'None detected.',
    whatToLearn: 'Maintain continuous discipline.',
    whatToConsiderNext: 'Monitor market updates.',
    aiProvider: 'FakeAI',
    modelId: 'fake-model-1',
    promptVersion: 'v1',
    latencyMs: 100,
  );

  @override
  Future<CoachResponse> generateCoachFeedback(CoachRequest request) async {
    generateCallCount++;
    if (shouldThrow) {
      throw Exception('AI Provider service unavailable');
    }
    return responseToReturn;
  }
}

void main() {
  late FakeAIProvider fakeInnerProvider;
  late CacheRepository<CoachResponse> cacheRepo;
  late DateTime currentTime;
  late CachedCoachProvider cachedCoachProvider;

  const sampleRequest = CoachRequest(
    userId: 'u1',
    tradeId: 't1',
    tradeContext: {
      'symbol': 'BTC',
      'side': 'buy',
      'quantity': 1.0,
      'execution_price_inr': 6000000.0,
      'total_trade_value_inr': 6000000.0,
      'has_stop_loss': true,
    },
    portfolioContext: {
      'total_equity_inr': 10000000.0,
      'virtual_cash_balance_inr': 4000000.0,
    },
    marketContext: {
      'risk_reason_codes': [],
      'discipline_reason_codes': [],
    },
    riskScore: 20,
    disciplineScore: 85,
  );

  setUp(() {
    fakeInnerProvider = FakeAIProvider();
    currentTime = DateTime(2026, 1, 1, 12, 0, 0);

    cacheRepo = DefaultCacheRepository<CoachResponse>(
      storage: InMemoryCacheStorage(),
      serializer: CoachResponseSerializer(),
      clock: () => currentTime,
    );

    cachedCoachProvider = CachedCoachProvider(
      innerProvider: fakeInnerProvider,
      cacheRepo: cacheRepo,
      defaultPolicy: CoachCachePolicyDefaults.defaultPolicy,
    );
  });

  group('CachedCoachProvider Unit Tests', () {
    test('Cache Miss: fetches fresh response from inner provider and caches it',
        () async {
      final response =
          await cachedCoachProvider.generateCoachFeedback(sampleRequest);

      expect(response.whatDoneWell,
          equals('Executed order with defined boundaries.'));
      expect(fakeInnerProvider.generateCallCount, equals(1));

      // Subsequent call should hit cache and NOT invoke inner provider again
      final secondResponse =
          await cachedCoachProvider.generateCoachFeedback(sampleRequest);
      expect(secondResponse.whatDoneWell,
          equals('Executed order with defined boundaries.'));
      expect(fakeInnerProvider.generateCallCount, equals(1)); // Still 1
    });

    test(
        'Cache Hit: returns cached data immediately without calling inner provider',
        () async {
      // Warm up cache
      await cachedCoachProvider.generateCoachFeedback(sampleRequest);
      expect(fakeInnerProvider.generateCallCount, equals(1));

      // Execute hit call
      final cachedResponse =
          await cachedCoachProvider.generateCoachFeedback(sampleRequest);
      expect(cachedResponse.whatDoneWell,
          equals(fakeInnerProvider.responseToReturn.whatDoneWell));
      expect(fakeInnerProvider.generateCallCount, equals(1));
    });

    test('Expired Cache: attempts fresh generation and updates cache',
        () async {
      // 1. Initial write
      await cachedCoachProvider.generateCoachFeedback(sampleRequest);
      expect(fakeInnerProvider.generateCallCount, equals(1));

      // 2. Advance clock beyond 24h TTL
      currentTime = currentTime.add(const Duration(hours: 25));

      // 3. Update inner provider response to verify refresh
      fakeInnerProvider.responseToReturn = const CoachResponse(
        whatDoneWell: 'Refreshed coaching after TTL expiration.',
        whatIncreasedRisk: 'None',
        whatToLearn: 'Keep learning',
        whatToConsiderNext: 'Proceed',
        aiProvider: 'FakeAI',
        modelId: 'fake-model-2',
        promptVersion: 'v2',
        latencyMs: 150,
      );

      final freshResponse =
          await cachedCoachProvider.generateCoachFeedback(sampleRequest);

      expect(freshResponse.whatDoneWell,
          equals('Refreshed coaching after TTL expiration.'));
      expect(fakeInnerProvider.generateCallCount, equals(2));
    });

    test(
        'Stale Cache Fallback: returns stale cached response when fresh generation fails and allowStale is true',
        () async {
      // 1. Initial write
      await cachedCoachProvider.generateCoachFeedback(sampleRequest);

      // 2. Advance time past TTL
      currentTime = currentTime.add(const Duration(hours: 30));

      // 3. Configure inner provider to fail
      fakeInnerProvider.shouldThrow = true;

      // 4. Call provider - should fall back to stale cached response gracefully
      final fallbackResponse = await cachedCoachProvider.generateCoachFeedback(
        sampleRequest,
        policy:
            CachePolicy.withTtl(const Duration(hours: 24), allowStale: true),
      );

      expect(fallbackResponse.whatDoneWell,
          equals('Executed order with defined boundaries.'));
      expect(fakeInnerProvider.generateCallCount, equals(2));
    });

    test(
        'Generation Failure without Cache: rethrows exception when no cache entry exists',
        () async {
      fakeInnerProvider.shouldThrow = true;

      await expectLater(
        cachedCoachProvider.generateCoachFeedback(sampleRequest),
        throwsA(isA<Exception>()),
      );
      expect(fakeInnerProvider.generateCallCount, equals(1));
    });
  });
}
