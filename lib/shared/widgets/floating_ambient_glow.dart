import 'package:flutter/material.dart';

class FloatingAmbientGlow extends StatefulWidget {
  final Color color;
  final double radius;
  final Duration animationDuration;
  final AlignmentGeometry alignment;

  const FloatingAmbientGlow({
    super.key,
    required this.color,
    this.radius = 100.0,
    this.animationDuration = const Duration(seconds: 4),
    this.alignment = Alignment.center,
  });

  @override
  State<FloatingAmbientGlow> createState() => _FloatingAmbientGlowState();
}

class _FloatingAmbientGlowState extends State<FloatingAmbientGlow>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.animationDuration,
    )..repeat(reverse: true);

    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.2).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOutSine),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: widget.alignment,
      child: AnimatedBuilder(
        animation: _scaleAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: Container(
              width: widget.radius * 2,
              height: widget.radius * 2,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: widget.color.withValues(alpha: 0.3),
                    blurRadius: widget.radius,
                    spreadRadius: widget.radius * 0.5,
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
