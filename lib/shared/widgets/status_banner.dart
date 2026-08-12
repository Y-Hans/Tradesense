import 'package:flutter/material.dart';

enum BannerSeverity {
  info,
  warning,
  success,
  error,
}

/// A generic, reusable, theme-aware status banner component.
///
/// Responsible purely for presentation. Knows nothing about connectivity or specific domain logic.
class StatusBanner extends StatelessWidget {
  final String title;
  final String? subtitle;
  final Widget? icon;
  final BannerSeverity severity;
  final bool isVisible;
  final VoidCallback? onTap;
  final Widget? action;

  StatusBanner({
    super.key,
    required this.title,
    this.subtitle,
    this.icon,
    this.severity = BannerSeverity.warning,
    this.isVisible = true,
    this.onTap,
    this.action,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final colors = _getBannerColors(colorScheme);

    return AnimatedSize(
      duration: const Duration(milliseconds: 250),
      curve: Curves.fastOutSlowIn,
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeIn,
        opacity: isVisible ? 1.0 : 0.0,
        child: isVisible
            ? Semantics(
                liveRegion: true,
                focused: isVisible,
                label: subtitle != null ? '$title. $subtitle' : title,
                child: Material(
                  color: colors.backgroundColor,
                  elevation: 1,
                  child: InkWell(
                    onTap: onTap,
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16.0,
                        vertical: 10.0,
                      ),
                      decoration: BoxDecoration(
                        border: Border(
                          bottom: BorderSide(
                            color: colors.borderColor,
                            width: 1.0,
                          ),
                        ),
                      ),
                      child: SafeArea(
                        top: false,
                        bottom: false,
                        child: Row(
                          children: [
                            if (icon != null) ...[
                              IconTheme(
                                data: IconThemeData(
                                  color: colors.foregroundColor,
                                  size: 20,
                                ),
                                child: icon!,
                              ),
                              const SizedBox(width: 12),
                            ],
                            Expanded(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    title,
                                    style: theme.textTheme.bodyMedium?.copyWith(
                                      color: colors.foregroundColor,
                                      fontWeight: FontWeight.bold,
                                      height: 1.2,
                                    ),
                                  ),
                                  if (subtitle != null &&
                                      subtitle!.isNotEmpty) ...[
                                    const SizedBox(height: 2),
                                    Text(
                                      subtitle!,
                                      style:
                                          theme.textTheme.bodySmall?.copyWith(
                                        color: colors.foregroundColor
                                            .withValues(alpha: 0.85),
                                        height: 1.2,
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                            if (action != null) ...[
                              const SizedBox(width: 8),
                              action!,
                            ],
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              )
            : const SizedBox(
                width: double.infinity,
                height: 0,
              ),
      ),
    );
  }

  _BannerColorPalette _getBannerColors(ColorScheme colorScheme) {
    switch (severity) {
      case BannerSeverity.warning:
        return const _BannerColorPalette(
          backgroundColor: Color(0xFF7C2D12),
          foregroundColor: Color(0xFFFFEDD5),
          borderColor: Color(0xFF9A3412),
        );
      case BannerSeverity.error:
        return _BannerColorPalette(
          backgroundColor: colorScheme.errorContainer,
          foregroundColor: colorScheme.onErrorContainer,
          borderColor: colorScheme.error,
        );
      case BannerSeverity.success:
        return const _BannerColorPalette(
          backgroundColor: Color(0xFF064E3B),
          foregroundColor: Color(0xFFD1FAE5),
          borderColor: Color(0xFF047857),
        );
      case BannerSeverity.info:
        return _BannerColorPalette(
          backgroundColor: colorScheme.surfaceContainerHigh,
          foregroundColor: colorScheme.onSurfaceVariant,
          borderColor: colorScheme.outlineVariant,
        );
    }
  }
}

class _BannerColorPalette {
  final Color backgroundColor;
  final Color foregroundColor;
  final Color borderColor;

  const _BannerColorPalette({
    required this.backgroundColor,
    required this.foregroundColor,
    required this.borderColor,
  });
}
