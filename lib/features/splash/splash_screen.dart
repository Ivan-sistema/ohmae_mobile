import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../auth/login_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late final AnimationController _controller;
  late final AnimationController _dotsController;
  late final Animation<double> _logoOpacity;
  late final Animation<double> _logoScale;
  late final Animation<Offset> _logoPosition;
  late final Animation<Offset> _topCirclePosition;
  late final Animation<Offset> _bottomCirclePosition;

  Timer? _navigationTimer;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
    _dotsController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat();

    _logoOpacity = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.2, 0.8, curve: Curves.easeIn),
      ),
    );
    _logoScale = Tween<double>(begin: 0.6, end: 1).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.2, 0.9, curve: Curves.elasticOut),
      ),
    );
    _logoPosition = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.2, 0.8, curve: Curves.easeOut),
      ),
    );
    _topCirclePosition = Tween<Offset>(
      begin: const Offset(0.5, -0.5),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0, 0.7, curve: Curves.easeOutCubic),
      ),
    );
    _bottomCirclePosition = Tween<Offset>(
      begin: const Offset(-0.5, 0.5),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.1, 0.8, curve: Curves.easeOutCubic),
      ),
    );

    _controller.forward();
    _navigationTimer = Timer(const Duration(seconds: 3), _abrirLogin);
  }

  void _abrirLogin() {
    if (!mounted) return;

    Navigator.of(context).pushReplacement(
      PageRouteBuilder<void>(
        pageBuilder: (context, animation, secondaryAnimation) =>
            const LoginScreen(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) =>
            FadeTransition(opacity: animation, child: child),
        transitionDuration: const Duration(milliseconds: 600),
      ),
    );
  }

  @override
  void dispose() {
    _navigationTimer?.cancel();
    _controller.dispose();
    _dotsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.cremeFundo,
      body: Stack(
        children: [
          Positioned(
            top: -50,
            right: -50,
            child: SlideTransition(
              position: _topCirclePosition,
              child: Container(
                width: 240,
                height: 240,
                decoration: BoxDecoration(
                  color: AppTheme.amareloStatus.withValues(alpha: 0.18),
                  shape: BoxShape.circle,
                ),
              ),
            ),
          ),
          Positioned(
            bottom: -80,
            left: -80,
            child: SlideTransition(
              position: _bottomCirclePosition,
              child: Container(
                width: 280,
                height: 280,
                decoration: BoxDecoration(
                  color: AppTheme.textoSecundario.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
              ),
            ),
          ),
          Center(
            child: FadeTransition(
              opacity: _logoOpacity,
              child: ScaleTransition(
                scale: _logoScale,
                child: SlideTransition(
                  position: _logoPosition,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SizedBox(
                        height: 120,
                        child: Image.asset(
                          'assets/images/logo.png',
                          fit: BoxFit.contain,
                          errorBuilder: (context, error, stackTrace) =>
                              const Icon(
                            Icons.child_care,
                            color: AppTheme.aquaPrincipal,
                            size: 60,
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      _buildPulsingDots(),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPulsingDots() {
    return AnimatedBuilder(
      animation: _dotsController,
      builder: (context, child) {
        return Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(3, (index) {
            final phase = (_dotsController.value * 2 * math.pi) - index * 0.8;
            final opacity =
                ((math.sin(phase) + 1) / 2).clamp(0.3, 1.0).toDouble();
            final color = switch (index) {
              0 => AppTheme.aquaPrincipal,
              1 => AppTheme.coralAlerta,
              _ => AppTheme.amareloStatus,
            };

            return Container(
              width: 8,
              height: 8,
              margin: const EdgeInsets.symmetric(horizontal: 4),
              decoration: BoxDecoration(
                color: color.withValues(alpha: opacity),
                shape: BoxShape.circle,
              ),
            );
          }),
        );
      },
    );
  }
}
