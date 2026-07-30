import 'dart:convert';
import 'dart:developer' as developer;
import 'package:dio/dio.dart';

import '../../../../core/contracts/provider_contracts.dart';
import '../../../../shared/models/coach_request.dart';
import '../builders/openrouter_prompt_builder.dart';
import '../config/openrouter_config.dart';
import '../dtos/openrouter_dtos.dart';
import '../exceptions/openrouter_exceptions.dart';

/// Production implementation of [AIProvider] interacting with the OpenRouter API.
///
/// Responsible strictly for network communication with OpenRouter:
/// - Constructing API request DTOs via [OpenRouterPromptBuilder],
/// - Transmitting network requests via [Dio],
/// - Parsing API responses into [OpenRouterResponseDto],
/// - Validating required feedback fields in [OpenRouterCoachFeedbackDto],
/// - Converting validated DTOs to domain [CoachResponse] objects.
///
/// Contains NO business logic for risk scoring, discipline scoring, or trade calculations.
class OpenRouterAIProvider implements AIProvider {
  final OpenRouterConfig _config;
  final Dio _client;
  final OpenRouterPromptBuilder _promptBuilder;
  final Stopwatch Function()? _stopwatchFactory;

  OpenRouterAIProvider({
    required OpenRouterConfig config,
    required Dio client,
    OpenRouterPromptBuilder? promptBuilder,
    Stopwatch Function()? stopwatchFactory,
  })  : _config = config,
        _client = client,
        _promptBuilder = promptBuilder ?? const OpenRouterPromptBuilder(),
        _stopwatchFactory = stopwatchFactory;

  @override
  Future<CoachResponse> generateCoachFeedback(CoachRequest request) async {
    if (_config.apiKey.trim().isEmpty) {
      developer.log(
        'OpenRouter request aborted: API key is empty or not configured.',
        name: 'OpenRouterAIProvider',
      );
      throw const OpenRouterException(
        'OpenRouter API key is empty or not configured.',
      );
    }

    final requestDto = _promptBuilder.buildRequest(
      request,
      modelId: _config.modelId,
    );

    developer.log(
      'Starting OpenRouter feedback request [model: ${_config.modelId}, promptVersion: ${_config.promptVersion}]',
      name: 'OpenRouterAIProvider',
    );

    final stopwatch = (_stopwatchFactory?.call() ?? Stopwatch())..start();

    try {
      final response = await _client.post<dynamic>(
        '${_config.baseUrl}/chat/completions',
        data: requestDto.toJson(),
        options: Options(
          headers: {
            'Authorization': 'Bearer ${_config.apiKey}',
            'Content-Type': 'application/json',
            'HTTP-Referer': 'https://cryptoedu.app',
            'X-Title': 'CryptoEdu',
          },
          sendTimeout: _config.timeout,
          receiveTimeout: _config.timeout,
        ),
      );

      stopwatch.stop();
      final elapsedMs = stopwatch.elapsedMilliseconds;

      if (response.statusCode != 200 || response.data == null) {
        developer.log(
          'OpenRouter HTTP failure [statusCode: ${response.statusCode}]',
          name: 'OpenRouterAIProvider',
        );
        throw OpenRouterException(
          'OpenRouter API returned non-200 status code',
          statusCode: response.statusCode,
          errorBody: response.data,
        );
      }

      final Map<String, dynamic> responseMap;
      if (response.data is Map<String, dynamic>) {
        responseMap = response.data as Map<String, dynamic>;
      } else if (response.data is String) {
        responseMap =
            jsonDecode(response.data as String) as Map<String, dynamic>;
      } else {
        throw const OpenRouterFormatException(
          'Unexpected response data format from OpenRouter API',
        );
      }

      final responseDto = OpenRouterResponseDto.fromJson(responseMap);

      if (responseDto.choices.isEmpty) {
        developer.log(
          'OpenRouter response choices array is empty',
          name: 'OpenRouterAIProvider',
        );
        throw const OpenRouterFormatException(
          'OpenRouter response choices array is empty',
        );
      }

      final rawContent = responseDto.choices.first.message.content;
      final Map<String, dynamic> feedbackMap;
      try {
        feedbackMap = jsonDecode(rawContent) as Map<String, dynamic>;
      } catch (e) {
        developer.log(
          'Failed to parse completion message content as JSON',
          name: 'OpenRouterAIProvider',
        );
        throw OpenRouterFormatException(
          'Failed to parse OpenRouter completion content as JSON: $e',
        );
      }

      final feedbackDto = OpenRouterCoachFeedbackDto.fromJson(feedbackMap);

      if (!feedbackDto.isValid) {
        developer.log(
          'OpenRouter response validation failed: missing or empty required feedback fields',
          name: 'OpenRouterAIProvider',
        );
        throw const OpenRouterValidationException(
          'OpenRouter response validation failed: missing or empty required feedback fields',
        );
      }

      developer.log(
        'OpenRouter response successfully received and validated [latency: ${elapsedMs}ms]',
        name: 'OpenRouterAIProvider',
      );

      return feedbackDto.toDomain(
        aiProvider: 'OpenRouter',
        modelId: _config.modelId,
        promptVersion: _config.promptVersion,
        latencyMs: elapsedMs,
      );
    } on DioException catch (e) {
      stopwatch.stop();
      if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.sendTimeout ||
          e.type == DioExceptionType.receiveTimeout) {
        developer.log(
          'OpenRouter request timed out after ${_config.timeout.inSeconds}s',
          name: 'OpenRouterAIProvider',
        );
        throw OpenRouterTimeoutException(
          'OpenRouter network request timed out: ${e.message}',
          statusCode: e.response?.statusCode,
          errorBody: e.response?.data,
        );
      }

      developer.log(
        'OpenRouter HTTP network failure [status: ${e.response?.statusCode}, error: ${e.message}]',
        name: 'OpenRouterAIProvider',
      );
      throw OpenRouterException(
        'OpenRouter HTTP request failed: ${e.message}',
        statusCode: e.response?.statusCode,
        errorBody: e.response?.data,
      );
    } catch (e) {
      stopwatch.stop();
      if (e is OpenRouterException) {
        rethrow;
      }
      developer.log(
        'Unexpected OpenRouter exception: $e',
        name: 'OpenRouterAIProvider',
      );
      throw OpenRouterException(
          'Unexpected error during OpenRouter execution: $e');
    }
  }
}
