import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../config/config_provider.dart';

/// Exposes the initialised [SupabaseClient] as a Riverpod provider.
///
/// The client is sourced from [Supabase.instance.client], which is initialised
/// once in `main()` before [runApp] is called.  This provider exists so that
/// consuming providers and widgets can obtain the client through the standard
/// Riverpod dependency graph rather than calling [Supabase.instance.client]
/// directly — making tests that need to override it straightforward.
///
/// ## Guard behaviour
/// If [AppConfig.isSupabaseConfigured] is `false` (i.e. the `--dart-define`
/// values were not provided at build time) this provider throws a
/// [StateError] with a descriptive message rather than returning a
/// misconfigured client.  This surfaces the misconfiguration early and loudly
/// instead of producing cryptic network errors at runtime.
///
/// ## Usage
/// ```dart
/// final client = ref.watch(supabaseClientProvider);
/// final response = await client.from('profiles').select().single();
/// ```
final supabaseClientProvider = Provider<SupabaseClient>((ref) {
  final config = ref.watch(appConfigProvider);

  if (!config.isSupabaseConfigured) {
    throw StateError(
      'Supabase is not configured. '
      'Provide --dart-define=SUPABASE_URL=<url> and '
      '--dart-define=SUPABASE_ANON_KEY=<key> at build time.',
    );
  }

  // Supabase.initialize() is called in main() before ProviderScope is mounted,
  // so Supabase.instance.client is always available here when configured.
  return Supabase.instance.client;
});
