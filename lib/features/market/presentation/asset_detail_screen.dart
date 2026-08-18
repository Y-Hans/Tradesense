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
    final isOffline =
        ref.watch(connectivityProvider) == ConnectivityStatus.offline;
    final tickerFuture = ref.read(marketRepositoryProvider).getTicker(symbol);

    return Scaffold(
      appBar: AppBar(title: Text('$symbol Market Detail')),
      body: Column(
        children: [
          if (isOffline)
            Padding(
              padding:
                  const EdgeInsets.only(left: 16.0, right: 16.0, top: 16.0),
              child: OfflineStateWidget(
                compact: true,
                message:
                    'Live market details and real-time prices are unavailable while offline.',
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
                            style: TextStyle(
                                color: Theme.of(context)
                                        .textTheme
                                        .bodyMedium
                                        ?.color ??
                                    Colors.grey)),
                        const SizedBox(height: 8),
                        FutureBuilder(
                          future: tickerFuture,
                          builder: (context, snapshot) {
                            if (snapshot.connectionState !=
                                ConnectionState.done) {
                              return const CircularProgressIndicator();
                            }
                            if (snapshot.hasError || !snapshot.hasData) {
                              return const Text('Live price unavailable');
                            }
                            final ticker = snapshot.data!;
                            final quote = ticker.quoteCurrency ?? 'INR';
                            return Column(children: [
                              Text('₹${ticker.priceInr.toStringAsFixed(2)}',
                                  style: const TextStyle(
                                      fontSize: 28,
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.electricCyan)),
                              Text(quote == 'INR'
                                  ? '$symbol/${ticker.quoteCurrency ?? 'INR'} · ${ticker.freshness.name.toUpperCase()}'
                                  : '$symbol/$quote · ${ticker.freshness.name.toUpperCase()} · INR converted'),
                              Text(
                                  'Source: ${ticker.source ?? 'market provider'}'),
                              Text('As of: ${ticker.timestamp.toLocal()}'),
                            ]);
                          },
                        ),
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
