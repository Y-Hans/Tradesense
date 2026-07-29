import 'dart:ui';
import 'package:flutter/material.dart';
import '../../app/theme/app_theme.dart';

/// A premium, glassmorphic card surface for trading metrics and actions,
/// with a neon-glow hover animation.
class TradeCard extends StatefulWidget {
  const TradeCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.margin,
    this.onTap,
    this.semanticLabel,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry? margin;
  final VoidCallback? onTap;
  final String? semanticLabel;

  @override
  State<TradeCard> createState() => _TradeCardState();
}

class _TradeCardState extends State<TradeCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final borderRadius = BorderRadius.circular(20);
    final isInteractive = widget.onTap != null;

    return Semantics(
      button: isInteractive,
      label: widget.semanticLabel,
      child: MouseRegion(
        onEnter:
            isInteractive ? (_) => setState(() => _isHovered = true) : null,
        onExit:
            isInteractive ? (_) => setState(() => _isHovered = false) : null,
        cursor:
            isInteractive ? SystemMouseCursors.click : SystemMouseCursors.basic,
        child: Padding(
          padding: widget.margin ?? EdgeInsets.zero,
          child: ClipRRect(
            borderRadius: borderRadius,
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeOutCubic,
                decoration: BoxDecoration(
                  borderRadius: borderRadius,
                  border: Border.all(
                    color: _isHovered
                        ? AppColors.primary
                        : AppColors.outline.withValues(alpha: 0.6),
                    width: _isHovered ? 2.0 : 1.5,
                  ),
                  boxShadow: _isHovered
                      ? [
                          BoxShadow(
                            color: AppColors.primary.withValues(alpha: 0.3),
                            blurRadius: 16,
                            spreadRadius: 2,
                          )
                        ]
                      : [],
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      AppColors.card.withValues(alpha: _isHovered ? 0.8 : 0.7),
                      AppColors.card.withValues(alpha: _isHovered ? 0.4 : 0.3),
                    ],
                  ),
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: borderRadius,
                    onTap: widget.onTap,
                    hoverColor: Colors.transparent,
                    splashColor: AppColors.primary.withValues(alpha: 0.1),
                    highlightColor: AppColors.primary.withValues(alpha: 0.05),
                    child: Padding(
                      padding: widget.padding,
                      child: widget.child,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
