import '../../../../core/contracts/provider_contracts.dart';
import '../../../../core/cache/domain/contracts/cache_repository.dart';
import '../../../../core/cache/domain/models/cache_policy.dart';
import '../../../../core/cache/domain/models/cache_result.dart';
import '../../../../shared/models/coach_request.dart';
import '../config/coach_cache_policy.dart';
import '../keys/coach_cache_keys.dart';

/// Cache-aware decorator around an [AIProvider] implementation.
///
/// Implements [AIProvider] by wrapping an inner provider and transparently managing
/// read, write, expiration, and stale fallback operations against a [CacheRepository<CoachResponse>].
class CachedCoachProvider implements AIProvider {
  final AIProvider _innerProvider;
  final CacheRepository<CoachResponse> _cacheRepo;
  final CachePolicy _defaultPolicy;

  CachedCoachProvider({
    required AIProvider innerProvider,
    required CacheRepository<CoachResponse> cacheRepo,
    CachePolicy? defaultPolicy,
  })  : _innerProvider = innerProvider,
        _cacheRepo = cacheRepo,
        _defaultPolicy =
            defaultPolicy ?? CoachCachePolicyDefaults.defaultPolicy;

  @override
  Future<CoachResponse> generateCoachFeedback(
    CoachRequest request, {
    CachePolicy? policy,
  }) async {
    final effectivePolicy = policy ?? _defaultPolicy;
    final key = CoachCacheKeys.forRequest(request);

    // 1. Read existing cache entry
    final cacheResult = await _cacheRepo.get(key, policy: effectivePolicy);

    // 2. Valid non-expired cache hit
    if (cacheResult is CacheHit<CoachResponse> && !cacheResult.isStale) {
      return cacheResult.value;
    }

    // Retain stale cached payload if present for fallback
    final staleResponse = cacheResult.dataOrNull;

    // 3. Attempt fresh generation via underlying AI provider
    try {
      final freshResponse =
          await _innerProvider.generateCoachFeedback(request);
      await _cacheRepo.set(key, freshResponse, policy: effectivePolicy);
      return freshResponse;
    } catch (error) {
      // 4. Fallback to stale response if allowed by policy and available
      if (effectivePolicy.allowStale && staleResponse != null) {
        return staleResponse;
      }
      rethrow;
    }
  }
}
