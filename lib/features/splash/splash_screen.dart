import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:mind_care_app/core/router/app_router.dart';
import 'package:mind_care_app/core/theme/app_colors.dart';
import 'package:mind_care_app/core/widgets/leaf_background.dart';
import 'package:mind_care_app/main.dart' show hiveReadyCompleter, appUserName, splashSavedName, splashSavedLang;

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeIn,
    );
    _controller.forward();

    Future.delayed(const Duration(milliseconds: 1500), () async {
      if (!mounted) return;

      // Wait for Hive + Prefs to be ready before navigating.
      // Keep timeout under Android's 5s ANR threshold.
      await hiveReadyCompleter.future
          .timeout(const Duration(seconds: 3), onTimeout: () {});

      if (!mounted) return;

      // Use pre-fetched values from _heavyInit() — zero platform channel calls
      // on the main thread here. splashSavedName/Lang are set before
      // hiveReadyCompleter.complete() so they are always ready by this point.
      final savedName = splashSavedName;
      final savedLang = splashSavedLang;

      // Sync notifier with fresh value
      appUserName.value = (savedName != null && savedName.isNotEmpty) ? savedName : null;

      if (!mounted) return;
      if (savedName != null && savedName.isNotEmpty) {
        // Returning user — show welcome-back onboarding screen
        context.go('${AppRouter.onboarding}?returning=true');
      } else {
        // New user — full onboarding flow
        context.go(AppRouter.onboarding);
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.gradientStart,
      body: Container(
        decoration: const BoxDecoration(
          gradient: AppColors.onboardingGradient,
        ),
        child: LeafBackground(
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 110,
                    height: 110,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.9),
                      borderRadius: BorderRadius.circular(28),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primaryDark.withOpacity(0.2),
                          blurRadius: 20,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.eco_rounded,
                      size: 60,
                      color: AppColors.primaryDark,
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'MindCare',
                    style: TextStyle(
                      fontSize: 36,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textDark,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Your safe space for mental wellness',
                    style: TextStyle(
                      fontSize: 15,
                      color: AppColors.textSecondaryDark.withOpacity(0.8),
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
