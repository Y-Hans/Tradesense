import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'app/app.dart';
import 'core/config/app_config.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final config = AppConfig.resolved();

  // Initialise Supabase only when the required defines are present.
  // During local UI-only development (no dart-defines) the SDK is skipped
  // and providers that need it will surface a clear StateError if accessed.
  if (config.isSupabaseConfigured) {
    await Supabase.initialize(
      url: config.supabaseUrl,
      anonKey: config.supabaseAnonKey,
      debug: config.environment.isDebugLoggingEnabled,
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
      child: CryptoEduApp(),
    ),
  );
}
