import 'package:cryptoedu/features/coach/data/config/openrouter_config.dart';
import 'package:cryptoedu/features/coach/data/providers/openrouter_ai_provider.dart';
import 'package:cryptoedu/features/coach/data/repositories/cached_coach_provider.dart';
import 'package:cryptoedu/features/coach/domain/coach_orchestrator.dart';
import 'package:cryptoedu/features/coach/providers/coach_cache_providers.dart';
import 'package:cryptoedu/features/coach/providers/openrouter_providers.dart';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('OpenRouter Providers Unit Tests', () {
    test('openRouterConfigProvider resolves default environment config', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final config = container.read(openRouterConfigProvider);
      expect(config, isA<OpenRouterConfig>());
      expect(config.baseUrl, equals('https://openrouter.ai/api/v1'));
      expect(config.modelId, equals('anthropic/claude-3.5-sonnet'));
      expect(config.promptVersion, equals('v1.0.0'));
    });

    test('openRouterDioProvider resolves Dio instance', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final dio = container.read(openRouterDioProvider);
      expect(dio, isA<Dio>());
    });

    test('openRouterAIProvider builds OpenRouterAIProvider instance', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final aiProvider = container.read(openRouterAIProvider);
      expect(aiProvider, isA<OpenRouterAIProvider>());
    });

    test('cachedAIProvider wraps openRouterAIProvider by default', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final cachedProvider = container.read(cachedAIProvider);
      expect(cachedProvider, isA<CachedCoachProvider>());
    });

    test('coachOrchestratorProvider builds CoachOrchestrator instance', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final orchestrator = container.read(coachOrchestratorProvider);
      expect(orchestrator, isA<CoachOrchestrator>());
    });
  });
}
