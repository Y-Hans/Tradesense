import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../app/theme/app_theme.dart';

/// ───────────────────────────────────────────────
///  CYBERPUNK RADIAL ACTION RING  ───────────────
///  Long-pressing triggers a glowing neon-cyan
///  radial menu around the touch point with haptic
///  ticks. Swiping toward an arc segment activates
///  it with a micro-particle burst.
/// ───────────────────────────────────────────────

enum RadialAction {
  buy('Buy', Icons.arrow_upward, AppColors.neonEmerald),
  swap('Swap', Icons.swap_horiz, AppColors.electricCyan),
  alert('Alert', Icons.notifications_outlined, AppColors.alert),
  send('Send', Icons.send, AppColors.cyberGold);

  final String label;
  final IconData icon;
  final Color color;

  const RadialAction(this.label, this.icon, this.color);
}

class RadialActionRing extends StatefulWidget {
  const RadialActionRing({
    super.key,
    required this.child,
    required this.actions,
    required this.onAction,
    this.ringRadius = 90,
  });

  final Widget child;
  final List<RadialAction> actions;
  final void Function(RadialAction) onAction;
  final double ringRadius;

  @override
  State<RadialActionRing> createState() => _RadialActionRingState();
}

class _RadialActionRingState extends State<RadialActionRing>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  bool _isOpen = false;
  Offset _origin = Offset.zero;
  int? _hoveredIndex;
  final List<_BurstParticle> _particles = [];

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
      reverseDuration: const Duration(milliseconds: 200),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _open(Offset globalPos) {
    final box = context.findRenderObject() as RenderBox;
    _origin = box.globalToLocal(globalPos);
    setState(() => _isOpen = true);
    _controller.forward(from: 0);
    HapticFeedback.mediumImpact();
  }

  void _close() {
    if (_hoveredIndex != null) {
      _triggerAction(widget.actions[_hoveredIndex!]);
    }
    setState(() {
      _isOpen = false;
      _hoveredIndex = null;
    });
    _controller.reverse();
  }

  void _triggerAction(RadialAction action) {
    _spawnBurst(_origin, action.color);
    widget.onAction(action);
    HapticFeedback.heavyImpact();
  }

  void _spawnBurst(Offset origin, Color color) {
    final rand = Random();
    for (int i = 0; i < 20; i++) {
      final angle = rand.nextDouble() * pi * 2;
      final speed = rand.nextDouble() * 120 + 40;
      _particles.add(_BurstParticle(
        origin: origin,
        velocity: Offset(cos(angle) * speed, sin(angle) * speed),
        color: color,
        size: rand.nextDouble() * 4 + 2,
        birth: DateTime.now(),
      ));
    }
    setState(() {});
    Future.delayed(const Duration(milliseconds: 600), () {
      if (mounted) setState(() => _particles.clear());
    });
  }

  void _updateHover(Offset localPos) {
    if (!_isOpen) return;
    final delta = localPos - _origin;
    final dist = delta.distance;

    if (dist < widget.ringRadius * 0.4) {
      setState(() => _hoveredIndex = null);
      return;
    }

    final angle = atan2(delta.dy, delta.dx);
    final sectorAngle = (pi * 2) / widget.actions.length;
    // Normalize angle to 0..2pi starting from -pi/2 (top)
    var normAngle = angle + pi / 2;
    if (normAngle < 0) normAngle += pi * 2;

    final index = (normAngle / sectorAngle).floor() % widget.actions.length;

    if (_hoveredIndex != index) {
      HapticFeedback.selectionClick();
      setState(() => _hoveredIndex = index);
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onLongPressStart: (details) => _open(details.globalPosition),
      onLongPressEnd: (_) => _close(),
      onLongPressMoveUpdate: (details) => _updateHover(
        (context.findRenderObject() as RenderBox).globalToLocal(details.globalPosition),
      ),
      onLongPressCancel: () => setState(() {
        _isOpen = false;
        _controller.reverse();
      }),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          widget.child,
          if (_isOpen)
            Positioned.fill(
              child: AnimatedBuilder(
                animation: _controller,
                builder: (context, child) {
                  return CustomPaint(
                    painter: _RadialRingPainter(
                      context: context,
                      origin: _origin,
                      actions: widget.actions,
                      ringRadius: widget.ringRadius,
                      progress: _controller.value,
                      hoveredIndex: _hoveredIndex,
                      particles: _particles,
                    ),
                    size: Size.infinite,
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}

class _BurstParticle {
  final Offset origin;
  final Offset velocity;
  final Color color;
  final double size;
  final DateTime birth;

  _BurstParticle({
    required this.origin,
    required this.velocity,
    required this.color,
    required this.size,
    required this.birth,
  });

  double get progress {
    final ms = DateTime.now().difference(birth).inMilliseconds;
    return (ms / 500).clamp(0.0, 1.0);
  }
}

class _RadialRingPainter extends CustomPainter {
  final BuildContext context;
  final Offset origin;
  final List<RadialAction> actions;
  final double ringRadius;
  final double progress;
  final int? hoveredIndex;
  final List<_BurstParticle> particles;

  _RadialRingPainter({
    required this.context,
    required this.origin,
    required this.actions,
    required this.ringRadius,
    required this.progress,
    required this.hoveredIndex,
    required this.particles,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Dim overlay
    final dimPaint = Paint()
      ..color = Theme.of(context).scaffoldBackgroundColor.withValues(alpha: 0.4 * progress);
    canvas.drawRect(Offset.zero & size, dimPaint);

    // Ring glow
    final ringGlow = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..color = AppColors.electricCyan.withValues(alpha: 0.3 * progress)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12);
    canvas.drawCircle(origin, ringRadius * progress, ringGlow);

    // Main ring
    final ringPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5
      ..color = AppColors.electricCyan.withValues(alpha: 0.6 * progress);
    canvas.drawCircle(origin, ringRadius * progress, ringPaint);

    // Arc segments
    final sectorAngle = (pi * 2) / actions.length;
    for (int i = 0; i < actions.length; i++) {
      final startAngle = -pi / 2 + i * sectorAngle;
      final endAngle = startAngle + sectorAngle * 0.85;
      final isHovered = hoveredIndex == i;

      final arcPaint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = isHovered ? 4 * progress : 2 * progress
        ..strokeCap = StrokeCap.round
        ..color = actions[i].color.withValues(
          alpha: isHovered ? 0.9 * progress : 0.5 * progress,
        )
        ..maskFilter = isHovered
            ? const MaskFilter.blur(BlurStyle.normal, 8)
            : null;

      canvas.drawArc(
        Rect.fromCircle(center: origin, radius: ringRadius * progress),
        startAngle,
        endAngle - startAngle,
        false,
        arcPaint,
      );

      // Icon position
      final midAngle = startAngle + (endAngle - startAngle) / 2;
      final iconPos = origin +
          Offset(
            cos(midAngle) * ringRadius * progress * 0.7,
            sin(midAngle) * ringRadius * progress * 0.7,
          );

      // Icon background
      final bgPaint = Paint()
        ..color = Theme.of(context).colorScheme.surface.withValues(
          alpha: isHovered ? 0.95 * progress : 0.8 * progress,
        );
      canvas.drawCircle(iconPos, 18 * progress, bgPaint);

      // Icon glow if hovered
      if (isHovered) {
        final glowPaint = Paint()
          ..color = actions[i].color.withValues(alpha: 0.4 * progress)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10);
        canvas.drawCircle(iconPos, 22 * progress, glowPaint);
      }
    }

    // Particles
    for (final p in particles) {
      final prog = p.progress;
      if (prog >= 1.0) continue;
      final pos = p.origin + p.velocity * prog;
      final alpha = (1.0 - prog) * 0.8;
      final particlePaint = Paint()
        ..color = p.color.withValues(alpha: alpha)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3);
      canvas.drawCircle(pos, p.size * (1.0 - prog * 0.3), particlePaint);
    }
  }

  @override
  bool shouldRepaint(covariant _RadialRingPainter old) {
    return old.progress != progress ||
        old.hoveredIndex != hoveredIndex ||
        old.particles.length != particles.length;
  }
}
