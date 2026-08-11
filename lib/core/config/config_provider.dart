import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'app_config.dart';
import 'app_environment.dart';

/// Exposes the resolved [AppConfig] as a Riverpod provider.
///
/// Consuming providers and widgets should read this provider instead of
/// calling [AppConfig.resolved] directly so that tests can override it via
/// [ProviderScope] overrides without touching compile-time defines.
///
/// ## Example — reading inside another provider
/// ```dart
/// final supabaseClientProvider = Provider<SupabaseClient>((ref) {
///   final config = ref.watch(appConfigProvider);
///   assert(config.isSupabaseConfigured, 'Supabase defines missing');
///   return SupabaseClient(config.supabaseUrl, config.supabaseAnonKey);
/// });
/// ```
///
/// ## Example — overriding in tests
/// ```dart
/// ProviderScope(
///   overrides: [
///     appConfigProvider.overrideWithValue(AppConfig.resolved()),
///   ],
///   child: MyWidget(),
/// )
/// ```
final appConfigProvider = Provider<AppConfig>((ref) {
  return AppConfig.resolved();
});

/// Convenience provider that exposes just the [AppEnvironment].
///
/// Use this when a provider or widget only needs to branch on environment
/// without consuming the full [AppConfig].
final appEnvironmentProvider = Provider<AppEnvironment>((ref) {
  return ref.watch(appConfigProvider).environment;
});
