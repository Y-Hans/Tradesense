import 'package:cryptoedu/features/coach/data/dtos/openrouter_dtos.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('OpenRouter DTOs Unit Tests', () {
    test('OpenRouterMessageDto json roundtrip', () {
      const dto = OpenRouterMessageDto(role: 'user', content: 'hello world');
      final json = dto.toJson();
      expect(json['role'], equals('user'));
      expect(json['content'], equals('hello world'));

      final parsed = OpenRouterMessageDto.fromJson(json);
      expect(parsed.role, equals('user'));
      expect(parsed.content, equals('hello world'));
    });

    test('OpenRouterResponseDto deserializes nested choices', () {
      final json = {
        'id': 'gen-123',
        'choices': [
          {
            'finish_reason': 'stop',
            'message': {
              'role': 'assistant',
              'content': '{"what_done_well": "good trade"}',
            },
          }
        ],
      };

      final responseDto = OpenRouterResponseDto.fromJson(json);
      expect(responseDto.id, equals('gen-123'));
      expect(responseDto.choices.length, equals(1));
      expect(responseDto.choices.first.finishReason, equals('stop'));
      expect(
        responseDto.choices.first.message.content,
        contains('what_done_well'),
      );
    });

    test('OpenRouterCoachFeedbackDto validation identifies valid payload', () {
      const validDto = OpenRouterCoachFeedbackDto(
        whatDoneWell: 'Executed order with stop-loss.',
        whatIncreasedRisk: 'Position size was slightly high.',
        whatToLearn: 'Risk management fundamentals.',
        whatToConsiderNext: 'Reduce trade size next time.',
      );

      expect(validDto.isValid, isTrue);

      final domain = validDto.toDomain(
        aiProvider: 'OpenRouter',
        modelId: 'anthropic/claude-3.5-sonnet',
        promptVersion: 'v1.0.0',
        latencyMs: 150,
      );

      expect(domain.whatDoneWell, equals('Executed order with stop-loss.'));
      expect(domain.aiProvider, equals('OpenRouter'));
      expect(domain.modelId, equals('anthropic/claude-3.5-sonnet'));
      expect(domain.promptVersion, equals('v1.0.0'));
      expect(domain.latencyMs, equals(150));
    });

    test('OpenRouterCoachFeedbackDto validation rejects missing or empty fields', () {
      const missingFieldDto = OpenRouterCoachFeedbackDto(
        whatDoneWell: 'Executed order with stop-loss.',
        whatIncreasedRisk: '',
        whatToLearn: 'Risk management fundamentals.',
        whatToConsiderNext: 'Reduce trade size next time.',
      );

      expect(missingFieldDto.isValid, isFalse);
      expect(
        () => missingFieldDto.toDomain(
          aiProvider: 'OpenRouter',
          modelId: 'claude',
          promptVersion: 'v1',
          latencyMs: 100,
        ),
        throwsFormatException,
      );
    });
  });
}
