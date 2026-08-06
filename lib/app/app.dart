import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/routing/app_router.dart';
import 'shell/app_shell.dart';
import 'package:design_system/design_system.dart';
import 'theme/app_theme.dart';

class CryptoEduApp extends ConsumerWidget {
  const CryptoEduApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(appRouterProvider);
    return MaterialApp.router(
      title: 'CryptoEdu Simulator',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      routerConfig: router,
      builder: (context, child) => AppShell(child: child),
    );
  }
}

