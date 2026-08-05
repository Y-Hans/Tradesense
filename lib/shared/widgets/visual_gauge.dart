import 'dart:math';
import 'package:flutter/material.dart';

import '../../app/theme/app_theme.dart';

class VisualGauge extends StatelessWidget {
  final double value; // 0.0 to 1.0
  final Color color;
  final double size;
  final double strokeWidth;

  const VisualGauge({
    super.key,
    required this.value,
    this.color = AppColors.electricCyan,
    this.size = 160.0,
    this.strokeWidth = 16.0,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size / 2 + strokeWidth,
      child: CustomPaint(
        painter: _GaugePainter(
          value: value,
          color: color,
          backgroundColor: AppColors.oledBlack.withValues(alpha: 0.5),
          strokeWidth: strokeWidth,
        ),
      ),
    );
  }
}

class _GaugePainter extends CustomPainter {
  final double value;
  final Color color;
  final Color backgroundColor;
  final double strokeWidth;

  _GaugePainter({
    required this.value,
    required this.color,
    required this.backgroundColor,
    required this.strokeWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height - strokeWidth / 2);
    final radius = (size.width - strokeWidth) / 2;
    final rect = Rect.fromCircle(center: center, radius: radius);

    // Draw background track
    final bgPaint = Paint()
      ..color = backgroundColor
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    canvas.drawArc(rect, pi, pi, false, bgPaint);

    // Draw progress track
    final progressPaint = Paint()
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    // Create a beautiful sweep gradient for the glow effect
    final gradient = SweepGradient(
      center: Alignment.bottomCenter,
      startAngle: pi,
      endAngle: 2 * pi,
      colors: [
        color.withValues(alpha: 0.5),
        color,
      ],
    );

    progressPaint.shader = gradient.createShader(rect);

    // Apply glow blur
    progressPaint.imageFilter = 
        const ColorFilter.mode(Colors.black, BlendMode.dstIn) as dynamic;
    progressPaint.maskFilter = const MaskFilter.blur(BlurStyle.solid, 4);

    final sweepAngle = pi * value.clamp(0.0, 1.0);
    canvas.drawArc(rect, pi, sweepAngle, false, progressPaint);
  }

  @override
  bool shouldRepaint(covariant _GaugePainter oldDelegate) {
    return oldDelegate.value != value ||
        oldDelegate.color != color ||
        oldDelegate.backgroundColor != backgroundColor ||
        oldDelegate.strokeWidth != strokeWidth;
  }
}
