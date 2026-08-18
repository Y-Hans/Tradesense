import 'package:dio/dio.dart';

/// Factory that produces pre-configured [Dio] instances for each upstream
/// service.
///
/// Each instance is scoped to a single base URL and carries only the
/// interceptors and timeouts appropriate for that service.  Nothing here
/// touches the UI or any Riverpod provider; callers wire those concerns.
///
/// ## Adding a new service
/// Add a named factory method following the pattern of [forBinanceRest] or
/// [forCoinGecko].  Avoid adding shared mutable state.
class DioClientFactory {
  DioClientFactory._();

  // ---------------------------------------------------------------------------
  // Shared timeout constants
  // ---------------------------------------------------------------------------

  static const Duration _connectTimeout = Duration(seconds: 10);
  static const Duration _receiveTimeout = Duration(seconds: 20);
  static const Duration _sendTimeout = Duration(seconds: 10);

  // ---------------------------------------------------------------------------
  // Binance REST
  // ---------------------------------------------------------------------------

  /// Returns a [Dio] instance configured for the Binance public REST API.
  ///
  /// Base URL: `https://api.binance.com`
  ///
  /// No authentication is applied — all endpoints used here are part of the
  /// Binance public market-data surface which requires no API key.
  static Dio forBinanceRest() {
    final dio = Dio(
      BaseOptions(
        baseUrl: 'https://api.binance.com',
        connectTimeout: _connectTimeout,
        receiveTimeout: _receiveTimeout,
        sendTimeout: _sendTimeout,
        responseType: ResponseType.json,
        headers: const {
          'Accept': 'application/json',
        },
      ),
    );

    dio.interceptors.addAll([
      const _LoggingInterceptor(tag: 'Binance'),
      const _RetryInterceptor(maxRetries: 2),
    ]);

    return dio;
  }

  // ---------------------------------------------------------------------------
  // CoinGecko REST
  // ---------------------------------------------------------------------------

  /// Returns a [Dio] instance configured for the CoinGecko public REST API.
  ///
  /// Base URL: `https://api.coingecko.com/api/v3`
  ///
  /// CoinGecko's free tier imposes a rate limit of ~10–30 req/min.  The
  /// [_RetryInterceptor] backs off on 429 responses automatically.
  static Dio forCoinGecko() {
    final dio = Dio(
      BaseOptions(
        baseUrl: 'https://api.coingecko.com/api/v3',
        connectTimeout: _connectTimeout,
        receiveTimeout: _receiveTimeout,
        sendTimeout: _sendTimeout,
        responseType: ResponseType.json,
        headers: const {
          'Accept': 'application/json',
        },
      ),
    );

    dio.interceptors.addAll([
      const _LoggingInterceptor(tag: 'CoinGecko'),
      const _RetryInterceptor(maxRetries: 1),
    ]);

    return dio;
  }

  /// Keyless current-rate endpoint used for fiat USD/INR conversion.
  static Dio forUsdFx() {
    return Dio(BaseOptions(
      baseUrl: 'https://api.frankfurter.app',
      connectTimeout: _connectTimeout,
      receiveTimeout: _receiveTimeout,
      sendTimeout: _sendTimeout,
      responseType: ResponseType.json,
      headers: const {'Accept': 'application/json'},
    ));
  }
}

// -----------------------------------------------------------------------------
// Internal interceptors — not exported outside this file
// -----------------------------------------------------------------------------

/// Lightweight logging interceptor that records request / response / error
/// events in debug builds only.
class _LoggingInterceptor extends Interceptor {
  const _LoggingInterceptor({required this.tag});

  final String tag;

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    assert(() {
      // ignore: avoid_print
      print('[$tag] → ${options.method} ${options.uri}');
      return true;
    }());
    handler.next(options);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    assert(() {
      // ignore: avoid_print
      print('[$tag] ← ${response.statusCode} ${response.requestOptions.uri}');
      return true;
    }());
    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    assert(() {
      // ignore: avoid_print
      print('[$tag] ✕ ${err.type} ${err.requestOptions.uri}: ${err.message}');
      return true;
    }());
    handler.next(err);
  }
}

/// Simple retry interceptor that retries idempotent GET requests on transient
/// network errors (connection timeout, receive timeout, socket errors).
///
/// It does NOT retry on 4xx responses to avoid amplifying caller errors.
class _RetryInterceptor extends Interceptor {
  const _RetryInterceptor({this.maxRetries = 2});

  final int maxRetries;

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    final options = err.requestOptions;
    final attempt = (options.extra['_retry_count'] as int?) ?? 0;

    final isRetryable = _isTransient(err) && options.method == 'GET';

    if (isRetryable && attempt < maxRetries) {
      options.extra['_retry_count'] = attempt + 1;
      await Future<void>.delayed(Duration(milliseconds: 300 * (attempt + 1)));
      try {
        final clonedDio = Dio(options.copyWith() as BaseOptions);
        final response = await clonedDio.fetch(options);
        handler.resolve(response);
        return;
      } catch (_) {
        // Fall through to the original error on retry failure.
      }
    }

    handler.next(err);
  }

  static bool _isTransient(DioException err) {
    switch (err.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.receiveTimeout:
      case DioExceptionType.connectionError:
        return true;
      case DioExceptionType.badResponse:
        final status = err.response?.statusCode;
        return status == 429 || (status != null && status >= 500);
      default:
        return false;
    }
  }
}
