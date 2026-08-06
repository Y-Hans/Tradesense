import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:design_system/design_system.dart';

class LevelUpCelebrationDialog extends StatelessWidget {
  final String levelTitle;
  final int newLevelXp;
  final String unlockMessage;
  final VoidCallback onClaim;

  const LevelUpCelebrationDialog({
    super.key,
    required this.levelTitle,
    required this.newLevelXp,
    required this.unlockMessage,
    required this.onClaim,
  });

  static Future<void> show(
    BuildContext context, {
    required String levelTitle,
    required int newLevelXp,
    required String unlockMessage,
    required VoidCallback onClaim,
  }) {
    return showDialog(
      context: context,
      barrierColor: Colors.transparent, // We handle the blur ourselves
      builder: (context) => LevelUpCelebrationDialog(
        levelTitle: levelTitle,
        newLevelXp: newLevelXp,
        unlockMessage: unlockMessage,
        onClaim: () {
          Navigator.of(context).pop();
          onClaim();
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      duration: const Duration(milliseconds: 600),
      curve: Curves.elasticOut,
      tween: Tween<double>(begin: 0.0, end: 1.0),
      builder: (context, scale, child) {
        return Stack(
          children: [
            // Background blur
            Positioned.fill(
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 15.0, sigmaY: 15.0),
                child: Container(
                  color: Colors.black.withValues(alpha: 0.6),
                ),
              ),
            ),
            // Dialog content
            Center(
              child: Transform.scale(
                scale: scale,
                child: Material(
                  color: Colors.transparent,
                  child: Container(
                    width: MediaQuery.of(context).size.width * 0.85,
                    constraints: const BoxConstraints(maxWidth: 400),
                    padding: const EdgeInsets.all(32.0),
                    decoration: BoxDecoration(
                      color: AppColors.surface.withValues(alpha: 0.8),
                      borderRadius: BorderRadius.circular(24.0),
                      border: Border.all(
                        color: AppColors.primaryCyan.withValues(alpha: 0.5),
                        width: 2.0,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primaryCyan.withValues(alpha: 0.3),
                          blurRadius: 30.0,
                          spreadRadius: 5.0,
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(20.0),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: AppColors.primaryCyan.withValues(alpha: 0.15),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.primaryCyan.withValues(alpha: 0.5),
                                blurRadius: 20.0,
                                spreadRadius: -5.0,
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.rocket_launch_rounded,
                            size: 64.0,
                            color: AppColors.primaryCyan,
                          ),
                        ),
                        const SizedBox(height: 24.0),
                        const Text(
                          'LEVEL UP!',
                          style: TextStyle(
                            color: AppColors.primaryCyan,
                            fontSize: 28.0,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 2.0,
                            shadows: [
                              Shadow(
                                color: AppColors.primaryCyan,
                                blurRadius: 10.0,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 8.0),
                        Text(
                          levelTitle,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 22.0,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16.0),
                        Text(
                          unlockMessage,
                          style: const TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 15.0,
                            height: 1.4,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 32.0),
                        SizedBox(
                          width: double.infinity,
                          height: 50.0,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primaryCyan,
                              foregroundColor: Colors.black,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12.0),
                              ),
                              elevation: 10.0,
                              shadowColor:
                                  AppColors.primaryCyan.withValues(alpha: 0.5),
                            ),
                            onPressed: onClaim,
                            child: const Text(
                              'CLAIM REWARDS',
                              style: TextStyle(
                                fontSize: 16.0,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1.2,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
