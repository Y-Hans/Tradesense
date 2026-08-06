import 'trading_events.dart';

typedef TradingEventListener = void Function(TradingEvent event);

abstract interface class TradingEventSubscription {
  void cancel();
}

abstract interface class TradingEventPublisher {
  TradingEventSubscription subscribe(TradingEventListener listener);
  void unsubscribe(TradingEventListener listener);
  void publish(TradingEvent event);
}

abstract interface class TradingCompletedTradeCountProvider {
  int completedTradeCountForUser(String userId);
}

class NoOpTradingEventPublisher implements TradingEventPublisher {
  const NoOpTradingEventPublisher();

  @override
  TradingEventSubscription subscribe(TradingEventListener listener) {
    return const _NoOpTradingEventSubscription();
  }

  @override
  void unsubscribe(TradingEventListener listener) {}

  @override
  void publish(TradingEvent event) {}
}

class InMemoryTradingEventPublisher implements TradingEventPublisher {
  final List<TradingEventListener> _listeners = [];

  @override
  TradingEventSubscription subscribe(TradingEventListener listener) {
    if (!_listeners.contains(listener)) {
      _listeners.add(listener);
    }
    return _InMemoryTradingEventSubscription(this, listener);
  }

  @override
  void unsubscribe(TradingEventListener listener) {
    _listeners.remove(listener);
  }

  @override
  void publish(TradingEvent event) {
    final listeners = List<TradingEventListener>.of(_listeners);
    for (final listener in listeners) {
      try {
        listener(event);
      } catch (_) {
        // Event consumers are isolated from trading execution.
      }
    }
  }
}

class _NoOpTradingEventSubscription implements TradingEventSubscription {
  const _NoOpTradingEventSubscription();

  @override
  void cancel() {}
}

class _InMemoryTradingEventSubscription implements TradingEventSubscription {
  final InMemoryTradingEventPublisher publisher;
  final TradingEventListener listener;
  bool _isCancelled = false;

  _InMemoryTradingEventSubscription(this.publisher, this.listener);

  @override
  void cancel() {
    if (_isCancelled) return;
    _isCancelled = true;
    publisher.unsubscribe(listener);
  }
}
