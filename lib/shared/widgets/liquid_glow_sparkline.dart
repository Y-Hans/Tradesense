import 'dart:math';
import 'dart:ui';
import 'package:flutter/material.dart';
import '../../app/theme/app_theme.dart';

/// ───────────────────────────────────────────────
///  LIQUID-GLOW SPARKLINE CHART  ────────────────
///  Custom Bezier path charts with illuminated
///  gradient trails. Touching creates a laser dot
///  riding the curve + glowing particle embers.
/// ───────────────────────────────────────────────

class LiquidGlowSparkline extends StatefulWidget {
  const LiquidGlowSparkline({
    super.key,
    required this.data,
    this.width = 120,
    this.height = 48,
    this.strokeWidth = 2.5,
    this.isPositive = true,
    this.enableTouch = true,
  });

  final List<double> data;
  final double width;
  final double height;
  final double strokeWidth;
  final bool isPositive;
  final bool enableTouch;

  @override
  State<LiquidGlowSparkline> createState() => _LiquidGlowSparklineState();
}

class _LiquidGlowSparklineState extends State<LiquidGlowSparkline>
    with TickerProviderStateMixin {
  late AnimationController _emberController;
  final List<_Ember> _embers = [];
  Offset? _touchPoint;
  double? _touchValue;

  @override
  void initState() {
    super.initState();
    _emberController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();
  }

  @override
  void dispose() {
    _emberController.dispose();
    super.dispose();
  }

  void _onPanUpdate(DragUpdateDetails details, Path path, Rect bounds) {
    if (!widget.enableTouch) return;
    final local = details.localPosition;

    // Find closest point on path
    final metric = path.computeMetrics().first;
    final length = metric.length;
    double closestDist = double.infinity;
    double closestT = 0;

    for (double t = 0; t <= length; t += 2) {
      final pos = metric.getTangentForOffset(t)!.position;
      final dist = (pos - local).distance;
      if (dist < closestDist) {
        closestDist = dist;
        closestT = t;
      }
    }

    final tangent = metric.getTangentForOffset(closestT)!;
    final index = ((closestT / length) * (widget.data.length - 1)).round().clamp(0, widget.data.length - 1);

    setState(() {
      _touchPoint = tangent.position;
      _touchValue = widget.data[index];
    });

    // Spawn ember
    if (_embers.length < 12) {
      _embers.add(_Ember(
        position: tangent.position,
        birth: DateTime.now(),
        velocity: Offset(
          (Random().nextDouble() - 0.5) * 20,
          -30 - Random().nextDouble() * 40,
        ),
      ));
    }
  }

  void _onPanEnd(DragEndDetails details) {
    setState(() {
      _touchPoint = null;
      _touchValue = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _emberController,
      builder: (context, child) {
        return CustomPaint(
          painter: _SparklinePainter(
            data: widget.data,
            strokeWidth: widget.strokeWidth,
            isPositive: widget.isPositive,
            touchPoint: _touchPoint,
            embers: _embers,
            now: DateTime.now(),
          ),
          size: Size(widget.width, widget.height),
          child: GestureDetector(
            onPanUpdate: (d) {}, // Handled below
            onPanEnd: _onPanEnd,
            onPanCancel: () => setState(() => _touchPoint = null),
            child: Listener(
              onPointerMove: (event) {
                final path = _buildPath(widget.data, Size(widget.width, widget.height));
                _onPanUpdate(
                  DragUpdateDetails(
                    globalPosition: event.position,
                    localPosition: event.localPosition,
                  ),
                  path,
                  Rect.fromLTWH(0, 0, widget.width, widget.height),
                );
              },
              onPointerUp: (_) => _onPanEnd(DragEndDetails()),
              child: SizedBox(
                width: widget.width,
                height: widget.height,
              ),
            ),
          ),
        );
      },
    );
  }

  Path _buildPath(List<double> data, Size size) {
    if (data.length < 2) return Path();

    final minVal = data.reduce(min);
    final maxVal = data.reduce(max);
    final range = (maxVal - minVal).abs() < 0.001 ? 1.0 : maxVal - minVal;

    final dx = size.width / (data.length - 1);

    final path = Path();
    final startY = size.height - ((data[0] - minVal) / range) * size.height;
    path.moveTo(0, startY);

    for (int i = 1; i < data.length; i++) {
      final x = i * dx;
      final y = size.height - ((data[i] - minVal) / range) * size.height;

      // Smooth bezier
      final prevX = (i - 1) * dx;
      final prevY = size.height - ((data[i - 1] - minVal) / range) * size.height;
      final cp1x = prevX + dx * 0.4;
      final cp1y = prevY;
      final cp2x = x - dx * 0.4;
      final cp2y = y;

      path.cubicTo(cp1x, cp1y, cp2x, cp2y, x, y);
    }

    return path;
  }
}

class _Ember {
  final Offset position;
  final DateTime birth;
  final Offset velocity;

  _Ember({required this.position, required this.birth, required this.velocity});

  double get ageMs => DateTime.now().difference(birth).inMilliseconds.toDouble();
  double get progress => (ageMs / 1200).clamp(0.0, 1.0);
}

class _SparklinePainter extends CustomPainter {
  final List<double> data;
  final double strokeWidth;
  final bool isPositive;
  final Offset? touchPoint;
  final List<_Ember> embers;
  final DateTime now;

  _SparklinePainter({
    required this.data,
    required this.strokeWidth,
    required this.isPositive,
    required this.embers,
    required this.now,
    this.touchPoint,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (data.length < 2) return;

    final minVal = data.reduce(min);
    final maxVal = data.reduce(max);
    final range = (maxVal - minVal).abs() < 0.001 ? 1.0 : maxVal - minVal;
    final dx = size.width / (data.length - 1);

    // Build path
    final path = Path();
    final startY = size.height - ((data[0] - minVal) / range) * size.height;
    path.moveTo(0, startY);

    for (int i = 1; i < data.length; i++) {
      final x = i * dx;
      final y = size.height - ((data[i] - minVal) / range) * size.height;
      final prevX = (i - 1) * dx;
      final prevY = size.height - ((data[i - 1] - minVal) / range) * size.height;
      path.cubicTo(
        prevX + dx * 0.4, prevY,
        x - dx * 0.4, y,
        x, y,
      );
    }

    final lineColor = isPositive ? AppColors.neonEmerald : AppColors.crimsonSpark;

    // 1. Glow beneath the line
    final glowPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth * 4
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8)
      ..color = lineColor.withValues(alpha: 0.25);
    canvas.drawPath(path, glowPaint);

    // 2. Gradient line
    final linePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..shader = LinearGradient(
        begin: Alignment.centerLeft,
        end: Alignment.centerRight,
        colors: [
          lineColor.withValues(alpha: 0.6),
          lineColor,
          lineColor.withValues(alpha: 0.6),
        ],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));
    canvas.drawPath(path, linePaint);

    // 3. Area fill beneath
    final fillPath = Path.from(path);
    fillPath.lineTo(size.width, size.height);
    fillPath.lineTo(0, size.height);
    fillPath.close();

    final fillPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          lineColor.withValues(alpha: 0.15),
          lineColor.withValues(alpha: 0.0),
        ],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));
    canvas.drawPath(fillPath, fillPaint);

    // 4. Touch laser dot
    if (touchPoint != null) {
      // Outer glow
      final dotGlow = Paint()
        ..color = AppColors.electricCyan.withValues(alpha: 0.4)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12);
      canvas.drawCircle(touchPoint!, 10, dotGlow);

      // Inner dot
      final dotPaint = Paint()
        ..color = AppColors.electricCyan
        ..style = PaintingStyle.fill;
      canvas.drawCircle(touchPoint!, 4, dotPaint);

      // Crosshair
      final crossPaint = Paint()
        ..color = AppColors.electricCyan.withValues(alpha: 0.3)
        ..strokeWidth = 0.5;
      canvas.drawLine(
        Offset(0, touchPoint!.dy),
        Offset(size.width, touchPoint!.dy),
        crossPaint,
      );
    }

    // 5. Floating embers
    for (final ember in embers) {
      final p = ember.progress;
      if (p >= 1.0) continue;

      final currentPos = ember.position + ember.velocity * p;
      final alpha = (1.0 - p) * 0.6;
      final radius = 2.0 * (1.0 - p * 0.5);

      final emberPaint = Paint()
        ..color = AppColors.electricCyan.withValues(alpha: alpha)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);
      canvas.drawCircle(currentPos, radius, emberPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _SparklinePainter old) {
    return old.touchPoint != touchPoint ||
        old.embers.length != embers.length ||
        old.now != now;
  }
}
