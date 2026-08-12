import 'package:flutter/material.dart';
import 'package:design_system/design_system.dart';

/// Adaptive TradeSense logo widget.
///
/// When [assets/images/logo.png] exists it renders the image logo.
/// When the asset is not yet present it automatically falls back to the
/// branded [AIAvatar] gradient icon so the UI is never broken.
///
/// Usage:
/// ```dart
/// AppLogo(size: 64)         // default icon
/// AppLogo.horizontal(size: 40) // logo + wordmark row
/// ```
class AppLogo extends StatelessWidget {
  final double size;
  final bool showWordmark;

  const AppLogo({
    super.key,
    this.size = 48,
    this.showWordmark = false,
  });

  /// Horizontal layout: logo icon + 'TradeSense' wordmark side by side.
  const AppLogo.horizontal({
    super.key,
    this.size = 32,
    this.showWordmark = true,
  });

  @override
  Widget build(BuildContext context) {
    final logo = _LogoImage(size: size);

    if (!showWordmark) return logo;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        logo,
        SizedBox(width: 10),
        Text(
          'TradeSense',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: AppColors.primaryCyan,
              ),
        ),
      ],
    );
  }
}

/// Internal widget that attempts to load the PNG logo; falls back to [AIAvatar].
class _LogoImage extends StatelessWidget {
  final double size;

  const _LogoImage({required this.size});

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      'assets/images/logo.png',
      width: size,
      height: size,
      fit: BoxFit.contain,
      // Graceful fallback: if the asset doesn't exist yet, render the gradient avatar.
      errorBuilder: (_, __, ___) => AIAvatar(size: size),
    );
  }
}
