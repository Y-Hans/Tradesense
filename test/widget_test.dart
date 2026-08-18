import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cryptoedu/main.dart';
import 'package:cryptoedu/core/config/app_preferences.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('App initializes with TradeSenseApp', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
    final preferences = await SharedPreferences.getInstance();
    await preferences.clear();
    await AppPreferences.initialize(preferences: preferences);

    try {
      await tester.pumpWidget(
        const ProviderScope(
          child: TradeSenseApp(),
        ),
      );
      await tester.pump(const Duration(seconds: 3));
      await tester.pumpAndSettle();
      expect(find.byType(MaterialApp), findsOneWidget);
    } finally {
      await AppPreferences.resetForTesting();
    }
  });
}
