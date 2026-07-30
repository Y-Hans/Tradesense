import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../app/theme/app_theme.dart';
import '../../../core/providers/app_providers.dart';
import '../../../core/utils/financial_math.dart';
import '../../../shared/models/crypto_asset.dart';
import '../../../shared/widgets/trade_card.dart';
import '../../../shared/constants/app_strings.dart';
import '../../../shared/widgets/offline_state_widget.dart';

class MarketsScreen extends ConsumerWidget {
  const MarketsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isOffline = ref.watch(
      connectivityProvider
          .select((status) => status == ConnectivityStatus.offline),
    );
    final assetsAsync = ref.watch(supportedAssetsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Live Crypto Markets')),
      body: isOffline
          ? const Center(
              child: OfflineStateWidget(
                title: 'Live Markets Offline',
                message: AppStrings.marketsOfflineMessage,
              ),
            )
          : assetsAsync.when(
              data: (assets) => ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: assets.length,
                separatorBuilder: (context, index) =>
                    const SizedBox(height: 12),
                itemBuilder: (context, index) => _LiveMarketTile(
                  asset: assets[index],
                ),
              ),
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, stack) => const Center(
                child: OfflineStateWidget(
                  title: 'Live Markets Offline',
                  message: AppStrings.marketsOfflineMessage,
                ),
              ),
            ),
    );
  }
}

class _LiveMarketTile extends ConsumerWidget {
  const _LiveMarketTile({required this.asset});

  final CryptoAsset asset;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final marketRepository = ref.watch(marketRepositoryProvider);

    return StreamBuilder(
      stream: marketRepository.streamTicker(asset.symbol),
      builder: (context, snapshot) {
        final currentPrice = snapshot.data?.priceInr ?? asset.currentPriceInr;
        final simulatedChange = asset.currentPriceInr == 0
            ? 0.0
            : ((currentPrice - asset.currentPriceInr) / asset.currentPriceInr) *
                100;
        final isPositive = simulatedChange >= 0;

        return TradeCard(
          semanticLabel: '${asset.symbol} simulated live market price',
          onTap: () => context.push('/asset/${asset.symbol}'),
          child: Row(
            children: [
              CircleAvatar(
                backgroundColor: AppColors.primary.withValues(alpha: 0.18),
                child: Text(
                  asset.symbol[0],
                  style: const TextStyle(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(asset.name,
                        style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 2),
                    Text('${asset.symbol} · SIMULATED LIVE'),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    FinancialMath.formatInr(currentPrice),
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  Text(
                    '${isPositive ? '+' : ''}${simulatedChange.toStringAsFixed(2)}%',
                    style: TextStyle(
                      color: isPositive ? AppColors.profit : AppColors.loss,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}
