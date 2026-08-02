import 'package:cryptoedu/core/events/domain_events.dart';
import 'package:cryptoedu/core/events/in_memory_domain_event_publisher.dart';
import 'package:cryptoedu/features/learning/application/domain_event_learning_adapter.dart';
import 'package:cryptoedu/features/learning/application/learning_progression_notifier.dart';
import 'package:cryptoedu/features/learning/domain/learning_event.dart';
import 'package:cryptoedu/features/learning/presentation/missions_screen.dart';
import 'package:cryptoedu/features/learning/presentation/widgets/achievement_cards_grid.dart';
import 'package:cryptoedu/features/learning/presentation/widgets/daily_streak_card.dart';
import 'package:cryptoedu/features/learning/presentation/widgets/level_up_celebration_dialog.dart';
import 'package:cryptoedu/features/learning/presentation/widgets/player_profile_summary_card.dart';
import 'package:cryptoedu/features/learning/presentation/widgets/recent_rewards_timeline.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Phase 7: Gamified Learning UI Integration & State Verification', () {
    Widget createWidgetUnderTest(LearningProgressionNotifier notifier) {
      return ProviderScope(
        overrides: [
          learningProgressionNotifierProvider.overrideWith((ref) => notifier),
        ],
        child: const MaterialApp(
          home: MissionsScreen(),
        ),
      );
    }

    testWidgets(
        '1. XP, Level/Tier, Streak, and Initial State are displayed from real Learning state',
        (tester) async {
      final notifier = LearningProgressionNotifier();
      await tester.pumpWidget(createWidgetUnderTest(notifier));
      await tester.pumpAndSettle();

      // Verify PlayerProfileSummaryCard is present
      expect(find.byType(PlayerProfileSummaryCard), findsOneWidget);
      expect(find.text('Rookie'), findsOneWidget);
      expect(find.text('0 / 99 XP'), findsOneWidget);
      expect(find.text('0 Days'), findsOneWidget);

      // Verify DailyStreakCard is present
      expect(find.byType(DailyStreakCard), findsOneWidget);

      // Verify Educational Missions are listed
      expect(find.text('Complete Onboarding'), findsOneWidget);

      // Verify Achievements section is rendered
      expect(find.byType(AchievementCardsGrid), findsOneWidget);
      expect(find.text('First Steps'), findsOneWidget);
      expect(find.text('Market Explorer'), findsOneWidget);

      // Verify Reward History section is rendered
      expect(find.byType(RecentRewardsTimeline), findsOneWidget);
    });

    testWidgets('2. XP progress and achievements update dynamically on event',
        (tester) async {
      final notifier = LearningProgressionNotifier();
      await tester.pumpWidget(createWidgetUnderTest(notifier));
      await tester.pumpAndSettle();

      // Tap +50 XP button for onboarding mission
      final claimButton = find.widgetWithText(ElevatedButton, '+50 XP').first;
      expect(claimButton, findsOneWidget);
      await tester.tap(claimButton);
      await tester.pumpAndSettle();

      // XP should update to 50 / 99 XP
      expect(find.text('50 / 99 XP'), findsOneWidget);

      // Mission button should change to Completed
      expect(find.text('Completed'), findsWidgets);

      // Unlocked achievement count/status update
      expect(notifier.state.achievements.firstWhere((a) => a.id == 'first_steps').isUnlocked, isTrue);
    });

    testWidgets(
        '3. Level-up dialog appears ONLY on a real level transition and does not duplicate',
        (tester) async {
      final notifier = LearningProgressionNotifier();
      await tester.pumpWidget(createWidgetUnderTest(notifier));
      await tester.pumpAndSettle();

      // Trigger event that passes 100 XP threshold (News Detective = +100 XP)
      notifier.processEvent(
          LearningEvent.newsDetectiveCompleted(eventId: 'evt_news_lvl'));

      await tester.pump(); // Trigger ref.listen callback
      await tester.pump(const Duration(milliseconds: 300));

      // LevelUpCelebrationDialog should be visible
      expect(find.byType(LevelUpCelebrationDialog), findsOneWidget);
      expect(find.text('LEVEL UP!'), findsOneWidget);
      expect(find.text('Explorer'), findsWidgets);

      // Tap CLAIM REWARDS button
      final claimRewardsButton = find.text('CLAIM REWARDS');
      expect(claimRewardsButton, findsOneWidget);
      await tester.tap(claimRewardsButton);
      await tester.pumpAndSettle();

      // Dialog should be dismissed
      expect(find.byType(LevelUpCelebrationDialog), findsNothing);

      // Rebuilding the widget tree should NOT re-open the dialog
      await tester.pumpWidget(createWidgetUnderTest(notifier));
      await tester.pumpAndSettle();
      expect(find.byType(LevelUpCelebrationDialog), findsNothing);
    });

    testWidgets('4. Duplicate events do not award duplicate rewards',
        (tester) async {
      final notifier = LearningProgressionNotifier();
      await tester.pumpWidget(createWidgetUnderTest(notifier));
      await tester.pumpAndSettle();

      // Process event once
      notifier.processEvent(
          LearningEvent.onboardingCompleted(eventId: 'evt_unique_1'));
      await tester.pumpAndSettle();
      expect(notifier.state.totalXp, equals(50));

      // Process same event again
      notifier.processEvent(
          LearningEvent.onboardingCompleted(eventId: 'evt_unique_1'));
      await tester.pumpAndSettle();

      // Total XP remains 50
      expect(notifier.state.totalXp, equals(50));
      expect(notifier.state.lastResult?.isDuplicate, isTrue);
    });

    testWidgets('5. Logout/reset clears displayed Learning state back to initial',
        (tester) async {
      final notifier = LearningProgressionNotifier();
      await tester.pumpWidget(createWidgetUnderTest(notifier));
      await tester.pumpAndSettle();

      // Award XP
      notifier.processEvent(
          LearningEvent.onboardingCompleted(eventId: 'evt_before_reset'));
      await tester.pumpAndSettle();
      expect(find.text('50 / 99 XP'), findsOneWidget);

      // Call reset
      notifier.reset();
      await tester.pumpAndSettle();

      // UI updates back to 0 XP and Rookie
      expect(find.text('0 / 99 XP'), findsOneWidget);
      expect(find.text('Rookie'), findsOneWidget);
    });

    testWidgets(
        '6. Existing domain-event integration updates Gamification UI',
        (tester) async {
      final notifier = LearningProgressionNotifier();
      final publisher = InMemoryDomainEventPublisher();
      final adapter = DomainEventLearningAdapter(
        publisher: publisher,
        notifier: notifier,
      );

      await tester.pumpWidget(createWidgetUnderTest(notifier));
      await tester.pumpAndSettle();

      // Publish a TradeExecuted domain event
      publisher.publish(TradeExecuted(
        tradeId: 'tr_ui_test_1',
        userId: 'u_1',
        symbol: 'BTCUSDT',
        side: 'BUY',
        quantity: 0.5,
        executionPriceInr: 5000000.0,
        totalAmountInr: 2500000.0,
        hasStopLoss: true,
      ));

      await tester.pumpAndSettle();

      // Gamification UI reflects 50 XP gained from First Virtual Trade
      expect(find.text('50 / 99 XP'), findsOneWidget);
      expect(notifier.state.completedMissionIds, contains('m4_first_trade'));

      adapter.dispose();
      publisher.dispose();
    });
  });
}
