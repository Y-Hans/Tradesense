import 'package:flutter/foundation.dart';

import '../domain/stop_loss_evaluation_result.dart';
import 'execute_sell_result.dart';

sealed class ExecuteStopLossResult {
  const ExecuteStopLossResult();

  bool get isSuccess => this is ExecuteStopLossSuccess;
}

@immutable
class ExecuteStopLossSuccess extends ExecuteStopLossResult {
  final StopLossEvaluationResult evaluation;
  final List<ExecuteStopLossExecutedSell> executedSells;

  ExecuteStopLossSuccess({
    required this.evaluation,
    required List<ExecuteStopLossExecutedSell> executedSells,
  }) : executedSells = List<ExecuteStopLossExecutedSell>.unmodifiable(
          executedSells,
        );

  int get evaluatedOrderCount =>
      evaluation.triggeredOrders.length +
      evaluation.pendingOrders.length +
      evaluation.expiredOrders.length +
      evaluation.rejectedOrders.length;

  int get triggeredOrderCount => evaluation.triggeredOrders.length;
  int get executedSellCount => executedSells.length;

  int get skippedOrderCount =>
      evaluation.pendingOrders.length +
      evaluation.expiredOrders.length +
      evaluation.rejectedOrders.length;

  int get pendingOrderCount => evaluation.pendingOrders.length;
  int get expiredOrderCount => evaluation.expiredOrders.length;
  int get rejectedOrderCount => evaluation.rejectedOrders.length;
}

@immutable
class ExecuteStopLossExecutedSell {
  final SellExecutionRequest sellRequest;
  final ExecuteSellSuccess sellResult;

  const ExecuteStopLossExecutedSell({
    required this.sellRequest,
    required this.sellResult,
  });

  String get stopLossOrderId => sellRequest.orderId;
  String get assetSymbol => sellRequest.assetSymbol;
  double get quantity => sellRequest.quantity;
}

@immutable
class ExecuteStopLossApplicationFailed extends ExecuteStopLossResult {
  final ExecuteStopLossFailure failure;
  final SellExecutionRequest? failedSellRequest;
  final ExecuteSellResult? failedSellResult;
  final List<ExecuteStopLossExecutedSell> executedSellsBeforeFailure;

  ExecuteStopLossApplicationFailed(
    this.failure, {
    this.failedSellRequest,
    this.failedSellResult,
    List<ExecuteStopLossExecutedSell> executedSellsBeforeFailure = const [],
  }) : executedSellsBeforeFailure =
            List<ExecuteStopLossExecutedSell>.unmodifiable(
          executedSellsBeforeFailure,
        );
}

enum ExecuteStopLossFailureCode {
  invalidUserContext,
  walletNotFound,
  walletOwnershipMismatch,
  walletRepositoryFailure,
  holdingOwnershipMismatch,
  holdingsRepositoryFailure,
  stopLossOrderOwnershipMismatch,
  stopLossOrderRepositoryFailure,
  malformedRepositoryData,
  marketTickerUnavailable,
  marketRepositoryFailure,
  executeSellFailure,
}

@immutable
class ExecuteStopLossFailure {
  final ExecuteStopLossFailureCode code;
  final String message;

  const ExecuteStopLossFailure({
    required this.code,
    required this.message,
  });
}
