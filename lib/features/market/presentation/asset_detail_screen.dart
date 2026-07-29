import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../app/theme/app_theme.dart';
import '../../../core/services/connectivity/connectivity_provider.dart';
import '../../../core/services/connectivity/connectivity_status.dart';
import '../../../shared/constants/app_strings.dart';
import '../../../shared/widgets/offline_state_widget.dart';

class AssetDetailScreen extends ConsumerWidget {
  final String symbol;
  const AssetDetailScreen({super.key, required this.symbol});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isOffline = ref.watch(
      connectivityProvider.select((status) => status == ConnectivityStatus.offline),
    );

    return Scaffold(
      appBar: AppBar(title: Text('$symbol Market Detail')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            if (isOffline)
              const OfflineStateWidget(
                message: AppStrings.assetDetailOfflineMessage,
                compact: true,
              ),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  children: [
                    Text(symbol,
                        style: Theme.of(context).textTheme.headlineMedium),
                    const SizedBox(height: 12),
                    const Text('Live Market Price',
                        style: TextStyle(color: AppColors.textSecondary)),
                    const SizedBox(height: 8),
                    const Text('₹5,850,000.00',
                        style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primary)),
                  ],
                ),
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
    );
  }
}
