import 'package:flutter/material.dart';
import '../../../app/theme/app_theme.dart';

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
            Card(
              color: AppColors.card,
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  children: [
                    const Text('Process Rating: EXCELLENT',
                        style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: AppColors.profit)),
                    const SizedBox(height: 12),
                    Text('85/100',
                        style: Theme.of(context)
                            .textTheme
                            .displayLarge
                            ?.copyWith(color: AppColors.discipline)),
                    const SizedBox(height: 12),
                    const LinearProgressIndicator(
                        value: 0.85,
                        color: AppColors.discipline,
                        backgroundColor: AppColors.background),
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
              ),
            )
          ],
        ),
      ),
    );
  }
}
