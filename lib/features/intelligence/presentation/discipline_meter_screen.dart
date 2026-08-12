import 'package:flutter/material.dart';
import '../../../app/theme/app_theme.dart';
import '../../../shared/widgets/trade_card.dart';
import '../../../shared/widgets/visual_gauge.dart';

class DisciplineMeterScreen extends StatelessWidget {
  const DisciplineMeterScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Trading Discipline Score')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TradeCard(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                children: [
                  const Text('Process Rating: EXCELLENT',
                      style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: AppColors.profit)),
                  const SizedBox(height: 24),
                  const VisualGauge(
                    value: 0.85,
                    color: AppColors.alert,
                  ),
                  SizedBox(height: 12),
                  Text('85/100',
                      style: Theme.of(context)
                          .textTheme
                          .displayLarge
                          ?.copyWith(color: AppColors.alert)),
                ],
              ),
            ),
            const SizedBox(height: 20),
            const TradeCard(
              padding: EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Discipline Breakdown (Independent of Profit):',
                      style: TextStyle(fontWeight: FontWeight.bold)),
                  SizedBox(height: 8),
                  Text('• 30% Risk Management Adherence'),
                  Text('• 25% Position Sizing Discipline'),
                  Text('• 20% Stop-Loss Usage'),
                  Text('• 15% Portfolio Concentration Control'),
                  Text('• 10% Trading Frequency Penalty Control'),
                ],
              ),
            )
          ],
        ),
      ),
    );
  }
}
