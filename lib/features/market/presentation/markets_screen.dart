import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../app/theme/app_theme.dart';
import '../../../core/providers/app_providers.dart';
import '../../../core/utils/financial_math.dart';

class MarketsScreen extends ConsumerWidget {
  const MarketsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final assetsAsync = ref.watch(supportedAssetsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Live Crypto Markets')),
      body: assetsAsync.when(
        data: (assets) => ListView.builder(
          itemCount: assets.length,
          itemBuilder: (context, index) {
            final asset = assets[index];
            return ListTile(
              title: Text(asset.name,
                  style: const TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Text(asset.symbol),
              trailing: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(FinancialMath.formatInr(asset.currentPriceInr),
                      style: const TextStyle(fontWeight: FontWeight.bold)),
                  Text('${asset.change24hPercent}%',
                      style: TextStyle(
                          color: asset.change24hPercent >= 0
                              ? AppColors.profit
                              : AppColors.loss)),
                ],
              ),
              onTap: () => context.push('/asset/${asset.symbol}'),
            );
          },
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Text('Error: $err'),
      ),
    );
  }
}
