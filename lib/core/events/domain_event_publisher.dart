import 'domain_event.dart';

/// Abstract contract for publishing domain events in the application.
///
/// Allows completed business operations to publish events without knowing
/// who consumes them. Subscribers react independently via the [events] stream.
abstract class DomainEventPublisher {
  /// Publishes a [DomainEvent] to all subscribers.
  void publish(DomainEvent event);

  /// Stream of published domain events.
  Stream<DomainEvent> get events;

  /// Releases resources allocated by the publisher.
  void dispose();
}
