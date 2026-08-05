import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cryptoedu/app/app.dart';

void main() {
  testWidgets('App initializes with CryptoEduApp', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: CryptoEduApp(),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.textContaining('Trader'), findsOneWidget);
  });
}
