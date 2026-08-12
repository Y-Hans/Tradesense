import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cryptoedu/main.dart';

void main() {
  testWidgets('App initializes with TradeSenseApp', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: TradeSenseApp(),
      ),
    );
    await tester.pump(const Duration(seconds: 3));
    await tester.pumpAndSettle();
    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
