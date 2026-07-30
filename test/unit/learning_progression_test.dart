import 'package:cryptoedu/core/events/domain_event.dart';
import 'package:cryptoedu/core/events/domain_events.dart';
import 'package:cryptoedu/core/events/in_memory_domain_event_publisher.dart';
import 'package:cryptoedu/features/learning/application/domain_event_learning_adapter.dart';
import 'package:cryptoedu/features/learning/application/learning_progression_notifier.dart';
import 'package:cryptoedu/features/learning/application/level_engine.dart';
import 'package:cryptoedu/features/learning/application/mission_engine.dart';
import 'package:cryptoedu/features/learning/application/xp_engine.dart';
import 'package:cryptoedu/features/learning/domain/learning_event.dart';
import 'package:cryptoedu/features/learning/domain/learning_title.dart';
import 'package:cryptoedu/features/learning/domain/level.dart';
import 'package:cryptoedu/features/learning/domain/mission.dart';
import 'package:cryptoedu/features/learning/domain/xp_state.dart';
import 'package:flutter_test/flutter_test.dart';

class UnknownTestDomainEvent extends DomainEvent {
  UnknownTestDomainEvent() : super(eventType: 'UnknownTestDomainEvent');
}

void main() {
  group('XP Engine & Duplicate Prevention Tests', () {
    test('XpEngine calculates XP for valid matching mission event', () {
      final event = LearningEvent.onboardingCompleted(eventId: 'evt_onboard_1');
      const mission = Mission(
        id: 'm1_onboarding',
        title: 'Complete Onboarding',
        description: 'Finish onboarding',
        xpReward: 50,
        eventType: LearningEventType.onboardingCompleted,
      );
      const xpState = XpState();

      final award = XpEngine.calculateXpAward(
        event: event,
        mission: mission,
        currentXpState: xpState,
      );

      expect(award.xpAwarded, equals(50));
      expect(award.isDuplicate, isFalse);
    });

    test('XpEngine prevents duplicate XP award for already completed mission',
        () {
      final event = LearningEvent.onboardingCompleted(eventId: 'evt_onboard_2');
      const mission = Mission(
        id: 'm1_onboarding',
        title: 'Complete Onboarding',
        description: 'Finish onboarding',
        xpReward: 50,
        eventType: LearningEventType.onboardingCompleted,
      );
      const xpState = XpState(completedMissionIds: {'m1_onboarding'});

      final award = XpEngine.calculateXpAward(
        event: event,
        mission: mission,
        currentXpState: xpState,
      );

      expect(award.xpAwarded, equals(0));
      expect(award.isDuplicate, isTrue);
    });

    test('XpEngine prevents duplicate XP award for already processed event',
        () {
      final event = LearningEvent.onboardingCompleted(eventId: 'evt_dup_123');
      const mission = Mission(
        id: 'm1_onboarding',
        title: 'Complete Onboarding',
        description: 'Finish onboarding',
        xpReward: 50,
        eventType: LearningEventType.onboardingCompleted,
      );
      const xpState = XpState(processedEventIds: {'evt_dup_123'});

      final award = XpEngine.calculateXpAward(
        event: event,
        mission: mission,
        currentXpState: xpState,
      );

      expect(award.xpAwarded, equals(0));
      expect(award.isDuplicate, isTrue);
    });

    test('XP calculation never uses trade profit or financial metrics', () {
      final tradeEvent = LearningEvent.firstTradeCompleted(
        eventId: 'trade_1',
        metadata: {'profitInr': 999999.0, 'roiPercentage': 500.0},
      );
      const mission = Mission(
        id: 'm4_first_trade',
        title: 'First Virtual Trade',
        description: 'Execute your first simulated order',
        xpReward: 50,
        eventType: LearningEventType.firstTradeCompleted,
      );

      final award = XpEngine.calculateXpAward(
        event: tradeEvent,
        mission: mission,
        currentXpState: const XpState(),
      );

      // Reward is strictly fixed educational XP (50), ignoring profit of 999,999 INR
      expect(award.xpAwarded, equals(50));
    });
  });

  group('Deterministic Level & Title Engine Tests', () {
    test('Level.fromXp calculates exact level tiers for thresholds', () {
      expect(Level.fromXp(0).tier, equals(LevelTier.rookie));
      expect(Level.fromXp(99).tier, equals(LevelTier.rookie));

      expect(Level.fromXp(100).tier, equals(LevelTier.explorer));
      expect(Level.fromXp(249).tier, equals(LevelTier.explorer));

      expect(Level.fromXp(250).tier, equals(LevelTier.riskAwareTrader));
      expect(Level.fromXp(429).tier, equals(LevelTier.riskAwareTrader));

      expect(Level.fromXp(430).tier, equals(LevelTier.disciplinedTrader));
      expect(Level.fromXp(1000).tier, equals(LevelTier.disciplinedTrader));
    });

    test('LearningTitle.fromXp calculates title progression correctly', () {
      expect(
          LearningTitle.fromXp(0).type, equals(LearningTitleType.cryptoRookie));
      expect(LearningTitle.fromXp(100).type,
          equals(LearningTitleType.marketExplorer));
      expect(LearningTitle.fromXp(250).type,
          equals(LearningTitleType.riskAwareTrader));
      expect(LearningTitle.fromXp(430).type,
          equals(LearningTitleType.disciplinedTrader));
      expect(LearningTitle.fromXp(750).type,
          equals(LearningTitleType.cryptoMentor));
    });

    test(
        'LevelEngine computes progress fraction and XP to next tier accurately',
        () {
      // Rookie: 0 to 99 (range = 100)
      final evalRookie =
          LevelEngine.evaluateLevel(previousXp: 0, currentXp: 50);
      expect(evalRookie.currentLevel.tier, equals(LevelTier.rookie));
      expect(evalRookie.progressToNext, closeTo(0.5, 0.01));
      expect(evalRookie.xpToNext, equals(50));
      expect(evalRookie.didLevelUp, isFalse);

      // Transition to Explorer
      final evalLevelUp =
          LevelEngine.evaluateLevel(previousXp: 90, currentXp: 100);
      expect(evalLevelUp.currentLevel.tier, equals(LevelTier.explorer));
      expect(evalLevelUp.didLevelUp, isTrue);

      // Max level (Disciplined Trader)
      final evalMax =
          LevelEngine.evaluateLevel(previousXp: 500, currentXp: 550);
      expect(evalMax.currentLevel.tier, equals(LevelTier.disciplinedTrader));
      expect(evalMax.progressToNext, equals(1.0));
      expect(evalMax.xpToNext, equals(0));
      expect(evalMax.didLevelUp, isFalse);
    });
  });

  group('Mission Engine & Idempotency Tests', () {
    test('MissionEngine processes event and completes matching mission', () {
      final event = LearningEvent.onboardingCompleted(eventId: 'onb_evt_1');
      final result = MissionEngine.processEvent(
        event: event,
        missions: Mission.initialMissions,
        xpState: const XpState(),
      );

      expect(result.isIdempotentSkip, isFalse);
      expect(result.totalXpGained, equals(50));
      expect(result.newlyCompletedMissions.length, equals(1));
      expect(result.newlyCompletedMissions.first.id, equals('m1_onboarding'));
      expect(result.updatedXpState.totalXp, equals(50));
      expect(
          result.updatedXpState.completedMissionIds, contains('m1_onboarding'));
      expect(result.updatedXpState.processedEventIds, contains('onb_evt_1'));
    });

    test(
        'MissionEngine is completely idempotent when receiving identical event twice',
        () {
      final event = LearningEvent.loginCompleted(eventId: 'login_evt_dup');

      final firstResult = MissionEngine.processEvent(
        event: event,
        missions: Mission.initialMissions,
        xpState: const XpState(),
      );

      expect(firstResult.totalXpGained, equals(30));

      final secondResult = MissionEngine.processEvent(
        event: event,
        missions: firstResult.updatedMissions,
        xpState: firstResult.updatedXpState,
      );

      expect(secondResult.isIdempotentSkip, isTrue);
      expect(secondResult.totalXpGained, equals(0));
      expect(secondResult.newlyCompletedMissions, isEmpty);
      expect(secondResult.updatedXpState.totalXp, equals(30));
    });
  });

  group('LearningProgressionNotifier Extended Gamification Tests', () {
    late LearningProgressionNotifier notifier;

    setUp(() {
      notifier = LearningProgressionNotifier();
    });

    tearDown(() {
      notifier.dispose();
    });

    test(
        'Initial state exposes title, profile summary, streak, and initial achievements',
        () {
      final state = notifier.state;
      expect(state.totalXp, equals(0));
      expect(state.currentLevel.tier, equals(LevelTier.rookie));
      expect(state.currentTitle.title, equals('Crypto Rookie'));
      expect(state.streak.currentStreak, equals(0));
      expect(state.achievements.length, equals(11));
      expect(state.playerProfileSummary.totalXp, equals(0));
      expect(state.playerProfileSummary.achievementsUnlocked, equals('0 / 11'));
      expect(state.playerProfileSummary.missionsCompleted, equals('0 / 9'));
      expect(state.showXpGainAnimation, isFalse);
      expect(state.showLevelUpAnimation, isFalse);
    });

    test(
        'processEvent updates streak, unlocks achievements, updates summary, and sets animation flags',
        () {
      final event =
          LearningEvent.onboardingCompleted(eventId: 'onboard_gami_1');
      notifier.processEvent(event);

      final state = notifier.state;
      expect(state.totalXp, equals(50));
      expect(state.streak.currentStreak, equals(1));
      expect(state.showXpGainAnimation, isTrue);
      expect(state.recentXpGained, equals(50));
      expect(
          state.achievements.any((a) => a.id == 'first_steps' && a.isUnlocked),
          isTrue);
      expect(state.playerProfileSummary.achievementsUnlocked,
          equals('2 / 11')); // first_steps & learning_streak (streak=1)
      expect(state.playerProfileSummary.missionsCompleted, equals('1 / 9'));
    });

    test('dismissXpGainAnimation resets showXpGainAnimation and recentXpGained',
        () {
      notifier.processEvent(
          LearningEvent.onboardingCompleted(eventId: 'evt_anim_1'));
      expect(notifier.state.showXpGainAnimation, isTrue);
      expect(notifier.state.recentXpGained, equals(50));

      notifier.dismissXpGainAnimation();

      expect(notifier.state.showXpGainAnimation, isFalse);
      expect(notifier.state.recentXpGained, equals(0));
    });

    test(
        'dismissLevelUpAnimation resets showLevelUpAnimation and unlockedAchievements',
        () {
      // News Detective = +100 XP -> triggers level up from Rookie to Explorer
      notifier.processEvent(
          LearningEvent.newsDetectiveCompleted(eventId: 'evt_lvl_1'));
      expect(notifier.state.showLevelUpAnimation, isTrue);

      notifier.dismissLevelUpAnimation();

      expect(notifier.state.showLevelUpAnimation, isFalse);
      expect(notifier.state.unlockedAchievements, isEmpty);
    });

    test('claimMission claims rewards manually and prevents secondary claims',
        () {
      final claimResult1 = notifier.claimMission('m3_view_market');
      expect(claimResult1.success, isTrue);
      expect(claimResult1.xpGained, equals(30));
      expect(notifier.state.totalXp, equals(30));

      final claimResult2 = notifier.claimMission('m3_view_market');
      expect(claimResult2.isDuplicate, isTrue);
      expect(claimResult2.xpGained, equals(0));
      expect(notifier.state.totalXp, equals(30));
    });

    test(
        'restoreState accurately restores progression state, streak, and summary',
        () {
      notifier.restoreState(
        totalXp: 300,
        completedMissionIds: {'m1_onboarding', 'm2_login', 'm6_news_detective'},
        processedEventIds: {'evt_1', 'evt_2', 'evt_3'},
      );

      expect(notifier.state.totalXp, equals(300));
      expect(
          notifier.state.currentLevel.tier, equals(LevelTier.riskAwareTrader));
      expect(notifier.state.currentTitle.title, equals('Risk-Aware Trader'));
      expect(notifier.state.completedMissionIds.length, equals(3));
      expect(notifier.state.playerProfileSummary.missionsCompleted,
          equals('3 / 9'));
    });

    test('reset clears learning progression back to initial state', () {
      notifier.claimMission('m1_onboarding');
      expect(notifier.state.totalXp, equals(50));

      notifier.reset();

      expect(notifier.state.totalXp, equals(0));
      expect(notifier.state.currentLevel.tier, equals(LevelTier.rookie));
      expect(notifier.state.completedMissionIds, isEmpty);
      expect(notifier.state.processedEventIds, isEmpty);
    });
  });

  group('DomainEventLearningAdapter & Business Event Integration Tests', () {
    late InMemoryDomainEventPublisher publisher;
    late LearningProgressionNotifier notifier;
    late DomainEventLearningAdapter adapter;

    setUp(() {
      publisher = InMemoryDomainEventPublisher();
      notifier = LearningProgressionNotifier();
      adapter = DomainEventLearningAdapter(
        publisher: publisher,
        notifier: notifier,
      );
    });

    tearDown(() {
      adapter.dispose();
      notifier.dispose();
      publisher.dispose();
    });

    test('1. TradeExecuted completes existing First Virtual Trade progression',
        () {
      final tradeEvent = TradeExecuted(
        tradeId: 'tr_100',
        userId: 'u_1',
        symbol: 'BTCUSDT',
        side: 'BUY',
        quantity: 0.1,
        executionPriceInr: 5000000.0,
        totalAmountInr: 500000.0,
        hasStopLoss: true,
      );

      publisher.publish(tradeEvent);

      expect(notifier.state.completedMissionIds, contains('m4_first_trade'));
      expect(notifier.state.totalXp, equals(50));
      expect(
          notifier.state.achievements
              .any((a) => a.id == 'first_trade' && a.isUnlocked),
          isTrue);
    });

    test('2. Repeated TradeExecuted does not duplicate the reward', () {
      final tradeEvent = TradeExecuted(
        tradeId: 'tr_101',
        userId: 'u_1',
        symbol: 'ETHUSDT',
        side: 'BUY',
        quantity: 1.0,
        executionPriceInr: 300000.0,
        totalAmountInr: 300000.0,
        hasStopLoss: true,
      );

      publisher.publish(tradeEvent);
      expect(notifier.state.totalXp, equals(50));

      // Publish exact duplicate TradeExecuted
      publisher.publish(tradeEvent);
      expect(notifier.state.totalXp, equals(50));
      expect(notifier.state.lastResult?.isDuplicate, isTrue);

      // Publish second TradeExecuted with different trade ID
      final secondTrade = TradeExecuted(
        tradeId: 'tr_102',
        userId: 'u_1',
        symbol: 'SOLUSDT',
        side: 'BUY',
        quantity: 5.0,
        executionPriceInr: 15000.0,
        totalAmountInr: 75000.0,
        hasStopLoss: false,
      );
      publisher.publish(secondTrade);
      // Mission m4_first_trade already completed -> 0 additional XP
      expect(notifier.state.totalXp, equals(50));
    });

    test(
        '3. RiskEvaluationCompleted triggers intended risk-learning progression',
        () {
      final riskEvent = RiskEvaluationCompleted(
        riskScore: 85,
        riskLevel: 'LOW',
        reasonCodes: const ['STOP_LOSS_PRESENT'],
        proposedTradeSizeInr: 10000.0,
        hasStopLoss: true,
        occurredAt: DateTime(2026, 7, 30, 10, 0),
      );

      publisher.publish(riskEvent);

      expect(
          notifier.state.completedMissionIds, contains('m7_risk_evaluation'));
      expect(notifier.state.totalXp, equals(40));
      expect(
          notifier.state.achievements
              .any((a) => a.id == 'risk_aware' && a.isUnlocked),
          isTrue);
    });

    test('4. Duplicate risk events do not award duplicate XP', () {
      final riskEvent = RiskEvaluationCompleted(
        riskScore: 85,
        riskLevel: 'LOW',
        reasonCodes: const ['STOP_LOSS_PRESENT'],
        proposedTradeSizeInr: 10000.0,
        hasStopLoss: true,
        occurredAt: DateTime(2026, 7, 30, 10, 0),
      );

      publisher.publish(riskEvent);
      expect(notifier.state.totalXp, equals(40));

      // Publish same risk event again
      publisher.publish(riskEvent);
      expect(notifier.state.totalXp, equals(40));
      expect(notifier.state.lastResult?.isDuplicate, isTrue);
    });

    test('5. DisciplineEvaluationCompleted triggers discipline progression',
        () {
      final disciplineEvent = DisciplineEvaluationCompleted(
        disciplineScore: 92,
        reasonCodes: const ['PROPER_POSITION_SIZE'],
        positionSizePercentage: 3.5,
        usedStopLoss: true,
        occurredAt: DateTime(2026, 7, 30, 11, 0),
      );

      publisher.publish(disciplineEvent);

      expect(notifier.state.completedMissionIds,
          contains('m8_discipline_evaluation'));
      expect(notifier.state.totalXp, equals(40));
      expect(
          notifier.state.achievements
              .any((a) => a.id == 'disciplined_trader' && a.isUnlocked),
          isTrue);
    });

    test('6. Duplicate discipline events do not award duplicate XP', () {
      final disciplineEvent = DisciplineEvaluationCompleted(
        disciplineScore: 92,
        reasonCodes: const ['PROPER_POSITION_SIZE'],
        positionSizePercentage: 3.5,
        usedStopLoss: true,
        occurredAt: DateTime(2026, 7, 30, 11, 0),
      );

      publisher.publish(disciplineEvent);
      expect(notifier.state.totalXp, equals(40));

      publisher.publish(disciplineEvent);
      expect(notifier.state.totalXp, equals(40));
      expect(notifier.state.lastResult?.isDuplicate, isTrue);
    });

    test('7. CoachSessionCompleted triggers coaching/reflection progression',
        () {
      final coachEvent = CoachSessionCompleted(
        tradeId: 'tr_200',
        userId: 'u_1',
        riskScore: 85,
        disciplineScore: 92,
        isFallback: false,
        providerName: 'gemini',
        occurredAt: DateTime(2026, 7, 30, 12, 0),
      );

      publisher.publish(coachEvent);

      expect(notifier.state.completedMissionIds, contains('m9_coach_session'));
      expect(notifier.state.totalXp, equals(50));
      expect(
          notifier.state.achievements
              .any((a) => a.id == 'coach_reflection' && a.isUnlocked),
          isTrue);
    });

    test('8. Duplicate coach events do not award duplicate XP', () {
      final coachEvent = CoachSessionCompleted(
        tradeId: 'tr_200',
        userId: 'u_1',
        riskScore: 85,
        disciplineScore: 92,
        isFallback: false,
        providerName: 'gemini',
        occurredAt: DateTime(2026, 7, 30, 12, 0),
      );

      publisher.publish(coachEvent);
      expect(notifier.state.totalXp, equals(50));

      publisher.publish(coachEvent);
      expect(notifier.state.totalXp, equals(50));
      expect(notifier.state.lastResult?.isDuplicate, isTrue);
    });

    test('9. Unknown DomainEvent types are ignored safely', () {
      final unknownEvent = UnknownTestDomainEvent();

      publisher.publish(unknownEvent);

      expect(notifier.state.totalXp, equals(0));
      expect(notifier.state.completedMissionIds, isEmpty);
    });

    test('10. Existing V1 missions m1-m6 continue to work', () {
      const missions = Mission.initialMissions;
      expect(missions.length, equals(9));
      expect(
          missions.take(6).map((m) => m.id),
          equals([
            'm1_onboarding',
            'm2_login',
            'm3_view_market',
            'm4_first_trade',
            'm5_read_education',
            'm6_news_detective',
          ]));

      // Verify processing each V1 event
      notifier
          .processEvent(LearningEvent.onboardingCompleted(eventId: 'v1_onb'));
      notifier.processEvent(LearningEvent.loginCompleted(eventId: 'v1_log'));
      notifier.processEvent(LearningEvent.viewedMarket(eventId: 'v1_mkt'));
      notifier.processEvent(LearningEvent.completedLesson(eventId: 'v1_les'));
      notifier.processEvent(
          LearningEvent.newsDetectiveCompleted(eventId: 'v1_news'));

      expect(notifier.state.completedMissionIds.length, equals(5));
      expect(notifier.state.totalXp, equals(250)); // 50+30+30+40+100
    });

    test('11. Existing XP and level thresholds remain unchanged', () {
      expect(Level.fromXp(0).tier, equals(LevelTier.rookie));
      expect(Level.fromXp(100).tier, equals(LevelTier.explorer));
      expect(Level.fromXp(250).tier, equals(LevelTier.riskAwareTrader));
      expect(Level.fromXp(430).tier, equals(LevelTier.disciplinedTrader));
    });

    test('12. Existing achievement behavior remains unchanged', () {
      notifier
          .processEvent(LearningEvent.onboardingCompleted(eventId: 'ach_1'));
      expect(
          notifier.state.achievements
              .any((a) => a.id == 'first_steps' && a.isUnlocked),
          isTrue);

      notifier.processEvent(LearningEvent.viewedMarket(eventId: 'ach_2'));
      expect(
          notifier.state.achievements
              .any((a) => a.id == 'market_explorer' && a.isUnlocked),
          isTrue);

      notifier.processEvent(LearningEvent.completedLesson(eventId: 'ach_3'));
      expect(
          notifier.state.achievements
              .any((a) => a.id == 'curious_learner' && a.isUnlocked),
          isTrue);
    });

    test('13. reset() still clears runtime progression correctly', () {
      publisher.publish(TradeExecuted(
        tradeId: 'tr_300',
        userId: 'u_1',
        symbol: 'BTCUSDT',
        side: 'BUY',
        quantity: 1.0,
        executionPriceInr: 1000.0,
        totalAmountInr: 1000.0,
        hasStopLoss: true,
      ));

      expect(notifier.state.totalXp, equals(50));

      notifier.reset();

      expect(notifier.state.totalXp, equals(0));
      expect(notifier.state.completedMissionIds, isEmpty);
      expect(notifier.state.processedEventIds, isEmpty);
    });

    test(
        '14. Learning module does not depend on concrete Risk, Discipline, Trading, or Coach classes',
        () {
      // DomainEventLearningAdapter only consumes generic DomainEvent & DomainEventPublisher
      final translated = adapter.translateEvent(TradeExecuted(
        tradeId: 'tr_400',
        userId: 'u_1',
        symbol: 'BTCUSDT',
        side: 'BUY',
        quantity: 1.0,
        executionPriceInr: 1000.0,
        totalAmountInr: 1000.0,
        hasStopLoss: true,
      ));

      expect(translated, isNotNull);
      expect(translated!.type, equals(LearningEventType.firstTradeCompleted));
      expect(translated.eventId, equals('domain_trade_tr_400'));
    });
  });
}
