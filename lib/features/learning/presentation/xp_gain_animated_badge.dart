import 'package:flutter/material.dart';
import '../../../app/theme/app_theme.dart';

class XpGainAnimatedBadge extends StatefulWidget {
  final int xpGained;
  final bool visible;
  final VoidCallback? onDismiss;

  const XpGainAnimatedBadge({
    super.key,
    required this.xpGained,
    required this.visible,
    this.onDismiss,
  });

  @override
  State<XpGainAnimatedBadge> createState() => _XpGainAnimatedBadgeState();
}

class _XpGainAnimatedBadgeState extends State<XpGainAnimatedBadge>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.3, curve: Curves.easeIn),
      ),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0.0, 0.5),
      end: const Offset(0.0, -0.2),
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeOutCubic,
      ),
    );

    if (widget.visible && widget.xpGained > 0) {
      _startAnimation();
    }
  }

  @override
  void didUpdateWidget(covariant XpGainAnimatedBadge oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.visible &&
        (!oldWidget.visible || widget.xpGained != oldWidget.xpGained)) {
      _startAnimation();
    }
  }

  void _startAnimation() {
    _controller.forward(from: 0.0).then((_) {
      if (mounted && widget.onDismiss != null) {
        widget.onDismiss!();
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.visible || widget.xpGained <= 0) {
      return const SizedBox.shrink();
    }

    return SlideTransition(
      position: _slideAnimation,
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          decoration: BoxDecoration(
            color: AppColors.profit,
            borderRadius: BorderRadius.circular(20.0),
            boxShadow: [
              BoxShadow(
                color: AppColors.profit.withValues(alpha: 0.4),
                blurRadius: 10.0,
                spreadRadius: 2.0,
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.stars_rounded,
                color: Colors.white,
                size: 20.0,
              ),
              const SizedBox(width: 6.0),
              Text(
                '+${widget.xpGained} XP!',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 14.0,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
