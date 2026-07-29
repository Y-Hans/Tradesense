import 'package:flutter/material.dart';
import '../../app/theme/app_theme.dart';
import '../constants/disclaimers.dart';

class DisclaimerCard extends StatelessWidget {
  final bool compact;

  const DisclaimerCard({
    super.key,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(compact ? 12.0 : 16.0),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12.0),
        border: Border.all(
          color: AppColors.primary.withValues(alpha: 0.3),
          width: 1.0,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.info_outline_rounded,
            color: AppColors.primary,
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
                    color: AppColors.primary,
                    fontSize: compact ? 12.0 : 14.0,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4.0),
                Text(
                  EducationalDisclaimers.coreDisclaimer,
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: compact ? 11.0 : 12.5,
                  ),
                ),
                if (!compact) ...[
                  const SizedBox(height: 4.0),
                  const Text(
                    EducationalDisclaimers.performanceDisclaimer,
                    style: TextStyle(
                      color: AppColors.textSecondary,
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
