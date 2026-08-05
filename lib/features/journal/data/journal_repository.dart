import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../domain/journal_state.dart';

part 'journal_repository.g.dart';

class JournalRepository {
  Future<List<Trade>> fetchTrades() async {
    await Future.delayed(const Duration(seconds: 1)); // Mock latency
    return [
      Trade(
        id: '1',
        symbol: 'BTCUSDT',
        type: 'Buy',
        pnl: 3450.50,
        date: DateTime.now().subtract(const Duration(hours: 2)),
        tags: ['Momentum', 'StopLoss'],
        aiReviewed: true,
      ),
      Trade(
        id: '2',
        symbol: 'ETHUSDT',
        type: 'Sell',
        pnl: -1200.00,
        date: DateTime.now().subtract(const Duration(days: 1)),
        tags: ['FOMO', 'Early exit'],
        aiReviewed: true,
      ),
      Trade(
        id: '3',
        symbol: 'SOLUSDT',
        type: 'Buy',
        pnl: 850.25,
        date: DateTime.now().subtract(const Duration(days: 2)),
        tags: ['Breakout'],
        aiReviewed: false,
      ),
    ];
  }
}

@riverpod
JournalRepository journalRepository(JournalRepositoryRef ref) {
  return JournalRepository();
}
