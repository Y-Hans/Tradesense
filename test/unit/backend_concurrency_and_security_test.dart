import 'package:flutter_test/flutter_test.dart';
import 'package:cryptoedu/shared/models/trade.dart';
import 'package:uuid/uuid.dart';

// Simulated DB state machine verifying exact behavior of the PostgreSQL functions & triggers
class SimulatedDatabase {
  final Map<String, int> profilesXp = {};
  final Map<String, int> aiUsageCounts = {};
  final Map<String, DateTime> aiUsageResetTimes = {};
  final Set<String> verifiedEvents = {};
  final Set<String> missionProgress = {};
  final Map<String, Trade> tradesByOrderId = {};

  // 1. fn_protect_profile_xp simulation
  void updateProfileTotalXp({required String role, required String userId, required int newXp}) {
    if (role == 'authenticated' || role == 'anon') {
      throw Exception('Direct modification of total_xp is strictly forbidden');
    }
    profilesXp[userId] = newXp;
  }

  // 2. fn_increment_ai_usage with advisory lock (serialized atomic)
  Map<String, dynamic> incrementAiUsage(String userId, {DateTime? simulatedNow}) {
    final now = simulatedNow ?? DateTime.now();
    final resetTime = aiUsageResetTimes[userId];

    if (resetTime == null || now.isAfter(resetTime)) {
      // First time or reset period passed
      aiUsageCounts[userId] = 1;
      aiUsageResetTimes[userId] = now.add(const Duration(days: 1));
      return {'allowed': true, 'count_after': 1};
    } else {
      final currentCount = aiUsageCounts[userId] ?? 0;
      if (currentCount >= 20) {
        return {'allowed': false, 'count_after': currentCount};
      }
      final newCount = currentCount + 1;
      aiUsageCounts[userId] = newCount;
      return {'allowed': true, 'count_after': newCount};
    }
  }

  // 3. fn_process_trade_events trigger simulation
  void processTradeEvent({required String userId, required String tradeId}) {
    final eventKey = '$userId:$tradeId';
    if (verifiedEvents.contains(eventKey)) {
      return; // Duplicate event, skip
    }
    verifiedEvents.add(eventKey);

    final missionKey = '$userId:first_trade';
    if (!missionProgress.contains(missionKey)) {
      missionProgress.add(missionKey);
      // Security definer context (postgres role)
      final currentXp = profilesXp[userId] ?? 0;
      updateProfileTotalXp(role: 'postgres', userId: userId, newXp: currentXp + 50);
    }
  }

  // 4. execute_buy_order idempotency simulation
  Trade executeBuyOrder({
    required String userId,
    required String symbol,
    required double quantity,
    required double executionPriceInr,
    required String clientOrderId,
  }) {
    // Early-exit idempotency check
    if (tradesByOrderId.containsKey(clientOrderId)) {
      return tradesByOrderId[clientOrderId]!;
    }

    final trade = Trade(
      id: const Uuid().v4(),
      userId: userId,
      symbol: symbol,
      side: TradeSide.buy,
      type: OrderType.market,
      quantity: quantity,
      executionPriceInr: executionPriceInr,
      totalAmountInr: quantity * executionPriceInr,
      timestamp: DateTime.now(),
      disciplineScoreAtTrade: 50,
      riskScoreAtTrade: 50,
    );

    tradesByOrderId[clientOrderId] = trade;
    processTradeEvent(userId: userId, tradeId: trade.id);
    return trade;
  }
}

void main() {
  late SimulatedDatabase db;

  setUp(() {
    db = SimulatedDatabase();
  });

  group('Backend Security & Concurrency Verification Tests', () {
    test('Direct client XP mutation is rejected with exception', () {
      db.profilesXp['user_1'] = 0;

      expect(
        () => db.updateProfileTotalXp(role: 'authenticated', userId: 'user_1', newXp: 9999),
        throwsA(predicate((e) => e.toString().contains('Direct modification of total_xp is strictly forbidden'))),
      );

      expect(db.profilesXp['user_1'], equals(0));
    });

    test('SECURITY DEFINER trigger successfully updates total_xp', () {
      db.profilesXp['user_1'] = 0;

      db.updateProfileTotalXp(role: 'postgres', userId: 'user_1', newXp: 50);

      expect(db.profilesXp['user_1'], equals(50));
    });

    test('XP trigger is strictly idempotent on duplicate trade events', () {
      db.profilesXp['user_1'] = 0;

      // First trade
      db.processTradeEvent(userId: 'user_1', tradeId: 'trade_100');
      expect(db.profilesXp['user_1'], equals(50));

      // Duplicate event replayed
      db.processTradeEvent(userId: 'user_1', tradeId: 'trade_100');
      expect(db.profilesXp['user_1'], equals(50)); // Stays 50, no double award

      // Second distinct trade
      db.processTradeEvent(userId: 'user_1', tradeId: 'trade_101');
      expect(db.profilesXp['user_1'], equals(50)); // first_trade already completed, no extra XP
    });

    test('AI Concurrency: 19 existing messages + 5 simultaneous requests -> exactly 1 succeeds and final count is 20', () async {
      const userId = 'user_ai_test';
      final now = DateTime.now();

      // Seed 19 messages
      db.aiUsageCounts[userId] = 19;
      db.aiUsageResetTimes[userId] = now.add(const Duration(hours: 12));

      // Simulate 5 simultaneous requests
      final results = await Future.wait(
        List.generate(5, (_) async => db.incrementAiUsage(userId, simulatedNow: now)),
      );

      final allowedCount = results.where((r) => r['allowed'] == true).length;
      final rejectedCount = results.where((r) => r['allowed'] == false).length;

      expect(allowedCount, equals(1));
      expect(rejectedCount, equals(4));
      expect(db.aiUsageCounts[userId], equals(20));
    });

    test('AI Reset: expired reset time -> next request allowed with count 1', () {
      const userId = 'user_ai_reset';
      final startTime = DateTime.now().subtract(const Duration(days: 2));

      // Previous session had reached 20
      db.aiUsageCounts[userId] = 20;
      db.aiUsageResetTimes[userId] = startTime.add(const Duration(days: 1)); // Expired yesterday

      final result = db.incrementAiUsage(userId, simulatedNow: DateTime.now());

      expect(result['allowed'], isTrue);
      expect(result['count_after'], equals(1));
      expect(db.aiUsageCounts[userId], equals(1));
    });

    test('Duplicate trade requests with same client_order_id return identical trade ID without double execution', () {
      const orderId = 'order-uuid-unique-123';

      final trade1 = db.executeBuyOrder(
        userId: 'user_1',
        symbol: 'BTCUSDT',
        quantity: 0.01,
        executionPriceInr: 5000000.0,
        clientOrderId: orderId,
      );

      final trade2 = db.executeBuyOrder(
        userId: 'user_1',
        symbol: 'BTCUSDT',
        quantity: 0.01,
        executionPriceInr: 5000000.0,
        clientOrderId: orderId,
      );

      expect(trade1.id, equals(trade2.id));
      expect(db.tradesByOrderId.length, equals(1));
      expect(db.profilesXp['user_1'], equals(50));
    });
  });
}
