import '../../../shared/models/stop_loss_order.dart';
import 'trading_failure.dart';

class StopLossEvaluationResult {
  final List<StopLossOrder> triggeredOrders;
  final List<StopLossOrder> pendingOrders;
  final List<StopLossOrder> expiredOrders;
  final List<StopLossRejectedOrder> rejectedOrders;
  final List<SellExecutionRequest> sellRequests;
  final DateTime evaluatedAt;

  const StopLossEvaluationResult({
    required this.triggeredOrders,
    required this.pendingOrders,
    required this.expiredOrders,
    required this.rejectedOrders,
    required this.sellRequests,
    required this.evaluatedAt,
  });

  bool get hasTriggeredOrders => triggeredOrders.isNotEmpty;
  bool get hasRejectedOrders => rejectedOrders.isNotEmpty;
}

class StopLossRejectedOrder {
  final StopLossOrder order;
  final TradingFailure failure;

  const StopLossRejectedOrder({
    required this.order,
    required this.failure,
  });
}

class SellExecutionRequest {
  static const String stopLossReason = 'STOP_LOSS';

  final String orderId;
  final String assetSymbol;
  final double quantity;
  final double marketPriceInr;
  final double triggerPriceInr;
  final double estimatedProceedsInr;
  final DateTime evaluatedAt;
  final String reason;

  const SellExecutionRequest({
    required this.orderId,
    required this.assetSymbol,
    required this.quantity,
    required this.marketPriceInr,
    required this.triggerPriceInr,
    required this.estimatedProceedsInr,
    required this.evaluatedAt,
    this.reason = stopLossReason,
  });
}
