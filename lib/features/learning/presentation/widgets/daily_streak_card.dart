import 'dart:ui';
import 'package:flutter/material.dart';
import '../../../../app/theme/app_theme.dart';

class DailyStreakCard extends StatelessWidget {
  final int streakDays;
  final bool isActive;

  const DailyStreakCard({
    super.key,
    required this.streakDays,
    required this.isActive,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16.0),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10.0, sigmaY: 10.0),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
          decoration: BoxDecoration(
            color: AppColors.surface.withValues(alpha: 0.4),
            borderRadius: BorderRadius.circular(16.0),
            border: Border.all(
              color: isActive
                  ? Colors.orangeAccent.withValues(alpha: 0.5)
                  : Colors.white.withValues(alpha: 0.1),
              width: 1.0,
            ),
            boxShadow: isActive
                ? [
                    BoxShadow(
                      color: Colors.orangeAccent.withValues(alpha: 0.2),
                      blurRadius: 15.0,
                      spreadRadius: -5.0,
                    )
                  ]
                : [],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.local_fire_department,
                color: isActive ? Colors.orangeAccent : Colors.grey,
                size: 28.0,
                shadows: isActive
                    ? [
                        const BoxShadow(
                          color: Colors.orangeAccent,
                          blurRadius: 12.0,
                        ),
                      ]
                    : null,
              ),
              const SizedBox(height: 8.0),
              Text(
                '$streakDays Day${streakDays == 1 ? '' : 's'}',
                style: TextStyle(
                  color: isActive ? Colors.white : Colors.grey,
                  fontWeight: FontWeight.bold,
                  fontSize: 14.0,
                ),
              ),
              const SizedBox(height: 2.0),
              Text(
                'Streak',
                style: TextStyle(
                  color: isActive ? Colors.white70 : Colors.grey,
                  fontSize: 11.0,
                  letterSpacing: 1.1,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
