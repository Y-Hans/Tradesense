import 'package:cryptoedu/features/coach/data/config/coach_cache_policy.dart';
import 'package:cryptoedu/features/coach/data/repositories/cached_coach_provider.dart';
import 'package:cryptoedu/features/coach/domain/coach_orchestrator.dart';
import 'package:cryptoedu/features/coach/providers/coach_cache_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Coach Cache Providers Unit Tests', () {
    test('coachCachePolicyProvider resolves default AI policy', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final policy = container.read(coachCachePolicyProvider);
      expect(policy, equals(CoachCachePolicyDefaults.defaultPolicy));
      expect(policy.ttl, equals(const Duration(hours: 24)));
      expect(policy.allowStale, isTrue);
      expect(policy.version, equals('v1'));
    });

    test('cachedAIProvider builds CachedCoachProvider instance', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final aiProvider = container.read(cachedAIProvider);
      expect(aiProvider, isA<CachedCoachProvider>());
    });

    test(
        'coachOrchestratorProvider builds CoachOrchestrator instance with cached AI provider',
        () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final orchestrator = container.read(coachOrchestratorProvider);
      expect(orchestrator, isA<CoachOrchestrator>());
    });
  });
}
