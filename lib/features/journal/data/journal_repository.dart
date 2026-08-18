import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../../core/providers/app_providers.dart';
import '../../../shared/models/trade.dart' show TradeSide;
import '../../trading/data/supabase_trading_repository.dart';
import '../domain/journal_state.dart';

part 'journal_repository.g.dart';

class JournalRepository {
  final Ref ref;
  JournalRepository(this.ref);

  Future<List<Trade>> fetchTrades() async {
    final tradingRepo = ref.read(tradingRepositoryProvider);
    final history = await tradingRepo.getTradeHistory();
    // Since JournalState.Trade is different from shared/models/trade.dart,
    // we need to map it. Wait, if JournalState.Trade is different, we map it here.
    return history.map((t) => Trade(
      id: t.id,
      symbol: t.symbol,
      type: t.side.name.toUpperCase(),
      pnl: t.side == TradeSide.sell ? (t.realizedPnl ?? 0.0) : 0.0,
      date: t.timestamp,
      tags: [],
      aiReviewed: false,
    )).toList();
  }
}

@riverpod
JournalRepository journalRepository(JournalRepositoryRef ref) {
  return JournalRepository(ref);
}
