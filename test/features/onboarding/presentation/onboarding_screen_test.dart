import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:cryptoedu/features/onboarding/presentation/onboarding_screen.dart';

void main() {
  testWidgets('OnboardingScreen renders 3 pages and triggers onGetStarted', (WidgetTester tester) async {
    bool getStartedTriggered = false;

    await tester.pumpWidget(MaterialApp(
      home: OnboardingScreen(
        onGetStarted: () {
          getStartedTriggered = true;
        },
      ),
    ));

    // Page 1 is visible
    expect(find.text('Practice Crypto Safely'), findsOneWidget);

    // Tap Skip
    await tester.tap(find.text('Skip'));
    await tester.pumpAndSettle();
    
    // Verify callback was triggered
    expect(getStartedTriggered, isTrue);

    // Reset flag for further testing
    getStartedTriggered = false;

    // We can't navigate if Skip was pressed in a real app, but here we just triggered the callback.
    // Let's swipe through the pages
    await tester.drag(find.text('Practice Crypto Safely'), const Offset(-500.0, 0.0));
    await tester.pumpAndSettle();

    // Page 2 is visible
    expect(find.text('₹100,000 Virtual Starting Balance'), findsOneWidget);

    await tester.drag(find.text('₹100,000 Virtual Starting Balance'), const Offset(-500.0, 0.0));
    await tester.pumpAndSettle();

    // Page 3 is visible
    expect(find.text('Discipline Score & AI Insights'), findsOneWidget);

    // Tap Get Started
    await tester.tap(find.text('Get Started'));
    await tester.pumpAndSettle();

    expect(getStartedTriggered, isTrue);
  });
}
