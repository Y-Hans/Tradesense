import 'package:flutter/material.dart';
import '../../../app/theme/app_theme.dart';
import '../../../shared/widgets/trade_card.dart';

class MissionsScreen extends StatelessWidget {
  const MissionsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Beginner Missions & XP')),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: const [
          TradeCard(
            margin: const EdgeInsets.only(bottom: 12),
            padding: EdgeInsets.zero,
            child: ListTile(
              leading: const Icon(Icons.check_circle, color: AppColors.profit),
              title: const Text('Mission 1: First Virtual Trade'),
              subtitle:
                  const Text('Execute a market buy order with ₹100,000 wallet.'),
              trailing: const Text('+100 XP',
                  style: TextStyle(
                      color: AppColors.discipline,
                      fontWeight: FontWeight.bold)),
            ),
          ),
          TradeCard(
            margin: const EdgeInsets.only(bottom: 12),
            padding: EdgeInsets.zero,
            child: ListTile(
              leading: const Icon(Icons.shield_outlined, color: AppColors.primary),
              title: const Text('Mission 2: Use a Stop-Loss Protection'),
              subtitle:
                  const Text('Set a stop-loss order on any active crypto position.'),
              trailing: const Text('+250 XP',
                  style: TextStyle(
                      color: AppColors.discipline,
                      fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }
}
