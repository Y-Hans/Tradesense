enum LearningEventType {
  onboardingCompleted,
  loginCompleted,
  viewedMarket,
  firstTradeCompleted,
  completedLesson,
  newsDetectiveCompleted,
  riskEvaluationCompleted,
  disciplineEvaluationCompleted,
  coachSessionCompleted,
}

class LearningEvent {
  final String eventId;
  final LearningEventType type;
  final DateTime timestamp;
  final Map<String, dynamic> metadata;

  LearningEvent({
    required this.type,
    String? eventId,
    DateTime? timestamp,
    Map<String, dynamic>? metadata,
  })  : eventId = eventId ??
            '${type.name}_${(timestamp ?? DateTime.now()).microsecondsSinceEpoch}',
        timestamp = timestamp ?? DateTime.now(),
        metadata = metadata ?? const {};

  factory LearningEvent.onboardingCompleted({
    String? eventId,
    DateTime? timestamp,
    Map<String, dynamic>? metadata,
  }) {
    return LearningEvent(
      type: LearningEventType.onboardingCompleted,
      eventId: eventId,
      timestamp: timestamp,
      metadata: metadata,
    );
  }

  factory LearningEvent.loginCompleted({
    String? eventId,
    DateTime? timestamp,
    Map<String, dynamic>? metadata,
  }) {
    return LearningEvent(
      type: LearningEventType.loginCompleted,
      eventId: eventId,
      timestamp: timestamp,
      metadata: metadata,
    );
  }

  factory LearningEvent.viewedMarket({
    String? eventId,
    DateTime? timestamp,
    Map<String, dynamic>? metadata,
  }) {
    return LearningEvent(
      type: LearningEventType.viewedMarket,
      eventId: eventId,
      timestamp: timestamp,
      metadata: metadata,
    );
  }

  factory LearningEvent.firstTradeCompleted({
    String? eventId,
    DateTime? timestamp,
    Map<String, dynamic>? metadata,
  }) {
    return LearningEvent(
      type: LearningEventType.firstTradeCompleted,
      eventId: eventId,
      timestamp: timestamp,
      metadata: metadata,
    );
  }

  factory LearningEvent.completedLesson({
    String? eventId,
    DateTime? timestamp,
    Map<String, dynamic>? metadata,
  }) {
    return LearningEvent(
      type: LearningEventType.completedLesson,
      eventId: eventId,
      timestamp: timestamp,
      metadata: metadata,
    );
  }

  factory LearningEvent.newsDetectiveCompleted({
    String? eventId,
    DateTime? timestamp,
    Map<String, dynamic>? metadata,
  }) {
    return LearningEvent(
      type: LearningEventType.newsDetectiveCompleted,
      eventId: eventId,
      timestamp: timestamp,
      metadata: metadata,
    );
  }

  factory LearningEvent.riskEvaluationCompleted({
    String? eventId,
    DateTime? timestamp,
    Map<String, dynamic>? metadata,
  }) {
    return LearningEvent(
      type: LearningEventType.riskEvaluationCompleted,
      eventId: eventId,
      timestamp: timestamp,
      metadata: metadata,
    );
  }

  factory LearningEvent.disciplineEvaluationCompleted({
    String? eventId,
    DateTime? timestamp,
    Map<String, dynamic>? metadata,
  }) {
    return LearningEvent(
      type: LearningEventType.disciplineEvaluationCompleted,
      eventId: eventId,
      timestamp: timestamp,
      metadata: metadata,
    );
  }

  factory LearningEvent.coachSessionCompleted({
    String? eventId,
    DateTime? timestamp,
    Map<String, dynamic>? metadata,
  }) {
    return LearningEvent(
      type: LearningEventType.coachSessionCompleted,
      eventId: eventId,
      timestamp: timestamp,
      metadata: metadata,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LearningEvent &&
          runtimeType == other.runtimeType &&
          eventId == other.eventId &&
          type == other.type;

  @override
  int get hashCode => eventId.hashCode ^ type.hashCode;

  @override
  String toString() =>
      'LearningEvent(eventId: $eventId, type: ${type.name}, timestamp: $timestamp)';
}
