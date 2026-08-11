import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import '../config/config_provider.dart';

/// Exposes the configured [Purchases] singleton as a Riverpod provider.
///
/// [Purchases] is initialised once in `main()` before [runApp] is called,
/// mirroring the pattern used by [supabaseClientProvider] and the Firebase
/// providers.  This provider exists so that consuming layers can obtain the
/// instance through the standard Riverpod dependency graph rather than
/// calling [Purchases.sharedInstance] directly — making test overrides
/// straightforward via [ProviderScope].
///
/// ## Guard behaviour
/// If [AppConfig.isRevenueCatConfigured] is `false` (i.e. the
/// `--dart-define=REVENUECAT_PUBLIC_KEY=...` value was not provided at build
/// time) this provider throws a [StateError] with a descriptive message
/// instead of returning an uninitialised instance.  This surfaces the
/// misconfiguration early and loudly, consistent with the contract of the
/// other platform providers in this directory.
///
/// ## Usage
/// ```dart
/// final purchases = ref.watch(purchasesProvider);
/// final offerings = await purchases.getOfferings();
/// ```
final purchasesProvider = Provider<Purchases>((ref) {
  final config = ref.watch(appConfigProvider);

  if (!config.isRevenueCatConfigured) {
    throw StateError(
      'RevenueCat is not configured. '
      'Provide --dart-define=REVENUECAT_PUBLIC_KEY=<key> at build time.',
    );
  }

  // Purchases.configure() is called in main() before ProviderScope is mounted.
  return Purchases();
});
