import '../../../../core/cache/data/serializers/cache_serializer.dart';
import '../../../../shared/models/coach_request.dart';

/// Serializer for [CoachResponse] payload leveraging generic cache serializer infrastructure.
class CoachResponseSerializer extends JsonCacheSerializer<CoachResponse> {
  CoachResponseSerializer()
      : super(
          toJson: (response) => response.toJson(),
          fromJson: (json) =>
              CoachResponse.fromJson(json as Map<String, dynamic>),
        );
}
