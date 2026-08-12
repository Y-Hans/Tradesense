import 'package:flutter/material.dart';
import '../../tokens/colors.dart';
import '../../tokens/spacing.dart';

/// A pulsing indicator showing that the AI is processing/thinking.
class ThinkingIndicator extends StatefulWidget {
  final String text;

  const ThinkingIndicator({
    super.key,
    this.text = 'Analyzing journal...',
  });

  @override
  State<ThinkingIndicator> createState() => _ThinkingIndicatorState();
}

class _ThinkingIndicatorState extends State<ThinkingIndicator>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _opacity;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat(reverse: true);
    
    _opacity = Tween<double>(begin: 0.4, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _opacity,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.auto_awesome,
            size: 16,
            color: AppColors.primaryCyan,
          ),
          SizedBox(width: AppSpacing.sm),
          Text(
            widget.text,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.primaryCyan,
                ),
          ),
        ],
      ),
    );
  }
}
