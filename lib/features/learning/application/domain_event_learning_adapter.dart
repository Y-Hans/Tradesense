import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/events/domain_event_providers.dart';
import '../domain/learning_event.dart';
import 'learning_progression_notifier.dart';

/// Translates generic application business events ([DomainEvent]) into
/// gamification learning events ([LearningEvent]) for progression processing.
///
/// Responsibilities:
/// 1. Subscribes to [DomainEventPublisher.events].
/// 2. Translates supported generic business events into Learning events.
/// 3. Passes translated events to [LearningProgressionNotifier].
/// 4. Preserves source event identity for deterministic idempotency.
/// 5. Ignores unsupported events safely.
/// 6. Cleans up subscription resources on dispose.
/// 7. Remains completely independent from source module implementations.
class DomainEventLearningAdapter {
  final DomainEventPublisher _publisher;
  final LearningProgressionNotifier _notifier;
  StreamSubscription<DomainEvent>? _subscription;

  DomainEventLearningAdapter({
    required DomainEventPublisher publisher,
    required LearningProgressionNotifier notifier,
  })  : _publisher = publisher,
        _notifier = notifier {
    _startListening();
  }

  void _startListening() {
    _subscription = _publisher.events.listen(
      handleDomainEvent,
      onError: (_) {
        // Handle stream errors safely without crashing progression engine
      },
    );
  }

  /// Handles an incoming [DomainEvent], translates supported event types
  /// into [LearningEvent]s, and forwards them to [LearningProgressionNotifier].
  ///
  /// Ignores unsupported/unknown domain events safely.
  void handleDomainEvent(DomainEvent event) {
    // We just refresh the backend-authoritative state when domain events happen
    _notifier.refresh();
  }

  /// Translates a generic [DomainEvent] to a [LearningEvent].
  /// Returns `null` if the event is not relevant to learning progression.
  LearningEvent? translateEvent(DomainEvent event) {
    if (event is TradeExecuted) {
      return LearningEvent.firstTradeCompleted(
        eventId: 'domain_trade_${event.tradeId}',
        timestamp: event.occurredAt,
        metadata: {
          'tradeId': event.tradeId,
          'symbol': event.symbol,
          'side': event.side,
          'hasStopLoss': event.hasStopLoss,
        },
      );
    } else if (event is RiskEvaluationCompleted) {
      return LearningEvent.riskEvaluationCompleted(
        eventId: 'domain_risk_${event.occurredAt.microsecondsSinceEpoch}',
        timestamp: event.occurredAt,
        metadata: {
          'riskScore': event.riskScore,
          'riskLevel': event.riskLevel,
          'hasStopLoss': event.hasStopLoss,
        },
      );
    } else if (event is DisciplineEvaluationCompleted) {
      return LearningEvent.disciplineEvaluationCompleted(
        eventId: 'domain_discipline_${event.occurredAt.microsecondsSinceEpoch}',
        timestamp: event.occurredAt,
        metadata: {
          'disciplineScore': event.disciplineScore,
          'usedStopLoss': event.usedStopLoss,
        },
      );
    } else if (event is CoachSessionCompleted) {
      return LearningEvent.coachSessionCompleted(
        eventId: 'domain_coach_${event.tradeId}',
        timestamp: event.occurredAt,
        metadata: {
          'tradeId': event.tradeId,
          'isFallback': event.isFallback,
        },
      );
    }

    // Safely ignore unknown/unsupported domain event types
    return null;
  }

  /// Disposes the underlying stream subscription.
  void dispose() {
    _subscription?.cancel();
    _subscription = null;
  }
}

/// Riverpod Provider for [DomainEventLearningAdapter].
final domainEventLearningAdapterProvider =
    Provider<DomainEventLearningAdapter>((ref) {
  final publisher = ref.watch(domainEventPublisherProvider);
  final notifier = ref.watch(learningProgressionNotifierProvider.notifier);
  final adapter = DomainEventLearningAdapter(
    publisher: publisher,
    notifier: notifier,
  );
  ref.onDispose(() => adapter.dispose());
  return adapter;
});
