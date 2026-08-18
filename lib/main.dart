import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:design_system/design_system.dart';
import 'core/routing/app_router.dart';
import 'app/theme/theme_provider.dart';
import 'app/theme/app_theme.dart' as local_theme;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'core/config/app_config.dart';
import 'core/config/secure_local_storage.dart';

import 'core/config/app_preferences.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await AppPreferences.initialize();

  final config = AppConfig.resolved();

  // Initialise Supabase only when the required defines are present.
  // During local UI-only development (no dart-defines) the SDK is skipped
  // and providers that need it will surface a clear StateError if accessed.
  if (config.isSupabaseConfigured) {
    // Sanitize the URL to remove accidental quotes, whitespace, or trailing slashes
    // which can cause SocketException during host lookup.
    String cleanUrl = config.supabaseUrl.trim().replaceAll('"', '').replaceAll("'", "");
    if (cleanUrl.endsWith('/')) {
      cleanUrl = cleanUrl.substring(0, cleanUrl.length - 1);
    }
    
    // Temporary diagnostic logging (hostname only, no secrets)
    try {
      final uri = Uri.parse(cleanUrl);
      debugPrint('[Supabase Diagnostic] Parsed Hostname: ${uri.host}');
    } catch (e) {
      debugPrint('[Supabase Diagnostic] Error parsing URL: $e');
    }

    await Supabase.initialize(
      url: cleanUrl,
      publishableKey: config.supabaseAnonKey.trim().replaceAll('"', '').replaceAll("'", ""),
      debug: config.environment.isDebugLoggingEnabled,
      authOptions: const FlutterAuthClientOptions(
        localStorage: SecureLocalStorage(),
      ),
    );
  }

  // Initialise Firebase using standard FlutterFire initialization.
  // If configuration is unavailable (e.g. missing native google-services.json /
  // GoogleService-Info.plist during local UI development), fail gracefully.
  try {
    await Firebase.initializeApp();
  } catch (e) {
    debugPrint('[Firebase] Initialisation skipped or failed: $e');
  }

  // Initialise RevenueCat only when the public SDK key is present.
  // During local UI-only development (no dart-define) the SDK is skipped
  // and purchasesProvider will surface a clear StateError if accessed.
  if (config.isRevenueCatConfigured) {
    await Purchases.configure(
      PurchasesConfiguration(config.revenueCatPublicKey),
    );
  }

  runApp(
    const ProviderScope(
      child: TradeSenseApp(),
    ),
  );
}

class TradeSenseApp extends ConsumerWidget {
  const TradeSenseApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final goRouter = ref.watch(appRouterProvider);
    final themeMode = ref.watch(themeModeProvider);

    return MaterialApp.router(
      title: 'TradeSense',
      theme: local_theme.AppTheme.lightTheme,
      darkTheme: local_theme.AppTheme.darkTheme,
      themeMode: themeMode,
      routerConfig: goRouter,
      debugShowCheckedModeBanner: false,
    );
  }
}
