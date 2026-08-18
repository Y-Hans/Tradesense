import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:cryptoedu/features/onboarding/presentation/onboarding_screen.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:cryptoedu/core/providers/app_providers.dart';
import 'package:cryptoedu/core/providers/mocks/mock_repositories.dart';
import 'package:cryptoedu/features/auth/application/auth_notifier.dart';

void main() {
  late MockAuthRepository mockAuthRepo;

  setUp(() {
    mockAuthRepo = MockAuthRepository();
  });
  testWidgets('OnboardingScreen renders 3 pages and handles navigation', (WidgetTester tester) async {
    final router = GoRouter(
      initialLocation: '/',
      routes: [
        GoRoute(
          path: '/',
          builder: (context, state) => const OnboardingScreen(),
        ),
        GoRoute(
          path: '/home',
          builder: (context, state) => const Scaffold(body: Text('Home Page')),
        ),
      ],
    );

    await tester.pumpWidget(ProviderScope(
      overrides: [
        authRepositoryProvider.overrideWithValue(mockAuthRepo),
        authStateProvider.overrideWith((ref) => AuthNotifier(mockAuthRepo, authStateChanges: const Stream.empty())),
      ],
      child: MaterialApp.router(
        routerConfig: router,
      ),
    ));
    
    await tester.pumpAndSettle();

    // Page 1 is visible
    expect(find.text('Practice Crypto Safely'), findsOneWidget);

    // Tap Skip
    await tester.tap(find.text('Skip'));
    await tester.pumpAndSettle();
    
    // We expect it navigated to home
    expect(find.text('Home Page'), findsOneWidget);
  });
}
