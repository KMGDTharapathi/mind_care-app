import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

/// A [Scaffold] wrapper that fills the background with [AppColors.onboardingGradient].
class GradientScaffold extends StatelessWidget {
  const GradientScaffold({
    super.key,
    required this.body,
    this.appBar,
  });

  final Widget body;
  final PreferredSizeWidget? appBar;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.gradientStart,
      appBar: appBar,
      body: Container(
        decoration: const BoxDecoration(
          gradient: AppColors.onboardingGradient,
        ),
        child: body,
      ),
    );
  }
}
