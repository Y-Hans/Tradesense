import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:video_player/video_player.dart';
import '../../app/theme/app_theme.dart';

/// ───────────────────────────────────────────────
///  BITCOIN FLIP LOADER  ────────────────────────
///  Seamlessly loops the gold Bitcoin flip video
///  with a dark overlay to neutralize green screen,
///  golden ambient glow, and OLED-integrated styling.
/// ───────────────────────────────────────────────

class BitcoinLoader extends StatefulWidget {
  const BitcoinLoader({
    super.key,
    this.size = 160,
    this.showLabel = true,
    this.label = 'Loading markets...',
  });

  final double size;
  final bool showLabel;
  final String label;

  @override
  State<BitcoinLoader> createState() => _BitcoinLoaderState();
}

class _BitcoinLoaderState extends State<BitcoinLoader>
    with SingleTickerProviderStateMixin {
  late VideoPlayerController _controller;
  late AnimationController _glowController;
  bool _isReady = false;

  @override
  void initState() {
    super.initState();
    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat(reverse: true);

    _initVideo();
  }

  Future<void> _initVideo() async {
    _controller = VideoPlayerController.asset(
      'assets/video/bitcoin_loader.mp4',
      videoPlayerOptions: VideoPlayerOptions(mixWithOthers: true),
    );

    try {
      await _controller.initialize();
      _controller.setVolume(0.0);
      _controller.setLooping(true);
      await _controller.play();

      if (mounted) {
        setState(() => _isReady = true);
      }
    } catch (e) {
      debugPrint('BitcoinLoader video error: $e');
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _glowController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // ── Coin Container with Glow ────────────
        AnimatedBuilder(
          animation: _glowController,
          builder: (context, child) {
            final pulse = 0.7 + (_glowController.value * 0.3);
            return Container(
              width: widget.size,
              height: widget.size,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: AppColors.cyberGold.withValues(alpha: 0.15 * pulse),
                    blurRadius: 40 * pulse,
                    spreadRadius: 8 * pulse,
                  ),
                  BoxShadow(
                    color: AppColors.electricCyan.withValues(alpha: 0.08 * pulse),
                    blurRadius: 60 * pulse,
                    spreadRadius: 16 * pulse,
                  ),
                ],
              ),
              child: child,
            );
          },
          child: _isReady
              ? ClipOval(
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // Video layer
                      SizedBox.expand(
                        child: FittedBox(
                          fit: BoxFit.cover,
                          child: SizedBox(
                            width: _controller.value.size.width,
                            height: _controller.value.size.height,
                            child: VideoPlayer(_controller),
                          ),
                        ),
                      ),
                      // Green-screen neutralizer overlay
                      Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: RadialGradient(
                            colors: [
                              Colors.transparent,
                              AppColors.oledObsidian.withValues(alpha: 0.35),
                            ],
                            stops: const [0.55, 1.0],
                          ),
                        ),
                      ),
                      // Outer rim darkening to crush green fringe
                      Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: AppColors.oledObsidian.withValues(alpha: 0.6),
                            width: 3,
                          ),
                        ),
                      ),
                    ],
                  ),
                )
              : _FallbackSpinner(size: widget.size),
        ),
        if (widget.showLabel) ...[
          const SizedBox(height: 24),
          _LoadingLabel(text: widget.label),
        ],
      ],
    );
  }
}

/// Shimmering text label beneath the loader
class _LoadingLabel extends StatefulWidget {
  const _LoadingLabel({required this.text});
  final String text;

  @override
  State<_LoadingLabel> createState() => _LoadingLabelState();
}

class _LoadingLabelState extends State<_LoadingLabel>
    with SingleTickerProviderStateMixin {
  late AnimationController _dotsController;

  @override
  void initState() {
    super.initState();
    _dotsController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();
  }

  @override
  void dispose() {
    _dotsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _dotsController,
      builder: (context, child) {
        final dots = '.' * ((_dotsController.value * 4).floor() % 4);
        return Text(
          '${widget.text}$dots',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppColors.textMuted,
                letterSpacing: 1.2,
              ),
        );
      },
    );
  }
}

/// Fallback when video fails to load
class _FallbackSpinner extends StatelessWidget {
  const _FallbackSpinner({required this.size});
  final double size;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: const CircularProgressIndicator(
        strokeWidth: 2.5,
        valueColor: AlwaysStoppedAnimation(AppColors.cyberGold),
      ),
    );
  }
}

/// ───────────────────────────────────────────────
///  FULL-SCREEN LOADING OVERLAY  ────────────────
///  Drops a dimmed OLED backdrop + centered loader
/// ───────────────────────────────────────────────
class BitcoinLoadingOverlay extends StatelessWidget {
  const BitcoinLoadingOverlay({
    super.key,
    this.label = 'Syncing markets...',
  });

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.oledBlack.withValues(alpha: 0.85),
      child: Center(
        child: BitcoinLoader(
          size: 140,
          label: label,
        ),
      ),
    );
  }
}

/// Convenience wrapper: replaces CircularProgressIndicator anywhere
class AdaptiveLoader extends StatelessWidget {
  const AdaptiveLoader({
    super.key,
    this.size = 48,
    this.strokeWidth = 2.5,
    this.isFullScreen = false,
  });

  final double size;
  final double strokeWidth;
  final bool isFullScreen;

  @override
  Widget build(BuildContext context) {
    if (isFullScreen) {
      return const BitcoinLoadingOverlay();
    }
    return SizedBox(
      width: size,
      height: size,
      child: CircularProgressIndicator(
        strokeWidth: strokeWidth,
        valueColor: const AlwaysStoppedAnimation(AppColors.electricCyan),
      ),
    );
  }
}
