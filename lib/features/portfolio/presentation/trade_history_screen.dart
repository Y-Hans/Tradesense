import 'package:flutter/material.dart';
import 'package:cryptoedu/shared/widgets/crypto_loading_indicator.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/providers/app_providers.dart';
import '../../../core/utils/financial_math.dart';

class TradeHistoryScreen extends ConsumerWidget {
  const TradeHistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tradingRepo = ref.watch(tradingRepositoryProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Trade History')),
      body: FutureBuilder(
        future: tradingRepo.getTradeHistory(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CryptoLoadingIndicator());
          }
          final trades = snapshot.data!;
          if (trades.isEmpty) {
            return const Center(child: Text('No executed trades yet.'));
          }
          return ListView.builder(
            itemCount: trades.length,
            itemBuilder: (context, index) {
              final trade = trades[index];
              return ListTile(
                title: Text('${trade.side.name.toUpperCase()} ${trade.symbol}',
                    style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text(
                    'Qty: ${trade.quantity} @ ${FinancialMath.formatInr(trade.executionPriceInr)}'),
                trailing: Text(FinancialMath.formatInr(trade.totalAmountInr),
                    style: const TextStyle(fontWeight: FontWeight.bold)),
                onTap: () => context.push('/coach-result/${trade.id}'),
              );
            },
          );
        },
      ),
    );
  }
}


