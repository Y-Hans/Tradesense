import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/contracts/provider_contracts.dart';
import '../data/builders/openrouter_prompt_builder.dart';
import '../data/config/openrouter_config.dart';
import '../data/providers/openrouter_ai_provider.dart';

/// Provider for [OpenRouterConfig].
final openRouterConfigProvider = Provider<OpenRouterConfig>((ref) {
  return OpenRouterConfig.fromEnvironment();
});

/// Provider for [Dio] client instance configured for OpenRouter API requests.
final openRouterDioProvider = Provider<Dio>((ref) {
  final config = ref.watch(openRouterConfigProvider);
  return Dio(
    BaseOptions(
      baseUrl: config.baseUrl,
      connectTimeout: config.timeout,
      receiveTimeout: config.timeout,
      sendTimeout: config.timeout,
    ),
  );
});

/// Provider for [OpenRouterPromptBuilder].
final openRouterPromptBuilderProvider = Provider<OpenRouterPromptBuilder>((ref) {
  final config = ref.watch(openRouterConfigProvider);
  return OpenRouterPromptBuilder(promptVersion: config.promptVersion);
});

/// Provider exposing [OpenRouterAIProvider] implementation of [AIProvider].
final openRouterAIProvider = Provider<AIProvider>((ref) {
  final config = ref.watch(openRouterConfigProvider);
  final client = ref.watch(openRouterDioProvider);
  final promptBuilder = ref.watch(openRouterPromptBuilderProvider);

  return OpenRouterAIProvider(
    config: config,
    client: client,
    promptBuilder: promptBuilder,
  );
});
