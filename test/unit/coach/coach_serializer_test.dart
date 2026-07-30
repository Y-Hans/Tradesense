import 'package:cryptoedu/core/cache/domain/models/cache_entry.dart';
import 'package:cryptoedu/features/coach/data/serializers/coach_serializers.dart';
import 'package:cryptoedu/shared/models/coach_request.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('CoachResponseSerializer Unit Tests', () {
    test(
        'serializes and deserializes CacheEntry<CoachResponse> round-trip correctly',
        () {
      final serializer = CoachResponseSerializer();

      const response = CoachResponse(
        whatDoneWell: 'Configured stop-loss boundaries.',
        whatIncreasedRisk: 'Position size was slightly elevated.',
        whatToLearn: 'Maintain steady position sizing.',
        whatToConsiderNext: 'Monitor market volatility.',
        aiProvider: 'TestAIProvider',
        modelId: 'test-model-v1',
        promptVersion: 'v1.0.0',
        latencyMs: 120,
      );

      final entry = CacheEntry<CoachResponse>(
        key: 'coach_req_test_key',
        value: response,
        createdAt: DateTime(2026, 1, 1, 12, 0, 0),
        ttl: const Duration(hours: 24),
        version: 'v1',
      );

      final serialized = serializer.serialize(entry);
      expect(serialized, isA<String>());

      final deserialized = serializer.deserialize(serialized);
      expect(deserialized.key, equals('coach_req_test_key'));
      expect(deserialized.ttl, equals(const Duration(hours: 24)));
      expect(deserialized.version, equals('v1'));

      final val = deserialized.value;
      expect(val.whatDoneWell, equals(response.whatDoneWell));
      expect(val.whatIncreasedRisk, equals(response.whatIncreasedRisk));
      expect(val.whatToLearn, equals(response.whatToLearn));
      expect(val.whatToConsiderNext, equals(response.whatToConsiderNext));
      expect(val.aiProvider, equals(response.aiProvider));
      expect(val.modelId, equals(response.modelId));
      expect(val.promptVersion, equals(response.promptVersion));
      expect(val.latencyMs, equals(response.latencyMs));
    });
  });
}
