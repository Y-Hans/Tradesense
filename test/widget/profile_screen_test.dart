import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:cryptoedu/core/providers/app_providers.dart';
import 'package:cryptoedu/core/providers/mocks/mock_repositories.dart';
import 'package:cryptoedu/features/auth/application/auth_notifier.dart';
import 'package:cryptoedu/features/profile/presentation/profile_screen.dart';
import 'package:cryptoedu/features/profile/data/profile_repository.dart';
import 'package:cryptoedu/features/profile/domain/profile_state.dart';

void main() {
  late MockAuthRepository mockAuthRepo;

  setUp(() {
    mockAuthRepo = MockAuthRepository();
  });

  Widget createWidgetUnderTest() {
    return ProviderScope(
      overrides: [
        authRepositoryProvider.overrideWithValue(mockAuthRepo),
        authStateProvider.overrideWith((ref) => AuthNotifier(mockAuthRepo, authStateChanges: const Stream.empty())),
      ],
      child: const MaterialApp(
        home: ProfileScreen(),
      ),
    );
  }

  group('ProfileScreen Widget Tests', () {
    testWidgets('renders user profile header, email, balance, and disclaimers',
        (WidgetTester tester) async {
      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      expect(find.text('Account & Profile'), findsOneWidget);
      expect(find.text('DisciplineTrader'), findsOneWidget);
      expect(find.text('trader@cryptoedu.app'), findsOneWidget);
      expect(find.textContaining('Starting Balance:'), findsOneWidget);
      expect(
          find.textContaining('Educational Simulation Notice'), findsOneWidget);
    });

    testWidgets('tapping Privacy & Disclaimers opens disclosure dialog',
        (WidgetTester tester) async {
      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      final privacyTile = find.text('Privacy & Disclaimers');
      expect(privacyTile, findsOneWidget);

      await tester.ensureVisible(privacyTile);
      await tester.pumpAndSettle();

      await tester.tap(privacyTile);
      await tester.pumpAndSettle();

      expect(find.text('Privacy & Disclosures'), findsOneWidget);
      expect(find.textContaining('This is an educational trading simulation.'),
          findsWidgets);

      final closeButton = find.text('Close');
      await tester.tap(closeButton);
      await tester.pumpAndSettle();

      expect(find.text('Privacy & Disclosures'), findsNothing);
    });

    testWidgets('delete account flow opens confirmation step 1 and step 2',
        (WidgetTester tester) async {
      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      final deleteTile = find.text('Delete Account & Private Data');
      expect(deleteTile, findsOneWidget);

      await tester.ensureVisible(deleteTile);
      await tester.pumpAndSettle();

      await tester.tap(deleteTile);
      await tester.pumpAndSettle();

      // Step 1 Confirmation
      expect(find.text('Delete Account'), findsWidgets);
      expect(
          find.textContaining('Are you sure you want to delete your account?'),
          findsOneWidget);

      final firstDeleteButton = find.widgetWithText(ElevatedButton, 'Delete');
      await tester.tap(firstDeleteButton);
      await tester.pumpAndSettle();

      // Step 2 Final Confirmation
      expect(find.text('Final Confirmation'), findsOneWidget);
      expect(find.textContaining('This is your final confirmation.'),
          findsOneWidget);

      final finalConfirmButton =
          find.widgetWithText(ElevatedButton, 'Confirm Deletion');
      await tester.tap(finalConfirmButton);
      await tester.pumpAndSettle();

      expect(await mockAuthRepo.getCurrentUser(), isNull);
    });

    testWidgets('shows error view and retry button when profile loading fails',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authRepositoryProvider.overrideWithValue(mockAuthRepo),
            authStateProvider.overrideWith((ref) => AuthNotifier(mockAuthRepo, authStateChanges: const Stream.empty())),
            profileRepositoryProvider.overrideWithValue(ThrowingProfileRepository()),
          ],
          child: const MaterialApp(
            home: ProfileScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Failed to load profile'), findsOneWidget);
      expect(find.text('Retry'), findsOneWidget);
    });
  });
}

class ThrowingProfileRepository extends ProfileRepository {
  @override
  Future<UserProfile> fetchProfile({String? name, String? email}) async {
    throw Exception('Database connection timeout');
  }
}

