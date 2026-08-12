import 'package:flutter/material.dart';
import '../../app/theme/app_theme.dart';

/// ───────────────────────────────────────────────
///  SENTIMENT-REACTIVE AMBIENT MESH ENGINE  ─────
///  A background canvas that subtly pulses Neon
///  Emerald (bullish) or Crimson Spark (bearish)
///  radial gradients based on portfolio P&L state.
///  Tapping creates a liquid ripple effect.
/// ───────────────────────────────────────────────

enum Sentiment { bullish, bearish, neutral }

class AmbientMeshBackground extends StatefulWidget {
  const AmbientMeshBackground({
    super.key,
    required this.sentiment,
    required this.child,
    this.intensity = 1.0,
    this.enableRipples = true,
  });

  final Sentiment sentiment;
  final Widget child;
  final double intensity;
  final bool enableRipples;

  @override
  State<AmbientMeshBackground> createState() => _AmbientMeshBackgroundState();
}

class _AmbientMeshBackgroundState extends State<AmbientMeshBackground>
    with TickerProviderStateMixin {
  late AnimationController _breatheController;
  late AnimationController _rippleController;
  final List<_Ripple> _ripples = [];

  @override
  void initState() {
    super.initState();
    _breatheController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 4500),
    )..repeat(reverse: true);

    _rippleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..addListener(() {
        if (mounted) setState(() {});
      });
  }

  @override
  void dispose() {
    _breatheController.dispose();
    _rippleController.dispose();
    super.dispose();
  }

  void _onTapDown(TapDownDetails details) {
    if (!widget.enableRipples) return;
    final box = context.findRenderObject() as RenderBox;
    final localPos = box.globalToLocal(details.globalPosition);

    setState(() {
      _ripples.add(_Ripple(
        origin: localPos,
        birthTime: DateTime.now(),
        color: _rippleColor,
      ));
    });

    // Prune old ripples
    _pruneRipples();

    if (!_rippleController.isAnimating) {
      _rippleController.forward(from: 0);
    }
  }

  void _pruneRipples() {
    final now = DateTime.now();
    _ripples.removeWhere(
      (r) => now.difference(r.birthTime).inMilliseconds > 2500,
    );
  }

  Color get _sentimentColor {
    switch (widget.sentiment) {
      case Sentiment.bullish:
        return AppColors.neonEmerald;
      case Sentiment.bearish:
        return AppColors.crimsonSpark;
      case Sentiment.neutral:
        return AppColors.electricCyan;
    }
  }

  Color get _rippleColor {
    switch (widget.sentiment) {
      case Sentiment.bullish:
        return AppColors.neonEmerald.withValues(alpha: 0.25);
      case Sentiment.bearish:
        return AppColors.crimsonSpark.withValues(alpha: 0.20);
      case Sentiment.neutral:
        return AppColors.electricCyan.withValues(alpha: 0.18);
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: _onTapDown,
      behavior: HitTestBehavior.translucent,
      child: AnimatedBuilder(
        animation: _breatheController,
        builder: (context, child) {
          return CustomPaint(
            painter: _AmbientMeshPainter(
              context: context,
              breatheValue: _breatheController.value,
              sentimentColor: _sentimentColor,
              intensity: widget.intensity,
              ripples: _ripples,
              rippleProgress: _rippleController.value,
            ),
            size: Size.infinite,
            child: child,
          );
        },
        child: widget.child,
      ),
    );
  }
}

class _Ripple {
  final Offset origin;
  final DateTime birthTime;
  final Color color;

  _Ripple({required this.origin, required this.birthTime, required this.color});

  double get ageMs => DateTime.now().difference(birthTime).inMilliseconds.toDouble();
  double get progress => (ageMs / 2500).clamp(0.0, 1.0);
}

class _AmbientMeshPainter extends CustomPainter {
  final BuildContext context;
  final double breatheValue;
  final Color sentimentColor;
  final double intensity;
  final List<_Ripple> ripples;
  final double rippleProgress;

  _AmbientMeshPainter({
    required this.context,
    required this.breatheValue,
    required this.sentimentColor,
    required this.intensity,
    required this.ripples,
    required this.rippleProgress,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // 1. Base OLED fill
    canvas.drawRect(
      Offset.zero & size,
      Paint()..color = AppColors.oledObsidian,
    );

    // 2. Deep vignette
    final vignettePaint = Paint()
      ..shader = RadialGradient(
        center: Alignment(0, -0.3),
        radius: 1.2,
        colors: [
          Colors.transparent,
          Theme.of(context).scaffoldBackgroundColor.withValues(alpha: 0.6),
        ],
        stops: const [0.4, 1.0],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));
    canvas.drawRect(Offset.zero & size, vignettePaint);

    // 3. Sentiment ambient orb (breathing)
    final orbAlpha = (0.06 + breatheValue * 0.06) * intensity;
    final orbRadius = size.width * (0.5 + breatheValue * 0.15);

    final orbPaint = Paint()
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 80)
      ..color = sentimentColor.withValues(alpha: orbAlpha);

    canvas.drawCircle(
      Offset(size.width * 0.5, size.height * 0.25),
      orbRadius,
      orbPaint,
    );

    // 4. Secondary counter-pulse orb
    final orb2Paint = Paint()
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 60)
      ..color = sentimentColor.withValues(alpha: orbAlpha * 0.5);

    canvas.drawCircle(
      Offset(size.width * 0.2, size.height * 0.6),
      orbRadius * 0.7,
      orb2Paint,
    );

    // 5. Ripples
    for (final ripple in ripples) {
      final p = ripple.progress;
      if (p >= 1.0) continue;

      final radius = p * size.width * 0.6;
      final alpha = (1.0 - p) * 0.15 * intensity;
      final strokeWidth = (1.0 - p) * 3.0;

      final ripplePaint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..color = ripple.color.withValues(alpha: alpha);

      canvas.drawCircle(ripple.origin, radius, ripplePaint);

      // Inner glow
      final glowPaint = Paint()
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 20)
        ..color = ripple.color.withValues(alpha: alpha * 0.5);
      canvas.drawCircle(ripple.origin, radius * 0.5, glowPaint);
    }

    // 6. Subtle noise texture overlay (very faint)
    final noisePaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.008);
    // We skip actual noise for performance; the gradient layers provide enough texture
    canvas.drawRect(Offset.zero & size, noisePaint);
  }

  @override
  bool shouldRepaint(covariant _AmbientMeshPainter old) {
    return old.breatheValue != breatheValue ||
        old.sentimentColor != sentimentColor ||
        old.ripples.length != ripples.length ||
        old.rippleProgress != rippleProgress;
  }
}
