import 'package:flutter/material.dart';
import 'dart:math' as math;
import '../../tokens/colors.dart';
import '../../tokens/typography.dart';

/// A circular score ring used to display metrics like Discipline or Risk out of 100.
/// 
/// Example usage:
/// ```dart
/// ScoreRing(
///   score: 85,
///   size: 100,
///   color: AppColors.successGreen,
/// )
/// ```
class ScoreRing extends StatelessWidget {
  /// The score to display (0-100)
  final int score;
  
  /// The size (width/height) of the ring
  final double size;
  
  /// The color of the active progress arc
  final Color color;
  
  /// The stroke width of the ring
  final double strokeWidth;

  const ScoreRing({
    super.key,
    required this.score,
    this.size = 80,
    this.color = AppColors.primaryCyan,
    this.strokeWidth = 6.0,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _ScoreRingPainter(
          score: score,
          color: color,
          strokeWidth: strokeWidth,
          backgroundColor: Theme.of(context).dividerColor,
        ),
        child: Center(
          child: Text(
            score.toString(),
            style: AppTypography.textTheme.titleLarge?.copyWith(
              color: Theme.of(context).colorScheme.onSurface,
              fontWeight: FontWeight.bold,
              fontSize: size * 0.3,
            ),
          ),
        ),
      ),
    );
  }
}

class _ScoreRingPainter extends CustomPainter {
  final int score;
  final Color color;
  final double strokeWidth;
  final Color backgroundColor;

  _ScoreRingPainter({
    required this.score,
    required this.color,
    required this.strokeWidth,
    required this.backgroundColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - strokeWidth) / 2;

    // Background circle
    final bgPaint = Paint()
      ..color = backgroundColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;

    canvas.drawCircle(center, radius, bgPaint);

    // Progress arc
    final progressPaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    final sweepAngle = 2 * math.pi * (score / 100.0);
    // Start from top (-pi/2)
    const startAngle = -math.pi / 2;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle,
      sweepAngle,
      false,
      progressPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _ScoreRingPainter oldDelegate) {
    return oldDelegate.score != score ||
        oldDelegate.color != color ||
        oldDelegate.strokeWidth != strokeWidth ||
        oldDelegate.backgroundColor != backgroundColor;
  }
}
