import 'package:flutter/material.dart';
import '../../app/theme/app_theme.dart';
import '../constants/disclaimers.dart';
import 'trade_card.dart';

class DisclaimerCard extends StatelessWidget {
  final bool compact;

  const DisclaimerCard({
    super.key,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    return TradeCard(
      padding: EdgeInsets.all(compact ? 12.0 : 16.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.info_outline_rounded,
            color: AppColors.alert, // Neon warning accent
            size: compact ? 18.0 : 22.0,
          ),
          const SizedBox(width: 12.0),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Educational Simulation Notice',
                  style: TextStyle(
                    color: AppColors.alert, // Warning accent
                    fontSize: compact ? 12.0 : 14.0,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 4.0),
                Text(
                  EducationalDisclaimers.coreDisclaimer,
                  style: TextStyle(
                    color: Theme.of(context).textTheme.bodyMedium?.color ?? Colors.grey,
                    fontSize: compact ? 11.0 : 12.5,
                  ),
                ),
                if (!compact) ...[
                  const SizedBox(height: 4.0),
                  Text(
                    EducationalDisclaimers.performanceDisclaimer,
                    style: TextStyle(
                      color: Theme.of(context).textTheme.bodyMedium?.color ?? Colors.grey,
                      fontSize: 11.5,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
