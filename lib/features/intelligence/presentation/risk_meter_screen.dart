import 'package:flutter/material.dart';
import '../../../app/theme/app_theme.dart';

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
            Card(
              color: AppColors.card,
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  children: [
                    const Text('Risk Level: MODERATE', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.discipline)),
                    const SizedBox(height: 12),
                    Text('35/100', style: Theme.of(context).textTheme.displayLarge),
                    const SizedBox(height: 12),
                    const LinearProgressIndicator(value: 0.35, color: AppColors.discipline, backgroundColor: AppColors.background),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            const Card(
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Risk Components:', style: TextStyle(fontWeight: FontWeight.bold)),
                    SizedBox(height: 8),
                    Text('• 40% Concentration (Single Asset % of Equity)'),
                    Text('• 30% Position Sizing (Trade Size % of Equity)'),
                    Text('• 20% Asset Volatility (24h Volatility Swing)'),
                    Text('• 10% Stop-Loss Behaviour'),
                  ],
                ),
              ),
            )
          ],
        ),
      ),
    );
  }
}
