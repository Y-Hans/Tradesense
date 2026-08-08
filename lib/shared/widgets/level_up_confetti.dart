import 'dart:math';
import 'package:flutter/material.dart';

class ConfettiController extends ChangeNotifier {
  void fire() {
    notifyListeners();
  }
}

class LevelUpConfetti extends StatefulWidget {
  final Widget child;
  final ConfettiController controller;

  const LevelUpConfetti({
    super.key,
    required this.child,
    required this.controller,
  });

  @override
  State<LevelUpConfetti> createState() => _LevelUpConfettiState();
}

class _LevelUpConfettiState extends State<LevelUpConfetti>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  final List<_Particle> _particles = [];
  final Random _random = Random();

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );

    widget.controller.addListener(_onFire);
    
    _animationController.addListener(() {
      setState(() {
        _updateParticles();
      });
    });
  }
  
  @override
  void didUpdateWidget(covariant LevelUpConfetti oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.controller != oldWidget.controller) {
      oldWidget.controller.removeListener(_onFire);
      widget.controller.addListener(_onFire);
    }
  }

  void _onFire() {
    _generateParticles();
    _animationController.forward(from: 0.0);
  }

  void _generateParticles() {
    _particles.clear();
    final colors = [
      const Color(0xFF00E5FF), // Neon Cyan
      const Color(0xFFFFD700), // Neon Gold
      const Color(0xFF00FF66), // Profit Green
      const Color(0xFFFF3366), // Neon Red
      const Color(0xFF5E5CE6), // Accent Purple
    ];

    for (int i = 0; i < 40; i++) {
      final angle = _random.nextDouble() * pi * 2;
      final speed = _random.nextDouble() * 150 + 50;
      _particles.add(
        _Particle(
          x: 0,
          y: 0,
          vx: cos(angle) * speed,
          vy: sin(angle) * speed - 100, // Bias upwards
          color: colors[_random.nextInt(colors.length)],
          size: _random.nextDouble() * 6 + 4,
          life: 1.0,
          decay: _random.nextDouble() * 0.5 + 0.5,
        ),
      );
    }
  }

  void _updateParticles() {
    const dt = 0.016; // Approx 60fps delta
    for (var particle in _particles) {
      particle.x += particle.vx * dt;
      particle.y += particle.vy * dt;
      particle.vy += 150 * dt; // Gravity
      particle.life -= particle.decay * dt;
    }
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onFire);
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      alignment: Alignment.center,
      children: [
        widget.child,
        if (_animationController.isAnimating)
          Positioned.fill(
            child: IgnorePointer(
              child: CustomPaint(
                painter: _ConfettiPainter(particles: _particles),
              ),
            ),
          ),
      ],
    );
  }
}

class _Particle {
  double x;
  double y;
  double vx;
  double vy;
  Color color;
  double size;
  double life;
  double decay;

  _Particle({
    required this.x,
    required this.y,
    required this.vx,
    required this.vy,
    required this.color,
    required this.size,
    required this.life,
    required this.decay,
  });
}

class _ConfettiPainter extends CustomPainter {
  final List<_Particle> particles;

  _ConfettiPainter({required this.particles});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;
    final center = Offset(size.width / 2, size.height / 2);

    for (var p in particles) {
      if (p.life > 0) {
        paint.color = p.color.withValues(alpha: p.life.clamp(0.0, 1.0));
        // Add a slight glow
        paint.maskFilter = MaskFilter.blur(BlurStyle.solid, p.size * 0.5);
        canvas.drawCircle(center + Offset(p.x, p.y), p.size, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _ConfettiPainter oldDelegate) => true;
}
