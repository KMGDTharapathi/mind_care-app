import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:mind_care_app/core/router/app_router.dart';
import 'package:mind_care_app/core/theme/app_colors.dart';
import 'package:mind_care_app/core/widgets/leaf_background.dart';
import 'package:mind_care_app/main.dart'
    show hiveReadyCompleter, appUserName, splashSavedName, splashSavedLang;

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<double> _progressAnimation;

  bool _logoFailed = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.0, 0.35, curve: Curves.easeIn),
    );
    _progressAnimation = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.05, 1.0, curve: Curves.easeInOut),
    );
    _controller.forward();
    _navigateWhenReady();
  }

  Future<void> _navigateWhenReady() async {
    // Wait for Hive + Prefs to be ready before navigating.
    // Keep timeout under Android's 5s ANR threshold.
    await hiveReadyCompleter.future.timeout(
      const Duration(seconds: 3),
      onTimeout: () {},
    );

    if (!mounted) return;

    // Let the loading circle visibly reach 100% before we leave.
    final remaining = _controller.duration! * (1 - _controller.value);
    if (remaining > Duration.zero) {
      await Future.delayed(remaining + const Duration(milliseconds: 120));
    }
    if (!mounted) return;
    if (!_controller.isCompleted) {
      await _controller.forward().orCancel;
    }
    if (!mounted) return;

    // Use pre-fetched values from _heavyInit() — zero platform channel calls
    // on the main thread here. splashSavedName/Lang are set before
    // hiveReadyCompleter.complete() so they are always ready by this point.
    final savedName = splashSavedName;

    // Sync notifier with fresh value
    appUserName.value = (savedName != null && savedName.isNotEmpty)
        ? savedName
        : null;

    if (!mounted) return;
    if (savedName != null && savedName.isNotEmpty) {
      // Returning user — show welcome-back onboarding screen
      context.go('${AppRouter.onboarding}?returning=true');
    } else {
      // New user — full onboarding flow
      context.go(AppRouter.onboarding);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final percent = (_progressAnimation.value * 100).clamp(0, 100).round();

    return Scaffold(
      backgroundColor: AppColors.gradientStart,
      body: Container(
        decoration: const BoxDecoration(gradient: AppColors.onboardingGradient),
        child: LeafBackground(
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 210,
                    height: 210,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.95),
                      borderRadius: BorderRadius.circular(48),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primaryDark.withValues(alpha: 0.25),
                          blurRadius: 34,
                          spreadRadius: 4,
                          offset: const Offset(0, 12),
                        ),
                      ],
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: _logoFailed
                        ? const Icon(
                            Icons.eco_rounded,
                            size: 110,
                            color: AppColors.primaryDark,
                          )
                        : Image.asset(
                            'assets/images/app_logo.png',
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              WidgetsBinding.instance.addPostFrameCallback((_) {
                                if (mounted && !_logoFailed) {
                                  setState(() => _logoFailed = true);
                                }
                              });
                              return const Icon(
                                Icons.eco_rounded,
                                size: 110,
                                color: AppColors.primaryDark,
                              );
                            },
                          ),
                  ),
                  const SizedBox(height: 34),
                  const Text(
                    'MindCare',
                    style: TextStyle(
                      fontSize: 42,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textDark,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Your safe space for mental wellness',
                    style: TextStyle(
                      fontSize: 15,
                      color: AppColors.textSecondaryDark.withValues(alpha: 0.8),
                    ),
                  ),
                  const SizedBox(height: 46),
                  SizedBox(
                    width: 64,
                    height: 64,
                    child: AnimatedBuilder(
                      animation: _progressAnimation,
                      builder: (context, child) {
                        return Stack(
                          alignment: Alignment.center,
                          fit: StackFit.expand,
                          children: [
                            CircularProgressIndicator(
                              value: _progressAnimation.value,
                              strokeWidth: 5,
                              backgroundColor: AppColors.primaryDark
                                  .withValues(alpha: 0.15),
                              valueColor: const AlwaysStoppedAnimation<Color>(
                                AppColors.primaryDark,
                              ),
                            ),
                            Text(
                              '$percent%',
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                color: AppColors.primaryDark,
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 16),
                  AnimatedBuilder(
                    animation: _progressAnimation,
                    builder: (context, child) {
                      return Text(
                        percent >= 100 ? 'Ready' : 'Loading your space…',
                        style: TextStyle(
                          fontSize: 13,
                          color: AppColors.textSecondaryDark.withValues(alpha: 0.75),
                          letterSpacing: 0.3,
                        ),
                      );
                    },
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
