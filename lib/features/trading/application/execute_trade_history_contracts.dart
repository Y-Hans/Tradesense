import '../../../shared/models/trade.dart';
import 'execute_buy_contracts.dart';

typedef ExecuteTradeHistoryWalletRepository = ExecuteBuyWalletRepository;
typedef ExecuteTradeHistoryClock = ExecuteBuyClock;
typedef SystemExecuteTradeHistoryClock = SystemExecuteBuyClock;

abstract interface class ExecuteTradeHistoryTradeRepository {
  Future<List<Trade>> getTradesForUser(String userId);
}
