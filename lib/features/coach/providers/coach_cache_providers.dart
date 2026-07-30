import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/cache/domain/models/cache_policy.dart';
import '../../../core/cache/providers/cache_providers.dart';
import '../../../core/contracts/provider_contracts.dart';
import '../../../shared/models/coach_request.dart';
import '../data/config/coach_cache_policy.dart';
import '../data/repositories/cached_coach_provider.dart';
import '../data/serializers/coach_serializers.dart';
import '../domain/coach_orchestrator.dart';
import 'openrouter_providers.dart';

/// Provider for overriding the AIProvider in test or custom environments.
final aiProviderOverrideProvider = Provider<AIProvider?>((ref) => null);

/// Provider for default AI coach cache policy configuration.
final coachCachePolicyProvider = Provider<CachePolicy>((ref) {
  return CoachCachePolicyDefaults.defaultPolicy;
});

/// Cache repository provider for [CoachResponse].
final coachResponseCacheRepositoryProvider =
    createCacheRepositoryProvider<CoachResponse>(
  serializer: CoachResponseSerializer(),
);

/// Provider exposing [CachedCoachProvider] decorating an underlying [AIProvider].
final cachedAIProvider = Provider<AIProvider>((ref) {
  final customAiProvider = ref.watch(aiProviderOverrideProvider);
  final AIProvider baseProvider = customAiProvider ?? ref.watch(openRouterAIProvider);

  return CachedCoachProvider(
    innerProvider: baseProvider,
    cacheRepo: ref.watch(coachResponseCacheRepositoryProvider),
    defaultPolicy: ref.watch(coachCachePolicyProvider),
  );
});

/// Provider for [CoachOrchestrator] initialized with the cache-aware AI provider.
final coachOrchestratorProvider = Provider<CoachOrchestrator>((ref) {
  final customAiProvider = ref.watch(aiProviderOverrideProvider);
  final config = ref.watch(openRouterConfigProvider);
  final aiProvider = ref.watch(cachedAIProvider);

  return CoachOrchestrator(
    aiProvider: aiProvider,
    aiEnabled: customAiProvider != null || config.apiKey.isNotEmpty,
  );
});

