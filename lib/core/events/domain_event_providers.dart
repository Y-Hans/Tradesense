import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'domain_event_publisher.dart';
import 'in_memory_domain_event_publisher.dart';

export 'domain_event.dart';
export 'domain_events.dart';
export 'domain_event_publisher.dart';
export 'in_memory_domain_event_publisher.dart';

/// Riverpod provider for [DomainEventPublisher].
///
/// Automatically disposes the publisher when the provider is disposed.
/// Replaceable in tests via ProviderScope overrides.
final domainEventPublisherProvider = Provider<DomainEventPublisher>((ref) {
  final publisher = InMemoryDomainEventPublisher();
  ref.onDispose(() => publisher.dispose());
  return publisher;
});
