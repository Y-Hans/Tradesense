import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cryptoedu/features/home/presentation/home_screen.dart';

void main() {
  testWidgets('DashboardScreen renders successfully',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: DashboardScreen(),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Virtual Portfolio Equity'), findsOneWidget);
    expect(find.text('Unrealised P&L'), findsOneWidget);
    expect(find.text('Discipline Score'), findsOneWidget);
  });
}
