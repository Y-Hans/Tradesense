import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import '../../../../app/theme/app_theme.dart';
import '../../../../shared/widgets/level_up_confetti.dart';

class DailyStreakCard extends StatefulWidget {
  final int streakDays;
  final bool isActive;

  const DailyStreakCard({
    super.key,
    required this.streakDays,
    required this.isActive,
  });

  @override
  State<DailyStreakCard> createState() => _DailyStreakCardState();
}

class _DailyStreakCardState extends State<DailyStreakCard> {
  final ConfettiController _confettiController = ConfettiController();

  @override
  void dispose() {
    _confettiController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Scale flame slightly based on streak days up to a max
    final flameScale = 1.0 + (widget.streakDays.clamp(0, 30) / 100.0);

    return GestureDetector(
      onTap: widget.isActive ? () => _confettiController.fire() : null,
      child: LevelUpConfetti(
        controller: _confettiController,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16.0),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10.0, sigmaY: 10.0),
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
              decoration: BoxDecoration(
                color: AppColors.surface.withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(16.0),
                border: Border.all(
                  color: widget.isActive
                      ? AppColors.discipline.withValues(alpha: 0.5)
                      : Colors.white.withValues(alpha: 0.1),
                  width: 1.0,
                ),
                boxShadow: widget.isActive
                    ? [
                        BoxShadow(
                          color: AppColors.discipline.withValues(alpha: 0.2),
                          blurRadius: 15.0,
                          spreadRadius: -5.0,
                        )
                      ]
                    : [],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Transform.scale(
                    scale: widget.isActive ? flameScale : 1.0,
                    child: SizedBox(
                      height: 36.0,
                      width: 36.0,
                      child: widget.isActive
                          ? Lottie.network(
                              'https://assets9.lottiefiles.com/packages/lf20_7hcgxtv9.json', // Placeholder fire animation
                              fit: BoxFit.contain,
                              errorBuilder: (context, error, stackTrace) {
                                // Fallback icon if offline/error
                                return const Icon(
                                  Icons.local_fire_department,
                                  color: AppColors.discipline,
                                  size: 32.0,
                                );
                              },
                            )
                          : const Icon(
                              Icons.local_fire_department,
                              color: Colors.grey,
                              size: 28.0,
                            ),
                    ),
                  ),
                  const SizedBox(height: 8.0),
                  Text(
                    '${widget.streakDays} Day${widget.streakDays == 1 ? '' : 's'}',
                    style: TextStyle(
                      color: widget.isActive ? Colors.white : Colors.grey,
                      fontWeight: FontWeight.bold,
                      fontSize: 14.0,
                    ),
                  ),
                  const SizedBox(height: 2.0),
                  Text(
                    'Streak',
                    style: TextStyle(
                      color: widget.isActive ? Colors.white70 : Colors.grey,
                      fontSize: 11.0,
                      letterSpacing: 1.1,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
