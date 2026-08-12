import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../app/theme/app_theme.dart';
import '../../../shared/widgets/trade_card.dart';
import '../../../core/providers/app_providers.dart';
import '../../../shared/widgets/offline_state_widget.dart';

class AssetDetailScreen extends ConsumerWidget {
  final String symbol;
  const AssetDetailScreen({super.key, required this.symbol});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isOffline = ref.watch(connectivityProvider) == ConnectivityStatus.offline;

    return Scaffold(
      appBar: AppBar(title: Text('$symbol Market Detail')),
      body: Column(
        children: [
          if (isOffline)
            Padding(
              padding: const EdgeInsets.only(left: 16.0, right: 16.0, top: 16.0),
              child: OfflineStateWidget(
                compact: true,
                message: 'Live market details and real-time prices are unavailable while offline.',
              ),
            ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  TradeCard(
                    padding: EdgeInsets.all(20.0),
                    child: Column(
                      children: [
                        Text(symbol,
                            style: Theme.of(context).textTheme.headlineMedium),
                        SizedBox(height: 12),
                        Text('Live Market Price',
                            style: TextStyle(color: Theme.of(context).textTheme.bodyMedium?.color ?? Colors.grey)),
                        const SizedBox(height: 8),
                        const Text('₹5,850,000.00',
                            style: TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.bold,
                                color: AppColors.electricCyan)),
                      ],
                    ),
                  ),
                  const Spacer(),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: () => context.push('/trade/$symbol'),
                      child: Text('TRADE $symbol VIRTUAL'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
