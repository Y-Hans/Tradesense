import 'package:flutter/material.dart';
import '../../tokens/colors.dart';

/// An avatar for the AI Coach.
class AIAvatar extends StatelessWidget {
  final double size;

  const AIAvatar({
    super.key,
    this.size = 40.0,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: AppColors.primaryGradient,
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryCyan.withValues(alpha: 0.3),
            blurRadius: size * 0.2,
            spreadRadius: 0,
          ),
        ],
      ),
      child: Center(
        child: Icon(
          Icons.auto_awesome,
          color: Theme.of(context).scaffoldBackgroundColor,
          size: size * 0.5,
        ),
      ),
    );
  }
}
