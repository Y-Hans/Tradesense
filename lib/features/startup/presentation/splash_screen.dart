import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cryptoedu/shared/widgets/crypto_loading_indicator.dart';
import 'package:go_router/go_router.dart';
import 'package:video_player/video_player.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late VideoPlayerController _videoController;
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;
  Timer? _transitionTimer;
  bool _isVideoInitialized = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.5).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInQuad),
    );

    _fadeAnimation = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeIn),
    );

    _initVideo();
  }

  Future<void> _initVideo() async {
    _videoController = VideoPlayerController.asset('assets/video/intro_splash.mp4');
    try {
      await _videoController.initialize();
      _videoController.setVolume(0.0);
      _videoController.play();
      setState(() {
        _isVideoInitialized = true;
      });

      // Start transition at exactly 4.2 seconds
      _transitionTimer = Timer(const Duration(milliseconds: 4200), () {
        _startTransition();
      });
    } catch (e) {
      // Fallback if video fails to load
      debugPrint('Error loading splash video: $e');
      _startTransition();
    }
  }

  void _startTransition() {
    if (!mounted) return;
    _animationController.forward().then((_) {
      if (mounted) {
        context.go('/home');
      }
    });
  }

  @override
  void dispose() {
    _transitionTimer?.cancel();
    _videoController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: AnimatedBuilder(
        animation: _animationController,
        builder: (context, child) {
          return Opacity(
            opacity: _fadeAnimation.value,
            child: Transform.scale(
              scale: _scaleAnimation.value,
              child: child,
            ),
          );
        },
        child: Center(
          child: _isVideoInitialized
              ? SizedBox.expand(
                  child: FittedBox(
                    fit: BoxFit.cover,
                    child: SizedBox(
                      width: _videoController.value.size.width,
                      height: _videoController.value.size.height,
                      child: VideoPlayer(_videoController),
                    ),
                  ),
                )
              : const CryptoLoadingIndicator(size: 40),
        ),
      ),
    );
  }
}
