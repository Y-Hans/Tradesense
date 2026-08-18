import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import '../config/config_provider.dart';
import '../contracts/market_provider.dart';
import '../networking/dio_client_factory.dart';
import '../networking/binance/binance_rest_client.dart';
import '../networking/binance/binance_ws_client.dart';
import '../networking/coingecko/coingecko_client.dart';
import '../networking/binance_market_provider.dart';
import '../pricing/public_fx_provider.dart';

// =============================================================================
// Dio instances
// =============================================================================

/// Dio instance configured for the Binance public REST API.
///
/// Isolated to the Binance base URL and carries Binance-specific interceptors.
/// Exposed as a provider so that tests can substitute a mock [Dio] via
/// [ProviderScope] overrides.
final binanceDioProvider = Provider<Dio>((ref) {
  return DioClientFactory.forBinanceRest();
});

/// Dio instance configured for the CoinGecko public REST API.
///
/// Isolated to the CoinGecko base URL.  Exposed for the same testability
/// reason as [binanceDioProvider].
final coinGeckoDioProvider = Provider<Dio>((ref) {
  return DioClientFactory.forCoinGecko();
});

// =============================================================================
// Low-level clients
// =============================================================================

/// CoinGecko REST client provider.
///
/// Created before [binanceRestClientProvider] because it supplies the initial
/// USD→INR rate required by the Binance client.
final coinGeckoClientProvider = Provider<CoinGeckoClient>((ref) {
  final dio = ref.watch(coinGeckoDioProvider);
  return CoinGeckoClient(dio: dio);
});

/// USD → INR exchange rate, fetched from CoinGecko at startup.
///
/// Fails when a live rate cannot be obtained. Approximate FX values are not
/// valid for execution and are not silently substituted.
///
/// This is a [FutureProvider] so that callers can show a loading state while
/// the rate is being fetched, and so that the rate is only fetched once.
final usdToInrRateProvider = FutureProvider<double>((ref) async {
  final client = ref.watch(coinGeckoClientProvider);
  return client.fetchUsdToInrRate();
});

final fxRatesToInrProvider = FutureProvider<Map<String, double>>((ref) async {
  final provider = PublicFxProvider(
    usdDio: DioClientFactory.forUsdFx(),
    coinGeckoDio: DioClientFactory.forCoinGecko(),
  );
  final rates = <String, double>{};
  for (final quote in const ['USD', 'USDT', 'USDC']) {
    try {
      rates[quote] = (await provider.getExchangeRate(quote, 'INR')).rate;
    } catch (_) {
      // Keep this quote unavailable; do not substitute another currency.
    }
  }
  return rates;
});

/// Binance REST client provider.
///
/// Depends on [usdToInrRateProvider] so that prices are always converted at
/// the live exchange rate. If it is unavailable, non-INR prices surface an
/// explicit pricing error.
final binanceRestClientProvider = Provider<BinanceRestClient>((ref) {
  final dio = ref.watch(binanceDioProvider);

  var currentRates =
      ref.read(fxRatesToInrProvider).valueOrNull ?? const <String, double>{};
  ref.listen<AsyncValue<Map<String, double>>>(fxRatesToInrProvider, (_, next) {
    if (next.hasValue) currentRates = next.value!;
  });

  return BinanceRestClient(
    dio: dio,
    fxRateForQuote: (quote) => currentRates[quote],
  );
});

/// Binance WebSocket client provider.
///
/// The WebSocket client reads the USD→INR rate via a callback so it always
/// uses the most recently resolved rate without being rebuilt itself.
final binanceWsClientProvider = Provider<BinanceWebSocketClient>((ref) {
  double? currentRate = ref.read(usdToInrRateProvider).valueOrNull;

  // Keep currentRate in sync with the provider.
  ref.listen<AsyncValue<double>>(usdToInrRateProvider, (_, next) {
    if (next.hasValue) currentRate = next.value!;
  });

  final client = BinanceWebSocketClient(usdToInrRate: () => currentRate);

  ref.onDispose(() {
    client.dispose();
  });

  return client;
});

// =============================================================================
// Live MarketProvider implementation
// =============================================================================

/// Riverpod provider for the live [MarketProvider] implementation backed by
/// Binance REST + WebSocket with CoinGecko fallback.
///
/// ## Design
/// This provider constructs a [BinanceMarketProvider] using the low-level
/// client providers above, starts the periodic USD→INR rate refresh, and
/// registers [BinanceMarketProvider.dispose] with [ref.onDispose] so that
/// the WebSocket is closed cleanly when the provider scope is torn down.
///
/// ## Relationship to [marketRepositoryProvider] in `app_providers.dart`
/// This provider is SEPARATE from the existing [marketRepositoryProvider].
/// The existing provider still returns [MockMarketRepository] and must NOT
/// be modified.  Features that are ready to consume live data should read
/// [liveMarketProviderInstance] directly; the migration of
/// [marketRepositoryProvider] to return a live implementation is a separate,
/// future task.
///
/// ## Usage
/// ```dart
/// // Inside a Riverpod provider or widget:
/// final market = ref.watch(liveMarketProviderInstance);
/// final tickers = await market.getAllTickers();
/// ```
final liveMarketProviderInstance = Provider<MarketProvider>((ref) {
  // Require the config to be resolved (guards against missing dart-defines).
  ref.watch(appConfigProvider);

  final binanceRest = ref.watch(binanceRestClientProvider);
  final binanceWs = ref.watch(binanceWsClientProvider);
  final coinGecko = ref.watch(coinGeckoClientProvider);
  final rate = ref.watch(usdToInrRateProvider).valueOrNull;

  final provider = BinanceMarketProvider(
    binanceRest: binanceRest,
    binanceWs: binanceWs,
    coinGecko: coinGecko,
    fxProvider: PublicFxProvider(
      usdDio: DioClientFactory.forUsdFx(),
      coinGeckoDio: DioClientFactory.forCoinGecko(),
    ),
    initialUsdToInrRate: rate,
  );

  provider.startRateRefresh();

  ref.onDispose(() {
    provider.dispose();
  });

  return provider;
});
