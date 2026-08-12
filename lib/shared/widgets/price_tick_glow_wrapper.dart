import 'package:flutter/material.dart';
import '../../app/theme/app_theme.dart';

class PriceTickGlowWrapper extends StatefulWidget {
  final Widget child;
  final double value;
  final BorderRadius? borderRadius;

  const PriceTickGlowWrapper({
    super.key,
    required this.child,
    required this.value,
    this.borderRadius,
  });

  @override
  State<PriceTickGlowWrapper> createState() => _PriceTickGlowWrapperState();
}

class _PriceTickGlowWrapperState extends State<PriceTickGlowWrapper>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _glowAnimation;
  double? _previousValue;
  bool _isPositiveTick = true;

  @override
  void initState() {
    super.initState();
    _previousValue = widget.value;
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );

    _glowAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeOutCubic,
      ),
    );
  }

  @override
  void didUpdateWidget(covariant PriceTickGlowWrapper oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.value != oldWidget.value && _previousValue != null) {
      if (widget.value != _previousValue) {
        _isPositiveTick = widget.value > _previousValue!;
        _previousValue = widget.value;
        
        _controller.forward(from: 0.0);
      }
    } else {
      _previousValue ??= widget.value;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final effectiveRadius = widget.borderRadius ?? BorderRadius.circular(20);
    final glowColor = _isPositiveTick ? AppColors.profit : AppColors.loss;

    return Stack(
      children: [
        widget.child,
        Positioned.fill(
          child: IgnorePointer(
            child: AnimatedBuilder(
              animation: _glowAnimation,
              builder: (context, child) {
                if (!_controller.isAnimating && _controller.isDismissed) {
                  return const SizedBox.shrink();
                }
                
                // Opacity fades out as animation progresses
                final opacity = (1.0 - _glowAnimation.value).clamp(0.0, 1.0);
                
                // Sweep position from left to right
                final sweepPos = _glowAnimation.value;

                return ClipRRect(
                  borderRadius: effectiveRadius,
                  child: Opacity(
                    opacity: opacity * 0.4, // Max opacity 40%
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.centerLeft,
                          end: Alignment.centerRight,
                          stops: [
                            (sweepPos - 0.2).clamp(0.0, 1.0),
                            sweepPos,
                            (sweepPos + 0.2).clamp(0.0, 1.0),
                          ],
                          colors: [
                            Colors.transparent,
                            glowColor,
                            Colors.transparent,
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ],
    );
  }
}
