import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../app/theme/app_theme.dart';
import '../../../core/providers/app_providers.dart';
import '../../../shared/widgets/trade_card.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(currentUserProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Profile & Settings')),
      body: userAsync.when(
        data: (user) => Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              TradeCard(
                padding: EdgeInsets.zero,
                child: ListTile(
                  leading: const CircleAvatar(child: Icon(Icons.person)),
                  title: Text(user?.displayName ?? 'Discipline Trader',
                      style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text(user?.email ?? 'trader@cryptoedu.app'),
                ),
              ),
              const SizedBox(height: 16),
              ListTile(
                leading: const Icon(Icons.star, color: AppColors.discipline),
                title: const Text('Subscription Status'),
                trailing: Text(user?.isPremium == true ? 'PREMIUM' : 'FREE',
                    style: const TextStyle(fontWeight: FontWeight.bold)),
                onTap: () => context.push('/paywall'),
              ),
              const Divider(),
              ListTile(
                leading: const Icon(Icons.privacy_tip_outlined),
                title: const Text('Privacy Policy & Data Safety'),
                onTap: () {},
              ),
              ListTile(
                leading:
                    const Icon(Icons.delete_forever, color: AppColors.loss),
                title: const Text('Delete Account & Private Data',
                    style: TextStyle(color: AppColors.loss)),
                onTap: () async {
                  final auth = ref.read(authRepositoryProvider);
                  await auth.deleteAccount();
                  if (context.mounted) context.go('/onboarding');
                },
              ),
            ],
          ),
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Text('Error: $err'),
      ),
    );
  }
}
