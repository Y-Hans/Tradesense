import 'package:cryptoedu/features/coach/data/builders/openrouter_prompt_builder.dart';
import 'package:cryptoedu/shared/models/coach_request.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('OpenRouterPromptBuilder Unit Tests', () {
    const promptBuilder = OpenRouterPromptBuilder(promptVersion: 'v1.0.0');

    const testRequest = CoachRequest(
      userId: 'user-123',
      tradeId: 'trade-456',
      tradeContext: {'symbol': 'BTC', 'side': 'buy', 'quantity': 0.5},
      portfolioContext: {'total_equity_inr': 100000.0},
      marketContext: {
        'risk_reason_codes': ['HIGH_VOLATILITY'],
        'discipline_reason_codes': ['STOP_LOSS_USED'],
      },
      riskScore: 40,
      disciplineScore: 85,
    );

    test('buildSystemPrompt contains required JSON field schema instructions',
        () {
      final systemPrompt = promptBuilder.buildSystemPrompt();
      expect(systemPrompt, contains('what_done_well'));
      expect(systemPrompt, contains('what_increased_risk'));
      expect(systemPrompt, contains('what_to_learn'));
      expect(systemPrompt, contains('what_to_consider_next'));
      expect(systemPrompt, contains('JSON'));
    });

    test('buildUserPrompt encodes structured request context', () {
      final userPrompt = promptBuilder.buildUserPrompt(testRequest);
      expect(userPrompt, contains('trade-456'));
      expect(userPrompt, contains('BTC'));
      expect(userPrompt, contains('HIGH_VOLATILITY'));
      expect(userPrompt, contains('STOP_LOSS_USED'));
    });

    test('buildRequest constructs valid OpenRouterRequestDto with modelId', () {
      final dto = promptBuilder.buildRequest(
        testRequest,
        modelId: 'anthropic/claude-3.5-sonnet',
      );

      expect(dto.model, equals('anthropic/claude-3.5-sonnet'));
      expect(dto.messages.length, equals(2));
      expect(dto.messages[0].role, equals('system'));
      expect(dto.messages[1].role, equals('user'));
      expect(dto.responseFormat, equals({'type': 'json_object'}));

      final json = dto.toJson();
      expect(json['model'], equals('anthropic/claude-3.5-sonnet'));
      expect(json['messages'], isA<List>());
      expect(json['response_format'], equals({'type': 'json_object'}));
    });
  });
}
