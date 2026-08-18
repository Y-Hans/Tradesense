import 'package:flutter_test/flutter_test.dart';
import 'package:cryptoedu/features/coach/data/coach_repository.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class MockFunctionsClient extends FunctionsClient {
  MockFunctionsClient() : super('https://test.supabase.co/functions/v1', {});

  int? mockStatus;
  dynamic mockResponseData;
  Map<String, dynamic>? lastBody;
  FunctionException? functionExceptionToThrow;

  @override
  Future<FunctionResponse> invoke(
    String functionName, {
    Map<String, String>? headers,
    Object? body,
    HttpMethod method = HttpMethod.post,
    Map<String, dynamic>? queryParameters,
    Iterable<MultipartFile>? files,
    String? region,
  }) async {
    lastBody = body as Map<String, dynamic>?;
    if (functionExceptionToThrow != null) {
      throw functionExceptionToThrow!;
    }
    return FunctionResponse(
      data: mockResponseData ?? {'text': 'Mock coach advice', 'conversation_id': 'conv-123'},
      status: mockStatus ?? 200,
    );
  }
}

class FakeSupabaseClient extends SupabaseClient {
  final MockFunctionsClient mockFunctions;

  FakeSupabaseClient(this.mockFunctions)
      : super('https://test.supabase.co', 'fake-anon-key');

  @override
  FunctionsClient get functions => mockFunctions;
}

void main() {
  late MockFunctionsClient mockFunctions;
  late FakeSupabaseClient fakeClient;
  late CoachRepository repository;

  setUp(() {
    mockFunctions = MockFunctionsClient();
    fakeClient = FakeSupabaseClient(mockFunctions);
    repository = CoachRepository(fakeClient);
  });

  group('CoachRepository Unit Tests', () {
    test('getCoachResponse success adds assistant message and returns ChatMessage', () async {
      mockFunctions.mockStatus = 200;
      mockFunctions.mockResponseData = {
        'text': 'Always use stop-loss orders to limit downside risk.',
        'conversation_id': 'conv-456'
      };

      final response = await repository.getCoachResponse('How to manage risk?');

      expect(response.isUser, isFalse);
      expect(response.text, equals('Always use stop-loss orders to limit downside risk.'));
      expect(repository.getHistorySync().any((m) => m.text == response.text), isTrue);
    });

    test('getCoachResponse never includes client-supplied history in body payload', () async {
      mockFunctions.mockStatus = 200;
      mockFunctions.mockResponseData = {'text': 'Advice'};

      await repository.sendMessage('First message');
      await repository.getCoachResponse('Second message');

      expect(mockFunctions.lastBody, isNotNull);
      expect(mockFunctions.lastBody!.containsKey('history'), isFalse);
      expect(mockFunctions.lastBody!['current_message'], equals('Second message'));
    });

    test('getCoachResponse with 429 status throws daily rate limit exception', () async {
      mockFunctions.functionExceptionToThrow = const FunctionException(
        status: 429,
        details: 'Daily message limit reached. Please try again tomorrow.',
      );

      expect(
        () => repository.getCoachResponse('Hello Coach'),
        throwsA(predicate((e) => e.toString().contains('Daily message limit reached'))),
      );
    });

    test('getCoachResponse with 403 status throws access denied exception', () async {
      mockFunctions.functionExceptionToThrow = const FunctionException(
        status: 403,
        details: 'Conversation access denied.',
      );

      expect(
        () => repository.getCoachResponse('Hello Coach'),
        throwsA(predicate((e) => e.toString().contains('Conversation access denied'))),
      );
    });

    test('getCoachResponse with generic error propagates meaningful error', () async {
      mockFunctions.functionExceptionToThrow = const FunctionException(
        status: 500,
        details: 'OpenRouter service error',
      );

      expect(
        () => repository.getCoachResponse('Hello Coach'),
        throwsA(predicate((e) => e.toString().contains('Coach is unavailable'))),
      );
    });

    test('History is bounded to 100 messages max', () async {
      for (int i = 0; i < 110; i++) {
        await repository.sendMessage('Message $i');
      }

      final history = repository.getHistorySync();
      expect(history.length, lessThanOrEqualTo(100));
    });
  });
}
