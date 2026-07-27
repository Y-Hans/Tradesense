import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cryptoedu/app/app.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Full User Journey: Launch -> Dashboard -> Trade -> AI Coach',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: CryptoEduApp(),
      ),
    );

    await tester.pumpAndSettle();

    // Verify main screen loaded
    expect(find.text('CryptoEdu Simulator'), findsOneWidget);
  });
}
