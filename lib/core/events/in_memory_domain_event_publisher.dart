import 'dart:async';
import 'domain_event.dart';
import 'domain_event_publisher.dart';

/// Lightweight, in-memory synchronous implementation of [DomainEventPublisher].
///
/// Dispatches published domain events to all subscribers synchronously via a
/// broadcast stream controller, preserving event ordering.
class InMemoryDomainEventPublisher implements DomainEventPublisher {
  final StreamController<DomainEvent> _controller;

  InMemoryDomainEventPublisher()
      : _controller = StreamController<DomainEvent>.broadcast(sync: true);

  @override
  void publish(DomainEvent event) {
    if (!_controller.isClosed) {
      _controller.add(event);
    }
  }

  @override
  Stream<DomainEvent> get events => _controller.stream;

  @override
  void dispose() {
    if (!_controller.isClosed) {
      _controller.close();
    }
  }
}
