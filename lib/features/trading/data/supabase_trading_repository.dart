import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/contracts/repository_contracts.dart';
import '../../../shared/models/trade.dart';
import '../../../shared/models/virtual_wallet.dart';
import '../../../shared/models/holding.dart';
import '../application/execute_buy_contracts.dart';
import 'package:uuid/uuid.dart';

class SupabaseTradingRepository implements TradingRepository {
  final SupabaseClient _client;

  SupabaseTradingRepository([SupabaseClient? client])
      : _client = client ?? Supabase.instance.client;

  String get _userId {
    final user = _client.auth.currentUser;
    if (user == null) {
      throw Exception('User must be logged in to execute trades.');
    }
    return user.id;
  }

  @override
  Future<Trade> executeMarketBuy({
    required String symbol,
    required double quantity,
    required double executionPriceInr,
    double? stopLossPriceInr,
  }) async {
    final totalCost = quantity * executionPriceInr;

    // We can use Supabase RPC for atomic transaction, but for this implementation
    // we'll do it sequentially or assume RPC 'execute_buy_trade' exists. 
    // Wait, the prompt says "Implement trading_repository.dart to handle Supabase inserts for trades and portfolio_holdings, including cash updates."
    // Let's do it sequentially in dart:
    // 1. Get profile and verify balance
    final profileData = await _client
        .from('profiles')
        .select('available_balance')
        .eq('id', _userId)
        .single();
    
    final currentBalance = (profileData['available_balance'] as num).toDouble();
    if (currentBalance < totalCost) {
      throw Exception('Insufficient funds');
    }

    // 2. Update profile balance
    final newBalance = currentBalance - totalCost;
    await _client.from('profiles').update({
      'available_balance': newBalance,
    }).eq('id', _userId);

    // 3. Insert into trades table
    final tradeResponse = await _client.from('trades').insert({
      'user_id': _userId,
      'asset_symbol': symbol,
      'trade_type': 'BUY',
      'quantity': quantity,
      'price': executionPriceInr,
      'total_amount': totalCost,
      'stop_loss_trigger': stopLossPriceInr,
      'created_at': DateTime.now().toIso8601String(),
    }).select().single();

    // 4. Update or Insert into portfolio_holdings
    final holdingData = await _client
        .from('portfolio_holdings')
        .select()
        .eq('user_id', _userId)
        .eq('asset_symbol', symbol)
        .maybeSingle();

    if (holdingData != null) {
      final currentQty = (holdingData['quantity'] as num).toDouble();
      final currentAvgPrice = (holdingData['average_buy_price'] as num).toDouble();
      
      final newQty = currentQty + quantity;
      final newAvgPrice = ((currentQty * currentAvgPrice) + totalCost) / newQty;

      await _client.from('portfolio_holdings').update({
        'quantity': newQty,
        'average_buy_price': newAvgPrice,
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', holdingData['id']);
    } else {
      await _client.from('portfolio_holdings').insert({
        'user_id': _userId,
        'asset_symbol': symbol,
        'quantity': quantity,
        'average_buy_price': executionPriceInr,
        'updated_at': DateTime.now().toIso8601String(),
      });
    }

    return Trade(
      id: tradeResponse['id'].toString(),
      userId: _userId,
      symbol: symbol,
      side: TradeSide.buy,
      type: OrderType.market,
      quantity: quantity,
      executionPriceInr: executionPriceInr,
      totalAmountInr: totalCost,
      stopLossPriceInr: stopLossPriceInr,
      timestamp: DateTime.parse(tradeResponse['created_at']),
      disciplineScoreAtTrade: stopLossPriceInr != null ? 85 : 45,
      riskScoreAtTrade: 50, // default
    );
  }

  @override
  Future<Trade> executeMarketSell({
    required String symbol,
    required double quantity,
    required double executionPriceInr,
  }) async {
    final totalProceeds = quantity * executionPriceInr;

    // 1. Get holding and verify quantity
    final holdingData = await _client
        .from('portfolio_holdings')
        .select()
        .eq('user_id', _userId)
        .eq('asset_symbol', symbol)
        .maybeSingle();

    if (holdingData == null) {
      throw Exception('Holding not found');
    }

    final currentQty = (holdingData['quantity'] as num).toDouble();
    if (currentQty < quantity) {
      throw Exception('Insufficient quantity');
    }

    // 2. Update or delete holding
    final remainingQty = currentQty - quantity;
    if (remainingQty <= 0.000001) {
      await _client.from('portfolio_holdings').delete().eq('id', holdingData['id']);
    } else {
      await _client.from('portfolio_holdings').update({
        'quantity': remainingQty,
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', holdingData['id']);
    }

    // 3. Update profile balance
    final profileData = await _client
        .from('profiles')
        .select('available_balance')
        .eq('id', _userId)
        .single();
    
    final currentBalance = (profileData['available_balance'] as num).toDouble();
    final newBalance = currentBalance + totalProceeds;
    
    await _client.from('profiles').update({
      'available_balance': newBalance,
    }).eq('id', _userId);

    // 4. Insert into trades table
    final tradeResponse = await _client.from('trades').insert({
      'user_id': _userId,
      'asset_symbol': symbol,
      'trade_type': 'SELL',
      'quantity': quantity,
      'price': executionPriceInr,
      'total_amount': totalProceeds,
      'created_at': DateTime.now().toIso8601String(),
    }).select().single();

    return Trade(
      id: tradeResponse['id'].toString(),
      userId: _userId,
      symbol: symbol,
      side: TradeSide.sell,
      type: OrderType.market,
      quantity: quantity,
      executionPriceInr: executionPriceInr,
      totalAmountInr: totalProceeds,
      timestamp: DateTime.parse(tradeResponse['created_at']),
      disciplineScoreAtTrade: 75,
      riskScoreAtTrade: 30, // default
    );
  }

  @override
  Future<List<Trade>> getTradeHistory() async {
    final response = await _client
        .from('trades')
        .select()
        .eq('user_id', _userId)
        .order('created_at', ascending: false);

    return (response as List).map((t) => Trade(
      id: t['id'].toString(),
      userId: _userId,
      symbol: t['asset_symbol'],
      side: t['trade_type'] == 'BUY' ? TradeSide.buy : TradeSide.sell,
      type: OrderType.market, // simplification
      quantity: (t['quantity'] as num).toDouble(),
      executionPriceInr: (t['price'] as num).toDouble(),
      totalAmountInr: (t['total_amount'] as num).toDouble(),
      stopLossPriceInr: t['stop_loss_trigger'] != null ? (t['stop_loss_trigger'] as num).toDouble() : null,
      timestamp: DateTime.parse(t['created_at']),
      disciplineScoreAtTrade: 50,
      riskScoreAtTrade: 50,
    )).toList();
  }

  @override
  Future<PersistedVirtualWallet?> getWalletForUser(String userId) async {
    final profileData = await _client
        .from('profiles')
        .select('available_balance')
        .eq('id', userId)
        .maybeSingle();
    if (profileData == null) return null;
    return PersistedVirtualWallet(
      userId: userId,
      wallet: VirtualWallet(
        balanceInr: (profileData['available_balance'] as num).toDouble(),
        lockedInr: 0.0,
        initialBalanceInr: 100000.0,
      ),
      version: '1.0',
    );
  }

  @override
  Future<Holding?> getHoldingForUserAsset({required String userId, required String symbol}) async {
    final holdingData = await _client
        .from('portfolio_holdings')
        .select()
        .eq('user_id', userId)
        .eq('asset_symbol', symbol)
        .maybeSingle();
    if (holdingData == null) return null;
    return Holding(
      id: holdingData['id'].toString(),
      userId: userId,
      symbol: symbol,
      quantity: (holdingData['quantity'] as num).toDouble(),
      averageEntryPriceInr: (holdingData['average_buy_price'] as num).toDouble(),
      currentPriceInr: (holdingData['average_buy_price'] as num).toDouble(), // fallback
    );
  }

  @override
  Future<List<Holding>> getHoldingsForUser(String userId) async {
    final response = await _client.from('portfolio_holdings').select().eq('user_id', userId);
    return (response as List).map((h) => Holding(
      id: h['id'].toString(),
      userId: userId,
      symbol: h['asset_symbol'],
      quantity: (h['quantity'] as num).toDouble(),
      averageEntryPriceInr: (h['average_buy_price'] as num).toDouble(),
      currentPriceInr: (h['average_buy_price'] as num).toDouble(), // fallback
    )).toList();
  }

  @override
  Future<List<Trade>> getTradesForUser(String userId) async {
    return getTradeHistory(); // getTradeHistory already scopes to _userId which is current user
  }

  @override
  String nextTradeId() => const Uuid().v4();

  @override
  String nextHoldingId({required String userId, required String symbol}) => const Uuid().v4();

  @override
  Future<BuyTransactionCommitResult> commitBuy({
    required String userId,
    required VirtualWallet updatedWallet,
    required Holding updatedHolding,
    required Trade trade,
    required double expectedPreviousWalletBalanceInr,
    String? expectedWalletVersion,
    required DateTime executedAt,
  }) async {
    try {
      await _client.from('profiles').update({
        'available_balance': updatedWallet.balanceInr,
      }).eq('id', userId);

      final holdingData = await _client
          .from('portfolio_holdings')
          .select()
          .eq('user_id', userId)
          .eq('asset_symbol', trade.symbol)
          .maybeSingle();

      if (holdingData != null) {
        await _client.from('portfolio_holdings').update({
          'quantity': updatedHolding.quantity,
          'average_buy_price': updatedHolding.averageEntryPriceInr,
          'updated_at': executedAt.toIso8601String(),
        }).eq('id', holdingData['id']);
      } else {
        await _client.from('portfolio_holdings').insert({
          'id': updatedHolding.id, // optional if generated by DB, but we pass it
          'user_id': userId,
          'asset_symbol': trade.symbol,
          'quantity': updatedHolding.quantity,
          'average_buy_price': updatedHolding.averageEntryPriceInr,
          'updated_at': executedAt.toIso8601String(),
        });
      }

      await _client.from('trades').insert({
        'id': trade.id,
        'user_id': userId,
        'asset_symbol': trade.symbol,
        'trade_type': 'BUY',
        'quantity': trade.quantity,
        'price': trade.executionPriceInr,
        'total_amount': trade.totalAmountInr,
        'stop_loss_trigger': trade.stopLossPriceInr,
        'created_at': executedAt.toIso8601String(),
      });

      return BuyTransactionCommitSuccess(committedAt: executedAt);
    } catch (e) {
      return BuyTransactionCommitFailure(BuyTransactionFailure(
        code: BuyTransactionFailureCode.persistenceFailure,
        message: e.toString(),
      ));
    }
  }

  @override
  Future<SellTransactionCommitResult> commitSell({
    required String userId,
    required VirtualWallet updatedWallet,
    required Holding updatedHolding,
    required Trade trade,
    required double expectedPreviousWalletBalanceInr,
    required double expectedPreviousHoldingQuantity,
    String? expectedWalletVersion,
    required DateTime executedAt,
    required String sellReason,
    String? sourceStopLossOrderId,
  }) async {
    try {
      await _client.from('profiles').update({
        'available_balance': updatedWallet.balanceInr,
      }).eq('id', userId);

      final holdingData = await _client
          .from('portfolio_holdings')
          .select()
          .eq('user_id', userId)
          .eq('asset_symbol', trade.symbol)
          .maybeSingle();

      if (holdingData != null) {
        if (updatedHolding.quantity <= 0.000001) {
          await _client.from('portfolio_holdings').delete().eq('id', holdingData['id']);
        } else {
          await _client.from('portfolio_holdings').update({
            'quantity': updatedHolding.quantity,
            'updated_at': executedAt.toIso8601String(),
          }).eq('id', holdingData['id']);
        }
      }

      await _client.from('trades').insert({
        'id': trade.id,
        'user_id': userId,
        'asset_symbol': trade.symbol,
        'trade_type': 'SELL',
        'quantity': trade.quantity,
        'price': trade.executionPriceInr,
        'total_amount': trade.totalAmountInr,
        'created_at': executedAt.toIso8601String(),
      });

      return SellTransactionCommitSuccess(committedAt: executedAt);
    } catch (e) {
      return SellTransactionCommitFailure(SellTransactionFailure(
        code: SellTransactionFailureCode.persistenceFailure,
        message: e.toString(),
      ));
    }
  }
}
