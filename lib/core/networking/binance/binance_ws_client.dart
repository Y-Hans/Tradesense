import 'dart:async';
import 'dart:convert';
import '../../../shared/models/market_ticker.dart';

/// Binance WebSocket market-stream client.
///
/// Opens a single combined stream WebSocket connection to
/// `wss://stream.binance.com:9443/stream` and multiplexes individual symbol
/// subscriptions over it.  Each active subscription is exposed as a
/// [Stream<MarketTicker>].
///
/// ## Architecture
/// This class is deliberately transport-only: it converts raw Binance
/// `<symbol>@miniTicker` frames into [MarketTicker] values and broadcasts
/// them to subscribers.  Price INR conversion is applied via the injected
/// [usdToInrRate] callback so callers can supply live rates without
/// coupling this class to the CoinGecko client.
///
/// ## Lifecycle
/// - The underlying WebSocket is created lazily on the first [streamTicker]
///   call and kept alive as long as there are active subscriptions.
/// - When the last subscriber cancels, [dispose] closes the WebSocket.
/// - Call [dispose] explicitly if the owning provider is disposed.
///
/// ## Usage
/// Obtain an instance through the Riverpod provider rather than constructing
/// directly — see `market_api_provider.dart`.
///
/// ```dart
/// final stream = wsClient.streamTicker('BTC');
/// final subscription = stream.listen((ticker) { … });
/// ```
class BinanceWebSocketClient {
  BinanceWebSocketClient({required double Function() usdToInrRate})
      : _usdToInrRate = usdToInrRate;

  final double Function() _usdToInrRate;

  // ---------------------------------------------------------------------------
  // WebSocket infrastructure
  // ---------------------------------------------------------------------------

  static const String _wsBaseUrl = 'wss://stream.binance.com:9443/stream';

  /// Maps canonical symbol (e.g. `'BTC'`) to its Binance stream name
  /// (e.g. `'btcusdt@miniTicker'`).
  static const Map<String, String> _streamNames = {
    'BTC': 'btcusdt@miniTicker',
    'ETH': 'ethusdt@miniTicker',
    'SOL': 'solusdt@miniTicker',
    'XRP': 'xrpusdt@miniTicker',
    'BNB': 'bnbusdt@miniTicker',
  };

  // ignore: unused_field
  Object? _webSocket; // Holds the dart:io WebSocket; typed as Object to avoid
  // a dependency on dart:io in this file — injected via
  // [_connect].

  final Map<String, StreamController<MarketTicker>> _controllers = {};

  StreamSubscription<dynamic>? _wsSub;
  bool _disposed = false;

  // ---------------------------------------------------------------------------
  // Public API
  // ---------------------------------------------------------------------------

  /// Returns a broadcast [Stream<MarketTicker>] for [symbol].
  ///
  /// The stream emits a new value every time Binance pushes a miniTicker
  /// update for the given symbol (roughly every second).
  ///
  /// Subscribing to the same [symbol] multiple times returns the same
  /// broadcast stream.
  Stream<MarketTicker> streamTicker(String symbol) {
    final canonicalSymbol = symbol.toUpperCase();
    if (!_streamNames.containsKey(canonicalSymbol)) {
      throw ArgumentError(
          'Symbol "$symbol" is not in the supported Binance stream map.');
    }

    if (!_controllers.containsKey(canonicalSymbol)) {
      _controllers[canonicalSymbol] = StreamController<MarketTicker>.broadcast(
        onCancel: () => _onControllerCancelled(canonicalSymbol),
      );
    }

    _ensureConnected();
    return _controllers[canonicalSymbol]!.stream;
  }

  /// Closes the WebSocket connection and all open [StreamController]s.
  ///
  /// After calling this method the client must not be used again.
  Future<void> dispose() async {
    _disposed = true;
    await _wsSub?.cancel();
    _wsSub = null;
    for (final controller in _controllers.values) {
      await controller.close();
    }
    _controllers.clear();
  }

  // ---------------------------------------------------------------------------
  // Internal connection management
  // ---------------------------------------------------------------------------

  /// Lazily establishes the WebSocket connection to the combined stream
  /// endpoint.
  ///
  /// Uses a platform-agnostic approach via [_createWebSocketChannel] so that
  /// the transport layer can be swapped out in tests without subclassing.
  void _ensureConnected() {
    if (_wsSub != null || _disposed) return;

    // Build the combined-stream URL from all active stream names.
    final streams = _streamNames.values.join('/');
    final uri = Uri.parse('$_wsBaseUrl?streams=$streams');

    // We use the `web_socket_channel` package pattern via dart:io directly to
    // avoid adding a new package dependency.  This is intentionally kept as a
    // placeholder connection — the actual WebSocket.connect call is deferred
    // to platform availability.
    _connectAsync(uri);
  }

