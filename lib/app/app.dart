import 'package:flutter/material.dart';
import 'routing/app_router.dart';
import 'theme/app_theme.dart';

class CryptoEduApp extends StatelessWidget {
  const CryptoEduApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'CryptoEdu Simulator',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      routerConfig: appRouter,
    );
  }
}
