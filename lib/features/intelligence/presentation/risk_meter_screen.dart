import 'package:flutter/material.dart';
import '../../../app/theme/app_theme.dart';
import '../../../shared/widgets/trade_card.dart';
import '../../../shared/widgets/visual_gauge.dart';

class RiskMeterScreen extends StatelessWidget {
  const RiskMeterScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Portfolio Risk Score')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TradeCard(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                children: [
                  const Text('Risk Level: MODERATE',
                      style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: AppColors.profit)),
                  const SizedBox(height: 24),
                  const VisualGauge(
                    value: 0.35,
                    color: AppColors.profit,
                  ),
                  SizedBox(height: 12),
                  Text('35/100',
                      style: Theme.of(context).textTheme.displayLarge),
                ],
              ),
            ),
            const SizedBox(height: 20),
            const TradeCard(
              padding: EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Risk Components:',
                      style: TextStyle(fontWeight: FontWeight.bold)),
                  SizedBox(height: 8),
                  Text('• 40% Concentration (Single Asset % of Equity)'),
                  Text('• 30% Position Sizing (Trade Size % of Equity)'),
                  Text('• 20% Asset Volatility (24h Volatility Swing)'),
                  Text('• 10% Stop-Loss Behaviour'),
                ],
              ),
            )
          ],
        ),
      ),
    );
  }
}
