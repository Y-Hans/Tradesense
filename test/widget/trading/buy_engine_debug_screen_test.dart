import 'package:cryptoedu/app/routing/app_router.dart';
import 'package:cryptoedu/features/trading/presentation/debug/buy_engine_debug_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

void main() {
  testWidgets('debug screen displays the one crore initial wallet',
      (tester) async {
    await _pumpScreen(tester);

    _expectTextByKey(
      tester,
      'buy-engine-wallet-balance',
      '\u20B91,00,00,000.00',
    );
    expect(find.text('No holding'), findsOneWidget);
  });

  testWidgets('valid first BUY updates displayed wallet and holding',
      (tester) async {
    await _pumpScreen(tester);

    await _enterText(tester, 'buy-engine-amount-field', '100000');
    await _enterText(tester, 'buy-engine-price-field', '5000000');
    await _tap(tester, 'buy-engine-execute-button');

    expect(find.text('\u20B999,00,000.00'), findsWidgets);
    expect(find.text('0.02 BTC'), findsOneWidget);
    expect(find.text('SUCCESS'), findsOneWidget);
    expect(find.text('debug_buy_trade_1'), findsOneWidget);
  });

  testWidgets('repeated BUY updates quantity and weighted average display',
      (tester) async {
    await _pumpScreen(tester);

    await _tap(tester, 'buy-engine-execute-button');
    await _tap(tester, 'buy-engine-second-scenario-button');
    await _tap(tester, 'buy-engine-execute-button');

    _expectTextByKey(
      tester,
      'buy-engine-wallet-balance',
      '\u20B997,00,000.00',
    );
    expect(
      _textByKey(tester, 'buy-engine-holding-quantity'),
      '0.0563636363636 BTC',
    );
    expect(find.text('\u20B953,22,580.65'), findsWidgets);
    expect(find.text('debug_buy_trade_2'), findsOneWidget);
  });

  testWidgets('insufficient funds rejection leaves state unchanged',
      (tester) async {
    await _pumpScreen(tester);

    await _tap(tester, 'buy-engine-insufficient-funds-button');

    _expectTextByKey(
      tester,
      'buy-engine-wallet-balance',
      '\u20B91,00,00,000.00',
    );
    expect(find.text('No holding'), findsOneWidget);
    expect(find.text('REJECTED'), findsOneWidget);
    expect(
      find.text('TradingFailureCode.insufficientFunds'),
      findsOneWidget,
    );
    expect(find.text('Wallet and holding state unchanged.'), findsOneWidget);
  });

  testWidgets('reset restores the initial in-memory state', (tester) async {
    await _pumpScreen(tester);

    await _tap(tester, 'buy-engine-execute-button');
    await _tap(tester, 'buy-engine-reset-button');

    _expectTextByKey(
      tester,
      'buy-engine-wallet-balance',
      '\u20B91,00,00,000.00',
    );
    expect(find.text('No holding'), findsOneWidget);
    expect(find.text('None'), findsOneWidget);
  });

  testWidgets('invalid text input does not crash', (tester) async {
    await _pumpScreen(tester);

    await _enterText(tester, 'buy-engine-amount-field', 'not-a-number');
    await _tap(tester, 'buy-engine-execute-button');

    expect(find.text('INPUT ERROR'), findsOneWidget);
    expect(
      find.text(
          'Invalid INR amount or market price text. Enter numeric values.'),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });

  test('debug buy route is omitted when debug routes are disabled', () {
    final router = createAppRouter(
      includeDebugRoutes: false,
      useBuyEngineDebugHome: true,
    );
    addTearDown(router.dispose);

    expect(_containsPath(router.configuration.routes, '/home'), isTrue);
    expect(_containsPath(router.configuration.routes, '/debug/buy-engine'),
        isFalse);
  });
}

Future<void> _pumpScreen(WidgetTester tester) async {
  await tester.pumpWidget(
    const MaterialApp(
      home: BuyEngineDebugScreen(),
    ),
  );
}

Future<void> _enterText(
  WidgetTester tester,
  String key,
  String text,
) async {
  final finder = find.byKey(Key(key));
  await tester.ensureVisible(finder);
  await tester.enterText(finder, text);
  await tester.pump();
}

Future<void> _tap(WidgetTester tester, String key) async {
  final finder = find.byKey(Key(key));
  await tester.ensureVisible(finder);
  await tester.tap(finder);
  await tester.pump();
}

bool _containsPath(List<RouteBase> routes, String path) {
  for (final route in routes) {
    if (route is GoRoute && route.path == path) {
      return true;
    }
    if (_containsPath(route.routes, path)) {
      return true;
    }
  }
  return false;
}

void _expectTextByKey(WidgetTester tester, String key, String expected) {
  expect(_textByKey(tester, key), expected);
}

String _textByKey(WidgetTester tester, String key) {
  final widget = tester.widget<Text>(find.byKey(Key(key)));
  return widget.data ?? '';
}
