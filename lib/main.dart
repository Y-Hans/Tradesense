import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:design_system/design_system.dart';
import 'core/routing/app_router.dart';

import 'app/theme/theme_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // TODO: Replace with real credentials in production
  await Supabase.initialize(
    url: 'https://mock-url.supabase.co',
    publishableKey: 'mock-anon-key',
  );

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
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeMode,
      routerConfig: goRouter,
      debugShowCheckedModeBanner: false,
    );
  }
}
