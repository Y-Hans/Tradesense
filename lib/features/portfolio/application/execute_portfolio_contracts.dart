import '../../../shared/models/holding.dart';
import '../../../shared/models/trade.dart';
import '../../trading/application/execute_buy_contracts.dart';

typedef ExecutePortfolioWalletRepository = ExecuteBuyWalletRepository;
typedef ExecutePortfolioClock = ExecuteBuyClock;
typedef SystemExecutePortfolioClock = SystemExecuteBuyClock;

abstract interface class ExecutePortfolioHoldingRepository {
  Future<List<Holding>> getHoldingsForUser(String userId);
}

abstract interface class ExecutePortfolioTradeRepository {
  Future<List<Trade>> getTradesForUser(String userId);
}
