import 'dart:convert';
import 'dart:typed_data';

import 'package:cryptoedu/features/coach/data/config/openrouter_config.dart';
import 'package:cryptoedu/features/coach/data/exceptions/openrouter_exceptions.dart';
import 'package:cryptoedu/features/coach/data/providers/openrouter_ai_provider.dart';
import 'package:cryptoedu/shared/models/coach_request.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

class _MockHttpClientAdapter implements HttpClientAdapter {
  int Function(RequestOptions options)? statusCodeHandler;
  dynamic Function(RequestOptions options)? responseHandler;
  DioException Function(RequestOptions options)? dioExceptionBuilder;
  RequestOptions? lastRequestOptions;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    lastRequestOptions = options;

    if (dioExceptionBuilder != null) {
      throw dioExceptionBuilder!(options);
    }

    final code = statusCodeHandler?.call(options) ?? 200;
    final responseData = responseHandler?.call(options) ?? {};

    final encodedData =
        responseData is String ? responseData : jsonEncode(responseData);

    return ResponseBody.fromString(
      encodedData,
      code,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

void main() {
  group('OpenRouterAIProvider Unit Tests', () {
    late _MockHttpClientAdapter mockAdapter;
    late Dio dio;
    late OpenRouterConfig testConfig;
    late CoachRequest testRequest;

    setUp(() {
      mockAdapter = _MockHttpClientAdapter();
      dio = Dio(BaseOptions(baseUrl: 'https://openrouter.ai/api/v1'))
        ..httpClientAdapter = mockAdapter;

      testConfig = const OpenRouterConfig(
        apiKey: 'test-key-12345',
        modelId: 'anthropic/claude-3.5-sonnet',
        baseUrl: 'https://openrouter.ai/api/v1',
        promptVersion: 'v1.0.0',
      );

      testRequest = const CoachRequest(
        userId: 'user-001',
        tradeId: 'trade-100',
        tradeContext: {'symbol': 'BTC'},
        portfolioContext: {'total_equity_inr': 500000.0},
        marketContext: {'risk_reason_codes': []},
        riskScore: 25,
        disciplineScore: 90,
      );
    });

    test('Successful 200 response parses into valid CoachResponse', () async {
      final validFeedback = {
        'what_done_well': 'Great risk management and stop loss placement.',
        'what_increased_risk': 'Asset concentration was slightly high.',
        'what_to_learn': 'Position sizing and risk-to-reward metrics.',
        'what_to_consider_next': 'Diversify across multiple non-correlated assets.',
      };

      mockAdapter.responseHandler = (_) => {
            'id': 'gen-xyz-123',
            'choices': [
              {
                'finish_reason': 'stop',
                'message': {
                  'role': 'assistant',
                  'content': jsonEncode(validFeedback),
                },
              }
            ],
          };

      final provider = OpenRouterAIProvider(config: testConfig, client: dio);
      final response = await provider.generateCoachFeedback(testRequest);

      expect(response.whatDoneWell, equals(validFeedback['what_done_well']));
      expect(response.whatIncreasedRisk, equals(validFeedback['what_increased_risk']));
      expect(response.whatToLearn, equals(validFeedback['what_to_learn']));
      expect(response.whatToConsiderNext, equals(validFeedback['what_to_consider_next']));
      expect(response.aiProvider, equals('OpenRouter'));
      expect(response.modelId, equals('anthropic/claude-3.5-sonnet'));
      expect(response.promptVersion, equals('v1.0.0'));

      expect(
        mockAdapter.lastRequestOptions?.headers['Authorization'],
        equals('Bearer test-key-12345'),
      );
    });

    test('Empty API key throws OpenRouterException before making network request', () async {
      final provider = OpenRouterAIProvider(
        config: testConfig.copyWith(apiKey: ''),
        client: dio,
      );

      expect(
        () => provider.generateCoachFeedback(testRequest),
        throwsA(isA<OpenRouterException>().having(
          (e) => e.message,
          'message',
          contains('empty or not configured'),
        )),
      );
      expect(mockAdapter.lastRequestOptions, isNull);
    });

    test('Malformed response with empty feedback fields throws OpenRouterValidationException', () async {
      final malformedFeedback = {
        'what_done_well': '',
        'what_increased_risk': 'Some risk',
        'what_to_learn': 'Lesson',
        'what_to_consider_next': 'Next step',
      };

      mockAdapter.responseHandler = (_) => {
            'choices': [
              {
                'message': {
                  'role': 'assistant',
                  'content': jsonEncode(malformedFeedback),
                },
              }
            ],
          };

      final provider = OpenRouterAIProvider(config: testConfig, client: dio);

      expect(
        () => provider.generateCoachFeedback(testRequest),
        throwsA(isA<OpenRouterValidationException>()),
      );
    });

    test('Non-JSON completion message content throws OpenRouterFormatException', () async {
      mockAdapter.responseHandler = (_) => {
            'choices': [
              {
                'message': {
                  'role': 'assistant',
                  'content': 'Plain text response not formatted as JSON',
                },
              }
            ],
          };

      final provider = OpenRouterAIProvider(config: testConfig, client: dio);

      expect(
        () => provider.generateCoachFeedback(testRequest),
        throwsA(isA<OpenRouterFormatException>()),
      );
    });

    test('Empty choices list throws OpenRouterFormatException', () async {
      mockAdapter.responseHandler = (_) => {'choices': []};

      final provider = OpenRouterAIProvider(config: testConfig, client: dio);

      expect(
        () => provider.generateCoachFeedback(testRequest),
        throwsA(isA<OpenRouterFormatException>()),
      );
    });

    test('HTTP 429 Rate Limit error throws OpenRouterException with status code', () async {
      mockAdapter.dioExceptionBuilder = (options) => DioException(
            requestOptions: options,
            response: Response(
              requestOptions: options,
              statusCode: 429,
              data: {'error': 'Rate limit exceeded'},
            ),
            type: DioExceptionType.badResponse,
          );

      final provider = OpenRouterAIProvider(config: testConfig, client: dio);

      expect(
        () => provider.generateCoachFeedback(testRequest),
        throwsA(isA<OpenRouterException>().having(
          (e) => e.statusCode,
          'statusCode',
          equals(429),
        )),
      );
    });

    test('Network timeout throws OpenRouterTimeoutException', () async {
      mockAdapter.dioExceptionBuilder = (options) => DioException(
            requestOptions: options,
            type: DioExceptionType.receiveTimeout,
            message: 'Receive timeout',
          );

      final provider = OpenRouterAIProvider(config: testConfig, client: dio);

      expect(
        () => provider.generateCoachFeedback(testRequest),
        throwsA(isA<OpenRouterTimeoutException>()),
      );
    });
  });
}
