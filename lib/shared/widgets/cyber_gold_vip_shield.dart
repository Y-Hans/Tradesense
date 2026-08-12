import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../app/theme/app_theme.dart';

/// ───────────────────────────────────────────────
///  CYBER GOLD VIP SHIELD HEADER  ───────────────
///  Compact app bar widget with a 3D Cyber Gold
///  progress ring. Tapping triggers a confetti
///  micro-reward revealing streak bonuses.
/// ───────────────────────────────────────────────

class CyberGoldVipShield extends StatefulWidget {
  const CyberGoldVipShield({
    super.key,
    required this.streakCount,
    required this.dailyProgress,
    this.maxDaily = 5,
    this.onTap,
    this.size = 48,
  });

  final int streakCount;
  final int dailyProgress;
  final int maxDaily;
  final VoidCallback? onTap;
  final double size;

  @override
  State<CyberGoldVipShield> createState() => _CyberGoldVipShieldState();
}

class _CyberGoldVipShieldState extends State<CyberGoldVipShield>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  bool _isPressed = false;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  double get _progress => (widget.dailyProgress / widget.maxDaily).clamp(0.0, 1.0);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) {
        HapticFeedback.lightImpact();
        setState(() => _isPressed = true);
      },
      onTapUp: (_) {
        setState(() => _isPressed = false);
        widget.onTap?.call();
      },
      onTapCancel: () => setState(() => _isPressed = false),
      child: AnimatedBuilder(
        animation: _pulseController,
        builder: (context, child) {
          final pulse = 1.0 + (_pulseController.value * 0.06);
          final scale = _isPressed ? 0.88 : pulse;

          return Transform.scale(
            scale: scale,
            child: SizedBox(
              width: widget.size,
              height: widget.size,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Outer glow
                  Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.cyberGold.withValues(
                            alpha: 0.2 + _pulseController.value * 0.15,
                          ),
                          blurRadius: 16,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                  ),
                  // Progress ring
                  CustomPaint(
                    size: Size(widget.size, widget.size),
                    painter: _VipRingPainter(
                      context: context,
                      progress: _progress,
                      strokeWidth: 3.5,
                      glowIntensity: _pulseController.value,
                    ),
                  ),
                  // Inner shield
                  Container(
                    width: widget.size * 0.65,
                    height: widget.size * 0.65,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          AppColors.cyberGold.withValues(alpha: 0.2),
                          Theme.of(context).colorScheme.surface.withValues(alpha: 0.9),
                        ],
                      ),
                      border: Border.all(
                        color: AppColors.cyberGold.withValues(alpha: 0.4),
                        width: 1,
                      ),
                    ),
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.local_fire_department,
                            color: AppColors.cyberGold.withValues(
                              alpha: 0.8 + _pulseController.value * 0.2,
                            ),
                            size: widget.size * 0.28,
                          ),
                          Text(
                            '${widget.streakCount}',
                            style: TextStyle(
                              color: AppColors.cyberGold,
                              fontSize: widget.size * 0.2,
                              fontWeight: FontWeight.w800,
                              height: 1,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  // Sparkle indicators when full
                  if (_progress >= 1.0) ...[
                    _Sparkle(
                      angle: -pi / 4,
                      radius: widget.size * 0.55,
                      pulse: _pulseController.value,
                    ),
                    _Sparkle(
                      angle: pi * 0.75,
                      radius: widget.size * 0.55,
                      pulse: 1.0 - _pulseController.value,
                    ),
                  ],
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _Sparkle extends StatelessWidget {
  const _Sparkle({
    required this.angle,
    required this.radius,
    required this.pulse,
  });

  final double angle;
  final double radius;
  final double pulse;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: radius + cos(angle) * radius * 0.5 - 3,
      top: radius + sin(angle) * radius * 0.5 - 3,
      child: Opacity(
        opacity: 0.4 + pulse * 0.6,
        child: Container(
          width: 6,
          height: 6,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AppColors.cyberGold,
            boxShadow: [
              BoxShadow(
                color: AppColors.cyberGold.withValues(alpha: 0.6),
                blurRadius: 6,
                spreadRadius: 1,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _VipRingPainter extends CustomPainter {
  final BuildContext context;
  final double progress;
  final double strokeWidth;
  final double glowIntensity;

  _VipRingPainter({
    required this.context,
    required this.progress,
    required this.strokeWidth,
    required this.glowIntensity,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - strokeWidth) / 2;

    // Background track
    final trackPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round
      ..color = Theme.of(context).cardColor.withValues(alpha: 0.6);
    canvas.drawCircle(center, radius, trackPaint);

    // Progress arc
    final sweep = progress * pi * 2;
    if (sweep > 0.01) {
      // Glow behind arc
      final glowPaint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth * 2.5
        ..strokeCap = StrokeCap.round
        ..color = AppColors.cyberGold.withValues(alpha: 0.2 + glowIntensity * 0.15)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        -pi / 2,
        sweep,
        false,
        glowPaint,
      );

      // Main arc
      final arcPaint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.round
        ..shader = SweepGradient(
          colors: [
            AppColors.cyberGold.withValues(alpha: 0.7),
            AppColors.cyberGold,
            AppColors.neonEmerald.withValues(alpha: 0.8),
          ],
          stops: const [0.0, 0.5, 1.0],
          startAngle: -pi / 2,
          endAngle: -pi / 2 + sweep,
        ).createShader(Rect.fromCircle(center: center, radius: radius));

      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        -pi / 2,
        sweep,
        false,
        arcPaint,
      );

      // Cap dot
      final capAngle = -pi / 2 + sweep;
      final capPos = center + Offset(cos(capAngle) * radius, sin(capAngle) * radius);
      final capPaint = Paint()
        ..color = AppColors.cyberGold
        ..style = PaintingStyle.fill;
      canvas.drawCircle(capPos, strokeWidth * 0.6, capPaint);

      // Cap glow
      final capGlow = Paint()
        ..color = AppColors.cyberGold.withValues(alpha: 0.5)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);
      canvas.drawCircle(capPos, strokeWidth * 1.2, capGlow);
    }
  }

  @override
  bool shouldRepaint(covariant _VipRingPainter old) {
    return old.progress != progress || old.glowIntensity != glowIntensity;
  }
}
