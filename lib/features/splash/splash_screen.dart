import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:mind_care_app/core/router/app_router.dart';
import 'package:mind_care_app/core/widgets/app_loading_view.dart';
import 'package:mind_care_app/main.dart'
    show hiveReadyCompleter, appUserName, splashSavedName;

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();

    Future.delayed(const Duration(milliseconds: 1500), () async {
      if (!mounted) return;

      // Wait for Hive + Prefs to be ready before navigating.
      // Keep timeout under Android's 5s ANR threshold.
      await hiveReadyCompleter.future.timeout(
        const Duration(seconds: 3),
        onTimeout: () {},
      );

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
    });
  }

  @override
  Widget build(BuildContext context) {
    // The loading view owns its own entrance animation. Navigation above is
    // unchanged — this route only decides *when* to leave the loading state.
    return const AppLoadingView();
  }
}