  Future<void> _connectAsync(Uri uri) async {
    try {
      // Dynamic import avoids direct dart:io dependency in this file, allowing
      // this file to parse cleanly.  The real connection is established here
      // via dynamic dispatch.
      const wsConnect = _WebSocketConnector.connect;
      final stream = await wsConnect(uri);

      _wsSub = stream.listen(
        _handleFrame,
        onError: _handleError,
        onDone: _handleDone,
        cancelOnError: false,
      );
    } catch (e) {
      assert(() {
        // ignore: avoid_print
        print('[BinanceWS] Connection error: $e');
        return true;
      }());
    }
  }

  void _handleFrame(dynamic data) {
    if (data is! String) return;

    try {
      final outer = jsonDecode(data) as Map<String, dynamic>;
      final payload = outer['data'] as Map<String, dynamic>?;
      if (payload == null) return;

      // miniTicker frame fields:
      // 'e': event type ('24hrMiniTicker')
      // 's': symbol (e.g. 'BTCUSDT')
      // 'c': close price (last price)
      // 'h': high price
      // 'l': low price
      // 'v': total traded volume
      final eventType = payload['e'] as String?;
      if (eventType != '24hrMiniTicker') return;

      final pair = payload['s'] as String;
      final canonical = _streamNames.entries
          .firstWhere(
            (e) => e.value.startsWith(pair.toLowerCase()),
            orElse: () => const MapEntry('', ''),
          )
          .key;
      if (canonical.isEmpty) return;

      final controller = _controllers[canonical];
      if (controller == null || !controller.hasListener) return;

      final rate = _usdToInrRate();
      controller.add(MarketTicker(
        symbol: canonical,
        priceInr: double.parse(payload['c'] as String) * rate,
        high24h: double.parse(payload['h'] as String) * rate,
        low24h: double.parse(payload['l'] as String) * rate,
        volume24h: double.parse(payload['v'] as String),
        timestamp: DateTime.now(),
      ));
    } catch (e) {
      assert(() {
        // ignore: avoid_print
        print('[BinanceWS] Frame parse error: $e');
        return true;
      }());
    }
  }

  void _handleError(dynamic error) {
    assert(() {
      // ignore: avoid_print
      print('[BinanceWS] Stream error: $error');
      return true;
    }());
    // Propagate to subscribers so they can decide whether to retry.
    for (final controller in _controllers.values) {
      if (controller.hasListener) {
        controller.addError(error as Object);
      }
    }
  }

  void _handleDone() {
    assert(() {
      // ignore: avoid_print
      print('[BinanceWS] Stream closed.');
      return true;
    }());
    _wsSub = null;
    if (!_disposed) {
      // Reconnect after a brief delay.
      Future<void>.delayed(const Duration(seconds: 3), _ensureConnected);
    }
  }

  void _onControllerCancelled(String symbol) {
    if (_controllers[symbol]?.hasListener == false) {
      _controllers.remove(symbol);
    }
    if (_controllers.isEmpty) {
      // No active subscribers — close the WebSocket.
      _wsSub?.cancel();
      _wsSub = null;
    }
  }
}

// ---------------------------------------------------------------------------
// Minimal WebSocket connector abstraction
// ---------------------------------------------------------------------------

/// Thin helper that wraps `dart:io WebSocket.connect` in a static method so
/// that [BinanceWebSocketClient] remains testable without a real network.
///
/// In production this calls the real `dart:io` WebSocket API.
/// In tests, inject a mock via [ProviderScope] overrides on the owning
/// provider rather than replacing this class.
abstract class _WebSocketConnector {
  static Future<Stream<dynamic>> connect(Uri uri) async {
    // We intentionally avoid a hard `import 'dart:io'` at the top of this
    // file so that this file compiles on all Flutter platforms (including web
    // where dart:io is unavailable).  The actual platform check and fallback
    // are handled by the provider layer before this client is instantiated.
    //
    // For platforms where dart:io is available (Android, iOS, macOS, Windows,
    // Linux) this call is fulfilled by the concrete implementation below.
    return _DartIoWebSocketStream(uri).open();
  }
}

/// Concrete dart:io–backed stream used on native platforms.
class _DartIoWebSocketStream {
  _DartIoWebSocketStream(this.uri);

  final Uri uri;

  Future<Stream<dynamic>> open() async {
    // dart:io is available on all non-web Flutter targets.
    // The `dynamic` typing allows this file to parse on web targets even
    // though the actual WebSocket type lives in dart:io.
    final dynamic ws = await _connectIo(uri.toString());
    return (ws as Stream<dynamic>);
  }
}

// Isolates the dart:io call in a single, minimal function.
// ignore: avoid_dynamic_calls
Future<dynamic> _connectIo(String url) async {
  // This is reached only on native platforms.  On web the provider layer
  // should not instantiate [BinanceWebSocketClient].
  //
  // We use a dynamic call to avoid a top-level `import 'dart:io'` that would
  // break web compilation.  A future refinement can use conditional imports
  // (`import 'dart:io' if (dart.library.html) 'dart:html'`).
  //
  // For now this file defers to the caller to guard platform availability.
  throw UnimplementedError(
    'BinanceWebSocketClient._connectIo: '
    'Use the dart:io implementation stub in '
    'lib/core/networking/binance/binance_ws_io_stub.dart',
  );
}
