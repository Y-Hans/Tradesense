import '../../../shared/models/holding.dart';
import '../../../shared/models/stop_loss_order.dart';
import 'execute_buy_contracts.dart';

typedef ExecuteStopLossWalletRepository = ExecuteBuyWalletRepository;
typedef ExecuteStopLossClock = ExecuteBuyClock;
typedef SystemExecuteStopLossClock = SystemExecuteBuyClock;

abstract interface class ExecuteStopLossHoldingRepository {
  Future<List<Holding>> getHoldingsForUser(String userId);
}

abstract interface class ExecuteStopLossOrderRepository {
  Future<List<StopLossOrder>> getActiveStopLossOrdersForUser(String userId);
}
