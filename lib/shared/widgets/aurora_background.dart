import 'dart:math';
import 'dart:ui';
import 'package:flutter/material.dart';
import '../../app/theme/app_theme.dart';

/// ───────────────────────────────────────────────
///  LIQUID GLASS AURORA — BACKGROUND  ────────────
///  A calm, slowly drifting aurora of soft
///  emerald → cyan → indigo blobs over a deep
///  obsidian base. Depth comes from blur, never
///  heavy shadows.
///
///  • ~12s drift loop (very slow = premium, calm).
///  • Optional [sentiment] tints the aurora toward
///    emerald (bullish) / crimson (bearish).
///  • [AuroraBackground.enabled] = false freezes
///    the animation (a static frame). Set this in
///    tests that call pumpAndSettle so the infinite
///    ticker never blocks the harness.
/// ───────────────────────────────────────────────

class AuroraBackground extends StatefulWidget {
  const AuroraBackground({
    super.key,
    this.sentiment,
    required this.child,
    this.intensity = 1.0,
  });

  /// Optional market sentiment that tints the aurora. When null the neutral
  /// emerald→cyan→indigo palette is used.
  final AuroraSentiment? sentiment;

  final Widget child;

  /// Multiplier on blob opacity (0.0–1.0+). Keep ≤ 1.0 for restraint.
  final double intensity;

  /// Master switch for the drift animation. Defaults to on. Tests that rely on
  /// `pumpAndSettle` should set this to false once at startup.
  static bool enabled = true;

  @override
  State<AuroraBackground> createState() => _AuroraBackgroundState();
}

enum AuroraSentiment { bullish, bearish, neutral }

class _AuroraBackgroundState extends State<AuroraBackground>
    with TickerProviderStateMixin {
  late final AnimationController _drift;

  @override
  void initState() {
    super.initState();
    _drift = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 12000),
    );
    if (AuroraBackground.enabled) {
      _drift.repeat();
    } else {
      // Park at a pleasant static frame so tests still get a nice backdrop.
      _drift.value = 0.32;
    }
  }

  @override
  void dispose() {
    _drift.dispose();
    super.dispose();
  }

  List<Color> _palette() {
    switch (widget.sentiment) {
      case AuroraSentiment.bullish:
        return [
          AppColors.auroraEmerald,
          AppColors.neonEmerald.withValues(alpha: 0.8),
          AppColors.auroraCyan,
        ];
      case AuroraSentiment.bearish:
        return [
          AppColors.crimsonSpark.withValues(alpha: 0.8),
          AppColors.auroraIndigo,
          AppColors.auroraViolet,
        ];
      case AuroraSentiment.neutral:
      case null:
        return AppGradients.auroraDrift;
    }
  }

  @override
  Widget build(BuildContext context) {
    final palette = _palette();
    return RepaintBoundary(
      child: AnimatedBuilder(
        animation: _drift,
        builder: (context, _) {
          return CustomPaint(
            painter: _AuroraPainter(
              t: _drift.value,
              palette: palette,
              intensity: widget.intensity,
            ),
            size: Size.infinite,
            child: widget.child,
          );
        },
      ),
    );
  }
}

/// Paints 3 large, heavily-blurred radial blobs that orbit slowly. Because
/// each blob is big and blurry, the cost is low and the result reads as a
/// smooth aurora rather than discrete circles.
class _AuroraPainter extends CustomPainter {
  _AuroraPainter({
    required this.t,
    required this.palette,
    required this.intensity,
  });

  final double t;
  final List<Color> palette;
  final double intensity;

  @override
  void paint(Canvas canvas, Size size) {
    // 1. Base fill — slightly warmer than pure black for an "alive" feel.
    canvas.drawRect(
      Offset.zero & size,
      Paint()..color = AppColors.auroraBase,
    );

    // 2. Vertical depth gradient (top lighter → bottom true black).
    final depth = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Colors.transparent,
          AppColors.oledBlack.withValues(alpha: 0.55),
        ],
      ).createShader(Offset.zero & size);
    canvas.drawRect(Offset.zero & size, depth);

    // 3. Three drifting aurora blobs.
    final w = size.width;
    final h = size.height;
    final blobs = [
      _BlobSpec(
        color: palette[0],
        baseX: w * 0.25,
        baseY: h * 0.18,
        radius: w * 0.55,
        phase: 0.0,
        ampX: w * 0.12,
        ampY: h * 0.06,
      ),
      _BlobSpec(
        color: palette[1],
        baseX: w * 0.78,
        baseY: h * 0.32,
        radius: w * 0.50,
        phase: 2.1,
        ampX: w * 0.10,
        ampY: h * 0.08,
      ),
      _BlobSpec(
        color: palette[2],
        baseX: w * 0.50,
        baseY: h * 0.72,
        radius: w * 0.60,
        phase: 4.0,
        ampX: w * 0.14,
        ampY: h * 0.05,
      ),
    ];

    for (final b in blobs) {
      // Each blob breathes (alpha) and drifts (x/y) on the shared t.
      final ang = (t * 2 * pi) + b.phase;
      final cx = b.baseX + (b.ampX * cos(ang));
      final cy = b.baseY + (b.ampY * sin(ang * 0.8));
      final breathe = 0.5 + 0.5 * sin(ang * 0.5);
      final alpha = (0.16 + 0.10 * breathe) * intensity;

      canvas.drawCircle(
        Offset(cx, cy),
        b.radius,
        Paint()
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 90)
          ..color = b.color.withValues(alpha: alpha.clamp(0.0, 0.4)),
      );
    }

    // 4. Faint top vignette so headers/overlays remain legible.
    final topVignette = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          AppColors.oledBlack.withValues(alpha: 0.35),
          Colors.transparent,
        ],
        stops: const [0.0, 0.25],
      ).createShader(Offset.zero & size);
    canvas.drawRect(Offset.zero & size, topVignette);
  }

  @override
  bool shouldRepaint(covariant _AuroraPainter old) =>
      old.t != t ||
      old.intensity != intensity ||
      old.palette.length != palette.length;
}

class _BlobSpec {
  const _BlobSpec({
    required this.color,
    required this.baseX,
    required this.baseY,
    required this.radius,
    required this.phase,
    required this.ampX,
    required this.ampY,
  });

  final Color color;
  final double baseX;
  final double baseY;
  final double radius;
  final double phase;
  final double ampX;
  final double ampY;
}
