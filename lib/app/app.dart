import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/providers/theme_provider.dart';
import 'routing/app_router.dart';
import 'theme/app_theme.dart';

class CryptoEduApp extends ConsumerWidget {
  const CryptoEduApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);

    ThemeData activeTheme;
    switch (themeMode) {
      case AppThemeMode.light:
        activeTheme = AppTheme.lightTheme;
        break;
      case AppThemeMode.dark:
        activeTheme = AppTheme.darkTheme;
        break;
      case AppThemeMode.special:
        activeTheme = AppTheme.specialTheme;
        break;
    }

    return MaterialApp.router(
      title: 'CryptoEdu Simulator',
      debugShowCheckedModeBanner: false,
      theme: activeTheme,
      routerConfig: appRouter,
    );
  }
}
