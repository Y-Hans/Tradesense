import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/contracts/repository_contracts.dart';
import '../../../shared/models/trade.dart';
import '../../../shared/models/holding.dart';
import '../../../shared/models/virtual_wallet.dart';
import '../../../core/events/domain_event_publisher.dart';
import '../../../core/events/domain_events.dart';
import 'package:uuid/uuid.dart';

class SupabaseTradingRepository implements TradingRepository {
  final SupabaseClient _client;
  final DomainEventPublisher? _eventPublisher;

  SupabaseTradingRepository({
    SupabaseClient? client,
    DomainEventPublisher? eventPublisher,
  })  : _client = client ?? Supabase.instance.client,
        _eventPublisher = eventPublisher;

  @override
  Future<Trade> executeMarketBuy({
    required String symbol,
    required double quantity,
    required double executionPriceInr,
    double? stopLossPriceInr,
  }) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) throw Exception('Your session expired. Please sign in again.');

    // 1. Call Edge Function (server-side pricing & secure RPC)
    late final String tradeIdStr;
    try {
      final response = await _client.functions.invoke(
        'execute_trade',
        body: {
          'symbol': symbol,
          'quantity': quantity,
          'side': 'buy',
          'client_order_id': const Uuid().v4(),
          'stop_loss_price_inr': stopLossPriceInr,
        },
      );
      tradeIdStr = response.data['trade_id'] as String;
    } on FunctionException catch (e) {
      final errorStr = e.details?.toString() ?? e.toString();
      if (errorStr.contains('Insufficient funds')) {
        throw Exception('You don\'t have enough virtual cash for this trade.');
      }
      throw Exception('Trade Failed: $errorStr');
    } catch (e) {
      throw Exception('Trade Failed: $e');
    }

    // 2. Fetch the inserted trade
    final tradeResp = await _client
        .from('trades')
        .select()
        .eq('id', tradeIdStr)
        .single();

    final trade = Trade.fromJson(tradeResp);

    _eventPublisher?.publish(
      TradeExecuted(
        tradeId: trade.id,
        userId: trade.userId,
        symbol: trade.symbol,
        side: 'buy',
        quantity: trade.quantity,
        executionPriceInr: trade.executionPriceInr,
        totalAmountInr: trade.totalAmountInr,
        hasStopLoss: trade.stopLossPriceInr != null,
        stopLossPriceInr: trade.stopLossPriceInr,
        occurredAt: trade.timestamp,
      ),
    );

    return trade;
  }

  @override
  Future<Trade> executeMarketSell({
    required String symbol,
    required double quantity,
    required double executionPriceInr,
  }) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) throw Exception('Your session expired. Please sign in again.');

    // 1. Call Edge Function (server-side pricing & secure RPC)
    late final String tradeIdStr;
    try {
      final response = await _client.functions.invoke(
        'execute_trade',
        body: {
          'symbol': symbol,
          'quantity': quantity,
          'side': 'sell',
          'client_order_id': const Uuid().v4(),
        },
      );
      tradeIdStr = response.data['trade_id'] as String;
    } on FunctionException catch (e) {
      final errorStr = e.details?.toString() ?? e.toString();
      if (errorStr.contains('Insufficient holding quantity')) {
        throw Exception('You don\'t have enough of this asset to sell.');
      }
      throw Exception('Trade Failed: $errorStr');
    } catch (e) {
      throw Exception('Trade Failed: $e');
    }

    // 2. Fetch the inserted trade
    final tradeResp = await _client
        .from('trades')
        .select()
        .eq('id', tradeIdStr)
        .single();

    final trade = Trade.fromJson(tradeResp);

    _eventPublisher?.publish(
      TradeExecuted(
        tradeId: trade.id,
        userId: trade.userId,
        symbol: trade.symbol,
        side: 'sell',
        quantity: trade.quantity,
        executionPriceInr: trade.executionPriceInr,
        totalAmountInr: trade.totalAmountInr,
        hasStopLoss: false,
        occurredAt: trade.timestamp,
      ),
    );

    return trade;
  }

  @override
  Future<List<Trade>> getTradeHistory() async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) throw Exception('Not authenticated');

    final response = await _client
        .from('trades')
        .select()
        .eq('user_id', userId)
        .order('timestamp', ascending: false);

    return (response as List<dynamic>).map((json) => Trade.fromJson(json as Map<String, dynamic>)).toList();
  }
}
