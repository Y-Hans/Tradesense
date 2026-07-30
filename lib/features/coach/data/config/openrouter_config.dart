import 'package:flutter/foundation.dart';

/// Configuration for the OpenRouter AI Provider.
///
/// Encapsulates environment-driven settings, API key credentials, model parameters,
/// base URL endpoints, and network timeout settings.
@immutable
class OpenRouterConfig {
  /// OpenRouter API Key used for Bearer token authorization.
  final String apiKey;

  /// OpenRouter model identifier (e.g. 'anthropic/claude-3.5-sonnet').
  final String modelId;

  /// OpenRouter API base URL (defaults to 'https://openrouter.ai/api/v1').
  final String baseUrl;

  /// Version identifier for the prompt template.
  final String promptVersion;

  /// Network request timeout.
  final Duration timeout;

  const OpenRouterConfig({
    required this.apiKey,
    this.modelId = 'anthropic/claude-3.5-sonnet',
    this.baseUrl = 'https://openrouter.ai/api/v1',
    this.promptVersion = 'v1.0.0',
    this.timeout = const Duration(seconds: 15),
  });

  /// Constructs [OpenRouterConfig] reading default values from compile-time environment flags.
  factory OpenRouterConfig.fromEnvironment() {
    return const OpenRouterConfig(
      apiKey: String.fromEnvironment('OPENROUTER_API_KEY', defaultValue: ''),
      modelId: String.fromEnvironment(
        'OPENROUTER_MODEL_ID',
        defaultValue: 'anthropic/claude-3.5-sonnet',
      ),
      baseUrl: String.fromEnvironment(
        'OPENROUTER_BASE_URL',
        defaultValue: 'https://openrouter.ai/api/v1',
      ),
    );
  }

  OpenRouterConfig copyWith({
    String? apiKey,
    String? modelId,
    String? baseUrl,
    String? promptVersion,
    Duration? timeout,
  }) {
    return OpenRouterConfig(
      apiKey: apiKey ?? this.apiKey,
      modelId: modelId ?? this.modelId,
      baseUrl: baseUrl ?? this.baseUrl,
      promptVersion: promptVersion ?? this.promptVersion,
      timeout: timeout ?? this.timeout,
    );
  }
}
