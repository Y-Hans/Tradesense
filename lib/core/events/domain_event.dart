import 'package:flutter/foundation.dart';

/// Generic immutable base class for all domain events in the application.
///
/// Represents a fact that occurred in the business domain.
/// Includes occurrence timestamp and event type identifier.
@immutable
abstract class DomainEvent {
  final DateTime occurredAt;
  final String eventType;

  DomainEvent({
    DateTime? occurredAt,
    required this.eventType,
  }) : occurredAt = occurredAt ?? DateTime.now();

  @override
  String toString() => '$eventType(occurredAt: $occurredAt)';
}
