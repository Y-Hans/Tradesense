import 'package:flutter/material.dart';
import '../../../../app/theme/app_theme.dart';

class AnimatedXpProgressBar extends StatelessWidget {
  final double progress; // 0.0 to 1.0
  final double height;

  const AnimatedXpProgressBar({
    super.key,
    required this.progress,
    this.height = 12.0,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(height / 2),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          return TweenAnimationBuilder<double>(
            duration: const Duration(milliseconds: 1200),
            curve: Curves.easeOutCubic,
            tween: Tween<double>(begin: 0.0, end: progress.clamp(0.0, 1.0)),
            builder: (context, value, _) {
              return Stack(
                children: [
                  Container(
                    width: constraints.maxWidth * value,
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(height / 2),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primary.withValues(alpha: 0.8),
                          blurRadius: 10.0,
                          spreadRadius: 1.0,
                        ),
                      ],
                    ),
                  ),
                ],
              );
            },
          );
        },
      ),
    );
  }
}
