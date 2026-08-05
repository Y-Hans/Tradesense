import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cryptoedu/app/app.dart';

void main() {
  testWidgets('CryptoEduApp renders HomeScreen dashboard successfully',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: CryptoEduApp(),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.textContaining('Trader'), findsOneWidget);
    expect(find.text('Total Portfolio Value'), findsOneWidget);
    expect(find.text('Watchlist'), findsOneWidget);
  });
}
