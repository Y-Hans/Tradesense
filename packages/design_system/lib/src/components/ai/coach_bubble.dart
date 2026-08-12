import 'package:flutter/material.dart';
import '../../tokens/colors.dart';
import '../../tokens/spacing.dart';

/// A chat bubble for the AI Coach.
/// 
/// Example usage:
/// ```dart
/// CoachBubble(
///   message: 'Hello Trader. Ready to review your trades?',
///   isUser: false,
/// )
/// ```
class CoachBubble extends StatelessWidget {
  /// The chat message content
  final String message;
  
  /// True if the message is from the user, false if from the AI coach
  final bool isUser;
  
  /// Whether the AI is currently thinking (shows loading instead of text)
  final bool isThinking;

  const CoachBubble({
    super.key,
    required this.message,
    this.isUser = false,
    this.isThinking = false,
  });

  @override
  Widget build(BuildContext context) {
    final borderRadius = BorderRadius.only(
      topLeft: const Radius.circular(AppSpacing.radiusMd),
      topRight: const Radius.circular(AppSpacing.radiusMd),
      bottomLeft: isUser ? const Radius.circular(AppSpacing.radiusMd) : Radius.zero,
      bottomRight: isUser ? Radius.zero : const Radius.circular(AppSpacing.radiusMd),
    );

    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.8,
        ),
        padding: EdgeInsets.all(AppSpacing.lg),
        margin: EdgeInsets.symmetric(vertical: AppSpacing.sm),
        decoration: BoxDecoration(
          color: isUser ? Theme.of(context).colorScheme.surface : AppColors.primaryCyan.withValues(alpha: 0.1),
          borderRadius: borderRadius,
          border: Border.all(
            color: isUser ? Theme.of(context).dividerColor : AppColors.primaryCyan.withValues(alpha: 0.3),
            width: 1,
          ),
        ),
        child: isThinking
            ? SizedBox(
                width: 40,
                height: 20,
                child: Center(
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: AppColors.primaryCyan,
                  ),
                ),
              )
            : Text(
                message,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: isUser ? Theme.of(context).colorScheme.onSurface : AppColors.primaryCyan,
                      height: 1.4,
                    ),
              ),
      ),
    );
  }
}
