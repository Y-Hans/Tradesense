import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../tokens/colors.dart';

class BitcoinLoader extends StatefulWidget {
  final double size;
  
  const BitcoinLoader({
    super.key,
    this.size = 48.0,
  });

  @override
  State<BitcoinLoader> createState() => _BitcoinLoaderState();
}

class _BitcoinLoaderState extends State<BitcoinLoader>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();
    _animation = Tween<double>(begin: 0, end: 2 * math.pi).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeInOutSine,
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Transform(
          alignment: Alignment.center,
          transform: Matrix4.identity()
            ..setEntry(3, 2, 0.001) // perspective
            ..rotateY(_animation.value),
          child: Container(
            width: widget.size,
            height: widget.size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFFF7931A), // Bitcoin Orange
                  Color(0xFFF0E68C), // Light Gold
                  Color(0xFFF7931A),
                ],
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFF7931A).withValues(alpha: 0.4),
                  blurRadius: 12,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: Center(
              child: Icon(
                Icons.currency_bitcoin,
                color: Colors.white,
                size: widget.size * 0.7,
              ),
            ),
          ),
        );
      },
    );
  }
}
