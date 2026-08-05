import 'dart:async';
import 'dart:math';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sensors_plus/sensors_plus.dart';
import '../../app/theme/app_theme.dart';

/// ───────────────────────────────────────────────
///  HOLOGRAPHIC GYROSCOPE HERO BENTO CARD  ──────
///  Uses sensors_plus gyroscope events to shift
///  specular highlights, neon borders, and 3D
///  perspective in real-time as the phone tilts.
/// ───────────────────────────────────────────────

class HolographicGyroCard extends StatefulWidget {
  const HolographicGyroCard({
    super.key,
    required this.child,
    this.borderRadius = 24,
    this.maxTiltDeg = 8.0,
    this.enableGyro = true,
    this.glowColor,
    this.borderGradient,
    this.surfaceGradient,
  });

  final Widget child;
  final double borderRadius;
  final double maxTiltDeg;
  final bool enableGyro;
  final Color? glowColor;
  final Gradient? borderGradient;
  final Gradient? surfaceGradient;

  @override
  State<HolographicGyroCard> createState() => _HolographicGyroCardState();
}

class _HolographicGyroCardState extends State<HolographicGyroCard>
    with SingleTickerProviderStateMixin {
  StreamSubscription<GyroscopeEvent>? _gyroSub;

  // Smoothed gyro values (low-pass filter)
  double _gyroX = 0.0;
  double _gyroY = 0.0;

  // Spring-back animation when gyro disabled or steady
  late AnimationController _springController;
  late Animation<double> _springX;
  late Animation<double> _springY;

  bool _isHovered = false;

  @override
  void initState() {
    super.initState();
    _springController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    if (widget.enableGyro) {
      _initGyroscope();
    }
  }

  void _initGyroscope() {
    _gyroSub = gyroscopeEventStream(samplingPeriod: SensorInterval.uiInterval)
        .listen((event) {
      if (!mounted) return;

      // Low-pass filter for smooth motion
      const factor = 0.12;
      setState(() {
        _gyroX += (event.x - _gyroX) * factor;
        _gyroY += (event.y - _gyroY) * factor;
      });
    });
  }

  @override
  void dispose() {
    _gyroSub?.cancel();
    _springController.dispose();
    super.dispose();
  }

  double get _tiltX {
    // Clamp and convert radians to a usable range
    final raw = _gyroX.clamp(-widget.maxTiltDeg, widget.maxTiltDeg);
    return raw * (pi / 180);
  }

  double get _tiltY {
    final raw = _gyroY.clamp(-widget.maxTiltDeg, widget.maxTiltDeg);
    return raw * (pi / 180);
  }

  Offset get _focal {
    // Normalized -1..1 focal point for specular gradient
    final fx = (_gyroY / widget.maxTiltDeg).clamp(-1.0, 1.0);
    final fy = (_gyroX / widget.maxTiltDeg).clamp(-1.0, 1.0);
    return Offset(fx, fy);
  }

  @override
  Widget build(BuildContext context) {
    final r = widget.borderRadius;
    final borderRadius = BorderRadius.circular(r);

    // 3D perspective transform
    final transform = Matrix4.identity()
      ..setEntry(3, 2, 0.0012) // Perspective depth
      ..rotateX(_tiltX)
      ..rotateY(_tiltY);

    final specularGradient = widget.surfaceGradient ??
        AppGradients.specular(focal: _focal);

    final glowColor = widget.glowColor ?? AppColors.electricCyan;

    Widget content = Container(
      decoration: BoxDecoration(
        borderRadius: borderRadius,
        border: GradientBoxBorder(
          gradient: widget.borderGradient ??
              LinearGradient(
                begin: Alignment(-_focal.dx, -_focal.dy),
                end: Alignment(_focal.dx, _focal.dy),
                colors: [
                  glowColor.withValues(alpha: _isHovered ? 0.8 : 0.4),
                  Colors.transparent,
                  glowColor.withValues(alpha: _isHovered ? 0.6 : 0.3),
                ],
              ),
          width: _isHovered ? 1.8 : 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: glowColor.withValues(
                alpha: _isHovered ? 0.25 : 0.12),
            blurRadius: _isHovered ? 32 : 20,
            spreadRadius: _isHovered ? 4 : 0,
            offset: Offset(_focal.dx * 4, _focal.dy * 4),
          ),
          ...AppShadows.cardFloat,
        ],
      ),
      child: ClipRRect(
        borderRadius: borderRadius,
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: borderRadius,
              gradient: AppGradients.glassSurface(hovered: _isHovered),
            ),
            child: Stack(
              children: [
                // Specular highlight layer
                Positioned.fill(
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: specularGradient,
                    ),
                  ),
                ),
                // Content
                widget.child,
              ],
            ),
          ),
        ),
      ),
    );

    // Apply 3D transform
    content = Transform(
      transform: transform,
      alignment: FractionalOffset.center,
      child: content,
    );

    // Haptic on interaction
    return GestureDetector(
      onTapDown: (_) {
        HapticFeedback.lightImpact();
        setState(() => _isHovered = true);
      },
      onTapUp: (_) => setState(() => _isHovered = false),
      onTapCancel: () => setState(() => _isHovered = false),
      child: MouseRegion(
        onEnter: (_) => setState(() => _isHovered = true),
        onExit: (_) => setState(() => _isHovered = false),
        child: content,
      ),
    );
  }
}

/// ───────────────────────────────────────────────
///  GRADIENT BORDER BOX DECORATION  ─────────────
///  Custom border that accepts a gradient instead
///  of a solid color.
/// ───────────────────────────────────────────────
class GradientBoxBorder extends BoxBorder {
  const GradientBoxBorder({
    required this.gradient,
    this.width = 1.0,
  });

  final Gradient gradient;
  final double width;

  @override
  BorderSide get top => BorderSide.none;

  @override
  BorderSide get bottom => BorderSide.none;

  @override
  bool get isUniform => false;

  /// Required by [BoxBorder]. A gradient border has no inset geometry, so the
  /// dimensions are zero (the stroke is painted on the rect edge).
  @override
  EdgeInsetsGeometry get dimensions => EdgeInsets.zero;

  @override
  GradientBoxBorder scale(double t) => this;

  @override
  ShapeBorder? lerpFrom(ShapeBorder? a, double t) => this;

  @override
  ShapeBorder? lerpTo(ShapeBorder? b, double t) => this;

  @override
  void paint(
    Canvas canvas,
    Rect rect, {
    TextDirection? textDirection,
    BoxShape shape = BoxShape.rectangle,
    BorderRadius? borderRadius,
  }) {
    final paint = Paint()
      ..strokeWidth = width
      ..style = PaintingStyle.stroke;

    final path = Path();
    if (borderRadius != null) {
      path.addRRect(borderRadius.toRRect(rect));
    } else {
      path.addRect(rect);
    }

    paint.shader = gradient.createShader(rect);
    canvas.drawPath(path, paint);
  }
}
